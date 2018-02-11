--------------------------------------------------------------------------------------------------------
-- Used as the Receive/Transmit Unit, between I2C unit and ECC Core in order to faciliate communication.
-- States have been modified to support El-Gamal scheme,specifically the subtraction part using R and C.
--------------------------------------------------------------------------------------------------------
-- In order to be used just to perform scalar multiplication need to do the following:
-- 1) uncomment k value from ROM
-- 2) make rdptr range to go from 0 to 49 instead of 0 to 39
-- 3) comment the state Send_C, and uncomment the state sendkey. State will now go from Send_R to sendkey
-- 4) remove elgamal_calc associated values and signals here and in top file
-- 5) make microcontroller only send Value of R to perform scalar multiplication operation of kR

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity Intermediate is
port(
		clk 		        			: in    std_logic;
		rst 		        			: in    std_logic;
		--! I2C I/O
		read_req      			      	: in    std_logic;
        data_valid          			: in    std_logic;
        data_from_master    			: in    std_logic_vector(15 downto 0);
        data_to_master      			: out   std_logic_vector(15 downto 0);
        --! ECC I/O
        di_ready           		 		: in    std_logic;
        do_valid            			: in    std_logic;
        do_data             			: in    std_logic_vector(15 downto 0);
        di_data             			: out   std_logic_vector(15 downto 0);
        di_valid            			: out   std_logic;
        do_ready            			: out   std_logic;
        init_field          			: out   std_logic;
        init_curve          			: out   std_logic;
        start               			: out   std_logic;
		elgamal_calc					: out   std_logic
     );
end Intermediate;

architecture arch of Intermediate is

   -- ROM to hold parameter values as described in ECC document(ECC_LW_ug.pdf). Parameter values was obtained from NIST Test Vectors(NIST_Tests_w16.txt). Both files provided to us by Ahmad Salman
   -- 1) encode value
   -- 2) value of prime p
   -- 3) precomputed value of R^2 mod p
   -- 4) curve parameter a
   -- 5) k(optional)
   type Initialization is array (0 to 36) of std_logic_vector(15 downto 0);
    constant Initialize: Initialization :=
    (
        "0000000000000000",--0(Encode = 0)
		"1111111111111111",--1(beginning of p )
		"1111111111111111",--2
		"1111111111111111",--3
		"1111111111111111",--4
		"1111111111111110",--5
		"1111111111111111",--6
		"1111111111111111",--7
		"1111111111111111",--8
		"1111111111111111",--9
		"1111111111111111",--10
		"1111111111111111",--11
		"1111111111111111",--12(end of p)
		"0000000000000001",--13(beginning of R^2 mod p)
		"0000000000000000",--14
		"0000000000000000",--15
		"0000000000000000",--16
		"0000000000000010",--17
		"0000000000000000",--18
		"0000000000000000",--19
		"0000000000000000",--20
		"0000000000000001",--21
		"0000000000000000",--22
		"0000000000000000",--23
		"0000000000000000", --24(end of R^2 mod p)
		"1111111111111100",--25(beginning of curve parameter a)
		"1111111111111111",--26
		"1111111111111111",--27
		"1111111111111111",--28
		"1111111111111110",--29
		"1111111111111111",--30
		"1111111111111111",--31
		"1111111111111111",--32
		"1111111111111111",--33
		"1111111111111111",--34
		"1111111111111111",--35
		"1111111111111111" --36(end of curve parameter a)
--		"0000000000000001", --37 (beginning of k)
--      "0000000000000000", --38
--      "0000000000000000", --39
--      "0000000000000000", --40
--      "0000000000000000", --41
--      "0000000000000000", --42
--      "0000000000000000", --43
--      "0000000000000000", --44
--      "0000000000000000", --45
--      "0000000000000000", --46
--      "0000000000000000", --47
--      "0000000000000000"  --48 (end of k)   
	);

    -- State Machine 
    -- add sendkey if want to perform scalar multiplication
    type State_type is(init,send_R,send_C,receive,idle,readdata);
	signal state : State_type;
	-- Signals: temp variables & flags
	signal fieldtemp 			   : std_logic;
	signal curvetemp 			   : std_logic;
	signal starttemp 			   : std_logic;
	signal elgamal_calctemp 	   : std_logic;
	signal one_second_counter      : unsigned(3 downto 0);
    signal one_second_done_flag    : std_logic;
	signal DO_count 			   : std_logic_vector(4 downto 0);--ECC output count
    -- Array to hold data
    type ecc_data is array (0 to 23) of std_logic_vector(15 downto 0);
    signal ecc_data_output 		   : ecc_data;

begin

fieldtemp <= '1' when one_second_counter = "1001" else '0'; -- Assert fieldtemp
-- Process to wait a number of clock cycles before starting. 
-- Can choose any number of clock cycles
process(clk,rst)
begin
    if(rst = '0') then
        one_second_counter <=(others => '0');
        one_second_done_flag <= '0';
    elsif (rising_edge(clk)) then  
        if(one_second_done_flag = '1') then
            one_second_counter <= (others => '0');
        else
            if(one_second_counter = "1001") then
                one_second_done_flag <= '1';
                one_second_counter <= one_second_counter + 1;
            else
                one_second_counter <= one_second_counter + 1;
            end if;
        end if;
    end if;
