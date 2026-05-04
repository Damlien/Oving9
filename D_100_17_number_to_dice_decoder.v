/* =============================================================
Task:       D-100.17 and D-100.18
File:       D_100_17_number_to_dice_decoder.v
Module:     number_to_dice_decoder
Purpose:    takes a number 1 to 6, and decodes it into binary number representation 
            for a dice module with 7 leds. 
Depends:    /lib/debouncer.v
            /lib/Repeated_sequentially_counter_1_6.v
=============================================================
*/

module number_to_dice_decoder (
    input SW1, clk,
    output PMOD1, PMOD2, PMOD3, PMOD4, PMOD7, PMOD8, PMOD9
);

wire D0, D1, D2;

wire clean_SW1;

debouncer debouncer(
    .button(SW1),
    .clk(clk),
    .debounce_state (clean_SW1)
);

Repeated_sequentially_counter_1_6 repeat_seq_counter(
    .clean_button(clean_SW1),
    .clk (clk),
    .D_now( {D2, D1, D0})
);

assign PMOD1 =  D2;
assign PMOD2 = D1 & D2;
assign PMOD3 = D1 | D2;
assign PMOD4 = D0;
assign PMOD7 = D1 | D2; 
assign PMOD8 = D1 & D2; 
assign PMOD9 = D2;

endmodule
