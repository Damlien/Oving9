/* =============================================================
Task:       D-100.16 
File:       D_100_16_Numbergenerator_counter_1_6.v
Module:     counter_1_6
Purpose:    a counter that repeatedly and sequentially counts from 1 to 6
Depends:    lib_modules/
=============================================================
*/

module counter_1_6 (
    input SW1, clk,
    output Segment1_A, Segment1_B, Segment1_C, Segment1_D, Segment1_E, Segment1_F, Segment1_G
);

reg [24:0] counter = 0; 
reg [3:0] D_now = 3'b001; 



wire running;




wire clean_SW1, clean_SW1_pre, clean_SW1_inv, pos_edge_det_output_SW1;

debouncer debouncer(
    .button(SW1),
    .clk(clk),
    .debounce_state (clean_SW1)
);


always @(posedge clk)
begin
if (clean_SW1 ==1)
    begin
        if (counter == 12_000_000)
            begin
                case(D_now)
                3'b001: D_now <= 3'b010;
                3'b010: D_now <= 3'b011;
                3'b011: D_now <= 3'b100;
                3'b100: D_now <= 3'b101;
                3'b101: D_now <= 3'b110;
                3'b110: D_now <= 3'b001;
                default: D_now = 3'b001;
                endcase
                counter =0;
            end
        else
            begin 
                counter = counter +1;
            end 
    end

end


seven_segment_display_0_F  seven_segment_LEFT(
    .D3(1'b0),
    .D2(D_now[2]),
    .D1(D_now[1]),
    .D0(D_now[0]),
    .Segment1_A(Segment1_A),
    .Segment1_B(Segment1_B),
    .Segment1_C(Segment1_C),
    .Segment1_D(Segment1_D),
    .Segment1_E(Segment1_E),
    .Segment1_F(Segment1_F),
    .Segment1_G(Segment1_G)
);



endmodule 