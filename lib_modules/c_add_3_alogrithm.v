
/* =============================================================
Task:       D-100.12 
File:       lib_module/c_add_3_algorithm.v
Module:     c_add_3_algorithm
Purpose:    Convert 8-bit binary value to two BCD digits using C-add-3 algorithm
Depends:    lib_module/add_3
=============================================================
*/




module c_add_3_algorithm (
    input [7:0] B,
    output [9:0] P
);



wire [3:0] C1;

add_3 add_3_C1 (
    .A ({ 1'b0, B[7:5] }),
    .S ( C1 )
);


wire [3:0] C2;

add_3 add_3_C2 (
    .A ({ C1[2:0], B[4] }),
    .S ( C2 )
);


wire [3:0] C3;

add_3 add_3_C3 (
    .A ({ C2[2:0], B[3] }),
    .S ( C3 )
);

wire [3:0] C4;

add_3 add_3_C4 (
    .A ({ C3[2:0], B[2] }),
    .S ( C4 )
);


wire [3:0] C5;

add_3 add_3_C5 (
    .A ({ C4[2:0], B[1] }),
    .S ( C5 )
);


wire [3:0] C6;

add_3 add_3_C6 (
    .A ({ 1'b0, C1[3], C2[3], C3[3] }),
    .S ( C6 )
);

wire [3:0] C7;

add_3 add_3_C7 (
    .A ({ C6[2:0], C4[3] }),
    .S ( C7 )
);


assign P = {C6[3], C7[3:0], C5[3:0], B[0]};
 

endmodule