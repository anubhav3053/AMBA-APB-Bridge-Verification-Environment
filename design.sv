class packet#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32);
  bit start_transfer;
  rand bit pwrite;
  rand bit [ADDR_WIDTH -1 :0] paddr;
  rand bit [DATA_WIDTH -1 :0] pwdata;
  bit [DATA_WIDTH -1 :0] prdata;
  bit transfer_done;
  bit rst;
  int seq_num;
endclass

class generator;
  packet gen_pkt;
  mailbox gen_mbx;
  event write_done;
  event read_done;
  bit wait_for_write = 0;
  bit wait_for_read = 0;
  int i;
  int last_addr;

  function new(mailbox mbx);
    this.gen_mbx = mbx;
  endfunction

  task write_done_event();
    -> write_done;
  endtask

  task read_done_event();
    -> read_done;
  endtask

  task run();
    gen_pkt = new();
    // Generate WRITE packet
    repeat(16) begin
      void'(gen_pkt.randomize() with {
        pwrite == 1; 
        paddr == i;
        pwdata == i * 10 + 5;
      });
      gen_pkt.start_transfer = 1'b1;
      last_addr = gen_pkt.paddr;
      gen_pkt.seq_num = i * 2;

      // Put write packet in the mailbox
      gen_mbx.put(gen_pkt);
      $display($time, " | [Generator] Put Write Packet in Mailbox : addr = %0h, data = %0h, seq = %0d", gen_pkt.paddr, gen_pkt.pwdata, gen_pkt.seq_num);

      // Wait for write to complete
      @(write_done);
      $display($time, " | [Generator] Write completed for addr = %0h", gen_pkt.paddr);

      // Small delay between write and read
      #10;

      // Generate READ packet to the same address
      void'(gen_pkt.randomize() with {
        pwrite == 0; 
        paddr == last_addr;
      });
      gen_pkt.start_transfer = 1'b1;
      gen_pkt.seq_num = i * 2 + 1;

      // Put write packet in the mailbox
      gen_mbx.put(gen_pkt);
      $display($time, " | [Generator] Put Read Packet in Mailbox : addr = %0h, seq = %0d", gen_pkt.paddr, gen_pkt.seq_num);

      // Wait for write to complete
      @(read_done);
      $display($time, " | [Generator] Read completed for addr = %0h", gen_pkt.paddr);

      // Increment address for next iteration
      i = i + 1;
    end
    $display($time, " | [Generator] All 16 Write-Read operations completed.");
  endtask
endclass

class driver;
  packet drv_pkt;
  generator gen_ref;
  mailbox drv_mbx;
  semaphore drv_done;
  virtual APB_intf drv_bus;

  function new(mailbox mbx, virtual APB_intf bus, semaphore sem);
    this.drv_mbx = mbx;
    this.drv_bus = bus;
    this.drv_done = sem;
  endfunction

  function void set_gen_ref(generator g_ref);
    this.gen_ref = g_ref;
  endfunction

  task reset();
    drv_bus.start_transfer = 0;
    drv_bus.rst = 1;
    @(posedge drv_bus.clk);
    drv_bus.rst = 0;
    @(posedge drv_bus.clk);
    drv_bus.rst = 1;
  endtask

  task write(packet pkt);
    drv_bus.start_transfer =  1;
    drv_bus.pwrite         =  pkt.pwrite;
    drv_bus.paddr          =  pkt.paddr;
    drv_bus.pwdata         =  pkt.pwdata;
    $display($time, " | [Driver] WRITE completed: addr=%0h, data=%0h", 
             pkt.paddr, pkt.pwdata);
    wait(drv_bus.transfer_done);
    // Notify generator that write is done
    if(gen_ref != null)
      gen_ref.write_done_event();
    $display($time, " | [Driver] Write transfer successfully done");
    #10;
  endtask

  task read(packet pkt);
    drv_bus.start_transfer =  1;
    drv_bus.pwrite         =  pkt.pwrite;
    drv_bus.paddr          =  pkt.paddr;
    $display($time, " | [Driver] READ completed: addr=%0h", 
             pkt.paddr);
    wait(drv_bus.transfer_done);
    // Notify generator that read is done
    if(gen_ref != null)
      gen_ref.read_done_event();
    #10;
    $display($time, " | [Driver] Read transfer successfully done");
  endtask

  task run();
    drv_pkt = new();
    reset();
    repeat(32) begin
      drv_mbx.get(drv_pkt);
      $display($time, " | [Driver] Got packet: %s addr=%0h seq=%0d", 
               drv_pkt.pwrite ? "WRITE" : "READ", 
               drv_pkt.paddr, drv_pkt.seq_num);
      if(drv_pkt.pwrite == 1) begin
        write(drv_pkt);
      end
      else begin
        read(drv_pkt);
      end
      #5;
    end
    $display($time, " | [Driver] All transactions completed");
  endtask
