# Makefile for SystemVerilog Lab1

RTL = ./top.v
SVTB = ./top_tb.sv
SEED = $random
SRCS = ./driver.sv ./environment.sv ./generator.sv ./interface.sv ./monitor.sv ./scoreboard.sv ./test.sv ./top_tb_direct.sv ./transaction.sv ./evaluation.sv

default: test 

test: compile run

run:
	./simv -l simv.log +ntb_random_seed_automatic

compile:
	vcs -l vcs.log -sverilog -debug_access+all -full64 $(SVTB) $(RTL) $(SRCS)

dve:
	dve -vpd vcdplus.vpd &

debug:
	./simv -l simv.log -gui -tbug +ntb_random_seed=$(SEED)

solution: clean
	cp ../../solutions/lab1/*.sv .

clean:
	rm -rf simv* csrc* *.tmp *.vpd *.key *.log *hdrs.h

nuke: clean
	rm -rf *.v* *.sv include .*.lock .*.old DVE* *.tcl *.h
	cp .orig/* .

help:
	@echo ==========================================================================
	@echo " 								       "
	@echo " USAGE: make target <SEED=xxx>                                         "
	@echo " 								       "
	@echo " ------------------------- Test TARGETS ------------------------------ "
	@echo " test       => Compile TB and DUT files, runs the simulation.          "
	@echo " compile    => Compile the TB and DUT.                                 "
	@echo " run        => Run the simulation.                                     "
	@echo " dve        => Run dve in post-processing mode                         "
	@echo " debug      => Runs simulation interactively with dve                  "
	@echo " clean      => Remove all intermediate simv and log files.             "
	@echo "                                                                       "
	@echo " -------------------- ADMINISTRATIVE TARGETS ------------------------- "
	@echo " help       => Displays this message.                                  "
	@echo " solution   => Copies all files from solutions directory               "
	@echo " nuke       => Erase all changes. Put all files back to original state "
	@echo "								       "
	@echo ==========================================================================
