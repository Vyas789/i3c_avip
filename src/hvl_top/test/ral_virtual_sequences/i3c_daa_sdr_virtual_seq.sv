class i3c_daa_sdr_virtual_seq extends top_virtual_base_seq; 

  

  `uvm_object_utils(i3c_daa_sdr_virtual_seq) 

  

  uvm_status_e    status; 

  uvm_reg_data_t  rdata; 

  

  bit [6:0] dyn_addr; 

  bit daa_done; 

  bit sdr_done; 

  

  bit [7:0] write_data = 8'h55; 

  bit [7:0] read_data; 

  

  function new(string name="i3c_daa_sdr_virtual_seq"); 

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

  

  

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd2); 

    p_sequencer.regmodel.ctrl_inst.ccc.set(`CCC_ENTDAA); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

  

    daa_done = 0; 

  

    while(!daa_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      daa_done = rdata[1]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    p_sequencer.regmodel.dynaddr_inst.read(status, rdata); 

    dyn_addr = rdata[6:0]; 

  

    if(dyn_addr != 0) 

      `uvm_info("DAA_CHECK", 

        $sformatf("Dynamic address assigned = %0h", dyn_addr), 

        UVM_MEDIUM) 

    else 

      `uvm_error("DAA_CHECK","Dynamic address assignment failed") 

  

  

    p_sequencer.regmodel.wdatab_inst.write(status, write_data); 

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(dyn_addr); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

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

  

  

    p_sequencer.regmodel.ctrl_inst.address.set(dyn_addr); 

    p_sequencer.regmodel.ctrl_inst.length.set(8'd1); 

    p_sequencer.regmodel.ctrl_inst.direction.set(1'b1); 

    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'd0); 

    p_sequencer.regmodel.ctrl_inst.start.set(1'b1); 

  

    p_sequencer.regmodel.ctrl_inst.update(status); 

  

  

    sdr_done = 0; 

  

    while(!sdr_done) begin 

      p_sequencer.regmodel.status_inst.read(status, rdata); 

      sdr_done = rdata[0]; 

      @(posedge p_sequencer.vif.clk); 

    end 

  

  

    p_sequencer.regmodel.rdatab_inst.read(status, rdata); 

    read_data = rdata; 

  

  

    if(read_data == write_data) 

      `uvm_info("SDR_DATA_CHECK", 

        $sformatf("PASS: write %0h read %0h",write_data,read_data), 

        UVM_MEDIUM) 

    else 

      `uvm_error("SDR_DATA_CHECK", 

        $sformatf("FAIL: write %0h read %0h",write_data,read_data)) 

  

  endtask 

  

endclass 
