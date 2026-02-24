## Create boot image for framebuffer
We are converting the image using `ffmpeg`. Ensure you have it installed.
```
ffmpeg -i <image> -vf "scale=128:128" -pix_fmt rgb565le -f rawvideo <output>.fb
```