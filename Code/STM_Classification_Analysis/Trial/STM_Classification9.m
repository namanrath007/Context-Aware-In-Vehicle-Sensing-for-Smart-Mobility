%% Initialization
clear; clc; close all;

%% Parameters
fs = 16000;             % Sampling frequency
duration = 5;           % seconds
t = (0:1/fs:duration-1/fs)';  % time vector
N = length(t);

%% Create Clean Sound (500 Hz sine wave)
sound_signal = 0.6 * sin(2*pi*500*t);

%% Create Noise (random noise or 200 Hz sine)
noise_signal = 0.4 * sin(2*pi*200*t) + 0.2*randn(N,1);

%% Combine to Create Noisy Sound
noisy_signal = sound_signal + noise_signal;

%% Save Audio Files
audiowrite('sound.wav', sound_signal, fs);
audiowrite('sound_plus_noise.wav', noisy_signal, fs);

%% Save Noise as CSV (simulating IMU-like reference)
csvwrite('noise.csv', noise_signal);

%% LMS Adaptive Filtering
% Load the noise reference from CSV
reference_noise = csvread('noise.csv');

% LMS Parameters
mu = 0.0005;              % Step size (adaptation constant)
filterOrder = 32;         % Filter length

% Initialize variables
nSamples = length(noisy_signal);
y = zeros(nSamples,1);         % Filter output
e = zeros(nSamples,1);         % Error signal (desired - output)
w = zeros(filterOrder,1);      % Filter coefficients

% Adaptive Filtering Process
for n = filterOrder:nSamples
    x = reference_noise(n:-1:n-filterOrder+1);   % Input vector
    y(n) = w' * x;                               % Filter output
    e(n) = noisy_signal(n) - y(n);               % Error signal (desired - output)
    w = w + mu * x * e(n);                       % Coefficient update
end

%% Save Filtered Output (Error Signal)
audiowrite('filtered_output.wav', e, fs);

%% Compare Error Signal to Clean Sound
[clean, ~] = audioread('sound.wav');

% Truncate to match length if needed
minLen = min(length(clean), length(e));
mse_val = mean((clean(1:minLen) - e(1:minLen)).^2);

fprintf('Mean Square Error between filtered output and clean sound: %f\n', mse_val);

%% Plot Results
figure;
subplot(3,1,1);
plot(t,noisy_signal);
title('Sound + Noise Signal'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(t,e);
title('Filtered Output (Error Signal)'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(t,clean);
title('Original Clean Sound'); xlabel('Time (s)'); ylabel('Amplitude');
