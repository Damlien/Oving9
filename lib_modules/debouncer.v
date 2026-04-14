
/* =============================================================
Task:       D-100.6 prerequisite 
File:       lib_module/debouncer
Module:     debouncer
Purpose:    a debouncer for buttons on FPGA board
Depends:    -
=============================================================
*/




module debouncer #(parameter THRESHOLD = 250_000) (
    input button, clk,
    output reg debounce_state = 1'b0
);



//SW1
reg button_pre_state = 1'b0;
reg [24:0] counter =0;

always @(posedge clk) begin

    if (button != button_pre_state ) begin
        counter <= 0;
    end

    else if ( counter < THRESHOLD)  begin
        counter <= counter + 1;
    end 
    else  begin
        debounce_state <= button;
    end

    button_pre_state<= button;
end


endmodule