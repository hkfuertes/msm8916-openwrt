// SPDX-License-Identifier: GPL-2.0+
/*
 * DRM driver for Sitronix ST7735S display panels
 *
 * Based on st7735r driver by David Lechner
 */

#include <linux/backlight.h>
#include <linux/delay.h>
#include <linux/dma-buf.h>
#include <linux/gpio/consumer.h>
#include <linux/module.h>
#include <linux/property.h>
#include <linux/spi/spi.h>
#include <video/mipi_display.h>

#include <drm/drm_atomic_helper.h>
#include <drm/drm_drv.h>
#include <drm/drm_fbdev_dma.h>
#include <drm/drm_gem_atomic_helper.h>
#include <drm/drm_gem_dma_helper.h>
#include <drm/drm_managed.h>
#include <drm/drm_mipi_dbi.h>

#define ST7735S_FRMCTR1		0xb1
#define ST7735S_FRMCTR2		0xb2
#define ST7735S_FRMCTR3		0xb3
#define ST7735S_INVCTR		0xb4
#define ST7735S_PWCTR1		0xc0
#define ST7735S_PWCTR2		0xc1
#define ST7735S_PWCTR3		0xc2
#define ST7735S_PWCTR4		0xc3
#define ST7735S_PWCTR5		0xc4
#define ST7735S_VMCTR1		0xc5
#define ST7735S_GAMCTRP1	0xe0
#define ST7735S_GAMCTRN1	0xe1

#define ST7735S_MY	BIT(7)
#define ST7735S_MX	BIT(6)
#define ST7735S_MV	BIT(5)
#define ST7735S_RGB	BIT(3)

struct st7735s_cfg {
	const struct drm_display_mode mode;
	unsigned int left_offset;
	unsigned int top_offset;
	unsigned int write_only:1;
	unsigned int rgb:1;
};

struct st7735s_priv {
	struct mipi_dbi_dev dbidev;
	const struct st7735s_cfg *cfg;
};

static void st7735s_pipe_enable(struct drm_simple_display_pipe *pipe,
				struct drm_crtc_state *crtc_state,
				struct drm_plane_state *plane_state)
{
	struct mipi_dbi_dev *dbidev = drm_to_mipi_dbi_dev(pipe->crtc.dev);
	struct st7735s_priv *priv = container_of(dbidev, struct st7735s_priv,
						 dbidev);
	struct mipi_dbi *dbi = &dbidev->dbi;
	int ret, idx;
	u8 addr_mode;

	if (!drm_dev_enter(pipe->crtc.dev, &idx))
		return;

	DRM_DEBUG_KMS("\n");

	ret = mipi_dbi_poweron_reset(dbidev);
	if (ret)
		goto out_exit;

	/* Secuencia de inicialización basada en Android DTS */
	
	/* Frame rate control - normal mode */
	mipi_dbi_command(dbi, ST7735S_FRMCTR1, 0x05, 0x3c, 0x3c);
	
	/* Frame rate control - idle mode */
	mipi_dbi_command(dbi, ST7735S_FRMCTR2, 0x05, 0x3c, 0x3c);
	
	/* Frame rate control - partial mode */
	mipi_dbi_command(dbi, ST7735S_FRMCTR3, 0x05, 0x3c, 0x3c,
			 0x05, 0x3c, 0x3c);
	
	/* Display inversion control */
	mipi_dbi_command(dbi, ST7735S_INVCTR, 0x03);
	
	/* Power control */
	mipi_dbi_command(dbi, ST7735S_PWCTR1, 0x0e, 0x0e, 0x04);
	mipi_dbi_command(dbi, ST7735S_PWCTR2, 0xc0);
	mipi_dbi_command(dbi, ST7735S_PWCTR3, 0x0d, 0x00);
	mipi_dbi_command(dbi, ST7735S_PWCTR4, 0x8d, 0x2a);
	mipi_dbi_command(dbi, ST7735S_PWCTR5, 0x8d, 0xee);
	
	/* VCOM control */
	mipi_dbi_command(dbi, ST7735S_VMCTR1, 0x0c);

	/* Memory access control - adaptado según rotación */
	switch (dbidev->rotation) {
	default:
		addr_mode = ST7735S_MX | ST7735S_MY;
		break;
	case 90:
		addr_mode = ST7735S_MX | ST7735S_MV;
		break;
	case 180:
		addr_mode = 0;
		break;
	case 270:
		addr_mode = ST7735S_MY | ST7735S_MV;
		break;
	}

	if (priv->cfg->rgb)
		addr_mode |= ST7735S_RGB;

	mipi_dbi_command(dbi, MIPI_DCS_SET_ADDRESS_MODE, addr_mode);

	/* Display inversion ON (0x21 del DTS Android) */
	mipi_dbi_command(dbi, MIPI_DCS_ENTER_INVERT_MODE);

	/* Positive gamma correction */
	mipi_dbi_command(dbi, ST7735S_GAMCTRP1,
			 0x0c, 0x1c, 0x0f, 0x18, 0x36, 0x2f, 0x27, 0x2a,
			 0x27, 0x25, 0x2d, 0x3c, 0x00, 0x05, 0x03, 0x10);
	
	/* Negative gamma correction */
	mipi_dbi_command(dbi, ST7735S_GAMCTRN1,
			 0x0c, 0x1a, 0x09, 0x09, 0x26, 0x22, 0x1e, 0x25,
			 0x25, 0x25, 0x2e, 0x3b, 0x00, 0x05, 0x03, 0x10);

