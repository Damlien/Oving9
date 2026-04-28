/* =============================================================
Task:       D-100.12 
File:       D_100_12_counter_99.v
Module:     counter_99
Purpose:    use two sevensegment-displays, with counter from 0-99
Depends:    lib_modules/debouncer.v
            lib_module/pos_edge_detector.v
            lib_module/c_add_algorithm.v
            lib_module/seven_segment_display_0_F
=============================================================
*/


module counter_99 (
    input SW1, clk,
    output Segment1_A, Segment1_B, Segment1_C, Segment1_D, Segment1_E, Segment1_F, Segment1_G,
    output Segment2_A, Segment2_B, Segment2_C, Segment2_D, Segment2_E, Segment2_F, Segment2_G
);



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


wire [9:0] OUT;


reg [6:0] counter = 7'b0000000;

always @(posedge pos_edge_det_output_SW1)
    begin 
        if  (counter == 7'b1100011) counter <= 7'b0000000;
        else 
            counter <= counter +1;
            
    end 

c_add_3_algorithm bcd_converter (
    .B( {1'b0, counter} ),
    .P(OUT)
);

seven_segment_display_0_F  seven_segment_LEFT(
    .D3(OUT[7]),
    .D2(OUT[6]),
    .D1(OUT[5]),
    .D0(OUT[4]),
    .Segment1_A(Segment1_A),
    .Segment1_B(Segment1_B),
    .Segment1_C(Segment1_C),
    .Segment1_D(Segment1_D),
    .Segment1_E(Segment1_E),
    .Segment1_F(Segment1_F),
    .Segment1_G(Segment1_G)
);

seven_segment_display_0_F  seven_segment_RIGHT(
    .D3(OUT[3]),
    .D2(OUT[2]),
    .D1(OUT[1]),
    .D0(OUT[0]),
    .Segment1_A(Segment2_A),
    .Segment1_B(Segment2_B),
    .Segment1_C(Segment2_C),
    .Segment1_D(Segment2_D),
    .Segment1_E(Segment2_E),
    .Segment1_F(Segment2_F),
    .Segment1_G(Segment2_G)
);


endmodule 

























