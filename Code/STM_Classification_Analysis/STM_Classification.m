%% Analysis for Engine Noise with an external Audio
%% Initialization
clear; clc; close all;

%% Sampling rate
sr = 16000;

%% Load audio files (first 30 seconds)
[y1, fs1] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_with_extAudio\Microphone_Data\2min\2min1_ext.wav", [1 sr*30]);
[y2, fs2] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\Only_extAudio\Microphone_Data\2min\2min.wav", [1 sr*30]);

% Ensure mono
if size(y1, 2) > 1
    y1 = mean(y1, 2);
end
if size(y2, 2) > 1
    y2 = mean(y2, 2);
end

%% Play audios
%sound(y1, sr);
%pause(5);
%sound(y2, sr);


%% Apply High-Pass Filter
[b, a] = butter(10, 200/(sr/2), 'high');
yrf1 = filter(b, a, y1);

%% Combined Waveform Plot
figure;

subplot(3,1,1);
plot((0:length(y1)-1)/sr, y1);
title('Original Audio [Engine Noise + Sound (y1)]');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot((0:length(y2)-1)/sr, y2);
title('External Audio [Sound (y2)]');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot((0:length(yrf1)-1)/sr, yrf1);
title('Filtered Audio (High-pass) (yrf1)');
xlabel('Time (s)'); ylabel('Amplitude');

sgtitle('Waveform Comparison: Original, External, and Filtered Audio');

% Optional: Play filtered audio again if you like
sound(yrf1, sr);

%% Compute Mel Spectrogram
figure;
subplot(1,2,1);
melSpectrogram(y2, sr, 'WindowLength',512, 'OverlapLength',256, 'NumBands',64);
title('Mel Spectrogram of y2');

subplot(1,2,2);
melSpectrogram(yrf1, sr, 'WindowLength',512, 'OverlapLength',256, 'NumBands',64);
title('Mel Spectrogram of yrf1');

%% Compute FFT
N = length(y1);
f = (0:N-1)*(sr/N);

Y_y2 = abs(fft(y2))/N;
Y_yrf1 = abs(fft(yrf1))/N;

figure;
plot(f(1:N/2), Y_y2(1:N/2));
hold on;
plot(f(1:N/2), Y_yrf1(1:N/2));
title('FFT Comparison');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
legend('y2', 'yrf1');
xlim([0 8000]);
grid on;

%% Numerical Statistics
stats_y2.mean = mean(y2);
stats_y2.var = var(y2);
stats_y2.std = std(y2);
stats_y2.rms = rms(y2);
stats_y2.max = max(y2);
stats_y2.min = min(y2);

stats_yrf1.mean = mean(yrf1);
stats_yrf1.var = var(yrf1);
stats_yrf1.std = std(yrf1);
stats_yrf1.rms = rms(yrf1);
stats_yrf1.max = max(yrf1);
stats_yrf1.min = min(yrf1);

disp('Statistics for y2:');
disp(stats_y2);
disp('Statistics for yrf1:');
disp(stats_yrf1);

%% Correlation
corr_val = corrcoef(y2, yrf1);
disp(['Pearson Correlation: ', num2str(corr_val(1,2))]);

%% SNR Estimation (assuming y2 is clean)
signal_power = mean(y2.^2);
noise_power = mean((y2 - yrf1).^2);
snr_val = 10 * log10(signal_power / noise_power);
disp(['SNR (dB): ', num2str(snr_val)]);

%% Percentage Difference
percentage_diff = @(v1,v2) ((v1-v2)/v1)*100;

var_diff = percentage_diff(stats_y2.var, stats_yrf1.var);
std_diff = percentage_diff(stats_y2.std, stats_yrf1.std);
rms_diff = percentage_diff(stats_y2.rms, stats_yrf1.rms);

fprintf('Percentage Difference in Variance: %.2f%%\n', var_diff);
fprintf('Percentage Difference in Std Dev : %.2f%%\n', std_diff);
fprintf('Percentage Difference in RMS     : %.2f%%\n', rms_diff);


%% Parameters for sliding correlation
window_duration = 1;               % in seconds
window_size = window_duration * sr;
hop_size = sr * 0.5;               % 50% overlap

num_windows = floor((length(y2) - window_size) / hop_size) + 1;
corr_values = zeros(num_windows, 1);
time_axis = zeros(num_windows, 1);

%% Sliding window correlation calculation
for k = 1:num_windows
    start_idx = (k-1)*hop_size + 1;
    end_idx = start_idx + window_size - 1;
    
    segment_y2 = y2(start_idx:end_idx);
    segment_yrf1 = yrf1(start_idx:end_idx);
    
    R = corrcoef(segment_y2, segment_yrf1);
    corr_values(k) = R(1,2);
    
    time_axis(k) = (start_idx + end_idx) / (2*sr); % center time of window
end

%% Plot correlation over time
figure;
plot(time_axis, corr_values, '-o', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Pearson Correlation Coefficient');
title('Time-varying Correlation between y2 and yrf1');
grid on;
ylim([-1 1]);

%% Display mean correlation over entire signal
overall_corr = corrcoef(y2, yrf1);
fprintf('Overall Pearson Correlation between y2 and yrf1: %.4f\n', overall_corr(1,2));

%% Function to compute PSNR
psnr_val = @(ref, test) 10*log10(max(ref).^2 / mean((ref - test).^2));

%% Parameters for sliding PSNR
window_duration = 1;               % in seconds
window_size = window_duration * sr;
hop_size = sr * 0.5;               % 50% overlap

num_windows = floor((length(y2) - window_size) / hop_size) + 1;
psnr_values = zeros(num_windows, 1);
time_axis_psnr = zeros(num_windows, 1);

%% Sliding window PSNR calculation
for k = 1:num_windows
    start_idx = (k-1)*hop_size + 1;
    end_idx = start_idx + window_size - 1;
    
    segment_y2 = y2(start_idx:end_idx);
    segment_yrf1 = yrf1(start_idx:end_idx);
    
    psnr_values(k) = psnr_val(segment_y2, segment_yrf1);
    time_axis_psnr(k) = (start_idx + end_idx) / (2*sr); % center time of window
end

%% Plot PSNR over time
figure;
plot(time_axis_psnr, psnr_values, '-o', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('PSNR (dB)');
title('Time-varying PSNR between y2 and yrf1');
grid on;

%% Global PSNR for entire signal
global_psnr = psnr_val(y2, yrf1);
fprintf('Overall PSNR between y2 and yrf1: %.2f dB\n', global_psnr);
