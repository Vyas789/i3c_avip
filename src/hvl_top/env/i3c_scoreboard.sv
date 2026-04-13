`ifndef I3C_SCOREBOARD_INCLUDED_
`define I3C_SCOREBOARD_INCLUDED_

class i3c_scoreboard extends uvm_component;
  `uvm_component_utils(i3c_scoreboard)

  // Analysis FIFOs
  uvm_tlm_analysis_fifo #(apb_master_tx)  apb_analysis_fifo;
  uvm_tlm_analysis_fifo #(i3c_target_tx)  target_analysis_fifo;

  // Config
  i3c_env_config i3c_env_cfg_h;

  // Counters
  int apb_tx_count;
  int target_tx_count;
  int write_pass;
  int write_fail;
  int read_pass;
  int read_fail;

  // Decoded expected values from CTRL register
  bit [6:0]  exp_address;
  bit [7:0]  exp_length;
  bit        exp_direction;   // 0=WRITE 1=READ
  bit [1:0]  exp_cmd_type;
  bit [7:0]  exp_ccc;

  // Accumulated write data bytes from WDATAB writes
  bit [7:0]  exp_write_data[$];

  extern function new(string name = "i3c_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task          run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);

  extern protected task collect_apb_transaction();
  extern protected task compare_with_target();
  extern protected function void decode_ctrl(bit [31:0] ctrl_val);

endclass : i3c_scoreboard


function i3c_scoreboard::new(string name = "i3c_scoreboard",
                              uvm_component parent = null);
  super.new(name, parent);
endfunction


function void i3c_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  apb_analysis_fifo    = new("apb_analysis_fifo",    this);
  target_analysis_fifo = new("target_analysis_fifo", this);

  if (!uvm_config_db #(i3c_env_config)::get(this, "", "i3c_env_config", i3c_env_cfg_h))
    `uvm_fatal("SB_CFG", "Cannot get i3c_env_config from config_db")
endfunction


task i3c_scoreboard::run_phase(uvm_phase phase);
  super.run_phase(phase);
  forever begin
    collect_apb_transaction();
    compare_with_target();
  end
endtask

/*
// collect_apb_transaction
// Waits for CTRL write with start=1, then collects N WDATAB writes for WRITE mode
task i3c_scoreboard::collect_apb_transaction();
  apb_master_tx apb_pkt;
  int           bytes_collected;

  exp_write_data.delete();
  bytes_collected = 0;

  // Step 1: find CTRL write with start bit asserted
  forever begin
    apb_analysis_fifo.get(apb_pkt);
    apb_tx_count++;

    `uvm_info("SB", $sformatf("APB pkt: addr=0x%0x pwrite=%s pwdata=0x%0x",
              apb_pkt.paddr, apb_pkt.pwrite.name(), apb_pkt.pwdata), UVM_HIGH)

    if (apb_pkt.pwrite == apb_global_pkg::WRITE && apb_pkt.paddr[6:0] == 7'h0C) begin
      if (apb_pkt.pwdata[31] == 1'b1) begin
        decode_ctrl(apb_pkt.pwdata);
        `uvm_info("SB", $sformatf(
          "CTRL decoded: addr=0x%0x dir=%0b len=%0d cmd_type=%0b ccc=0x%0x",
          exp_address, exp_direction, exp_length, exp_cmd_type, exp_ccc), UVM_MEDIUM)
        break;
      end
    end
  end

  // Step 2: collect WDATAB bytes only for WRITE transactions
  if (exp_direction == 1'b0) begin
    while (bytes_collected < int'(exp_length)) begin
      apb_analysis_fifo.get(apb_pkt);
      apb_tx_count++;

      if (apb_pkt.pwrite == apb_global_pkg::WRITE && apb_pkt.paddr[6:0] == 7'h30) begin
        exp_write_data.push_back(apb_pkt.pwdata[7:0]);
        bytes_collected++;
        `uvm_info("SB", $sformatf("WDATAB[%0d] = 0x%0x",
                  bytes_collected-1, apb_pkt.pwdata[7:0]), UVM_HIGH)
      end
    end
  end
endtask

*/

