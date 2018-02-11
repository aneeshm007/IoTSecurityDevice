-------------------------------------------------------------------------------
--! @file       Mem_Ctrl_LW.vhd
--! @brief      Memory controller module.
--!
--!             Priority based access controller for the RAM module with
--!             the following priority level (lower is higher):
--!                 MC  : 0
--!                 MAS : 1
--!                 MMM : 2
--!
--!             Below are the operands index mapping and its respective
--!             location of RAM1 and RAM2
--!              Op | RAM | Index | Intended variable
--!             -----------------------------------------
--!              0  | 1    | 0     |   R^2 mod M
--!              1  | 1    | 1     |   a / aR(aZ_p^4)
--!              2  | 1    | 2     |   x / xR(X_p) / x'R / x'
--!              3  | 1    | 3     |   y / yR(Y_p) / y'R / y'
--!              4  | 1    | 4     |   R(Z_p)
--!              5  | 1    | 5     |   X_q
--!              6  | 1    | 6     |   Y_q
--!              7  | 1    | 7     |   Z_q
--!              8  | 1    | 8     |   aZ_q^4
--!              9  | 1    | 9     |   T_1 / 1
--!              10 | 1    | 10    |   T_2 / Z_q^(-1)R
--!              11 | 1    | 11    |   T_3 / Z_q^(-2)R / Z_q^(-3)R
--!              12 | 1    | 12    |   T_4
--!              13 | 1    | 13    |   T_5
--!              14 | 1    | 14    |   T_6
--!              15 | 1    | 15    |   partial of RAM1
--!              16 | 2    | 0     |   M
--!              17 | 2    | 1     |   2 / M-2
--!              18 | 2    | 2     |   k
--!              19 | 2    | 3     |   partial of RAM2

--!
--! @author     Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mem_Ctrl_LW is
    generic (
        G_N                 : integer := 3;
        G_W                 : integer := 64
    );
    port (
        --! Global
        rstn                : in  std_logic;
        clk                 : in  std_logic;
        --! MAS
        mas_lock_req        : in  std_logic;
        mas_lock_release    : in  std_logic;
        mas_lock_ack        : out std_logic;
        mas_op_a            : in  std_logic_vector(5            -1 downto 0);
        mas_op_b            : in  std_logic_vector(5            -1 downto 0);
        mas_op_dest         : in  std_logic_vector(5            -1 downto 0);
        mas_idx_a           : in  std_logic_vector(G_N+1        -1 downto 0);
        mas_idx_b           : in  std_logic_vector(G_N+1        -1 downto 0);
        mas_idx_dest        : in  std_logic_vector(G_N+1        -1 downto 0);
        mas_idx_wr          : in  std_logic;
        mas_data_dest       : in  std_logic_vector(G_W          -1 downto 0);
        --! MMM
        mmm_lock_req        : in  std_logic;
        mmm_lock_release    : in  std_logic;
        mmm_lock_ack        : out std_logic;
        mmm_op_a            : in  std_logic_vector(5            -1 downto 0);
        mmm_op_b            : in  std_logic_vector(5            -1 downto 0);
        mmm_op_dest         : in  std_logic_vector(5            -1 downto 0);
        mmm_idx_a           : in  std_logic_vector(G_N+1        -1 downto 0);
        mmm_idx_b           : in  std_logic_vector(G_N+1        -1 downto 0);
        mmm_idx_dest        : in  std_logic_vector(G_N+1        -1 downto 0);
        mmm_idx_wr          : in  std_logic;
        mmm_data_dest       : in  std_logic_vector(G_W          -1 downto 0);
        --! MC
        field_size          : in  std_logic_vector(3            -1 downto 0);
        field_words         : in  std_logic_vector(G_N+1        -1 downto 0);
        mc_lock_req         : in  std_logic;
        mc_lock_release     : in  std_logic;
        mc_lock_ack         : out std_logic;
        mc_op_a             : in  std_logic_vector(5            -1 downto 0);
        mc_op_b             : in  std_logic_vector(5            -1 downto 0);
        mc_op_dest          : in  std_logic_vector(5            -1 downto 0);
        mc_idx_a            : in  std_logic_vector(G_N+1        -1 downto 0);
        mc_idx_b            : in  std_logic_vector(G_N+1        -1 downto 0);
        mc_idx_dest         : in  std_logic_vector(G_N+1        -1 downto 0);
        mc_idx_wr           : in  std_logic;
        mc_data_dest        : in  std_logic_vector(G_W          -1 downto 0);
        --! Memory data
        data_a              : out std_logic_vector(G_W          -1 downto 0);
        data_b              : out std_logic_vector(G_W          -1 downto 0);
        --! RAM-1
        ram1_data_a         : in  std_logic_vector(G_W          -1 downto 0);
        ram1_data_b         : in  std_logic_vector(G_W          -1 downto 0);
        ram1_addr_a         : out std_logic_vector(G_N+4        -1 downto 0);
        ram1_addr_b         : out std_logic_vector(G_N+4        -1 downto 0);
        ram1_wr_data        : out std_logic_vector(G_W          -1 downto 0);
        ram1_wr_en          : out std_logic_vector(G_W/8        -1 downto 0);
        --! RAM-2
        ram2_data_a         : in  std_logic_vector(G_W          -1 downto 0);
        ram2_data_b         : in  std_logic_vector(G_W          -1 downto 0);
        ram2_addr_a         : out std_logic_vector(G_N+2        -1 downto 0);
        ram2_addr_b         : out std_logic_vector(G_N+2        -1 downto 0);
        ram2_wr_data        : out std_logic_vector(G_W          -1 downto 0);
        ram2_wr_en          : out std_logic_vector(G_W/8        -1 downto 0)
    );
