function DepthAttenuationCorrectionFromCSV(inputTiff, outputTiff, csvFile, dz)
% depthAttenuationCorrectionFromCSV  Correct Z‑attenuation using precomputed means
%
%   depthAttenuationCorrectionFromCSV(inputTiff, outputTiff, csvFile, dz)
%
%   INPUTS:
%     inputTiff  – string: path to your 16‑bit multi‑page TIFF
%     outputTiff – string: path where corrected TIFF will be written
%     csvFile    – string: path to your CSV from “Plot Z‑axis Profile”
%     dz         – scalar: Z‑step (in same units as you want μ, e.g. µm)
%
%   The CSV may have two columns [sliceIndex, meanIntensity] or a single
%   column of mean intensities. This function:
%     1) Loads the CSV and extracts slice means
%     2) Fits ln(mean) vs. z to get μ
%     3) Reads the TIFF into a 3D array
%     4) Multiplies each slice by exp(μ·z)
%     5) Writes out a new 16‑bit TIFF

% 
% DepthAttenuationCorrectionFromCSV('C:\Users\allis\Downloads\Confocal Simulation\ExM81_PSD-95_9SA_86x_11_19_21\MagentaGreen\PSDAdjustedBCrbEC.ome.tiff', ...
%     'C:\Users\allis\Downloads\Confocal Simulation\ExM81_PSD-95_9SA_86x_11_19_21\MagentaGreen\', ...
%     'C:\Users\allis\Downloads\Confocal Simulation\ExM81_PSD-95_9SA_86x_11_19_21\MagentaGreen\Z-axisProfile.csv', ...
%     0.348)


%% 1) Load CSV of means
data = readmatrix(csvFile);
if size(data,2) >= 2
    slices = data(:,1);
    means  = data(:,2);
else
    means  = data(:,1);
    slices = (1:numel(means))';
end
% Compute z positions
z = (slices-1) * dz;

%% 2) Fit exponential: ln(mean) = ln(I0) – μ·z
p  = polyfit(z, log(means), 1);
mu = -p(1);
I0 = exp(p(2));
fprintf('  → fitted μ = %.4g per unit z\n', mu);

%% 3) Read your TIFF stack into double
info    = imfinfo(inputTiff);
nSlices = numel(info);
h       = info(1).Height;
w       = info(1).Width;
stack   = zeros(h, w, nSlices, 'double');
for k = 1:nSlices
    stack(:,:,k) = double(imread(inputTiff, k));
end

%% 4) Apply physics correction: multiply slice k by exp(μ·z_k)
corrected = zeros(size(stack));
for k = 1:nSlices
    zk     = (k-1)*dz;           % assume slice 1 at z=0
    factor = exp(mu * zk);
    corrected(:,:,k) = stack(:,:,k) * factor;
end

%% 5) Clamp and write out as 16‑bit TIFF
corrected = min(max(corrected, 0), 2^16-1);
corrected = uint16(corrected);

for k = 1:nSlices
    if k==1
        imwrite(corrected(:,:,k), outputTiff, 'Compression','none');
    else
        imwrite(corrected(:,:,k), outputTiff, ...
                'WriteMode','append', 'Compression','none');
    end
end

fprintf('  → corrected stack saved to:\n     %s\n', outputTiff);
end
