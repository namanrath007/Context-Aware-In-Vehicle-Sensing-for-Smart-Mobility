%% Analysis for Engine Noise with an external Audio and Random Voice
%% Initialization
clear; clc; close all;

%% Sampling rate
sr = 16000;

%% Load audio files
[y1, ~] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_with_extAudio_and_RandomVoice\Microphone_Data\2min\2min1.wav", [1 sr*30]);
[y2, ~] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\Simulation_Of_Audio_Sound\Real_time_data\filtered_audio.wav", [1 sr*30]);

% Convert to mono if needed
if size(y1, 2) > 1, y1 = mean(y1, 2); end
if size(y2, 2) > 1, y2 = mean(y2, 2); end

%% LMS Adaptive Filtering
order = 10;
mu = 0.001;
lmsFilter = dsp.LMSFilter('Length', order, 'StepSize', mu);
[~, lms_error] = lmsFilter(y1, y2);

%% Load IMU Data
imu_data = readtable("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\MemsSensorData\DataCollection\Engine_Noise_with_Ext_Audio\1min.csv");
time_imu = imu_data{:,1} / 1e6;  % convert µs to s
acc_x = imu_data{:,2};  % in mg
gyro_x = imu_data{:,5}; % in mdps

%% Audio Statistics (windowed)
win_size = sr; % 1-second windows
num_windows = floor(length(y2) / win_size);

rms_audio = zeros(num_windows,1);
var_audio = zeros(num_windows,1);

for i = 1:num_windows
    idx_start = (i-1)*win_size + 1;
    idx_end = idx_start + win_size - 1;
    segment = lms_error(idx_start:idx_end);
    rms_audio(i) = rms(segment);
    var_audio(i) = var(segment);
end

%% Downsample IMU data to match audio windows
imu_indices = round(linspace(1, length(acc_x), num_windows));
acc_x_down = acc_x(imu_indices);
gyro_x_down = gyro_x(imu_indices);

%% Correlation Calculations
corr_rms_accx = corrcoef(rms_audio, acc_x_down);
corr_var_accx = corrcoef(var_audio, acc_x_down);
corr_rms_gyrox = corrcoef(rms_audio, gyro_x_down);
corr_var_gyrox = corrcoef(var_audio, gyro_x_down);

fprintf('Correlation between Audio RMS and Accel X: %.4f\n', corr_rms_accx(1,2));
fprintf('Correlation between Audio Variance and Accel X: %.4f\n', corr_var_accx(1,2));
fprintf('Correlation between Audio RMS and Gyro X: %.4f\n', corr_rms_gyrox(1,2));
fprintf('Correlation between Audio Variance and Gyro X: %.4f\n', corr_var_gyrox(1,2));

%% Plot Correlation Trends
time_axis_corr = (1:num_windows);

%figure;
%subplot(2,1,1);
%plot(time_axis_corr, rms_audio, '-o', 'DisplayName', 'Audio RMS');
%hold on;
%plot(time_axis_corr, acc_x_down, '-x', 'DisplayName', 'Accel X (mg)');
%legend;
%xlabel('Window Index');
%ylabel('Value');
%title('Audio RMS and Accel X Correlation Trend');
%grid on;

%subplot(2,1,2);
%plot(time_axis_corr, var_audio, '-o', 'DisplayName', 'Audio Variance');
%hold on;
%plot(time_axis_corr, gyro_x_down, '-x', 'DisplayName', 'Gyro X (mdps)');
%legend;
%xlabel('Window Index');
%ylabel('Value');
%title('Audio Variance and Gyro X Correlation Trend');
%grid on;

%sgtitle('Audio-IMU Correlation Analysis (LMS Filtered Audio)');

t_audio = (0:length(y2)-1) / sr;

figure;
plot(t_audio, y1, 'b', 'DisplayName', 'Original Audio (y1)');
hold on;
plot(t_audio, y2, 'g', 'DisplayName', 'Reference Audio (y2)');
plot(t_audio, lms_error, 'r', 'DisplayName', 'Error Signal');
xlabel('Time (s)');
ylabel('Amplitude');
title('Waveform Comparison: Original, Reference, and Error Signal');
legend;
grid on;


N = length(y2);
f = (0:N-1)*(sr/N);

Y_y1 = abs(fft(y1))/N;
Y_y2 = abs(fft(y2))/N;
Y_error = abs(fft(lms_error))/N;

figure;
plot(f(1:N/2), Y_y1(1:N/2), 'b', 'DisplayName', 'Original Audio');
hold on;
plot(f(1:N/2), Y_y2(1:N/2), 'g', 'DisplayName', 'Reference Audio');
plot(f(1:N/2), Y_error(1:N/2), 'r', 'DisplayName', 'Error Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT Spectrum Comparison');
legend;
xlim([0 sr/2]);
grid on;


N = length(y2);
f = (0:N-1)*(sr/N);

Y_y1 = abs(fft(y1))/N;
Y_y2 = abs(fft(y2))/N;
Y_error = abs(fft(lms_error))/N;

