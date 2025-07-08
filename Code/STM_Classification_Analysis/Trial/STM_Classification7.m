%% Initialization
clear; clc; close all;

%% Parameters
fs = 16000;                      % Sampling frequency

%% Load Data
[noisy_signal, fs1] = audioread('C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_without_extAudio\Microphone_Data\noise1.wav');
[clean_signal, fs2] = audioread('C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_without_extAudio\Microphone_Data\noise2.wav');
%reference_noise = readmatrix('C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\MemsSensorData\DataCollection\Engine_Noise_with_Ext_Audio\1min.csv');
reference_noise = readmatrix('C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\MemsSensorData\1min_new.csv');

% Ensure equal lengths
minLen = min([length(noisy_signal), length(clean_signal), size(reference_noise,1)]);
noisy_signal     = noisy_signal(1:minLen);
clean_signal     = clean_signal(1:minLen);
reference_noise  = reference_noise(1:minLen,:);

% Number of channels
numChannels = size(reference_noise,4);

%% LMS Parameters
filterOrder = 32;                  % M
mu = 0.0001;                       % Step size (tune for stability and convergence)
% Initialize
w = zeros(filterOrder, numChannels);   % Filter coefficients [M x numChannels]
y = zeros(minLen,1);                   % Filter output
e = zeros(minLen,1);                   % Error signal

%% Adaptive LMS Filtering Process (Formal Implementation)
for n = filterOrder:minLen
    
    % Create tap input vector for each channel (x(n), x(n-1),...,x(n-M+1))
    X = reference_noise(n:-1:n-filterOrder+1, :);   % [M x numChannels]
    
    % Compute y(n) = sum_over_channels(sum_over_taps(wi * x(n-i)))
    y(n) = sum(sum(w .* X));                        % Element-wise multiply and sum
    
    % Compute error signal e(n) = d(n) - y(n)
    e(n) = noisy_signal(n) - y(n);
    
    % Update coefficients: wi(n+1) = wi(n) + 2*mu*e(n)*x(n-i)
    w = w + 2 * mu * X * e(n);                     % LMS coefficient update
end

%% Save Filtered Output (Error Signal)
%audiowrite('C:\YourPath\FilteredOutput.wav', e, fs);

%% Compare Error Signal to Clean Sound
mse_val = mean((clean_signal - e).^2);
fprintf('Mean Square Error between filtered output and clean sound: %f\n', mse_val);

%% Plot Results
timeVec = (0:1/fs:(minLen-1)/fs)';

figure;
subplot(3,1,1);
plot(timeVec, noisy_signal);
title('Sound + Noise Signal'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(timeVec, e);
title('Filtered Output (Error Signal)'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(timeVec, clean_signal);
title('Original Clean Sound'); xlabel('Time (s)'); ylabel('Amplitude');

