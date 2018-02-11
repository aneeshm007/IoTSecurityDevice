-------------------------------------------------------------------------------
--! @file       reg1e.vhd
--! @brief      1-bit register with active low reset
--!
--! @author     Ahmad Salman
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------		

LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY reg1e IS
	PORT (
		clk 	: IN 	STD_LOGIC;
		rstn  	: IN 	STD_LOGIC;
		R 		: IN 	STD_LOGIC;
		E 		: IN 	STD_LOGIC;
		Q 		: OUT 	STD_LOGIC
	);
END reg1e;

ARCHITECTURE Behavior OF reg1e IS	
BEGIN
	PROCESS(clk, rstn)
		BEGIN
			IF rstn = '0' THEN
				Q <= '0';
			ELSIF (clk'EVENT AND clk = '1')  THEN
				IF E = '1' THEN
					Q <= R ;
				END IF;
			END IF ;			
	END PROCESS ;
END Behavior ;
