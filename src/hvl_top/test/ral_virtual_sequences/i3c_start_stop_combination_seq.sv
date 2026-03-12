`ifndef I3C_START_STOP_COMBINATION_SEQ_INCLUDED_ 

`define I3C_START_STOP_COMBINATION_SEQ_INCLUDED_ 

  

class i3c_start_stop_combination_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_start_stop_combination_seq) 

  

  uvm_status_e status; 

  uvm_reg_data_t rdata; 

  uvm_reg_data_t wdatab_mirror; 

  bit sdr_done; 

  

  function new(string name="i3c_start_stop_combination_seq"); 

    super.new(name); 

  endfunction 

  

  

  task body(); 

    super.body(); 

  

    i3c_target_writeOperationWith8bitsData_seq target_seq; 

  

    fork 

      forever begin 

        target_seq = 

        i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq"); 

        target_seq.start(p_sequencer.i3c_target_seqr_h); 

      end 

    join_none; 

  

  

  

    // FIRST TRANSFER (START -> WRITE -> STOP) 

    p_sequencer.regmodel.wdatab_inst.write(status, 8'hA5); 

  

    wdatab_mirror = 

    p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

  

    p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK); 

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(TARGET0_ADDRESS); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); 

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'b00); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

  

    sdr_done = 0; 

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0];  

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    // SECOND TRANSFER (START -> WRITE -> STOP) 

    p_sequencer.regmodel.wdatab_inst.write(status, 8'h3C); 

  

    wdatab_mirror = 

    p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

  

    p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK); 

  

  

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

  

    sdr_done = 0; 

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    `uvm_info(get_type_name(), 

    "Start-Stop-Start-Stop transfers completed", UVM_MEDIUM) 

  

  endtask 

  

endclass 

  

`endif 
