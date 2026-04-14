`timescale 1ns/1ps


module D_100_7_tb (

);
reg SW1;
reg SW2;
reg clk;

wire LED1;
wire LED2;


defparam uut.debouncer_SW1.THRESHOLD = 2;
defparam uut.debouncer_SW2.THRESHOLD = 2;


SR_latch_with_ctrl uut (
    .SW1(SW1),
    .SW2(SW2),
    .clk(clk),
    .LED1(LED1),
    .LED2(LED2)
);

always #40 clk = ~clk;

localparam DEBOUNCE_WAIT = 6; 
localparam RELEASE_WAIT  = 6;

initial begin
    $dumpvars(0, D_100_7_tb);
    clk = 0;
    SW1 = 0;
    SW2 = 0;
    

    repeat(3) @(posedge clk);

    SW2 = 1;
    repeat(DEBOUNCE_WAIT) @(posedge clk);
   
    SW2 = 0;
    repeat(RELEASE_WAIT) @(posedge clk);

  
    SW1 = 1;
    repeat(DEBOUNCE_WAIT) @(posedge clk);
  
    SW1 = 0;
    repeat(RELEASE_WAIT) @(posedge clk);

  
    SW2 = 1;
    repeat(DEBOUNCE_WAIT) @(posedge clk);
 
    SW2 = 0;
    repeat(RELEASE_WAIT) @(posedge clk);
 
    repeat(5) @(posedge clk);





    $finish;
end

endmodule