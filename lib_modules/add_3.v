
/* =============================================================
Task:       D-100.12 
File:       lib_module/add_3.v
Module:     add-3
Purpose:    add 3 to a 4-bit group when value is 5 or greater
Depends:    -
=============================================================
*/

module add_3 (
    input [3:0] A,
    output reg [3:0] S
);

always @(*) begin

    case(A)
        4'b0000: S = 4'b0000;
        4'b0001: S = 4'b0001;
        4'b0010: S = 4'b0010;
        4'b0011: S = 4'b0011;
        4'b0100: S = 4'b0100;
        4'b0101: S = 4'b1000;
        4'b0110: S = 4'b1001;
        4'b0111: S = 4'b1010;
        4'b1000: S = 4'b1011;
        4'b1001: S = 4'b1100;
        default: S = 4'b0000;
    endcase

end 


endmodule 