import webknossos as wk
import tifffile as tiff
import numpy as np
import xml.etree.ElementTree as ET
import os 

input_path = '/Volumes/Extreme SSD/240718_ms8_b_expanded_1.ome.tiff'

# Define the region you want to extract as a subset (e.g., [slice(0, 100), slice(0, 100), slice(0, 10)])
#region = (slice(0, 15000), slice(0, 25986), slice(50, 51))  # Adjust this as needed
region = (slice(0, 4096), slice(2000, 6096), slice(0, 105))  # Adjust this as needed

do_extract_subset = 1
do_convert2wkw = 0
channel_idx = 1

subset_output_path = '/Users/atk42/repos/wk_tools/240718_ms8_b_expanded_4k_subset_chan%i/' % channel_idx
new_dataset_name = '/Users/atk42/repos/wk_tools/large_subset_chan%i.wkw' % channel_idx

def parse_ome_metadata(metadata):
    """Extract useful information from the OME metadata."""
    root = ET.fromstring(metadata)
    namespaces = {'ome': 'http://www.openmicroscopy.org/Schemas/OME/2016-06'}
    
    size_x = int(root.find('.//ome:Pixels', namespaces).get('SizeX'))
    size_y = int(root.find('.//ome:Pixels', namespaces).get('SizeY'))
    size_z = int(root.find('.//ome:Pixels', namespaces).get('SizeZ'))
    size_c = int(root.find('.//ome:Pixels', namespaces).get('SizeC'))
    size_t = int(root.find('.//ome:Pixels', namespaces).get('SizeT'))
    
    return size_x, size_y, size_z, size_c, size_t

def extract_subset_multipage(input_path, output_path, region, channel_idx = 0):
    with tiff.TiffFile(input_path) as tif:
        # Read OME metadata
        ome_metadata = tif.ome_metadata
        size_x, size_y, size_z, size_c, size_t = parse_ome_metadata(ome_metadata)
        
        print(f"Image dimensions (X, Y, Z, Channels, Timepoints): ({size_x}, {size_y}, {size_z}, {size_c}, {size_t})")
        
        # Initialize an empty list to store the slices
        subset_slices = []
        
        # Iterate through the specified Z slices (pages)
        for z in range(region[2].start, region[2].stop):
            print('%i of %i slices' % (z+1, region[2].stop))

            # Select Channel
            z = z + size_z * channel_idx 
            # Read the page (z-slice)
            page_data = tif.pages[z].asarray()
            #print(page_data.shape)

            range(size_c) 
            # Check if the data has channels
            if len(page_data.shape) == 3:  # (Y, X, Channels)
                subset = page_data[region[0], region[1], :]
            elif len(page_data.shape) == 2:  # (Y, X)
                subset = page_data[region[0], region[1]]
            else:
                raise ValueError(f"Unexpected page data shape: {page_data.shape}")
            
            subset_slices.append(subset)
        
        # Stack the slices to form the final 3D array
        subset = np.stack(subset_slices, axis=0)
        
        # Save the subset as a new TIFF file
        #tiff.imwrite(output_path, subset, photometric='minisblack')
        tiff.imwrite(output_path, subset, description=None, metadata={})

def extract_subset(input_path, output_folder, region, channel_idx=0):
    with tiff.TiffFile(input_path) as tif:
        # Read OME metadata
        ome_metadata = tif.ome_metadata
        size_x, size_y, size_z, size_c, size_t = parse_ome_metadata(ome_metadata)
        
        print(f"Image dimensions (X, Y, Z, Channels, Timepoints): ({size_x}, {size_y}, {size_z}, {size_c}, {size_t})")
        
        # Ensure the output directory exists
        os.makedirs(output_folder, exist_ok=True)
        
        # Iterate through the specified Z slices (pages)
        for z in range(region[2].start, region[2].stop):
            print(f'{z + 1} of {z+region[2].stop - z+region[2].start} slices')
            
            # Adjust the Z index for the specified channel
            adjusted_z = z + size_z * channel_idx
            
            # Read the page (z-slice)
            page_data = tif.pages[adjusted_z].asarray()

            # Extract the region
            if len(page_data.shape) == 3:  # (Y, X, Channels)
                subset = page_data[region[0], region[1], :]
            elif len(page_data.shape) == 2:  # (Y, X)
                subset = page_data[region[0], region[1]]
            else:
                raise ValueError(f"Unexpected page data shape: {page_data.shape}")
            
            # Define the output file name
            filename = f'slice_{z:04d}.tiff'
            filepath = os.path.join(output_folder, filename)
            
            # Save the slice as an individual TIFF file
            tiff.imwrite(filepath, subset)

def main():

    
    with tiff.TiffFile(input_path) as tif:
        # Read OME metadata
        ome_metadata = tif.ome_metadata
        size_x, size_y, size_z, size_c, size_t = parse_ome_metadata(ome_metadata)
        print(f"Image dimensions (X, Y, Z, Channels, Timepoints): ({size_x}, {size_y}, {size_z}, {size_c}, {size_t})")

    if do_extract_subset:
        extract_subset(input_path, subset_output_path, region, channel_idx = channel_idx)
    
    if do_convert2wkw: # Doesnt really work yet
        ds = wk.Dataset(new_dataset_name, voxel_size=(5, 5, 25))
        layer_i16 = ds.add_layer_from_images(
            images=[subset_output_path],
            layer_name="data_i16",
            use_bioformats=False  # might be required
        )
        ds.downsample()

if __name__ == "__main__":
    main()