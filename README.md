# 📖 Overview  

## 🔐 About CSIDH  
**CSIDH (Commutative Supersingular Isogeny Diffie–Hellman)** is a post-quantum key exchange protocol proposed as a candidate for securing communications against adversaries equipped with quantum computers.  
Unlike classical public-key schemes (RSA, ECC), CSIDH is based on **isogenies between supersingular elliptic curves**, providing resistance to both classical and quantum attacks.  

**Key advantages of CSIDH include:**  
- 🔑 **Small public keys** compared to lattice-based schemes.  
- 🔄 **Commutative group action**, enabling efficient key exchange.  
- 🛡️ **Potential long-term post-quantum security** due to hard mathematical assumptions.  

---

## ⚡ Importance of CSIDH Hardware Acceleration in Embedded Systems  
As **post-quantum cryptography (PQC)** becomes a global requirement, one of the greatest challenges is its deployment on **embedded and resource-constrained devices** such as IoT nodes, smartcards, automotive controllers, and edge processors. Unlike data centers or high-performance servers, these platforms must meet **strict limitations on power, memory, and area**.  

Running CSIDH purely in **software** is often **impractical** in such systems because:  
- ⚙️ Operations involve **512-bit modular arithmetic**, which is computationally heavy for microcontrollers.  
- 🔋 Pure software implementations consume **high energy** and result in **long execution times**, unsuitable for battery-powered devices.  
- ⏱️ Constant-time execution is required to **prevent side-channel attacks**, but this further increases software overhead.  

**A dedicated hardware accelerator solves these problems by:**  
- 🚀 **Drastically reducing latency** of key exchange, making PQC feasible for real-time embedded communication.  
- 🔋 **Improving energy efficiency**, which is critical for IoT and mobile devices.  
- 🧮 **Offloading complex arithmetic** (additions, multiplications, isogeny evaluations) from the CPU to specialized datapaths.  
- 📈 **Offering scalability**: FPGA prototypes can be deployed today, while ASIC designs provide long-term, low-power integration for industrial or consumer products.  

By enabling **lightweight, constant-time, and high-performance CSIDH operations**, hardware acceleration paves the way for **practical PQC adoption in embedded systems** — ensuring that even small, low-cost devices can remain secure in the post-quantum era.  

---

## 🚀 Our Implementation  
This work directly targets the **embedded systems use case**. We present both **FPGA and ASIC implementations** of CSIDH:  

- 🖧 **FPGA design** – allows rapid prototyping and can be integrated into IoT or edge devices for immediate experimentation.  
- ⚙️ **ASIC design** – demonstrates how CSIDH can be built into future low-power chips for secure embedded products.  
- 🧩 **Modular hardware architecture** – based on building blocks (`xMUL`, `xISOG`, `xAffinize`, `xTwist`, `xDBLADD`) optimized for **constant-time operation**.  
- 🔒 **Software reference and validation** – we adapted the **original CSIDH C code** into a **constant-time form** for testbenches and performance comparisons. This ensures that our hardware implementation is both **secure and verifiable** against software.  

---
