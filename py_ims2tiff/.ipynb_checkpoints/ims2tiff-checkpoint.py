import os
from PyQt5 import QtGui, QtCore, QtWidgets
import numpy as N
import threading
import tifffile


class filedropSignalHelper(QtCore.QObject):
    event_Dropped = QtCore.pyqtSignal(object)

class DragDropListView(QtWidgets.QListWidget):
    def __init__(self, type, parent=None):
        super(DragDropListView, self).__init__(parent)
        self.setAcceptDrops(True)
        self.setSelectionMode(QtWidgets.QAbstractItemView.ExtendedSelection)
        self._signal_helper = filedropSignalHelper()
        self.event_Dropped = self._signal_helper.event_Dropped

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.accept()
        else:
            event.ignore()

    def dragMoveEvent(self, event):
        if event.mimeData().hasUrls():
            event.setDropAction(QtCore.Qt.CopyAction)
            event.accept()
        else:
            event.ignore()

    def dropEvent(self, event):
        d = event.mimeData()
        if event.mimeData().hasUrls():
            event.setDropAction(QtCore.Qt.CopyAction)
            event.accept()
            links = []
            for url in event.mimeData().urls():
                links.append(str(url.toLocalFile()))
            self.event_Dropped.emit(links)
        else:
            print("Invalid URL")
            event.ignore()

    def keyPressEvent(self, event):
        super(DragDropListView, self).keyPressEvent(event)
        if event.key() == QtCore.Qt.Key_Delete:
            for item in self.selectedItems():
                row = self.row(item)
                self.takeItem(row)
                del item

class Converter(QtCore.QObject):
    eventFinished = QtCore.pyqtSignal() # for sigaling processing thread's end 

    def threadEntry(self, listOfFileNames, dirToSaveIn):
        threading.Thread(target=self.threadFunction,
                         args = (listOfFileNames, dirToSaveIn)).start()

    def threadFunction(self, listOfFiles, dirToSaveIn):
        for fileName in listOfFiles:
            ims2tiff(fileName, dirToSaveIn)

        self.eventFinished.emit()
        

class mainGUI(QtWidgets.QFrame):
    ''' '''

    def __init__(self):

        self.viewer_count = 0
        QtWidgets.QFrame.__init__(self)
        self.setWindowTitle("Imaris-to-TIFF batch conversion")
        self.setMinimumSize(400, 400)

        layout = QtWidgets.QVBoxLayout()

        # 1. The listview to be populated with directories:
        self.listbox = DragDropListView(self)
        label = QtWidgets.QLabel("Files to be converted (drag and drop here):")
        layout.addWidget(label)
        layout.addWidget(self.listbox)
        self.listbox.setToolTip('Drag input files and drop here;\npress "delete" to remove selected files\nmultiple selections are allowed')

        layout2 = QtWidgets.QHBoxLayout()

        # 4. Button to start processing all data files:
        self.processBut = QtWidgets.QPushButton('Batch Convert', self)
        self.processBut.clicked.connect(self.onProcess)

        layout2.addWidget(self.processBut)

        self.dirOpenBut = QtWidgets.QPushButton('Select save folder', self)
        self.dirOpenBut.clicked.connect(self.onDirOpen)
        self.dirToSaveIn = ''

        layout2.addWidget(self.dirOpenBut)
        layout.addLayout(layout2)

        self.statbar = QtWidgets.QStatusBar(self)
        self.statusLabel = QtWidgets.QLabel('Ready')
        self.statbar.addWidget(self.statusLabel, 1)
        self.saveFolderLabel = QtWidgets.QLabel('Save folder not specified')
        # self.saveFolderLabel.setScaledContents(True)
        self.statbar.addWidget(self.saveFolderLabel, 1)
        layout.addWidget(self.statbar)

        self.setLayout(layout)

        self.listbox.event_Dropped.connect(self.onFileDropped)
        self.processBut.setFocus()

        self.converterThread = Converter()
        self.converterThread.eventFinished.connect(self.onTaskFinished)


    def onProcess(self):
        '''
        Responds to "Process" button pressed
        1. Check validity of Wiener constant inputs
        2. Check if "TIRF" is checked
        3. Loop over the listed folders and launch sirecon subprocess for each
        '''
        if self.listbox.count() == 0:
            QtWidgets.QMessageBox.warning(self, "Stop",
                                      "No input file has been specified",
                                      QtWidgets.QMessageBox.Ok, QtWidgets.QMessageBox.NoButton)
            return

        self.processBut.setEnabled(False)
        self.statusLabel.setText('Busy...')
        fileNames = []
        for ind in range(self.listbox.count()):
            fileNames.append(str(self.listbox.item(ind).text()))
        self.converterThread.threadEntry(fileNames, self.dirToSaveIn)

    def onTaskFinished(self):
        for ind in range(self.listbox.count()):
            item = self.listbox.takeItem(0)
            del item
        self.processBut.setEnabled(True)
        self.statusLabel.setText('Ready')
        
    def onDirOpen(self):
        dlg = QtWidgets.QFileDialog()
        dlg.setFileMode(QtWidgets.QFileDialog.Directory)
        dirnames = []
        if dlg.exec_():
            dirnames = dlg.selectedFiles()
        if len(dirnames) > 0:
            self.dirToSaveIn = dirnames[0]
            self.saveFolderLabel.setText(self.dirToSaveIn)

    def onFileDropped(self, links):
        for url in links:
            if os.path.exists(url):
                # If this file is not on the list yet, add it to the list:
                if len(self.listbox.findItems(url, QtCore.Qt.MatchExactly)) == 0:
                    item = QtWidgets.QListWidgetItem(url, self.listbox)

