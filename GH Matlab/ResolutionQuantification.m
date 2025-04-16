% Confocal Resolution Calculator
% A. Cairns
% 03.18.2025
clc; clear; close all;
%%
%% -----------|| GUI USER INPUT ||-----------
prompt = {'Enter XY file path:', 'Enter Z file path:', 'Enter excitation wavelength (nm):', 'Enter Numerical Aperture (NA):'};
dlgtitle = 'Input Required';
defaults = {'C:\Users\allis\OneDrive - Yale University\Imspector\Excel\Imsp_60x_CF40_stack03_8f0__01.xlsx', ...
            'C:\Users\allis\OneDrive - Yale University\Imspector\Excel\Zaxial_res_60x_CF40_stack03_8_F0_substack_8bit.xlsx', ...
            '488', '1.4'};
userInput = inputdlg(prompt, dlgtitle, [1 100], defaults);

XYfileName = userInput{1};
ZfileName = userInput{2};
lambda = str2double(userInput{3});
NA = str2double(userInput{4});

XYdata = readtable(XYfileName); 
XYdata = XYdata(2:end, :); 
Zdata = readtable(ZfileName); 
Zdata = Zdata(2:end, :);

numColsXY = width(XYdata);
numColsZ = width(Zdata);
numDatasetsXY = numColsXY / 2; 
numDatasetsZ = numColsZ / 2;   
w0sXY = ones(numDatasetsXY, 1);  
w0sZ = ones(numDatasetsZ, 1);

%%
XYdata = readtable(XYfileName); 
XYdata = XYdata(2:end, :); % skip headers
Zdata = readtable(ZfileName); 
Zdata = Zdata(2:end, :);
%%
% Preallocate storage for datasets
numColsXY = width(XYdata);
numColsZ = width(Zdata);
numDatasetsXY = numColsXY / 2; % Assuming each dataset has an (x,y) pair
numDatasetsZ = numColsZ / 2;   
w0sXY = ones(numDatasetsXY, 1);  
w0sZ = ones(numDatasetsZ, 1);    

% --- || Loop through each XY dataset ||---
% -----------------------------------------
for i = 1:numDatasetsXY
    % Extract x and y values for XY dataset
    Xcols = 2 * i - 1; % x-values (odd columns)
    Ycols = 2 * i;     % y-values (even columns)

    % Ensure there are no NaN values (for variable row lengths)
    validIdx = ~isnan(XYdata{:, Xcols}) & ~isnan(XYdata{:, Ycols});
    x = XYdata{validIdx, Xcols};
    y = XYdata{validIdx, Ycols};

    % Skip if empty
    if isempty(x) || isempty(y)
        continue;
    end

    % Find the index of the maximum y value
    [~, maxIndex] = max(y);
    x0 = x(maxIndex); % Initial peak location guess

    % ---- || Define the Gaussian function with background || ---
    gaussian = @(params, x) params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + params(4);

    % Define the error function (sum of squared residuals)
    errorFxn = @(params) sum((gaussian(params, x) - y).^2);

    % Initial parameter guesses [a0, x0, w0, B]
    initGuess = [max(y), x0, 0.1, min(y)];  % w0 = 0.1 (initial)

    % Perform optimization - 100 iterations
    options = optimset('MaxIter', 100, 'Display', 'off');
    optimizedParams = fminsearch(errorFxn, initGuess, options);

    % Extract optimized w0 value for XY
    w0sXY(i) = optimizedParams(3); % Store optimized w0 for XY

    % Generate fitted curve for XY
    Xfit = linspace(min(x), max(x), 300);
    Yfit = gaussian(optimizedParams, Xfit);

    % Plot individual Gaussian fits for XY
    figure;
    hold on;
    % Data
    plot(x, y, 'co:', 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'b', 'LineWidth', 2);
    % Gaussian Fit
    plot(Xfit, Yfit, 'm-', 'LineWidth', 2);
    yline(optimizedParams(4), '--', 'Background', 'Color', 'k');
    % Format
    xlabel('Position (x)');
    ylabel('Intensity (f(x))');
    title(['Gaussian Fit for XY Dataset ', num2str(i)]);
    legend('Data', 'Gaussian Fit', 'Background Level');
    grid on;
    hold off;
