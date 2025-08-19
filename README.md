# CSIDH
📖 Overview
🔐 About CSIDH

CSIDH (Commutative Supersingular Isogeny Diffie–Hellman) is a post-quantum key exchange protocol proposed as a candidate for securing communications against adversaries equipped with quantum computers. Unlike classical public-key schemes (RSA, ECC), CSIDH is based on isogenies between supersingular elliptic curves, providing resistance to both classical and quantum attacks.

Key advantages of CSIDH include:

Small public keys compared to lattice-based schemes.

Commutative group action, enabling efficient key exchange.

Potential long-term post-quantum security due to hard mathematical assumptions.

However, CSIDH is computationally expensive in software, requiring large-integer arithmetic (512-bit modular operations) and repeated isogeny evaluations. This makes hardware acceleration essential for practical deployment.
