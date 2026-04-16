
/* =============================================================
Task:       D-100.9 
File:       D_100_9_counter_4_1.v
Module:     counter_4_1
Purpose:    count from 4 to 1, etc on seven segment display. 
Depends:    lib_module/debouncer.v,
            lib_module/pos_edge_detector.v, 
            lib_module/D_vippe.v
            lib_module/seven_segment_display_0_F.v
=============================================================
*/

module counter_4_1(
input SW1, clk,
output Segment1_A, Segment1_B, Segment1_C, Segment1_D, Segment1_E, Segment1_F, Segment1_G
);

wire D3_next, D3, D3_inv;
wire D2_next, D2, D2_inv;
wire D1_next, D1, D1_inv;
wire D0_next, D0, D0_inv;
wire clean_SW1, clean_SW1_pre, clean_SW1_inv, pos_edge_det_output_SW1;

debouncer debouncer(
    .button(SW1),
    .clk(clk),
    .debounce_state (clean_SW1)
);
pos_edge_detector pos_edge_detector (
    .button(clean_SW1),
    .button_pre_state(clean_SW1_pre),
    .button_pre_state_inv(clean_SW1_pre),
    .pos_edge_det_output(pos_edge_det_output_SW1)
);

// use pos_edge_det_output_SW1 to toggle counter
assign D3 = 1'b0;
assign D2_next = D0 & ~D1 & ~D2  ;
assign D1_next = D0 & D1 & ~D2 | ~D0 & ~D1 & D2  ;
assign D0_next =  ~D0 & D1 & ~D2 | ~D0 & ~D1 & D2;

D_vippe #(.INIT(1'b1)) d_vippe_D2 (
    .D(D2_next),
    .clk(pos_edge_det_output_SW1),
    .Q (D2),
    .Qn (D2_inv)
);

D_vippe d_vippe_D1 (
    .D(D1_next),
    .clk(pos_edge_det_output_SW1),
    .Q (D1),
    .Qn (D1_inv)
);

D_vippe d_vippe_D0 (
    .D(D0_next),
    .clk(pos_edge_det_output_SW1),
    .Q (D0),
    .Qn (D0_inv)
);

seven_segment_display_0_F  seven_segment(
    .D3(D3),
    .D2(D2),
    .D1(D1),
    .D0(D0),
    .Segment1_A(Segment1_A),
    .Segment1_B(Segment1_B),
    .Segment1_C(Segment1_C),
    .Segment1_D(Segment1_D),
    .Segment1_E(Segment1_E),
    .Segment1_F(Segment1_F),
    .Segment1_G(Segment1_G),
);
endmodule