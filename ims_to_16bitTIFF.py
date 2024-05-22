# ims -> OME-Zarr
# A. Cairns
# 05-24-2024

import os
import h5py
import zarr
from bioformats import from_tiff

def ims_to_ome_zarr(input_folder, output_folder):
    os.makedirs(output_folder, exist_ok=True)
    for file_name in os.listdir(input_folder):
        if file_name.endswith(".ims"):
            ims_file_path = os.path.join(input_folder, file_name)
            print(f"Processing IMS file: {ims_file_path}")  
            output_file_path = os.path.join(output_folder, os.path.splitext(file_name)[0] + "_OME-Zarr")
            with h5py.File(ims_file_path, 'r') as ims_file:
                dataset_name = 'ImageData'  
                if dataset_name in ims_file:
                    image_data = ims_file[dataset_name][()]  
                    metadata = ims_file['ImageMeta'][()] if 'ImageMeta' in ims_file else None
                    zarr_store = zarr.open(output_file_path, mode='w')
                    zarr_store.create_dataset('data', data=image_data, chunks=image_data.shape, dtype='uint16', compressor=zarr.Blosc())
                    if metadata is not None:
                        zarr_store.attrs.update(from_tiff(metadata).to_omexml())
                    zarr_store.close()
                    print(f"Converted: {ims_file_path}")
                else:
                    print(f"Skipped: {ims_file_path} (missing dataset: {dataset_name})")

ims_to_ome_zarr(r"D:\Dragonfly\2024-05-20", r"D:\Dragonfly\OME-Zarr_Data")
print("Conversion to OME-Zarr complete.")
