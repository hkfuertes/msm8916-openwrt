// SPDX-License-Identifier: GPL-2.0
/*
 * ST7735S Framebuffer Driver for MSM8916
 *
 * Copyright (C) 2025
 * Based on XLIORF/linux_fb_st7735s
 * Adapted for MSM8916 with Android 4.4 KitKat init sequence
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/string.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/fb.h>
#include <linux/init.h>
#include <linux/platform_device.h>
#include <linux/spi/spi.h>
#include <linux/gpio/consumer.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/uaccess.h>

#define DRIVER_NAME "st7735s"

/* Display specifications */
#define ST7735S_WIDTH       128
#define ST7735S_HEIGHT      128
#define ST7735S_BPP         16
#define ST7735S_VMEM_SIZE   (ST7735S_WIDTH * ST7735S_HEIGHT * ST7735S_BPP / 8)

/* ST7735S Commands (from Android 4.4 DTS) */
#define CMD_SLPOUT      0x11  /* Sleep Out */
#define CMD_INVON       0x21  /* Display Inversion On */
#define CMD_DISPON      0x29  /* Display On */
#define CMD_CASET       0x2A  /* Column Address Set */
#define CMD_RASET       0x2B  /* Row Address Set */
#define CMD_RAMWR       0x2C  /* Memory Write */
#define CMD_MADCTL      0x36  /* Memory Data Access Control */
#define CMD_COLMOD      0x3A  /* Interface Pixel Format */
#define CMD_FRMCTR1     0xB1  /* Frame Rate Control (Normal Mode) */
#define CMD_FRMCTR2     0xB2  /* Frame Rate Control (Idle Mode) */
#define CMD_FRMCTR3     0xB3  /* Frame Rate Control (Partial Mode) */
#define CMD_INVCTR      0xB4  /* Display Inversion Control */
#define CMD_PWCTR1      0xC0  /* Power Control 1 */
#define CMD_PWCTR2      0xC1  /* Power Control 2 */
#define CMD_PWCTR3      0xC2  /* Power Control 3 */
#define CMD_PWCTR4      0xC3  /* Power Control 4 */
#define CMD_PWCTR5      0xC4  /* Power Control 5 */
#define CMD_VMCTR1      0xC5  /* VCOM Control 1 */
#define CMD_GMCTRP1     0xE0  /* Positive Gamma Correction */
#define CMD_GMCTRN1     0xE1  /* Negative Gamma Correction */

struct st7735s_par {
	struct spi_device *spi;
	struct fb_info *info;
	struct gpio_desc *gpio_reset;
	struct gpio_desc *gpio_dc;
	u8 *spi_buf;
	u8 *vmem;
};

/* Fixed framebuffer information */
static struct fb_fix_screeninfo st7735s_fix = {
	.id          = "ST7735S",
	.type        = FB_TYPE_PACKED_PIXELS,
	.visual      = FB_VISUAL_TRUECOLOR,
	.xpanstep    = 0,
	.ypanstep    = 0,
	.ywrapstep   = 0,
	.line_length = ST7735S_WIDTH * ST7735S_BPP / 8,
	.accel       = FB_ACCEL_NONE,
};

/* Variable framebuffer information */
static struct fb_var_screeninfo st7735s_var = {
	.xres           = ST7735S_WIDTH,
	.yres           = ST7735S_HEIGHT,
	.xres_virtual   = ST7735S_WIDTH,
	.yres_virtual   = ST7735S_HEIGHT,
	.bits_per_pixel = ST7735S_BPP,
	.red            = { .offset = 11, .length = 5 },
	.green          = { .offset = 5,  .length = 6 },
	.blue           = { .offset = 0,  .length = 5 },
	.transp         = { .offset = 0,  .length = 0 },
	.activate       = FB_ACTIVATE_NOW,
	.height         = -1,
	.width          = -1,
	.vmode          = FB_VMODE_NONINTERLACED,
};

/* SPI write helpers */
static inline void st7735s_write_cmd(struct st7735s_par *par, u8 cmd)
{
	gpiod_set_value(par->gpio_dc, 0);  /* Command mode */
	spi_write(par->spi, &cmd, 1);
}

static inline void st7735s_write_data(struct st7735s_par *par, 
                                       const u8 *data, size_t len)
{
	gpiod_set_value(par->gpio_dc, 1);  /* Data mode */
	spi_write(par->spi, data, len);
}

static inline void st7735s_write_data_byte(struct st7735s_par *par, u8 data)
{
	st7735s_write_data(par, &data, 1);
}

