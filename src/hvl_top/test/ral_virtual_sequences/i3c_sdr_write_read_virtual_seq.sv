`ifndef I3C_SDR_WRITE_READ_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_WRITE_READ_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_write_read_virtual_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_sdr_write_read_virtual_seq)

  uvm_status_e status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;
  uvm_reg_data_t wdatab_mirror;
  uvm_reg_data_t rdata;

  bit sdr_done;

  function new(string name = "i3c_sdr_write_read_virtual_seq");
    super.new(name);
  endfunction


  task body();
    super.body();

    i3c_target_writeOperationWith8bitsData_seq target_write_seq;
    i3c_target_readOperationWith8bitsData_seq  target_read_seq;

    `uvm_info(get_type_name(),
    "Starting SDR WRITE followed by READ test",
    UVM_LOW)


    fork
      forever begin
        target_write_seq =
        i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_write_seq");
        target_write_seq.start(p_sequencer.i3c_target_seqr_h);
      end
      forever begin
        target_read_seq =
        i3c_target_readOperationWith8bitsData_seq::type_id::create("target_read_seq");
        target_read_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none


  // Write data
    p_sequencer.regmodel.wdatab_inst.write(status, 8'hA5);
    wdatab_mirror =
    p_sequencer.regmodel.wdatab_inst.get_mirrored_value();

    `uvm_info("WDATAB_DEBUG",
      $sformatf("WDATAB mirrored value = %0h", wdatab_mirror),
      UVM_LOW)

    p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK);


    p_sequencer.regmodel.ctrl_inst.address.set(TARGET0_ADDRESS);
    p_sequencer.regmodel.ctrl_inst.length.set(8'd1);
    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0);
    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'b00);
    p_sequencer.regmodel.ctrl_inst.start.set(1'b1);

    ctrl_val =
    p_sequencer.regmodel.ctrl_inst.get();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL value before update = %0h", ctrl_val),
      UVM_LOW)

    p_sequencer.regmodel.ctrl_inst.update(status);

    ctrl_mirror =
    p_sequencer.regmodel.ctrl_inst.get_mirrored_value();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored value after update = %0h", ctrl_mirror),
      UVM_LOW)

    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK);


    sdr_done = 0;

    while(!sdr_done) begin
      p_sequencer.regmodel.status_inst.read(status, rdata);
      sdr_done = rdata[0];
      @(posedge p_sequencer.vif.clk);
    end


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


    p_sequencer.regmodel.rdatab_inst.read(status, rdata);

    `uvm_info("READ_BACK",
      $sformatf("Data from RDATAB = %0h", rdata),
      UVM_MEDIUM)


    `uvm_info(get_type_name(),
    "SDR WRITE followed by READ completed",
    UVM_LOW)

  endtask

endclass

`endif
