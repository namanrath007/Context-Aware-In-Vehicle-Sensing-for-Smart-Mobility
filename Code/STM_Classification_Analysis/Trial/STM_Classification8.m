%% Initialization
clear; clc; close all;

%% Sampling rate
sr = 16000;

%% Load audio file (Noisy audio with engine noise)
[y1, ~] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_without_extAudio\Microphone_Data\noise1.wav", [1 sr*30]);

% Convert to mono if stereo
if size(y1, 2) > 1, y1 = mean(y1, 2); end

%% Load IMU data
imu_data = readtable("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\MemsSensorData\DataCollection\Engine_Noise_with_Ext_Audio\1min.csv");
time_imu = imu_data{:,1} / 1e6;  % µs to s
acc_x = imu_data{:,2};  % in mg
acc_y = imu_data{:,2};
acc_z = imu_data{:,2};

%% Resample IMU acc_x to match audio sample count
N = length(y1);
acc_x_resampled = interp1(time_imu, acc_x, linspace(time_imu(1), time_imu(end), N), 'linear', 'extrap')';
acc_y_resampled = interp1(time_imu, acc_y, linspace(time_imu(1), time_imu(end), N), 'linear', 'extrap')';
acc_z_resampled = interp1(time_imu, acc_z, linspace(time_imu(1), time_imu(end), N), 'linear', 'extrap')';

%% NaN Check & Fix: IMU Resampled Data
acc_x_resampled(isnan(acc_x_resampled)) = 0;
acc_y_resampled(isnan(acc_y_resampled)) = 0;
acc_z_resampled(isnan(acc_z_resampled)) = 0;

%% NaN Check & Fix: Audio Signal
y1(isnan(y1)) = 0;


%% LMS Adaptive Filtering using IMU data as reference
order = 32;
mu = 0.00001;

lmsFilter = dsp.LMSFilter('Length', order, 'StepSize', mu);
% Combine acc_x, acc_y, acc_z into one reference
imu_ref_combined = acc_x_resampled + acc_y_resampled + acc_z_resampled;

% Apply LMS
[~, lms_error] = lmsFilter(imu_ref_combined, y1);


% Replace any NaNs in LMS error signal (if any)
lms_error(isnan(lms_error)) = 0;


%% Plot Waveforms
t_audio = (0:N-1) / sr;
figure;
subplot(3,1,1);
plot(t_audio, y1); title('Noisy Audio Signal'); xlabel('Time (s)'); grid on;
subplot(3,1,2);
plot(t_audio, acc_x_resampled); title('Resampled IMU acc_x (Reference)'); xlabel('Time (s)'); grid on;
subplot(3,1,3);
plot(t_audio, lms_error); title('Filtered Audio (Error Signal)'); xlabel('Time (s)'); grid on;

sgtitle('ANC using IMU Accelerometer Data as Reference (LMS Filter)');

%% Optional: FFT Spectrum
f = (0:N-1)*(sr/N);
Y_y1 = abs(fft(y1))/N;
Y_error = abs(fft(lms_error))/N;

figure;
plot(f(1:N/2), Y_y1(1:N/2), 'b', 'DisplayName', 'Original Audio');
hold on;
plot(f(1:N/2), Y_error(1:N/2), 'r', 'DisplayName', 'Filtered Audio (Error)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT Spectrum Comparison: Original vs Filtered');
legend;
grid on;
xlim([0 sr/2]);

%% Optional: Correlation
% Make sure both vectors are finite
valid_indices = isfinite(y1) & isfinite(lms_error);

% Calculate correlation only on valid indices
corr_value = corr(y1(valid_indices), lms_error(valid_indices));

% Display result
fprintf('Pearson Correlation between Original and Filtered Audio: %.5f\n', corr_value);

