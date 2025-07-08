%% Step 1: Read Sound+Noise (S+N)
[sound_noise, fs] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\2min\2min.wav");

%% Step 2: Read Original Sound (S)
[original_sound, fs_orig] = audioread("D:\STMicroelectronics\Data_Collection\Only_extAudio\Microphone_Data\2min\2min1.wav");

if fs ~= fs_orig
    error('Sampling rates of sound+noise and original sound do not match!');
end

%% Step 3: Read Noise Data (N*)
noise_data = readmatrix("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\IMU_only\2min\2min.csv");

% If N* is one channel and (S+N) is stereo, duplicate channel
if size(noise_data,2) ~= size(sound_noise,2)
    if size(noise_data,2) == 1 && size(sound_noise,2) == 2
        noise_data = [noise_data, noise_data];
    elseif size(sound_noise,2) == 1
        noise_data = mean(noise_data,2);
    else
        error('Noise and sound+noise channels mismatch!');
    end
end

%% Step 4: Match lengths of all signals
min_len = min([length(sound_noise), length(noise_data), length(original_sound)]);
sound_noise = sound_noise(1:min_len,:);
noise_data  = noise_data(1:min_len,:);
original_sound = original_sound(1:min_len,:);

% Create common time vector for plotting
time_common = (0:min_len-1)' / fs;

%% Step 5: Adaptive Filtering (LMS)

% Normalize noise data
noise_data = noise_data / max(abs(noise_data(:)));

% LMS Parameters
filter_order = 64;
mu = 0.00001;

% Preallocate
error_signal = zeros(size(sound_noise));
y = zeros(size(sound_noise));

for ch = 1:size(sound_noise,2)
    w = zeros(filter_order,1);
    x = noise_data(:,ch);
    d = sound_noise(:,ch);
    x_buffer = zeros(filter_order,1);

    for n = filter_order:min_len
        x_buffer = x(n:-1:n-filter_order+1);
        y(n,ch) = w' * x_buffer;
        error_signal(n,ch) = d(n) - y(n,ch);
        w = w + 2 * mu * error_signal(n,ch) * x_buffer;
    end
end

%% Step 6: Calculate Difference Metrics

diff_signal = error_signal - original_sound;

% Check for NaNs or Infs before calling snr
if any(~isfinite(original_sound), 'all')
    error('original_sound contains NaN or Inf');
end

if any(~isfinite(diff_signal), 'all')
    warning('diff_signal contains NaN or Inf. Replacing such values with zero.');
    diff_signal(~isfinite(diff_signal)) = 0;
end

% Compute MSE per channel
mse = mean(diff_signal.^2);

% Compute SNR manually to avoid errors
signal_power = mean(original_sound.^2);
noise_power = mean(diff_signal.^2);
snr_val = 10 * log10(signal_power ./ noise_power);

%% Step 7: Visualization

figure;
subplot(4,1,1);
plot(time_common, original_sound);
title('Original Sound (S)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,2);
plot(time_common, sound_noise);
title('Sound + Noise (S+N)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,3);
plot(time_common, error_signal);
title('Error Signal after Adaptive Filtering (S*)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,4);
plot(time_common, diff_signal);
title('Difference (S* - S)');
xlabel('Time (s)');
ylabel('Amplitude');

%% Step 8: Display Metrics
disp(['Mean Squared Error (per channel): ', num2str(mse)]);
disp(['Signal-to-Noise Ratio (dB) (manual calculation): ', num2str(snr_val)]);

%% Optional: Play Signals
% sound(original_sound, fs);
% pause(length(original_sound)/fs + 1);
% sound(error_signal, fs);
