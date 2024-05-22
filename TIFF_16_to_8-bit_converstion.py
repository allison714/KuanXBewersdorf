# 16-bit TIFF -> 8-bit TIFF with auto B/C
# A. Cairns
# 05.22.24

import numpy as np
import tifffile
from skimage import exposure

def adjust_brightness_contrast(image, min_intensity, max_intensity):
    """
    Adjusts the brightness and contrast of a 16-bit image based on given min and max intensity values.
    """
    # Clip the image intensities to the specified range
    image_clipped = np.clip(image, min_intensity, max_intensity)
    # Normalize the clipped image to the range 0-1
    image_normalized = (image_clipped - min_intensity) / (max_intensity - min_intensity)
    # Scale to 8-bit range (0-255)
    image_8bit = (image_normalized * 255).astype(np.uint8)
    return image_8bit

# Load the 16-bit hyperstack
input_path = 'path/to/your/16bit_hyperstack.tif'
output_path = 'path/to/save/adjusted_hyperstack.tif'
hyperstack = tifffile.imread(input_path)

# Determine the middle slice
n_slices = hyperstack.shape[0]
middle_slice = hyperstack[n_slices // 2]

# Auto-adjust B/C on the middle slice using histogram percentile clipping
p2, p98 = np.percentile(middle_slice, (2, 98))

# Adjust all slices based on the determined intensity range
adjusted_hyperstack = np.zeros_like(hyperstack, dtype=np.uint8)
for i in range(n_slices):
    adjusted_hyperstack[i] = adjust_brightness_contrast(hyperstack[i], p2, p98)

# Save the adjusted 8-bit hyperstack
tifffile.imwrite(output_path, adjusted_hyperstack)

print("Adjustment and conversion complete. Saved to:", output_path)
