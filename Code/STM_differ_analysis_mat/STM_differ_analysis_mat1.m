%% 1. Read mic signal from V1 (Engine Sound(N) + External Audio(S))
[mic_signal, fs_mic] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\1min.wav");
time_mic = (0:length(mic_signal)-1) / fs_mic;

figure;
plot(time_mic, mic_signal);
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

%% 2. Read IMU data from V2 (Engine Sound(N))
opts = detectImportOptions("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", 'Delimiter', ',');
imu_data = readtable("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", opts);
disp(imu_data.Properties.VariableNames);

% Extract relevant numeric arrays
acc_x = imu_data.accX_mg_;
acc_y = imu_data.accY_mg_;
acc_z = imu_data.accZ_mg_;

gyro_x = imu_data.gyroX_mdps_;
gyro_y = imu_data.gyroY_mdps_;
gyro_z = imu_data.gyroZ_mdps_;

%% 3. Convert unsigned to signed (if needed) and scale
max_unsigned = 65536;
half_range = 32768;

acc_x(acc_x >= half_range) = acc_x(acc_x >= half_range) - max_unsigned;
acc_y(acc_y >= half_range) = acc_y(acc_y >= half_range) - max_unsigned;
acc_z(acc_z >= half_range) = acc_z(acc_z >= half_range) - max_unsigned;

acc_x = acc_x / 1000;  % mg to g
acc_y = acc_y / 1000;
acc_z = acc_z / 1000;

gyro_x(gyro_x >= half_range) = gyro_x(gyro_x >= half_range) - max_unsigned;
gyro_y(gyro_y >= half_range) = gyro_y(gyro_y >= half_range) - max_unsigned;
gyro_z(gyro_z >= half_range) = gyro_z(gyro_z >= half_range) - max_unsigned;

gyro_x = gyro_x / 1000; % mdps to dps
gyro_y = gyro_y / 1000;
gyro_z = gyro_z / 1000;

% Remove NaNs/Infs from IMU data
acc_x(~isfinite(acc_x)) = 0;
acc_y(~isfinite(acc_y)) = 0;
acc_z(~isfinite(acc_z)) = 0;

gyro_x(~isfinite(gyro_x)) = 0;
gyro_y(~isfinite(gyro_y)) = 0;
gyro_z(~isfinite(gyro_z)) = 0;


%% 4. Estimate IMU sampling rate
num_samples = height(imu_data);
recording_duration = 60;  % seconds
fs_imu = num_samples / recording_duration;
disp(['Estimated IMU Sampling Rate: ', num2str(fs_imu), ' Hz']);

%% 5. Bandpass filter IMU signals (30-500 Hz band)
bpFilt = designfilt('bandpassiir', 'FilterOrder', 4, ...
         'HalfPowerFrequency1', 5, 'HalfPowerFrequency2', 40, ...
         'SampleRate', fs_imu);


acc_x_f = filtfilt(bpFilt, acc_x);
acc_y_f = filtfilt(bpFilt, acc_y);
acc_z_f = filtfilt(bpFilt, acc_z);

% Optional: Include gyro signals if you want
% gyro_x_f = filtfilt(bpFilt, gyro_x);
% gyro_y_f = filtfilt(bpFilt, gyro_y);
% gyro_z_f = filtfilt(bpFilt, gyro_z);

%% 6. Combine filtered IMU signals to produce anti-noise
anti_noise_signal = (acc_x_f + acc_y_f + acc_z_f) / 3;

%% 7. Resample anti-noise signal to match mic sampling rate
anti_noise_resampled = resample(anti_noise_signal, fs_mic, fs_imu);
anti_noise_signal(~isfinite(anti_noise_signal)) = 0;

%% 8. Match signal lengths
N = min(length(mic_signal), length(anti_noise_resampled));
mic_signal = mic_signal(1:N);
anti_noise_resampled = anti_noise_resampled(1:N);
time_mic = time_mic(1:N);

% Clean NaNs and Infs
mic_signal(isnan(mic_signal) | isinf(mic_signal)) = 0;
anti_noise_resampled(isnan(anti_noise_resampled) | isinf(anti_noise_resampled)) = 0;

%% 9. Rescale anti-noise signal to mic signal RMS
anti_noise_resampled = anti_noise_resampled * (rms(mic_signal) / rms(anti_noise_resampled));

%% 10. Apply LMS adaptive filter
filterOrder = 64;
mu = 0.001679;  % adjusted for faster adaptation
lms_filter = dsp.LMSFilter('Length', filterOrder, 'StepSize', mu);

[~, error_signal] = lms_filter(anti_noise_resampled, mic_signal);

% Clean NaNs/Infs in error signal
error_signal(isnan(error_signal) | isinf(error_signal)) = 0;



%% 11. Time Domain Plot

% Read original clean sound signal (S)
[clean_signal, fs_clean] = audioread("D:\STMicroelectronics\Data_Collection\Only_extAudio\Microphone_Data\2min\2min.wav");

% Resample if needed to match mic/error signal sampling rate
if fs_clean ~= fs_mic
    clean_signal = resample(clean_signal, fs_mic, fs_clean);
end

% Match signal lengths
N_compare = min([length(clean_signal), length(mic_signal)]);
clean_signal = clean_signal(1:N_compare);
mic_signal_plot = mic_signal(1:N_compare);
anti_noise_resampled_plot = anti_noise_resampled(1:N_compare);
error_signal_plot = error_signal(1:N_compare);
time_plot = time_mic(1:N_compare);

% Clean NaNs/Infs
clean_signal(~isfinite(clean_signal)) = 0;