end entity Mem_Ctrl_LW;

architecture structure of Mem_Ctrl_LW is
    --! =======================================================================
    --! Internal port signals
    --! =======================================================================
    signal sig_mas_op_a             : std_logic_vector(5        -1 downto 0);
    signal sig_mas_op_b             : std_logic_vector(5        -1 downto 0);
    signal sig_mas_op_dest          : std_logic_vector(5        -1 downto 0);
    signal sig_mas_lock_req         : std_logic;
    signal sig_mas_lock_ack         : std_logic;
    signal sig_mas_lock_release     : std_logic;
    signal sig_mas_idx_a            : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mas_idx_b            : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mas_idx_dest         : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mas_idx_wr           : std_logic;
    signal sig_mas_data_dest        : std_logic_vector(G_W      -1 downto 0);
    --! MMM
    signal sig_mmm_op_a             : std_logic_vector(5        -1 downto 0);
    signal sig_mmm_op_b             : std_logic_vector(5        -1 downto 0);
    signal sig_mmm_op_dest          : std_logic_vector(5        -1 downto 0);
    signal sig_mmm_lock_req         : std_logic;
    signal sig_mmm_lock_ack         : std_logic;
    signal sig_mmm_lock_release     : std_logic;
    signal sig_mmm_idx_a            : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mmm_idx_b            : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mmm_idx_dest         : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mmm_idx_wr           : std_logic;
    signal sig_mmm_data_dest        : std_logic_vector(G_W      -1 downto 0);
    --! MC
    signal sig_mc_op_a              : std_logic_vector(5        -1 downto 0);
    signal sig_mc_op_b              : std_logic_vector(5        -1 downto 0);
    signal sig_mc_op_dest           : std_logic_vector(5        -1 downto 0);
    signal sig_mc_lock_req          : std_logic;
    signal sig_mc_lock_ack          : std_logic;
    signal sig_mc_lock_release      : std_logic;
    signal sig_mc_idx_a             : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mc_idx_b             : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mc_idx_dest          : std_logic_vector(G_N+1    -1 downto 0);
    signal sig_mc_idx_wr            : std_logic;
    signal sig_mc_data_dest         : std_logic_vector(G_W      -1 downto 0);
    --! Memory data
    signal sig_data_a               : std_logic_vector(G_W      -1 downto 0);
    signal sig_data_b               : std_logic_vector(G_W      -1 downto 0);
    --! RAM-1
    signal sig_ram1_data_a          : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram1_data_b          : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram1_addr_a          : std_logic_vector(G_N+4    -1 downto 0);
    signal sig_ram1_addr_b          : std_logic_vector(G_N+4    -1 downto 0);
    signal sig_ram1_wr_addr         : std_logic_vector(G_N+4    -1 downto 0);
    signal sig_ram1_wr_data         : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram1_wr_hi           : std_logic;
    signal sig_ram1_wr_lo           : std_logic;
    --! RAM-2
    signal sig_ram2_data_a          : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram2_data_b          : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram2_addr_a          : std_logic_vector(G_N+2    -1 downto 0);
    signal sig_ram2_addr_b          : std_logic_vector(G_N+2    -1 downto 0);
    signal sig_ram2_wr_addr         : std_logic_vector(G_N+2    -1 downto 0);
    signal sig_ram2_wr_data         : std_logic_vector(G_W      -1 downto 0);
    signal sig_ram2_wr_hi           : std_logic;
    signal sig_ram2_wr_lo           : std_logic;

    --! =======================================================================
    --! Internal signals/registers
    --! =======================================================================
    constant ZEROS          : std_logic_vector(G_W      -1 downto 0)
        := (others => '0');
    constant MODULE_MC      : std_logic_vector(2        -1 downto 0) := "00";
    constant MODULE_MMM     : std_logic_vector(2        -1 downto 0) := "01";
    constant MODULE_MAS     : std_logic_vector(2        -1 downto 0) := "10";

    signal reg_zero_a       : std_logic;
    signal reg_zero_b       : std_logic;
    signal reg_mem_busy     : std_logic;
    signal reg_mem_sel      : std_logic_vector(1 downto 0);
    signal sig_mem_release  : std_logic;
    signal sig_op_a         : std_logic_vector(5        -1 downto 0);
    signal sig_op_b         : std_logic_vector(5        -1 downto 0);
    signal sig_op_dest      : std_logic_vector(5        -1 downto 0);
    signal idx_a            : std_logic_vector(G_N+1    -1 downto 0);
    signal idx_b            : std_logic_vector(G_N+1    -1 downto 0);
    signal idx_dest         : std_logic_vector(G_N+1    -1 downto 0);
    signal idx_wr           : std_logic;
    signal data_dest        : std_logic_vector(G_W      -1 downto 0);
    signal lower_addr_op_a  : std_logic_vector(G_N      -1 downto 0);
    signal lower_addr_op_b  : std_logic_vector(G_N      -1 downto 0);
    signal lower_addr_dest  : std_logic_vector(G_N      -1 downto 0);
    signal reg_op_a_msb     : std_logic;
    signal reg_op_b_msb     : std_logic;
    --! 64-bit related signals
    signal reg_op_a_lsb     : std_logic;
    signal reg_op_b_lsb     : std_logic;
    signal reg_idx_a_msb    : std_logic;
    signal reg_idx_b_msb    : std_logic;
