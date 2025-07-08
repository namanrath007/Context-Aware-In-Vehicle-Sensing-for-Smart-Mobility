% 1. Read mic signal from V1 (Engine Sound(N) + External Audio(S))
[mic_signal, fs_mic] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\1min.wav");
time_mic = (0:length(mic_signal)-1) / fs_mic;

figure;
plot(time_mic, mic_signal);
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

% 2. Read IMU data
opts = detectImportOptions("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", 'Delimiter', ',');
imu_data = readtable("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\1min.csv", opts);
disp(imu_data.Properties.VariableNames);

% Convert to numeric arrays
acc_x = imu_data.accX_mg_;
acc_y = imu_data.accY_mg_;
acc_z = imu_data.accZ_mg_;

gyro_x = imu_data.gyroX_mdps_;
gyro_y = imu_data.gyroY_mdps_;
gyro_z = imu_data.gyroZ_mdps_;

% 3. Convert unsigned to signed for accelerometer (mg) and gyro (mdps)
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

% 4. Produce anti-noise signal (V2)
anti_noise_signal = (acc_x + acc_y + acc_z + gyro_x + gyro_y + gyro_z) / 6;

% 5. Estimate IMU sampling rate
num_samples = height(imu_data);
recording_duration = 60;  % in seconds
fs_imu = num_samples / recording_duration;
disp(['Estimated IMU Sampling Rate: ', num2str(fs_imu), ' Hz']);

% 6. Resample the anti-noise signal to match mic sampling rate
anti_noise_resampled = resample(anti_noise_signal, fs_mic, fs_imu);

% 7. Match signal lengths
N = min(length(mic_signal), length(anti_noise_resampled));
mic_signal = mic_signal(1:N);
anti_noise_resampled = anti_noise_resampled(1:N);
time_mic = time_mic(1:N);

% --- Clean NaNs and Infs before LMS filtering ---
mic_signal(isnan(mic_signal) | isinf(mic_signal)) = 0;
anti_noise_resampled(isnan(anti_noise_resampled) | isinf(anti_noise_resampled)) = 0;

% 8. Apply LMS adaptive filter
filter_order = 64;
mu = 0.0001;
lms_filter = dsp.LMSFilter('Length', filter_order, 'StepSize', mu);
[~, error_signal] = lms_filter(anti_noise_resampled, mic_signal);

% --- Clean NaNs/Infs in error signal before plotting ---
error_signal(isnan(error_signal) | isinf(error_signal)) = 0;

% 9. Time Domain Plot
figure;
subplot(3,1,1);
plot(time_mic, mic_signal);
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(time_mic, anti_noise_resampled);
title('IMU-based Anti-Noise Signal (N*)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(time_mic, error_signal);
title('Error Signal (~S)');
xlabel('Time (s)'); ylabel('Amplitude');

% 10. Frequency Domain Plot
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

% 11. Spectrograms
figure;
spectrogram(mic_signal, 256, 200, 512, fs_mic, 'yaxis');
title('Mic Signal Spectrogram');

figure;
spectrogram(error_signal, 256, 200, 512, fs_mic, 'yaxis');
title('Error Signal Spectrogram');


output_folder = "D:\STMicroelectronics\Matlab_Main\Code\STM_differ_analysis_mat\Output";

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

filename = fullfile(output_folder, "error_signal.wav");

% Normalize error_signal to avoid clipping
error_signal = error_signal / max(abs(error_signal));

% Write to WAV file
audiowrite(filename, error_signal, fs_mic);
