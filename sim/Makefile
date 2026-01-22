#------------------------------------------------------------------------------
# Project      : AMBA APB Bridge Verification
# File Name    : Makefile
# Description  : Makefile for compiling and running the verification environment
#------------------------------------------------------------------------------

# Define the RTL and TB directories
RTL_DIR = ../rtl
TB_DIR  = ../tb

# List of Source Files
RTL_SRC = $(RTL_DIR)/design.sv
TB_SRC  = $(TB_DIR)/testbench.sv $(TB_DIR)/apb_master.sv $(TB_DIR)/apb_slave.sv

# default target
all: compile run

#------------------------------------------------------------------------------
# OPTION 1: MENTOR GRAPHICS QUESTASIM / MODELSIM
# (Uncomment the lines below if you use Questa/Modelsim)
#------------------------------------------------------------------------------
# compile:
# 	vlib work
# 	vlog -sv +incdir+$(TB_DIR) $(RTL_SRC) $(TB_SRC)
#
# run:
# 	vsim -c -do "run -all; quit" testbench
#
# clean:
# 	rm -rf work transcript vsim.wlf

#------------------------------------------------------------------------------
# OPTION 2: ICARUS VERILOG (Open Source)
# (Uncomment the lines below if you use Icarus)
#------------------------------------------------------------------------------
# compile:
# 	iverilog -g2012 -o amba_apb.vvp -I $(TB_DIR) $(RTL_SRC) $(TB_SRC)
#
# run:
# 	vvp amba_apb.vvp
#
# clean:
# 	rm -f amba_apb.vvp

#------------------------------------------------------------------------------
# HELP TARGET
#------------------------------------------------------------------------------
help:
	@echo "Usage:"
	@echo "  make compile  - Compile the design and testbench"
	@echo "  make run      - Run the simulation"
	@echo "  make clean    - Remove generated files"
