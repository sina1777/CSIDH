# 📖 Overview  

## 🔐 About CSIDH  
CSIDH (Commutative Supersingular Isogeny Diffie–Hellman) is a post-quantum key exchange protocol designed to secure communications against adversaries equipped with quantum computers. Its security relies on the computational hardness of finding isogenies between supersingular elliptic curves.  

### Key advantages of CSIDH  
- 🔑 **Compact Keys:** Smaller public keys than many lattice-based candidates, suitable for bandwidth-constrained environments.  
- 🔄 **Commutative Group Action:** Enables simple, non-interactive Diffie–Hellman-style key exchange.  
- 🛡️ **Quantum-Resistant Security:** Based on hard mathematical problems believed to resist quantum algorithms.  

---

## ⚡ Why Hardware Acceleration Matters  
Deploying post-quantum cryptography (PQC) on **embedded and resource-constrained devices** (IoT, smart cards, automotive controllers, edge processors) presents unique challenges.  

Software-only CSIDH is often impractical due to:  
- ⚙️ **High Computational Cost:** 512-bit+ modular arithmetic overwhelms microcontrollers.  
- 🔋 **Energy Inefficiency:** Software execution consumes too much power for battery-powered devices.  
- ⏱️ **Side-Channel Risks:** Ensuring constant-time execution in software adds significant overhead.  

### Benefits of Hardware Acceleration  
- 🚀 **Latency Reduction:** Offloads heavy arithmetic for real-time PQC.  
- 🔋 **Energy Efficiency:** Hardware requires a fraction of the power compared to software.  
- 🔒 **Robust Security:** Hardware enforces constant-time execution, mitigating timing/power side-channel attacks.  

---

## 🚀 Our Implementation  
This repository provides an **open-source hardware accelerator for CSIDH**, designed for embedded security and scalable from FPGA prototyping to ASIC integration.  

- 🖧 **FPGA Target:** For research, prototyping, and reconfigurable deployments.  
- ⚙️ **ASIC Target:** Synthesizable design suitable for mass production in low-power secure chips.  
- 🧩 **Modular Architecture:** Built from reusable arithmetic blocks (adder, multiplier, isogeny operators).  
- 🛡️ **Constant-Time by Design:** Dedicated controller ensures strict resistance against timing attacks.  
- 📐 **Scalable Parameters:** Supports both CSIDH-512 and CSIDH-1024 configurations.  

---

## 📦 Repository Structure  
