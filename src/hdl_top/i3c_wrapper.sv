`ifndef APB_IF_INCLUDED_
`define APB_IF_INCLUDED_
`include "apb_if.sv"
import apb_global_pkg::*;
module apb_i3c_wrapper(
    apb_if apb,

    output logic        wr_en,
    output logic        rd_en,
    output logic [6:0]  addrs,
    output logic [31:0] w_reg_data,
    output logic [7:0]  w_data,

    input  logic [31:0] rd_data,
    input  logic [7:0]  r_data
);

logic pready_r;

assign apb.pready  = pready_r;
assign apb.pslverr = 1'b0;

always_ff @(posedge apb.pclk or negedge apb.preset_n) begin
    if(!apb.preset_n) begin
        wr_en      <= 0;
        rd_en      <= 0;
        addrs      <= 0;
        w_reg_data <= 0;
        w_data     <= 0;
        apb.prdata <= 0;
        pready_r   <= 0;
    end
    else begin
        wr_en    <= 0;
        rd_en    <= 0;
        pready_r <= 0;

        if(apb.pselx[0] && apb.penable) begin
            addrs <= apb.paddr[6:0];

            if(apb.pwrite) begin
                wr_en      <= 1;
                w_reg_data <= apb.pwdata;
                w_data     <= apb.pwdata[7:0];
            end
            else begin
                rd_en <= 1;
                apb.prdata <= {24'b0, r_data};
            end

            pready_r <= 1;
        end
    end
end

endmodule
`endif

