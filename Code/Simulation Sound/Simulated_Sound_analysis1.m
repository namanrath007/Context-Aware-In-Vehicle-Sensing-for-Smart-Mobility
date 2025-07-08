% 1. Read microphone signal (N)
[mic_signal, fs_mic] = audioread("D:\STMicroelectronics\Matlab_Main\Code\Simulation Sound\simulated_sound1.wav");
time_mic = (0:length(mic_signal)-1) / fs_mic;

figure;
plot(time_mic, mic_signal);
title('Microphone Signal (N)');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

% 2. Read IMU data
opts = detectImportOptions("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", 'Delimiter', ',');
imu_data = readtable("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", opts);
disp(imu_data.Properties.VariableNames);

% Extract numeric arrays
acc_x = imu_data.accX_mg_;
acc_y = imu_data.accY_mg_;
acc_z = imu_data.accZ_mg_;
gyro_x = imu_data.gyroX_mdps_;
gyro_y = imu_data.gyroY_mdps_;
gyro_z = imu_data.gyroZ_mdps_;

% 3. Convert unsigned to signed (if needed)
max_unsigned = 65536; half_range = 32768;
acc_x(acc_x >= half_range) = acc_x(acc_x >= half_range) - max_unsigned;
acc_y(acc_y >= half_range) = acc_y(acc_y >= half_range) - max_unsigned;
acc_z(acc_z >= half_range) = acc_z(acc_z >= half_range) - max_unsigned;
gyro_x(gyro_x >= half_range) = gyro_x(gyro_x >= half_range) - max_unsigned;
gyro_y(gyro_y >= half_range) = gyro_y(gyro_y >= half_range) - max_unsigned;
gyro_z(gyro_z >= half_range) = gyro_z(gyro_z >= half_range) - max_unsigned;

% Convert units
acc_x = acc_x / 1000; acc_y = acc_y / 1000; acc_z = acc_z / 1000;
gyro_x = gyro_x / 1000; gyro_y = gyro_y / 1000; gyro_z = gyro_z / 1000;

% Clean IMU signals before filtering (remove NaNs/Infs)
acc_x(~isfinite(acc_x)) = 0;
acc_y(~isfinite(acc_y)) = 0;
acc_z(~isfinite(acc_z)) = 0;
gyro_x(~isfinite(gyro_x)) = 0;
gyro_y(~isfinite(gyro_y)) = 0;
gyro_z(~isfinite(gyro_z)) = 0;

% 4. Design a bandpass filter for IMU noise components (0.5–50 Hz)
fs_imu_est = height(imu_data) / 60; % 60 sec recording
disp(['Estimated IMU Sampling Rate: ', num2str(fs_imu_est), ' Hz']);

bpFilt = designfilt('bandpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 0.5, 'HalfPowerFrequency2', min(50, fs_imu_est/2-1), ...
    'SampleRate', fs_imu_est);

% 5. Apply bandpass filter to IMU data
acc_x = filtfilt(bpFilt, acc_x);
acc_y = filtfilt(bpFilt, acc_y);
acc_z = filtfilt(bpFilt, acc_z);
gyro_x = filtfilt(bpFilt, gyro_x);
gyro_y = filtfilt(bpFilt, gyro_y);
gyro_z = filtfilt(bpFilt, gyro_z);

% Clean IMU signals after filtering (remove NaNs/Infs if any)
acc_x(~isfinite(acc_x)) = 0;
acc_y(~isfinite(acc_y)) = 0;
acc_z(~isfinite(acc_z)) = 0;
gyro_x(~isfinite(gyro_x)) = 0;
gyro_y(~isfinite(gyro_y)) = 0;
gyro_z(~isfinite(gyro_z)) = 0;

% 6. Combine IMU channels to generate anti-noise signal (mean of all)
anti_noise_signal = (acc_x + acc_y + acc_z + gyro_x + gyro_y + gyro_z) / 6;

% 7. Resample anti-noise signal to match mic sampling rate
anti_noise_resampled = resample(anti_noise_signal, fs_mic, fs_imu_est);

% 8. Match lengths
N = min(length(mic_signal), length(anti_noise_resampled));
mic_signal = mic_signal(1:N);
anti_noise_resampled = anti_noise_resampled(1:N);
time_mic = time_mic(1:N);

% 9. Clean NaNs/Infs (final precaution)
mic_signal(~isfinite(mic_signal)) = 0;
anti_noise_resampled(~isfinite(anti_noise_resampled)) = 0;

% 10. LMS Adaptive Filtering
filter_order = 64;
mu = 0.00005;
lms_filter = dsp.LMSFilter('Length', filter_order, 'StepSize', mu);
[~, error_signal] = lms_filter(anti_noise_resampled, mic_signal);

% Clean error signal
error_signal(~isfinite(error_signal)) = 0;
error_signal = error_signal / max(abs(error_signal));

% 11. Plot results

% Time-domain plots
figure;
subplot(3,1,1);
plot(time_mic, mic_signal); title('Microphone Signal (N)');
subplot(3,1,2);
plot(time_mic, anti_noise_resampled); title('IMU Anti-Noise Signal (N*)');
subplot(3,1,3);
plot(time_mic, error_signal); title('Error Signal (~)');

% Frequency-domain plot
nfft = 2^nextpow2(N);
f = fs_mic/2 * linspace(0,1,nfft/2+1);
mic_fft = abs(fft(mic_signal, nfft))/N;
error_fft = abs(fft(error_signal, nfft))/N;

figure;
plot(f, 2*mic_fft(1:nfft/2+1), 'b');
hold on;
plot(f, 2*error_fft(1:nfft/2+1), 'r');
title('Frequency Spectrum');
legend('Mic Signal (N)', 'Error Signal (~)');
xlabel('Frequency (Hz)'); ylabel('Amplitude'); grid on;

% Spectrograms
figure;
spectrogram(mic_signal, 256, 200, 512, fs_mic, 'yaxis'); title('Mic Spectrogram');
figure;
spectrogram(error_signal, 256, 200, 512, fs_mic, 'yaxis'); title('Error Signal Spectrogram');

% 12. Write error signal to .wav file
output_folder = "D:\STMicroelectronics\Matlab_Main\Code\Simulation Sound\Output";
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
filename = fullfile(output_folder, "error_signal1.wav");
audiowrite(filename, error_signal, fs_mic);

disp("✅ Error signal written to: " + filename);

% 13. Numerical comparison between original mic signal and error signal

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
