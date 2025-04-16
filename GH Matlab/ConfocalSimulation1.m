function ConfocalSimulation1
% Create GUI figure with adjusted height to reduce empty space
f = figure('Name', 'Confocal Simulation GUI', 'Position', [300 300 550 550]);

ypos = @(i) 550 - i*40;  % Adjusted to fit in the shorter window

% === File I/O ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(1) 150 20], 'String', 'Image Sequence Folder:');
inputBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(1) 240 25], 'String', 'C:\Users\allis\Downloads\PSD-95 Simulation\PSD95 Sequence');
uicontrol(f, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [430 ypos(1) 60 25], ...
    'Callback', @(~,~) browseFolder(inputBox));

uicontrol(f, 'Style', 'text', 'Position', [20 ypos(2) 150 20], 'String', 'Output Folder:');
outputBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(2) 240 25], 'String', 'C:\Users\allis\OneDrive - Yale University\Figures');
uicontrol(f, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [430 ypos(2) 60 25], ...
    'Callback', @(~,~) browseFolder(outputBox));

uicontrol(f, 'Style', 'text', 'Position', [20 ypos(3) 150 20], 'String', 'File Name Root:');
nameBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(3) 240 25]);

% === Background Choice ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(4) 150 20], 'String', 'Background Color:');
bgChoice = uicontrol(f, 'Style', 'popupmenu', 'Position', [180 ypos(4) 240 25], ...
    'String', {'White (invert needed)', 'Black (no invert)'});

% === Image Dimensions ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(5) 150 20], 'String', 'Pixels X:');
pixXBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(5) 80 25], 'String', '2048');
uicontrol(f, 'Style', 'text', 'Position', [270 ypos(5) 70 20], 'String', 'Pixels Y:');
pixYBox = uicontrol(f, 'Style', 'edit', 'Position', [340 ypos(5) 80 25], 'String', '2048');
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(6) 150 20], 'String', 'Z Slices:');
zBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(6) 80 25], 'String', '87');

% === Voxel Sizes ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(7) 150 20], 'String', 'Voxel X (µm):');
vxBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(7) 80 25], 'String', '0.004');
uicontrol(f, 'Style', 'text', 'Position', [270 ypos(7) 80 20], 'String', 'Voxel Y (µm):');
vyBox = uicontrol(f, 'Style', 'edit', 'Position', [360 ypos(7) 80 25], 'String', '0.004');
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(8) 150 20], 'String', 'Voxel Z (µm):');
vzBox = uicontrol(f, 'Style', 'edit', 'Position', [180 ypos(8) 80 25], 'String', '0.014');

% === FWHM Inputs ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(9) 200 20], 'String', 'FWHM XY (nm):');
fwhmXYBox = uicontrol(f, 'Style', 'edit', 'Position', [230 ypos(9) 80 25], 'String', '250');
uicontrol(f, 'Style', 'text', 'Position', [320 ypos(9) 200 20], 'String', 'FWHM Z (nm):');
fwhmZBox = uicontrol(f, 'Style', 'edit', 'Position', [430 ypos(9) 80 25], 'String', '800');

% === Expansion Factor (ExF) ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(10) 200 20], 'String', 'Expansion Factor (ExF):');
exfBox = uicontrol(f, 'Style', 'edit', 'Position', [230 ypos(10) 80 25]);

% === Blur Mode Selection ===
uicontrol(f, 'Style', 'text', 'Position', [20 ypos(11) 480 20], ...
    'String', 'Blur Mode:');
blurModeBox = uicontrol(f, 'Style', 'popupmenu', 'Position', [20 ypos(12) 490 25], ...
    'String', {
    '1 - FWHM-based: σ = (FWHM / 2.355) / voxel (confocal PSF)';
    '2 - Pixel size-based: σ = pixelX * 0.05';
    '3 - Physical blur: σ = 0.25 / voxelX';
    });

% === Generate Button ===
uicontrol(f, 'Style', 'pushbutton', 'String', 'Generate Panels', ...
    'FontSize', 12, 'Position', [160 ypos(13) 200 40], ...
    'Callback', @(~,~) onGenerate());  % Callback to onGenerate

% Logic for browsing folder
    function browseFolder(box)
        % Folder browsing function
        folder = uigetdir;
        if folder ~= 0
            set(box, 'String', folder);
        end
    end