end

% ---|| Loop through each Z dataset ||---
% -----------------------------------------
fvalZ = [];
pointsAroundPeak = 30; % number of points to include on each side

for i = 1:numDatasetsZ
    % Extract x and z values for Z dataset
    Xcols = 2 * i - 1; % x-values in odd columns
    Zcols = 2 * i;     % z-values in even columns

    % Ensure there are no NaN values (for variable row lengths)
    validIdx = ~isnan(Zdata{:, Xcols}) & ~isnan(Zdata{:, Zcols});
    xFull = Zdata{validIdx, Xcols};
    zFull = Zdata{validIdx, Zcols};
    
    % Skip if dataset is empty
    if isempty(xFull) || isempty(zFull)
        continue;
    end

    % Find the index of the maximum z value
    [~, maxIndex] = max(zFull);
    
    % Calculate start and end indices for cropping
    startIdx = max(maxIndex - pointsAroundPeak, 1);
    endIdx = min(maxIndex + pointsAroundPeak, length(zFull));
    
    % Crop to ±35 data points around the peak
    x = xFull(startIdx:endIdx);
    z = zFull(startIdx:endIdx);

    % Define the Gaussian function with background
    gaussian = @(params, x) params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + params(4);

    % Define the error function (sum of squared residuals)
    errorFxn = @(params) sum((gaussian(params, x) - z).^2);

    % Initial parameter guesses [a0, x0, w0, B]
    initGuess = [max(z), x(maxIndex - startIdx + 1), 0.5, min(z)];  % Correct x0 using cropped indexing

    % Perform optimization
    options = optimset('MaxIter', 100, 'Display', 'off');
    [optimizedParams, fval] = fminsearch(errorFxn, initGuess, options);
    fvalZ(i) = fval;
    
    % Extract optimized w0 value for Z
    w0sZ(i) = optimizedParams(3); % Store optimized w0 for Z

    % Generate fitted curve for Z
    Xfit = linspace(min(x), max(x), 300);
    Zfit = gaussian(optimizedParams, Xfit);

    % Plot individual Gaussian fits for Z
    figure;
    hold on;
    % Data
    plot(x, z, 'co:', 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'b', 'LineWidth', 2);
    % Gaussian Fit
    plot(Xfit, Zfit, 'g-', 'LineWidth', 2);
    yline(optimizedParams(4), '--', 'Background', 'Color', 'k');
    % Format
    xlabel('Position (x)');
    ylabel('Intensity (f(x))');
    title(['Gaussian Fit for Z Dataset ', num2str(i)]);
    legend('Data', 'Gaussian Fit', 'Background Level');
    grid on;
    hold off;
end

%%
%% w0 Table - only works if XY & Z have the same number of datapoints
% Combine and display results for XY and Z datasets
w0s_all = zeros(50,2);  % Combine XY and Z results
w0s_all(:,1) = w0sXY;
w0s_all(:,2) = w0sZ;

% Convert results to a table
w0_table = array2table(w0s_all, 'VariableNames', {'w0_{XY}','w0_{Z}'} );

% Display the table
disp('Optimized w0 values for XY and Z:');
disp(w0_table);
%%
% ---|| Calculate FWHM for XY ||---
% -----------------------------------------

% Plot histogram of optimized w0 values for XY
figure;
histogram(w0sXY, 'FaceColor', 'm', 'EdgeColor', 'k');
xlabel('Optimized w0 (µm) for XY');
ylabel('Frequency');
title('Distribution of Optimized w0 Values for XY');
grid on;

FWHMs_XY = 2.355 * w0sXY;

% Plot histogram of FWHM values for XY
figure;
histogram(FWHMs_XY, 'FaceColor', 'm', 'EdgeColor', 'k');
xlabel('FWHM for XY');
ylabel('Frequency');
title('Distribution of Optimized FWHM Values for XY');
grid on;

% Microscope parameters for XY (assuming GFP or similar)
lambdaGFP = 0.488; % Excitation wavelength for GFP (488 nm = 0.488 µm)
NA = 1.4;  % Numerical aperture of objective lens