begin
    --! =======================================================================
    --! I/O to/from internal signals
    --! =======================================================================
    --! MAS
    sig_mas_op_a         <= mas_op_a                                         ;
    sig_mas_op_b         <= mas_op_b                                         ;
    sig_mas_op_dest      <= mas_op_dest                                      ;
    sig_mas_lock_req     <= mas_lock_req                                     ;
    sig_mas_lock_release <= mas_lock_release                                 ;
    sig_mas_idx_a        <= mas_idx_a                                        ;
    sig_mas_idx_b        <= mas_idx_b                                        ;
    sig_mas_idx_dest     <= mas_idx_dest                                     ;
    sig_mas_idx_wr       <= mas_idx_wr                                       ;
    sig_mas_data_dest    <= mas_data_dest                                    ;
    mas_lock_ack         <= sig_mas_lock_ack                                 ;
    --! MMM
    sig_mmm_op_a         <= mmm_op_a                                         ;
    sig_mmm_op_b         <= mmm_op_b                                         ;
    sig_mmm_op_dest      <= mmm_op_dest                                      ;
    sig_mmm_lock_req     <= mmm_lock_req                                     ;
    sig_mmm_lock_release <= mmm_lock_release                                 ;
    sig_mmm_idx_a        <= mmm_idx_a                                        ;
    sig_mmm_idx_b        <= mmm_idx_b                                        ;
    sig_mmm_idx_dest     <= mmm_idx_dest                                     ;
    sig_mmm_idx_wr       <= mmm_idx_wr                                       ;
    sig_mmm_data_dest    <= mmm_data_dest                                    ;
    mmm_lock_ack         <= sig_mmm_lock_ack                                 ;
    --! MC
    sig_mc_op_a          <= mc_op_a                                          ;
    sig_mc_op_b          <= mc_op_b                                          ;
    sig_mc_op_dest       <= mc_op_dest                                       ;
    sig_mc_lock_req      <= mc_lock_req                                      ;
    sig_mc_lock_release  <= mc_lock_release                                  ;
    sig_mc_idx_a         <= mc_idx_a                                         ;
    sig_mc_idx_b         <= mc_idx_b                                         ;
    sig_mc_idx_dest      <= mc_idx_dest                                      ;
    sig_mc_idx_wr        <= mc_idx_wr                                        ;
    sig_mc_data_dest     <= mc_data_dest                                     ;
    mc_lock_ack          <= sig_mc_lock_ack                                  ;
    --! Memory data
    data_a               <= sig_data_a                                       ;
    data_b               <= sig_data_b                                       ;
    --! RAM-1
    sig_ram1_data_a      <= ram1_data_a                                      ;
    sig_ram1_data_b      <= ram1_data_b                                      ;
    ram1_addr_a          <= sig_ram1_wr_addr
                            when sig_ram1_wr_hi = '1' or sig_ram1_wr_lo = '1'
                            else sig_ram1_addr_a                             ;
    ram1_addr_b          <= sig_ram1_addr_b                                  ;
    ram1_wr_data         <= sig_ram1_wr_data                                 ;
    ram1_wr_en(G_W/8-1 downto G_W/8-(G_W/8)/2) <= (others => sig_ram1_wr_hi) ;
    ram1_wr_en(G_W/8-(G_W/8)/2-1 downto     0) <= (others => sig_ram1_wr_lo) ;
    --! RAM-2
    sig_ram2_data_a      <= ram2_data_a                                      ;
    sig_ram2_data_b      <= ram2_data_b                                      ;
    ram2_addr_a          <= sig_ram2_wr_addr
                            when sig_ram2_wr_hi = '1' or sig_ram2_wr_lo = '1'
                            else sig_ram2_addr_a                             ;
    ram2_addr_b          <= sig_ram2_addr_b                                  ;
    ram2_wr_data         <= sig_ram2_wr_data                                 ;
    ram2_wr_en(G_W/8-1 downto G_W/8-(G_W/8)/2) <= (others => sig_ram2_wr_hi) ;
    ram2_wr_en(G_W/8-(G_W/8)/2-1 downto     0) <= (others => sig_ram2_wr_lo) ;

    --! =======================================================================
    --! Data selection
    --! =======================================================================
    g_dout_wn64: if G_W/=64 generate
        signal sel_a : std_logic_vector(1 downto 0);
        signal sel_b : std_logic_vector(1 downto 0);
    begin
        sel_a(1) <= reg_zero_a;
        sel_a(0) <= reg_op_a_msb;
        sel_b(1) <= reg_zero_b;
        sel_b(0) <= reg_op_b_msb;

        with sel_a select
        sig_data_a <=   sig_ram1_data_a when "00",
                        sig_ram2_data_a when "01",
                        (others => '0') when others;
        with sel_b select
        sig_data_b <=   sig_ram1_data_b when "00",
                        sig_ram2_data_b when "01",
                        (others => '0') when others;
    end generate;
    g_dout_w64: if G_W=64 generate
        signal sel_hi_a : std_logic_vector(1 downto 0);
        signal sel_hi_b : std_logic_vector(1 downto 0);
        signal sel_lo_a : std_logic_vector(2 downto 0);
        signal sel_lo_b : std_logic_vector(2 downto 0);
    begin
        sel_hi_a <= (reg_idx_a_msb or reg_zero_a) & reg_op_a_msb;
        sel_hi_b <= (reg_idx_b_msb or reg_zero_b) & reg_op_b_msb;

        with sel_hi_a select
        sig_data_a(G_W-1 downto G_W/2) <=
            sig_ram1_data_a(G_W-1 downto G_W/2) when "00",
            sig_ram2_data_a(G_W-1 downto G_W/2) when "01",
            (others => '0')                     when others;
        with sel_hi_b select
        sig_data_b(G_W-1 downto G_W/2) <=
            sig_ram1_data_b(G_W-1 downto G_W/2) when "00",
            sig_ram2_data_b(G_W-1 downto G_W/2) when "01",
            (others => '0')                     when others;

        sel_lo_a <= reg_zero_a
            & (reg_idx_a_msb and reg_op_a_lsb)
            & reg_op_a_msb;
        sel_lo_b <= reg_zero_b
            & (reg_idx_b_msb and reg_op_b_lsb)
            & reg_op_b_msb;

        with sel_lo_a select
        sig_data_a(G_W/2-1 downto 0) <=
            sig_ram1_data_a(G_W/2-1 downto 0)     when "000",
            sig_ram2_data_a(G_W/2-1 downto 0)     when "001",
            sig_ram1_data_a(G_W-1   downto G_W/2) when "010",
            sig_ram2_data_a(G_W-1   downto G_W/2) when "011",
            (others => '0')                       when others;

        with sel_lo_b select
        sig_data_b(G_W/2-1 downto 0) <=
            sig_ram1_data_b(G_W/2-1 downto 0)     when "000",
            sig_ram2_data_b(G_W/2-1 downto 0)     when "001",
            sig_ram1_data_b(G_W-1   downto G_W/2) when "010",
            sig_ram2_data_b(G_W-1   downto G_W/2) when "011",
            (others => '0')                       when others;
    end generate;
    --! Data input
    g_data_wn64: if G_W/=64 generate
        sig_ram1_wr_data <= ZEROS(G_W-1 downto 9) & data_dest(8 downto 0)
            when field_size = "100" and idx_dest(G_N) = '1' else
            data_dest;
        sig_ram2_wr_data <= sig_ram1_wr_data;
    end generate;
    g_data_w64: if G_W=64 generate
        signal data_dest2 : std_logic_vector(G_W           -1 downto 0);
        signal sel_input  : std_logic_vector(2             -1 downto 0);
    begin
        sel_input(1) <=
            '1' when field_size = "100" and idx_dest(G_N) = '1' else '0';
        sel_input(0) <=
            '1' when field_size = "001" and idx_dest(2 downto 0) = "011"
            else '0';
        with sel_input select
        data_dest2 <=
            ZEROS(63 downto 32) & data_dest(31 downto 0) when "01",
            ZEROS(63 downto  9) & data_dest( 8 downto 0) when "10",
            data_dest when others;

        sig_ram1_wr_data(G_W  -1 downto G_W/2) <=
            data_dest2(G_W  -1 downto G_W/2)
            when idx_dest(G_N) = '0' else
            data_dest2(G_W/2-1 downto 0);
        sig_ram1_wr_data(G_W/2-1 downto 0) <= data_dest2(G_W/2-1 downto 0);
        sig_ram2_wr_data <= sig_ram1_wr_data;
    end generate;
    --! Address
    g_addr_w16: if G_W=16 generate   --! G_N = 5
        lower_addr_op_a <= '0' & sig_op_a(3 downto 0);
        lower_addr_op_b <= '0' & sig_op_b(3 downto 0);
        lower_addr_dest <= '0' & sig_op_dest(3 downto 0);
    end generate;
    g_addr_w32: if G_W=32 generate   --! G_N = 4
        lower_addr_op_a <= sig_op_a(3 downto 0);
        lower_addr_op_b <= sig_op_b(3 downto 0);
        lower_addr_dest <= sig_op_dest(3 downto 0);
    end generate;
    g_addr_w64: if G_W=64 generate   --! G_N = 3
        lower_addr_op_a <= sig_op_a(3 downto 1);
        lower_addr_op_b <= sig_op_b(3 downto 1);
        lower_addr_dest <= sig_op_dest(3 downto 1);
    end generate;

    sig_ram1_addr_a  <=
        sig_op_a(3 downto 0) & idx_a(G_N-1 downto 0)
        when idx_a(G_N) = '0' else
        "1111" & lower_addr_op_a;
    sig_ram1_addr_b  <=
        sig_op_b(3 downto 0)    & idx_b(G_N-1 downto 0)
        when idx_b(G_N) = '0' else
        "1111" & lower_addr_op_b;
    sig_ram2_addr_a  <=
        sig_op_a(1 downto 0)    & idx_a(G_N-1 downto 0)
        when idx_a(G_N) = '0' else
        "11" & lower_addr_op_a;
    sig_ram2_addr_b  <=
        sig_op_b(1 downto 0)    & idx_b(G_N-1 downto 0)
        when idx_b(G_N) = '0' else
        "11" & lower_addr_op_b;
    sig_ram1_wr_addr <=
        sig_op_dest(3 downto 0) & idx_dest(G_N-1 downto 0)
        when idx_dest(G_N) = '0' else
        "1111" & lower_addr_dest;
    sig_ram2_wr_addr <=
        sig_op_dest(1 downto 0) & idx_dest(G_N-1 downto 0)
        when idx_dest(G_N) = '0' else
        "11" & lower_addr_dest;
    --! Write controls
    g_wr_wn64: if G_W/=64 generate
        sig_ram1_wr_hi <= idx_wr and not sig_op_dest(4);
        sig_ram1_wr_lo <= sig_ram1_wr_hi;
        sig_ram2_wr_hi <= idx_wr and     sig_op_dest(4);
        sig_ram2_wr_lo <= sig_ram2_wr_hi;
    end generate;
    g_wr_w64: if G_W=64 generate
        sig_ram1_wr_hi <=
            idx_wr and not sig_op_dest(4)
            when idx_dest(G_N) = '0' else
            idx_wr and not sig_op_dest(4) and     sig_op_dest(0);
        sig_ram1_wr_lo <=
            idx_wr and not sig_op_dest(4)
            when idx_dest(G_N) = '0' else
            idx_wr and not sig_op_dest(4) and not sig_op_dest(0);
        sig_ram2_wr_hi <=
            idx_wr and     sig_op_dest(4)
            when idx_dest(G_N) = '0' else
            idx_wr and     sig_op_dest(4) and     sig_op_dest(0);
        sig_ram2_wr_lo <=
            idx_wr and     sig_op_dest(4)
            when idx_dest(G_N) = '0' else
            idx_wr and     sig_op_dest(4) and not sig_op_dest(0);
    end generate;
    --! Operands, write and data selection
    with reg_mem_sel select
    idx_a <= sig_mas_idx_a    when MODULE_MAS,
                sig_mmm_idx_a    when MODULE_MMM,
                sig_mc_idx_a     when others;
    with reg_mem_sel select
    idx_b <= sig_mas_idx_b    when MODULE_MAS,
                sig_mmm_idx_b    when MODULE_MMM,
                sig_mc_idx_b     when others;
    with reg_mem_sel select
    idx_dest <= sig_mas_idx_dest    when MODULE_MAS,
                sig_mmm_idx_dest    when MODULE_MMM,
                sig_mc_idx_dest     when others;
    with reg_mem_sel select
    idx_wr  <=  sig_mas_idx_wr      when MODULE_MAS,
                sig_mmm_idx_wr      when MODULE_MMM,
                sig_mc_idx_wr       when others;
    with reg_mem_sel select
    data_dest <= sig_mas_data_dest  when MODULE_MAS,
                 sig_mmm_data_dest  when MODULE_MMM,
                 sig_mc_data_dest   when others;
    with reg_mem_sel select
    sig_op_a <= sig_mas_op_a when MODULE_MAS,
                sig_mmm_op_a when MODULE_MMM,
                sig_mc_op_a when others;
    with reg_mem_sel select
    sig_op_b <= sig_mas_op_b when MODULE_MAS,
                sig_mmm_op_b when MODULE_MMM,
                sig_mc_op_b when others;
    with reg_mem_sel select
    sig_op_dest <=  sig_mas_op_dest when MODULE_MAS,
                    sig_mmm_op_dest when MODULE_MMM,
                    sig_mc_op_dest when others;

    --! =======================================================================
    --! Status registers
    --! =======================================================================
    process(clk, rstn)
    begin
        if (rstn = '0') then
            reg_mem_busy <= '0';
            reg_mem_sel  <= MODULE_MC;
        elsif rising_edge(clk) then
            reg_op_a_msb  <= sig_op_a(4);
            reg_op_b_msb  <= sig_op_b(4);
            reg_op_a_lsb  <= sig_op_a(0);
            reg_op_b_lsb  <= sig_op_b(0);
            reg_idx_a_msb <= idx_a(G_N);
            reg_idx_b_msb <= idx_b(G_N);

            if (idx_a > field_words) then
                reg_zero_a <= '1';
            else
                reg_zero_a <= '0';
            end if;
            if (idx_b > field_words) then
                reg_zero_b <= '1';
            else
                reg_zero_b <= '0';
            end if;

            if (reg_mem_busy = '0') then
                if (sig_mc_lock_ack  = '1' or
                    sig_mmm_lock_ack = '1' or
                    sig_mas_lock_ack = '1')
                then
                    reg_mem_busy <= '1';
                end if;
                if (sig_mc_lock_ack = '1') then
                    reg_mem_sel  <= MODULE_MC;
                elsif (sig_mas_lock_ack = '1') then
                    reg_mem_sel  <= MODULE_MAS;
                elsif (sig_mmm_lock_ack = '1') then
                    reg_mem_sel  <= MODULE_MMM;
                end if;
            else
                if (sig_mem_release = '1') then
                    reg_mem_busy <= '0';
                    reg_mem_sel  <= MODULE_MC;
                end if;
            end if;
        end if;
    end process;

    --! =======================================================================
    --! Control
    --! =======================================================================
    process(sig_mc_lock_req, sig_mmm_lock_req,
        sig_mas_lock_req,
        sig_mas_lock_release, sig_mmm_lock_release,
        sig_mc_lock_release,
        reg_mem_sel, reg_mem_busy)
    begin
        sig_mc_lock_ack     <= '0';
        sig_mem_release     <= '0';
        sig_mas_lock_ack    <= '0';
        sig_mmm_lock_ack    <= '0';
        sig_mc_lock_ack     <= '0';

        if (reg_mem_busy = '0') then
            if (sig_mc_lock_req = '1') then
                sig_mc_lock_ack <= '1';
            elsif (sig_mas_lock_req = '1') then
                sig_mas_lock_ack <= '1';
            elsif (sig_mmm_lock_req = '1') then
                sig_mmm_lock_ack <= '1';            
            end if;
        elsif (reg_mem_busy = '1') then
            if (sig_mas_lock_release = '1'
                and reg_mem_sel = MODULE_MAS)
            then
                sig_mem_release <= '1';
            elsif (sig_mmm_lock_release = '1'
                and reg_mem_sel = MODULE_MMM)
            then
                sig_mem_release <= '1';
            elsif (sig_mc_lock_release = '1'
                and reg_mem_sel = MODULE_MC)
            then
                sig_mem_release <= '1';
            end if;
        end if;
    end process;
end architecture structure;