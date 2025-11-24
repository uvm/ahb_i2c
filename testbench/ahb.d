import esdl;
import uvm;
import uvm.reg;

import i2c_reg_model;

import esdl.intf.verilator.verilated;
import esdl.intf.verilator.trace;
import std.stdio;
import std.string: format;

enum rw_e: byte {READ, WRITE};

enum trans_e: ubvec!2 {
  IDLE = UBVEC!(2, 0),
  NONSEQ = UBVEC!(2, 1),
  SEQ = UBVEC!(2, 2),
  BUSY = UBVEC!(2, 3)
}

enum burst_e: ubvec!3 {
  SINGLE = UBVEC!(3, 0),
  INCR = UBVEC!(3, 1),
  WRAP4 = UBVEC!(3, 2),
  INCR4 = UBVEC!(3, 3),
  WRAP8 = UBVEC!(3, 4),
  INCR8 = UBVEC!(3, 5),
  WRAP16 = UBVEC!(3, 6),
  INCR16 = UBVEC!(3, 7)
}

class ahb_reg_seq: uvm_reg_sequence!(uvm_sequence!(uvm_reg_item)) // uvm_sequence!ahb_transfer
{
  reg_block ahb_model;
   
  mixin uvm_object_utils;
   
  this(string name = "ahb_reg_seq") {
    super(name);
  }

  override void body() {
    uvm_reg_data_t data, rd_data;
      
    uvm_status_e status;

    uvm_info("Reg_seq", " Executing sequence", UVM_NONE);

    assert (model !is null);

    ahb_model = cast (reg_block) model;
    assert (ahb_model !is null);
    
    ahb_model.PRERlo_h.write(status, 0x81, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot write into register PRERlo_h");
    }
    ahb_model.PRERlo_h.read(status, data, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot read from register PRERlo_h");
    }
    writefln("read data is %h", data);
    ahb_model.PRERlo_h.write(status, 0x80, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot write into register PRERlo_h");
    }
    ahb_model.PRERlo_h.read(status, data, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot read from register PRERlo_h");
    }
    writefln("read data is %h", data);
    ahb_model.PRERhi_h.write(status, 0xDE, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot write into register PRERhi_h");
    }
    ahb_model.PRERhi_h.read(status, data, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot read from register PRERhi_h");
    }
    writefln("read data is %h", data);
    ahb_model.PRERhi_h.write(status, 0x42, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot write into register PRERhi_h");
    }
    ahb_model.PRERhi_h.read(status, data, UVM_DEFAULT_DOOR, null, this);
    if (status == UVM_NOT_OK) {
      writeln(" cannot read from register PRERhi_h");
    }
    writefln("read data is %h", data);
    // ahb_model.CTR_h.IEN.write(status, 0x1, UVM_DEFAULT_DOOR, null, this);
    // if (status == UVM_NOT_OK) {
    //   writeln(" cannot write into register CTR_h.IEN");
    // }
    // ahb_model.CTR_h.IEN.read(status, data, UVM_DEFAULT_DOOR, null, this);
    // if (status == UVM_NOT_OK) {
    //   writeln(" cannot read from register CTR_h.IEN");
    // }
    // // writefln("read data is %h", data);
    // ahb_model.CTR_h.IEN.read(status, data, UVM_DEFAULT_DOOR, null, this);
    // if (status == UVM_NOT_OK) {
    //   writeln(" cannot read from register CTR_h.IEN");
    // }
    // writefln("read data is %h", data);
    uvm_info("Reg_seq", "Sequence completed", UVM_LOW);
  }
}

class ahb_transfer: uvm_sequence_item
 {
   mixin uvm_object_utils;

   @UVM_DEFAULT {
     ubvec!8 hrdata;
     @rand ubyte hwdata;
     @rand ubyte haddr;
     @rand ubvec!1 hwrite;
     @rand ubvec!3 hsize;
     @rand trans_e htrans;
     @rand burst_e hburst;
     ubvec!2 hresp;
     bool response_required = false;
   }

   this(string name = "ahb_transfer") {
     super(name);
   }

   constraint!q{
     haddr < 8;
   } haddr_range;

   constraint!q{
     hburst == 0;
   } valid_hnurst;
}
 
class ahb_transfer_sequence: uvm_sequence!(ahb_transfer)
{

