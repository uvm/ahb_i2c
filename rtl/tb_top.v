`timescale 1ns/1ns
`include "ahb_dut.v"

module tb_top;

   reg clk;
   reg resetn;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [7:0]		hrdata;			// From dut of ahb_dut.v
   wire			hready;			// From dut of ahb_dut.v
   wire [1:0]		hresp;			// From dut of ahb_dut.v
   // End of automatics
   
   /*AUTOREGINPUT*/
   // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
   reg [2:0]		haddr;			// To dut of ahb_dut.v
   reg [2:0]		hburst;			// To dut of ahb_dut.v
   reg [2:0]		hsize;			// To dut of ahb_dut.v
   reg [1:0]		htrans;			// To dut of ahb_dut.v
   reg [7:0]		hwdata;			// To dut of ahb_dut.v
   reg			hwrite;			// To dut of ahb_dut.v
   // End of automatics

   integer queue_len;
   integer pull_val;
   
   reg [7:0]		addr;			// To dut of ahb_dut.v
   reg [7:0]		burst;			// To dut of ahb_dut.v
   reg [2:0]		size;			// To dut of ahb_dut.v
   reg [7:0]		trans;			// To dut of ahb_dut.v
   reg [7:0]		wdata;			// To dut of ahb_dut.v
   reg			write;			// To dut of ahb_dut.v

   ahb_dut dut (.hclk   (clk),
		.hresetn (resetn),
		/*AUTOINST*/
		// Outputs
		.hrdata			(hrdata[7:0]),
		.hready			(hready),
		.hresp			(hresp[1:0]),
		// Inputs
		.haddr			(haddr[2:0]),
		.hburst			(hburst[2:0]),
		.hsize			(hsize[2:0]),
		.htrans			(htrans[1:0]),
		.hwdata			(hwdata[7:0]),
		.hwrite			(hwrite));


   initial begin: driver
      forever begin
	 @(negedge clk);
	 if(resetn == 0 && hready != 0) begin
	    $display("Device is not ready for a transaction!!");
	 end
	 else begin
	    $display("Start Transaction");
	    pull_val = $pull_ahb(queue_len);
	    $display("queue_len: %d", queue_len);
	    if (queue_len == 1) begin
	       htrans <= 0;		// IDLE
	    end // if (queue_len == 1)
	    else begin
	       if (queue_len > 1) begin
		  pull_val = $pull_ahb_addr(trans, write, addr, burst, size);
		  $display("trans: %b, addr: %b, burst: %b, size: %b, write: %b",
			   trans, addr, burst, size, write);
		  htrans <= trans;
		  hwrite <= write;
		  haddr  <= addr;
		  hburst <= burst; 
		  hsize  <= size;
	       end // if (queue_len > 1)
	       if (queue_len > 2) begin
		  pull_val = $pull_ahb_data(trans, write, wdata, hresp, hrdata);
		  $display({"trans: %b, write: %b, wdata: %b,",
			    " hresp: %b, hrdata: %b"},
			   trans, write, wdata, hresp, hrdata);
		  
		  if(trans == 2 /*SEQ*/ || trans == 1 /*NONSEQ*/) 
		    if(write == 1'b1)
		      begin
			 hwdata <= wdata;
		      end // else: !if(req_list[2].hwrite == 1'b0)
	       end // if (queue_len > 2)
	    end
	 end
      end
   end // block: driver
   
   initial begin
      $dumpfile("bench.vcd");
      $dumpvars(0, dut, clk, resetn);
      $dumpon;
   end

   always @(posedge clk) begin
      if(resetn == 0) begin
	 haddr <= 0;
	 hwdata <= 0;
      end
   end
   

   initial begin
      resetn = 1'b1;
      #100;
      resetn = 1'b0;

      #1000;
      resetn = 1'b1;
   end

   initial begin
      forever begin
	 clk = 1'b0;
	 #50;
	 clk = 1'b1;
	 #50;
      end
   end // initial begin

   initial begin: watchdog
      #1000000;
      $finish;
   end
   
endmodule