/* Hardware reset */
static void st7735s_reset(struct st7735s_par *par)
{
	gpiod_set_value(par->gpio_reset, 1);
	msleep(1);
	gpiod_set_value(par->gpio_reset, 0);
	msleep(10);
	gpiod_set_value(par->gpio_reset, 1);
	msleep(120);
}

/* Display initialization - Android 4.4 sequence */
static int st7735s_init_display(struct st7735s_par *par)
{
	u8 data[16];

	dev_info(&par->spi->dev, "Initializing ST7735S (Android 4.4 sequence)\n");

	/* Hardware reset */
	st7735s_reset(par);

	/* 1. Sleep Out + 150ms delay */
	st7735s_write_cmd(par, CMD_SLPOUT);
	msleep(150);

	/* 2. Memory Access Control = 0x00 */
	st7735s_write_cmd(par, CMD_MADCTL);
	st7735s_write_data_byte(par, 0x00);

	/* 3. Column Address Set = 0,0,0,131 (0x83) */
	st7735s_write_cmd(par, CMD_CASET);
	data[0] = 0x00; data[1] = 0x00;
	data[2] = 0x00; data[3] = 0x83;
	st7735s_write_data(par, data, 4);

	/* 4. Row Address Set = 0,0,0,131 (0x83) */
	st7735s_write_cmd(par, CMD_RASET);
	data[0] = 0x00; data[1] = 0x00;
	data[2] = 0x00; data[3] = 0x83;
	st7735s_write_data(par, data, 4);

	/* 5. Interface Pixel Format = 0x05 (16-bit RGB565) */
	st7735s_write_cmd(par, CMD_COLMOD);
	st7735s_write_data_byte(par, 0x05);

	/* 6. Frame Rate Control 1 (Normal Mode) */
	st7735s_write_cmd(par, CMD_FRMCTR1);
	data[0] = 0x05; data[1] = 0x3c; data[2] = 0x3c;
	st7735s_write_data(par, data, 3);

	/* 7. Frame Rate Control 2 (Idle Mode) */
	st7735s_write_cmd(par, CMD_FRMCTR2);
	data[0] = 0x05; data[1] = 0x3c; data[2] = 0x3c;
	st7735s_write_data(par, data, 3);

	/* 8. Frame Rate Control 3 (Partial Mode) */
	st7735s_write_cmd(par, CMD_FRMCTR3);
	data[0] = 0x05; data[1] = 0x3c; data[2] = 0x3c;
	data[3] = 0x05; data[4] = 0x3c; data[5] = 0x3c;
	st7735s_write_data(par, data, 6);

	/* 9. Display Inversion Control = 0x03 */
	st7735s_write_cmd(par, CMD_INVCTR);
	st7735s_write_data_byte(par, 0x03);

	/* 10. Power Control 1 */
	st7735s_write_cmd(par, CMD_PWCTR1);
	data[0] = 0x0e; data[1] = 0x0e; data[2] = 0x04;
	st7735s_write_data(par, data, 3);

	/* 11. Power Control 2 = 0xc0 */
	st7735s_write_cmd(par, CMD_PWCTR2);
	st7735s_write_data_byte(par, 0xc0);

	/* 12. Power Control 3 */
	st7735s_write_cmd(par, CMD_PWCTR3);
	data[0] = 0x0d; data[1] = 0x00;
	st7735s_write_data(par, data, 2);

	/* 13. Power Control 4 */
	st7735s_write_cmd(par, CMD_PWCTR4);
	data[0] = 0x8d; data[1] = 0x2a;
	st7735s_write_data(par, data, 2);

	/* 14. Power Control 5 */
	st7735s_write_cmd(par, CMD_PWCTR5);
	data[0] = 0x8d; data[1] = 0xee;
	st7735s_write_data(par, data, 2);

	/* 15. VCOM Control 1 = 0x0c */
	st7735s_write_cmd(par, CMD_VMCTR1);
	st7735s_write_data_byte(par, 0x0c);

	/* 16. Positive Gamma Correction (from Android DTS) */
	st7735s_write_cmd(par, CMD_GMCTRP1);
	data[0]  = 0x0c; data[1]  = 0x1c; data[2]  = 0x0f; data[3]  = 0x18;
	data[4]  = 0x36; data[5]  = 0x2f; data[6]  = 0x27; data[7]  = 0x2a;
	data[8]  = 0x27; data[9]  = 0x25; data[10] = 0x2d; data[11] = 0x3c;
	data[12] = 0x00; data[13] = 0x05; data[14] = 0x03; data[15] = 0x10;
	st7735s_write_data(par, data, 16);

	/* 17. Negative Gamma Correction (from Android DTS) */
	st7735s_write_cmd(par, CMD_GMCTRN1);
	data[0]  = 0x0c; data[1]  = 0x1a; data[2]  = 0x09; data[3]  = 0x09;
	data[4]  = 0x26; data[5]  = 0x22; data[6]  = 0x1e; data[7]  = 0x25;
	data[8]  = 0x25; data[9]  = 0x25; data[10] = 0x2e; data[11] = 0x3b;
	data[12] = 0x00; data[13] = 0x05; data[14] = 0x03; data[15] = 0x10;
	st7735s_write_data(par, data, 16);

	/* 18. Display Inversion On */
	st7735s_write_cmd(par, CMD_INVON);

	/* 19. Display On + 120ms delay */
	st7735s_write_cmd(par, CMD_DISPON);
	msleep(120);

	dev_info(&par->spi->dev, "ST7735S initialized successfully\n");
	return 0;
}

