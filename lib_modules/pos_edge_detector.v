
/* =============================================================
Task:       D-100.6 a 
File:       lib_module/pos_edge_detector.v
Module:     pos_edge_detector
Purpose:    detects when a button has positive edge
Depends:    lib_module/D_vippe.v
=============================================================
*/



module pos_edge_detector (
    input button, clk,
    output  button_pre_state, button_pre_state_inv, pos_edge_det_output
);


    D_vippe D_vippe_pos(
        .D(button), 
        .clk(clk),
        .Q(button_pre_state),
        .Qn(button_pre_state_inv)
    );

    assign pos_edge_det_output = button & ~button_pre_state;

endmodule