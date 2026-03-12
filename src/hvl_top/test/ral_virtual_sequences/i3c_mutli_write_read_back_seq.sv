class i3c_multi_write_read_back_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_multi_write_read_back_seq) 

  

  uvm_status_e status; 

  uvm_reg_data_t rdata; 

  uvm_reg_data_t mirror_val; 

  bit sdr_done; 

  

  bit [7:0] tx_data [3] = '{8'h11,8'h22,8'h33}; 

  bit [7:0] rx_data [3]; 

  

  function new(string name="i3c_multi_write_read_back_seq"); 

    super.new(name); 

  endfunction 

  

  

  task body(); 

  

    super.body(); 

  

    i3c_target_writeOperationWith8bitsData_seq multi_wr_target_seq; 

    i3c_target_readOperationWith8bitsData_seq  multi_rd_target_seq;   

    `uvm_info(get_type_name(), "Starting MULTI WRITE READ BACK test", UVM_LOW) 

  

  

    fork 

      forever begin 

        multi_wr_target_seq = 

        i3c_target_writeOperationWith8bitsData_seq::type_id::create("multi_wr_target_seq"); 

  

        multi_wr_target_seq.start(p_sequencer.i3c_target_seqr_h); 

      end    

    forever begin 

        multi_rd_target_seq= 

        i3c_target_readOperationWith8bitsData_seq::type_id::create("multi_rd_target_seq"); 

        multi_rd_target_seq.start(p_sequencer.i3c_target_seqr_h); 

      end                                                                                                      

    join_none; 

  

//write 

    foreach(tx_data[i]) begin 

      p_sequencer.regmodel.wdatab_inst.write(status, tx_data[i]); 

  

      mirror_val = p_sequencer.regmodel.wdatab_inst.get_mirrored_value(); 

      `uvm_info("WDATAB_DEBUG", 

        $sformatf("Mirror after write[%0d] = %0h",i,mirror_val), 

        UVM_LOW) 

    end 

  

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(7'h68); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd3); 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); 

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd0); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK); 

  

  

    sdr_done = 0; 

  

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

    p_sequencer.regmodel.status_inst.mirror(status, UVM_CHECK); 

  

  

//read 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b1); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK); 

  

  

    sdr_done = 0; 

  

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

  

    foreach(rx_data[i]) begin 

      p_sequencer.regmodel.rdatab_inst.read(status, rdata); 

      rx_data[i] = rdata; 

  

      p_sequencer.regmodel.rdatab_inst.mirror(status, UVM_NO_CHECK); 

    end 

  

  

    foreach(tx_data[i]) begin 

      if(rx_data[i] == tx_data[i]) 

        `uvm_info("MULTI_RW", 

          $sformatf("Match index %0d data %0h",i,rx_data[i]), 

          UVM_MEDIUM) 

      else 

        `uvm_error("MULTI_RW", 

          $sformatf("Mismatch index %0d expected %0h got %0h", 

          i,tx_data[i],rx_data[i])) 

    end 

  

  endtask 

  

endclass 
