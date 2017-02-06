from Quartz.CoreGraphics import *
# from colour import xy_to_CCT_Hernandez1999, XYZ_to_xy, sRGB_to_XYZ
from time import sleep
# import struct

# lasttemp = None

while True:

  image = CGDisplayCreateImage(CGMainDisplayID())

  context = CGBitmapContextCreate(
    None, 1, 1,
    CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image),
    CGImageGetColorSpace(image), CGImageGetAlphaInfo(image)
  )

  CGContextSetInterpolationQuality(context, kCGInterpolationMedium)

  CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), image)

  data = CGBitmapContextGetData(context)
  r, g, b = data[1:4]
  print("{},{},{}".format(ord(r), ord(g), ord(b)))
  sleep(0.1)

# CGImageRef imgRef = CGBitmapContextCreateImage(context)
