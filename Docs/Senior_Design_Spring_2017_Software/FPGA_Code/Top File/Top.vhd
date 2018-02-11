----------------------------------------------------------------------------------
-- Top level file.
-- Design was used on Actel Igloo nano FPGA, using active low rst for whole design
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top is
port(
		scl 				: inout std_logic;
		sda 				: inout std_logic;
		clk 				: in    std_logic;
		rst 				: in    std_logic;
		busy				: out   std_logic
	);
end Top;

architecture RTL of Top is

	signal Read_Req			: std_logic;
	signal Data_Valid  		: std_logic;
	signal Di_ready 		: std_logic;
	signal Do_ready 		: std_logic;
	signal Do_valid 		: std_logic;
	signal Di_valid 		: std_logic;
	signal Init_curve 		: std_logic;
	signal Init_field 		: std_logic;
	signal Start 			: std_logic;
	signal Data_From_Master : std_logic_vector(15 downto 0);
	signal Data_To_Master	: std_logic_vector(15 downto 0);
	signal Di_data 			: std_logic_vector(15 downto 0);
	signal Do_data 			: std_logic_Vector(15 downto 0);
    signal Elgamal_calc     : std_logic;

BEGIN
-- Port Mapping
I2C: ENTITY work.I2C_slave(arch)
	 GENERIC MAP (SLAVE_ADDR => "0000011")-- Making slave address equal to three. This can be changed.
	 PORT MAP
			(
				clk 			 			=> clk,             -- <--
				rst 			 			=> rst,             -- <--
				scl 			 			=> scl,             -- <-->
				sda 			 			=> sda,             -- <-->
				data_to_master   			=> Data_To_Master,  -- <--
				data_from_master 			=> Data_From_Master,-- -->
				read_req 			 		=> Read_Req,        -- -->
				data_valid 		 			=> Data_Valid       -- -->
			);
			  
Inter:ENTITY work.Intermediate(arch)
	PORT MAP(
                elgamal_calc                => Elgamal_calc,
                --
				clk 						=> clk,             -- <--
				rst 						=> rst,             -- <--
				--! I2C I/O
				read_req 					=> Read_Req,        -- <--
				data_valid 	    			=> Data_Valid,      -- <--
				data_from_master 			=> Data_From_Master,-- <--
				data_to_master 				=> Data_To_Master,  -- -->
				--! ECC I/O
				di_ready 					=> Di_ready,        -- <--
				do_valid 					=> Do_valid,        -- <--
				do_data						=> Do_data,         -- <--
				di_data 					=> Di_data,         -- -->
				di_valid 					=> Di_valid,        -- -->
				do_ready 					=> Do_ready,        -- -->
				init_field 					=> Init_field,      -- -->
				init_curve 					=> Init_curve,      -- -->
				start 						=> Start            -- -->
			);
								
ECC:ENTITY work.ECC_Mult_Wrapper(structure)
	PORT MAP(
                elgamal_calc                => Elgamal_calc,
				clk 						=> clk,             -- <--
				rstn 						=> rst,             -- <--
				busy						=> busy,            -- -->
				di_data 					=> Di_data,         -- <--
				do_data						=> Do_data,         -- -->
				di_valid 					=> Di_valid,		-- <--
				do_valid 					=> Do_valid,		-- -->
				do_ready 					=> Do_ready,        -- <--
				di_ready 					=> Di_ready,        -- -->
				init_field 					=> Init_field,		-- <--
				init_curve 					=> Init_curve,		-- <--
				start 						=> Start			-- <--
			);
END RTL;

