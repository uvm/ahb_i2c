CC              = gcc
CFLAGS		= -Wall -O3 -fPIC
SEED            = 1
DUMPVCD         = 1
VEROPTS         = -O3 --euvm --no-timing --x-assign fast --x-initial fast -Wno-fatal --threads 1 +incdir+../rtl

ifeq ($(DUMPVCD),1)
	VEROPTS += --trace
endif

DFLAGS = -relocation-model=pic -w -O0 --allinst

ifeq ($(DUMPVCD),1)
    DFLAGS += --d-version=DUMPVCD
endif

LDC2BINDIR = $(dir $(shell which ldc2))
VLBINDIR = $(dir $(shell which verilator))
VERBOSITY = NONE

TBSRC = ../testbench/ahb.d \
	../testbench/i2c_reg_model.d \
	euvm_dir/Vahb_dut_euvm.d \
        $(LDC2BINDIR)/../import/esdl/intf/verilator/trace.d

DUTOBJ = euvm_dir/verilated_d.o \
	 euvm_dir/Vahb_dut_euvm_funcs.o  \
	 obj_dir/Vahb_dut__ALL.a \
	 obj_dir/verilated.o \
	 obj_dir/verilated_threads.o \
	 obj_dir/verilated_vcd_c.o \
	 euvm_dir/verilated_vcd_d.o

VLATOR_SRC = euvm_dir/Vahb_dut_euvm.d euvm_dir/Vahb_dut_euvm_funcs.cpp obj_dir/Vahb_dut.cpp obj_dir/Vahb_dut.h

.PHONY: all clean

all: ahb

clean:
	rm -rf ahb* euvm_dir obj_dir link_verilator

link_verilator: ../rtl/ahb_dut.v ../rtl/i2c_master_bit_ctrl.v \
	../rtl/i2c_master_byte_ctl.v ../rtl/i2c_master_defines.v \
	../rtl/i2c_master_top.v
	verilator $(VEROPTS) $^
	(cd obj_dir; make -f Vahb_dut.mk Vahb_dut__ALL.a verilated.o verilated_threads.o)
	(cd obj_dir; make -f Vahb_dut.mk verilated_vcd_c.o;)
	(cd euvm_dir; g++ -c -I ../obj_dir/ -I $(VLBINDIR)/../share/verilator/include $(LDC2BINDIR)/../import/esdl/intf/verilator/cpp/verilated_vcd_d.cpp -o verilated_vcd_d.o)
	(cd euvm_dir; g++ -c -I ../obj_dir/ -I $(VLBINDIR)/../share/verilator/include Vahb_dut_euvm_funcs.cpp)
	(cd euvm_dir; g++ -c -I ../obj_dir/ -I $(VLBINDIR)/../share/verilator/include $(LDC2BINDIR)/../import/esdl/intf/verilator/cpp/verilated_d.cpp -o verilated_d.o)
	touch link_verilator

ahb: link_verilator $(DUTOBJ) ../testbench/i2c_reg_model.d ../testbench/ahb.d
	ldc2 $(DFLAGS) -I./euvm_dir $(TBSRC) \
	-of$@ -L-luvm-ldc-shared -L-lesdl-ldc-shared \
	 -L-ldruntime-ldc-shared $(DUTOBJ) -L-ldl -L-lstdc++

.PHONY: run_random_test
run_random_test: ahb
	./ahb +UVM_TESTNAME=ahb.random_test +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED) # +UVM_OBJECTION_TRACE

.PHONY: run_directed_reg_test
run_directed_reg_test: ahb
	./ahb +UVM_TESTNAME=ahb.directed_reg_test +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED) # +UVM_OBJECTION_TRACE

.PHONY: run_reg_tests
run_reg_tests:
	./ahb +UVM_TESTNAME=ahb.reg_test +UVM_SEQUENCE=uvm.reg.sequences.uvm_reg_bit_bash_seq.uvm_reg_bit_bash_seq +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED)

