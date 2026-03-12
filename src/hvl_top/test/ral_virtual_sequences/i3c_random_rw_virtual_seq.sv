class i3c_random_rw_virtual_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_random_rw_virtual_seq) 

  

  uvm_status_e status; 

  uvm_reg_data_t rdata; 

  

  bit [7:0] data; 

  bit dir; 

  bit sdr_done; 

  

  function new(string name="i3c_random_rw_virtual_seq"); 

    super.new(name); 

  endfunction 

  

  

  task body(); 

  

    super.body(); 

  

    i3c_target_writeOperationWith8bitsData_seq target_wr_seq; 

    i3c_target_readOperationWith8bitsData_seq  target_rd_seq; 

  

    fork 

      forever begin 

        target_wr_seq = 

        i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_wr_seq"); 

  

        target_wr_seq.start(p_sequencer.i3c_target_seqr_h); 

      end 

  

      forever begin 

        target_rd_seq = 

        i3c_target_readOperationWith8bitsData_seq::type_id::create("target_rd_seq"); 

  

        target_rd_seq.start(p_sequencer.i3c_target_seqr_h); 

      end 

    join_none; 

  

  

    repeat(20) begin 

  

      dir  = $urandom_range(0,1); 

      data = $urandom_range(0,255); 

  

      if(dir == 0) begin 

  

        p_sequencer.regmodel.wdatab_inst.write(status, data); 

  

        p_sequencer.regmodel.ctrl_inst.address.set(7'h68); 

        p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

        p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); 

        p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd0); 

        p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

        p_sequencer.regmodel.ctrl_inst.update(status); 

  

      end 

  

      else begin 

  

        p_sequencer.regmodel.ctrl_inst.address.set(7'h68); 

        p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

        p_sequencer.regmodel.ctrl_inst.direction.set(1'b1); 

        p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd0); 

        p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

        p_sequencer.regmodel.ctrl_inst.update(status); 

  

      end 

  

  

      sdr_done = 0; 

  

      while(!sdr_done) begin 

        p_sequencer.regmodel.status_inst.read(status, rdata); 

        sdr_done = rdata[0]; 

        @(posedge p_sequencer.vif.clk); 

      end 

  

  

      if(dir == 1) begin 

        p_sequencer.regmodel.rdatab_inst.read(status, rdata); 

  

        `uvm_info("RANDOM_READ", 

          $sformatf("Random read data = %0h", rdata), 

          UVM_MEDIUM) 

      end 

  

    end 

  

  endtask 

  

endclass 
