//==============================================================================
// Project      : AMBA APB 3.0 Verification Environment
// File         : apb_master.sv
// Author       : Anubhav Agarwal
// Description  : Implements the APB Master BFM (Bus Functional Model) to generate PSEL, PENABLE, and PWRITE signals.
// Protocol     : AMBA APB v3.0
//==============================================================================
module apb_master #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input PCLK,
  input PRESETn,
  // Contol Interface
  input start_transfer,
  input write_read_n,
  input [ADDR_WIDTH -1 :0] address,
  input [DATA_WIDTH -1 :0] write_data,
  output reg [DATA_WIDTH -1 :0] read_data,
  output reg transfer_done,

  //APB Interface
  output reg PSEL, 
  output reg PENABLE,
  output reg [ADDR_WIDTH -1 :0] PADDR,
  output reg [DATA_WIDTH -1 :0] PWDATA,
  output reg PWRITE,
  input  PREADY,
  input  PSLVERR,
  input  [DATA_WIDTH -1 :0] PRDATA
);

  // States defined parameters
  parameter IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b10;

  //State Variables
  reg [1:0] c_state;
  reg [1:0] n_state;
  reg transfer_complete;

  // Current State Logic - Sequential Circuit
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin// !reset_n
      c_state <= IDLE;
      PSEL <= 0;
      PENABLE <= 0;
      PWRITE <= 0;
      PADDR <= 0;
      PWDATA <= 0;
      read_data <= 0;
      transfer_done <= 0;
      transfer_complete <= 0;
    end
    else begin
      c_state <= n_state;

      // Capture read data when PREADY is asserted
      if (PREADY && !PWRITE && c_state == ACCESS) begin
        read_data <= PRDATA;
      end

      // Generate single-cycle transfer_done pulse
      if(transfer_complete) begin
        transfer_done <= 1;
        transfer_complete <= 0;
      end
      else begin
        transfer_done <= 0;
      end
    end
  end

  // Next State Logic - Combinational Circuit
  always @(*) begin
    //n_state = c_state;
    transfer_complete = 0;
    case (c_state)
      IDLE: begin
        if (start_transfer)
          n_state = SETUP;
      end
      SETUP: begin
        n_state = ACCESS;
      end
      ACCESS: begin
        if (PREADY) begin
          n_state = IDLE;
          transfer_complete = 1'b 1;
        end
      end
      default: n_state = IDLE;
    endcase
  end

  // Output Logic - Combinational + Sequential Circuit
  always @(*) begin
    case(c_state)
      IDLE: begin
        PSEL = 0;
        PENABLE = 0;
        PWRITE = write_read_n;
        PADDR = address;
        PWDATA = write_data;
      end
      SETUP: begin
        PSEL = 1;
        PENABLE = 0;
        PWRITE = write_read_n;
        PADDR = address;
        PWDATA = write_data;
      end
      ACCESS: begin
        PSEL = 1;
        PENABLE = 1;
        PWRITE = write_read_n;
        PADDR = address;
        PWDATA = write_data;
      end
    endcase
  end
endmodule
