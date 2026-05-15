//=================================================================================================
// Project      : AMBA APB Bridge Verification Environment
// File         : apb_assertion.sv
// Author       : Anubhav Agarwal
// Description  : SVA Property Module for AMBA APB Protocol Verification. Contains 14 assertions
//                organised into 4 blocks — Reset, State Invariants, State Transitions, and Data
//                Integrity. Bound to the DUT using a bind statement; RTL is never modified.
// Protocol     : AMBA APB v3.0
//=================================================================================================
module apb_assertion #(
  parameter ADDR_WIDTH = 32, 
  parameter DATA_WIDTH = 32
) ( 
  input pclk,
  input presetn,
  input [ADDR_WIDTH - 1 : 0] paddr,
  input [DATA_WIDTH - 1 : 0] pwdata,
  input [DATA_WIDTH - 1 : 0] prdata,
  input pwrite,
  input psel,
  input penable,
  input pready,
  input transfer_done,
  input pslverr
);
//==================== Reset Asertion ====================//
  // Ideal State at reset
  property reset_state;
    @(posedge pclk)
    (!presetn) |-> (psel == 0 && penable == 0);
  endproperty
  r_state: assert property(reset_state) 
    else $error("APB Violation: At reset c_satte should be ideal not followed");
    
  property reset_signal;
    @(posedge pclk)
    (!presetn) |-> (pwrite == 0 && paddr == 0 && pwdata == 0 && prdata == 0 );
  endproperty
  r_data: assert property(reset_signal) 
    else $error("APB Violation: At reset All signal values should be zero not followed");
    
  property reset_handshake;
    @(posedge pclk)
    !presetn |-> (pready == 0 && transfer_done == 0);
  endproperty
  r_handshake: assert property(reset_handshake)
    else $error("APB Violation: PREADY or transfer_done not zero during reset");
    
//========================================================//  
    
//=============== State Invariant assertion ==============//
    
  // SETUP state Invariant
  // Adress and Pwrite and Pwdata should have a valid value
  property setup_signal;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable) |-> (!$isunknown(paddr) && !$isunknown(pwrite));
  endproperty
  a_setup_valid: assert property(setup_signal)
    else $error ("APB Violation: PADDR or PWRITE is X during SETUP phase");
    
  property setup_wdata_valid;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable && pwrite) |-> (!$isunknown(pwdata));
  endproperty
  a_setup_wdata: assert property(setup_wdata_valid)
    else $error ("APB Violation: PWDATA is X during SETUP phase");  
    
  // ACCESS STATE Invariant
  // Paddr, pwdata, pwite should be stable 
  // Also prdata is has a valid value when preday is high and pwrite is low
    
  property access_signal;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable) |-> ($stable(pwrite) && $stable(paddr));
  endproperty
    a_acces_stable: assert property(access_signal)
      else $error("APB Violation: PADDR and PWRITE changed during ACCESS STATE");
  
  property access_wdata_stable;
  @(posedge pclk) disable iff (!presetn)
  (psel && penable && pwrite) |-> ($stable(pwdata));
endproperty
a_access_wdata: assert property(access_wdata_stable)
  else $error("APB Violation: PWDATA changed during ACCESS write phase");
      
  property access_read;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pready && !pwrite) |-> (!$isunknown(prdata));
  endproperty
      a_access_prdata: assert property(access_read)
        else $error("APB Violation: PRDATA value is not valid in ACCESS STATE");
//========================================================//


//=============== State Tranition assertion ==============//
        
  // IDLE To SETUP 
  property transition1;
    @(posedge pclk) disable iff (!presetn)
    ($rose(psel) |-> $past(!penable && !psel));
  endproperty
  a_IDEAL_to_SETUP: assert property(transition1)
    else $error ("APB Violation: PSEL rose but previous state was not IDLE");
    
  // SETUP To ACCESS
  property transition2;
    @(posedge pclk) disable iff (!presetn)
    ($rose(penable) |-> $past(!penable && psel));
  endproperty
  a_SETUPL_to_ACCESS: assert property(transition2)
    else $error ("APB Violation: PENABLE rose but previous state was not SETUP");
    
  // SETUP to ACCESS — data must remain stable across the transition
  property transition2_data_stable;
    @(posedge pclk) disable iff (!presetn)
    $rose(penable) |-> ($past(paddr) == paddr && 
                        $past(pwrite) == pwrite);
  endproperty
  a_setup_to_access_data: assert property (transition2_data_stable)
    else $error ("APB Violation: PADDR/PWRITE changed between SETUP and ACCESS");
    
  property transition2_wdata_stable;
    @(posedge pclk) disable iff (!presetn)
    ($rose(penable) && pwrite) |-> ($past(pwdata) == pwdata);
  endproperty
  a_setup_to_access_wdata: assert property(transition2_wdata_stable)
    else $error("APB Violation: PWDATA changed between SETUP and ACCESS on write");
   
  // ACCESS To IDEAL
  property transition3;
    @(posedge pclk) disable iff (!presetn)
    (penable && psel && pready) |=> (psel == 0 && penable == 0);
  endproperty
  a_ACCESS_to_IDEAL: assert property(transition3)
    else $error ("APB Violation: PSEL PENABLE and PREADY is high but next state was not IDLE");
//========================================================//
        
//================ data Integrity assertion ==============//

  // Write Integrity
  // transfer_done must rise cycle after ACCESS completes
  property transfer_done_rises;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pready) |=> $rose(transfer_done);
  endproperty
  a_tf_done_rises: assert property(transfer_done_rises)
    else $error("APB Violation: transfer_done did not rise after ACCESS completed");

// transfer_done must fall the very next cycle — one cycle pulse only
  property transfer_done_one_cycle;
    @(posedge pclk) disable iff (!presetn)
    $rose(transfer_done) |=> $fell(transfer_done);
  endproperty
  a_tf_done_pulse: assert property(transfer_done_one_cycle)
    else $error("APB Violation: transfer_done stayed high more than one cycle");
    
//transfer_done must never rise without ACCESS completing
  property transfer_done_requires_access;
    @(posedge pclk) disable iff (!presetn)
    $rose(transfer_done) |-> $past(psel && penable && pready);
  endproperty
  a_tf_needs_access: assert property(transfer_done_requires_access)
    else $error("APB Violation: transfer_done rose without ACCESS phase completing"); 
    
  // Error Response
  property error_response;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pready && pslverr) |=> $rose(transfer_done);
  endproperty
  a_err_res: assert property(error_response)
    else $error("APB Violation: transfer_done did not rise after error response");
//========================================================//
endmodule
