
/* =============================================================
Task:       D-100.6 d
File:       lib_module/T_vippe.v
Module:     T_vippe
Purpose:    It is a T-flip-flop (T-vippe)
Depends:    -
=============================================================
*/


module T_vippe (
    input T, clk,
    output Q, Qn
);

wire D; 

assign D = T^Q;

D_vippe D_vippe (
    .D (D),
    .clk (clk),
    .Q (Q),
    .Qn (Qn)
);





endmodule