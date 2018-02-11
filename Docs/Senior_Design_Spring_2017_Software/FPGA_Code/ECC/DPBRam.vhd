--------------------------------------------------------------------------------
--! @File       : DPBRam.vhd
--! @Brief      : Dual port 2^AddrWidth x DataWidth (depth x width) 
--!               block ram (embedded memory units in Xilinx)  
--!   ______   ________  _______    ______  
--!  /      \ /        |/       \  /      \ 
--! /$$$$$$  |$$$$$$$$/ $$$$$$$  |/$$$$$$  |
--! $$ |  $$/ $$ |__    $$ |__$$ |$$ | _$$/ 
--! $$ |      $$    |   $$    $$< $$ |/    |
--! $$ |   __ $$$$$/    $$$$$$$  |$$ |$$$$ |
--! $$ \__/  |$$ |_____ $$ |  $$ |$$ \__$$ |
--! $$    $$/ $$       |$$ |  $$ |$$    $$/ 
--!  $$$$$$/  $$$$$$$$/ $$/   $$/  $$$$$$/  
--!
--! @Author     : Panasayya Yalla
--! @Copyright  : Copyright© 2016 Cryptographic Engineering Research Group
--!               ECE Department, George Mason University Fairfax, VA, U.S.A.
--!               All rights Reserved.
--------------------------------------------------------------------------------
--!
--! Description         : Dual-port BLOCK RAM with synchronous read/write
--! DataWidth(integer)  : Generic parameter for setting width of the memory
--! AddrWidth(integer)  : Address bus width determining the depth of memory
--!                       2^AddrWidth 
--! wenA                : Write enable for port A      
--! wenB                : Write enable for port B      
--! enA                 : Read enable for port A      
--! enB                 : Read enable for port B      
--! setRstA             : Synchronous set/reset of port A
--! setRstb             : Synchronous set/reset of port B
--! addrA               : Address for port A
--! addrB               : Address for port B
--! dinA                : Input data for port A
--! dinB                : Input data for port B
--! doutA               : output data for port A
--! doutB               : output data for port B
--! Mode                : read_first_write_next
--!                       Place "Read data" line after "Write data" line for 
--!                       write_first_read_next 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity DPBRam is
    generic (   DataWidth   : integer:=32;
                AddrWidth   : integer:=8 
            ); 
    port    (
                clk         : in  std_logic;
                wenA        : in  std_logic_vector(DataWidth/8 -1 downto 0);
                --wenB        : in  std_logic; 
                --enA         : in  std_logic;
                --enB         : in  std_logic;
                --setRstA     : in  std_logic;
                --setRstB     : in  std_logic;
                addrA       : in  std_logic_vector(AddrWidth    -1 downto 0);
                addrB       : in  std_logic_vector(AddrWidth    -1 downto 0);
                dinA        : in  std_logic_vector(DataWidth    -1 downto 0); 
                --dinB        : in  std_logic_vector(DataWidth    -1 downto 0); 
                doutA       : out std_logic_vector(DataWidth    -1 downto 0);
                doutB       : out std_logic_vector(DataWidth    -1 downto 0)
            );
    --Xilinx attributes for using block rams
   -- attribute ram_style:string;
   -- attribute ram_style of DPBRam: entity is "block";

          
    end DPBRam;

architecture behavioral of DPBRam is
type ram_type is array (2**AddrWidth-1 downto 0) of std_logic_vector (DataWidth-1 downto 0); 
signal RAM : ram_type; 
begin
    ----------------------------------------------------------------------------
    --=========  PORT A    -----------------------------------------------------
    -----------READ/WRITE PORT--------------------------------------------------
    portA:  process (clk)
            begin
                if rising_edge(clk) then
                  for i in 0 to DataWidth/8-1 loop
                     if (wenA(i) = '1') then
                        RAM(to_integer(unsigned(addrA)))(7+8*i downto 8*i)
                        <= dinA(7+8*i downto 8*i);  --Write data
                     end if;
                  end loop;
                  doutA <= RAM(to_integer(unsigned(addrA)));--Read data
                  doutB <= RAM(to_integer(unsigned(addrB)));--Read data
                end if;
            end process;
    ----------------------------------------------------------------------------
    
--    ----------------------------------------------------------------------------
--    --=========  PORT B    -----------------------------------------------------
--    -----------READ/WRITE PORT--------------------------------------------------
--    portB:  process (clk)
--            begin
--                if rising_edge(clk) then
--                    if (wenB = '1') then
--                        RAM(conv_integer(unsigned(addrB))):= dinB;  --Write data
--                    end if;
--						  doutB <= RAM(conv_integer(unsigned(addrB)));--Read data
--					end if;
--            end process;
    ----------------------------------------------------------------------------    
end behavioral;
