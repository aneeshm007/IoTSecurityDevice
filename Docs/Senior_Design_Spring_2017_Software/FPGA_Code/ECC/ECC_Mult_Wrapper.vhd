-------------------------------------------------------------------------------
--! @file       ECC_Mult_Wrapper.vhd
--! @brief      Entity wrapper for ECC Multiplier.
--!             This unit also serves as an example integeration.
--!
--! @author     Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ECC_Mult_Wrapper is
    generic (
        G_N                 : integer := 5;
        G_W                 : integer := 16
    );
    port (
        --! Global
        rstn                : in  std_logic;
        clk                 : in  std_logic;
        --! Controls
        elgamal_calc        : in std_logic;
        start               : in  std_logic;
        init_field          : in  std_logic;
        init_curve          : in  std_logic;
        di_valid            : in  std_logic;
        di_data             : in  std_logic_vector(G_W           -1 downto 0);
        do_ready            : in  std_logic;
        busy                : out std_logic;
        di_ready            : out std_logic;
        do_valid            : out std_logic;
        do_data             : out std_logic_vector(G_W           -1 downto 0)
    );
end ECC_Mult_Wrapper;

architecture structure of ECC_Mult_Wrapper is
    type ram1_addr_type is array (0 to 2**(4+G_N)-1)
        of std_logic_vector(G_W-1 downto 0);
    type ram2_addr_type is array (0 to 2**(2+G_N)-1)
        of std_logic_vector(G_W-1 downto 0);
    signal ram1                 : ram1_addr_type;
    signal ram2                 : ram2_addr_type;

    signal ram1_data_a          : std_logic_vector(G_W          -1 downto 0);
    signal ram1_data_b          : std_logic_vector(G_W          -1 downto 0);
    signal ram1_addr_a          : std_logic_vector(G_N+4        -1 downto 0);
    signal ram1_addr_b          : std_logic_vector(G_N+4        -1 downto 0);
    signal ram1_wr_data         : std_logic_vector(G_W          -1 downto 0);
    signal ram1_wr_en           : std_logic_vector(G_W/8        -1 downto 0);
    --! RAM-2
    signal ram2_data_a          : std_logic_vector(G_W          -1 downto 0);
    signal ram2_data_b          : std_logic_vector(G_W          -1 downto 0);
    signal ram2_addr_a          : std_logic_vector(G_N+2        -1 downto 0);
    signal ram2_addr_b          : std_logic_vector(G_N+2        -1 downto 0);
    signal ram2_wr_data         : std_logic_vector(G_W          -1 downto 0);
    signal ram2_wr_en           : std_logic_vector(G_W/8        -1 downto 0);
    --!
      COMPONENT DPBRam
         generic (   DataWidth   : integer:=32;
                     AddrWidth   : integer:=8 
                  ); 
         PORT(
               clk         : in  std_logic;
               wenA        : in  std_logic_vector(DataWidth/8 -1 downto 0);
               addrA       : in  std_logic_vector(AddrWidth    -1 downto 0);
               addrB       : in  std_logic_vector(AddrWidth    -1 downto 0);
               dinA        : in  std_logic_vector(DataWidth    -1 downto 0); 
               doutA       : out std_logic_vector(DataWidth    -1 downto 0);
               doutB       : out std_logic_vector(DataWidth    -1 downto 0)
            );
      END COMPONENT;
    
    
    
    --! =======================================================================
    --! Signal aliases for debugging
    --! =======================================================================
    type ram_alias_type is array (0 to 2**(G_N))
        of std_logic_vector(G_W-1 downto 0);

    impure function get_alias(addr: integer) return ram_alias_type is
        variable ret    : ram_alias_type;
        variable tmp    : std_logic_vector(G_W         -1 downto 0);
        variable vaddr  : integer;
    begin
        for i in 0 to (2**G_N)-1 loop
            if (addr > 15) then
                ret(i) := ram2((addr-16)*(512/G_W)+i);
            else
                ret(i) := ram1((addr- 0)*(512/G_W)+i);
            end if;
        end loop;
        vaddr := addr;
        if (vaddr > 15) then
            vaddr := vaddr-16;
        end if;
        if (G_W = 64) then
            vaddr := vaddr/2;
        end if;
        if (addr > 15) then
            tmp := ram2( 3*(512/G_W)+vaddr);
        else
            tmp := ram1(15*(512/G_W)+vaddr);
        end if;
        if (G_W = 64) then
            if ((addr mod 2) = 1) then
                tmp(31 downto 0) := tmp(63 downto 32);
            else
                tmp(31 downto 0) := tmp(31 downto 0);
            end if;
            tmp(63 downto 32) := (others => 'X');
        end if;
        ret(2**G_N) := tmp;
        return ret;
    end function get_alias;

    signal ram1_00 : ram_alias_type;
    signal ram1_01 : ram_alias_type;
    signal ram1_02 : ram_alias_type;
    signal ram1_03 : ram_alias_type;
    signal ram1_04 : ram_alias_type;
    signal ram1_05 : ram_alias_type;
    signal ram1_06 : ram_alias_type;
    signal ram1_07 : ram_alias_type;
    signal ram1_08 : ram_alias_type;
    signal ram1_09 : ram_alias_type;
    signal ram1_10 : ram_alias_type;
    signal ram1_11 : ram_alias_type;
    signal ram1_12 : ram_alias_type;
    signal ram1_13 : ram_alias_type;
    signal ram1_14 : ram_alias_type;
    signal ram2_01 : ram_alias_type;
    signal ram2_02 : ram_alias_type;
    signal ram2_03 : ram_alias_type;
