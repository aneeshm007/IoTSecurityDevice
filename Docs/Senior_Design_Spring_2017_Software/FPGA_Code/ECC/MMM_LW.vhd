-------------------------------------------------------------------------------
--! @file       MMM_LW.vhd
--! @brief      Montgomery Modular Multiplier for High-Speed implementation
--!
--! @author     Ekawat (ice) Homsirikamol
--!             Ahmad Salman
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MMM_LW is
    generic (
        G_N                 : integer := 5;
        G_W                 : integer := 16;
        G_PE                : integer := 4
    );
    port (
        rstn                : in  std_logic;
        clk                 : in  std_logic;
        --! Controls
        --!     Scheduler
        start               : in  std_logic;
        done                : out std_logic;
        field_size          : in  std_logic_vector(3            -1 downto 0);
        sched_op_a          : in  std_logic_vector(5            -1 downto 0);
        sched_op_b          : in  std_logic_vector(5            -1 downto 0);
        sched_op_dest       : in  std_logic_vector(5            -1 downto 0);
        --!     MAS
        mas_busy            : in  std_logic;
        mas_start           : out std_logic;
        mas_op_dest         : out std_logic_vector(5            -1 downto 0);
        mas_reduce          : out std_logic;
        --! Memory controller
        lock_ack            : in  std_logic;
        lock_req            : out std_logic;
        lock_release        : out std_logic;
        op_a                : out std_logic_vector(5            -1 downto 0);
        op_b                : out std_logic_vector(5            -1 downto 0);
        op_dest             : out std_logic_vector(5            -1 downto 0);
        idx_a               : out std_logic_vector(G_N+1        -1 downto 0);
        idx_b               : out std_logic_vector(G_N+1        -1 downto 0);
        idx_dest            : out std_logic_vector(G_N+1        -1 downto 0);
        idx_wr              : out std_logic;
        data_a              : in  std_logic_vector(G_W          -1 downto 0);
        data_b              : in  std_logic_vector(G_W          -1 downto 0);
        data_dest           : out std_logic_vector(G_W          -1 downto 0)
    );
end entity MMM_LW;

architecture structure of MMM_LW is
    constant K              : integer := 512 + G_W;
    constant E              : integer := (K / G_W);
    constant MAX_COUNT      : integer := (512+G_W)/G_W-1;
    constant ZERO_S         : std_logic_vector(G_W - 1 downto 0) := (others => '0');
    -------------------------------------------------
    -- Execution Unit defines and signals          --
    -------------------------------------------------
    --!     Signals
    --!     Registers
    signal reg_op_a         : std_logic_vector(5                -1 downto 0);
    signal reg_op_b         : std_logic_vector(5                -1 downto 0);
    signal reg_dest         : std_logic_vector(5                -1 downto 0);
    -----------------------------------------------
    -- Control Unit defines and signals          --
    -----------------------------------------------
    signal sig_mas_start    : std_logic;
    signal sig_lock_req     : std_logic;
    signal sig_lock_release : std_logic;
    signal sig_not_done     : std_logic;
    signal ld_ctr_x         : std_logic;
    signal en_ctr_x         : std_logic;
    signal ld_ctr_ym        : std_logic;
    signal en_ctr_ym        : std_logic;
    signal ld_ctr_ymb       : std_logic;    --! ym blocks
    signal en_ctr_ymb       : std_logic;    --! ym blocks
    signal ld_ctr_out       : std_logic;    --! ym blocks
    signal en_ctr_out       : std_logic;    --! ym blocks
    signal ld_mult          : std_logic;
    signal en_mult          : std_logic;
    signal mmm_core_done    : std_logic;
    signal ym_almost_done   : std_logic;
    signal almost_done      : std_logic;

    signal ctr_x            : std_logic_vector(G_N+1                -1 downto 0);
    signal ctr_ym           : std_logic_vector(G_N+1                -1 downto 0);
    signal ctr_ymb          : std_logic_vector(1+(G_W/G_PE)/4       -1 downto 0);
    signal ctr_out          : std_logic_vector(G_N+1                -1 downto 0);
    signal reg_ld_mult      : std_logic;
    signal reg_ld_x         : std_logic;
    signal reg_ld_ym        : std_logic;
    signal reg_rstn         : std_logic;
    signal reg_mmm_c_out    : std_logic;
    signal ld_x             : std_logic;
    signal ld_ym            : std_logic;
    signal mmm_s_out        : std_logic_vector(G_W                  -1 downto 0);
    signal mmm_c_out        : std_logic;
    signal mmm_out          : std_logic;

    type state_type is (
        S_RSTN, S_IDLE, S_DATA_LOCK,
        S_LOAD_X, S_LOAD_YM0, S_LOAD_YM, S_STALL, S_WAIT_MAS);
    signal state            : state_type;
    signal nstate           : state_type;
