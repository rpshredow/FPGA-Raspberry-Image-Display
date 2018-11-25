module LED_7seg(
    input clk,
	 input [3:0] input_data,
    output segA, segB, segC, segD, segE, segF, segG, segDP
);

reg [7:0] SevenSeg;
always @(posedge clk)
case(input_data)
    4'b0000: SevenSeg = 8'b11111100;  //0
    4'b0001: SevenSeg = 8'b01100000;  //1
    4'b0010: SevenSeg = 8'b11011010;  //2
    4'b0011: SevenSeg = 8'b11110010;  //3
    4'b0100: SevenSeg = 8'b01100110;  //4
    4'b0101: SevenSeg = 8'b10110110;  //5
    4'b0110: SevenSeg = 8'b10111110;  //6
    4'b0111: SevenSeg = 8'b11100000;  //7
    4'b1000: SevenSeg = 8'b11111110;  //8
    4'b1001: SevenSeg = 8'b11110110;  //9
	 4'b1010: SevenSeg = 8'b11101111;  //A 10
	 4'b1011: SevenSeg = 8'b11111111;  //B 11
	 4'b1100: SevenSeg = 8'b10011101;  //C 12
	 4'b1101: SevenSeg = 8'b11111101;  //D 13
	 4'b1110: SevenSeg = 8'b10011111;  //E 14
	 4'b1111: SevenSeg = 8'b10001111;  //F 15
    default: SevenSeg = 8'b00000000;  //0 
endcase

assign {segA, segB, segC, segD, segE, segF, segG, segDP} = ~SevenSeg;
endmodule