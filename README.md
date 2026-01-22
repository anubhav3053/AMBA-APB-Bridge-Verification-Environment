# AMBA APB v3.0 Verification Environment

## Overview
This repository contains a SystemVerilog-based verification environment for an AMBA APB (Advanced Peripheral Bus) v3.0 Bridge. The project demonstrates a layered testbench architecture used to verify the protocol compliance of Master and Slave bridging logic.

## Directory Structure
* **rtl/**: Contains the synthesizable Design Under Test (DUT).
  * `design.sv`: The APB Slave/Bridge RTL.
* **tb/**: Contains the verification components.
  * `testbench.sv`: Top-level testbench environment.
  * `apb_master.sv`: Master Bus Functional Model (BFM).
  * `apb_slave.sv`: Slave BFM / Monitor components.

## Features Verified
* **Protocol Compliance**: Checks PSEL, PENABLE, and PREADY handshake mechanisms.
* **Data Integrity**: Verifies that `PWDATA` written by the master matches `PRDATA` read from the slave.
* **Corner Cases**:
  * Back-to-back transfers (No wait states).
  * Wait states injection (using `PREADY` randomization).
  * Error responses (`PSLVERR`).

## Tools Used
* **Language**: SystemVerilog
* **Simulator**: [Mention what you used, e.g., EDA Playground / Vivado / Questasim]

## How to Run
1. Clone the repository.
2. Compile the `rtl/design.sv` and `tb/` files together.
3. Observe the waveforms to verify the APB state machine transitions (IDLE -> SETUP -> ACCESS).