begin
    --! Hook up Montgomery Multiplier
    u_mult: entity work.MMM_Datapath
    GENERIC MAP( K => K, W => G_W, PE_COUNT => G_PE )
    PORT MAP
    (
        clk         => clk,
        rstn        => reg_rstn,
        load        => reg_ld_mult,
        LD_X        => reg_ld_x,
        LD_YM       => reg_ld_ym,
        enable      => reg_ld_ym,
        field_size  => field_size,
        X_in        => data_a,
        Y_in        => data_b,
        M_in        => data_a,
        wr          => mmm_core_done,
        YM_ctrl     => ym_almost_done,
        en_out      => mmm_out,
        S_out       => mmm_s_out,
        C_out       => mmm_c_out
    );

    --! Output
    op_a            <= "10000" when state = S_LOAD_YM or state = S_LOAD_YM0 else reg_op_a;
    op_b            <= reg_op_b;
    op_dest         <= reg_dest;
    lock_req        <= sig_lock_req;
    lock_release    <= sig_lock_release;
    idx_a           <= ctr_x when state = S_LOAD_X else ctr_ym;
    idx_b           <= ctr_ym;
    idx_dest        <= ctr_out;
    idx_wr          <= en_ctr_out;
    data_dest       <= mmm_s_out ;

    --! Ignore for now
    mas_start       <= sig_mas_start;
    mas_op_dest     <= reg_dest;
    mas_reduce      <= reg_mmm_c_out;

    --! =======================================================================
    --! Controller
    --! =======================================================================
    p_regs:
    process(rstn, clk)
    begin
        if (rstn = '0') then
            state         <= S_IDLE;
            reg_rstn      <= '0';
            reg_mmm_c_out <= '0';
        elsif rising_edge(clk) then
            reg_rstn      <= (not mmm_core_done) and sig_not_done;
            state         <= nstate     ;
            reg_ld_x      <= ld_x       ;
            reg_ld_ym     <= ld_ym      ;
            reg_ld_mult   <= ld_mult    ;

            if (ld_ctr_x = '1') then
                ctr_x <= (others => '0');
            elsif (en_ctr_x = '1') then
                ctr_x <= std_logic_vector(unsigned(ctr_x) + "1");
            end if;

            if (ld_ctr_ym = '1') then
                ctr_ym <= (others => '0');
            elsif (en_ctr_ym = '1') then
                ctr_ym <= std_logic_vector(unsigned(ctr_ym) + "1");
            end if;

            if (ld_ctr_ymb = '1') then
                ctr_ymb <= (others => '0');
            elsif (en_ctr_ymb = '1') then
                ctr_ymb <= std_logic_vector(unsigned(ctr_ymb) + "1");
            end if;

            if (ld_ctr_out = '1') then
                ctr_out <= (others => '0');
            elsif (en_ctr_out = '1') then
                ctr_out <= std_logic_vector(unsigned(ctr_out) + "1");
            end if;

            if (state = S_IDLE) then
                reg_op_a        <= sched_op_a;
                reg_op_b        <= sched_op_b;
                reg_dest        <= sched_op_dest;
            end if;

            if (mmm_core_done = '1') then
                reg_mmm_c_out   <= mmm_c_out;
            end if;
            
            done <= almost_done;
        end if;
    end process;

    en_ctr_out <= '1' when mmm_out = '1'
        and (state = S_LOAD_YM or state = S_STALL)
        else '0';
    en_ctr_ymb <= ym_almost_done when state = S_LOAD_YM else '0';

    p_combs:
    process(state, start, lock_ack, mmm_core_done, mas_busy, ctr_x, 
        ctr_ym, ctr_ymb, ym_almost_done)
    begin
        nstate              <= state;
        en_ctr_x            <= '0';
        en_ctr_ym           <= '0';
        en_mult             <= '0';
        ld_ctr_out          <= '0';
        ld_ctr_x            <= '0';
        ld_ctr_ym           <= '0';
        ld_ctr_ymb          <= '0';
        ld_mult             <= '0';
        ld_x                <= '0';
        ld_ym               <= '0';        
        sig_mas_start       <= '0';
        sig_lock_req        <= '0';
        sig_not_done        <= '1';
        almost_done         <= '0';

        case state is
        when S_RSTN =>
             sig_not_done <= '0';
             nstate <= S_IDLE;
        when S_IDLE =>
            if (start = '1') then
                nstate <= S_DATA_LOCK;
            end if;
        when S_DATA_LOCK =>
            if (lock_ack = '1') then
                nstate  <= S_LOAD_X;
                ld_mult <= '1';
            end if;
            sig_lock_req <= '1';
            ld_ctr_x <= '1';
            ld_ctr_ym <= '1';
            ld_ctr_ymb <= '1';
            ld_ctr_out <= '1';
        when S_LOAD_X =>
            ld_x     <= '1';
            nstate   <= S_LOAD_YM0;
        when S_LOAD_YM0 =>
            ld_ym   <= '1';
            en_ctr_ym <= '1';
            nstate <= S_LOAD_YM;
        when S_LOAD_YM =>
            ld_ym   <= '1';
            en_ctr_ym <= '1';
            if (mmm_core_done = '1') then
                sig_mas_start <= '1';
                nstate <= S_WAIT_MAS;
            elsif (ym_almost_done = '1') then
                ld_ctr_ym <= '1';
                if (unsigned(ctr_ymb) = (G_W/G_PE)-1) then
                    nstate <= S_STALL;
                end if;
            end if;
        when S_STALL =>
            nstate  <= S_LOAD_X;
            ld_ctr_ymb <= '1';
            en_ctr_x <= '1';
        when S_WAIT_MAS =>
           if (mas_busy = '0') then
               nstate <= S_RSTN;
               almost_done <= '1';
           end if;

        end case;
    end process;

    sig_lock_release  <= mmm_core_done;
end architecture structure;