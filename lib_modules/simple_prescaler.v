
/* =============================================================
Task:       D-100.7 b
File:       lib_module/prescaler.v
Module:     simple_prescaler
Purpose:    prescaler for a slow repeating signal and a fast        
            repeating signal
Depends:    -
=============================================================
*/



module simple_prescaler (

    input clk,
    output fast_blink, slow_blink
);

reg [24:0] counter = 0;

always @(posedge clk) begin 
    counter = counter + 1;
end 

assign slow_blink = counter[24];
assign fast_blink = counter[22];


endmodule