  mixin uvm_object_utils;
  this(string name="ahb_transfer_sequence") {
    super(name);
    rand_ahb = ahb_transfer.type_id.create("ahb_trans");
  }

  @UVM_DEFAULT {
    ahb_transfer rand_ahb;
  }

  override void body() {
   
    rand_ahb.randomize();
    
    ahb_transfer ahb_trans = cast(ahb_transfer) rand_ahb.clone();
  
    // ahb_trans.print();

    //  with { ahb_trans.haddr == 32'hfffa; })


    // wait_for_grant();
    
    // send_request(ahb_trans);

    start_item(ahb_trans);  
    finish_item(ahb_trans);

    // ahb_trans.print();
   
    //   start_item(ahb_trans);

    //   assert(ahb_trans.randomize() with {rw_1 == READ;});
    //  finish_item(ahb_trans);
 
   
    // ahb_trans.print();
   
  }

}

class tb_env: uvm_component
{
   mixin uvm_component_utils;
   
  uvm_reg_sequence!(uvm_sequence!(uvm_reg_item)) seq;

  @UVM_BUILD {
    ahb_agent agent;
  }
   
  reg_to_ahb_adapter adap;
  reg_block model;

  this(string name, uvm_component parent=null) {
     super(name,parent);
   }

   override void build_phase(uvm_phase phase) {
     uvm_info("INFO","Called reg_layer::build_phase", UVM_NONE);
     if (model is null) {
       uvm_info("INFO", "Creating the model", UVM_NONE);
       model = reg_block.type_id.create("model", this);
       model.build();
       model.lock_model();
       //  uvm_config_object::set(this, "*", "model", model); //set register model for tstbench
     }
   }
   
  override void connect_phase(uvm_phase phase) {
    agent.driver.make_full_duplex();
    uvm_info("INFO","Called reg_layer:: connect_phase", UVM_NONE);   
    if (model.get_parent() is null) {
      if (adap is null) {
	uvm_info("INFO", "Creating the adapter", UVM_NONE);
	adap = reg_to_ahb_adapter.type_id.create("adap",this);
      }
      model.get_default_map.set_sequencer(agent.sequencer, adap);
      model.get_default_map.set_auto_predict(1);
    }
  }

  override void run_phase(uvm_phase phase) {
    agent.driver.disable_pipeline();
    phase.raise_objection(this, "reg_seq");
    phase.get_objection.set_drain_time(this, 100.nsec);
    
    if (seq is null) {
      uvm_info("NO_SEQUENCE","Env's sequence is not defined. Nothing to do. Exiting.", UVM_DEBUG);
      return;
    }

    seq.model = model;
    uvm_info("REG_SEQUENCE","Starting Reg Sequence", UVM_DEBUG);
    seq.start(agent.sequencer);
    uvm_info("REG_SEQUENCE","Done Starting Reg Sequence", UVM_DEBUG);

    phase.drop_objection(this, "reg_seq");
  }
}

class reg_to_ahb_adapter: uvm_reg_adapter
{
  this(string name = "reg_to_ahb_adapter") {
    super(name);
    provides_responses = 1;
  }

  override uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw) {
      /*ahb_transfer_sequence my_seq; // original sequence type to allow access to the sequence's data members and methods  
       ahb_transfer item = get_item(); 
       if($cast(my_seq, item.parent)) // data contained within that sequence to provide context for bus_item creation
       begin
       `uvm_error("reg2bus_adapter:parent casting failed")
       return;
end */
      ahb_transfer transfer = ahb_transfer.type_id.create("ahb_transfer");
      transfer.hwrite  = (rw.kind == UVM_READ) ? 0 : 1;
      transfer.haddr = cast(ubyte) rw.addr;
      transfer.htrans = trans_e.NONSEQ;
      transfer.hwdata = cast(ubyte) rw.data;
      return transfer;
  }

  override void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw) {
    ahb_transfer transfer = cast(ahb_transfer) bus_item;
    if (transfer is null) {
      uvm_fatal("NOT_REG_TYPE", "Incorrect bus item type. Expecting ahb_transfer");
      return;
    }
    rw.kind = (transfer.hwrite == 0) ? UVM_READ : UVM_WRITE;
    rw.addr = transfer.haddr;
    if(rw.kind == UVM_WRITE) rw.data = transfer.hwdata;
    else rw.data = cast(ubvec!8) transfer.hrdata;
    rw.status = UVM_IS_OK;
  }

  mixin uvm_object_utils;
}


