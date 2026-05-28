`timescale 1ns / 1ps

// Basic ultrasonic sensor module
module ultrasonic_sensor(
    input clk,
    input start,
    output reg trigger,
    input echo,
    output reg [20:0] distance,
    output reg measurement_done
);
    
    parameter CLK_MHZ = 50;
    parameter TRIGGER_TIME = 600;  // 12us * 50MHz = 600 clocks
    parameter TIMEOUT = 150000;    // 3ms * 50MHz = 150000 clocks
    
    reg [20:0] counter;
    reg [2:0] state;
    
    // States
    parameter IDLE = 0;
    parameter SEND_TRIGGER = 1;
    parameter WAIT_ECHO_START = 2;
    parameter MEASURE_ECHO = 3;
    parameter DONE = 4;
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                trigger <= 0;
                measurement_done <= 0;
                counter <= 0;
                if (start) begin
                    state <= SEND_TRIGGER;
                    trigger <= 1;
                end
            end
            
            SEND_TRIGGER: begin
                counter <= counter + 1;
                if (counter >= TRIGGER_TIME) begin
                    trigger <= 0;
                    counter <= 0;
                    state <= WAIT_ECHO_START;
                end
            end
            
            WAIT_ECHO_START: begin
                counter <= counter + 1;
                if (echo) begin
                    counter <= 0;
                    state <= MEASURE_ECHO;
                end else if (counter >= TIMEOUT) begin
                    distance <= 21'h1FFFFF;  // Max value for timeout
                    state <= DONE;
                end
            end
            
            MEASURE_ECHO: begin
                counter <= counter + 1;
                if (!echo) begin
                    distance <= counter;
                    state <= DONE;
                end else if (counter >= TIMEOUT) begin
                    distance <= 21'h1FFFFF;  // Max value for timeout
                    state <= DONE;
                end
            end
            
            DONE: begin
                measurement_done <= 1;
                state <= IDLE;
            end
        endcase
    end
endmodule

// Single sensor controller with reduced LEDs
module sensor_controller(
    input CLOCK_50,
    output TRIG,
    input ECHO,
    output [3:0] LED  // Reduced to 4 LEDs
);
    
    reg [24:0] ping_counter;
    wire start_measurement;
    wire [20:0] distance;
    wire measurement_done;
    
    // Send ping every 60ms (50MHz * 60ms = 3,000,000 clocks)
    parameter PING_PERIOD = 3000000;
    
    // Distance thresholds (calibrated for your sensor)
    // Closer objects = smaller distance values = more LEDs ON
    parameter D = 2900;  // Distance scaling factor
    
    // Create ultrasonic sensor instance
    ultrasonic_sensor sensor(
        .clk(CLOCK_50),
        .start(start_measurement),
        .trigger(TRIG),
        .echo(ECHO),
        .distance(distance),
        .measurement_done(measurement_done)
    );
    
    // Generate start pulse every 60ms
    assign start_measurement = (ping_counter == PING_PERIOD - 1);
    
    always @(posedge CLOCK_50) begin
        if (ping_counter == PING_PERIOD - 1)
            ping_counter <= 0;
        else
            ping_counter <= ping_counter + 1;
    end
    
    // LED control with only 4 LEDs - MORE LEDs ON when object is CLOSER
    assign LED[0] = (distance < 30*D);  // < 30cm - farthest threshold
    assign LED[1] = (distance < 20*D);  // < 20cm 
    assign LED[2] = (distance < 15*D);  // < 15cm
    assign LED[3] = (distance < 10*D);  // < 10cm - closest threshold
    
endmodule

// Main module with two sensors and comparison (4 LEDs each)
module dual_ultrasonic(
    input CLOCK_50,
    
    // Sensor 1
    output TRIG1,
    input ECHO1,
    output [3:0] LED1,    // Reduced to 4 LEDs
    
    // Sensor 2  
    output TRIG2,
    input ECHO2,
    output [3:0] LED2,    // Reduced to 4 LEDs
    
    // Comparison outputs
    output reg[1:0] GREEN_LED,   // Closer sensor indicator
    output reg [1:0]RED_LED      // Farther sensor indicator
);

    wire [3:0] sensor1_leds, sensor2_leds;
    
    // Create two sensor controllers
    sensor_controller sensor1(
        .CLOCK_50(CLOCK_50),
        .TRIG(TRIG1),
        .ECHO(ECHO1),
        .LED(sensor1_leds)
    );
    
    sensor_controller sensor2(
        .CLOCK_50(CLOCK_50),
        .TRIG(TRIG2),
        .ECHO(ECHO2),
        .LED(sensor2_leds)
    );
    
    assign LED1 = sensor1_leds;
    assign LED2 = sensor2_leds;
    
    // Count how many LEDs are ON for each sensor (now only 4 LEDs each)
    // More LEDs ON means object is closer
    wire [2:0] sensor1_count, sensor2_count;
    
    assign sensor1_count = sensor1_leds[0] + sensor1_leds[1] + sensor1_leds[2] + sensor1_leds[3];
    assign sensor2_count = sensor2_leds[0] + sensor2_leds[1] + sensor2_leds[2] + sensor2_leds[3];
    
    // Comparison logic
    always @(*) begin
        if (sensor1_count > sensor2_count) begin
            // Sensor 1 detects closer object
            GREEN_LED[0] = 1;  // Sensor 1 side is closer
            RED_LED[1] = 1;
        end
        else if (sensor2_count > sensor1_count) begin
            // Sensor 2 detects closer object  
            GREEN_LED[1] = 1;
            RED_LED[0] = 1;    // Sensor 2 side is closer
        end
        else begin
            // Equal distance or no detection
            GREEN_LED = 0;
            RED_LED = 0;
        end
    end
    
endmodule