% Plot all four signals in time domain
figure;
subplot(4,1,1);
plot(time_plot, mic_signal_plot);
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,2);
plot(time_plot, anti_noise_resampled_plot);
title('IMU-based Anti-Noise Signal (N*)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,3);
plot(time_plot, error_signal_plot);
title('Error Signal (~S)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,4);
plot(time_plot, clean_signal);
title('Original Clean Signal (S)');
xlabel('Time (s)'); ylabel('Amplitude');

sgtitle('Time Domain Comparison of All Signals');


%% 11. Time Domain Plot
%figure;
%subplot(3,1,1);
%plot(time_mic, mic_signal);
%title('Microphone Signal (S+N)');
%xlabel('Time (s)'); ylabel('Amplitude');

%subplot(3,1,2);
%plot(time_mic, anti_noise_resampled);
%title('IMU-based Anti-Noise Signal (N*)');
%xlabel('Time (s)'); ylabel('Amplitude');

%subplot(3,1,3);
%plot(time_mic, error_signal);
%title('Error Signal (~S)');
%xlabel('Time (s)'); ylabel('Amplitude');


%% 12. Frequency Domain Plot
nfft = 2^nextpow2(N);
f = fs_mic/2 * linspace(0,1,nfft/2+1);
mic_fft = abs(fft(mic_signal, nfft))/N;
error_fft = abs(fft(error_signal, nfft))/N;

figure;
plot(f, 2*mic_fft(1:nfft/2+1), 'b');
hold on;
plot(f, 2*error_fft(1:nfft/2+1), 'r');
title('Frequency Spectrum Comparison');
legend('Mic Signal (S+N)', 'Error Signal (~S)');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
grid on;

%% 13. Spectrograms
figure;
spectrogram(mic_signal, 256, 200, 512, fs_mic, 'yaxis');
title('Mic Signal Spectrogram');

figure;
spectrogram(error_signal, 256, 200, 512, fs_mic, 'yaxis');
title('Error Signal Spectrogram');

%% 14. Write Error Signal to WAV File
output_folder = "D:\STMicroelectronics\Matlab_Main\Code\STM_differ_analysis_mat\Output";
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
filename = fullfile(output_folder, "error_signal1.wav");

% Normalize to avoid clipping
error_signal = error_signal / max(abs(error_signal));

% Write to WAV file
audiowrite(filename, error_signal, fs_mic);

disp('Processing complete! Error signal saved.');

%% 15. Numerical comparison between original mic signal and error signal

% Mean Squared Error (MSE)
mse_val = mean((mic_signal - error_signal).^2);

% Root Mean Squared Error (RMSE)
rmse_val = sqrt(mse_val);

% Signal-to-Error Ratio (SER)
signal_power = mean(mic_signal.^2);
error_power = mean((mic_signal - error_signal).^2);
ser_val = 10 * log10(signal_power / error_power);

% Percentage difference in RMS values
rms_mic = rms(mic_signal);
rms_error = rms(error_signal);
percentage_diff_rms = ((rms_mic - rms_error) / rms_mic) * 100;

% Display the results
fprintf('\n📊 Numerical Comparison Metrics:\n');
fprintf('Mean Squared Error (MSE): %.6f\n', mse_val);
fprintf('Root Mean Squared Error (RMSE): %.6f\n', rmse_val);
fprintf('Signal-to-Error Ratio (SER): %.2f dB\n', ser_val);
fprintf('Percentage Difference in RMS: %.2f%%\n', percentage_diff_rms);

%% 16. Spectral Coherence between Microphone Signal and Error Signal

% Use mscohere function (Welch's method) to compute magnitude-squared coherence
window_length = 1024;
noverlap = 512;
nfft_coh = 2048;

[coh,f_coh] = mscohere(mic_signal, error_signal, window_length, noverlap, nfft_coh, fs_mic);

% Plot the coherence 
figure;
plot(f_coh, coh, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude-Squared Coherence');
title('Spectral Coherence between Mic Signal and Error Signal');
ylim([0 1]);

%% 17. Compare Error Signal to Original Clean Signal (S)

%% 17. Compare Error Signal to Original Clean Signal (S)

% Ensure signals are aligned in length
N_compare = min(length(clean_signal), length(error_signal));
clean_signal_compare = clean_signal(1:N_compare);
error_signal_compare = error_signal(1:N_compare);

% Numerical comparison
mse_clean_err = mean((clean_signal_compare - error_signal_compare).^2);
rmse_clean_err = sqrt(mse_clean_err);
signal_power_clean = mean(clean_signal_compare.^2);
error_power_clean = mean((clean_signal_compare - error_signal_compare).^2);
ser_clean_err = 10 * log10(signal_power_clean / error_power_clean);

rms_clean = rms(clean_signal_compare);
rms_err_compare = rms(error_signal_compare);
percentage_diff_rms_clean = ((rms_clean - rms_err_compare) / rms_clean) * 100;

% Display results
fprintf('\n📊 Numerical Comparison with Original Clean Signal (S):\n');
fprintf('Mean Squared Error (MSE): %.6f\n', mse_clean_err);
fprintf('Root Mean Squared Error (RMSE): %.6f\n', rmse_clean_err);
fprintf('Signal-to-Error Ratio (SER): %.2f dB\n', ser_clean_err);
fprintf('Percentage Difference in RMS: %.2f%%\n', percentage_diff_rms_clean);

% Spectral Coherence between Clean Signal (S) and Error Signal (~S)
[coh_clean_err, f_coh_clean] = mscohere(clean_signal_compare, error_signal_compare, window_length, noverlap, nfft_coh, fs_mic);

% Plot the coherence
figure;
plot(f_coh_clean, coh_clean_err, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude-Squared Coherence');
title('Spectral Coherence between Clean Signal (S) and Error Signal (~S)');
ylim([0 1]);
