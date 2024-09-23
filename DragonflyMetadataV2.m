% Extract Dragonfly Metadata
% A. Cairns
% 11 September 2024
% Updated by _____ on _____

clc; clear; close all;

% Define the folder containing metadata files
%% Test path
% %folderPath = 'C:/Users/allis/Documents/MATLAB/';  % Adjust this to your folder path

folderPath = 'C:\Users\allis\Documents\GitHub\KuanXBewersdorf\ims Metadata';
outputPath ='C:\Users\allis\Documents\GitHub\KuanXBewersdorf\Dragonfly_Metadata';

% Get a list of all .txt files in the folder
fileList = dir(fullfile(folderPath, '*.txt'));

% Initialize arrays to store data
dateArray = {};
fileNameArray = {};
objectiveArray = {};
ZslicesArray = [];
exposureCh1Array = [];
exposureCh2Array = [];
binningArray = {};
sensorWidthArray = [];
sensorHeightArray = [];
fileSizeGBArray = [];

% Loop through each file in the folder
for k = 1:length(fileList)
    % Get the full path of the file
    filePath = fullfile(folderPath, fileList(k).name);
    
    % Read the metadata from the file
    metadata = fileread(filePath);
    
    % File Name
    [~, fileName, ~] = fileparts(filePath);
    fileName = string(fileName);
    
    % Date and Time
    datePattern = 'DateAndTime=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})';
    dateTokens = regexp(metadata, datePattern, 'tokens');
    date = datetime(dateTokens{1}{1}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    % Objective Info
    objectivePattern = 'Description=([^\r\n]+)';
    objectiveTokens = regexp(metadata, objectivePattern, 'tokens');
    objective = string(objectiveTokens{1}{1});
    
    % Exposure (ms)
    exposureCh1Pattern = 'Exposure Time, Value=([\d.]+)';
    exposureCh1Tokens = regexp(metadata, exposureCh1Pattern, 'tokens');
    exposureCh1 = str2double(exposureCh1Tokens{1}{1});
    
    exposureCh2Pattern = 'Exposure Time, Value=([\d.]+)';
    exposureCh2Tokens = regexp(metadata, exposureCh2Pattern, 'tokens');
    exposureCh2 = str2double(exposureCh2Tokens{2}{1});
    
    % Binning
    binningPattern = 'Binning, Value=(\dx\d)';
    binningTokens = regexp(metadata, binningPattern, 'tokens');
    binning = string(binningTokens{1}{1});
    
    % Protocol Name
    userNamePattern = 'Name=(Joerg|Allison)([^\r\n]+)';
    tokens = regexp(metadata, userNamePattern, 'tokens');
    if ~isempty(tokens)
        name = tokens{1}{1};  % Name (Joerg or Allison)
        value = tokens{1}{2}; % The rest of the string after the name
        protocol = string([name, value]);
    else
        protocol = "NA";
    end
    
    % Zslices
    ZslicesPattern = 'NumberOfZPoints=(\d+)';
    ZslicesTokens = regexp(metadata, ZslicesPattern, 'tokens');
    Zslices = str2double(ZslicesTokens{1}{1});
    
    % Frame Rate (not used in table, but included for completeness)
    frameRatePattern = 'Frame Rate, Value=([\d.]+)';
    frameRateTokens = regexp(metadata, frameRatePattern, 'tokens');
    frameRate = string(frameRateTokens{1}{1});
    
    % Pixel Width/ Height
    pixelWidthPattern = 'DisplayName=Pixel Width \(µm\), Value=([\d.]+)';
    pixelWidthTokens = regexp(metadata, pixelWidthPattern, 'tokens');
    pixelWidth = str2double(pixelWidthTokens{1}{1});
    
    pixelHeightPattern = 'DisplayName=Pixel Height \(µm\), Value=([\d.]+)';
    pixelHeightTokens = regexp(metadata, pixelHeightPattern, 'tokens');
    pixelHeight = str2double(pixelHeightTokens{1}{1});
    
    % Extract Sensor Width and Height
    sensorWidthPattern = 'Width=(\d+)';
    sensorWidthTokens = regexp(metadata, sensorWidthPattern, 'tokens');
    sensorWidth = str2double(sensorWidthTokens{1}{1});
    
    sensorHeightPattern = 'Height=(\d+)';
    sensorHeightTokens = regexp(metadata, sensorHeightPattern, 'tokens');
    sensorHeight = str2double(sensorHeightTokens{1}{1});
    
    % Image Size Bytes (if available)
    fileSizeExpr = 'Image Size Bytes, Value=(\d+)';
    fileSizeTokens = regexp(metadata, fileSizeExpr, 'tokens');
    fileSizeBytes = str2double(fileSizeTokens{1}{1});
    fileSizeGB = fileSizeBytes / 1e9;  % Convert to GB

    % Store extracted data
    dateArray{end+1} = date;
    fileNameArray{end+1} = fileName;
    objectiveArray{end+1} = objective;
    ZslicesArray(end+1) = Zslices;
    exposureCh1Array(end+1) = exposureCh1;
    exposureCh2Array(end+1) = exposureCh2;
    binningArray{end+1} = binning;
    sensorWidthArray(end+1) = sensorWidth;
    sensorHeightArray(end+1) = sensorHeight;
    fileSizeGBArray(end+1) = fileSizeGB;
end

% Create the final table
% T = table(dateArray', fileNameArray', protocol', objectiveArray', ...
%     ZslicesArray', exposureCh1Array', exposureCh2Array', binningArray', ...
%     sensorWidthArray', sensorHeightArray', fileSizeGBArray', ...
%     'VariableNames', {'Date', 'File Name', 'Protocol', 'Objective Info', ...
%     'Z Slices', 'Ch1 Exposure', 'Ch2 Exposure', 'Binning', ...
%     'Sensor Width', 'Sensor Height', 'FileSizeGB'});
T = table(dateArray', fileNameArray', objectiveArray', ...
    ZslicesArray', exposureCh1Array', exposureCh2Array', binningArray', ...
    sensorWidthArray', sensorHeightArray', fileSizeGBArray', ...
    'VariableNames', {'Date', 'File Name', 'Objective Info', ...
    'Z Slices', 'Ch1 Exposure', 'Ch2 Exposure', 'Binning', ...
    'Sensor Width', 'Sensor Height', 'FileSizeGB'});


% Display the table
disp(T);

% Get current date and time
currentDateTime = datetime('now');
formattedDateTime = datestr(currentDateTime, 'yyyy-mm-dd_HH-MM-SS');

% Define the output file path with current date and time
outputFileName = sprintf('%s_Imaging_Data.txt', formattedDateTime);
outputFilePath = fullfile(outputPath, outputFileName);

% Write the table to a text file
writetable(T, outputFilePath, 'FileType', 'text', 'Delimiter', '\t');

% Display a message confirming the output
fprintf('Table written to %s\n', outputFilePath);