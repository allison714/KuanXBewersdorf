from pathlib import Path
from webknossos import Dataset
from webknossos.dataset import COLOR_CATEGORY

# Define input file and output folder based on user input
INPUT_FILE = Path(r"Z:\Joerg\ims2TIFF")
OUTPUT_FOLDER = Path(r"Z:\Joerg")

def main() -> None:
    """Convert a list of images into a WEBKNOSSOS dataset and directly add them as a new layer."""
    # Assuming we need to convert the single input file to a TIFF sequence, update accordingly
    # Adjust your conversion logic as needed
    input_files = (INPUT_FILE,)

    dataset = Dataset(
        dataset_path=OUTPUT_FOLDER,
        voxel_size=(3.220, 3.238, 8.068),
        name="My_new_dataset2",
        exist_ok=False,
      #  allow_multiple_layers=True,  # Handle multiple layers
    )
    dataset.add_layer_from_images(
        images=input_files,
        layer_name="test2",
        category=COLOR_CATEGORY,
    )

    # dataset.upload()

if __name__ == "__main__":
    main()
