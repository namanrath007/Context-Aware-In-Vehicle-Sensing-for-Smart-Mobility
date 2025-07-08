%% 1. Read mic signal from V1 (Engine Sound(N) + External Audio(S))
[mic_signal, fs_mic] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\2min\2min.wav");
time_mic = (0:length(mic_signal)-1) / fs_mic;

figure;
plot(time_mic, mic_signal);
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

%% 2. Read IMU data from V2 (Engine Sound(N))
opts = detectImportOptions("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\2min\2min.csv", 'Delimiter', ',');
imu_data = readtable("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\2min\2min.csv", opts);
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

%% 5. Bandpass filter IMU signals (5-40 Hz band)
bpFilt = designfilt('bandpassiir', 'FilterOrder', 4, ...
         'HalfPowerFrequency1', 5, 'HalfPowerFrequency2', 40, ...
         'SampleRate', fs_imu);

acc_x_f = filtfilt(bpFilt, acc_x);
acc_y_f = filtfilt(bpFilt, acc_y);
acc_z_f = filtfilt(bpFilt, acc_z);

gyro_x_f = filtfilt(bpFilt, gyro_x);
gyro_y_f = filtfilt(bpFilt, gyro_y);
gyro_z_f = filtfilt(bpFilt, gyro_z);

%% 6. Combine filtered IMU signals to produce anti-noise reference
% You can use only accelerometer signals, or include gyroscope signals for better noise modeling
anti_noise_signal = (acc_x_f + acc_y_f + acc_z_f) / 3;
% anti_noise_signal = (acc_x_f + acc_y_f + acc_z_f + gyro_x_f + gyro_y_f + gyro_z_f) / 6; % Uncomment to include gyro

%% 7. Resample anti-noise signal to match mic sampling rate
[P, Q] = rat(fs_mic / fs_imu, 1e-6);  % 1e-6 tolerance for high accuracy
anti_noise_resampled = resample(anti_noise_signal, P, Q);

% Remove NaNs/Infs
anti_noise_resampled(~isfinite(anti_noise_resampled)) = 0;

%% 8. Match signal lengths
N = min(length(mic_signal), length(anti_noise_resampled));
mic_signal = mic_signal(1:N);
anti_noise_resampled = anti_noise_resampled(1:N);
time_mic = time_mic(1:N);

mic_signal(isnan(mic_signal) | isinf(mic_signal)) = 0;
anti_noise_resampled(isnan(anti_noise_resampled) | isinf(anti_noise_resampled)) = 0;

%% 9. Align signals using cross-correlation for best time alignment
[xcorr_val, lag] = xcorr(mic_signal, anti_noise_resampled);
[~, I] = max(abs(xcorr_val));
time_shift = lag(I);

if time_shift > 0
    anti_noise_resampled = [zeros(time_shift,1); anti_noise_resampled(1:end-time_shift)];
elseif time_shift < 0
    anti_noise_resampled = anti_noise_resampled(-time_shift+1:end);
end

% Adjust length after alignment
N = min(length(mic_signal), length(anti_noise_resampled));
mic_signal = mic_signal(1:N);
anti_noise_resampled = anti_noise_resampled(1:N);
time_mic = time_mic(1:N);

%% 10. Rescale anti-noise signal to mic signal RMS
anti_noise_resampled = anti_noise_resampled * (rms(mic_signal) / rms(anti_noise_resampled));