% onGenerate function
    function onGenerate()
        % Inputs
        inputPath = get(inputBox, 'String');
        outputPath = get(outputBox, 'String');
        fileRoot = get(nameBox, 'String');
        bgOption = get(bgChoice, 'Value');
        mode = get(blurModeBox, 'Value');

        % Dimensions
        pixelX = str2double(get(pixXBox, 'String'));
        slicesZ = str2double(get(zBox, 'String'));

        % Voxel sizes
        voxelX = str2double(get(vxBox, 'String'));
        voxelZ = str2double(get(vzBox, 'String'));

        % Diffraction (with defaults)
        fwhmXY = str2double(get(fwhmXYBox, 'String')); if isnan(fwhmXY), fwhmXY = 250; end
        fwhmZ  = str2double(get(fwhmZBox, 'String'));  if isnan(fwhmZ),  fwhmZ  = 800; end

        % Expansion factor (optional)
        ExF = str2double(get(exfBox, 'String')); if isnan(ExF), ExF = 1; end

        % === FWHM-based calculation with correct unit conversion ===
        % Convert FWHM from nm to micrometers
        fwhmXY_um = fwhmXY / 1000;  % FWHM in micrometers
        sigmaXY_um = fwhmXY_um / 2.355;  % Convert to sigma in micrometers
        sigmaZ_um  = (fwhmZ / 1000) / 2.355;  % Convert FWHM to sigma in micrometers for Z

        % Convert to pixels based on voxel size (µm)
        sigmaXY = sigmaXY_um / voxelX;   % σ in pixels for XY
        sigmaZ  = sigmaZ_um  / voxelZ;    % σ in pixels for Z

        % === Sigma Calculation Based on Blur Mode ===
        switch mode
            case 1  % FWHM-based
                sigmaXY = (fwhmXY_um / 2.355) / voxelX;  % FWHM-based in pixels
            case 2  % Pixel size-based
                sigmaXY = pixelX * 0.05;  % Calculate sigma based on pixel size
            case 3  % Physical blur
                sigmaXY = 0.25 / voxelX;  % Physical blur based on 250 nm
        end

        % Safety check: if sigmaXY is too large (e.g., greater than 200), display a warning and exit
        if sigmaXY > 200
            msgbox('Warning: sigmaXY is too large (sigma > 200). Please adjust the parameters.', 'Error', 'error');
            return;  % Stop further execution
        end

        % Debugging outputs
        disp(['FWHM (XY): ', num2str(fwhmXY), ' nm']);
        disp(['FWHM (Z): ', num2str(fwhmZ), ' nm']);
        disp(['Calculated sigmaXY (in pixels): ', num2str(sigmaXY)]);
        disp(['Calculated sigmaZ (in pixels): ', num2str(sigmaZ)]);

        % === Load the image stack and apply Gaussian blur ===
        fileList = dir(fullfile(inputPath, '*.tif'));
        fileList = sort({fileList.name});

        % Load the stack and apply Gaussian filter to each slice
        stack = [];
        for k = 1:numel(fileList)
            img = imread(fullfile(inputPath, fileList{k}));
            if size(img,3) == 3
                img = rgb2gray(img);
            end
            % This is needed for floating point:
            img = im2double(img);  % Convert to double precision
            stack(:,:,k) = img;
        end

        % Invert the stack if background is white
        if bgOption == 1
            stack = imcomplement(stack);
        end

        % Apply 3D Gaussian filter to the stack
        smoothedStack = imgaussfilt3(stack, [sigmaXY sigmaXY sigmaZ]);

        % Create a Max Intensity Projection (MIP) from the blurred stack
        mipBlur = max(smoothedStack, [], 3);

        % --- 4 Panels Generation (Full-size images) ---
        mid_raw = stack(:,:,round(size(stack,3)/2));  % Raw middle slice
        mid_blur = imgaussfilt(mid_raw, sigmaXY);  % Blurred middle slice
        mip_raw = max(stack,[],3);  % MIP without blur
        mip_blur = imgaussfilt3(stack, [sigmaXY sigmaXY sigmaZ]);
        %%% mip_blur = max(imgaussfilt3(stack, [sigmaXY sigmaXY sigmaZ]), [], 3);  % MIP with blur

        % RGB + scale bar function with larger font size
        toGreen = @(img) cat(3, zeros(size(img)), mat2gray(img), zeros(size(img)));
        function imgOut = addScale(img)
            scaleBar_um = 1;  % 1 µm scale bar
            scaleBar_px = round(scaleBar_um / voxelX);
            posX = size(img,2) - scaleBar_px - 40;
            posY = size(img,1) - 60;
            imgOut = insertShape(toGreen(img), 'FilledRectangle', ...
                [posX posY scaleBar_px 5], 'Color','white', 'Opacity',1);
        end

        % Add scale bars to images
        mid_raw_rgb = addScale(mid_raw);
        mid_blur_rgb = addScale(mid_blur);
        mip_raw_rgb = addScale(mip_raw);
        mip_blur_rgb = addScale(mip_blur);

        % --- Display the blurred MIP to crop ---
        figure;
        imshow(mipBlur, []);
        title('Select crop region');
        rect = getrect;  % Get the crop rectangle

        % Crop the MIP and display it
        cropped_mip = imcrop(mipBlur, rect);
        figure;
        imshow(cropped_mip, []);
        title('Cropped MIP Region');

        % === Crop the full stack images based on the rectangle ===
        cropped_mid_raw = mid_raw(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3)));
        cropped_mid_blur = mid_blur(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3)));
        cropped_mip_raw = mip_raw(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3)));
        cropped_mip_blur = mip_blur(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3)));

        % === New Addition: Crop the Raw Tiff Stack ===
        % Crop every slice of the raw stack using the same ROI
        cropped_raw_stack = stack(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3)), :);
        
        % Save the cropped raw stack as a multi-page TIFF file
        rawStackFile = fullfile(outputPath, [fileRoot '_cropped_stack_raw.tiff']);
        for k = 1:size(cropped_raw_stack, 3)
            if k == 1
                imwrite(mat2gray(cropped_raw_stack(:,:,k)), rawStackFile, 'tiff', 'Compression','none');
            else
                imwrite(mat2gray(cropped_raw_stack(:,:,k)), rawStackFile, 'tiff', 'WriteMode', 'append', 'Compression','none');
            end
        end

        % Continue with saving the cropped panels as before
        
        % Save cropped images with scale bars
        cropped_mid_raw_rgb = addScale(cropped_mid_raw);
        cropped_mid_blur_rgb = addScale(cropped_mid_blur);
        cropped_mip_raw_rgb = addScale(cropped_mip_raw);
        cropped_mip_blur_rgb = addScale(cropped_mip_blur);

        imwrite(cropped_mid_raw_rgb, fullfile(outputPath, [fileRoot '_cropped_mid_raw.tiff']));
        imwrite(cropped_mid_blur_rgb, fullfile(outputPath, [fileRoot '_cropped_mid_blur.tiff']));
        imwrite(cropped_mip_raw_rgb, fullfile(outputPath, [fileRoot '_cropped_mip_raw.tiff']));
        imwrite(cropped_mip_blur_rgb, fullfile(outputPath, [fileRoot '_cropped_mip_blur.tiff']));

        % Grayscale versions of cropped images
        imwrite(mat2gray(cropped_mid_raw), fullfile(outputPath, [fileRoot '_cropped_mid_raw_gs.tiff']));
        imwrite(mat2gray(cropped_mid_blur), fullfile(outputPath, [fileRoot '_cropped_mid_blur_gs.tiff']));
        imwrite(mat2gray(cropped_mip_raw), fullfile(outputPath, [fileRoot '_cropped_mip_raw_gs.tiff']));
        imwrite(mat2gray(cropped_mip_blur), fullfile(outputPath, [fileRoot '_cropped_mip_blur_gs.tiff']));

        % Create and save the 2x2 figure for cropped panels
        f3 = figure('Units','inches','Position',[11 1 4 4],'Color','w');
        cropped_rgbImgs = {cropped_mid_raw_rgb, cropped_mid_blur_rgb, cropped_mip_raw_rgb, cropped_mip_blur_rgb};
        panels = {'a','b','c','d'};
        for i = 1:4
            subplot(2,2,i); imshow(cropped_rgbImgs{i});
            title(upper(['(' panels{i} ')']), 'FontName','Arial', 'FontSize',10); axis off;
        end

        set(f3, 'PaperUnits','inches','PaperPosition', [0 0 4 4]);
        print(f3, fullfile(outputPath, [fileRoot '_cropped_2x2_figure']), '-dtiff', '-r600');
        close(f3);

        % --- Non-cropped panels generation ---
        f4 = figure('Units','inches','Position',[16 1 4 4],'Color','w');
        full_rgbImgs = {mid_raw_rgb, mid_blur_rgb, mip_raw_rgb, mip_blur_rgb};
        for i = 1:4
            subplot(2,2,i); imshow(full_rgbImgs{i});
            title(upper(['(' panels{i} ')']), 'FontName','Arial', 'FontSize',10); axis off;
        end

        set(f4, 'PaperUnits','inches','PaperPosition', [0 0 4 4]);
        print(f4, fullfile(outputPath, [fileRoot '_2x2_figure']), '-dtiff', '-r600');
        close(f4);

        % Grayscale versions of the non-cropped figures
        imwrite(mat2gray(mid_raw), fullfile(outputPath, [fileRoot '_mid_raw_gs.tiff']));
        imwrite(mat2gray(mid_blur), fullfile(outputPath, [fileRoot '_mid_blur_gs.tiff']));
        imwrite(mat2gray(mip_raw), fullfile(outputPath, [fileRoot '_mip_raw_gs.tiff']));
        imwrite(mat2gray(mip_blur), fullfile(outputPath, [fileRoot '_mip_blur_gs.tiff']));

        msgbox('Simulation completed and saved successfully!', 'Done');
    end
end
