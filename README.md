# Batch-16

# 📡  COMPARISON OF BER OF DIFFERENT CHANNEL CODING TECHNIQUES FOR ADVANCED 5G & 6G NETWORKS

## 📌 Project Overview

This project presents a comprehensive analysis of different **channel coding techniques** using a **MIMO-OFDM communication system**. The main objective is to evaluate and compare the performance of **Convolutional, LDPC, Turbo, and Polar codes** in terms of **Bit Error Rate (BER), Spectral Efficiency, Data Rate, and Latency**.

The system is implemented in **MATLAB** and simulates real-world wireless communication conditions such as noise and fading. The results demonstrate how advanced coding techniques improve system reliability and efficiency for **5G and future 6G networks**.

---

## 🎯 Objectives

* To implement a **MIMO-OFDM system** using MATLAB
* To analyze different **channel coding techniques**
* To compare system performance based on:

  * Bit Error Rate (BER)
  * Signal-to-Noise Ratio (SNR)
  * Spectral Efficiency
  * Data Rate
  * Latency
* To identify the most efficient coding technique for **next-generation communication systems**

---

## 🏗️ System Architecture

The system follows a standard digital communication flow:

**Input Data → Channel Encoding → Interleaving → Modulation → OFDM (IFFT + CP) → MIMO Channel → Receiver (FFT + Detection) → Demodulation → Deinterleaving → Decoding → BER Calculation**

---

## ⚙️ Technologies Used

* MATLAB
* MIMO (Multiple Input Multiple Output)
* OFDM (Orthogonal Frequency Division Multiplexing)
* Channel Coding Techniques:

  * Convolutional Codes
  * LDPC Codes
  * Turbo Codes
  * Polar Codes

---

## 📊 Key Parameters

* Bandwidth: 1 GHz
* Number of Subcarriers: 64
* MIMO Configuration: 2×2
* Modulation Techniques:

  * QPSK
  * 16-QAM
  * 64-QAM
* Channel Model:

  * AWGN
  * Rayleigh Fading

---

## 📈 Results & Observations

* BER decreases as SNR increases for all techniques
* QPSK shows better reliability compared to higher-order modulation
* Soft decoding performs better than hard decoding
* LDPC and Turbo codes significantly reduce BER
* **Polar coding provides the best performance** in terms of:

  * Lowest BER
  * Low latency
  * High efficiency

---

## 🚀 Advantages

* Reduced Bit Error Rate (BER)
* Improved reliability and accuracy
* High spectral efficiency
* Better performance at low SNR
* Suitable for high-speed communication

---

## 📡 Applications

* 5G and 6G communication systems
* Mobile networks
* Satellite communication
* IoT (Internet of Things)
* Wireless sensor networks
* High-speed data transmission

---

## ⚠️ Limitations

* Implemented in MATLAB (simulation only)
* Uses AWGN channel (limited real-world modeling)
* Higher computational complexity for advanced coding
* No real-time hardware implementation

---

## 🔮 Future Scope

* Implementation using **SDR or FPGA hardware**
* Inclusion of **real-world fading channels (Rayleigh, Rician)**
* Integration with **AI/ML-based optimization techniques**
* Extension to **6G communication technologies**

---

## 📌 Conclusion

This project demonstrates that integrating advanced channel coding techniques with MIMO-OFDM significantly improves communication performance. Among all techniques, **Polar coding shows the best results**, making it highly suitable for **advanced 5G and future 6G networks**.

---

## 📚 References

* IEEE Research Papers on Channel Coding
* MATLAB Documentation
* 5G Communication Standards

---

## 👩‍💻 Author

D.Chandana     - 22KA1A0434
M.Faizia Anjum - 23KA5A0415
B. Tech Final Year
JNTUA College of Engineering, Kalikiri
Department of Electronics & Communication Engineering

---