figure;
plot(f(1:N/2), Y_y1(1:N/2), 'b', 'DisplayName', 'Original Audio');
hold on;
plot(f(1:N/2), Y_y2(1:N/2), 'g', 'DisplayName', 'Reference Audio');
plot(f(1:N/2), Y_error(1:N/2), 'r', 'DisplayName', 'Error Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT Spectrum Comparison');
legend;
xlim([0 sr/2]);
grid on;


% Interpolating error RMS to IMU timestamps
error_rms_per_sample = movmean(abs(lms_error), sr); % 1 sec moving RMS

error_rms_at_imu = interp1(t_audio, error_rms_per_sample, time_imu, 'linear', 'extrap');

%figure;
%subplot(2,1,1);
%plot(time_imu, acc_x, 'b', 'DisplayName', 'Accel X (mg)');
%hold on;
%plot(time_imu, error_rms_at_imu, 'r', 'DisplayName', 'Error RMS');
%xlabel('Time (s)');
%ylabel('Value');
%title('Accel X vs Error Signal RMS');
%legend;
%grid on;

%subplot(2,1,2);
%plot(time_imu, gyro_x, 'g', 'DisplayName', 'Gyro X (mdps)');
%hold on;
%plot(time_imu, error_rms_at_imu, 'r', 'DisplayName', 'Error RMS');
%xlabel('Time (s)');
%ylabel('Value');
%title('Gyro X vs Error Signal RMS');
%legend;
%grid on;


% Time axis for audio
t_audio = (0:length(y2)-1) / sr;

figure;
subplot(2,1,1);
plot(t_audio, y2, 'g');
xlabel('Time (s)');
ylabel('Amplitude');
title('Reference Sound (y2)');
grid on;

subplot(2,1,2);
plot(t_audio, lms_error, 'r');
xlabel('Time (s)');
ylabel('Amplitude');
title('Error Signal (After LMS Filtering)');
grid on;

sgtitle('Waveform Comparison: Reference Sound vs Error Signal');

%% Comparison Plot: Original vs LMS Filtered Waveform (Side-by-Side + Overlay)
figure;

% Original Audio
subplot(3, 1, 1);
plot(t_audio, y1, 'b');
title('Original Audio Waveform (y1)');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
xlim([0 max(t_audio)]);

% LMS Filtered Audio (Error Signal)
subplot(3, 1, 2);
plot(t_audio, lms_error, 'r');
title('Filtered Audio Waveform (LMS Error Signal)');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
xlim([0 max(t_audio)]);

% Both Overlaid
subplot(3, 1, 3);
plot(t_audio, y1, 'b', 'DisplayName', 'Original Audio');
hold on;
plot(t_audio, lms_error, 'r', 'DisplayName', 'LMS Filtered Audio');
title('Overlay: Original vs LMS Filtered Audio Waveform');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
legend('show');
xlim([0 max(t_audio)]);

sgtitle('Original vs LMS Filtered Audio: Side-by-Side and Overlay Comparison');

%% Audio Statistics Comparison: y2 (Reference) vs lms_error (Filtered)

% Statistics for y2
mean_y2 = mean(y2);
var_y2 = var(y2);
std_y2 = std(y2);
rms_y2 = rms(y2);
max_y2 = max(y2);
min_y2 = min(y2);

% Statistics for lms_error (Filtered)
mean_filt = mean(lms_error);
var_filt = var(lms_error);
std_filt = std(lms_error);
rms_filt = rms(lms_error);
max_filt = max(lms_error);
min_filt = min(lms_error);

% Pearson Correlation
corr_value = corr(y2, lms_error);

% Signal-to-Noise Ratio (SNR) in dB
signal_power = mean(y2.^2);
noise_power = mean((y2 - lms_error).^2);
snr_value = 10*log10(signal_power / noise_power);

% Percentage Difference Calculations
perc_diff_var = 100 * abs(var_y2 - var_filt) / var_y2;
perc_diff_std = 100 * abs(std_y2 - std_filt) / std_y2;
perc_diff_rms = 100 * abs(rms_y2 - rms_filt) / rms_y2;

% Peak Signal-to-Noise Ratio (PSNR)
max_val = max(abs(y2));
mse = mean((y2 - lms_error).^2);
psnr_value = 10 * log10(max_val^2 / mse);

% Display Results
fprintf('\nStatistics for y2:\n');
fprintf('    mean: %.4e\n    var: %.4e\n    std: %.4f\n    rms: %.4f\n    max: %.4f\n    min: %.4f\n', ...
    mean_y2, var_y2, std_y2, rms_y2, max_y2, min_y2);

fprintf('\nStatistics for lms_error:\n');
fprintf('    mean: %.4e\n    var: %.4e\n    std: %.4f\n    rms: %.4f\n    max: %.4f\n    min: %.4f\n', ...
    mean_filt, var_filt, std_filt, rms_filt, max_filt, min_filt);

fprintf('\nPearson Correlation: %.5f\n', corr_value);
fprintf('SNR (dB): %.4f\n', snr_value);
fprintf('Percentage Difference in Variance: %.2f%%\n', perc_diff_var);
fprintf('Percentage Difference in Std Dev : %.2f%%\n', perc_diff_std);
fprintf('Percentage Difference in RMS     : %.2f%%\n', perc_diff_rms);
fprintf('Overall PSNR between y2 and lms_error: %.2f dB\n', psnr_value);