def ims2tiff(imsfile, dirToSaveIn):
    import imsparser
    ims = imsparser.imsparser(imsfile)
    bigT = True if ims.nX * ims.nY * ims.nZ * ims.nC * ims.nT * 2 > 3758096384 else False  # > 3.5GB make a bigTiff
    md = {
        'unit': 'um',
        'spacing': ims.dz,
        'finterval': ims.dT,
        'hyperstack': 'true',
        'mode': 'color',
        'loop': 'true'
    }
    # ijmd = { 
    #     "Labels": [str(w) for w in ims.wavelengths]
    # this label only appears in section 0 image
    # }


    if dirToSaveIn == '':
        outfile = imsfile.replace(".ims", ".tif")
    elif not os.path.exists(dirToSaveIn):
        print("Error: save folder doesn't exist")
        return
    else:
        basename = os.path.basename(imsfile)
        outfile = os.path.join(dirToSaveIn, basename.replace('.ims', '.tif'))

    def genTags4Colors(colorsList, rangeList):
        col_maps = []
        for ci in range(len(colorsList)):
            colormap = N.zeros((3,256), dtype = 'uint8')
            colorRGBfloat = colorsList[ci]
            for rgb in range(3):
                if colorRGBfloat[rgb] > 0:
                    colormap[rgb, :] = N.round(N.arange(256) * colorRGBfloat[rgb])
        
            col_maps.append(colormap)

        displayRanges = N.array(rangeList, dtype='float64')
        return {'LUTs': col_maps, 'Ranges': displayRanges.flatten()}

    ijmd = genTags4Colors(ims.displayColors, ims.displayRanges)
    md.update(ijmd)

    ## tifffile requires array organized in TZCYX order
    res = N.empty((ims.nZ, ims.nC, ims.nY, ims.nX), N.uint16)

    bigT = False ### Lin: BigTIFF and ImageJ are incompatible, and somehow tifffile ...
    ## ... has >4GB covered, even with a "truncating ImageJ file" warning. Strange!!

    with tifffile.TiffWriter(outfile, bigtiff=bigT, imagej=True) as tifReg:
        toBreak = False
        for t in range(ims.nT):
            for c in range(ims.nC):
                try:
                    rawImage = ims.load1stack(t, c)
                except KeyError:
                    print("Invalid time point %d channel %d in IMS file \"%s\" encountered" %
                          (t+1, c+1, os.path.basename(imsfile)) )
                    print("This and the rest of time points will be ignored")
                    toBreak = True
                    break
                try:
                    res[:,c,:,:] = rawImage
                except ValueError:
                    print("Shape mismatch between rawImage and res; nothing was performed")
                    tifReg.close()
                    os.remove(outfile)
                    return
            if not toBreak:
                tifReg.write(res, resolution=(1/ims.dxy, 1/ims.dxy), metadata = md)
            else:
                 break
    
if __name__ == '__main__':
    # Load defaults, such as Windows batch file names, into global namespace:
    # execfile(os.path.dirname(os.path.abspath(__file__))+'/settings.py', globals())

    app = QtWidgets.QApplication([])
    window = mainGUI()
    window.show()
    app.exec_()
