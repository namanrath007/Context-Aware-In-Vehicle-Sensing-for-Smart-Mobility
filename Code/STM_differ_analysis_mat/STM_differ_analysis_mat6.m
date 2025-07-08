% Read the audio files
[sound_noise, fs] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_with_extAudio\Microphone_Data\2min\2min.wav");
[n_noise, ~] = audioread("D:\STMicroelectronics\Data_Collection\CarSound_without_extAudio\Microphone_Data\2min\2min1.wav");
[clean_sound, ~] = audioread("D:\STMicroelectronics\Data_Collection\Only_extAudio\Microphone_Data\2min\2min1.wav");

% Ensure all signals are the same length
min_len = min([length(sound_noise), length(n_noise), length(clean_sound)]);
sound_noise = sound_noise(1:min_len);
n_noise = n_noise(1:min_len);
clean_sound = clean_sound(1:min_len);

% Parameters for STFT
windowSize = 1024;
overlap = windowSize/2;
nFFT = windowSize;

% Perform STFT
[S_noise, f, t] = stft(n_noise, fs, 'Window', hamming(windowSize, 'periodic'), ...
    'OverlapLength', overlap, 'FFTLength', nFFT);
[S_signal, ~, ~] = stft(sound_noise, fs, 'Window', hamming(windowSize, 'periodic'), ...
    'OverlapLength', overlap, 'FFTLength', nFFT);

% Estimate the noise magnitude spectrum (average over noise frames)
noiseMag = mean(abs(S_noise), 2);

% Spectral subtraction
S_clean_mag = abs(S_signal) - repmat(noiseMag, 1, size(S_signal, 2));
% Ensure no negative magnitudes
S_clean_mag = max(S_clean_mag, 0);

% Preserve the phase of the original signal
S_clean = S_clean_mag .* exp(1j * angle(S_signal));
% Inverse STFT to reconstruct time domain signal
clean_audio = istft(S_clean, fs, 'Window', hamming(windowSize, 'periodic'), ...
    'OverlapLength', overlap, 'FFTLength', nFFT);

% Make sure the output is real
clean_audio = real(clean_audio);

% Normalize the output
clean_audio = clean_audio / max(abs(clean_audio));

% Save the processed audio
audiowrite("", clean_audio, fs);

