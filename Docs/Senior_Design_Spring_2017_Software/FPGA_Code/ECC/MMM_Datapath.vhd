-------------------------------------------------------------------------------
--! @file       MMM_Datapath.vhd
--! @brief      MMM Datapath
--!
--! @author     Ahmad Salman
--! @translator Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.MMM_Components.all;

entity MMM_Datapath is
    generic( K : integer := 528; W : integer := 16; PE_COUNT: integer := 4);
    port (
        clk             : in  std_logic;
        rstn            : in  std_logic;
        load            : in  std_logic;
        ld_x            : in  std_logic;
        ld_ym           : in  std_logic;
        enable          : in  std_logic;
        field_size      : in  std_logic_vector( 2     downto 0);
        x_in            : in  std_logic_vector( W - 1 downto 0);
        y_in            : in  std_logic_vector( W - 1 downto 0);
        m_in            : in  std_logic_vector( W - 1 downto 0);
        wr              : out std_logic;
        ym_ctrl         : out std_logic;
        en_out          : out std_logic;
        s_out           : out std_logic_vector( W - 1 downto 0);
        c_out           : out std_logic
    );
end MMM_Datapath;

architecture behavioral of MMM_Datapath is
    CONSTANT CTR_WIDTH      : integer := 14-PE_COUNT/4;
    CONSTANT E              : INTEGER := (K / W);
    ------------------
    -- Type Defines --
    ------------------
    type ARRAY_PE_YM     is array (PE_COUNT - 1 downto 0) of std_logic_vector(W - 1 downto 0);
    type ARRAY_PE_X      is array (PE_COUNT - 1 downto 0) of std_logic_vector((W / PE_COUNT) - 1 downto 0);
    type t_s_wbitm1      is array (0 to PE_COUNT)         of std_logic_vector(W - 2 downto 0);
    type t_ce_array      is array (0 to PE_COUNT)         of std_logic_vector(1 downto 0);
    type array_s_shift   is array (0 to E - PE_COUNT - 1) of std_logic_vector(W - 2 downto 0);
    type array_ce_shift  is array (0 to E - PE_COUNT - 1) of std_logic_vector(1 downto 0);
    -----------------------
    -- Execution Signals --
    -----------------------
    signal qi_reg_in, qi_reg_out                            : std_logic_vector( PE_COUNT - 1 downto 0 );

    signal S_shift_reg_in, S_shift_reg_out                  : std_logic_vector(((W - 1) * (E - PE_COUNT)) -1 downto 0);
    signal swbitm1_array_out                                : array_s_shift;

    signal ce_shift_reg_in, ce_shift_reg_out                : std_logic_vector((2 * (E - PE_COUNT)) -1 downto 0);
    signal ce_array_out                                     : array_ce_shift;

    signal S_bit_zero_shift_reg_in, S_bit_zero_shift_reg_out: std_logic_vector((E - PE_COUNT) -1 downto 0);
    signal S_word_MSB, Sfinal_bit_zero,sel_Sout_MSB         : std_logic;
    signal ce_bit0_reg, ce_bit1_reg                         : std_logic;
    signal ce0final, ce1final                               : std_logic;

    signal Smux0_out, Smux1_out, Smux2_out, Smux3_out       : std_logic_vector (W - 2 downto 0);
    signal cemux0_out, cemux1_out, cemux2_out, cemux3_out   : std_logic_vector (1 downto 0);
    signal Sbit0mux0_out, Sbit0mux1_out                     : std_logic;
    signal Sbit0mux2_out, Sbit0mux3_out                     : std_logic;
    signal d_f_mux_out                                      : std_logic;
    signal decode                                           : std_logic_vector(3 downto 0);
    signal Y_array_out, M_array_out                         : ARRAY_PE_YM;
    signal XShift_in, XShift_out                            : ARRAY_PE_X;
    signal Xi                                               : std_logic_vector (PE_COUNT - 1 downto 0);

    signal YShift_reg_in, YShift_reg_out                    : std_logic_vector((PE_COUNT * W) - 1 downto 0);
    signal MShift_reg_in, MShift_reg_out                    : std_logic_vector((PE_COUNT * W) - 1 downto 0);
    signal S_final_out                                      : std_logic_vector( W - 1 downto 0 );
    signal ce_array                                         : t_ce_array;
    signal s_wbitm1                                         : t_s_wbitm1;
    signal S_wbitm1_reg, Sfinal_wbitm1                      : std_logic_vector(W - 2 downto 0);
    signal s_bit_zero                                       : std_logic_vector(0 to PE_COUNT);
    signal xreg0_enable                                     : std_logic;

    ---------------------
    -- Control Signals --
    ---------------------
    signal ZI_ZERO, ZI_MP_LASTROUND, SEND_OUTPUT            : std_logic;
    signal CI                                               : std_logic_vector(CTR_WIDTH  -1 downto 0);
    signal last_round                                       : unsigned(CTR_WIDTH  -1 downto 0);
    signal first_output                                     : unsigned(CTR_WIDTH  -1 downto 0);
    signal calc_d_reg_out                                   : std_logic_vector(E              -1 downto 0);
    signal is_first                                         : std_logic;
