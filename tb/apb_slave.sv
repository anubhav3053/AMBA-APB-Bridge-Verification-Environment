//=============================================================================================
// Project      : AMBA APB Bridge Verification Environment
// File         : apb_master.sv
// Author       : Anubhav Agarwal
// Description  : APB Slave BFM. Monitors the bus for requests and responds with PREADY/PRDATA. 
//                Simulates peripheral behavior including random wait-state insertion.
// Protocol     : AMBA APB v3.0
//============================================================================================
module apb_slave #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input PCLK,
  input PRESETn,
  //APB Interface
  input PSEL, 
  input PENABLE,
  input PWRITE,
  input [ADDR_WIDTH -1 : 0] PADDR,
  input [DATA_WIDTH -1 : 0] PWDATA,
  output PSLVERR,
  output reg PREADY,
  output reg [DATA_WIDTH -1 : 0] PRDATA
);

  integer i;
  integer j = 0;
  // Internal registers
  reg [DATA_WIDTH -1 :0] memory [0:15]; // 16 registers

  // Write Operation
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      for (i = 0; i < 16; i=i+1)
        memory[i] <= 32'h0;
    end
    else begin
      if(PSEL && PENABLE) begin
        PREADY <= 1'b1;
        if(PWRITE) begin
          memory[PADDR] <= PWDATA;
        end
        else begin
          PRDATA <= memory[PADDR];
        end
      end
      else begin
        PREADY <= 1'b0;
      end
    end
  end

  assign PSLVERR = 1'b0; // No error
endmodule
