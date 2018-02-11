-------------------------------------------------------------------------------
--! @file       MAS_LW.vhd
--! @brief      Modular Adder/Subtractor module
--!
--! @author     Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MAS_LW is
    generic (
        G_N                 : integer := 3;
        G_W                 : integer := 64
    );
    port (
        --! Global
        rstn                : in  std_logic;
        clk                 : in  std_logic;
        --! Controls
        start               : in  std_logic;
        op_subtract         : in  std_logic;
        busy                : out std_logic;
        done                : out std_logic;
        field_size          : in  std_logic_vector(3            -1 downto 0);
        field_words         : in  std_logic_vector(G_N+1        -1 downto 0);
        sched_op_a          : in  std_logic_vector(5            -1 downto 0);
        sched_op_b          : in  std_logic_vector(5            -1 downto 0);
        sched_op_dest       : in  std_logic_vector(5            -1 downto 0);
        --! MMM
        mmm_start           : in  std_logic;
        mmm_op_dest         : in  std_logic_vector(5            -1 downto 0);
        mmm_reduce          : in  std_logic;
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
end entity MAS_LW;

architecture structure of MAS_LW is
    --! Constant
    constant ZEROS : std_logic_vector(G_W+1   -1 downto 0) := (others => '0');
    --! Data
    signal in_a                 : std_logic_vector(G_W          -1 downto 0);
    signal in_b                 : std_logic_vector(G_W          -1 downto 0);
    signal data_b_sel           : std_logic_vector(G_W          -1 downto 0);
    signal add_out              : std_logic_vector(G_W+1        -1 downto 0);

    signal reg_op_a             : std_logic_vector(5            -1 downto 0);
    signal reg_op_b             : std_logic_vector(5            -1 downto 0);
    signal reg_dest             : std_logic_vector(5            -1 downto 0);
    signal reg_op_sub           : std_logic;
    signal reg_carry            : std_logic;
    signal reg_busy             : std_logic;
    signal reg_done             : std_logic;
    signal is_mmm               : std_logic;

    --! Controls
    signal is_reduction         : std_logic;
    signal do_subtract          : std_logic;
    signal set_operation        : std_logic;
    signal set_reduce           : std_logic;
    signal goto_reduction       : std_logic;

    signal a_eq_b_reg           : std_logic;
    signal a_eq_b               : std_logic;

    signal toggle_busy          : std_logic;
    signal ld_ctr               : std_logic;
    signal en_ctr               : std_logic;
    signal en_carry             : std_logic;
    signal ram_wr               : std_logic;
    signal ovf                  : std_logic;    --! Overflow bit

    signal last                 : std_logic;
    signal needs_reduce         : std_logic;
    signal reg_subtract         : std_logic;
    signal sig_done             : std_logic;
    signal sig_lock_req         : std_logic;
    signal sig_lock_release     : std_logic;
    signal sign_bit             : std_logic;
    signal sel_mmm              : std_logic;
    signal sel_carry            : std_logic;
    signal sel_operand          : std_logic;
    signal to_reg_carry         : std_logic;
    signal ctr                  : std_logic_vector(G_N+1        -1 downto 0);

    type state_type is (
        S_WAIT_START,       S_WAIT_MEM_ACK,
        S_ADDSUB_RD,        S_ADDSUB_WR,
        S_COMPARE_INIT,     S_COMPARE,      S_COMPARE_FINAL);
    signal state    : state_type;
    signal nstate   : state_type;
begin
    --! =======================================================================
    --! Datapath
    --! =======================================================================
    --! Internal
    in_a <= data_a;
    in_b <= data_b when sel_mmm = '0' else (others => '0');

    data_b_sel <= (not in_b) when reg_subtract = '1' else in_b;
    
    plus: block
        signal op1 : unsigned(G_W+1        -1 downto 0);
        signal op2 : unsigned(G_W+1        -1 downto 0);
    begin
        op1 <= unsigned('0' & in_a);
        op2 <= unsigned(sign_bit & data_b_sel);
        add_out <= std_logic_vector(op1 + op2 + (reg_carry & ""));
    end block;
        
    a_eq_b <= '1' when in_a = in_b and a_eq_b_reg = '1' else '0';

    gen64:
    if (G_W = 64) generate
        signal sel_ovf : std_logic_vector(3                 -1 downto 0);
    begin
        sel_ovf(2) <= field_size(2) and (not reg_subtract);
        sel_ovf(1) <= field_size(1) and (not reg_subtract);
        sel_ovf(0) <= field_size(0) and (not reg_subtract);
        with sel_ovf select
        ovf <=  add_out(32)  when "001",
                add_out(9)   when "100",
                add_out(G_W) when others;
    end generate;
    genn64:
    if (G_W /= 64) generate
    begin
        ovf <=  add_out(9) when field_size(2) = '1' and reg_subtract = '0'
                           else add_out(G_W);
    end generate;

    to_reg_carry <= do_subtract when sel_carry = '1' else add_out(G_W);

    --! Output
    done <= reg_done;
    busy <= reg_busy;
    op_a <= reg_op_a when sel_operand = '1' else reg_dest;
    op_b <= reg_op_b when sel_operand = '1' else "10000";
    op_dest         <= reg_dest;
    lock_req        <= sig_lock_req;
    lock_release    <= sig_lock_release;
    idx_a           <= ctr;
    idx_b           <= ctr;
    idx_dest        <= ctr;
    idx_wr          <= ram_wr;
    data_dest       <= add_out(G_W-1 downto 0);

    --! =======================================================================
    --! Registers
    --! =======================================================================
    process(rstn, clk)
    begin
        if rstn = '0' then
            state <= S_WAIT_START;
            reg_busy <= '0';
        elsif rising_edge(clk) then
            state       <= nstate;
            reg_done    <= sig_done;
            sign_bit    <= last and reg_subtract;

            if (toggle_busy = '1') then
                reg_busy <= not reg_busy;
            end if;

            if (set_operation = '1') then
                reg_subtract <= do_subtract;
            end if;

            if (state = S_WAIT_START) then
                if (mmm_start = '1') then
                    is_mmm      <= '1';
                    reg_op_a    <= mmm_op_dest;
                    reg_op_b    <= (others => '0');
                    reg_dest    <= mmm_op_dest;
                    reg_op_sub  <= '0';
                else
                    is_mmm      <= '0';
                    reg_op_a    <= sched_op_a;
                    reg_op_b    <= sched_op_b;
                    reg_dest    <= sched_op_dest;
                    reg_op_sub  <= op_subtract;
                end if;
            end if;
            if (state = S_WAIT_START) then
                is_reduction <= '0';
            elsif (goto_reduction = '1') then
                is_reduction <= '1';
            end if;
            if (state = S_WAIT_MEM_ACK) then
                needs_reduce <= is_mmm and mmm_reduce;
            elsif (set_reduce = '1') then
                needs_reduce <= '1';
            end if;
            if (state = S_COMPARE_INIT) then
                a_eq_b_reg <= '1';
            else
                a_eq_b_reg <= a_eq_b;
            end if;

            if (ld_ctr = '1') then
                ctr <= (others => '0');
            elsif (en_ctr = '1') then
                ctr <= std_logic_vector(unsigned(ctr) + 1);
            end if;

            if (en_carry = '1') then
                reg_carry <= to_reg_carry;
            end if;
        end if;
    end process;

    --! =======================================================================
    --! Controller
    --! =======================================================================
    last <= '1' when ctr = field_words else '0';

    p_comb:
    process(state, start, field_words, reg_op_sub,
        lock_ack, ctr, mmm_start, needs_reduce,
        is_reduction, a_eq_b, is_mmm, ovf)
    begin
        nstate              <= state;
        sig_done            <= '0';
        sig_lock_req        <= '0';
        sig_lock_release    <= '0';
        ld_ctr              <= '0';
        en_ctr              <= '0';
        en_carry            <= '0';
        ram_wr              <= '0';
        sel_operand         <= '0';
        set_operation       <= '0';
        set_reduce          <= '0';

        sel_carry           <= '0';
        goto_reduction      <= '0';
        toggle_busy         <= '0';
        sel_mmm             <= '0';
        do_subtract         <= '0';

        case state is
        when S_WAIT_START =>
            if (start = '1' or mmm_start = '1') then
                nstate      <= S_WAIT_MEM_ACK;
                toggle_busy <= '1';
            end if;

        when S_WAIT_MEM_ACK =>
            sig_lock_req  <= '1';
            ld_ctr        <= '1';
            en_carry      <= '1';
            sel_carry     <= '1';
            set_operation <= '1';
            do_subtract   <= reg_op_sub;
            if (lock_ack = '1') then
                nstate    <= S_ADDSUB_RD;
            end if;


        when S_ADDSUB_RD =>
            nstate      <= S_ADDSUB_WR;
            sel_operand <= not is_reduction;


        when S_ADDSUB_WR =>
            if (is_reduction = '1') then
                ram_wr   <= needs_reduce;
            else
                ram_wr   <= '1';
            end if;
            en_carry <= '1';
            en_ctr   <= '1';

            if (is_reduction = '0' and is_mmm = '1') then
                sel_mmm <= '1';
            end if;

            if (ctr = field_words) then
                if (ovf = '1') then
                    set_reduce <= '1';
                end if;
                ld_ctr    <= '1';
                if (is_reduction = '0') then
                    nstate <= S_COMPARE_INIT;
                else
                    sig_lock_release     <= '1';
                    sig_done             <= '1';
                    toggle_busy          <= '1';
                    nstate               <= S_WAIT_START;
                end if;
            else
                nstate <= S_ADDSUB_RD;
            end if;


        when S_COMPARE_INIT =>
            nstate      <= S_COMPARE;
            en_ctr      <= '1';
            en_carry    <= '1';
            sel_carry   <= '1';
            set_operation <= '1';
            do_subtract   <= '1';


        when S_COMPARE =>
            en_carry    <= '1';
            en_ctr      <= '1';
            if (ctr = field_words) then
                nstate    <= S_COMPARE_FINAL;
            end if;


        when others => --! S_COMPARE_FINAL
            ld_ctr    <= '1';
            en_carry  <= '1';
            sel_carry <= '1';
            goto_reduction <= '1';
            set_operation <= '1';

            if (reg_op_sub = '0') then
                if ((a_eq_b = '1' or ovf = '0') or needs_reduce = '1') then
                    set_reduce  <= '1';
                    do_subtract <= not reg_op_sub;
                end if;
            else
                if (needs_reduce = '1') then
                    do_subtract <= not reg_op_sub;
                end if;
            end if;

            nstate    <= S_ADDSUB_RD;
        end case;
    end process;
end architecture structure;