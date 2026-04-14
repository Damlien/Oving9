
/* =============================================================
Task:       D-100.6 c 
File:       lib_module/any_edge_detector.v
Module:     any_edge_detector
Purpose:    detects when a button either has positive edge or 
            negative edge
Depends:    lib_module/D_vippe.v
=============================================================
*/


module any_edge_detector(
    input button, clk,
    output button_pre_state, button_pre_state_inv, any_edge_det_output
);


D_vippe D_vippe_any_edge (
    .D(button),
    .clk (clk),
    .Q(button_pre_state),
    .Qn(button_pre_state_inv)
);

assign any_edge_det_output = button ^ button_pre_state;

endmodule