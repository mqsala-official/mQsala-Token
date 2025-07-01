# MQSALA Token Smart Contract

## Overview
The **MQSALA Token** is a utility-only **BEP-20** token that powers the mQsala ecosystem.  
This repository contains the **audited** and **deployed** smart-contract code for the token.

---

## Key Features
- **Hard-Capped Supply** – 1,000,000,000 MQSLA tokens (18 decimals).  
- **Dynamic Auto-Burn** – Adjustable auto-burn up to **20 %** (2,000 bps).  
- **Controlled Transfers** – Whitelist & per-address restrictions; transfers locked until `licenseObtained == true`.  
- **Upgradeable (UUPS)** – Uses the **UUPS** proxy pattern, enabling future upgrades without changing the token address.  
- **Enhanced Security** – `Pausable`, `ERC20Votes` snapshots, `ERC20Permit`, and a storage gap for safe upgrades.  
- **Role-Based Access Control** – `ADMIN_ROLE`, `MINTER_ROLE`, `BURNER_ROLE` managed via OpenZeppelin `AccessControl`.

---

## Audit Status : **100 % PASS**
| Item | Details |
|------|---------|
| **Auditor** | Assure DeFi |
| **Edition** | Advanced + |
| **Initial Report** | 29 Jun 2025 |
| **Remediation Confirmed** | 01 Jul 2025 |
| **Result** | **100 % compliance – all findings fully remediated** |

---

## Contract Details
| Description | Address | Explorer |
|-------------|---------|----------|
| **Proxy (Main Token)** | `0x8c76e68352E0cd18b7F21B14839Ab09F1BA498B4` | [BscScan](https://bscscan.com/address/0x8c76e68352E0cd18b7F21B14839Ab09F1BA498B4) |
| **Implementation (Logic)** | `0x091b8ada4885f7a5514c7d4b1b59fec4eb61fc6d` | [BscScan](https://bscscan.com/address/0x091b8ada4885f7a5514c7d4b1b59fec4eb61fc6d) |

---

## Upgradeability & Admin Control
- **Pattern** : UUPS (Universal Upgradeable Proxies Standard).  
- **Admin** : Critical `ADMIN_ROLE` functions (including upgrades) are controlled by a **Gnosis Safe multisig** – ensuring no single actor can execute sensitive operations.

---

## Deployment
Deployed via **Remix IDE** with **OpenZeppelin Upgrades Plugin**, following best practices for upgradeable contracts.

---

## Interacting with the Contract
1. **Always use the Proxy address**  
   `0x8c76e68352E0cd18b7F21B14839Ab09F1BA498B4`
2. Connect a Web3 wallet (e.g., MetaMask) to BNB Smart Chain.
3. On BscScan, use **“Read Contract”** / **“Write Contract”** tabs to interact.

---

## Security Disclaimer
While this contract has undergone a professional audit and follows industry best practices, **no smart contract can be guaranteed free of vulnerabilities**.  
Perform your own due diligence before interacting.

---

## License
This project is released under the **MIT License**.  
See [`LICENSE`](./LICENSE) for details.