begin
    --! =======================================================================
    --! ECC Multiplier Core
    --! =======================================================================
    uut:
    entity work.ECC_Mult_LW_Top
        generic map (
            G_N             => G_N          ,
            G_W             => G_W
        )
        port map (
            --! Global
            rstn            => rstn         ,
            clk             => clk          ,
            --! Controls
            elgamal_calc    => elgamal_calc,
            start           => start        ,
            init_field      => init_field   ,
            init_curve      => init_curve   ,
            di_valid        => di_valid     ,
            di_data         => di_data      ,
            do_ready        => do_ready     ,
            busy            => busy         ,
            di_ready        => di_ready     ,
            do_valid        => do_valid     ,
            do_data         => do_data      ,
            --! RAM-1
            ram1_data_a     => ram1_data_a  ,
            ram1_data_b     => ram1_data_b  ,
            ram1_addr_a     => ram1_addr_a  ,
            ram1_addr_b     => ram1_addr_b  ,
            ram1_wr_data    => ram1_wr_data ,
            ram1_wr_en      => ram1_wr_en   ,
            --! RAM-2
            ram2_data_a     => ram2_data_a  ,
            ram2_data_b     => ram2_data_b  ,
            ram2_addr_a     => ram2_addr_a  ,
            ram2_addr_b     => ram2_addr_b  ,
            ram2_wr_data    => ram2_wr_data ,
            ram2_wr_en      => ram2_wr_en
        );

    --! =======================================================================
    --! External RAMs
    --! =======================================================================
--    process(clk)
--    begin
--        if rising_edge(clk) then
--            --! RAM-1
--            for i in 0 to G_W/8-1 loop
--                if (ram1_wr_en(i) = '1') then
--                    ram1(to_integer(unsigned(ram1_addr_a)))(7+8*i downto 8*i)
--                        <= ram1_wr_data(7+8*i downto 8*i);
--                end if;
--            end loop;
--            ram1_data_a <= ram1(to_integer(unsigned(ram1_addr_a)));
--            ram1_data_b <= ram1(to_integer(unsigned(ram1_addr_b)));
--            --! RAM-2
--            for i in 0 to G_W/8-1 loop
--                if (ram2_wr_en(i) = '1') then
--                    ram2(to_integer(unsigned(ram2_addr_a)))(7+8*i downto 8*i)
--                        <= ram2_wr_data(7+8*i downto 8*i);
--                end if;
--            end loop;
--            ram2_data_a <= ram2(to_integer(unsigned(ram2_addr_a)));
--            ram2_data_b <= ram2(to_integer(unsigned(ram2_addr_b)));
--        end if;
--    end process;
      EXRAM1: DPBRam 
               generic map (
                           DataWidth   => G_W          ,
                           AddrWidth   => G_N+4
                           )
               PORT MAP(
                           clk         => clk,
                           wenA        => ram1_wr_en,
                           addrA       => ram1_addr_a,
                           addrB       => ram1_addr_b,
                           dinA        => ram1_wr_data,
                           doutA       => ram1_data_a,
                           doutB       => ram1_data_b
                        );   
      EXRAM2: DPBRam 
               generic map (
                           DataWidth   => G_W          ,
                           AddrWidth   => G_N+2
                           )
               PORT MAP(
                           clk         => clk,
                           wenA        => ram2_wr_en,
                           addrA       => ram2_addr_a,
                           addrB       => ram2_addr_b,
                           dinA        => ram2_wr_data,
                           doutA       => ram2_data_a,
                           doutB       => ram2_data_b
                        );   
      
      
   


-- synthesis translate off
    --! Alias for debugging
    process(ram1, ram2)
    begin
        ram1_00 <= get_alias(0);
        ram1_01 <= get_alias(1);
        ram1_02 <= get_alias(2);
        ram1_03 <= get_alias(3);
        ram1_04 <= get_alias(4);
        ram1_05 <= get_alias(5);
        ram1_06 <= get_alias(6);
        ram1_07 <= get_alias(7);
        ram1_08 <= get_alias(8);
        ram1_09 <= get_alias(9);
        ram1_10 <= get_alias(10);
        ram1_11 <= get_alias(11);
        ram1_12 <= get_alias(12);
        ram1_13 <= get_alias(13);
        ram1_14 <= get_alias(14);
        ram2_01 <= get_alias(16);
        ram2_02 <= get_alias(17);
        ram2_03 <= get_alias(18);
    end process;
-- synthesis translate on
end architecture structure;
