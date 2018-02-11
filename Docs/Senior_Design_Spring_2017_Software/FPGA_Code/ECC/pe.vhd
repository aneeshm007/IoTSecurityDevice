-------------------------------------------------------------------------------
--! @file       pe.vhd
--! @brief      PE unit for LW ECC core
--!
--! @author     Ahmad Salman
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;
USE work.MMM_Components.all;

entity PE is
    GENERIC ( W : INTEGER := 16 );
    PORT (
        clk                 : in  STD_LOGIC;
        rstn                : in  STD_LOGIC;
        enable              : in  STD_LOGIC;
        Xi_in               : in  STD_LOGIC;
        Y_in                : in  STD_LOGIC_VECTOR( W - 1 downto 0 );
        M_in                : in  STD_LOGIC_VECTOR( W - 1 downto 0 );
        S_in                : in  STD_LOGIC_VECTOR( W - 2 downto 0 );
        ce_in               : in  STD_LOGIC_VECTOR( 1 downto 0);
        qi_in               : in  STD_LOGIC;
        S_next_bit_zero     : in  STD_LOGIC;
        sel_d               : in  STD_LOGIC;
        sel_f               : in  std_logic;

        qi_out              : out STD_LOGIC;
        ce_out              : out STD_LOGIC_VECTOR(1 downto 0);
        S_bit_zero          : out STD_LOGIC;
        S_out               : out STD_LOGIC_VECTOR( W - 2 downto 0 )
    );
end PE;

architecture Structural of PE  is
    signal qi_int                       : STD_LOGIC;
    signal parity                       : STD_LOGIC;
    signal Z, R                         : STD_LOGIC_VECTOR( W - 1 downto 0 );
    signal S_prime, S_word_select       : STD_LOGIC_VECTOR( W - 2 downto 0 );
    signal S0,S1                        : STD_LOGIC_VECTOR( W + 1 downto 0 );
    signal sel_f_r                      : std_logic;
    signal ce_sel                       : STD_LOGIC_VECTOR(1 downto 0);
    signal C_int                        : STD_LOGIC_VECTOR(1 downto 0);
    signal carry_out_s                  : STD_LOGIC_VECTOR(1 downto 0);
    signal S0_precalc_in, S1_precalc_in : STD_LOGIC_VECTOR(2 downto 0);
    signal S0_precalc_out,S1_precalc_out: STD_LOGIC_VECTOR(2 downto 0);
begin
    -- Determine contribution of Y
    Z <= Y_in WHEN Xi_in = '1' ELSE (OTHERS => '0');

    -- Determine contribution of M
    parity <= Z(0) xor S_in(0);
    qi_int <= parity WHEN sel_d = '1' ELSE qi_in;
    C_int <= "00" WHEN sel_d = '1' ELSE carry_out_s;
    R <= M_in WHEN qi_int = '1' ELSE (OTHERS => '0');
    ce_sel <= ce_in when sel_f = '1' else "01";
    S1 <= ('0' & ce_sel & S_in) + ("0000" & C_int) + ("00" & Z) + ("00" & R);
    S0 <= ("000" & S_in) + ("0000" & C_int) + ("00" & Z) + ("00" & R);
    S_prime <= S0(W-2 downto 0);
    S0_precalc_in <= S0(W+1 downto W-1);
    S1_precalc_in <= S1(W+1 downto W-1);

    -- Hook up determined parity to output
    qi_out <= qi_int;

    process(clk, rstn)
    begin
        if rstn = '0' then
            S1_precalc_out <= (others => '0');
            S0_precalc_out <= (others => '0');
            S_word_select  <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                S1_precalc_out <= S1_precalc_in;
                S0_precalc_out <= S0_precalc_in;
                S_word_select  <= S_prime;
                sel_f_r        <= sel_f;
            end if;
        end if;
    end process;

    -- Add array signals for combined SS/SC values and carry based on
    -- calculated LSB from PE#2 unit
    S_out <= S1_precalc_out(0) & S_word_select(W - 2 downto 1)
                WHEN S_next_bit_zero  = '1' or sel_f_r = '1'
                ELSE S0_precalc_out(0) & S_word_select(W - 2 downto 1);

    carry_out_s <= S1_precalc_out(2 downto 1)
                    WHEN S_next_bit_zero  = '1' or sel_f_r = '1'
                    ELSE S0_precalc_out(2 downto 1);

    ce_out    <= carry_out_s;
    S_bit_zero <= S_word_select(0);
end Structural;



