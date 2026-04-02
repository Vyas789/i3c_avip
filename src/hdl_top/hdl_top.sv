/*
`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

import i3c_globals_pkg::*;
// Description : hdl top has a interface and controller and target agent bfm
module hdl_top;
 bit clk;
 bit rst;

 wire I3C_SCL;
 wire I3C_SDA;

 initial begin
   $display("HDL TOP");
 end

 initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
 end

 //-------------------------------------------------------
 // System Reset Generation
 // Active low reset
 //-------------------------------------------------------
 initial begin
   rst = 1'b1;

   repeat (2) begin
     @(posedge clk);
   end
   rst = 1'b0;

   repeat (2) begin
     @(posedge clk);
   end
   rst = 1'b1;
 end

 // Variable : intf_controller
 // I3C Interface Instantiation
 i3c_if intf_controller(.pclk(clk),
                    .areset(rst),
                    .SCL(I3C_SCL),
                    .SDA(I3C_SDA));

 // Variable : intf_target
 // I3C Interface Instantiation
 i3c_if intf_target(.pclk(clk),
                   .areset(rst),
                   .SCL(I3C_SCL),
                   .SDA(I3C_SDA));

 // MSHA: // Implementing week0 and week1 concept
 // MSHA: // Logic for Pull-up registers using opne-drain concept
 // MSHA: assign (weak0,weak1) SCL = 1'b1;
 // MSHA: assign (weak0,weak1) SDA = 1'b1;

  // Below table shows different values for each strength .
  //
  // Strength    Value     Value displayed by display tasks
  //   supply       7         Su
  //   strong       6         St
  //   pull         5         Pu
  //   large        4         La
  //   weak         3         We
  //   medium       2         Me
  //   small        1         Sm
  //   highz        0         HiZ

  //  To display strength of a signal %v is used with the signal name
  //  assign (weak1, weak0) io_dq = (direction) ? io : 1'bz;
  //  ex: $display("%v",io_dq);
    
 // Pullup for I3C interface
 pullup p1 (I3C_SCL);
 pullup p2 (I3C_SDA);

 // Variable : controller_agent_bfm_h
 // I3C controller BFM Agent Instantiation 
 //i3c_controller_agent_bfm i3c_controller_agent_bfm_h(intf_controller); 

 // TODO(mshariff): 
 // The interface should have SDA and SCL along with
 // (sda_o, sda_oe and sda_i) 
 // (scl_o, scl_oe and scl_i) 
 // But no clock and reset
 //
 // The clock and reset should be given to the agent_bfm block

 
 // Variable : target_agent_bfm_h
 // I3C target BFM Agent Instantiation
 //i3c_target_agent_bfm i3c_target_agent_bfm_h(intf_target);

  genvar i;
  generate
    for (i=0; i<NO_OF_CONTROLLERS; i++) begin : i3c_controller_agent_bfm
      i3c_controller_agent_bfm i3c_controller_agent_bfm_h(intf_controller); 
    end
    for (i=0; i<NO_OF_TARGETS; i++) begin : i3c_target_agent_bfm
      i3c_target_agent_bfm i3c_target_agent_bfm_h(intf_target);
    end
  endgenerate

 initial begin
   $dumpfile("i3c_avip.vcd");
   $dumpvars();
 end

endmodule : hdl_top

`endif

*/


`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

import i3c_globals_pkg::*;
import apb_global_pkg::*;

module hdl_top;

bit clk;
bit rst;

wire I3C_SCL;
wire I3C_SDA;

//---------------------------------
// APB clock/reset
//---------------------------------
wire pclk;
wire preset_n;

assign pclk     = clk;
assign preset_n = rst;

//---------------------------------
// DUT CPU interface signals
//---------------------------------
logic        wr_en;
logic        rd_en;
logic [6:0]  addrs;
logic [31:0] w_reg_data;
logic [7:0]  w_data;

logic [31:0] rd_data;
logic [7:0]  r_data;

logic scl_o;
logic sda_o;
logic sda_oe;

initial begin
$display("HDL TOP");
end

//---------------------------------
// Clock generation
//---------------------------------
initial begin
clk = 1'b0;
forever #10 clk = ~clk;
end

//---------------------------------
// Reset generation
//---------------------------------
initial begin
rst = 1'b1;

repeat (2) @(posedge clk);
rst = 1'b0;

repeat (2) @(posedge clk);
rst = 1'b1;
end

//---------------------------------
// APB interface
//---------------------------------
apb_if apb_intf(.pclk(pclk), .preset_n(preset_n));




//---------------------------------
// I3C Target Interface
//---------------------------------
i3c_if intf_target(
.pclk(clk),
.areset(rst),
.SCL(I3C_SCL),
.SDA(I3C_SDA)
);

//---------------------------------
// Pullups for I3C bus
//---------------------------------
pullup p1 (I3C_SCL);
pullup p2 (I3C_SDA);

//---------------------------------
// APB -> DUT wrapper
//---------------------------------
apb_i3c_wrapper wrapper(
.apb(apb_intf),

.wr_en(wr_en),
.rd_en(rd_en),
.addrs(addrs),
.w_reg_data(w_reg_data),
.w_data(w_data),

.rd_data(rd_data),
.r_data(r_data)
);

//---------------------------------
// DUT (I3C MASTER)
//---------------------------------
I3C_TOP dut(
.clk(clk),
.rst_n(rst),

.wr_en(wr_en),
.rd_en(rd_en),
.addrs(addrs),
.w_reg_data(w_reg_data),
.w_data(w_data),

.rd_data(rd_data),
.r_data(r_data),

.scl_i(I3C_SCL),
.scl_o(scl_o),

.sda_i(I3C_SDA),
.sda_o(sda_o),
.sda_oe(sda_oe)
);

//---------------------------------
// I3C bus connection (open drain)
//---------------------------------
assign I3C_SDA = sda_oe ? sda_o : 1'bz;
assign I3C_SCL = scl_o;

//added apb_master agent bfm
apb_master_agent_bfm apb_master_agent_bfm_h(apb_intf);
i3c_controller_agent_bfm i3c_controller_agent_bfm_h(intf_target);

//---------------------------------
// Target AVIP
//---------------------------------
genvar i;
generate
for (i=0; i<NO_OF_TARGETS; i++) begin : i3c_target_agent_bfm
i3c_target_agent_bfm i3c_target_agent_bfm_h(intf_target);
end
endgenerate

//---------------------------------
// Dump waves
//---------------------------------
initial begin
$dumpfile("i3c_avip.vcd");
$dumpvars();
end

endmodule : hdl_top

`endif

