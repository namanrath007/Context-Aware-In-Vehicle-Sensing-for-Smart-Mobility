% Adaptive LMS Noise Cancellation in MATLAB

% File paths
primary_file = "D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\1min.wav";
reference_file = "D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\Microphone_Data\1min_no.wav";
clean_sound_file = "D:\STMicroelectronics\Data_Collection\Only_extAudio\Microphone_Data\2min\2min1.wav";

output_folder = "D:\STMicroelectronics\Matlab_Main\Code\STM_differ_analysis_mat\Output";
output_filename = fullfile(output_folder, "cleaned_output.wav");

% Create output folder if it doesn't exist
if ~isfolder(output_folder)
    mkdir(output_folder);
    fprintf('Created output folder: %s\n', output_folder);
end

% Read primary signal (sound + engine noise)
[primary_signal, fs_primary] = audioread(primary_file);
if size(primary_signal, 2) > 1
    primary_signal = mean(primary_signal, 2); % convert to mono
end

% Read reference noise signal (engine noise only)
[reference_noise, fs_noise] = audioread(reference_file);
if size(reference_noise, 2) > 1
    reference_noise = mean(reference_noise, 2);
end

% Resample noise if sampling rates differ
if fs_primary ~= fs_noise
    reference_noise = resample(reference_noise, fs_primary, fs_noise);
    fs_noise = fs_primary;
end

% Pad or truncate reference noise to match primary signal length
if length(reference_noise) < length(primary_signal)
    reference_noise = repmat(reference_noise, ceil(length(primary_signal) / length(reference_noise)), 1);
end
reference_noise = reference_noise(1:length(primary_signal));

% LMS Filter Parameters
mu = 0.001;               % Learning rate
filter_order = 128;       % Number of filter taps
N = length(primary_signal);
weights = zeros(filter_order, 1);
ref_buffer = zeros(filter_order, 1);

% Output signals initialization
y = zeros(N, 1);          % Estimated noise
e = zeros(N, 1);          % Error signal (cleaned output)

% Adaptive LMS Filtering
for n = 1:N
    % Shift buffer
    ref_buffer(2:end) = ref_buffer(1:end-1);
    ref_buffer(1) = reference_noise(n);
    
    % Filter output
    y(n) = weights' * ref_buffer;
    
    % Error signal (desired output)
    e(n) = primary_signal(n) - y(n);
    
    % Update filter weights
    weights = weights + 2 * mu * e(n) * ref_buffer;
end

% Normalize cleaned output
e = e / max(abs(e));

% Save cleaned output with error handling
try
    audiowrite(output_filename, e, fs_primary);
    fprintf('✅ Cleaning complete. File saved as:\n%s\n', output_filename);
catch ME
    warning('Failed to save cleaned output: %s\n', ME.message);
    return
end

% Read clean sound for comparison
[clean_sound, fs_clean] = audioread(clean_sound_file);
if size(clean_sound, 2) > 1
    clean_sound = mean(clean_sound, 2);
end

% Read cleaned output
[cleaned_output, fs_cleaned] = audioread(output_filename);
if size(cleaned_output, 2) > 1
    cleaned_output = mean(cleaned_output, 2);
end

% Resample cleaned output if needed
if fs_clean ~= fs_cleaned
    cleaned_output = resample(cleaned_output, fs_clean, fs_cleaned);
end

% Truncate to match lengths
min_len = min(length(clean_sound), length(cleaned_output));
clean_sound = clean_sound(1:min_len);
cleaned_output = cleaned_output(1:min_len);

% Numerical comparisons
mse_val = mean((clean_sound - cleaned_output).^2);
rmse_val = sqrt(mse_val);
signal_power = mean(clean_sound.^2);
error_power = mean((clean_sound - cleaned_output).^2);
ser_val = 10 * log10(signal_power / error_power);
rms_clean = rms(clean_sound);
rms_cleaned = rms(cleaned_output);
percentage_rms_diff = ((rms_cleaned - rms_clean) / rms_clean) * 100;

% Display results
fprintf('Mean Squared Error (MSE): %.6f\n', mse_val);
fprintf('Root Mean Squared Error (RMSE): %.6f\n', rmse_val);
fprintf('Signal-to-Error Ratio (SER): %.2f dB\n', ser_val);
fprintf('RMS of Clean Sound: %.4f\n', rms_clean);
fprintf('RMS of Cleaned Output: %.4f\n', rms_cleaned);
fprintf('Percentage RMS Difference: %.2f%%\n', percentage_rms_diff);

% Plot signals
figure;
subplot(3,1,1);
plot(primary_signal);
title('Primary Signal (Sound + Engine Noise)');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(3,1,2);
plot(reference_noise);
title('Reference Noise (Engine Noise Only)');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(3,1,3);
plot(e);
title('Cleaned Output (After LMS Filtering)');
xlabel('Sample Index');
ylabel('Amplitude');

figure;
subplot(2,1,1);
plot(clean_sound);
title('Original Clean Sound');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(2,1,2);
plot(cleaned_output);
title('Cleaned Output (After LMS Filtering)');
xlabel('Sample Index');
ylabel('Amplitude');

% Plot spectrograms
figure;
subplot(2,1,1);
spectrogram(clean_sound, 512, [], [], fs_clean, 'yaxis');
title('Spectrogram of Clean Sound');

subplot(2,1,2);
spectrogram(cleaned_output, 512, [], [], fs_clean, 'yaxis');
title('Spectrogram of Cleaned Output');

disp('✅ Comparison complete.');
