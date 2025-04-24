% zSliceScaleBar2ImgSeq_RobustZ.m
% Adds a scale bar + "Z = ###" label (in matching color) to every .tif or .png in a folder,
% extracting the Z index from the last digits in the filename.

% 1) Select folders
inDir   = uigetdir(pwd, 'Select folder with images to process');
if inDir == 0, error('No input folder selected.'); end

outImg  = uigetdir(pwd, 'Select output folder for annotated images');
if outImg == 0, error('No output folder selected.'); end

% 2) Get parameters
prompt = { ...
  'Voxel size (µm per pixel):', ...
  'Scale bar length (µm):', ...
  'Scale bar color (m,c,b,g,k,w):', ...
  'Zero‑pad width for Z‑label:', ...
  'File type to process (tif or png):' ...
};
defAns = {'0.088','10','w','1','tif'};
dlgAns = inputdlg(prompt, 'Parameters', [1 50], defAns);
if isempty(dlgAns), error('Cancelled by user.'); end

voxelX   = str2double(dlgAns{1});
sb_um    = str2double(dlgAns{2});
sb_col   = dlgAns{3};
padWidth = str2double(dlgAns{4});
ftype    = lower(dlgAns{5});
if ~ismember(ftype,{'tif','png'})
    error('File type must be "tif" or "png".');
end

% 3) Color map (normalized for insertText)
colorMap = struct('m',[1 0 1], 'c',[0 1 1], 'b',[0 0 1], ...
                  'g',[0 1 0], 'k',[0 0 0], 'w',[1 1 1]);

% 4) Loop through files
files = dir(fullfile(inDir, ['*.' ftype]));
if isempty(files)
    warning('No .%s files found in %s', ftype, inDir);
end

for k = 1:numel(files)
    fname = files(k).name;
    img   = imread(fullfile(inDir, fname));
    
    % ensure RGB
    if ismatrix(img)
        imgOut = cat(3, img, img, img);
    else
        imgOut = img;
    end
    
    % determine max intensity
    if isfloat(imgOut)
        maxV = 1;
    elseif isa(imgOut,'uint8')
        maxV = 255;
    elseif isa(imgOut,'uint16')
        maxV = 65535;
    else
        maxV = double(max(imgOut(:)));
    end
    
    % compute scale bar in px
    sb_px = round(sb_um/voxelX);
    [h,w,~] = size(imgOut);
    margin    = 10;   % px from edges
    thickness = 5;    % bar thickness
    
    % bottom‑right coords
    x0 = w - margin - sb_px + 1;
    y0 = h - margin - thickness + 1;
    
    % draw bar in chosen color
    rgbN = colorMap.(sb_col);   % normalized 0–1
    rgbV = rgbN * maxV;         % scaled to img class
    for ch = 1:3
        imgOut(y0:y0+thickness-1, x0:x0+sb_px-1, ch) = rgbV(ch);
    end
    
    % extract all numeric runs, take last as Z index
    [~, baseName, ~] = fileparts(fname);
    nums = regexp(baseName, '\d+', 'match');
    if isempty(nums)
        rawZ = '0';
    else
        rawZ = nums{end};
    end
    zstr = pad(rawZ, padWidth, 'left', '0');
    
    % % overlay "Z = ###" in same color
    % annotation = ['Z = ' zstr];
    % posText = [margin, h - margin - thickness - 100];
    % imgOut = insertText(imgOut, posText, annotation, ...
    %                     'FontSize', 72, ...
    %                     'BoxOpacity', 0, ...
    %                     'TextColor', rgbV);
    
    % save annotated image
    outName = fullfile(outImg, [baseName '_scaledZ.' ftype]);
    imwrite(imgOut, outName);
end

msgbox(sprintf('Processed %d .%s files.', numel(files), ftype), 'All Done');
