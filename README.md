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
.
├── rtl/ # Verilog RTL for all modules (ASIC & FPGA)
├── tb/ # Verilog testbenches (self-checking, KATs)
├── sw/ # C reference models (standard & constant-time)
└── synthesis/ # Example FPGA/ASIC synthesis scripts

yaml
Copy
Edit

---

## 🎯 Targets and Variants  
The accelerator includes **8 top-level implementations**:  

| Target | Security Model      | Parameter Set | Top-Level Module |
|--------|---------------------|---------------|------------------|
| FPGA   | Standard (Variable-Time) | CSIDH-512  | `csidh_fpga_std_512_top.v` |
| FPGA   | Standard (Variable-Time) | CSIDH-1024 | `csidh_fpga_std_1024_top.v` |
| FPGA   | Constant-Time       | CSIDH-512     | `csidh_fpga_ct_512_top.v` |
| FPGA   | Constant-Time       | CSIDH-1024    | `csidh_fpga_ct_1024_top.v` |
| ASIC   | Standard (Variable-Time) | CSIDH-512  | `csidh_asic_std_512_top.v` |
| ASIC   | Standard (Variable-Time) | CSIDH-1024 | `csidh_asic_std_1024_top.v` |
| ASIC   | Constant-Time       | CSIDH-512     | `csidh_asic_ct_512_top.v` |
| ASIC   | Constant-Time       | CSIDH-1024    | `csidh_asic_ct_1024_top.v` |  

🔧 **Shared Arithmetic Core:** All variants rely on a highly optimized two-stage carry-select adder and parallel 512×512 (and 1024×1024) multipliers with partial-product folding.  

---

## 🧪 Verification Strategy  
- **Golden Model:** Constant-time C implementation (`sw/csidh_ct/`) adapted from the official [CSIDH reference](https://csidh.isogeny.org/).  
- **Test Vectors:** Known-Answer Tests (KATs) and random vectors generated from the C model.  
- **Self-Checking Testbenches:** Hardware outputs are automatically compared against the golden model for all 8 configurations.  

---

## 📝 Publication  
The full architecture, algorithms, and benchmarks are presented in our research paper:  

**“Hardware Acceleration for CSIDH on FPGA/ASIC”**  
Preprint: [arXiv:2508.11082](https://arxiv.org/abs/2508.11082)  

If you use this repository in your research, please consider citing our work.  