/* Set display window */
static void st7735s_set_addr_window(struct st7735s_par *par,
                                     u16 xs, u16 ys, u16 xe, u16 ye)
{
	u8 data[4];

	/* Column Address Set */
	st7735s_write_cmd(par, CMD_CASET);
	data[0] = xs >> 8;
	data[1] = xs & 0xFF;
	data[2] = xe >> 8;
	data[3] = xe & 0xFF;
	st7735s_write_data(par, data, 4);

	/* Row Address Set */
	st7735s_write_cmd(par, CMD_RASET);
	data[0] = ys >> 8;
	data[1] = ys & 0xFF;
	data[2] = ye >> 8;
	data[3] = ye & 0xFF;
	st7735s_write_data(par, data, 4);

	/* Memory Write */
	st7735s_write_cmd(par, CMD_RAMWR);
}

/* Update display from vmem */
static void st7735s_update_display(struct st7735s_par *par)
{
	u16 *vmem16 = (u16 *)par->vmem;
	int i;

	/* Set full window */
	st7735s_set_addr_window(par, 0, 0, ST7735S_WIDTH - 1, ST7735S_HEIGHT - 1);

	/* Write pixel data */
	gpiod_set_value(par->gpio_dc, 1);  /* Data mode */

	/* Convert from CPU endian to big endian and send */
	for (i = 0; i < ST7735S_WIDTH * ST7735S_HEIGHT; i++) {
		u16 pixel = vmem16[i];
		par->spi_buf[i * 2] = pixel >> 8;
		par->spi_buf[i * 2 + 1] = pixel & 0xFF;
	}

	spi_write(par->spi, par->spi_buf, ST7735S_VMEM_SIZE);
}

/* Framebuffer operations */
static ssize_t st7735s_fb_write(struct fb_info *info, const char __user *buf,
                                 size_t count, loff_t *ppos)
{
	struct st7735s_par *par = info->par;
	unsigned long p = *ppos;
	void *dst;
	int err = 0;
	unsigned long total_size;

	total_size = info->fix.smem_len;

	if (p > total_size)
		return -EFBIG;

	if (count + p > total_size)
		count = total_size - p;

	if (!count)
		return -EINVAL;

	dst = (void __force *)(info->screen_base + p);

	if (copy_from_user(dst, buf, count))
		err = -EFAULT;

	if (!err)
		*ppos += count;

	st7735s_update_display(par);

	return (err) ? err : (ssize_t)count;
}

static void st7735s_fb_fillrect(struct fb_info *info,
                                 const struct fb_fillrect *rect)
{
	struct st7735s_par *par = info->par;

	sys_fillrect(info, rect);
	st7735s_update_display(par);
}

static void st7735s_fb_copyarea(struct fb_info *info,
                                 const struct fb_copyarea *area)
{
	struct st7735s_par *par = info->par;

	sys_copyarea(info, area);
	st7735s_update_display(par);
}

static void st7735s_fb_imageblit(struct fb_info *info,
                                  const struct fb_image *image)
{
	struct st7735s_par *par = info->par;

	sys_imageblit(info, image);
	st7735s_update_display(par);
}

static struct fb_ops st7735s_fbops = {
	.owner        = THIS_MODULE,
	.fb_read      = fb_sys_read,
	.fb_write     = st7735s_fb_write,
	.fb_fillrect  = st7735s_fb_fillrect,
	.fb_copyarea  = st7735s_fb_copyarea,
	.fb_imageblit = st7735s_fb_imageblit,
};

