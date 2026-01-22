//==============================================================================
// Project      : AMBA APB 3.0 Verification Environment
// File         : design.sv
// Author       : Anubhav Agarwal
// Description  : Synthesizable RTL for the APB Bridge/Slave DUT.
// Protocol     : AMBA APB v3.0
//==============================================================================
interface APB_intf #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32) (input clk);
  logic start_transfer;
  logic pwrite;
  logic [ADDR_WIDTH -1 :0] paddr;
  logic [DATA_WIDTH -1 :0] pwdata;
  logic [DATA_WIDTH -1 :0] prdata;
  logic transfer_done;
  logic rst;
endinterface

`include "apb_slave.sv"
`include "apb_master.sv"

module abp_top #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input PCLK,
  input PRESETn,
  //Controller Interface
  input start_transfer,
  input write_read_n,
  input [ADDR_WIDTH -1 :0] address,
  input [DATA_WIDTH -1 :0] write_data,
  output reg [DATA_WIDTH -1 :0] read_data,
  output reg transfer_done
);
//   APB_intf bus();
  wire [ADDR_WIDTH -1 :0] paddr;
  wire[DATA_WIDTH -1 :0] pwdata, prdata;
  wire psel, penable, pwrite, pready, pslverr;

  apb_master #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) inst_apb_master (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    //Controller Interface
    .start_transfer(start_transfer),
    .write_read_n(write_read_n),
    .address(address),
    .write_data(write_data),
    .read_data(read_data),
    .transfer_done(transfer_done),
    //APB Interface
    .PSEL(psel), 
    .PENABLE(penable),
    .PADDR(paddr),
    .PWDATA(pwdata),
    .PWRITE(pwrite),
    .PREADY(pready),
    .PSLVERR(pslverr),
    .PRDATA(prdata)
  );
  apb_slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) inst_apb_slave (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    //APB Interface
    .PSEL(psel), 
    .PENABLE(penable),
    .PADDR(paddr),
    .PWDATA(pwdata),
    .PWRITE(pwrite),
    .PREADY(pready),
    .PSLVERR(pslverr),
    .PRDATA(prdata)
  );
endmodule
