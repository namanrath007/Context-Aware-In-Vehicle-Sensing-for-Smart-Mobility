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
## 🔹 LMS Adaptive Filtering Working

### 📌 Idea  
Use these **IMU signals** (after resampling them to the audio sampling rate) as reference inputs to the **LMS adaptive filter**. The filter estimates the noise component due to the engine and subtracts it from the audio.

<p align="center">
  <img src="https://github.com/user-attachments/assets/6a145725-abdc-4277-b02e-abb1c3880eb1" alt="LMS Filter Block Diagram">
</p>

---

### 📥 Data Loading  

After loading the data:
- Column parameters such as **Time**, **Accelerometer (X, Y, Z)**, and **Gyroscope (X, Y, Z)** values are stored.
- These signals are prepared for the resampling process.

<p align="center">
  <img src="https://github.com/user-attachments/assets/5714bf8c-c0dc-414c-953a-510d931a3009" alt="IMU Data Columns">
</p>

---

### 🔄 Resampling IMU Data  

- The IMU data is typically collected at a lower sampling rate (e.g., **1000 Hz**), whereas the audio might be at **16000 Hz**.
- To synchronize both, **IMU data is resampled** to match the audio sampling rate.
- This ensures both data streams are time-aligned and suitable for adaptive filtering.

<p align="center">
  <img src="https://github.com/user-attachments/assets/9c11c1c3-c781-4646-940a-30e8093566c0" alt="Resampling Process">
</p>

---

### 📝 LMS Filtering Process  

- The **resampled IMU data** is used as the **reference input `x(n)`**.
- It updates the **filter weights `W`** based on the **error signal `e(n)`**.
- The adaptive weights adjust the filter output `y(n)` (estimated noise).
- The difference between the **primary signal `d(n)`** and the noise estimate forms the **error signal `e(n)`**, which improves iteratively.

<p align="center">
  <img src="https://github.com/user-attachments/assets/94b7e6da-1b53-4179-9989-6f9949e83f5a" alt="LMS Filtering Process">
</p>

---

### 📊 Multi-Channel IMU Inputs  

- Since multiple IMU columns (Accelerometer X, Y, Z and Gyroscope X, Y, Z) are available:
  - These can be treated as **multichannel inputs**.
  - Each signal is resampled and passed into the adaptive filter setup.
  - Combining multiple IMU axes may improve noise estimation accuracy.

---

## 📑 Summary Workflow  

<p align="center">
  <img src="https://github.com/user-attachments/assets/215c1daa-6c77-42b1-8bd7-bb42a9eae010" alt="ANC System Workflow">
</p>


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