task i3c_scoreboard::collect_apb_transaction();
  apb_master_tx apb_pkt;
  int bytes_collected;
  exp_write_data.delete();
  bytes_collected = 0;

  // collect ALL APB transactions until CTRL start=1
  forever begin
    apb_analysis_fifo.get(apb_pkt);
    apb_tx_count++;

    // collect WDATAB writes as they come
    if(apb_pkt.pwrite == apb_global_pkg::WRITE && 
       apb_pkt.paddr[6:0] == 7'h30) begin
      exp_write_data.push_back(apb_pkt.pwdata[7:0]);
      `uvm_info("SB", $sformatf("WDATAB collected = 0x%0x", 
                apb_pkt.pwdata[7:0]), UVM_HIGH)
    end

    // when CTRL start=1 seen, stop collecting
    if(apb_pkt.pwrite == apb_global_pkg::WRITE && 
       apb_pkt.paddr[6:0] == 7'h0C &&
       apb_pkt.pwdata[31] == 1'b1) begin
      decode_ctrl(apb_pkt.pwdata);
      `uvm_info("SB", $sformatf(
        "CTRL decoded: addr=0x%0x dir=%0b len=%0d cmd_type=%0b ccc=0x%0x",
        exp_address, exp_direction, exp_length, 
        exp_cmd_type, exp_ccc), UVM_MEDIUM)
      break;
    end
  end
endtask

function void i3c_scoreboard::decode_ctrl(bit [31:0] ctrl_val);
  exp_address   = ctrl_val[6:0];
  exp_length    = ctrl_val[14:7];
  exp_direction = ctrl_val[15];
  exp_ccc       = ctrl_val[23:16];
  exp_cmd_type  = ctrl_val[25:24];
endfunction


task i3c_scoreboard::compare_with_target();
  i3c_target_tx tgt;

  target_analysis_fifo.get(tgt);
  target_tx_count++;

  `uvm_info("SB", $sformatf("Target pkt:\n%s", tgt.sprint()), UVM_HIGH)

  if (exp_address == tgt.targetAddress)
    `uvm_info("SB_ADDR_MATCH",
      $sformatf("Address match: 0x%0x", exp_address), UVM_MEDIUM)
  else
    `uvm_error("SB_ADDR_MISMATCH",
      $sformatf("Address: expected 0x%0x  got 0x%0x",
                exp_address, tgt.targetAddress))

  begin
    operationType_e exp_op = (exp_direction == 1'b0) ? 
                             i3c_globals_pkg::WRITE : 
                             i3c_globals_pkg::READ;
    if (exp_op == tgt.operation)
      `uvm_info("SB_OP_MATCH",
        $sformatf("Operation match: %s", exp_op.name()), UVM_MEDIUM)
    else
      `uvm_error("SB_OP_MISMATCH",
        $sformatf("Operation: expected %s  got %s",
                  exp_op.name(), tgt.operation.name()))
  end

  if (exp_direction == 1'b0) begin

    if (exp_write_data.size() != tgt.writeData.size()) begin
      `uvm_error("SB_WDATA_SIZE",
        $sformatf("Write data size mismatch: expected %0d  got %0d",
                  exp_write_data.size(), tgt.writeData.size()))
    end else begin
      for (int i = 0; i < exp_write_data.size(); i++) begin
        if (exp_write_data[i] == tgt.writeData[i][7:0]) begin
          `uvm_info("SB_WDATA_MATCH",
            $sformatf("writeData[%0d]: expected 0x%0x  got 0x%0x",
                      i, exp_write_data[i], tgt.writeData[i][7:0]), UVM_MEDIUM)
          write_pass++;
        end else begin
          `uvm_error("SB_WDATA_MISMATCH",
            $sformatf("writeData[%0d]: expected 0x%0x  got 0x%0x",
                      i, exp_write_data[i], tgt.writeData[i][7:0]))
          write_fail++;
        end
      end
    end

  end else begin

    bit [7:0] apb_read_data[$];
    apb_master_tx rd_pkt;
    int rd_count = 0;

    while (rd_count < int'(exp_length)) begin
      apb_analysis_fifo.get(rd_pkt);
      apb_tx_count++;
      if (rd_pkt.pwrite == apb_global_pkg::READ && rd_pkt.paddr[6:0] == 7'h40) begin
        apb_read_data.push_back(rd_pkt.prdata[7:0]);
        rd_count++;
        `uvm_info("SB", $sformatf("RDATAB[%0d] = 0x%0x",
                  rd_count-1, rd_pkt.prdata[7:0]), UVM_HIGH)
      end
    end

    if (apb_read_data.size() != tgt.readData.size()) begin
      `uvm_error("SB_RDATA_SIZE",
        $sformatf("Read data size mismatch: expected %0d  got %0d",
                  apb_read_data.size(), tgt.readData.size()))
    end else begin
      for (int i = 0; i < apb_read_data.size(); i++) begin
        if (apb_read_data[i] == tgt.readData[i][7:0]) begin
          `uvm_info("SB_RDATA_MATCH",
            $sformatf("readData[%0d]: expected 0x%0x  got 0x%0x",
                      i, apb_read_data[i], tgt.readData[i][7:0]), UVM_MEDIUM)
          read_pass++;
        end else begin
          `uvm_error("SB_RDATA_MISMATCH",
            $sformatf("readData[%0d]: expected 0x%0x  got 0x%0x",
                      i, apb_read_data[i], tgt.readData[i][7:0]))
          read_fail++;
        end
      end
    end

  end
endtask


function void i3c_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);

  `uvm_info("SB_SUMMARY", $sformatf({
    "\n========= SCOREBOARD SUMMARY =========\n",
    "  APB transactions seen    : %0d\n",
    "  I3C target transactions  : %0d\n",
    "  Write byte pass / fail   : %0d / %0d\n",
    "  Read  byte pass / fail   : %0d / %0d\n",
    "======================================"},
    apb_tx_count, target_tx_count,
    write_pass,   write_fail,
    read_pass,    read_fail), UVM_NONE)

  if (write_fail != 0)
    `uvm_error("SB_SUMMARY", "Write data mismatches detected")
  if (read_fail  != 0)
    `uvm_error("SB_SUMMARY", "Read data mismatches detected")
  if (apb_analysis_fifo.size() != 0)
    `uvm_error("SB_SUMMARY",
      $sformatf("APB FIFO not empty: %0d leftover packets",
                apb_analysis_fifo.size()))
  if (target_analysis_fifo.size() != 0)
    `uvm_error("SB_SUMMARY",
      $sformatf("Target FIFO not empty: %0d leftover packets",
                target_analysis_fifo.size()))
endfunction

`endif
