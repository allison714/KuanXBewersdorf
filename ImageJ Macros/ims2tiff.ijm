// Converting .ims -> .tiff z-slices (with auto B/C)
// A. Cairns
// 06.05.24

// Have ImageJ run this macro without opening windows
setBatchMode(true) 
t0 = getTime(); // in ms
print("Start Time: " + t0);

// ---- THE ONLY PART OF THE MACRO YOU NEED TO CHANGE ----
	// Input folder containing the .ims files
inputFolder = "Z:/Joerg/ims/";
	// Output folder/ save path for the TIFFs
savePath = "Z:/Joerg/ims2TIFF/"; 	 
// --------------------------------------------------------

// Get a list of all files in the folder
list = getFileList(inputFolder);

// Loop through each file in the folder
for (i = 0; i < list.length; i++) {
    // Extract the file name without extension
    fileNameWithExtension = list[i];
    dotIndex = fileNameWithExtension.lastIndexOf(".");
    fileName = fileNameWithExtension.substring(0, dotIndex);

    // Construct the full file path
    filePath = inputFolder + fileNameWithExtension;
    print("---");
    print("Opening" + filePath);
    print("---");

    // Open the file using Bio-Formats Importer
    run("Bio-Formats Importer", "open=" + filePath + " color_mode=Default view=Hyperstack stack_order=XYCZT use_virtual_stack series_1");

    // Get stack dimensions
    Stack.getDimensions(width, height, channels, slices, frames);

    // Loop through each channel
    for (c = 1; c <= channels; c++) {
        // Set the current channel
        Stack.setChannel(c);
        Stack.setSlice(floor(slices/2));
        resetMinAndMax();
        run("Enhance Contrast", "saturated=0.35");  // Auto adjust B/C
    }
    // Construct the save path for this channel
    savePath2 = savePath + fileName + ".tif";

    // Save the file with the the channel in the name as a TIFF
    saveAs("Tiff", savePath2);
    print("---");
    print("Saving " + savePath2);
    print("---");

    // Close the opened image - this can probably be removed
    close();
}
setBatchMode(false)
tf = getTime();
print("Start Time: " + tf);
ts = (tf - t0)/1000; // seconds
t = ts/ 60; // minutes
print("Total Time: " + t);