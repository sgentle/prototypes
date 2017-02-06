from Quartz.CoreGraphics import *
from StringIO import StringIO
from PIL.ImageCms import ImageCmsProfile


colorSpace = CGDisplayCopyColorSpace(CGMainDisplayID())
print(colorSpace)
iccdata = StringIO(CGColorSpaceCopyICCProfile(colorSpace))

# print(isinstance(iccdata, str))
profile = ImageCmsProfile(iccdata).profile

# print dir(profile)
# print(profile.model)
# print(profile.profile_id)
print(profile.profile_description)
# print(profile.product_description)
print(profile.media_white_point_temperature)
print(profile.media_white_point)
print(profile.chromatic_adaptation)
# print(profile.__slots__)

# for p in dir(profile):
    # print p, getattr(profile, p)
