`ifndef I3C_SDR_READ_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_READ_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_read_virtual_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_sdr_read_virtual_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t rdata_get;
  uvm_reg_data_t rdata_mirror;

  bit busy;
  bit done;

  function new(string name = "i3c_sdr_read_virtual_seq");
    super.new(name);
  endfunction


  task body();
    super.body();

    i3c_target_readOperationWith8bitsData_seq target_seq_read;

    `uvm_info(get_type_name(), "Starting SDR READ test", UVM_LOW)


    // Start target sequence
    fork
      begin
        target_seq_read = i3c_target_readOperationWith8bitsData_seq::type_id::create("target_seq_read");
        target_seq_read.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;



    // Configure CTRL register
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b1); // READ
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00); // SDR
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    if(status != UVM_IS_OK)
      `uvm_error("RAL","CTRL register write failed")

    `uvm_info(get_type_name(), "SDR READ command issued", UVM_LOW)


    do begin
      i3c_env_cfg_h.regBlockHandle.status_inst.read(status, rdata);
      busy = rdata[2]; // SDR_BUSY
      #100ns;
    end while(busy);


    // Status checks
    done = rdata[0];

    if(!done)
      `uvm_error("SDR_READ","SDR transaction did not complete")

    if(rdata[4])
      `uvm_error("SDR_READ","SDR_ERROR detected")

    if(rdata[6])
      `uvm_error("SDR_READ","NAK received from target")


    // Read RDATAB
    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata);

    if(status != UVM_IS_OK)
      `uvm_error("RAL","RDATAB read failed")


    rdata_get    = i3c_env_cfg_h.regBlockHandle.rdatab_inst.get();
    rdata_mirror = i3c_env_cfg_h.regBlockHandle.rdatab_inst.get_mirrored_value();

    `uvm_info("RDATAB_DEBUG",
      $sformatf("RDATAB read value (DUT)   = %0h", rdata),
      UVM_LOW)

    `uvm_info("RDATAB_DEBUG",
      $sformatf("RDATAB get() value (RAL)  = %0h", rdata_get),
      UVM_LOW)

    `uvm_info("RDATAB_DEBUG",
      $sformatf("RDATAB mirror value (RAL) = %0h", rdata_mirror),
      UVM_LOW)


    `uvm_info(get_type_name(), "SDR READ completed successfully", UVM_LOW)

  endtask

endclass

`endif
