`timescale 1us/1us
module HazardDetectionUnit (
    input wire id_use_rs,
    input wire id_use_rt,
    input wire [4:0] if_id_rs,
    input wire [4:0] if_id_rt,
    input wire id_ex_mem_to_reg,
    input wire [4:0] id_ex_dest,
    output wire stallF,
    output wire stallD,
    output wire flushE
);
    wire hazard_rs = id_use_rs && (id_ex_dest != 5'd0) && (id_ex_dest == if_id_rs);
    wire hazard_rt = id_use_rt && (id_ex_dest != 5'd0) && (id_ex_dest == if_id_rt);
    wire load_use_hazard = id_ex_mem_to_reg && (hazard_rs || hazard_rt);

    assign stallF = load_use_hazard;
    assign stallD = load_use_hazard;
    assign flushE = load_use_hazard;
endmodule
