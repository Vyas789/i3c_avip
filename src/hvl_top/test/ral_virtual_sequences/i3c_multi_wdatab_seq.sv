 

class i3c_multi_wdatab_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_multi_wdatab_seq) 

  

  uvm_status_e status; 

  uvm_reg_data_t rdata; 

  uvm_reg_data_t mirror_val; 

  

  bit sdr_done; 

  

  function new(string name="i3c_multi_wdatab_seq"); 

    super.new(name); 

  endfunction 

  

  

  task body(); 

  

    super.body(); 

  

    i3c_target_writeOperationWith8bitsData_seq multiple_wdatab_write_seq; 

  

    `uvm_info(get_type_name(), "Starting MULTI WDATAB WRITE test", UVM_LOW) 

  

    fork 

      forever begin 

        multiple_wdatab_write_seq = 

          i3c_target_writeOperationWith8bitsData_seq::type_id::create("multiple_wdatab_write_seq"); 

  

        multiple_wdatab_write_seq.start(p_sequencer.i3c_target_seqr_h); 

      end 

    join_none; 

  

 

    p_sequencer.regmodel.wdatab_inst.write(status, 8'h11); 

    mirror_val = p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

    `uvm_info("WDATAB_DEBUG",$sformatf("Mirror after write1 = %0h",mirror_val),UVM_LOW) 

  

    p_sequencer.regmodel.wdatab_inst.write(status, 8'h22); 

    mirror_val = p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

    `uvm_info("WDATAB_DEBUG",$sformatf("Mirror after write2 = %0h",mirror_val),UVM_LOW) 

  

    p_sequencer.regmodel.wdatab_inst.write(status, 8'h33); 

    mirror_val = p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

    `uvm_info("WDATAB_DEBUG",$sformatf("Mirror after write3 = %0h",mirror_val),UVM_LOW) 

  

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(7'h68); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd3); 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0);  

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd0);  

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

  

    sdr_done = 0; 

  

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK); 

  

    `uvm_info(get_type_name(),"3-byte FIFO write completed",UVM_MEDIUM) 

  

  endtask 

  

endclass 
