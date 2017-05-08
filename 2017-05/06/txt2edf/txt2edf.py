from __future__ import division, print_function, absolute_import

import os
import sys
import numpy as np
import json
import pyedflib

infilename = sys.argv[1] or 'in.txt'
outfilename = sys.argv[2] or 'out.edf'

CHANNELS = ['AF3', 'AF4', 'F7', 'F8', 'F3', 'F4', 'FC5', 'FC6', 'T7', 'T8', 'P7', 'P8', 'O1', 'O2']

with open(infilename, 'r') as f:
    lines = f.readlines() 
    data = [[json.loads(line)[chan] for chan in CHANNELS] for line in lines]
    npdata = np.array(data).transpose()

    file_duration = len(lines) / 128
    f = pyedflib.EdfWriter(outfilename, len(CHANNELS),
                           file_type=pyedflib.FILETYPE_BDFPLUS)


    channel_info = [{'label': name, 'dimension': 'uV', 'sample_rate': 128, 'physical_max': 106496, 'physical_min': -106496, 'digital_max': 8192, 'digital_min': -8192, 'transducer': '', 'prefilter': ''} for name in CHANNELS]
    data_list = []


    f.setSignalHeaders(channel_info)
    f.writeSamples(npdata)
    #f.writeAnnotation(0, -1, "Recording starts")
    #f.writeAnnotation(298, -1, "Test 1")
    #f.writeAnnotation(294.99, -1, "pulse 1")
    #f.writeAnnotation(295.9921875, -1, "pulse 2")
    #f.writeAnnotation(296.99078341013825, -1, "pulse 3")
    #f.writeAnnotation(600, -1, "Recording ends")
    f.close()
    del f
