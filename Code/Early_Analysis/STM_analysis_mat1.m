% Read microphone data
[micData, fs_mic] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\Microphone_Data\1min.wav");

% Read IMU CSV data
imuData = readmatrix("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv");

% Confirm number of columns
disp(size(imuData, 2));

% Extract accX and gyroX (assuming 2 columns)
accX = imuData(:, 1);
gyroX = imuData(:, 2);

% Convert gyroX from mdps to dps
gyroX_dps = gyroX / 1000;

% Resample accX to match micData length
if length(accX) ~= length(micData)
    accX_resampled = interp1(1:length(accX), accX, linspace(1, length(accX), length(micData)), 'linear')';
else
    accX_resampled = accX;
end

% Create anti-phase noise signal
%antiNoise = -accX_resampled;
%antiNoise = antiNoise / max(abs(antiNoise));  % normalize

% invert phase anti-noise
antiNoise = -micData;

% LMS filter function
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

% Filter parameters
filterOrder = 64;
mu = 0.00005;

% Apply LMS filter
[y, e, w] = myLMS(micData, antiNoise, mu, filterOrder);

% Time vector
t = (0:length(micData)-1)/fs_mic;

% Plot signals
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

% Plot LMS filter coefficients
figure;
plot(w);
title('LMS Filter Coefficients');
xlabel('Coefficient Index');
ylabel('Value');
