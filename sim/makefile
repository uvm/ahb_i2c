CC              = gcc
SEED            = 1
DUMPFST         = 1
VEROPTS         = -O3 --euvm --no-timing --x-assign fast --x-initial fast -Wno-fatal --threads 1 +incdir+../rtl

ifeq ($(DUMPFST),1)
	VEROPTS += --trace-fst
endif

DFLAGS = -relocation-model=pic -w -O3 --allinst --release --boundscheck=off

ifeq ($(DUMPFST),1)
    DFLAGS += --d-version=DUMPFST
endif

LDC2BINDIR = $(dir $(shell which ldc2))
VLBINDIR = $(dir $(shell which verilator))
VERBOSITY = NONE

TBSRC = ../testbench/ahb.d \
	../testbench/i2c_reg_model.d

DUTLIB = obj_dir/DVahb_dut.a

.PHONY: all clean

all: ahb

clean:
	rm -rf ahb* euvm_dir obj_dir

$(DUTLIB): ../rtl/ahb_dut.v ../rtl/i2c_master_bit_ctrl.v \
	../rtl/i2c_master_byte_ctl.v ../rtl/i2c_master_defines.v \
	../rtl/i2c_master_top.v
	verilator $(VEROPTS) $^
	make -C obj_dir -f DVahb_dut.mk DVahb_dut.a

ahb: $(DUTLIB) ../testbench/i2c_reg_model.d ../testbench/ahb.d
	ldc2 $(DFLAGS) -I./euvm_dir $(TBSRC) \
	-of$@ -L-luvm-ldc-shared -L-lesdl-ldc-shared \
	 -L-ldruntime-ldc-shared $(DUTLIB) -L-ldl -L-lstdc++

.PHONY: run_random_test
run_random_test: ahb
	./ahb +UVM_TESTNAME=ahb.random_test +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED) # +UVM_OBJECTION_TRACE

.PHONY: run_directed_reg_test
run_directed_reg_test: ahb
	./ahb +UVM_TESTNAME=ahb.directed_reg_test +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED) # +UVM_OBJECTION_TRACE

.PHONY: run_reg_tests
run_reg_tests:
	./ahb +UVM_TESTNAME=ahb.reg_test +UVM_SEQUENCE=uvm.reg.sequences.uvm_reg_bit_bash_seq.uvm_reg_bit_bash_seq +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED)
