# 📖 Overview  

## 🔐 About CSIDH  
CSIDH (Commutative Supersingular Isogeny Diffie–Hellman) is a post-quantum key exchange protocol designed to secure communications against adversaries equipped with quantum computers. Its security relies on the computational hardness of finding isogenies between supersingular elliptic curves.  
For more detailed information on the protocol, please refer to the original CSIDH paper:  
- [Luca De Feo, David Jao, and Jérôme Plût, *CSIDH: An Efficient Post-Quantum Commutative Group Action*, 2018](https://csidh.isogeny.org/)
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

```text
.
├── ASIC/                          # Synthesizable RTL for ASIC targets (RTL & testbenches)
│   ├── original/                  # Variable-time (reference)
│   │   ├── 512/                   # CSIDH-512: top + modules + tb
│   │   └── 1024/                  # CSIDH-1024: top + modules + tb
│   └── constant_time/             # Constant-time (hardened)
│       ├── 512/
│       └── 1024/
├── FPGA/                          # RTL for FPGA targets (wrappers, constraints, tb)
│   ├── original/
│   │   ├── 512/
│   │   └── 1024/
│   └── constant_time/
│       ├── 512/
│       └── 1024/
└── SW/                            # C reference & tools
    └── csidh_ct/                  # Constant-time adaptation (golden model)

```
---

## 🎯 Targets and Variants  
The accelerator includes **8 top-level implementations**:  

| Target | Security Model           | Parameter Set |
|--------|--------------------------|---------------|
| FPGA   | Standard (Variable-Time) | CSIDH-512     | 
| FPGA   | Standard (Variable-Time) | CSIDH-1024    | 
| FPGA   | Constant-Time            | CSIDH-512     | 
| FPGA   | Constant-Time            | CSIDH-1024    |
| ASIC   | Standard (Variable-Time) | CSIDH-512     |
| ASIC   | Standard (Variable-Time) | CSIDH-1024    |
| ASIC   | Constant-Time            | CSIDH-512     | 
| ASIC   | Constant-Time            | CSIDH-1024    |

🔧 **Shared Arithmetic Core:** All variants rely on a highly optimized two-stage carry-select adder and parallel 512×512 (and 1024×1024) multipliers with partial-product folding.  

---

## 🧪 Verification Strategy  
- **Golden Model:** Constant-time C implementation (`SW/csidh_ct/`) adapted from the official [CSIDH reference](https://csidh.isogeny.org/).  
- **Test Vectors:** Known-Answer Tests (KATs) and random vectors generated from the C model.  
- **Self-Checking Testbenches:** Hardware outputs are automatically compared against the golden model for all 8 configurations.  

---

## 📝 Publication  
The full architecture, algorithms, and benchmarks are presented in our research paper:  

**“A Constant-Time Hardware Architecture for the CSIDH Key-Exchange Protocol”**  
Preprint: [arXiv:2508.11082](https://arxiv.org/abs/2508.11082)  

If you use this repository in your research, please consider citing our work.  
