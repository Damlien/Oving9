/* =============================================================
Task:       D-100.10 
File:       D_100_10_counter_up_down.v
Module:     counter_4_1
Purpose:    count from 1-4 either up or down on seven segment display. 
            
Depends:    lib_module/debouncer.v,
            lib_module/pos_edge_detector.v, 
            lib_module/D_vippe.v
            lib_module/seven_segment_display_0_F.v
            
=============================================================
*/

module counter_up_down(
    input SW1, SW2,  clk,
    output Segment1_A, Segment1_B, Segment1_C, Segment1_D, Segment1_E, Segment1_F, Segment1_G
);



wire D3;
wire D2_next, D2;
wire D1_next, D1;
wire D0_next, D0;

wire X;

wire clean_SW1, clean_SW1_pre, clean_SW1_inv, pos_edge_det_output_SW1;
wire clean_SW2, clean_SW2_pre, clean_SW2_inv, pos_edge_det_output_SW2;

debouncer debouncer(
    .button(SW1),
    .clk(clk),
    .debounce_state (clean_SW1)
);

debouncer debouncer2(
    .button(SW2),
    .clk(clk),
    .debounce_state (clean_SW2)
);

pos_edge_detector pos_edge_detector (
    .button(clean_SW1),
    .button_pre_state(clean_SW1_pre),
    .button_pre_state_inv(clean_SW1_pre),
    .pos_edge_det_output(pos_edge_det_output_SW1)
);

pos_edge_detector pos_edge_detector2 (
    .button(clean_SW2),
    .button_pre_state(clean_SW2_pre),
    .button_pre_state_inv(clean_SW2_pre),
    .pos_edge_det_output(pos_edge_det_output_SW2)
);

assign X =  clean_SW2;
// logic for counting through 4-3-2-1-4, etc
// 
assign D3 = 1'b0;
assign D2_next = D0 & D1 & ~D2 & X | D0 & ~D1 & ~D2 & ~X;
assign D1_next = D0 & D1 & ~D2 & ~X | ~D0 & ~D1 & D2 & ~X | D0 & ~D1 & ~D2 & X | ~D0 & D1 & ~D2 & X; 
assign D0_next =  ~D0 & ~D1 & D2 & ~X | ~D0 & ~D1 & D2 & X | ~D0 & D1 & ~D2 & ~X | ~D0 & D1 & ~D2 & X;




D_vippe #(.INIT(1'b1)) d_vippe_D2 (
    .D(D2_next),
    .clk(pos_edge_det_output_SW1 | pos_edge_det_output_SW2), // use pos_edge_det as clk, change value on keypress
    .Q (D2)
);

D_vippe d_vippe_D1 (
    .D(D1_next),
    .clk(pos_edge_det_output_SW1 | pos_edge_det_output_SW2), // use pos_edge_det as clk, change value on keypress
    .Q (D1)
);

D_vippe d_vippe_D0 (
    .D(D0_next),
    .clk(pos_edge_det_output_SW1 | pos_edge_det_output_SW2), // use pos_edge_det as clk, change value on keypress
    .Q (D0)
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