`ifndef I3C_VERIFY_REPEATED_START_SEQ_INCLUDED_ 

`define I3C_VERIFY_REPEATED_START_SEQ_INCLUDED_ 

  

class i3c_verify_repeated_start_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_verify_repeated_start_seq) 

  

  uvm_status_e status; 

  uvm_reg_data_t rdata; 

  uvm_reg_data_t wdatab_mirror; 

  uvm_reg_data_t ctrl_mirror; 

  

  bit sdr_done; 

  

  function new(string name = "i3c_verify_repeated_start_seq"); 

    super.new(name); 

  endfunction 

  

  

  task body(); 

    super.body(); 

  

    i3c_target_writeOperationWithRepeatedStart_seq target_seq; 

  

    `uvm_info(get_type_name(), "Starting Repeated Start Verification", UVM_LOW) 

  

    fork 

      forever begin 

        target_seq = 

        i3c_target_writeOperationWithRepeatedStart_seq::type_id::create("target_seq"); 

        target_seq.start(p_sequencer.i3c_target_seqr_h); 

      end 

    join_none; 

  

  

    // WRITE 1 

    p_sequencer.regmodel.wdatab_inst.write(status, 8'hA5); 

    wdatab_mirror = 

    p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

  

    `uvm_info("WDATAB_DEBUG", 

    $sformatf("WDATAB mirror value = %0h", wdatab_mirror), UVM_LOW) 

    p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK); 

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(TARGET0_ADDRESS); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); 

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'b00); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    ctrl_mirror = 

    p_sequencer.regmodel.ctrl_inst.start.get(); 

  

    `uvm_info("CTRL_DEBUG", 

    $sformatf("CTRL start bit set to = %0d", ctrl_mirror), UVM_LOW) 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK); 

  

  

    sdr_done = 0; 

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0];  

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

  

    // REPEATED START + WRITE 2 

    p_sequencer.regmodel.wdatab_inst.write(status, 8'h3C); 

  

    wdatab_mirror = 

    p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

  

    `uvm_info("WDATAB_DEBUG", 

    $sformatf("WDATAB mirror value = %0h", wdatab_mirror), UVM_LOW) 

    p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

    ctrl_mirror = 

    p_sequencer.regmodel.ctrl_inst.start.get(); 

    `uvm_info("CTRL_DEBUG", 

    $sformatf("CTRL start bit for repeated start = %0d", ctrl_mirror), UVM_LOW) 

    p_sequencer.regmodel.ctrl_inst.update(status); 

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK); 

  

    sdr_done = 0; 

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    `uvm_info(get_type_name(), 

    "Repeated Start transfer completed successfully", UVM_MEDIUM) 

  

  endtask 

  

endclass 

  

`endif 
