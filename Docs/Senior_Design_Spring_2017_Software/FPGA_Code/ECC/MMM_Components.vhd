---------------------------------------------------------------------------------------------------
--
-- Title       : MM_Components
-- Design      : 
-- Author      : 
-- Company     :
--
---------------------------------------------------------------------------------------------------
--
-- File        : 
-- Generated   : 
-- From        : 
-- By          : 
--
---------------------------------------------------------------------------------------------------
--
-- Description : Component definitions for Montgomery multiplication implementations
--
---------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE MMM_Components IS

---------------------------------------------------------------------------------------------------
--  Common Components
---------------------------------------------------------------------------------------------------

	-- 1-Bit Register
	COMPONENT reg1e IS
		PORT
		(
			clk 	: IN 	STD_LOGIC;
			rstn  	: IN 	STD_LOGIC;
			R 		: IN 	STD_LOGIC;
			E 		: IN 	STD_LOGIC;
			Q 		: OUT 	STD_LOGIC
		);
	END COMPONENT;

	-- N-bit Register
	COMPONENT regne
		GENERIC ( N : INTEGER := 64 );
		PORT
		(
			clk 	: IN 	STD_LOGIC;
			rstn  	: IN 	STD_LOGIC;
			R 		: IN 	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			E 		: IN 	STD_LOGIC;
			Q 		: OUT 	STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
	END COMPONENT ;
	
	-- 1-Bit Shift Register
	COMPONENT shift_regne
		GENERIC ( N : INTEGER := 128 );
		PORT
		(
			clk 	: in 	STD_LOGIC;
			rstn	: in 	STD_LOGIC;
			R 		: in 	STD_LOGIC_VECTOR( N - 1 downto 0);
			E 		: in 	STD_LOGIC;
			S		: in	STD_LOGIC;
			Q 		: buffer STD_LOGIC_VECTOR( N - 1 downto 0)
		);
	END COMPONENT;
	
	
	
	-- Variable Bit Shift Left Register
	COMPONENT shiftLeft_regne
		GENERIC ( N : INTEGER := 128; SHIFT : INTEGER := 2 );
		PORT
		(
			clk 	: in 	STD_LOGIC;
			rstn	: in 	STD_LOGIC;
			R 		: in 	STD_LOGIC_VECTOR( N - 1 downto 0);
			E 		: in 	STD_LOGIC;
			S		: in	STD_LOGIC;
			Q 		: buffer STD_LOGIC_VECTOR( N - 1 downto 0)
		);
	END COMPONENT;
	
	
	-- Variable Bit Shift Right Register
	COMPONENT shiftne_regne
		GENERIC ( N : INTEGER := 128; SHIFT : INTEGER := 2 );
		PORT
		(
			clk 	: in 	STD_LOGIC;
			rstn	: in 	STD_LOGIC;
			R 		: in 	STD_LOGIC_VECTOR( N - 1 downto 0);
			E 		: in 	STD_LOGIC;
			S		: in	STD_LOGIC;
			Q 		: buffer STD_LOGIC_VECTOR( N - 1 downto 0)
		);
	END COMPONENT;
	
	-- Up-Counter That Counts From 0 to Modulus-1
	COMPONENT upcount
		GENERIC ( modulus : INTEGER := 64 );
		PORT
		(
			clk	: IN     STD_LOGIC;
			rstn 	: IN     STD_LOGIC;
			E		: IN 	 STD_LOGIC;
			L		: IN 	 STD_LOGIC;
			Q 		: OUT INTEGER RANGE 0 TO modulus-1
		);
	END COMPONENT;
	
---------------------------------------------------------------------------------------------------
--  Montgomery Multiplier Components
---------------------------------------------------------------------------------------------------

	-- Single Carry Save Adder
	COMPONENT csa
		PORT
		(
			a : IN STD_LOGIC;
			b : IN STD_LOGIC;
			c : IN STD_LOGIC;
			carry : OUT STD_LOGIC;
			save  : OUT STD_LOGIC
		);
	END COMPONENT;

	-- Single Full Adder
	COMPONENT fulladd
	PORT
		(
		a     : IN STD_LOGIC;
		b     : IN STD_LOGIC;
		cin     : IN STD_LOGIC;
		sum : OUT STD_LOGIC;
		cout  : OUT STD_LOGIC
		);
	END COMPONENT;

---------------------------------------------------------------------------------------------------
--  MM Specific Components
---------------------------------------------------------------------------------------------------

	COMPONENT PE_Type_D
		GENERIC ( W : INTEGER := 16 );
		PORT
		(
			clk			: in  STD_LOGIC;
			rstn			: in  STD_LOGIC;
			enable		: in  STD_LOGIC;
			Xi_in			: in STD_LOGIC;
			Y_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			M_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			SS_in			: in STD_LOGIC_VECTOR( W - 2 downto 0 );
			SC_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			c_in			: in STD_LOGIC;
			qi_out			: out STD_LOGIC;
			SS_prime_MSB_out: out STD_LOGIC;
			SS_out			: out STD_LOGIC_VECTOR( W - 2 downto 0 );
			SC_out			: out STD_LOGIC_VECTOR( W - 1 downto 1 );
			S0_precalc_out : out STD_LOGIC_VECTOR(2 downto 0);
			S1_precalc_out : out STD_LOGIC_VECTOR(2 downto 0)
		);
	END COMPONENT;
	
	COMPONENT PE_Type_E
		GENERIC ( W : INTEGER := 16 );
		PORT
		(	
			clk			: in  STD_LOGIC;
			rstn			: in  STD_LOGIC;
			enable		: in  STD_LOGIC;
			Xi_in			: in STD_LOGIC;
			Y_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			M_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			SS_in			: in STD_LOGIC_VECTOR( W - 2 downto 0 );
			SC_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			c_in			: in STD_LOGIC;
			qi_in			: in STD_LOGIC;
			SS_prime_MSB_out : out STD_LOGIC;
			SS_out			: out STD_LOGIC_VECTOR( W - 2 downto 0 );
			SC_out			: out STD_LOGIC_VECTOR( W - 1 downto 1 );
			S0_precalc_out : out STD_LOGIC_VECTOR(2 downto 0);
			S1_precalc_out : out STD_LOGIC_VECTOR(2 downto 0)

		);
	END COMPONENT;

	COMPONENT PE_Type_F
		GENERIC ( W : INTEGER := 16 );
		PORT
		(
			clk			: in  STD_LOGIC;
			rstn			: in  STD_LOGIC;
			enable		: in  STD_LOGIC;
			Xi_in			: in STD_LOGIC;
			Y_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			M_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			SS_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			SC_in			: in STD_LOGIC_VECTOR( W - 1 downto 0 );
			c_in			: in STD_LOGIC;
			qi_in			: in STD_LOGIC;
			SS_prime_MSB_out: out STD_LOGIC;
			SS_out			: out STD_LOGIC_VECTOR( W     downto 0 );
			SC_out			: out STD_LOGIC_VECTOR( W - 1 downto 0 )
		);
	END COMPONENT;
	
	
	COMPONENT MMM_Datapath
		GENERIC( K : INTEGER := 1024; W : INTEGER := 16 );
		PORT
		(
			clk		: in  STD_LOGIC;
			rstn		: in  STD_LOGIC;
			load    	: in  STD_LOGIC;
			enable	    : in  STD_LOGIC;
			field_size  : in  STD_LOGIC_VECTOR( 2           downto 0 );
			X_in   	    : in  STD_LOGIC_VECTOR( (K - 1) downto 0);
			Y_in   	    : in  STD_LOGIC_VECTOR( (K - 1) downto 0);
			M_in   	    : in  STD_LOGIC_VECTOR( (K - 1) downto 0);
			write		: out STD_LOGIC;
			S_out	    : out STD_LOGIC_VECTOR( (K - 1) downto 0);
			C_out : out STD_LOGIC
		);
	END COMPONENT;
---------------------------------------------------------------------------------------------------
--  End Of Component List
---------------------------------------------------------------------------------------------------

END MMM_Components;
