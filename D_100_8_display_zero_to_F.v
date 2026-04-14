
/* =============================================================
Task:       D-100.8 
File:       D_100_8_display_zero_to_F.v
Module:     display_zero_to_F
Purpose:    Display numbers 0 to 9 and letters A to F on seven segment dispaly. 
            4-bit input: SW1, SW2, SW3 and SW4 are binary representation of 16 
            first numbers of hexadecimal number system
Depends:    
=============================================================
*/


module display_zero_to_F (
    input   SW1, SW2, SW3, SW4,
    output  Segment1_A, Segment1_B, Segment1_C, Segment1_D, Segment1_E, Segment1_F, Segment1_G
);


    wire D3, D2, D1, D0;

    assign D3 = SW1, D2 = SW2, D1 = SW3, D0 = SW4;


assign Segment1_A = ~( ~D0 & D1 | ~D0 & ~D2 | D1 & D2 | D1 & ~D3 | ~D1 & ~D2 & D3 | ~D0 & ~D1 & D3 | D0 & D2 & ~D3  );
assign Segment1_B = ~( ~D2 & ~D3 | ~D0 & ~D2 | D0 & D1 & ~D3 | ~D0 & ~D1 & ~D3 | D0 & ~D1 & D3 );
assign Segment1_C = ~ ( ~D1 & ~D3 | ~D1 & ~D2 | D0 & ~D3 | D1 & D2 & ~D3 | D0 & ~D1 | D3 & ~D2 );
assign Segment1_D =  ~ (  ~D1 & D3 | D1 & ~D2 & ~D3 | ~D0 & D1 & ~D3 | ~D0 & D1 & D2 | D0 & ~D2 & D3 | ~D0 & ~D1 & ~D2 | D0 & ~D1 & D2 & ~D3  ) ; 
assign Segment1_E =    ~ ( ~D0 & D1 | D2 & D3 | D1 & D3 | ~D0 & ~D2) ;
assign Segment1_F =  ~( ~D0 & ~D1 | ~D2 & D3 | D1 & D3 | ~D0 & D2 | ~D1 & D2 & ~D3   );
assign Segment1_G = ~( ~D0 & D1 | ~D2 & D3 | D1 & D3 | D0 & D3 | ~D1 & D2 & ~D3 | D1 & ~D2)  ;

endmodule