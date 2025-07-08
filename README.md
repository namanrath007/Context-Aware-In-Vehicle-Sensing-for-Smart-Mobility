# Context-Aware-In-Vehicle-Sensing-for-Smart-Mobility
This repository contains the implementation and theoretical background of an Adaptive Noise Cancellation (ANC) system designed to suppress engine noise in a car environment using a unique reference signal derived from IMU sensors (accelerometer and gyroscope).

📖 # Overview
Adaptive Noise Cancellation (ANC) is a signal processing technique used to dynamically suppress unwanted noise from a signal without prior knowledge of the noise or signal characteristics. This is achieved by adaptively filtering a reference signal correlated with the noise and subtracting it from the primary signal.

In this project, we apply ANC to audio signals captured inside a car cabin, where the primary input is a noisy microphone signal (speech + engine noise + ambient sounds) and the reference input is derived from IMU data capturing engine-induced vibrations. The system adaptively filters the reference signal to estimate the noise component present in the microphone signal and subtracts it to produce a cleaner output.

🎯# Project Objectives
Develop an Adaptive Noise Cancellation system using IMU data as a correlated noise reference.

Implement the Least Mean Squares (LMS) adaptive filtering algorithm for real-time noise suppression.

Correlate engine vibration data (from accelerometer and gyroscope) with audio data to estimate and subtract engine noise from microphone recordings.

Evaluate performance through audio output and error analysis.

📑 # Theoretical Background
🔹 Adaptive Noise Cancellation (ANC) Principle
ANC systems typically involve:

Primary Input: A signal containing both the desired signal and noise (e.g., microphone signal inside a car).

Reference Input: A signal correlated with the noise but uncorrelated with the desired signal (e.g., IMU data measuring engine vibrations).

An adaptive filter processes the reference signal to generate an estimate of the noise. This estimate is subtracted from the primary input to produce an error signal, which is the desired signal with reduced noise. The system continuously updates the filter coefficients to minimize the mean squared error.

🔹# Mathematical Representation
Let:

𝑑
(
𝑛
)
d(n): primary signal (desired signal + noise)

𝑥
(
𝑛
)
x(n): reference input (IMU data)

𝑦
(
𝑛
)
y(n): adaptive filter output (noise estimate)

𝑒
(
𝑛
)
e(n): error signal (clean output)

Then:

𝑒
(
𝑛
)
=
𝑑
(
𝑛
)
−
𝑦
(
𝑛
)
e(n)=d(n)−y(n)
The adaptive filter coefficients are updated iteratively using the LMS algorithm:

𝑤
(
𝑛
+
1
)
=
𝑤
(
𝑛
)
+
𝜇
⋅
𝑒
(
𝑛
)
⋅
𝑥
(
𝑛
)
w(n+1)=w(n)+μ⋅e(n)⋅x(n)
Where:

𝜇
μ is the step-size parameter.

🚘 Application Context
In this project:

Primary Input: Microphone data collected inside a moving car, containing ambient noise, external voices, and engine noise.

Reference Input: IMU data (accelerometer in mg and gyroscope in mdps) capturing vibrations produced by the engine.

By correlating IMU data with microphone recordings, the adaptive filter effectively estimates the engine noise component and subtracts it from the microphone signal to enhance audio quality within the car cabin.

📂 # Project Structure
Copy
Edit
.
├── Data_Collection/
│   ├── Microphone_Data/
│   └── IMU_Data/
├── MATLAB_Scripts/
│   └── LMS_ANC_with_IMU.m
├── Results/
│   └── Output_Audio/
├── README.md
🛠️ Technologies Used
MATLAB for implementing LMS adaptive filtering and audio signal processing.

LSM6DSV16X/LSM6DSV16BX IMU sensors for acquiring accelerometer and gyroscope data.

Audio files (.wav) for primary microphone input.

CSV files for IMU data logs.

📊 # Results
The ANC system successfully reduced engine-induced noise components in the audio recordings, improving the clarity of desired signals (such as speech). Error signals and residual noise levels were analyzed to validate the system's performance.

📜 # References
Widrow, B., & Stearns, S. D. (1985). Adaptive Signal Processing. Prentice-Hall.

Haykin, S. (2002). Adaptive Filter Theory (4th ed.). Pearson.

📬 # Contact
Naman Rath
Final Year IT Undergraduate, VIT Vellore
📧 [Your Email]
🔗 [LinkedIn Profile (optional)]
