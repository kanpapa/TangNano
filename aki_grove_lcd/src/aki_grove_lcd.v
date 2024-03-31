//===========================================================
// AKIZUKI Grove LCD Project
//-----------------------------------------------------------
// File Name   : FPGA.v
// Description : Top of the FPGA
//-----------------------------------------------------------
// History :
// Rev.01 2016.07.12 @kanpapa beta release
//-----------------------------------------------------------
// Copyright (C) 2016 @kanpapa
//===========================================================

`ifdef SIMULATION
    `define POR_MAX 16'h000f // period of power on reset 
`else  // Real FPGA
    `define POR_MAX 16'hffff  // period of power on reset 
`endif


//--------------------
// Top of the FPGA
//--------------------
module FPGA
(
    input  wire clk27,     // 27MHz Clock
    output reg [5:0] r,        // R 6bit
    output reg [5:0] g,        // G 6bit
    output reg [5:0] b,        // B 6bit  
    output reg hsync,      // HSYNC
    output reg vsync,      // YSYNC
    output wire clkout_o,       // CLK 6.75MHz
    output reg de,	   	// DE
    output wire stby,	   // STBY
    output wire rev	   	// REV   
);

//---------
// PLL
//---------
//PLL	PLL
//(
//    .inclk0 (clk48), // External Clock 48MHz
//    .c0     (clk)    // Internal Clock 6.75MHz
//);
    Gowin_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout 6.75MHz
        .clkin(clk27) //input clkin EXternal Clock 27MHz 
    );


//--------------------------
// Internal Power on Reset
//--------------------------
wire res_n;            // Internal Reset Signal
reg  por_n;            // should be power-up level = Low
reg  [15:0] por_count; // should be power-up level = Low

always @(posedge clk27)
begin
    if (por_count != `POR_MAX)
    begin
        por_n <= 1'b0;
        por_count <= por_count + 16'h0001;
    end
    else
    begin
        por_n <= 1'b1;
        por_count <= por_count;
    end
end

assign res_n = por_n;

// display parameter
//
// LCD H:588 V:196

`define H_PERIOD 429   // th
`define H_PWIDTH 11    // tw3H
`define H_BPORCH 42    // thb
`define H_DEWIDTH 320  // tw4H
`define H_DISPLAY 196  // thdp
`define H_DUMMYB 62    // tdumhb
`define H_DUMMYF 62    // tdumhf
 
`define V_PERIOD 262   // tv
`define V_PWIDTH 3     // tw2H
`define V_BPORCH 6     // tvb
`define V_DISPLAY 196  // tvdp
`define V_DUMMYB 22    // tdumvb
`define V_DUMMYF 22    // tdumvf

reg  [9:0]  pcnt;      // PULSE COUNTER
reg  [9:0]  hcnt;      // HSYNC COUNTER

//wire [15:0] addrb;
//wire [9:0] p_addr;
//wire [9:0] h_addr;

// CLK counter (0-428)
always @(posedge clkout_o, negedge res_n)
begin
	if (~res_n)
		pcnt <= 10'h0000;
	else if (pcnt == `H_PERIOD-1)    // 429CLK
		pcnt <= 10'h0000;
	else
		pcnt <= pcnt + 10'h0001;
end

// create HSYNC
always @(posedge clkout_o, negedge res_n)
begin
	if (~res_n)
		hsync <= 1'b1;
	else if (pcnt < `H_PWIDTH)
		hsync <= 1'b0;
	else
		hsync <= 1'b1;
end

// create DE
always @(posedge clkout_o, negedge res_n)
begin
	if (~res_n)
		de <= 1'b0;
	else if (hcnt < `V_BPORCH+1)
		de <= 1'b0;
	else if (pcnt < `H_BPORCH)
		de <= 1'b0;
	else if (pcnt < 362)  // H_BPORCH + H_DEWIDTH
		de <= 1'b1;
	else
		de <= 1'b0;
end


// HSYNC counter
always @(posedge hsync, negedge res_n)
begin
	if (~res_n)
		hcnt <= 10'h0000;
	else if (hcnt == `V_PERIOD-1)
		hcnt <= 10'h0000;            
	else
		hcnt <= hcnt + 10'h0001;
end

// create VSYNC
always @(posedge hsync)
begin
	if(hcnt < `V_PWIDTH)
		vsync <= 1'b0;
	else
		vsync <= 1'b1;
end


// etc.
assign stby = 1'b0;
assign rev = 1'b0;

// set display data
always @(posedge de, negedge res_n)
begin
	if (~res_n)
		begin
			r <= 6'b000000;
			g <= 6'b000000;
			b <= 6'b000000;
		end		
	else if(hcnt < 28)    // V_BPORCH 6 + DUMMY DATA 22
		begin
			r <= 6'b111111;
			g <= 6'b111111;
			b <= 6'b111111;
		end
	else if(hcnt < 70)    // RED
		begin
			r <= 6'b111111;
			g <= 6'b000000;
			b <= 6'b000000;
		end
	else if(hcnt < 100)    // ORANGE
		begin
			r <= 6'b111111;
			g <= 6'b100000;
			b <= 6'b000000;
		end
	else if (hcnt < 130)  // GREEN
		begin
			r <= 6'b000000;
			g <= 6'b111111;
			b <= 6'b000000;
		end
	else if (hcnt < 160)  // PURPLE
		begin
			r <= 6'b000000;
			g <= 6'b100000;
			b <= 6'b111111;
		end
	else if (hcnt < 224)  // BLUE
		begin
			r <= 6'b000000;
			g <= 6'b000000;
			b <= 6'b111111;
		end
	else
		begin				// DUMMY DATA 22
			r <= 6'b111111;
			g <= 6'b111111;
			b <= 6'b111111;
		end
end	

endmodule
//===========================================================