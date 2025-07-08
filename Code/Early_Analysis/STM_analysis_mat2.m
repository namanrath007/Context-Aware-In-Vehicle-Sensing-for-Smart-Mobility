% =================== Load Microphone Data ===================
[micData, fs_mic] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\Microphone_Data\1min.wav");

% =================== Load IMU CSV Data ===================
imuData = readmatrix("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv");

% Confirm number of columns
disp(['Number of IMU columns: ', num2str(size(imuData, 2))]);

% Check if at least 2 columns exist
if size(imuData,2) < 2
    error('CSV must have at least 2 columns for accX and gyroX');
end

% =================== Extract accX and gyroX ===================
accX = imuData(:, 1);           % accX in mg
gyroX = imuData(:, 2);          % gyroX in mdps

% =================== Convert Gyroscope from mdps to dps ===================
gyroX_dps = gyroX / 1000;

% =================== Resample accX to match micData length ===================
if length(accX) ~= length(micData)
    accX_resampled = interp1(1:length(accX), accX, linspace(1, length(accX), length(micData)), 'linear')';
else
    accX_resampled = accX;
end

% Resample gyroX_dps to match micData length
if length(gyroX_dps) ~= length(micData)
    gyroX_dps_resampled = interp1(1:length(gyroX_dps), gyroX_dps, linspace(1, length(gyroX_dps), length(micData)), 'linear')';
else
    gyroX_dps_resampled = gyroX_dps;
end

% =================== Create Anti-Phase Noise Signal ===================
%antiNoise = -accX_resampled;
%antiNoise = antiNoise / max(abs(antiNoise));  % normalize

% invert phase anti-noise
antiNoise = -micData;

% =================== LMS Adaptive Filter Function ===================
function [y, e, w] = myLMS(d, x, mu, M)
    N = length(d);
    w = zeros(M, 1);
    y = zeros(N, 1);
    e = zeros(N, 1);
    x_buf = zeros(M, 1);
    for n = 1:N
        x_buf = [x(n); x_buf(1:end-1)];
        y(n) = w' * x_buf;
        e(n) = d(n) - y(n);
        w = w + 2 * mu * e(n) * x_buf;
    end
end

% =================== Filter Parameters ===================
filterOrder = 64;
mu = 0.00005;

% =================== Apply LMS Filter ===================
[y, e, w] = myLMS(micData, antiNoise, mu, filterOrder);

% =================== Create Time Vector ===================
t = (0:length(micData)-1)/fs_mic;

% =================== Plot Signals ===================
figure;
subplot(3,1,1);
plot(t, micData);
title('Original Microphone Signal');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(t, antiNoise);
title('Anti-Phase Noise Signal (from accX)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(t, e);
title('Error Signal (After LMS)');
xlabel('Time (s)'); ylabel('Amplitude');

%subplot(4,1,4);
%plot(t, gyroX_dps_resampled);
%title('Gyroscope X-axis (dps)');
%xlabel('Time (s)'); ylabel('Angular Velocity (dps)');

% =================== Plot LMS Filter Coefficients ===================
figure;
plot(w);
title('LMS Filter Coefficients');
xlabel('Coefficient Index');
ylabel('Value');