endclass

class monitor;
  packet mon_pkt;
  semaphore drv_done;
  mailbox mon_mbx;
  virtual APB_intf mon_bus;
  function new(virtual APB_intf bus, semaphore smr, mailbox mbx);
    this.mon_bus = bus;
    this.drv_done = smr;
    this.mon_mbx = mbx;
  endfunction
  task run();
    forever begin
      //       repeat(3) begin
      @(posedge mon_bus.clk);
      mon_pkt = new();
      mon_pkt.start_transfer  = mon_bus.start_transfer;
      mon_pkt.pwrite          = mon_bus.pwrite;
      mon_pkt.paddr           = mon_bus.paddr;
      mon_pkt.pwdata          = mon_bus.pwdata;
      mon_pkt.prdata          = mon_bus.prdata;
      mon_pkt.transfer_done   = mon_bus.transfer_done;
      mon_pkt.rst             = mon_bus.rst;
      mon_mbx.put(mon_pkt);
      $display($time, " | [Monitor] %s transaction: addr=%0h, %s=%0h",
               mon_pkt.pwrite ? "WRITE" : "READ",
               mon_pkt.paddr,
               mon_pkt.pwrite ? "wdata" : "rdata",
               mon_pkt.pwrite ? mon_pkt.pwdata : mon_pkt.prdata);
    end
  endtask
endclass

class scoreboard;
  packet scr_pkt;
  mailbox scb_mbx;
  logic [31:0] ref_mem [0:15];
  int reg_addr;
  int prev_data;
  int i;
  function new(mailbox mbx);
    scb_mbx = mbx;
    for (i = 0; i < 16; i++)
      ref_mem[i] = 32'h0;
  endfunction
  task run();
    forever begin
      scb_mbx.get(scr_pkt);
      if (scr_pkt.transfer_done == 1) begin
        $display ($time, "-----------------------------------------");
        if (scr_pkt.pwrite == 1) begin
          prev_data = scr_pkt.pwdata;
          ref_mem[scr_pkt.paddr] = scr_pkt.pwdata; 
          $display($time, " | [Write] Data to the slave : %0h", scr_pkt.pwdata);
        end
        else 
          if (scr_pkt.prdata == prev_data)
            $display($time, " | [READ] Data sent by the slave : %0h", scr_pkt.prdata);
        $display ($time, "-----------------------------------------");
      end
    end
  endtask
endclass

module tb_apb_top;
  bit PCLK, PRESETn;
  mailbox gen2drv;  
  mailbox mon2scb;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;
  semaphore drv_done;

  APB_intf bus(PCLK);

  abp_top #(
    .ADDR_WIDTH(bus.ADDR_WIDTH),
    .DATA_WIDTH(bus.DATA_WIDTH)
  ) inst_apb_top (
    .PCLK(PCLK),
    .PRESETn(bus.rst),
    .start_transfer(bus.start_transfer),
    .write_read_n(bus.pwrite),
    .address(bus.paddr),
    .write_data(bus.pwdata),
    .read_data(bus.prdata),
    .transfer_done(bus.transfer_done)
  );

  always #5 PCLK = ~PCLK;
  //   initial #30 PRESETn = 1'b1;

  initial begin
    gen2drv = new();
    mon2scb = new();
    drv_done = new();
    gen = new(gen2drv);
    drv = new(gen2drv, bus, drv_done);
    mon = new(bus, drv_done, mon2scb);
    scb = new(mon2scb);
    drv.set_gen_ref(gen);
    //     #5;
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
      #2000 $finish;
    join
    //     #500 $finish;
  end
  initial begin
    $dumpfile("Apb.vcd");
    $dumpvars();
  end
endmodule