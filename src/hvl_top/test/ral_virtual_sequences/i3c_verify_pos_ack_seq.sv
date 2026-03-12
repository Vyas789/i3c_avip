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

    fork
      forever begin
        target_seq = i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq");
        target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;

    p_sequencer.regmodel.wdatab_inst.write(status, 8'hA5);

    wdatab_mirror = p_sequencer.regmodel.wdatab_inst.get_mirrored_value();
    `uvm_info("WDATAB_DEBUG", $sformatf("WDATAB mirrored value = %0h", wdatab_mirror), UVM_LOW)


    p_sequencer.regmodel.ctrl_inst.address.set(TARGET0_ADDRESS);
    p_sequencer.regmodel.ctrl_inst.length.set(8'd1);
    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); // WRITE
    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'b00);  // SDR
    p_sequencer.regmodel.ctrl_inst.start.set(1'b1);


    p_sequencer.regmodel.ctrl_inst.update(status);
    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK);

    sdr_done = 0;
    while(!sdr_done) begin
      p_sequencer.regmodel.status_inst.read(status, rdata);
      sdr_done = rdata[0]; 
      @(posedge p_sequencer.vif.clk);
    end

    if (sdr_done)
      `uvm_info(get_type_name(), "Positive ACK received from target", UVM_MEDIUM)
    else
      `uvm_error(get_type_name(), "No ACK received from target")

  endtask

endclass

`endif
