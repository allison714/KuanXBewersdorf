// Converting .ims -> .tiff z-slices (with auto B/C)
// A. Cairns
// 06.05.24
fileName = "ms8ai_1_FusionStitcher"

filePath = "D:/Dragonfly/" + fileName + ".ims";
savePath = "D:/Test/" + fileName;

// Open as a virtual hyperstack & split channels
// run("Bio-Formats Importer", "open=" + filePath + " autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT use_virtual_stack");
run("Bio-Formats Importer", "open=" + filePath + " color_mode=Default view=Hyperstack stack_order=XYCZT use_virtual_stack series_1");

Stack.getDimensions(width, height, channels, slices, frames)
//print(slices);

for (c=1; c<=channels; c++) {
  Stack.setChannel(c);
  Stack.setSlice(floor(slices/2));
  resetMinAndMax();
  run("Enhance Contrast", "saturated=0.35");  // Auto adjust B/C

  savePath2 = savePath + "_ch_" + c + ".tif";
  saveAs("Tiff", savePath2);
}

    // Save each z slices of each channel as a .tiff without displaying it
    // for (z = 1; z <= slices; z++) {
        // selectWindow("C" + c);
        // setSlice(z);
        // saveAs("Tiff", "D:/Test/Slices" + c + "_slice" + z + ".tiff");  // Change to "OME-Tiff" if needed
    // }