%% 11. Apply Normalized LMS adaptive filter
function [y, e] = normalized_lms(x, d, mu, filterOrder)
    % x: reference input (anti-noise)
    % d: desired signal (microphone)
    % mu: step size
    % filterOrder: length of adaptive filter
    
    N = length(x);
    w = zeros(filterOrder,1); % filter weights initialization
    y = zeros(N,1);           % filter output
    e = zeros(N,1);           % error signal

    epsilon = 1e-6; % small constant to avoid division by zero

    for n = filterOrder:N
        x_vec = x(n:-1:n-filterOrder+1);   % input vector (most recent samples)
        y(n) = w' * x_vec;                 % filter output
        e(n) = d(n) - y(n);                % error signal

        norm_x = (x_vec'*x_vec) + epsilon; % power of input vector
        w = w + (mu / norm_x) * x_vec * e(n); % NLMS update
    end
end

filterOrder = 128;
mu = 0.0005;

[~, error_signal] = normalized_lms(anti_noise_resampled, mic_signal, mu, filterOrder);


%% 12. Read original clean sound signal (S)
[clean_signal, fs_clean] = audioread("D:\STMicroelectronics\Data_Collection\Only_extAudio\Microphone_Data\2min\2min.wav");

% Resample clean signal if needed to match mic/error signal sampling rate
if fs_clean ~= fs_mic
    clean_signal = resample(clean_signal, fs_mic, fs_clean);
end

% Match lengths for comparison
N_compare = min([length(clean_signal), length(error_signal)]);
clean_signal = clean_signal(1:N_compare);
error_signal = error_signal(1:N_compare);
time_plot = time_mic(1:N_compare);

clean_signal(~isfinite(clean_signal)) = 0;

%% 13. Time Domain Plot
figure;
subplot(3,1,1);
plot(time_plot, mic_signal(1:N_compare));
title('Microphone Signal (S+N)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(time_plot, error_signal);
title('Estimated Clean Signal (S*)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(time_plot, clean_signal);
title('Original Clean Signal (S)');
xlabel('Time (s)'); ylabel('Amplitude');

sgtitle('Time Domain Comparison');

%% 14. Frequency Domain Plot
nfft = 2^nextpow2(N_compare);
f = fs_mic/2 * linspace(0,1,nfft/2+1);
mic_fft = abs(fft(mic_signal(1:N_compare), nfft))/N_compare;
error_fft = abs(fft(error_signal, nfft))/N_compare;

figure;
plot(f, 2*mic_fft(1:nfft/2+1), 'b');
hold on;
plot(f, 2*error_fft(1:nfft/2+1), 'r');
title('Frequency Spectrum Comparison');
legend('Mic Signal (S+N)', 'Estimated Clean Signal (S*)');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
grid on;

%% 15. Spectrograms
figure;
spectrogram(mic_signal(1:N_compare), 256, 200, 512, fs_mic, 'yaxis');
title('Mic Signal Spectrogram');

figure;
spectrogram(error_signal, 256, 200, 512, fs_mic, 'yaxis');
title('Estimated Clean Signal (S*) Spectrogram');

%% 16. Write Estimated Clean Signal (S*) to WAV File
output_folder = "D:\STMicroelectronics\Matlab_Main\Code\STM_differ_analysis_mat\Output";
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
filename = fullfile(output_folder, "estimated_signal.wav");

% Normalize to avoid clipping
error_signal_norm = error_signal / max(abs(error_signal));

audiowrite(filename, error_signal_norm, fs_mic);
disp('Estimated clean signal saved.');

%% 17. Numerical comparison between estimated clean signal (S*) and original clean signal (S)

mse_val = mean((clean_signal - error_signal).^2);
rmse_val = sqrt(mse_val);
signal_power = mean(clean_signal.^2);
error_power = mean((clean_signal - error_signal).^2);
ser_val = 10 * log10(signal_power / error_power);

rms_clean = rms(clean_signal);
rms_estimated = rms(error_signal);
percentage_diff_rms = ((rms_clean - rms_estimated) / rms_clean) * 100;

fprintf('\n📊 Comparison between Estimated Clean Signal (S*) and Original Clean Signal (S):\n');
fprintf('Mean Squared Error (MSE): %.6f\n', mse_val);
fprintf('Root Mean Squared Error (RMSE): %.6f\n', rmse_val);
fprintf('Signal-to-Error Ratio (SER): %.2f dB\n', ser_val);
fprintf('Percentage Difference in RMS: %.2f%%\n', percentage_diff_rms);
