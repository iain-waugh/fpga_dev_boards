# fpga_dev_boards

#  1 Overview

This project started off by only targeting the AX309 development board.  The intention was to use that board as a platform to write experimental code for a custom computing system.  One of the key outputs of such a system is a computer monitor, so VGA is a simple and natural choice to get meaningful output to the user.  Another useful output is a serial port.

After getting a basic video test pattern out on the AX309, I took a look at the stack of development boards I had lying around and wondered what it would take to write a core block of code that would run on all of them.

So, a bit more coding later and we have the ability to target more than 1 board and the beginnings of targeting more than 1 FPGA vendor (Xilinx and Altera/Intel).

Each target board has a top-level VHDL file named the same as the project (i.e `zedboard` or `ax309_board`).  This top-level file is an interface between the common core modules (VGA, UART, switched, CPU, etc) and each board's different IO's and resources.  The top-level code provides support for different numbers of switches or with different PLL/DLL clock generators.



##  1.1 Project File Hierarchy

`doc` – Project documents

`src` – Synthesisable VHDL source code

`sim` – Testbenches (not synthesised)

`syn` – makefiles, scripts and design constraints for the platform



##  1.2 Multi-Platform System Architecture

To build an FPGA image for any board, make sure you’ve got the appropriate build executables on your PATH (make, vivado, ise, quartus_*), open a terminal in the appropriate build directory and type “make synth” to get a synthesised netlist, or “make” to go all the way to an FPGA bitstream.

Example:

​	`cd syn/zedboard`

​	`make`

