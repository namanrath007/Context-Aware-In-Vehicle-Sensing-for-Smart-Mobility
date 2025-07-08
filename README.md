# 🚗 Context-Aware In-Vehicle Sensing for Smart Mobility

This repository contains the implementation and theoretical background of an **Adaptive Noise Cancellation (ANC)** system designed to suppress **engine noise in a car environment** using a unique reference signal derived from **IMU sensors (accelerometer and gyroscope)**.

---

## 📖 Overview

**Adaptive Noise Cancellation (ANC)** is a signal processing technique used to dynamically suppress unwanted noise from a signal without prior knowledge of the noise or signal characteristics. This is achieved by adaptively filtering a reference signal correlated with the noise and subtracting it from the primary signal.

In this project, we apply ANC to **audio signals captured inside a car cabin**, where the **primary input** is a noisy microphone signal (speech + engine noise + ambient sounds) and the **reference input** is derived from **IMU data capturing engine-induced vibrations**. The system adaptively filters the reference signal to estimate the noise component present in the microphone signal and subtracts it to produce a cleaner output.

---

## 🎯 Project Objectives

- Develop an **Adaptive Noise Cancellation system** using **IMU data as a correlated noise reference**.
- Implement the **Least Mean Squares (LMS) adaptive filtering algorithm** for real-time noise suppression.
- Correlate **engine vibration data (from accelerometer and gyroscope)** with audio data to estimate and subtract engine noise from microphone recordings.
- Evaluate system performance through audio output and error analysis.

---

## 📑 Theoretical Background

### 🔹 Adaptive Noise Cancellation (ANC) Principle

ANC systems typically involve:

- **Primary Input:** A signal containing both the desired signal and noise (e.g., microphone signal inside a car).
- **Reference Input:** A signal correlated with the noise but uncorrelated with the desired signal (e.g., IMU data measuring engine vibrations).

An adaptive filter processes the reference signal to generate an estimate of the noise. This estimate is subtracted from the primary input to produce an error signal, which is the desired signal with reduced noise. The system continuously updates the filter coefficients to minimize the mean squared error.

---
### Research Paper Study and Theoretical Insights
Dedicated time to studying research papers on adaptive noise cancellation, focusing on LMS algorithm parameter optimization. Gained several key theoretical insights:
- Step Size (μ): Crucial for balancing convergence speed and algorithm stability.
- Filter Order: Higher order tracks complex noise but increases computational load.
- Convergence Rate: Dependent on step size and input signal characteristics.
- Noise Reduction vs. Signal Distortion: A trade-off must be maintained; careful tuning is vital.
- Real-time Processing Efficiency: Algorithm optimization for speed is essential.
- Adaptive Filter Initialization: Starting values affect convergence behaviors.
- Use of Reference Signals: Highly correlated reference signals improve suppression.
- Performance Metrics: Incorporating MSE and SNR for quantitative tracking.

---
### 🔹 Mathematical Representation

Let:

- `d(n)` → Primary signal (desired signal + noise)  
- `x(n)` → Reference input (IMU data)  
- `y(n)` → Adaptive filter output (noise estimate)  
- `e(n)` → Error signal (cleaned output)  

Then:

e(n) = d(n) - y(n)


The adaptive filter coefficients are updated iteratively using the LMS algorithm:

w(n+1) = w(n) + μ * e(n) * x(n)


Where:

- `μ` is the step-size parameter controlling convergence speed and stability.

---
### 🔹 LMS Adaptive Filtering Working
Idea: Use these IMU signals (after resampling them to the audio sampling rate) as reference inputs to the LMS filter to estimate the noise component due to engine, and subtract it from the audio.
![image](https://github.com/user-attachments/assets/6a145725-abdc-4277-b02e-abb1c3880eb1)
- After loading the data, column parameters such as time, accelerometer at x, y and z axis and  Gyroscope at x, y, z axis are stored.
![image](https://github.com/user-attachments/assets/5714bf8c-c0dc-414c-953a-510d931a3009)
- We resample the IMU(accelerometer, Gyroscope) data because the audio might be at 16000 Hz but IMU might be at 1000Hz or may have time delays.
![image](https://github.com/user-attachments/assets/9c11c1c3-c781-4646-940a-30e8093566c0)
- The resampled IMU data is used as reference input in [x(n)]. It is later used in updating the weights [W]. The weights are used to make changes in actual output [Y]. This would make changes in error output signal [e(n)].
![image](https://github.com/user-attachments/assets/94b7e6da-1b53-4179-9989-6f9949e83f5a)
- As there are multiple column parameters e can use multichannel inputs into single unit. Then resampling it to take it in reference input.


#### Summary Workflow
![image](https://github.com/user-attachments/assets/215c1daa-6c77-42b1-8bd7-bb42a9eae010)

---

## 🚘 Application Context

In this project:

- **Primary Input:** Microphone data collected inside a moving car, containing ambient noise, external voices, and engine noise.
- **Reference Input:** IMU data (accelerometer in mg and gyroscope in mdps) capturing vibrations produced by the engine.

By correlating IMU data with microphone recordings, the adaptive filter effectively estimates the engine noise component and subtracts it from the microphone signal to enhance audio quality within the car cabin.

---

## 📂 Project Structure

├── Data_Collection/
│ ├── Microphone_Data/
│ └── IMU_Data/
├── MATLAB_Scripts/
│ └── LMS_ANC_with_IMU.m
├── Results/
│ └── Output_Audio/
├── README.md


---

## 🛠️ Technologies Used

- **MATLAB** for implementing LMS adaptive filtering and audio signal processing.
- **Jupyter Notebook** for implementing Audio signal processing and Visualizations.
- **SensorTile.BOX / LSM6DSV16BX IMU sensors** for acquiring accelerometer and gyroscope data.
- **Audio files (.wav)** for primary microphone input.
- **CSV files** for IMU data logs.

---

## 📊 Results

The ANC system successfully reduced engine-induced noise components in the audio recordings, improving the clarity of desired signals (such as speech). Error signals and residual noise levels were analyzed to validate the system's performance.

---

## 📜 References

- Widrow, B., & Stearns, S. D. (1985). *Adaptive Signal Processing*. Prentice-Hall.
- Haykin, S. (2002). *Adaptive Filter Theory* (4th ed.). Pearson.

---

## 📬 Contact

**Naman Rath**  
VIT Vellore  
📧 [namanrath2003@gmail.com]  

