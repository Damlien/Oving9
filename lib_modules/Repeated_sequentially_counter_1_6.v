/* =============================================================
Task:       D-100.16 
File:       Repeated_sequentially_counter_1_6.v
Module:     Repeated_sequentially_counter_1_6
Purpose:    a counter that repeatedly and sequentially counts from 1 to 6
Depends:    
=============================================================
*/

module Repeated_sequentially_counter_1_6 (
    input clean_button, clk,
    output reg [2:0] D_now =3'b001
);

reg [24:0] counter = 0; 


always @(posedge clk)
begin
if (clean_button ==1)
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
                default: D_now <= 3'b001;
                endcase
                counter <=0;
            end
        else
            begin 
                counter <= counter +1;
            end 
    end

end





endmodule 