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


    fork
      begin
        target_seq =
        i3c_target_readOperationWithRandomDataTransferWidth_seq::type_id::create("target_seq");

        target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;



    repeat(data_len) begin
      p_sequencer.regmodel.wdatab_inst.write(status, $urandom_range(0,255));

      rdata = p_sequencer.regmodel.wdatab_inst.get();
      mirror_val = p_sequencer.regmodel.wdatab_inst.get_mirrored_value();
      p_sequencer.regmodel.wdatab_inst.mirror(status, UVM_CHECK);

    end


    p_sequencer.regmodel.ctrl_inst.address.set(TARGET0_ADDRESS);
    p_sequencer.regmodel.ctrl_inst.direction.set(1'b0); // write
    p_sequencer.regmodel.ctrl_inst.length.set(data_len);
    p_sequencer.regmodel.ctrl_inst.cmd_type.set(2'b00);
    p_sequencer.regmodel.ctrl_inst.start.set(1'b1);
    p_sequencer.regmodel.ctrl_inst.update(status);

    rdata = p_sequencer.regmodel.ctrl_inst.get();
    mirror_val = p_sequencer.regmodel.ctrl_inst.get_mirrored_value();
    p_sequencer.regmodel.ctrl_inst.mirror(status, UVM_CHECK);

    sdr_done = 0;

    while(!sdr_done) begin
      p_sequencer.regmodel.status_inst.read(status, rdata);
      sdr_done = rdata[0];
      @(posedge p_sequencer.vif.clk);
    end


    `uvm_info(get_type_name(),
      "Random data width transfer completed",
      UVM_MEDIUM)

  endtask

endclass

`endif
 
