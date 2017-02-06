from Quartz.CoreGraphics import *
from iccp import Profile, s15f16l
import struct
import colour

colorSpace = CGDisplayCopyColorSpace(CGMainDisplayID())
# print(colorSpace)
iccdata = str(CGColorSpaceCopyICCProfile(colorSpace))

profile = Profile().fromString(iccdata)

# print(profile.d)
vcgt = profile.tag['vcgt'][1]
# print(struct.unpack('>lllllllll', vcgt[4:]))
vcgtdata = s15f16l(vcgt[4:])
rgb = [vcgtdata[2], vcgtdata[5], vcgtdata[8]]
print("rgb", rgb)

print(colour.xy_to_CCT_Hernandez1999(colour.XYZ_to_xy(colour.sRGB_to_XYZ(rgb))))
