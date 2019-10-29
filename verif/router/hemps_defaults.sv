localparam RADDR = 8'b00010001;

localparam BL = 0;  // bottom-left, center, and right
localparam BC  = 1;
localparam BR  = 2;
localparam CL  = 3; // center 
localparam CC  = 4;
localparam CRX = 5; 
localparam TL  = 6;
localparam TC  = 7;
localparam TR  = 8;

localparam NPORT = 5;
localparam EAST = 0;
localparam WEST = 1;
localparam NORTH = 2;
localparam SOUTH = 3;
localparam LOCAL = 4;

localparam TAM_FLIT = 16;
localparam METADEFLIT = TAM_FLIT/2;
localparam QUARTOFLIT = TAM_FLIT/4;

localparam TAM_BUFFER = 4;
localparam TAM_BUFFER_DMNI = 16;
localparam TAM_POINTER = 2;

typedef logic[2:0]  reg3;
typedef logic[7:0]  reg8;
typedef logic[29:0] reg30;
typedef logic[31:0] reg32; 

typedef logic[(NPORT-1):0] regNport;
typedef logic[(TAM_FLIT-1) :0] regflit;
typedef logic[(METADEFLIT-1) :0] regmetadeflit;
typedef logic[(QUARTOFLIT-1) :0] regquartoflit;
typedef logic[(TAM_POINTER-1):0] pointer;

typedef regflit[0:(TAM_BUFFER-1)] buff;
typedef regflit [0:(TAM_BUFFER_DMNI-1)] buff_dmni;
typedef reg3[(NPORT-1):0] arrayNport_reg3;

typedef reg8[(NPORT-1) : 0] arrayNport_reg8;
typedef regflit[(NPORT-1) : 0] arrayNport_regflit;

typedef regflit[3:0] arrayNPORT_1_regflit;

//================================================================================
// FUNCTIONS
//================================================================================
//XY routing 
function integer route(regmetadeflit addr_flit, regmetadeflit r_addr);
	regquartoflit x, y, rx, ry;
	x = addr_flit[(METADEFLIT-1) : (QUARTOFLIT-1)];
	y = addr_flit[(QUARTOFLIT-1) : 0];
	rx = r_addr[(METADEFLIT-1) : (QUARTOFLIT-1)];
	ry = r_addr[(QUARTOFLIT-1) : 0];

	if(x == rx && y == ry) begin
		return LOCAL;
	end

	if(x == rx) begin
		if(y > ry) begin
			return NORTH;
		end else begin
			return SOUTH;
		end
	end

	if(x > rx) begin
		return EAST;
	end else begin
		return WEST;
	end
endfunction

//generate a packet of X+2 flits
function automatic void gen_pkt(regflit addr, regflit size, ref regflit data_v[]);

	data_v = new[size + 2];
	data_v[0] = addr;
	data_v[1] = size;

	for(int i = 0; i < size; i++) begin
		data_v[i + 2] = i;
	end
endfunction

parameter regflit  MAX_REGFLIT_VAL  = 2 ** $bits(regflit)  - 1;
parameter regNport MAX_REGNPORT_VAL = 2 ** $bits(regNport) - 1;





