%read the image
I = imread('knuckles80.jpg');	
imshow(I);
		
%Extract RED, GREEN and BLUE components from the image
R = I(:,:,1);			
G = I(:,:,2);
B = I(:,:,3);

%make the numbers to be of double format for 
R = double(R);	
G = double(G);
B = double(B);

%Raise each member of the component by appropriate value. 
R = R.^(1/2); % 8 bits -> 4 bits
G = G.^(1/2); % 8 bits -> 4 bits
B = B.^(1/2); % 8 bits -> 4 bits

%tranlate to integer
R = uint16(R); % float -> uint16
G = uint16(G);
B = uint16(B);

%minus one cause sometimes conversion to integers rounds up the numbers wrongly
R = R-1; % 4 bits -> max value is 1111 (bin) -> 15 (dec)(hex)
G = G-1;
B = B-1; 

%shift bits and construct one Byte from 4 + 4 + 4 bits
G = bitshift(G, 4); % 4 << G (shift by 4 bits)
B = bitshift(B, 8); % 8 << B (shift by 8 bits)
COLOR = R+G+B;      % R + 4 << G + 8 << B

%save variable COLOR to a file in HEX format for the chip to read
fileID = fopen ('picture.list', 'w');
for i = 1:size(COLOR(:), 1)-1
    fprintf (fileID, '%X\n', COLOR(i)); % COLOR (dec) -> print to file (hex)
end
fprintf (fileID, '%X', COLOR(size(COLOR(:), 1))); % COLOR (dec) -> print to file (hex)
%save variable COLOR to a file in HEX format for the chip to read
fclose (fileID);

%translate to hex to see how many lines
COLOR_HEX = dec2hex(COLOR);
