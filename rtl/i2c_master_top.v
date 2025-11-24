`ifndef _I2C_MASTER_TOP_V_
 `define _I2C_MASTER_TOP_V_

 `include "timescale.v"
// synopsys translate_on

 `include "i2c_master_defines.v"
//`include "i2c_master_byte_ctl.v"

module i2c_master_top(hclk, hresetn, haddr, hwdata, hrdata, hwrite,
                      hresp, htrans, hsize, hburst, hready, scl_pad_i,
                      scl_pad_o, scl_padoen_o, sda_padoen_o,
                      arst_i, sda_pad_i, sda_pad_o);
   // parameters
   parameter ARST_LVL = 1'b0; // asynchronous reset level

   // inputs & outputs

   input     hclk;   //master clock input 
   input     hresetn;  //active low to reset the signal
   input     arst_i;  // asynchronous reset
   input [2:0] haddr; // 32 bit system address bus
   input [7:0] hwdata;         
   //output  [7:0] hwdata; //  write data bus to transfer data from master to slave during write operations.
   output [7:0] hrdata ; // read data bus to transfer data from slave to master during write operations.
   input [1:0]  htrans; // type of transfer
   input [2:0]  hsize;  // size of transfer
   input [2:0]  hburst; // if burst,4,8,16
   output       hready; // hready=1: transfer has finished
   input        hwrite; //hwrite =1 write , hwrite =0 read transfer //input given first then changed
   output [1:0] hresp; //info on status of transfer 
   
   parameter    okay = 2'b00;
   parameter    error = 2'b01;
   parameter    split = 2'b10; 
   parameter    retry = 2'b11; 
   parameter    single = 3'b000;
   
   reg [7:0]    hrdata;          
   reg          count;
   reg [2:0]    a;
   reg [7:0]    d;

   wire [7:0]   hwdata;
   //  reg [7:0] hwdata;
   reg          hready;
   //   wire hwrite;
   reg [1:0]    hresp;
   
   // I2C signals
   // i2c clock line
   input        scl_pad_i;       // SCL-line input
   output       scl_pad_o;       // SCL-line output (always 1'b0)
   output       scl_padoen_o;    // SCL-line output enable (active low)

   // i2c data line
   input        sda_pad_i;       // SDA-line input
   output       sda_pad_o;       // SDA-line output (always 1'b0)
   output       sda_padoen_o;    // SDA-line output enable (active low)



   //
   // variable declarations
   //

   // registers
   reg [15:0]   prer; // clock prescale register
   reg [ 7:0]   ctr;  // control register
   reg [ 7:0]   txr;  // transmit register
   wire [ 7:0]  rxr;  // receive register
   reg [ 7:0]   cr;   // command register
   reg [ 7:0]   sr;   // status register //#wire initially
   //        reg [7:0] sr;
   // done signal: command completed, clear command register
   wire         done;

   wire         core_en;
   wire         ien;
   wire         sta;
   wire         sto;
   wire         rd;
   wire         wr;
   wire         ack;
   wire         iack;
   

   // status register signals
   wire         irxack;
   reg          rxack;       // received aknowledge from slave
   reg          tip;         // transfer in progress
   reg          irq_flag;    // interrupt pending flag
   wire         i2c_busy;    // bus busy (start signal detected)
   wire         i2c_al;      // i2c bus arbitration lost
   reg          al;          // status register arbitration lost bit

   /* -----\/----- EXCLUDED -----\/-----
    initial 
    begin
    $dumpfile("bench2.vcd");
    $dumpvars(1,txr,rxr,prer,ctr,cr,sr,haddr);
     end
    -----/\----- EXCLUDED -----/\----- */
   wire         rst_i = hresetn ^ ARST_LVL;
   
   
   always @(posedge hclk)
     begin
        if (hwrite == 1) // || hready == 1)
          begin  
             case (haddr) // synopsys parallel_case
               3'b000: begin
                  prer [7:0] <= hwdata;               
                  // $display("display prer_lo :hwdata=%h, haddr=%b",hwdata, haddr);
                  
               end 
               3'b001: begin 
                  prer [15:8] <= hwdata;         
                  // $display(" display prer_hi:hwdata =%h",prer[15:8]);
               end
               3'b010: begin
                  ctr <= hwdata;     
               end
               3'b011: begin 
                  txr <= #1 hwdata ; // write in transmit register (txr)
                  // $display(" hwdata : rxr = %h",hwdata);
               end     
               3'b100: begin
                  sr <= #1 hwdata;  //hwdata <= #1 sr;  // write is command register (cr)
                  //$display(" hwdata : sr =%b,%b",hwdata,haddr);
               end
               3'b101: begin 
                  txr <= hwdata;
                  //$display(" hwdata : txr= %h" , hwdata);
               end
               3'b110: begin
                  cr <= #1 hwdata;
                  //$display(" hwdata : cr =%h,%h",hwdata,haddr);
               end
               3'b111: begin 
                  // hwdata <= #1 0;   // reserved
                  // $display(" hwdata :reserved =%h",hwdata);
               end  
             endcase
          end
     end
   always @(posedge hclk or negedge hresetn or prer or txr or rxr or sr or cr)
     begin
        hready = 1'b1;
        hresp = okay;
     end
   
   // generate registers
   always @(posedge hclk or negedge rst_i)
     begin
        /*       if (!rst_i)
         begin
         prer <= #1 16'hffff;
         ctr  <= #1  8'h0;
         txr  <= #1  8'h0;
            end
         else if (hresetn)
         begin
         prer <= #1 16'hffff;
         ctr  <= #1  8'h0;
         txr  <= #1  8'h0;
            end
         else */  
        if (hwrite == 0) //  ||  hready == 1 )        
          begin 
             case (haddr) // synopsys parallel_case
               3'b000 : begin
                  hrdata <= #1 prer [7:0];
                  
                  // prer [ 7:0] <= #1 hrdata;
                  // $display("hrdata written to prer when haddr =000, %h,%h",prer [7:0],haddr);
               end
               3'b001 : begin
                  hrdata <= #1 prer[15:8];
                  
                  // prer [15:8] <= #1 hrdata;
                  // $display("hrdata written to prer[15:8] when haddr = 001 ,%h",prer [15:8]);
               end
               3'b010 : begin 
                  hrdata <= #1 ctr;
                  
                  //ctr         <= #1 hrdata;
                  // $display("hrdata written to ctr when haddr = 010,%h",ctr);
               end
               3'b011 : begin
                  hrdata <= #1 txr;
                  // txr         <= #1 hrdata;
                  // $display("hrdata written to txr when haddr = 011 ,%h",txr);
               end
               default: ;
             endcase
          end 
     end // always @ (posedge hclk or negedge rst_i)
   
   // generate command register (special case)
   //   always @(posedge hclk or negedge rst_i)

   /* if (!rst_i)
    cr <= #1 8'h0;
    else */
   always @(posedge hclk or negedge rst_i) 
     begin 
        if (hresetn)
          cr <= #1 8'h0;
        else
          begin   
             if (hwrite == 1 ||  hready == 1)
               begin
                  if (core_en & (haddr == 3'b100) )
                    begin
                       cr <= #1 hrdata; 
                       // $display("value of hrdata when haddr = 100 & core_en = %b",cr); //displaing the data of command register or hrdata 
                    end
               end

             
             
             else
               begin
                  if (done | i2c_al)
                    cr[7:4] <= #1 4'h0;     // clear command bits when done
                  // or when aribitration lost
                  cr[2:1] <= #1 2'b0;             // reserved bits
                  cr[0]   <= #1 1'b0;             // clear IRQ_ACK bit
               end // else: !if(hwrite == 1 ||  hready == 1)
          end // else: !if(hresetn)
     end // always @ (posedge hclk or negedge rst_i)
   


   // decode command register
   assign    sta = cr[7];
   assign sto  = cr[6];
   assign  rd   = cr[5];
   assign  wr   = cr[4];
   assign ack  = cr[3];
   assign iack = cr[0];

   
   
   /* always @(sta or sto or rd or wr or ack or iack)
    
    begin
    $display(" sta=%b,sto=%b,rd=%b,wr=%b,ack=%b,iack=%b",sta,sto,rd,wr,ack,iack);
        end
    */
   // decode control register
   assign core_en = ctr[7];
   assign ien = ctr[6];
   
   
   // hookup byte controller block
   i2c_master_byte_ctl byte_controller (
                                        .clk      ( hclk         ),
                                        .rst      ( hresetn      ),
                                        .nReset   ( rst_i        ),
                                        .ena      ( core_en      ),
                                        .clk_cnt  ( prer         ),
                                        .start    ( sta          ),
                                        .stop     ( sto          ),
                                        .read     ( rd           ),
                                        .write    ( wr           ),
                                        .ack_in   ( ack          ),
                                        .din      ( txr          ), 
                                        .cmd_ack  ( done         ),
                                        .ack_out  ( irxack       ),
                                        .dout     ( rxr          ),
                                        .i2c_busy ( i2c_busy     ),
                                        .i2c_al   ( i2c_al       ),
                                        .scl_i    ( scl_pad_i    ),
                                        .scl_o    ( scl_pad_o    ),
                                        .scl_oen  ( scl_padoen_o ),
                                        .sda_i    ( sda_pad_i    ),
                                        .sda_o    ( sda_pad_o    ),
                                        .sda_oen  ( sda_padoen_o )                                       );
   
   // status register block + interrupt request signal
   always @(posedge hclk or negedge rst_i)
     begin
        if (!rst_i)
          begin
             al       <= #1 1'b0;
             rxack    <= #1 1'b0;
             tip      <= #1 1'b0;
             irq_flag <= #1 1'b0;
          end
        else if (hresetn)
          begin
             al       <= #1 1'b0;
             rxack    <= #1 1'b0;
             tip      <= #1 1'b0;
             irq_flag <= #1 1'b0;
          end
        else
          begin
             al       <= #1 i2c_al | (al & ~sta);
             rxack    <= #1 irxack;
             // $display("rxack=%d",rxack);
             if(rxack == 1'b1)
               begin
                  hresp = okay;
               end
             tip      <= #1 (rd | wr);
             //   $display("tip =%d",tip);
             irq_flag <= #1 (done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
             //  $display(" irq_flag = %d",irq_flag);
          end
     end // always @ (posedge hclk or negedge rst_i)
   
   always @ (sr) begin
      // assign status register bits
      sr[7]   <= rxack;
      sr[6]   <= i2c_busy;
      sr[5]   <= al;
      sr[4:2] <= 3'h0; // reserved
      sr[1]   <= tip;
      sr[0]   <= irq_flag;
   end
   always @(rxack,i2c_busy,al,tip,irq_flag,haddr)
     begin
        // $display(" Status register bits raxack,i2c_busy,al,tip,irq_flag= %b,%b,%b,%b,%b",rxack,i2c_busy,al,tip,irq_flag);
     end  
endmodule


`endif // _I2C_MASTER_TOP_V_

