`timescale 1ns / 1ps

module MainActivity(
   input CLK,					//clock signal
   output [11:0] COLOUR_OUT,//bit patterns for colour that goes to VGA port
   output HS,					//Horizontal Synch signal that goes into VGA port
   output VS,					//Vertical Synch signal that goes into VGA port
	input SCK,
	input SSEL,
	input MOSI,
	output MISO
	);
	
	assign clk = CLK;
	
	reg DOWNCOUNTER = 0;		//need a downcounter to 25MHz
	parameter pic = 14'd14400;	//overall there are 6400 pixels
	parameter picX = 7'd120;
	parameter picY = 7'd120;
	
	//Downcounter to 25MHz		
	always @(posedge CLK)begin     
		DOWNCOUNTER <= ~DOWNCOUNTER;	//Slow down the counter to 25MHz
	end
	
	reg [11:0] COLOUR_IN;
	// reg [11:0] COLOUR_DATA [0:pic-1];
	reg [13:0] STATE;
	wire TrigRefresh;			//Trigger gives a pulse when displayed refreshed
	wire [9:0] ADDRH;			//wire for getting Horizontal pixel value
	wire [8:0] ADDRV;			//wire for getting vertical pixel value
	
	//VGA Interface gets values of ADDRH & ADDRV and by puting COLOUR_IN, gets valid output COLOUR_OUT
	//Also gets a trigger, when the screen is refreshed
	VGAInterface VGA(
				.CLK(CLK),
			   .COLOUR_IN (COLOUR_IN),
				.COLOUR_OUT(COLOUR_OUT),
				.HS(HS),
				.VS(VS),
				.REFRESH(TrigRefresh),
				.ADDRH(ADDRH),
				.ADDRV(ADDRV),
				.DOWNCOUNTER(DOWNCOUNTER)
			);
	// places picture at middle of screen
	reg signed [10:0]X = 10'd280; // 280
	reg signed [9:0]Y = 9'd200; // 200

	// assign STATE = (ADDRH-X)*picY+ADDRV-Y;
	
	// assign STATE = ADDRH*ADDRV;

	always @(posedge CLK) 
	begin
		if (ADDRH>=X && ADDRH<X+picX && ADDRV>=Y && ADDRV<Y+picY)
			begin
			COLOUR_IN <= data_out[11:0];
			STATE = (ADDRH-X)*picY+ADDRV-Y;
			end
		else
			COLOUR_IN <= 12'hFFF;
	end
	
	/**********************************************************************/
	
// sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;  
always @(posedge clk) 
SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  
always @(posedge clk) 
SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
reg [1:0] MOSIr;  
always @(posedge clk) 
MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];

// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
reg [3:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [15:0] byte_data_received;

always @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 4'b0000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 4'b0001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[14:0], MOSI_data};
  end
end

always @(posedge clk) 
	byte_received <= SSEL_active && SCK_risingedge && (bitcnt==4'b1111);

reg [14:0] address;
always @(posedge clk) 
if(byte_received)
	begin
		wren = 1'b1;
		address = address + 15'd1;
		data_in <= byte_data_received;
		if(address == pic)
			address = 15'b000000000000000;
	end
else 
	begin
		wren = 1'b0;
	end


reg [15:0] data_in;
reg wren;
wire [15:0] data_out;
	
ram r1 (
	.data(data_in),
	.inclock(clk),
	.outclock(clk),
	.rdaddress(STATE),
	.wraddress(address),
	.wren(wren),
	.q(data_out)
);
	

reg [7:0] byte_data_sent;

reg [7:0] cnt;
always @(posedge clk) 
	if(SSEL_startmessage) 
		cnt<=cnt+8'h1;  // count the messages

always @(posedge clk)
if(SSEL_active)
begin
  if(SSEL_startmessage)
    byte_data_sent <= cnt;  // first byte sent in a message is the message count
  else
  if(SCK_fallingedge)
  begin
    if(bitcnt==3'b000)
      byte_data_sent <= 8'h000;  // after that, we send 0s
    else
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};
  end
end

assign MISO = byte_data_sent[7];  // send MSB first

endmodule
