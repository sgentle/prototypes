from Quartz.CoreGraphics import CGGetDisplayTransferByTable, CGMainDisplayID
from colour import xy_to_CCT_Hernandez1999, XYZ_to_xy, sRGB_to_XYZ
from time import sleep

lasttemp = None

while True:
  (_, red, green, blue, _) = CGGetDisplayTransferByTable(CGMainDisplayID(), 3, None, None, None, None)

  rgb = [red[2], green[2], blue[2]]
  # print("rgb", rgb)

  temp = xy_to_CCT_Hernandez1999(XYZ_to_xy(sRGB_to_XYZ(rgb)))
  if temp != lasttemp:
    print temp
    sleeptime = 0.1
  else:
    sleeptime = 1
  lasttemp = temp

  sleep(sleeptime)
