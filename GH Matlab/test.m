fwhm_xy = 288; %nm
fwhm_z = 844; % nm

ExF_Thy1 = 20;
ExF_PSD95 = 19.4;

voxel_xy = 100;  % nm
voxel_z = 299;  % nm

voxel_xy_Thy1 = 88;  % nm
voxel_z_Thy1 = 348;  % nm

sigma_Thy1_xy = ((fwhm_xy / 2.355)/ voxel_xy_Thy1) * ExF_Thy1;
sigma_PSD95_xy = ((fwhm_xy / 2.355)/ voxel_xy) * ExF_PSD95;

sigma_Thy1_z = ((fwhm_z / 2.355)/ voxel_z_Thy1) * ExF_Thy1;
sigma_PSD95_z = ((fwhm_z / 2.355)/ voxel_z) * ExF_PSD95;
