
/* =============================================================
Task:       D-100.6 - prerequisite
File:       lib_module/D_vippe.v
Module:     D_vippe
Purpose:    It is a D-flip-flop (D-vippe)
Depends:    -
=============================================================
*/



module D_vippe (
    input D, clk,
    output reg Q = 1'b0, 
    output reg Qn = 1'b0
    //  reg (variable som kan huske verdi)
    // 1'b0 (ett bit satt til 0)
);

    always @(posedge clk) // kode kjører alltid når clk går fra 0 til 1.
    begin 
        Q <= D; // <= parallell endring
        Qn <= ~D;
    end


endmodule 