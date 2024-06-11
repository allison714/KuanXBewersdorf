import ij.IJ;
import ij.ImagePlus;
import ij.plugin.ChannelSplitter;

public class SimpleImageJMacro {
    public static void main(String[] args) {
        // Specify the file path
        String filePath = "/path/to/your/file";  // Replace with your actual file path
        
        // Open the file as a virtual hyperstack
        ImagePlus imp = IJ.openImage(filePath);
        imp.show();

        // Split channels
        ImagePlus[] channels = ChannelSplitter.split(imp);
        
        // Get the dimensions of the hyperstack
        int slices = imp.getNSlices();
        int middleSlice = slices / 2;  // Calculate the middle slice
        
        // Adjust brightness and contrast for the middle slice of each channel
        for (ImagePlus channel : channels) {
            channel.setSlice(middleSlice);
            IJ.run(channel, "Enhance Contrast", "saturated=0.35");
        }
        
        // Save each channel as a .tiff without displaying it
        for (int c = 0; c < channels.length; c++) {
            for (int z = 1; z <= slices; z++) {
                channels[c].setSlice(z);
                IJ.saveAsTiff(channels[c], "/path/to/save/channel" + (c + 1) + "_slice" + z + ".tiff");
            }
        }
        
        // Close all windows
        IJ.run("Close All");
    }
}
