// ImageJ Macro to Measure PSF (Gaussian Fitting) for 5 Selected Points in XY
macro "Measure PSF in XY (Gaussian Fit, Corrected FWHM)" {
    origTitle = getTitle();
    voxelSizeXY = 0.1005; // XY voxel size in microns

    // Initialize results table
    run("Clear Results");
    print("PSF Measurements (XY)");
    print("Line\tSigma (µm)\tFWHM (µm)\tFWHM (Pixels)");

    for (i = 1; i <= 5; i++) {
        print("Draw a line across PSF spot #" + i + " and press OK.");
        waitForUser("Draw a line across the PSF spot and click OK.");
        
        // Extract and fit Gaussian
        run("Plot Profile");
        run("Gaussian Fit");

        // Extract Sigma from Gaussian fit
        sigma_um = getResult("Sigma", i - 1);  // Extract sigma (already in microns)
        fwhm_um = sigma_um * 2.35;  // Compute FWHM in microns
        fwhm_pixels = fwhm_um / voxelSizeXY;  // Convert to pixels

        print(i + "\t" + sigma_um + "\t" + fwhm_um + "\t" + fwhm_pixels);

        // Save image with overlay
        saveAs("TIFF", origTitle + "_line_" + i + ".tif");
    }
    
    print("PSF measurement completed. Check saved images.");
}