end process;     
-- Process where appropriate data is sent to the ECC core depending on which state it is in
process(clk,rst)
variable rdptr : integer range 0 to 39;-- counter that goes through ROM indices
variable count : integer range 0 to 23;-- counter used to count number of ECC outputs
begin
    -- Initialize upon active low reset
	if(rst = '0') then
		rdptr     := 0;
        count     := 0;
		state     <= init;
        DO_count  <= (others => '0');
		curvetemp <= '0';
		starttemp <= '0';
		elgamal_calctemp    <= '0';
        ecc_data_output(0)  <= (others => '0');
        ecc_data_output(1)  <= (others => '0');
        ecc_data_output(2)  <= (others => '0');
        ecc_data_output(3)  <= (others => '0');
        ecc_data_output(4)  <= (others => '0');
        ecc_data_output(5)  <= (others => '0');
        ecc_data_output(6)  <= (others => '0');
        ecc_data_output(7)  <= (others => '0');
        ecc_data_output(8)  <= (others => '0');
        ecc_data_output(9)  <= (others => '0');
        ecc_data_output(10) <= (others => '0');
        ecc_data_output(11) <= (others => '0');
        ecc_data_output(12) <= (others => '0');
        ecc_data_output(13) <= (others => '0');
        ecc_data_output(14) <= (others => '0');
        ecc_data_output(15) <= (others => '0');
        ecc_data_output(16) <= (others => '0');
        ecc_data_output(17) <= (others => '0');
        ecc_data_output(18) <= (others => '0');
        ecc_data_output(19) <= (others => '0');
        ecc_data_output(20) <= (others => '0');
        ecc_data_output(21) <= (others => '0');
        ecc_data_output(22) <= (others => '0');
        ecc_data_output(23) <= (others => '0');

	elsif(rising_edge(clk)) then

		init_field   <= fieldtemp;
		init_curve   <= curvetemp;
		start 	     <= starttemp;
		elgamal_calc <= elgamal_calctemp;
			
		case state is
            -- State to Send Field and Curve Initialization values
			when init =>
				di_valid <= '1';
				if(di_ready = '1') then
					rdptr:= rdptr + 1;
					if(rdptr = 25) then
						curvetemp <= '1';-- Assert curvetemp
					end if;
					if(rdptr = 26) then
						curvetemp <= '0';
					end if;
					if(rdptr = 37) then
						state <= idle;
						rdptr:= rdptr - 1;
					end if;
				end if;
				di_data <= Initialize(rdptr);	
            -- After Initialization of field and curve, wait till microcontroller sends R value
			when idle =>
				di_valid <= '0';
				if(data_valid = '1') then-- wait for one dummy data before starting
                        starttemp <= '1';-- Assert starttemp
                        state <= send_R;
						elgamal_calctemp <= '1';-- Assert elgamal_calctemp
				end if;
			-- Receiving R value from microcontroller and sending it to ECC core	
			when send_R =>	
				if(data_valid = '1' and di_ready = '1') then
					di_valid <= '1';
					di_data <= data_from_master;
					count := count + 1;
				else
					di_valid <= '0';
				end if;
				if(count = 24) then
					count := 0;
					state <= send_C;
					di_valid <= '1';
				end if;		
			-- Receiving C value from microcontroller and sending it to ECC core	
			when Send_C =>
				if(data_valid = '1' and di_ready = '1') then
					di_valid <= '1';
					di_data <= data_from_master;
					count := count + 1;
				else
					di_valid <= '0';
				end if;
				if(count = 24) then
					rdptr:= 36;
					count:= 0;
					state <= receive;
					starttemp <= '0';
					elgamal_calctemp <= '0';
					do_ready <= '1';
				end if;
                
            -----------------------------------------------------   
            -- when sendkey =>
				-- if(di_ready = '1') then
					-- rdptr:= rdptr + 1;
					-- if(rdptr = 49) then
						-- rdptr := 36;-- 
						-- state <= receive;
						-- starttemp <= '0';
						-- do_ready <= '1';
					-- end if;
				-- end if;
				-- di_data <= Initialize(rdptr);   
            --------------------------------------------------------
            
			-- Store ECC core output values into array 	
			when receive =>
                if(do_valid = '1' and Do_count = "10111") then
                    ecc_data_output(23) <= do_data;
                    Do_count <= (others => '0');
                    state <= readdata;
                elsif(do_valid = '1') then
                    ecc_data_output(to_integer(unsigned(Do_count))) <= do_data;
                    Do_count <= std_logic_vector(unsigned(Do_count) + 1);
                end if;
            -- Upon microcontroller starting receive mode, will send data back to master from array which holds ECC core outputs      
            when readdata =>
                if(read_req = '1' and Do_count = "10111") then
                    data_to_master <= ecc_data_output(23);
                    Do_count <= (others => '0');
                    state <= idle;-- Go back to idle after finish reading and wait till these operations want to be performed again
                    do_ready <= '0';
                elsif(read_req = '1') then
                    data_to_master <= ecc_data_output(to_integer(unsigned(Do_count)));
                    Do_count <= std_logic_vector(unsigned(Do_count) + 1);
                end if;

			end case;
		end if;
	end process;
end arch;
