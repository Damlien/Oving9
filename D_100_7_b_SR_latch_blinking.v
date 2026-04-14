/* =============================================================
Task:       D-100.7b 
File:       D_100_7_b_SR_latch_blinking.v
Module:     SR_latch_blinking
Purpose:    SR_latch with positive edge of SW1 as reset, 
            positive edge of SW2 as set and LED1 as output. 
            Has also a ctrl output, triggered on any positive edge 
            
Depends:    lib_module/debouncer.v,
            lib_module/pos_edge_detector.v, 
            lib_module/D_vippe.v
            lib_module/prescaler.v
            D_100_b_SR_latch_with_blinking.v
            
=============================================================
*/

module SR_latch_blinking (
    input SW1, SW2, clk,
    output LED1, LED2, LED3
);


SR_latch_with_ctrl SR_latch (
    .SW1(SW1), 
    .SW2(SW2),
    .clk(clk),
    .LED1(LED1),
    .LED2(LED2),
);

wire slow_blink;
wire fast_blink;

simple_prescaler simple_prescaler (
    .clk(clk),
    .slow_blink(slow_blink),
    .fast_blink(fast_blink)
);

assign LED3 = slow_blink & ~LED1 | fast_blink & LED1; 

endmodule