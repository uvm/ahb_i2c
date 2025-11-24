`include "timescale.v"

module ahb_master_model_8(hclk,hresetn,hlock,haddr,hburst,hbusreq,hgrant,hprot,hrdata,hready,hresp,hsize,htrans,hwdata,hwrite,ack);
   parameter dwidth=32;
   parameter awidth=32;

   input hclk,hresetn;
   output [awidth-1:0] haddr;
   output [2:0]        hburst;
   output 	       hbusreq;
   input 	       hgrant;
   output 	       hlock;
   output [3:0]        hprot;
   input [dwidth-1:0]  hrdata;
   input 	       hready;
   input [1:0] 	       hresp;
   output [2:0]        hsize;
   output [1:0]        htrans;
   output [dwidth-1:0] hwdata;
   output 	       hwrite;
   input 	       ack;
   

   reg 		       trans;
   reg 		       delay;
   reg 		       count;
   reg [dwidth-1:0]    q;
   reg [awidth-1:0]    haddr;
   reg [2:0] 	       hburst;
   //reg hbusreq;
   reg 		       hlock;
   reg [3:0] 	       hprot;
   reg [2:0] 	       hsize;
   reg [1:0] 	       htrans;
   reg [dwidth-1:0]    hwdata;
   wire [awidth-1:0]   a;
   wire [dwidth-1:0]   d;
   reg [dwidth-1:0]    rdata;
   reg 		       hwrite;
   
   wire [dwidth-1:0]   hrdata;
   reg [31:0] 	       pre_add;
   reg [31:0] 	       next_add;
   reg [31:0] 	       latch_addr;
   //reg ack;

   parameter single = 3'b000;
   parameter incr = 3'b100;

   parameter okay =  2'b00,
     error = 2'b01,
     split = 2'b10,
     retry = 2'b11;

   parameter Burst_size_4 = 3'b000,
     Burst_size_8 = 3'b001,
     Burst_size_16 = 3'b010;

   /*  parameter PRER_LO = 3'b000;
    parameter PRER_HI = 3'b001;
    parameter CTR     = 3'b010;
    parameter RXR     = 3'b011;
    parameter TXR     = 3'b011;
    parameter CR      = 3'b100;
    parameter SR      = 3'b100;
    */
   initial
     begin

	haddr = {awidth{1'b0}};
	hburst = single;
	hlock = 1'b0 ;
	hprot = 4'b0000;
	hwdata = {dwidth{1'bx}} ;
	hsize = Burst_size_4;
	htrans = 2'b00 ;
	hwrite = 1'b0 ;
	$display("\n Info : ahb_master_model instantiated (%m) \n");
	
     end 

   always @(posedge hclk)
     begin
	if(hwrite == 1 )
	  begin
	     count = 0;
	     case({htrans})
	       2'b00: begin
		  if(hready == 1 && hresp == 0 )
		    begin
		       haddr = a;
		       hwdata = d;
		    end
	       end
	       2'b01:;
	       2'b10:;
	       2'b11:;
	       
	     endcase // case ({htrans})
	  end // if (hwrite == 1)
	if (hwrite == 0 )
	  begin
	     count = 0;
	     case({htrans})
	       2'b00:begin
		  if(!hready)
		    begin
		       rdata = hrdata;
		    end
	       end
	     endcase // case ({htrans})
	  end // if (hwrite == 0 )
     end  
endmodule // ahb_master_model_8






/*
 

 task ahb_write(input delay,input [awidth-1:0] a,input [dwidth-1:0] d);

 begin
 assign hwrite = 1'b1;

 repeat(delay) @(posedge hclk )  // first cycle sending address and control info.
 haddr= a;
 htrans= 2'b00;
 hburst= hburst ? single : incr ;
 hsize = Burst_size_4;
 
 // $display(" haddr given in sending address+control_info in write cycle =%h,,%b,%b,%b",haddr,htrans,hsize,hburst);

 if (hwrite == 1)
 begin
 count = 0;
 // $display("hwrite in write  and hready in write =%b,%b",hwrite,hready);
 case({htrans}) 
 2'b00: //Non-seq
 if( hready == 1 || hresp == okay)//try ||
 begin
 //  if(hburst == single)
 //  @(posedge hclk)
 haddr = a;
 hwdata=d;
 $display("haddr fo non-seq=%h and hwdata fo non-seq =%h",haddr, hwdata);
		    end 
 2'b01: ;
 2'b10: ;
 2'b11: ;

	      endcase
	   end
      end
   endtask


 task ahb_read(input delay,input [awidth-1:0] a,input [dwidth-1:0] d);
 begin
 assign hwrite = 1'b0;
 begin
 @(posedge hclk)  // first cycle sending address and control info.
 haddr=a;
 htrans= 2'b00;
 // hburst= hburst ? single : incr ;
 //hsize = Burst_size_4;
 //$display(" haddr given in sending address+control_info in read cycle=%h,%b,%b",a,htrans,hburst,hsize);

 if (hwrite == 0 && hready == 1)  //hready should be 1
 // begin
 count = 0; 
 //   $display("hwrite in read=%b, hready in read=%b", hwrite, hready);
 
 case ({htrans})
 2'b00: //non-seq
 if(hready) // not hready

 begin  
 //  $display("hready in read cycle");
 d = hrdata;
 $display("data on hrdata:non-seq =%h",d);       
		  end
 else if(!hready)
 begin 
 d=32'h00000000;
		  end
 2'b01: ;
 2'b10: ;
 2'b11: ;
	    endcase
	 end
      end
   endtask

 task ahb_cmp(input delay,input [awidth-1:0] a,input [dwidth-1:0] d_exp);
 begin
 @(posedge hclk)
 ahb_read (delay,a,q);
 $display(" in compare cycle :a1=%h,d_exp=%h",a,d_exp);
 if (d_exp !== q)
 begin
 $display("Data compare error.Recieved %h, expected %h at time %t", q,d_exp,$time);
	   end
      end
   endtask 
 

 /*always @(posedge hclk)
  begin
  case({haddr[2:0]})
  3'b000 : begin  haddr[2:0] = 3'b001; end
  3'b001: begin  haddr[2:0]  = 3'b010;  end 
  3'b010: begin   haddr[2:0] =  3'b011 ;          end
  3'b011: begin   haddr[2:0] =  3'b100 ; end
  3'b100: begin   haddr[2:0] = 3'b101; end
  3'b101: begin haddr[2:0]  = 3'b110; end
  3'b110: begin haddr[2:0]  = 3'b111; end
  3'b111: begin haddr[2:0] =  3'b000; end
  

endcase
end*/
