// ─── Batch Merge by **3‑digit** Suffix (000–087) ───
// MUST BE RGB Color, then saved as TIFF image sequences
// Outputs as a png
macro "Batch Merge by Suffix 000–087" {
    // 1) Ask for your folders and filename parts
    dir1      = getDirectory("Choose GREY channel folder");   // e.g. …/InvertedPan/
    dir2      = getDirectory("Choose CYAN channel folder");   // e.g. …/PSD95 sigma xyz 25 px/
    outDir    = getDirectory("Choose OUTPUT folder");
    // ─── **** Change below to your files names **** ───
    prefix1   = getString("GREY filename prefix (include trailing \"_\")", "InvertedPan_");
    prefix2   = getString("CYAN filename prefix (include trailing \"_\")", "Cyan_");
    outPrefix = getString("Output file prefix",               "Composite_");
  
    mergedCount = 0;
    // 2) Loop 000 → 087
    // ─── ** Change to the number Z slices you have, e.g. 87 ** ───
    for (i = 0; i <= 87; i++) {
        // zero‑pad to 3 digits
        if (i < 10)      suf = "00" + i;
        else if (i < 100) suf = "0" + i;
        else              suf = ""  + i;
      
        name1 = prefix1 + suf + ".tif";
        name2 = prefix2 + suf + ".tif";
      
        // only proceed if both files exist
        if (File.exists(dir1 + name1) && File.exists(dir2 + name2)) {
            // open each
            open(dir1 + name1);
            open(dir2 + name2);
          
            // Merge via Image > Color > Merge Channels…
            // Note: use bracketed window titles
            // ─── * Grey is ch4, Cyan is ch5 in ImageJ, 'ch' = 'c' in imageJ * ───
            // ─── * I think ch1,2,3 = R,G,B, idk about 6 on * ───
            run("Merge Channels...", "c4=[" + name1 + "] c5=[" + name2 + "] create");
          
            // saveAs("Tiff", outDir + outPrefix + suf + ".tif");
            // Above doesn't work for me so I save as .png
            saveAs("PNG",  outDir + outPrefix + suf + ".png");
          
            // close composite and sources
            close(getTitle());  // merged
            close(name1);
            close(name2);
          
            mergedCount++;
        }
    }
    showMessage("Done", "Merged " + mergedCount + " stacks\n(000–087) into:\n" + outDir);
}