begin
    ---------------------------------------------------------------------------------------------------
    -- Execution Unit Architecture                                                                                                                                   --
    ---------------------------------------------------------------------------------------------------

    -- Split X into individual signals per PE unit
    SPLIT_X_GENERATE_1: FOR i in 0 to PE_COUNT - 1 GENERATE
        SPLIT_X_GENERATE_2: FOR j in 0 to ((W / PE_COUNT) - 1) GENERATE
            XShift_in(i)(j) <= X_in((j * PE_COUNT) + i);
        END GENERATE;
    END GENERATE;

    -- Add registers and signals for storing values of X for each PE
    X_REG_GENERATE: FOR i in 0 to PE_COUNT - 1 GENERATE
        X_REG_PE: shift_regne
        GENERIC MAP( N => (W / PE_COUNT))
        PORT MAP(clk => clk, rstn => rstn, R => XShift_in(i) , E => LD_X,
                 S => calc_d_reg_out(E-2-i), Q => XShift_out(i) );

        --! Shift register input is split X values for this PE unit
        ASSIGN_XI0_GENERATE: if i = 0 GENERATE
            REG0_Xi: reg1e
            PORT MAP(clk => clk, rstn => rstn, R => XShift_out(i)(0), E => xreg0_enable, Q => Xi(i) );
        END GENERATE;
        ASSIGN_XI_GENERATE: if i > 0 GENERATE
            REG_Xi: reg1e
            PORT MAP(clk => clk, rstn => rstn, R => XShift_out(i)(0), E => calc_d_reg_out(E-1-i), Q => Xi(i) );
        END GENERATE;
    END GENERATE;

    xreg0_enable <= calc_d_reg_out(E - 1) and enable;

    --! Add shift registers and logic for Y and M inputs for PE units
    YShift_reg_in <= Y_in &  YShift_reg_out((PE_COUNT * W) - 1 downto W);
    MShift_reg_in <= M_in &  MShift_reg_out((PE_COUNT * W) - 1 downto W);

    Y_SHIFT_REG: shiftne_regne
    GENERIC MAP( N => ((PE_COUNT * W) ), SHIFT => W )
    PORT MAP(clk => clk, rstn => rstn, R => YShift_reg_in, E => LD_YM, S => enable, Q => YShift_reg_out );

    M_SHIFT_REG: shiftne_regne
    GENERIC MAP( N => ((PE_COUNT * W) ), SHIFT => W )
    PORT MAP(clk => clk, rstn => rstn, R => MShift_reg_in, E => LD_YM, S => enable, Q => MShift_reg_out );

    PE_YM_ARRAY_GENERATE: FOR i in 0 to PE_COUNT - 1  GENERATE
        Y_array_out(PE_COUNT-1-i) <= YShift_reg_out( ((W * (i + 1)) - 1) downto (W * i) );
        M_array_out(PE_COUNT-1-i) <= MShift_reg_out( ((W * (i + 1)) - 1) downto (W * i) );
    END GENERATE;

    REG_qi: regne
    GENERIC MAP( N => PE_COUNT)
    PORT MAP(clk => clk, rstn => rstn, R => qi_reg_in, E => enable, Q => qi_reg_out );

    -- Add PE units
    process(clk)
    begin
        if rising_edge(clk) then
            if (load = '1') then
                is_first <= '1';
            elsif (calc_d_reg_out(E-1) = '1') then
                is_first <= '0';
            end if;
        end if;
    end process;

    s_wbitm1(0)   <= (others => '0') when is_first = '1' else Smux3_out;
    s_bit_zero(0) <= '0'             when is_first = '1' else Sbit0mux3_out;
    ce_array(0)   <= "00"            when is_first = '1' else cemux3_out;

    PE_GENERATE: FOR i in 0 to PE_COUNT - 1 GENERATE
        PE_UNIT: entity work.pe
        GENERIC MAP( W => W )
        PORT MAP (
            clk             => clk,
            rstn            => rstn,
            enable          => enable,
            Xi_in           => Xi(i),
            Y_in            => Y_array_out(i),
            M_in            => M_array_out(i),
            S_in            => S_wbitm1(i),
            ce_in           => ce_array(i),
            qi_in           => qi_reg_out(i),
            S_next_bit_zero => S_bit_zero(i),

            sel_d           => calc_d_reg_out(E-2-i),
            sel_f           => calc_d_reg_out(E-1-i),

            qi_out          => qi_reg_in(i),
            ce_out          => ce_array(i+1),
            S_bit_zero      => S_bit_zero(i+1),
            S_out           => S_wbitm1(i+1)
        );
    END GENERATE;

    -- Add shift registers and logic for Swbitm1, ce and S_bit_zero inputs for PE units
    S_shift_reg_in (((W - 1) * (E - PE_COUNT -  22))  - 1 downto                                0) <=  S_shift_reg_out(((W - 1) * (E - PE_COUNT -  23)) - 1 downto                                0) & S_wbitm1(PE_COUNT);
    S_shift_reg_in (((W - 1) * (E - PE_COUNT -  19))  - 1 downto ((W - 1) * (E - PE_COUNT -  22))) <=  S_shift_reg_out(((W - 1) * (E - PE_COUNT -  20)) - 1 downto ((W - 1) * (E - PE_COUNT -  22))) & Smux0_out         ;
    S_shift_reg_in (((W - 1) * (E - PE_COUNT -  10))  - 1 downto ((W - 1) * (E - PE_COUNT -  19))) <=  S_shift_reg_out(((W - 1) * (E - PE_COUNT -  11)) - 1 downto ((W - 1) * (E - PE_COUNT -  19))) & Smux1_out         ;
    S_shift_reg_in (((W - 1) * (E - PE_COUNT      ))  - 1 downto ((W - 1) * (E - PE_COUNT -  10))) <=  S_shift_reg_out(((W - 1) * (E - PE_COUNT -   1)) - 1 downto ((W - 1) * (E - PE_COUNT -  10))) & Smux2_out         ;

    Smux0_out <= swbitm1_array_out(E - PE_COUNT -  25) when decode (0) = '1' else swbitm1_array_out(E - PE_COUNT -  23);
    Smux1_out <= swbitm1_array_out(E - PE_COUNT -  22) when decode (1) = '1' else swbitm1_array_out(E - PE_COUNT -  20);
    Smux2_out <= swbitm1_array_out(E - PE_COUNT -  19) when decode (2) = '1' else swbitm1_array_out(E - PE_COUNT -  11);
    Smux3_out <= swbitm1_array_out(E - PE_COUNT -  10) when decode (3) = '1' else swbitm1_array_out(E - PE_COUNT -   1);

    ce_shift_reg_in (((2) * (E - PE_COUNT -  22)) - 1 downto                            0) <=  ce_shift_reg_out(((2) * (E - PE_COUNT -  23)) - 1 downto                            0) & ce_array(PE_COUNT);
    ce_shift_reg_in (((2) * (E - PE_COUNT -  19)) - 1 downto ((2) * (E - PE_COUNT -  22))) <=  ce_shift_reg_out(((2) * (E - PE_COUNT -  20)) - 1 downto ((2) * (E - PE_COUNT -  22))) & cemux0_out        ;
    ce_shift_reg_in (((2) * (E - PE_COUNT -  10)) - 1 downto ((2) * (E - PE_COUNT -  19))) <=  ce_shift_reg_out(((2) * (E - PE_COUNT -  11)) - 1 downto ((2) * (E - PE_COUNT -  19))) & cemux1_out        ;
    ce_shift_reg_in (((2) * (E - PE_COUNT      )) - 1 downto ((2) * (E - PE_COUNT -  10))) <=  ce_shift_reg_out(((2) * (E - PE_COUNT -   1)) - 1 downto ((2) * (E - PE_COUNT -  10))) & cemux2_out        ;

    cemux0_out <= ce_array_out(E - PE_COUNT -  25) when decode (0) = '1' else ce_array_out(E - PE_COUNT -  23);
    cemux1_out <= ce_array_out(E - PE_COUNT -  22) when decode (1) = '1' else ce_array_out(E - PE_COUNT -  20);
    cemux2_out <= ce_array_out(E - PE_COUNT -  19) when decode (2) = '1' else ce_array_out(E - PE_COUNT -  11);
    cemux3_out <= ce_array_out(E - PE_COUNT -  10) when decode (3) = '1' else ce_array_out(E - PE_COUNT -   1);

    S_bit_zero_shift_reg_in((E - PE_COUNT -  22) - 1 downto                    0) <=  S_bit_zero_shift_reg_out((E - PE_COUNT -  23) - 1 downto                    0) & S_bit_zero(PE_COUNT);
    S_bit_zero_shift_reg_in((E - PE_COUNT -  19) - 1 downto (E - PE_COUNT -  22)) <=  S_bit_zero_shift_reg_out((E - PE_COUNT -  20) - 1 downto (E - PE_COUNT -  22)) & Sbit0mux0_out       ;
    S_bit_zero_shift_reg_in((E - PE_COUNT -  10) - 1 downto (E - PE_COUNT -  19)) <=  S_bit_zero_shift_reg_out((E - PE_COUNT -  11) - 1 downto (E - PE_COUNT -  19)) & Sbit0mux1_out       ;
    S_bit_zero_shift_reg_in((E - PE_COUNT      ) - 1 downto (E - PE_COUNT -  10)) <=  S_bit_zero_shift_reg_out((E - PE_COUNT -   1) - 1 downto (E - PE_COUNT -  10)) & Sbit0mux2_out       ;

    Sbit0mux0_out <= S_bit_zero_shift_reg_out(E - PE_COUNT -  25) when decode (0) = '1' else S_bit_zero_shift_reg_out(E - PE_COUNT -  23);
    Sbit0mux1_out <= S_bit_zero_shift_reg_out(E - PE_COUNT -  22) when decode (1) = '1' else S_bit_zero_shift_reg_out(E - PE_COUNT -  20);
    Sbit0mux2_out <= S_bit_zero_shift_reg_out(E - PE_COUNT -  19) when decode (2) = '1' else S_bit_zero_shift_reg_out(E - PE_COUNT -  11);
    Sbit0mux3_out <= S_bit_zero_shift_reg_out(E - PE_COUNT -  10) when decode (3) = '1' else S_bit_zero_shift_reg_out(E - PE_COUNT -   1);

    S_SHIFT_REG: shiftne_regne
    GENERIC MAP( N => ((E - PE_COUNT) * (W - 1) ), SHIFT => W - 1 )
    PORT MAP(clk => clk, rstn => rstn, R => S_Shift_reg_in, E => enable, S => enable, Q => S_Shift_reg_out );

    CE_SHIFT_REG: shiftne_regne
    GENERIC MAP( N => ((E - PE_COUNT) * 2 ), SHIFT => 2 )
    PORT MAP(clk => clk, rstn => rstn, R => ce_Shift_reg_in, E => enable, S => enable, Q => ce_Shift_reg_out );

    S_BIT_ZERO_SHIFT_REG: shiftne_regne
    GENERIC MAP( N => ((E - PE_COUNT) ), SHIFT => 1 )
    PORT MAP(clk => clk, rstn => rstn, R => s_bit_zero_Shift_reg_in, E => enable, S => enable, Q => s_bit_zero_Shift_reg_out );

    S_ARRAY_GENERATE: FOR i in 0 to E - PE_COUNT - 1 GENERATE
        swbitm1_array_out(i) <= S_Shift_reg_out( ((W - 1) * (i + 1)) - 1 downto ((W - 1) * i) );
        ce_array_out(i)      <= ce_Shift_reg_out( ((2) * (i + 1)) - 1 downto ((2) * i) );
    END GENERATE;

    with field_size select
    decode <= "1111" when "000",
              "1110" when "001",
              "1100" when "010",
              "1000" when "011",
              "0000" when others;

    Sfinal_wbitm1   <= S_wbitm1(1)    when field_size(2) = '1' else S_wbitm1(PE_COUNT);
    ce0final        <= ce_array(1)(0) when field_size(2) = '1' else ce_array(PE_COUNT)(0);
    ce1final        <= S_wbitm1(1)(9) when field_size(2) = '1' else ce_array(PE_COUNT)(1);
    Sfinal_bit_zero <= S_bit_zero(1)  when field_size(2) = '1' else S_bit_zero(PE_COUNT);

    sel_Sout_MSB <= calc_d_reg_out(E - 1 - 2) when field_size(2) = '1' else calc_d_reg_out(E - PE_COUNT - 2);

    S_word_REG: regne
    GENERIC MAP( N => (W - 1) )
    PORT MAP(clk => clk, rstn => rstn, R => Sfinal_wbitm1, E => enable, Q => S_wbitm1_reg);

    ce_bit_zero_REG: reg1e
    PORT MAP(clk => clk, rstn => rstn, R => ce0final, E => enable, Q => ce_bit0_reg);
    
    ce_bit_one_REG: reg1e
    PORT MAP(clk => clk, rstn => rstn, R => ce1final, E => enable, Q => ce_bit1_reg);

    S_final_out <=  S_word_MSB & S_wbitm1_reg;
    S_word_MSB <=  ce_bit0_reg when  sel_Sout_MSB = '1' else Sfinal_bit_zero;

    -- Output final Result and Carry
    S_out <= S_final_out;
    C_out <= ce_bit1_reg;

    ------------------
    -- Control Unit --
    ------------------
    -- Set the counter value for the amount of clock cycle needed to perform a full montegomery multiplication for each field size
    with field_size select
    last_round <= to_unsigned((192 +  ((192/PE_COUNT)   *(12 - PE_COUNT)) + PE_COUNT + 1), CTR_WIDTH) when "000",
                  to_unsigned((224 +  ((224/PE_COUNT)   *(14 - PE_COUNT)) + PE_COUNT + 1), CTR_WIDTH) when "001",
                  to_unsigned((256 +  ((256/PE_COUNT)   *(16 - PE_COUNT)) + PE_COUNT + 1), CTR_WIDTH) when "010",
                  to_unsigned((384 +  ((384/PE_COUNT)   *(24 - PE_COUNT)) + PE_COUNT + 1), CTR_WIDTH) when "011",
                  to_unsigned((521 + (((521/PE_COUNT)+1)*(33 - PE_COUNT)) + PE_COUNT + 1), CTR_WIDTH) when others;

    with field_size select
    first_output <= to_unsigned((192 +  ((192/PE_COUNT)   *(12 - PE_COUNT)) + PE_COUNT + 1) - 12, CTR_WIDTH) when "000",
                    to_unsigned((224 +  ((224/PE_COUNT)   *(14 - PE_COUNT)) + PE_COUNT + 1) - 14, CTR_WIDTH) when "001",
                    to_unsigned((256 +  ((256/PE_COUNT)   *(16 - PE_COUNT)) + PE_COUNT + 1) - 16, CTR_WIDTH) when "010",
                    to_unsigned((384 +  ((384/PE_COUNT)   *(24 - PE_COUNT)) + PE_COUNT + 1) - 24, CTR_WIDTH) when "011",
                    to_unsigned((521 + (((521/PE_COUNT)+1)*(33 - PE_COUNT)) + PE_COUNT + 1) - 33, CTR_WIDTH) when others;

    -- Add counter
    process(clk)
    begin
        if rising_edge(clk) then
            if (load = '1') then
                CI <= (others => '0');
            elsif (enable = '1') then
                CI <= std_logic_vector(unsigned(CI) + 1);
            end if;
        end if;
    end process;

    -- Add start and end of Montgomery Multiply signal
    ZI_ZERO <= '1' WHEN unsigned(CI) = 0 ELSE '0';
    ZI_MP_LASTROUND <= '1' WHEN unsigned(CI) = last_round ELSE '0';
    SEND_OUTPUT <= '1' WHEN unsigned(CI) = first_output ELSE '0';

    -- Enable signal to send the output
    REG_OUT_ENABLE: reg1e
    PORT MAP(clk => clk, rstn => rstn, R => '1', E => SEND_OUTPUT, Q => en_out );

    wr <= ZI_MP_LASTROUND;

    with field_size select
    d_f_mux_out <=  calc_d_reg_out(E - 12) when "000",
                    calc_d_reg_out(E - 14) when "001",
                    calc_d_reg_out(E - 16) when "010",
                    calc_d_reg_out(E - 24) when "011",
                    calc_d_reg_out(E - 33) when others;

    -- Add shift register to control the enable for X, queue size and type of task in PE
    process(clk)
    begin
        if rising_edge(clk) then
            if (load = '1') then
                calc_d_reg_out(E-1)          <= '1';
                calc_d_reg_out(E-2 downto 0) <= (others => '0');
            elsif (enable = '1') then
                calc_d_reg_out(E-1)          <= d_f_mux_out;
                calc_d_reg_out(E-2 downto 0) <= calc_d_reg_out(E-1 downto 1);
            end if;
        end if;
    end process;

    -- Control signal to Enable the shifting of Y_word and M_word
    with field_size select
    YM_ctrl <=  calc_d_reg_out(E - 11) when "000",
                calc_d_reg_out(E - 13) when "001",
                calc_d_reg_out(E - 15) when "010",
                calc_d_reg_out(E - 23) when "011",
                calc_d_reg_out(E - 32) when others;

end Behavioral;