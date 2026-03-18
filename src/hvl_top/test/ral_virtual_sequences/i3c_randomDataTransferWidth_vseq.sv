`ifndef I3C_RANDOM_DATA_WIDTH_VSEQ_INCLUDED_
`define I3C_RANDOM_DATA_WIDTH_VSEQ_INCLUDED_

class i3c_randomDataTransferWidth_vseq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_randomDataTransferWidth_vseq)

  uvm_status_e status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t mirror_val;
  bit sdr_done;

  rand int data_len;
  constraint c_len { data_len inside {[1:128]}; }

  function new(string name="i3c_randomDataTransferWidth_vseq");
    super.new(name);
  endfunction

  task body();
    super.body();

    i3c_target_readOperationWithRandomDataTransferWidth_seq target_seq;

    if(!randomize())
      `uvm_fatal(get_type_name(),"Randomization failed")

    `uvm_info(get_type_name(),
      $sformatf("Random transfer width = %0d bytes", data_len),
      UVM_MEDIUM)

    // Start target sequence
    fork
      begin
        target_seq =
          i3c_target_readOperationWithRandomDataTransferWidth_seq::type_id::create("target_seq");
        target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;

    // Write random data to WDATAB
    repeat(data_len) begin
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, $urandom_range(0,255));

      rdata = i3c_env_cfg_h.regBlockHandle.wdatab_inst.get();
      mirror_val = i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.mirror(status, UVM_CHECK);
    end

    // Configure CTRL register
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0); // write
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(data_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    rdata = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();
    mirror_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);

    sdr_done = 0;
    while(!sdr_done) begin
      i3c_env_cfg_h.regBlockHandle.status_inst.read(status, rdata);
      sdr_done = rdata[0];
      @(posedge p_sequencer.vif.clk);
    end

    `uvm_info(get_type_name(),
      "Random data width transfer completed",
      UVM_MEDIUM)

  endtask

endclass

`endif
