`timescale 1ns / 1ps
module tb_ultrasonic_dual;
    reg CLOCK_50,
    
    // Sensor 1
    wire TRIG1,
    reg ECHO1,
    wire [3:0] LED1,    // Reduced to 4 LEDs
    
    // Sensor 2  
    wire TRIG2,
    reg ECHO2,
    wire [3:0] LED2,    // Reduced to 4 LEDs
    
    // Comparison outputs
    wire [1:0] GREEN_LED,   // Closer sensor indicator
    wire [1:0]RED_LED      // Farther sensor indicator
ultrasonic_dual dut (.CLOCK_50(CLOCK_50),.TRIG1(TRIG1),ECHO1(ECHO1),LED1(LED1), .TRIG2(TRIG2),.ECHO2(ECHO2),.LED2(LED2),.GREEN_LED(GREEN_LED),.RED_LED(RED_LED)  );

    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end
    initial begin
        
        ECHO1 = 0;
        ECHO2 = 0;
    
        #200;
        ECHO1 = 1;
        #1000;
        ECHO1 = 0;
        #5000;
        ECHO2 = 1;
        #1500;
        ECHO2 = 0;
        #50000;

        $finish;
    end
endmodule
