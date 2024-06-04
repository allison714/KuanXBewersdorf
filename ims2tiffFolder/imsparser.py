import h5py

def bStr2Int(bstr, func):
    # convert array of binary letters into an integer
    return func(''.join([s.decode() for s in bstr])) 

class imsparser:
    def __init__(self, filename):
        self.f = h5py.File(filename, 'r')

        #figure out how many channels there are:
        chlist = list(self.f['DataSet/ResolutionLevel 0/TimePoint 0'])
        self.nC = len(chlist)

        # figure out excitation wavelengths of the channels:
        datasetinfo = self.f['DataSetInfo']
        self.wavelengths = []
        self.displayColors = []
        self.displayRanges = []
        for c in range(self.nC):
            keyStr = 'Channel %d' % c
            channelInfo = datasetinfo[keyStr].attrs['LSMExcitationWavelength']
            try:
                self.wavelengths.append(bStr2Int(channelInfo[:3], int))
                #Lin added:
                displayColor = datasetinfo[keyStr].attrs['Color']
                self.displayColors.append( [float(ss) for ss in (bStr2Int(displayColor, str)).split()] )
            # except ValueError: # LSMExcitationWavelength is "unknown"
            except KeyError: # 'Color' key doesn't exist?
                self.wavelengths = 0
                self.displayColors.append([1.0, 1.0, 1.0])  # use gray scale map
            displayRange = datasetinfo[keyStr].attrs['ColorRange']
            self.displayRanges.append( [float(ss) for ss in (bStr2Int(displayRange, str)).split()] )
                

        # figure out number of time points, and XYZ dimensions
        tiList = list(self.f['DataSet/ResolutionLevel 0'])
        self.nT = len(tiList)
        if self.nT > 1:
            t1str = ''.join([s.decode() for s in self.f['DataSetInfo']['TimeInfo'].attrs['TimePoint1']])
            t2str = ''.join([s.decode() for s in self.f['DataSetInfo']['TimeInfo'].attrs['TimePoint2']])
            from dateutil import parser
            t1 = parser.parse(t1str)
            t2 = parser.parse(t2str)
            self.dT = (t2-t1).total_seconds()
        else:
            self.dT = 0.

        self.nX = bStr2Int(datasetinfo['Image'].attrs['X'], int)
        self.nY = bStr2Int(datasetinfo['Image'].attrs['Y'], int)
        self.nZ = bStr2Int(datasetinfo['Image'].attrs['Z'], int)

        # figure out voxel sizes
        extmax = bStr2Int(datasetinfo['Image'].attrs['ExtMax0'], float)
        extmin = bStr2Int(datasetinfo['Image'].attrs['ExtMin0'], float)
        self.dxy = (extmax-extmin) / (self.nX-1)
        extmax = bStr2Int(datasetinfo['Image'].attrs['ExtMax2'], float)
        extmin = bStr2Int(datasetinfo['Image'].attrs['ExtMin2'], float)
        if self.nZ>1:
            self.dz = (extmax-extmin) / (self.nZ-1)
        else:
            self.dz = 1

    def load1stack(self, ti, ci):
        keyStr = 'DataSet/ResolutionLevel 0/TimePoint %d/Channel %d' % (ti, ci)
        import numpy
        array = numpy.asarray(self.f[keyStr]["Data"])
        if array.shape[0] > self.nZ: # Dragonfly sometimes pads with extra 0-value sections
            array = array[:self.nZ]
        if array.shape[1] > self.nY: # Dragonfly sometimes pads with extra 0-value columns
            array = array[:,:self.nY,:]
        if array.shape[2] > self.nX: # Dragonfly sometimes pads with extra 0-value rows
            array = array[:,:,:self.nX]
        return array

    def close(self):
        self.f.close()
