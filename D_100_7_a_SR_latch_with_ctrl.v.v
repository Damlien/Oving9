/* =============================================================
Task:       D-100.7a 
File:       D_100_7_a_SR_latch_with_ctrl.v
Module:     SR_latch_with_ctrl
Purpose:    SR_latch with positive edge of SW1 as reset, 
            positive edge of SW2 as set and LED1 as output. 
            Has also a ctrl output, triggered on any positive edge 
            
Depends:    lib_module/debouncer.v,
            lib_module/pos_edge_detector.v, 
            lib_module/D_vippe.v
            
=============================================================
*/


module SR_latch_with_ctrl (
    input SW1, SW2, clk,
    output LED1, LED2
);

wire clean_SW1;
wire clean_SW2;

debouncer debouncer_SW1 (
    .button(SW1),
    .clk (clk),
    .debounce_state(clean_SW1)
);

debouncer debouncer_SW2 (
    .button(SW2),
    .clk (clk),
    .debounce_state(clean_SW2)
);


    wire SW1_pre, SW1_pre_inv, pos_edge_det_output_SW1;
    wire SW2_pre, SW2_pre_inv, pos_edge_det_output_SW2;
    
    wire LED1_next;
    wire ctrl_pulse;

pos_edge_detector pos_edge_SW1(
        .button(clean_SW1),
        .clk(clk),
        .button_pre_state(SW1_pre),
        .button_pre_state_inv(SW1_pre_inv),
        .pos_edge_det_output(pos_edge_det_output_SW1)
    );


pos_edge_detector pos_edge_SW2(
        .button(clean_SW2),
        .clk(clk),
        .button_pre_state(SW2_pre),
        .button_pre_state_inv(SW2_pre_inv),
        .pos_edge_det_output(pos_edge_det_output_SW2)
    );


assign LED2 = pos_edge_det_output_SW1 | pos_edge_det_output_SW2;

assign LED1_next = pos_edge_det_output_SW2 | ~pos_edge_det_output_SW1 & LED1;


D_vippe D_vippe (
    .D (LED1_next),
    .clk (clk),
    .Q (LED1)
);



endmodule