/* SPI probe */
static int st7735s_probe(struct spi_device *spi)
{
	struct device *dev = &spi->dev;
	struct st7735s_par *par;
	struct fb_info *info;
	int ret;

	dev_info(dev, "ST7735S framebuffer driver probe\n");

	/* Allocate framebuffer info */
	info = framebuffer_alloc(sizeof(struct st7735s_par), dev);
	if (!info) {
		dev_err(dev, "Failed to allocate framebuffer\n");
		return -ENOMEM;
	}

	par = info->par;
	par->info = info;
	par->spi = spi;

	/* Get GPIOs from device tree */
	par->gpio_reset = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(par->gpio_reset)) {
		ret = PTR_ERR(par->gpio_reset);
		dev_err(dev, "Failed to get reset GPIO: %d\n", ret);
		goto err_free_fb;
	}

	par->gpio_dc = devm_gpiod_get(dev, "dc", GPIOD_OUT_LOW);
	if (IS_ERR(par->gpio_dc)) {
		ret = PTR_ERR(par->gpio_dc);
		dev_err(dev, "Failed to get DC GPIO: %d\n", ret);
		goto err_free_fb;
	}

	/* Allocate video memory */
	par->vmem = vzalloc(ST7735S_VMEM_SIZE);
	if (!par->vmem) {
		dev_err(dev, "Failed to allocate video memory\n");
		ret = -ENOMEM;
		goto err_free_fb;
	}

	/* Allocate SPI buffer */
	par->spi_buf = devm_kzalloc(dev, ST7735S_VMEM_SIZE, GFP_KERNEL);
	if (!par->spi_buf) {
		ret = -ENOMEM;
		goto err_free_vmem;
	}

	/* Setup framebuffer info */
	info->screen_base = (char __force __iomem *)par->vmem;
	info->fbops = &st7735s_fbops;
	info->fix = st7735s_fix;
	info->fix.smem_start = (unsigned long)par->vmem;
	info->fix.smem_len = ST7735S_VMEM_SIZE;
	info->var = st7735s_var;
	info->flags = FBINFO_FLAG_DEFAULT | FBINFO_VIRTFB;
	info->pseudo_palette = NULL;

	/* Initialize display */
	ret = st7735s_init_display(par);
	if (ret < 0) {
		dev_err(dev, "Failed to initialize display\n");
		goto err_free_vmem;
	}

	/* Register framebuffer */
	ret = register_framebuffer(info);
	if (ret < 0) {
		dev_err(dev, "Failed to register framebuffer: %d\n", ret);
		goto err_free_vmem;
	}

	spi_set_drvdata(spi, info);

	dev_info(dev, "ST7735S framebuffer registered: %s (/dev/fb%d)\n",
	         info->fix.id, info->node);
	dev_info(dev, "Resolution: %dx%d @ %dbpp\n",
	         info->var.xres, info->var.yres, info->var.bits_per_pixel);

	return 0;

err_free_vmem:
	vfree(par->vmem);
err_free_fb:
	framebuffer_release(info);
	return ret;
}

static void st7735s_remove(struct spi_device *spi)
{
	struct fb_info *info = spi_get_drvdata(spi);
	struct st7735s_par *par = info->par;

	unregister_framebuffer(info);
	vfree(par->vmem);
	framebuffer_release(info);

	dev_info(&spi->dev, "ST7735S framebuffer removed\n");
}

/* Device tree matching */
static const struct of_device_id st7735s_of_match[] = {
	{ .compatible = "sitronix,st7735s-fb" },
	{ }
};
MODULE_DEVICE_TABLE(of, st7735s_of_match);

/* SPI device ID */
static const struct spi_device_id st7735s_id[] = {
	{ "st7735s", 0 },
	{ }
};
MODULE_DEVICE_TABLE(spi, st7735s_id);

static struct spi_driver st7735s_driver = {
	.driver = {
		.name           = DRIVER_NAME,
		.of_match_table = st7735s_of_match,
	},
	.id_table = st7735s_id,
	.probe    = st7735s_probe,
	.remove   = st7735s_remove,
};

module_spi_driver(st7735s_driver);

MODULE_DESCRIPTION("ST7735S Framebuffer Driver for MSM8916");
MODULE_AUTHOR("OpenWRT Builder");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("spi:st7735s");
