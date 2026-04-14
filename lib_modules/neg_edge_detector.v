
/* =============================================================
Task:       D-100.6 b
File:       lib_module/neg_edge_detector.v
Module:     neg_edge_detector
Purpose:    detects when a button either has neg edge
Depends:    lib_module/D_vippe.v
=============================================================
*/


module neg_edge_detector (
    input button, clk,
    output  button_pre_state, button_pre_state_inv, neg_edge_det_output
);

    D_vippe D_vippe_neg(
        .D(button), 
        .clk(clk),
        .Q(button_pre_state),
        .Qn(button_pre_state_inv)
    );

    assign neg_edge_det_output = ~button & button_pre_state;

endmodule