`default_nettype none

module spi_peripheral (
    input wire copi,
    input wire nCS,
    input wire clk, 
    input wire sclk,
    input wire rst_n,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);


// For synchronization
reg sclk_flip1, sclk_flip2;
reg nCS_flip1, nCS_flip2;
reg copi_flip1, copi_flip2;

// past values of the registers
reg nCS_previous, sclk_previous;
reg [4:0] bit_counter;
reg [15:0] shift_register;


// Boolean wires
wire nCS_rising_edge = (nCS_previous == 1'b0 && nCS_flip2 == 1'b1);
wire nCS_falling_edge = (nCS_previous == 1'b1 && nCS_flip2 == 1'b0);
wire sclk_rising_edge = (sclk_previous == 1'b0 && sclk_flip2 == 1'b1);
wire sclk_falling_edge = (sclk_previous == 1'b1 && sclk_flip2 == 1'b0);

// Checking if all 16 bits are filled
wire nCS_pulled_low = !nCS_flip2;
wire transaction_ready = nCS_rising_edge && (bit_counter == 5'd16);
wire [6:0] max_address = 7'h04;
wire rw_bit = shift_register[15];

always@(posedge clk or negedge rst_n) begin
    // Resetting everything
    if (!rst_n) begin
        // set copi and sclk flip flop values to 0
        copi_flip1 <= 1'b0;
        copi_flip2 <= 1'b0;
        sclk_flip1 <= 1'b0;
        sclk_flip2 <= 1'b0;

        // setting nCS flipflop value to 0 to denote it is off
        nCS_flip1 <= 1'b1;
        nCS_flip2 <= 1'b1;
        nCS_previous <= 1'b1;
        sclk_previous <= 1'b0;

        // Resetting all the registers
        en_reg_out_15_8 <= 8'd0;
        en_reg_pwm_7_0 <= 8'd0;
        en_reg_pwm_15_8  <= 8'd0;
        en_reg_out_7_0  <= 8'd0;

        // resetting the bit counter and the shift registers
        shift_register <= 16'd0;
        bit_counter <= 5'd0;
    end
    else begin
        // flip flop bits
        sclk_flip1 <= sclk;
        sclk_flip2 <= sclk_flip1;
        sclk_previous <= sclk_flip2;

        copi_flip1 <= copi;
        copi_flip2 <= copi_flip1;

        nCS_flip1 <= nCS;
        nCS_flip2 <= nCS_flip1;
        nCS_previous <= nCS_flip2;

        // Checking for transaction based on nCS value
        if (nCS_falling_edge) begin
            shift_register <= 16'd0;
            bit_counter <= 5'd0;
        end
        else if (nCS_pulled_low && sclk_rising_edge) begin
            shift_register <= {shift_register[14:0], copi_flip2};
            if (bit_counter < 5'd16)
                bit_counter <= bit_counter + 5'd1;
        end
        // if statement wire
        else if (transaction_ready && shift_register[14:8] <= max_address && rw_bit) begin
            if (shift_register[14:8] == 7'h00) en_reg_out_7_0 <= shift_register[7:0];
            else if (shift_register[14:8] == 7'h01) en_reg_out_15_8 <= shift_register[7:0];
            else if (shift_register[14:8] == 7'h02) en_reg_pwm_7_0 <= shift_register[7:0];
            else if (shift_register[14:8] == 7'h03) en_reg_pwm_15_8 <= shift_register[7:0];
            else if (shift_register[14:8] == 7'h04) pwm_duty_cycle <= shift_register[7:0];

            // resetting back to zero
            bit_counter <= 5'b0;
            shift_register <= 16'b0;
        end

    end
end

endmodule