	/* Pixel format: 16-bit color (0x3a 0x05 = RGB565) */
	mipi_dbi_command(dbi, MIPI_DCS_SET_PIXEL_FORMAT,
			 MIPI_DCS_PIXEL_FMT_16BIT);

	/* Column address set */
	mipi_dbi_command(dbi, MIPI_DCS_SET_COLUMN_ADDRESS,
			 0x00, 0x00, 0x00, 0x83);
	
	/* Row address set */
	mipi_dbi_command(dbi, MIPI_DCS_SET_PAGE_ADDRESS,
			 0x00, 0x00, 0x00, 0x83);

	/* Exit sleep mode */
	mipi_dbi_command(dbi, MIPI_DCS_EXIT_SLEEP_MODE);
	msleep(120);

	/* Display on */
	mipi_dbi_command(dbi, MIPI_DCS_SET_DISPLAY_ON);
	msleep(120);

	mipi_dbi_enable_flush(dbidev, crtc_state, plane_state);

out_exit:
	drm_dev_exit(idx);
}

static const struct drm_simple_display_pipe_funcs st7735s_pipe_funcs = {
	DRM_MIPI_DBI_SIMPLE_DISPLAY_PIPE_FUNCS(st7735s_pipe_enable),
};

/* Configuración para panel 132x132 (128x128 área visible) */
static const struct st7735s_cfg st7735s_128x128_cfg = {
	.mode		= { DRM_SIMPLE_MODE(128, 128, 22, 22) },
	.left_offset	= 2,
	.top_offset	= 1,
	.write_only	= false,
	.rgb		= false,  /* BGR order por defecto */
};

DEFINE_DRM_GEM_DMA_FOPS(st7735s_fops);

static const struct drm_driver st7735s_driver = {
	.driver_features	= DRIVER_GEM | DRIVER_MODESET | DRIVER_ATOMIC,
	.fops			= &st7735s_fops,
	DRM_GEM_DMA_DRIVER_OPS_VMAP,
	.debugfs_init		= mipi_dbi_debugfs_init,
	.name			= "st7735s",
	.desc			= "Sitronix ST7735S",
	.date			= "20251013",
	.major			= 1,
	.minor			= 0,
};

static const struct of_device_id st7735s_of_match[] = {
	{ .compatible = "sitronix,st7735s", .data = &st7735s_128x128_cfg },
	{ },
};
MODULE_DEVICE_TABLE(of, st7735s_of_match);

static const struct spi_device_id st7735s_id[] = {
	{ "st7735s", (uintptr_t)&st7735s_128x128_cfg },
	{ },
};
MODULE_DEVICE_TABLE(spi, st7735s_id);

static int st7735s_probe(struct spi_device *spi)
{
	struct device *dev = &spi->dev;
	const struct st7735s_cfg *cfg;
	struct mipi_dbi_dev *dbidev;
	struct st7735s_priv *priv;
	struct drm_device *drm;
	struct mipi_dbi *dbi;
	struct gpio_desc *dc;
	u32 rotation = 0;
	int ret;

	cfg = device_get_match_data(&spi->dev);
	if (!cfg)
		cfg = (void *)spi_get_device_id(spi)->driver_data;

	priv = devm_drm_dev_alloc(dev, &st7735s_driver,
				  struct st7735s_priv, dbidev.drm);
	if (IS_ERR(priv))
		return PTR_ERR(priv);

	dbidev = &priv->dbidev;
	priv->cfg = cfg;

	dbi = &dbidev->dbi;
	drm = &dbidev->drm;

	dbi->reset = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(dbi->reset))
		return dev_err_probe(dev, PTR_ERR(dbi->reset),
				     "Failed to get GPIO 'reset'\n");

	dc = devm_gpiod_get(dev, "dc", GPIOD_OUT_LOW);
	if (IS_ERR(dc))
		return dev_err_probe(dev, PTR_ERR(dc),
				     "Failed to get GPIO 'dc'\n");

	dbidev->backlight = devm_of_find_backlight(dev);
	if (IS_ERR(dbidev->backlight))
		return PTR_ERR(dbidev->backlight);

	device_property_read_u32(dev, "rotation", &rotation);

	ret = mipi_dbi_spi_init(spi, dbi, dc);
	if (ret)
		return ret;

	if (cfg->write_only)
		dbi->read_commands = NULL;

	dbidev->left_offset = cfg->left_offset;
	dbidev->top_offset = cfg->top_offset;

	ret = mipi_dbi_dev_init(dbidev, &st7735s_pipe_funcs, &cfg->mode,
				rotation);
	if (ret)
		return ret;

	drm_mode_config_reset(drm);

	ret = drm_dev_register(drm, 0);
	if (ret)
		return ret;

	spi_set_drvdata(spi, drm);

	drm_fbdev_dma_setup(drm, 16);

	return 0;
}

static void st7735s_remove(struct spi_device *spi)
{
	struct drm_device *drm = spi_get_drvdata(spi);

	drm_dev_unplug(drm);
	drm_atomic_helper_shutdown(drm);
}

static void st7735s_shutdown(struct spi_device *spi)
{
	drm_atomic_helper_shutdown(spi_get_drvdata(spi));
}

static struct spi_driver st7735s_spi_driver = {
	.driver = {
		.name = "st7735s",
		.of_match_table = st7735s_of_match,
	},
	.id_table = st7735s_id,
	.probe = st7735s_probe,
	.remove = st7735s_remove,
	.shutdown = st7735s_shutdown,
};
module_spi_driver(st7735s_spi_driver);

MODULE_DESCRIPTION("Sitronix ST7735S DRM driver");
MODULE_AUTHOR("Based on st7735r by David Lechner");
MODULE_LICENSE("GPL");
