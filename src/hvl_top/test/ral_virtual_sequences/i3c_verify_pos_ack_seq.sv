`ifndef I3C_VERIFY_POS_ACK_SEQ_INCLUDED_
`define I3C_VERIFY_POS_ACK_SEQ_INCLUDED_

class i3c_verify_pos_ack_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_verify_pos_ack_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t wdatab_mirror;
  bit sdr_done;

  function new(string name = "i3c_verify_pos_ack_seq");
    super.new(name);
  endfunction

  task body();
    super.body();

    i3c_target_writeOperationWith8bitsData_seq target_seq;

    `uvm_info(get_type_name(), "Starting Positive ACK verification", UVM_LOW)

    // Start target BFM sequence
    fork
      forever begin
        target_seq = i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq");
        target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;

    // WRITE data using handle from env config (DMA style)
    i3c_env_cfg_h.regBlockHandle.WDATAB_inst.write(
      status,
      8'hA5
    );

    wdatab_mirror = i3c_env_cfg_h.regBlockHandle.WDATAB_inst.get_mirrored_value();
    `uvm_info("WDATAB_DEBUG", $sformatf("WDATAB mirrored value = %0h", wdatab_mirror), UVM_LOW)

    // Configure CTRL register via handle
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.address.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.length.set(8'd1);
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.direction.set(1'b0); // WRITE
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.cmd_type.set(2'b00);  // SDR
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.CTRL_inst.update(status);
    i3c_env_cfg_h.regBlockHandle.CTRL_inst.mirror(status, UVM_CHECK);

    // Wait for SDR transaction to complete
    sdr_done = 0;
    while(!sdr_done) begin
      i3c_env_cfg_h.regBlockHandle.STATUS_inst.read(status, rdata);
      sdr_done = rdata[0]; // SDR_DONE
      #100;
    end

    // Positive ACK check
    if (sdr_done)
      `uvm_info(get_type_name(), "Positive ACK received from target", UVM_MEDIUM)
    else
      `uvm_error(get_type_name(), "No ACK received from target")

  endtask

endclass

`endif
