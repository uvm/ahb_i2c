`include "timescale.v"
`include "i2c_master_top.v"
// `include "ahb_master_model_5.v"
`include "i2c_master_byte_ctl.v"
`include "i2c_master_bit_ctrl.v"
`include "i2c_master_defines.v"
`include "i2c_slave_model.v"
// `include "timescale.v"
module ahb_dut(/*AUTOARG*/
   // Outputs
   hresp, hready, hrdata,
   // Inputs
   hwrite, hwdata, htrans, hsize, hresetn, hclk, hburst, haddr
   );
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input [2:0]		haddr;			// To i2c_top of i2c_master_top.v
   input [2:0]		hburst;			// To i2c_top of i2c_master_top.v
   input		hclk;			// To i2c_top of i2c_master_top.v
   input		hresetn;		// To i2c_top of i2c_master_top.v
   input [2:0]		hsize;			// To i2c_top of i2c_master_top.v
   input [1:0]		htrans;			// To i2c_top of i2c_master_top.v
   input [7:0]		hwdata;			// To i2c_top of i2c_master_top.v
   input		hwrite;			// To i2c_top of i2c_master_top.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [7:0]		hrdata;			// From i2c_top of i2c_master_top.v
   output		hready;			// From i2c_top of i2c_master_top.v
   output [1:0]		hresp;			// From i2c_top of i2c_master_top.v
   // End of automatics
   
   /*AUTOWIRE*/

   /*AUTOREGINPUT*/
   
   wire        scl, scl0_o, scl0_oen, scl1_o, scl1_oen;
   wire        sda, sda0_o, sda0_oen, sda1_o, sda1_oen;

   parameter PRER_LO = 3'b000;
   parameter PRER_HI = 3'b001;
   parameter CTR     = 3'b010;
   parameter RXR     = 3'b011;
   parameter TXR     = 3'b011;
   parameter CR      = 3'b100;
   parameter SR      = 3'b100;

   parameter TXR_R   = 3'b101; // undocumented / reserved output
   parameter CR_R    = 3'b110; // undocumented / reserved output

   parameter RD      = 1'b1;
   parameter WR      = 1'b0;
   parameter SADR    = 7'b0010_000;

   //
   // Module body
   //

   // generate clock
   // always #5 hclk = ~hclk;

   // hookup ahb master model
   
/* -----\/----- EXCLUDED -----\/-----
   ahb_master_model_8  #(8, 32) u0(
				   .hclk(hclk),
				   .hresetn(hresetn),
				   .haddr(haddr),
				   .hwdata(hwdata),
				   .hrdata(hrdata),
				   .htrans(htrans),
				   .hwrite(hwrite),
				   .hresp(hresp),
				   .hburst(hburst),
				   .hbusreq(hbusreq),
				   .hgrant(1'b1),
				   .hready(1'b1),
				   .hsize(hsize),
				   .hprot(hprot),
				   .hlock(hlock)
				   );
 -----/\----- EXCLUDED -----/\----- */

   // hookup ahb_i2c_master core
   i2c_master_top i2c_top (
			   // i2c signals
			   .scl_pad_i(scl),
			   .scl_pad_o(scl0_o),
			   .scl_padoen_o(scl0_oen),
			   .sda_pad_i(sda),
			   .sda_pad_o(sda0_o),
			   .sda_padoen_o(sda0_oen),
			   .arst_i		(arst_i),
  			   // ahb interface
			   /*AUTOINST*/
			   // Outputs
			   .hrdata		(hrdata[7:0]),
			   .hready		(hready),
			   .hresp		(hresp[1:0]),
			   // Inputs
			   .hclk		(hclk),
			   .hresetn		(hresetn),
			   .haddr		(haddr[2:0]),
			   .hwdata		(hwdata[7:0]),
			   .htrans		(htrans[1:0]),
			   .hsize		(hsize[2:0]),
			   .hburst		(hburst[2:0]),
			   .hwrite		(hwrite));


   // hookup i2c slave model
   i2c_slave_model #(SADR)  i2c_slave (
				       .scl(scl),
				       .sda(sda)
				       ); 

   // create i2c lines
   delay m0_scl (scl0_oen ? 1'bz : scl0_o, scl),
     m1_scl (scl1_oen ? 1'bz : scl1_o, scl),
     m0_sda (sda0_oen ? 1'bz : sda0_o, sda),
     m1_sda (sda1_oen ? 1'bz : sda1_o, sda);

   pullup p1(scl); // pullup scl line
   pullup p2(sda); // pullup sda line

   initial
     begin
`ifdef WAVES
	$shm_open("waves");
	$shm_probe("AS",tst_bench_top,"AS");
	$display("INFO: Signal dump enabled ...\n\n");
`endif

	force i2c_slave.debug = 1'b1; // enable i2c_slave debug information
	//	      force i2c_slave.debug = 1'b0; // disable i2c_slave debug information

	//   $display("\nstatus: %t Testbench started\n\n", $time);

	//	      $dumpfile("bench.vcd");
	//	      $dumpvars(1, tst_bench_top);
	//	      $dumpvars(1, tst_bench_top.i2c_slave);

	// initially values
     end	   
endmodule

`include "timescale.v"
module delay (in, out);
   input  in;
   output out;

   assign out = in;

   specify
      (in => out) = (600,600);
   endspecify

endmodule 
