# Test
import h5py

# Path to the IMS file
ims_file_path = r"D:\Dragonfly\2024-05-15\ms8aii_2_FusionStitcher.ims"
# dataset_name = DataSet

# Open the IMS file in read mode
with h5py.File(ims_file_path, 'r') as ims_file:
    # Print the datasets available in the IMS file
    print("Datasets in IMS file:")
    for dataset_name in ims_file:
        print(dataset_name)