class ahb_sequencer: uvm_sequencer!(ahb_transfer)
{

  mixin uvm_component_utils;
  
  this(string name, uvm_component parent=null) {
    super(name, parent);
  }

}

class ahb_env: uvm_env
{

  mixin uvm_component_utils;

  //Components of the enviorment
   
  @UVM_BUILD ahb_agent agent;

  this(string name, uvm_component parent) {
    super(name, parent);
  }

}

class ahb_agent: uvm_agent
{
  @UVM_BUILD {
    ahb_sequencer sequencer;
    ahb_driver    driver;
  }
 
  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name,parent);
  }

  override void connect_phase(uvm_phase phase) {
    if(get_is_active() == UVM_ACTIVE) {
      driver.seq_item_port.connect(sequencer.seq_item_export);
      writeln("Driver is connected to sequencer");
    }
  }
}

class ahb_driver_cbs: uvm_callback
{
  void pre_tx(ahb_driver xactor, ahb_transfer cycle) {}
  void post_tx(ahb_driver xactor, ahb_transfer cycle) {}
}
  
class ahb_driver: uvm_driver!(ahb_transfer)
{
   
  mixin uvm_component_utils;
   
  ahb_intf ahb_if;

  Queue!ahb_transfer req_list;
  
  bool pipeline_enabled = true;
  bool is_full_duplex = false;

  void make_full_duplex() {
    is_full_duplex = true;
  }

  void disable_pipeline() {
    pipeline_enabled = false;
  }
   
  this(string name,uvm_component parent) {
    super(name, parent);
  }

  override void run_phase(uvm_phase phase) {
    super.run_phase(phase);
    uvm_info("INFO","called my_driver::run_phase", UVM_NONE);
    get_and_drive(phase);
  }

  void get_and_drive(uvm_phase phase) {

    ahb_transfer idle = new ahb_transfer("idle transaction");
    idle.htrans = trans_e.IDLE;
    while(true) {
      seq_item_port.get_next_item(req);    
      phase.raise_objection(this);
      rsp = cast(ahb_transfer) req.clone();
      rsp.set_id_info(req);
      drive_transfer(rsp);
      if (pipeline_enabled == 0) {
	drive_transfer(idle);
	drive_transfer(idle);
      }
      seq_item_port.item_done(rsp);
      phase.drop_objection(this);
    }
  }

  void drive_transfer(ahb_transfer tx) {
    wait (ahb_if.hclk.posedge());

    while (ahb_if.hreset)
      wait (ahb_if.hclk.posedge());
    
    req_list.pushFront(tx);
    
    if(req_list.length == 1 && ahb_if.hready == 1) {
      ahb_if.htrans = trans_e.IDLE;
    //	      $dislay(" first transaction is inserted");
    }
      
    if (req_list.length >  1 && ahb_if.hready == 1) { // address phase
      // req_list.push_front(trans);
      ahb_if.haddr = req_list[1].haddr.toubvec!3;
      ahb_if.htrans = req_list[1].htrans;
      ahb_if.hwrite = req_list[1].hwrite;
      ahb_if.hsize = req_list[1].hsize;
      ahb_if.hburst = req_list[1].hburst; 

      // writefln("0d.in req_list> 1 haddr,htrans,hwrite,hsize,hburst,%h,%b,%b,%b,%b ",
      // 	       ahb_if.haddr,ahb_if.htrans,ahb_if.hwrite,ahb_if.hsize,ahb_if.hburst);
    }

    if (req_list.length > 2 && ahb_if.hready == 1) { // data phase
      req_list[2].hresp = ahb_if.hresp;
      // $display(" req_list[2].hresp=%b",req_list[2].hresp);
	 
      if (req_list[2].htrans == trans_e.SEQ || req_list[2].htrans == trans_e.NONSEQ) {
	if (req_list[2].hwrite == false) {
	  req_list[2].hrdata = ahb_if.hrdata;
	  // writefln("ahb_if.hrdata =%h", ahb_if.hrdata);
	  // writefln("req_list[1].hrdata =%h ", req_list[2].hrdata);
	  // writefln("Inside driver getting read  transaction at time %t", $time);
	  req_list[2].print();
	}
	else {
	  ahb_if.hwdata = req_list[2].hwdata;
	  // writefln("req_list[1].hwdata = %h", ahb_if.hwdata);
	  // writefln("Inside driver getting write transaction at time %t", $time);
	  req_list[2].print();
		
	} // else: !if(req_list[2].hwrite == 1'b0)
      }
	 
      req_list.popBack();
    }

    if (tx !is null) 
      uvm_info("INFO Drive Transfer", tx.sprint(), UVM_NONE);
    // req_egress.put(tx);
  }
  
