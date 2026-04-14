
/* =============================================================
Task:       D-100.7 d - alternative test for short signals
File:       lib_module/pulse_prolonger
Module:     pulse_prolonger
Purpose:    Extends a signal. Signals with clk are to fast for human       
            perception. By using a counter one can make a signal last longer,
            like making a LED stay on longer when triggered.
Depends:    -
=============================================================
*/

module pulse_prolonger #(

    parameter MAX_TIMER = 12_500_000) 
    (
    input input_pulse, clk,
    output output_prolonged
);

    

    reg [23:0] timer = 0;

    always @(posedge clk) begin
        if (input_pulse) timer <= MAX_TIMER;
        else if (timer > 0) timer <= timer- 1;
    end

    assign output_prolonged = (timer > 0);


endmodule