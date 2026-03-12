`ifndef TOP_VIRTUAL_BASE_SEQ_INCLUDED_
`define TOP_VIRTUAL_BASE_SEQ_INCLUDED_

class top_virtual_base_seq extends uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(top_virtual_base_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata;
  bit sdr_done;

  function new(string name = "top_virtual_base_seq");
    super.new(name);
  endfunction

endclass

`endif