  override void connect_phase(uvm_phase phase) {
    auto cs = uvm_coreservice_t.get();
    uvm_config_db!ahb_intf.get(this, "", "ahb_if", ahb_if);
    if (ahb_if is null) assert (false);
  }

  override void final_phase(uvm_phase phase) {
    uvm_info("ENDTEST", "Sending a null transaction to terminate test", UVM_NONE);
    // req_egress.put(null);
  }
  
}

class directed_reg_test: uvm_test
{
  mixin uvm_component_utils;
  this(string name, uvm_component parent=null) {
    super(name, parent);
    uvm_info("INFO", "Called directed_reg_test.new", UVM_NONE);
  }
   
  tb_env env;

  override void build_phase(uvm_phase phase) {
    super.build_phase(phase);
    env = tb_env.type_id.create("env", this);
    ahb_reg_seq seq = ahb_reg_seq.type_id.create("seq", this);
    env.seq = seq;
  }

  // override void run_phase(uvm_phase phase) {
  //   env.agent.driver.disable_pipeline();
  //   uvm_info("INFO", "Called directed_reg_test.run_phase", UVM_NONE);
  //   phase.raise_objection(this);   
  //   ahb_reg_seq seq = ahb_reg_seq.type_id.create("seq", this);
  //   writeln("ahb_reg_seq created in directed_reg_test");
  //   seq.model = env.model;
  //   // seq.start(null);
  //   seq.start(env.agent.sequencer);
  //   phase.drop_objection(this);
  // }

  // env.model.reset();
   
      
      
  /* -----\/----- EXCLUDED -----\/-----
     begin
     uvm_cmdline_processor opts = uvm_cmdline_processor::get_inst();

     uvm_reg_sequence  seq;
     string            seq_name;

     void'(opts.get_arg_value("+UVM_REG_SEQ=", seq_name));
         
     if (!$cast(seq, factory.create_object_by_name(seq_name,
     get_full_name(),
     "seq"))
     || seq == null) begin
     `uvm_fatal("TEST/CMD/BADSEQ", {"Sequence ", seq_name,
     " is not a known sequence"})
     end
     seq.model = env.model;
     //	 $display("seq.model == env.model");
	 
     seq.start(null);
     end
     -----/\----- EXCLUDED -----/\----- */
      
   
  override void report_phase(uvm_phase phase) {
    uvm_info("INFO", "Called my_test::report_phase", UVM_NONE);
  }
}

class reg_test: uvm_test
{
  mixin uvm_component_utils;

  tb_env env;

  uvm_reg_sequence!(uvm_sequence!uvm_reg_item) seq;

  this(string name="reg_test", uvm_component parent=null) {
    super(name, parent);
  }

  override void build_phase(uvm_phase phase) {
    super.build_phase(phase);

    env = tb_env.type_id.create("env", this);

    string seq_name;
    CommandLine cmdl = new CommandLine();
    if (! cmdl.plusArgs("UVM_SEQUENCE=%s", seq_name)) {
      uvm_fatal("REG TEST", "Test Sequence not specified, use +UVM_SEQUENCE=<reg seq name> command line option");
    }

    //uvm_reg_sequence!(uvm_sequence!uvm_reg_item) seq;

    uvm_coreservice_t cs = uvm_coreservice_t.get();                                                     
    uvm_factory factory = cs.get_factory();
  
    uvm_object obj = factory.create_object_by_name(seq_name, "reg_test", seq_name);

    seq = cast (uvm_reg_sequence!(uvm_sequence!uvm_reg_item)) obj;
    
    if (seq is null) {
      uvm_report_error("WRONG_TYPE", "The type_name given '" ~ seq_name ~
		       "' with context 'reg_test' did not produce the expected type.");
    }
    
    env.seq = seq;
  }

  override void connect_phase(uvm_phase phase) {
    super.connect_phase(phase);
    seq.model = env.model;
  }

}

class random_test: uvm_test
{

