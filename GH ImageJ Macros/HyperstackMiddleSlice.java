// Converting .ims -> .tiff z-slices (with auto B/C)
// A. Cairns
// 06.05.24

// Have ImageJ run this macro without opening windows
setBatchMode(true) 

// ---- THE ONLY PART OF THE MACRO YOU NEED TO CHANGE ----
	// Input folder containing the .ims files
inputFolder = "E:/ims2/";
	// Output folder/ save path for the TIFFs
savePath = "E:/TIFF Slice/"; 	 
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
	print("Opening " + filePath);
	print("---");
	
	// Create an ImageInfo object using an external class loader
	imgInfo = new loci.formats.tools.ImageInfo();
	imgInfo.setId(filePath);

	// Get the number of slices from metadata
	slices = imgInfo.getImageCount();

	// Calculate middleSlice
	middleSlice = floor(slices/2);
	
	
    // Open the file using Bio-Formats Importer
    run("Bio-Formats Importer", "open=" + filePath + "color_mode=Default view=Hyperstack stack_order=XYCZT use_virtual_stack series_1 slice_1=" + slice/2);
	
	// Get stack dimensions
    Stack.getDimensions(width, height, channels, slices, frames);
	// middleSlice = floor(slices/2)
	
    // Loop through each channel
    for (c = 1; c <= channels; c++) {
        // Set the current channel
        Stack.setChannel(c);
        // ~~~ Stack.setSlice(middleSlice);
        
        // Auto adjust B/C
        resetMinAndMax();
        run("Enhance Contrast", "saturated=0.35");  
   
    // Construct the save path for this channel
    savePath2 = savePath + fileName + "_slice_" + middleSlice + ".tif";
    

    // Save the file with the the channel in the name as a TIFF
    saveAs("Tiff", savePath2);
     }
    print("---");
	print("Saved " + savePath2);
	print("---");
	
    // Close the opened image - this can probably be removed
    close();
}
setBatchMode(false)