/* =============================================================
Task:       D-100.6
File:       D100_6_edge_detector_test.v
Module:     Edge_detector_test
Purpose:    Top-level test for pos/neg/any edge detectors.
            Each detector drives a T-vippe; output visible on LEDs.
Depends:    lib_modules/debouncer.v, 
            lib_module/pos_edge_detector.v,
            lib_module/neg_edge_detector.v, 
            lib_module/any_edge_detector.v,
            lib_module/T_vippe.v
=============================================================
*/
module edge_detector_test(
    input SW1, SW2, SW3, clk,
    output LED1, LED2, LED3
);


     wire SW1_pre, SW1_pre_inv, pos_edge_det_output_SW1; 

     wire SW2_pre, SW2_pre_inv, neg_edge_det_output_SW2 ;

     wire SW3_pre, SW3_pre_inv, pos_edge_det_output_SW3, neg_edge_det_output_SW3, any_edge_det_output_SW3;

// *****************************************************
// ****************** DEBOUNCER ************************
// *****************************************************

    debouncer debouncer_SW1 (
        .button(SW1),
        .clk (clk),
        .debounce_state(clean_SW1)
    );

    debouncer debouncer_SW2 (
        .button(SW2),
        .clk (clk),
        .debounce_state(clean_SW2)
    );

    debouncer debouncer_SW3 (
        .button(SW3),
        .clk (clk),
        .debounce_state(clean_SW3)
    );




// *****************************************************
// ****************** DETECTORS ************************
// *****************************************************

  //pos edge detector module for SW1
    pos_edge_detector pos_edge_detector(
        .button(clean_SW1),
        .clk(clk),
        .button_pre_state(SW1_pre),
        .button_pre_state_inv(SW1_pre_inv),
        .pos_edge_det_output(pos_edge_det_output_SW1)

    );

    

    //Neg edge detector module for SW2
    neg_edge_detector neg_edge_detector(
        .button(clean_SW2),
        .clk(clk),
        .button_pre_state(SW2_pre),
        .button_pre_state_inv(SW2_pre_inv),
        .neg_edge_det_output(neg_edge_det_output_SW2)

    );

  


    //edge detector module for SW3

    any_edge_detector any_edge_detector (
        .button(clean_SW3),
        .clk(clk),
        .button_pre_state(SW3_pre),
        .button_pre_state_inv(SW3_pre_inv),
        .any_edge_det_output(any_edge_det_output_SW3)
    );


// *************************************************************************

// pos_edge testing - T-vippe

T_vippe pos_edge_tester (

    .T(1'b1),
    .clk(pos_edge_det_output_SW1),
    .Q(LED1)
);

   

// neg_edge testing -  T-vippe
    
T_vippe neg_edge_tester (
    .T(1'b1),
    .clk (neg_edge_det_output_SW2),
    .Q(LED2)
);


// any_edge testing -  T-vippe

T_vippe any_edge_tester (
    .T(1'b1),
    .clk(any_edge_det_output_SW3),
    .Q(LED3)
);

// *************************************************************************
// *************************************************************************

endmodule