  // my_test gets instantiated by means of the +UVM_TESTNAME command line argument and run_test()
  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name, parent);
    uvm_info("INFO", "Called my_test::new", UVM_NONE);
  }

  @UVM_BUILD {
    ahb_env env;
  }
   
  override void run_phase(uvm_phase phase) {
    uvm_info("INFO", "Called my_test::run_phase", UVM_NONE);
    ahb_transfer_sequence seq = ahb_transfer_sequence.type_id.create("seq");
    phase.raise_objection(this);
    for (size_t i=0; i!=100; ++i) {
      uvm_info("INFO", "Called my_test::run_phase", UVM_NONE);
      seq.randomize();
      auto sequence = cast(ahb_transfer_sequence) seq.clone();
      // $display("Randomising TEST SEQUENCE FOR RANDOM TEST");
      // seq.print();
      sequence.start(env.agent.sequencer);
    }
    phase.drop_objection(this);
  }

  override void report_phase(uvm_phase phase) {
    uvm_info("INFO", "Called my_test::report_phase", UVM_NONE);
  }
}

class ahb_intf: VlInterface
{
  Port!(Signal!(ubvec!1)) hclk;
  Port!(Signal!(ubvec!1)) hreset;
  
  VlPort!2 hresp;
  VlPort!1 hready;
  VlPort!8 hrdata;
  VlPort!1 hwrite;
  VlPort!8 hwdata;
  VlPort!2 htrans;
  VlPort!3 hsize;
  VlPort!3 hburst;
  VlPort!3 haddr;
}

class Top: Entity
{
  import Vahb_dut_euvm;
  import esdl.intf.verilator.verilated;

  VerilatedVcdD _trace;

  Signal!(ubvec!1) hreset;
  Signal!(ubvec!1) hclk;

  DVahb_dut dut;

  ahb_intf ahb_if;

  void opentrace(string vcdname) {
    version (DUMPVCD) {
      traceEverOn(true);
      if (_trace is null) {
        _trace = new VerilatedVcdD();
        dut.trace(_trace, 99);
        _trace.open(vcdname);
      }
    }
  }

  void closetrace() {
    if (_trace !is null) {
      _trace.flush();
      _trace.close();
      _trace = null;
    }
  }

  override void doConnect() {
    import std.stdio;

    // Interface connections for Driver Side
    ahb_if.hclk(hclk);
    ahb_if.hreset(hreset);


    ahb_if.hresp(dut.hresp);
    ahb_if.hready(dut.hready);
    ahb_if.hrdata(dut.hrdata);
    ahb_if.hwrite(dut.hwrite);
    ahb_if.hwdata(dut.hwdata);
    ahb_if.htrans(dut.htrans);
    ahb_if.hsize(dut.hsize);
    ahb_if.hburst(dut.hburst);
    ahb_if.haddr(dut.haddr);
  }

  override void doBuild() {
    dut = new DVahb_dut();
    opentrace("ahb_dut.vcd");
  }
  
  override void doFinish() {
    closetrace();
  }
  
  Task!stimulateClock stimulateClockTask;
  Task!stimulateReset stimulateResetTask;
  
  void stimulateClock() {
    while (true) {
      hclk = false;
      dut.hclk = false;
      wait (1.nsec);
      dut.eval();
      if (_trace !is null) _trace.dump(getSimTime().getVal());
      wait (4.nsec);
      hclk = true;
      dut.hclk = true;
      wait (1.nsec);
      dut.eval();
      if (_trace !is null) _trace.dump(getSimTime().getVal());
      wait (4.nsec);
    }
  }

  void stimulateReset() {
    hreset = true;
    dut.hresetn = false;
    wait (100.nsec);
    hreset = false;
    dut.hresetn = true;
  }

}

class uvm_ahb_tb: uvm_context
{
  Top top;
  override void initial() {
    uvm_config_db!(ahb_intf).set(null, "uvm_test_top.env.agent.driver", "ahb_if", top.ahb_if);
  }
}

void main(string[] args) {
  import std.stdio;
  uint random_seed;

  CommandLine cmdl = new CommandLine(args);

  if (cmdl.plusArgs("random_seed=" ~ "%d", random_seed))
    writeln("Using random_seed: ", random_seed);
  else random_seed = 1;

  auto tb = new uvm_ahb_tb;
  tb.elaborate("tb", args);
  tb.set_seed(random_seed);
  tb.start();
}
