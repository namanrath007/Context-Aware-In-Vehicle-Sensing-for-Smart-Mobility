%% Real time data classification
%% Initialization
clear; clc; close all;

%% Load Audio Files
sr = 16000;
[y1, ~] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\CarSound_with_extAudio\Microphone_Data\1min.wav");
[y2, ~] = audioread("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\Data_Collection\Only_extAudio\Microphone_Data\2min\2min1.wav");

if size(y1, 2) > 1, y1 = mean(y1, 2); end
if size(y2, 2) > 1, y2 = mean(y2, 2); end

%% Load IMU Data
imu_data = readtable("C:\Users\naman\OneDrive\Desktop\ST_Work\ST_MainWork\MemsSensorData\DataCollection\Engine_Noise_with_Ext_Audio\1min.csv");
time_imu = imu_data{:,1} / 1e6; % convert to seconds
acc_x = imu_data{:,2};

% Remove duplicate timestamps
[time_imu, ia, ~] = unique(time_imu);
acc_x = acc_x(ia);

%% Initialize LMS Filter
order = 10;
mu = 0.001;
lmsFilter = dsp.LMSFilter('Length', order, 'StepSize', mu);

%% Real-Time Simulation Setup
chunk_size = sr; % 1-second chunk
num_chunks = floor(min(length(y1), length(y2)) / chunk_size);

% Time vector for audio
t_audio = (0:length(y2)-1)/sr;

%% Initialize real-time LMS error and correlation plots
figure;

subplot(2,1,1);
h1 = animatedline('Color','r'); % LMS Error
title('Real-Time Error Signal (LMS Filter)');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
xlim([0 60]);
ylim([-1 1]);

subplot(2,1,2);
h2 = animatedline('Color','b'); % Correlation trend
title('Real-Time Correlation (Error RMS vs IMU accX)');
xlabel('Chunk Number');
ylabel('Correlation');
grid on;
%xlim([0 num_chunks]);
%ylim([-1 1]);

corr_vals = zeros(num_chunks,1);

%% Initialize real-time waveform comparison figure
figure;

subplot(3,1,1);
h_y1 = animatedline('Color','b');
title('Original Microphone Data (y1)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;
xlim([0 60]); ylim([-1 1]);

subplot(3,1,2);
h_y2 = animatedline('Color','g');
title('Clean Reference Sound (y2)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;
xlim([0 60]); ylim([-1 1]);

subplot(3,1,3);
h_err = animatedline('Color','r');
title('Filtered Error Signal (LMS Output)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;
xlim([0 60]); ylim([-1 1]);

sgtitle('Real-Time Audio Waveform Comparison: Original, Reference, and LMS Error');

%% Initialize overlay waveform plot
figure;
h_overlay_y1 = animatedline('Color','b','DisplayName','y1 (Mic+Noise)');
h_overlay_y2 = animatedline('Color','g','DisplayName','y2 (Clean Ref)');
h_overlay_err = animatedline('Color','r','DisplayName','LMS Error');
title('Overlay: Real-Time Audio Signals');
xlabel('Time (s)');
ylabel('Amplitude');
legend;
grid on;
xlim([0 60]);
ylim([-1 1]);

%% Simulate Real-Time Processing Loop
for i = 1:num_chunks
    idx_start = (i-1)*chunk_size + 1;
    idx_end = idx_start + chunk_size - 1;

    chunk_y1 = y1(idx_start:idx_end);
    chunk_y2 = y2(idx_start:idx_end);
    time_chunk = t_audio(idx_start:idx_end);

    % LMS Filtering on current chunk
    [~, err_chunk] = lmsFilter(chunk_y1, chunk_y2);

    % Interpolate IMU acc_x data to current time chunk
    imu_in_chunk = interp1(time_imu, acc_x, time_chunk, 'linear', 'extrap');

    % Correlation between Error RMS and IMU in this chunk
    rms_error = rms(err_chunk);
    corr_matrix = corr(rms_error * ones(size(imu_in_chunk)), imu_in_chunk, 'rows','complete');
    corr_val = corr_matrix(1,2);

    corr_vals(i) = corr_val;

    % Update LMS Error Signal plot
    addpoints(h1, time_chunk, err_chunk);

    % Update Correlation plot
    addpoints(h2, i, corr_val);

    % Update Real-Time Waveform comparison plots
    addpoints(h_y1, time_chunk, chunk_y1);
    addpoints(h_y2, time_chunk, chunk_y2);
    addpoints(h_err, time_chunk, err_chunk);

    % Update overlay plot
    addpoints(h_overlay_y1, time_chunk, chunk_y1);
    addpoints(h_overlay_y2, time_chunk, chunk_y2);
    addpoints(h_overlay_err, time_chunk, err_chunk);

    % Refresh all plots
    drawnow;

    % Simulate real-time pacing (adjust this for actual timing)
    pause(0.1);
end

sgtitle('Simulated Real-Time LMS Filtering, Correlation & Audio Waveform Comparison');