% Microscope parameters for XY (assuming GFP or similar)
lambdapan = 0.561; % Excitation wavelength for pan (561 nm = 0.561 µm)
NA = 1.4;  % Numerical aperture of objective lens

% Compute theoretical lateral resolution (XY) for GFP or pan channel
XYresPan = 0.61 * lambdaGFP / NA;

% Compute mean and standard deviation of FWHM for XY
meanFWHM_XY = mean(FWHMs_XY);
stdFWHM_XY = std(FWHMs_XY);

% Compute ratio of FWHM to theoretical lateral resolution (XY)
ratioXY = meanFWHM_XY / XYresPan;

% Display comparison for XY
fprintf('Theoretical Lateral Resolution (XY) for pan ch.: %.4f µm\n', XYresPan);
fprintf('Mean Experimental FWHM for XY: %.4f µm\n', meanFWHM_XY);
fprintf('Standard Deviation of FWHM for XY: %.4f µm\n', stdFWHM_XY);
fprintf('Ratio (FWHM / Theoretical XY Resolution for pan ch.): %.2f\n', ratioXY);

% Perform a one-sample t-test for XY comparing to theoretical resolution
[h_XY, p_XY] = ttest(FWHMs_XY, XYresPan);

% Display test results for XY
if h_XY == 0
    fprintf('No significant difference for XY (p = %.4f)\n', p_XY);
else
    fprintf('Significant difference for XY (p = %.4f)\n', p_XY);
end


% Plot histogram of optimized w0 values for Z
figure;
histogram(w0sZ, 'FaceColor', 'g', 'EdgeColor', 'k');
xlabel('Optimized w0 (µm) for Z');
ylabel('Frequency');
title('Distribution of Optimized w0 Values for Z');
grid on;

% --- || Calculate FWHM for Z ||---
% -----------------------------------------
FWHMs_Z = 2.355 * w0sZ;

% Plot histogram of FWHM
figure;
histogram(FWHMs_Z, 'FaceColor', 'g', 'EdgeColor', 'k');
xlabel('FWHM (µm) for Z');
ylabel('Frequency');
title('Distribution of Optimized FWHM Values for Z');
grid on;

% Compute theoretical axial resolution (Z) for pan channel
ZresPan = 2 * lambdaGFP / (NA^2);

% Compute mean and standard deviation of FWHM for Z
meanFWHM_Z = mean(FWHMs_Z);
stdFWHM_Z = std(FWHMs_Z);

% Compute ratio of FWHM to theoretical axial resolution (Z)
ratioZ = meanFWHM_Z / ZresPan;

% Display comparison for Z
fprintf('Theoretical Axial Resolution (Z) for pan ch.: %.4f µm\n', ZresPan);
fprintf('Mean Experimental FWHM for Z: %.4f µm\n', meanFWHM_Z);
fprintf('Standard Deviation of FWHM for Z: %.4f µm\n', stdFWHM_Z);
fprintf('Ratio (FWHM / Theoretical Z Resolution for pan ch.): %.2f\n', ratioZ);

% Perform a one-sample t-test for Z comparing to theoretical resolution
[h_Z, p_Z] = ttest(FWHMs_Z, ZresPan);

% Display test results for Z
if h_Z == 0
    fprintf('No significant difference for Z (p = %.4f)\n', p_Z);
else
    fprintf('Significant difference for Z (p = %.4f)\n', p_Z);
end

%%
%% Comparison of Theoretical and Experimental Resolution

figure;

% Set up the data for plotting (XY and Z)
labels = {'XY', 'Z'};
theoretical_res = [XYresPan, ZresPan];  % Theoretical resolutions
mean_FWHM = [meanFWHM_XY, meanFWHM_Z];  % Mean experimental FWHMs
std_FWHM = [stdFWHM_XY, stdFWHM_Z];  % Standard deviations of experimental FWHMs

% Define the positions for the bars to avoid overlap
xPos = 1:length(labels);  % Positions for the categories

% Bar width
barWidth = 0.3;

% Create the bar chart
hold on;

% Plot bars for Theoretical Resolution
barTheor = bar(xPos - barWidth / 2, theoretical_res, barWidth, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'k');

% Plot bars for Mean Experimental FWHM
barExp = bar(xPos + barWidth / 2, mean_FWHM, barWidth, 'FaceColor', [0, 0.5, 1], 'EdgeColor', 'k');

% Plot error bars (standard deviation) for Experimental FWHM
% Using error bars instead of a bar for SD
errorbar(xPos + barWidth / 2, mean_FWHM, std_FWHM, 'k', 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10);

% Format
set(gca, 'XTick', xPos, 'XTickLabel', labels);
xlabel('Lateral/ Axial Resolution');
ylabel('Resolution (µm)');
ylim([0, 1.5*stdFWHM_Z+ meanFWHM_Z])
title('Comparison of Theoretical and Experimental Resolution');
legend([barTheor, barExp], 'Theoretical Resolution', 'Mean Experimental FWHM', 'Location', 'Southeast');
grid on;

% Display values on top of the bars
for i = 1:length(xPos) % For Theoretical Resolution
    text(xPos(i) - barWidth / 2, theoretical_res(i) + 0.02, sprintf('%.4f', theoretical_res(i)), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
end

% for i = 1:length(x_pos) % For Mean Experimental FWHM
%     text(x_pos(i) + barWidth / 2, mean_FWHM(i) + 0.02, sprintf('%.4f', mean_FWHM(i)), ...
%          'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
% end

for i = 1:length(xPos) % For SD (error bars)
    text(xPos(i) + barWidth / 2, mean_FWHM(i) + std_FWHM(i) + 0.02, sprintf('%.4f ± %.4f', mean_FWHM(i), std_FWHM(i)), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
end

hold off;
%%
%% Comparison of Theoretical and Experimental Resolution

figure;

% Set up the data for plotting (XY and Z)
labels = {'XY', 'Z'};
% theoretical_res = [XYresPan, ZresPan];  % Theoretical resolutions
mean_FWHM = [meanFWHM_XY, meanFWHM_Z];  % Mean experimental FWHMs
std_FWHM = [stdFWHM_XY, stdFWHM_Z];  % Standard deviations of experimental FWHMs

% Define the positions for the bars to avoid overlap
xPos = 1:length(labels);  % Positions for the categories

% Bar width
barWidth = 0.3;

% Create the bar chart
hold on;

% Plot bars for Theoretical Resolution
% barTheor = bar(xPos - barWidth / 2, theoretical_res, barWidth, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'k');

% Plot bars for Mean Experimental FWHM
barExp = bar(xPos + barWidth / 2, mean_FWHM, barWidth, 'FaceColor', [0, 0.5, 1], 'EdgeColor', 'k');

% Plot error bars (standard deviation) for Experimental FWHM
% Using error bars instead of a bar for SD
errorbar(xPos + barWidth / 2, mean_FWHM, std_FWHM, 'k', 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10);

% Format
set(gca, 'XTick', xPos, 'XTickLabel', labels);
xlabel('Mean Experimental FWHM');
ylabel('Resolution (µm)');
ylim([0, 1.5*stdFWHM_Z+ meanFWHM_Z])
title('Lateral and Axial Experimental Resolution');
% legend([barExp], 'Mean Experimental FWHM', 'Location', 'Southeast');
grid on;

% Display values on top of the bars
% for i = 1:length(xPos) % For Theoretical Resolution
%     text(xPos(i) - barWidth / 2, theoretical_res(i) + 0.02, sprintf('%.4f', theoretical_res(i)), ...
%          'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
% end

% for i = 1:length(x_pos) % For Mean Experimental FWHM
%     text(x_pos(i) + barWidth / 2, mean_FWHM(i) + 0.02, sprintf('%.4f', mean_FWHM(i)), ...
%          'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
% end

for i = 1:length(xPos) % For SD (error bars)
    text(xPos(i) + barWidth / 2, mean_FWHM(i) + std_FWHM(i) + 0.02, sprintf('%.4f ± %.4f', mean_FWHM(i), std_FWHM(i)), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
end

hold off;