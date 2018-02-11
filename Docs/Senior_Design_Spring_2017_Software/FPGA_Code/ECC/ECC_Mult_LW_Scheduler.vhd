-------------------------------------------------------------------------------
--! @file       ECC_Mult_LW_Scheduler.vhd
--! @brief      ECC Multiplier Scheduler for LW
--!
--! @author     Ahmed Ferozpuri
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ECC_Mult_LW_Scheduler is
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
        init_field          : in  std_logic;
        init_curve          : in  std_logic;
		  elgamal_calc			 : in  std_logic;
        busy                : out std_logic;
        di_valid            : in  std_logic;
        di_ready            : out std_logic;
        di_data             : in  std_logic_vector(G_W           -1 downto 0);
        do_valid            : out std_logic;
        do_ready            : in  std_logic;
        do_data             : out std_logic_vector(G_W           -1 downto 0);
        --! MAS
        mas_sched_op_a      : out std_logic_vector(5           -1 downto 0);
        mas_sched_op_b      : out std_logic_vector(5           -1 downto 0);
        mas_sched_op_dest   : out std_logic_vector(5           -1 downto 0);
        mas_start           : out std_logic;
        mas_done            : in std_logic;
        mas_op_subtract     : out std_logic;
        --! MMMM
        mmm_sched_op_a      : out std_logic_vector(5           -1 downto 0);
        mmm_sched_op_b      : out std_logic_vector(5           -1 downto 0);
        mmm_sched_op_dest   : out std_logic_vector(5           -1 downto 0);    
        mmm_start           : out std_logic;
        mmm_done            : in std_logic;
        --! MAS & MMM
        field_size          : out std_logic_vector(3           -1 downto 0);
        field_words         : out std_logic_vector(G_N+1        -1 downto 0);
        --! Memory controller
        lock_ack            : in  std_logic;
        lock_req            : out std_logic;
        lock_release        : out std_logic;
        op_a                : out std_logic_vector(5           -1 downto 0);
        op_b                : out std_logic_vector(5           -1 downto 0);
        op_dest             : out std_logic_vector(5           -1 downto 0);
        idx_a               : out std_logic_vector(G_N+1       -1 downto 0);
        idx_b               : out std_logic_vector(G_N+1       -1 downto 0);
        idx_dest            : out std_logic_vector(G_N+1       -1 downto 0);
        idx_wr              : out std_logic;
        data_a              : in  std_logic_vector(G_W         -1 downto 0);
        data_b              : in  std_logic_vector(G_W         -1 downto 0);
        data_dest           : out std_logic_vector(G_W         -1 downto 0)
    );
end entity ECC_Mult_LW_Scheduler;

architecture structure of ECC_Mult_LW_Scheduler is

   constant NTOM_START_ADDR    : std_logic_vector := "0000010"; --2
   constant NTOM_END_ADDRm1    : std_logic_vector := "0000100"; --4
   constant NTOM_END_ADDR      : std_logic_vector := "0000101"; --5
   constant INIT_P_START_ADDR  : std_logic_vector := "0000110"; --6
   constant INIT_P_END_ADDR    : std_logic_vector := "0010100"; --20   
   constant EPA_PQ_START_ADDR  : std_logic_vector := "0010101"; --21
   constant EPA_PQ_END_ADDR    : std_logic_vector := "0100111"; --39
   constant EPD_2P_START_ADDR  : std_logic_vector := "0101000"; --40
   constant EPD_2P_END_ADDR    : std_logic_vector := "0110110"; --54
   constant EPA_QP_START_ADDR  : std_logic_vector := "0110111"; --55
   constant EPA_QP_END_ADDR    : std_logic_vector := "1001001"; --73   
   constant EPD_2Q_START_ADDR  : std_logic_vector := "1001010"; --74
   constant EPD_2Q_END_ADDR    : std_logic_vector := "1011000"; --88
   constant EPS_CQ_START_ADDR  : std_logic_vector := "1011001"; --89
   constant EPS_CQ_END_ADDR    : std_logic_vector := "1101100"; --108	
   constant PTOA_START_ADDR    : std_logic_vector := "1101101"; --109
   constant PTOA_START_ADDR_p2 : std_logic_vector := "1101111"; --111
   constant PTOA_END_ADDR      : std_logic_vector := "1110010"; --114
   constant MTON_START_ADDR    : std_logic_vector := "1110011"; --115
   constant MTON_END_ADDR      : std_logic_vector := "1110100"; --116
   type EXEC_EPM_STATE IS (IDLE,
                     LOAD_FIELD_SIZE, FIELD_DATA_LOCK, LOAD_FIELD_DATA_1, LOAD_FIELD_DATA_2, FB_GEN_2, GEN_2, START_M_2, WAIT_M_2,
                     CURVE_DATA_LOCK, LOAD_CURVE_DATA,
                     START_DATA_LOCK, LOAD_START_DATA_1, LOAD_START_DATA_2, LOAD_START_DATA_3, FB_GEN_1_NTOM, GEN_1_NTOM,
                     LOAD_ELGAMAL_DATA, FB_GEN_ELGAMAL_DATA, GEN_ELGAMAL_DATA, 
							L_INIT_a, INIT_a, L_INIT_one, INIT_one, L_INIT_aZ4_P, INIT_aZ4_P,
                     START_S1, S1, WML_INIT_Q, L_INIT_Q_1, INIT_Q_1, L_INIT_Q_2, INIT_Q_2, L_INIT_Q_3, INIT_Q_3, L_INIT_Q_4, INIT_Q_4,
                     L_INIT_P, INIT_P,
							START_SUB_CQ, L_START_SUB_CQ, GEN_0, FB_GEN_0, LOAD_ELGAMAL_DATA_2, LOAD_ELGAMAL_DATA_1, ELGAMAL_DATA_LOCK,		
                     WML_S2, L_WML_S2, L_S2, START_S2_D_P, S2_D_P, START_S2_A_PQ, S2_A_PQ,START_S2_D_Q, S2_D_Q, START_S2_A_QP, S2_A_QP,
                     WAIT_1_R2, WML_INIT_T2, L_INIT_T2, INIT_T2,
                     WML_S3, L_WML_S3, L_S3, START_S3_S, S3_S, START_S3_M, S3_M, START_S3_FINAL, S3_FINAL, FB_GEN_1_MTON, GEN_1_MTON,
                     START_S4, S4,
                     WML_OUTPUT_X, W_OUTPUT_X, OUTPUT_X, W_OUTPUT_Y, OUTPUT_Y);
   
   signal mc_state, mc_nstate                                : EXEC_EPM_STATE;
   signal PC_en, PC_ld, PC_rst                               : std_logic;
   signal PC, PC_next, pc_m1                                 : std_logic_vector(6 downto 0);--up to 128 instructions
   signal shift_reg                                          : std_logic_vector(G_W         -1 downto 0);
   signal shift_cnt, gw_m1                                   : std_logic_vector(5 downto 0); --size should be log2(G_W)
   signal s_en, s_ld, s_empty, s_rst                         : std_logic;
   
   signal field_size_reg                                     : std_logic_vector(2 downto 0);
   signal field_count, field_count_next, field_count_zero_val: std_logic_vector(G_N+1        -1 downto 0);
   signal field_count_en, field_count_rst, field_count_l     : std_logic;
   signal field_words_l, field_words_m1, field_words_val     : std_logic_vector(G_N+1        -1 downto 0);
   signal field_size_reg_l                                   : std_logic;
   signal mc_rom_out                                         : std_logic_vector (26 downto 0);
   signal instr_op                                           : std_logic_vector(2 downto 0);
   signal msb_op                                             : std_logic;
   signal op_done                                            : std_logic;
   signal op_start                                           : std_logic;
   signal first_one, first_one_r, first_one_s                                          : std_logic;
   signal field_count_zero                                   : std_logic;
   signal pc_equals_field_words, pc_equals_field_words_m_1   : std_logic;

   signal data_dest_sel                                      : std_logic_vector(2 downto 0);
   signal PC_next_sel, op_a_sel                              : std_logic_vector(3 downto 0);
	signal op_dest_sel                                        : std_logic_vector(4 downto 0);
   signal idx_a_sel, init_curve_flag                         : std_logic;
   signal shift_reg_msb_1, shift_reg_msb_2                   : std_logic;
   signal init_curve_flag_r, init_curve_flag_s               : std_logic;
   signal field_count_next_sel                               : std_logic_vector(1 downto 0);
begin

mc_rom:
entity work.ECC_MC_ROM
   port map (
      addr => PC,
      dout => mc_rom_out
   );

mc_fsm: process(clk, rstn)
begin
    if rstn = '0' then
        mc_state     <= IDLE;
        PC           <= (others => '0');
        shift_reg    <= (others => '0');
        shift_cnt    <= (others => '0');
      field_count    <= (others => '0');
      field_size_reg <= (others => '0');
    elsif rising_edge(clk) then
        mc_state     <= mc_nstate;
        
      --counters
        if (PC_rst = '1') then
         PC <= (others => '0');
      elsif (PC_ld = '1') then
            PC <= PC_next;
        elsif (PC_en = '1') then
            PC <= std_logic_vector(unsigned(PC) + "1");
        end if;
        
        if (s_rst = '1') then
         shift_cnt <= (others => '0');
      elsif (s_ld = '1') then
            shift_reg <= data_a;
        elsif (s_en = '1') then
            shift_reg <= shift_reg(G_W         -2 downto 0) & '0';
            shift_cnt <= std_logic_vector(unsigned(shift_cnt) + "1"); 
        end if;
      
      if (field_count_rst = '1') then
         field_count <= (others => '0');
      elsif (field_count_l = '1') then
         field_count <= field_count_next;
      elsif (field_count_en = '1') then
         field_count <= std_logic_vector(unsigned(field_count) - "1");
      end if;
      
      if (first_one_s = '1') then
         first_one <= '1';
      elsif (first_one_r = '1') then
         first_one <= '0';
      end if;
      
      if (init_curve_flag_s = '1') then
         init_curve_flag <= '1';
      elsif (init_curve_flag_r = '1') then
         init_curve_flag <= '0';
      end if;
      
      if (field_size_reg_l = '1') then
         field_size_reg <= di_data(2 downto 0);
      end if;
    end if;
end process;

--signal constants
gw_m1                <= std_logic_vector(to_unsigned(G_W-1, shift_cnt'length));
field_count_zero_val <= (others => '0');
field_words_m1       <= std_logic_vector(unsigned(field_words_l) - "1");
pc_m1                <= std_logic_vector(unsigned(PC) - "1");

with field_size_reg select
field_words_l <= std_logic_vector(to_unsigned((224+(G_W-1))/G_W, field_words_l'length)) when "001",
                 std_logic_vector(to_unsigned((256+(G_W-1))/G_W, field_words_l'length)) when "010",
                 std_logic_vector(to_unsigned((384+(G_W-1))/G_W, field_words_l'length)) when "011",
                 std_logic_vector(to_unsigned((521+(G_W-1))/G_W, field_words_l'length)) when "100",
                 std_logic_vector(to_unsigned((192+(G_W-1))/G_W, field_words_l'length)) when others;
             
--registered output
field_size      <= field_size_reg;
field_words     <= field_words_m1;
field_words_val <= field_words_l when field_size_reg = "100" else field_words_m1;

--ports
op_b    <= (others => '0');
idx_b   <= (others => '0');
do_data <= data_a;

with data_dest_sel select
data_dest <= (0 => '1', others => '0')           when "001",
             (1 => '1', others => '0')           when "010",
             (di_data)                           when "011",
             (data_a)                            when "100",
				 (2 => '1', 0 => '1', others => '0') when "101",
             (others => '0')                     when others;

with op_dest_sel select
op_dest <=  "10000"          when "00001", --M
            "10001"          when "00010", --M-2
            "00001"          when "00011", --Pa
            "00010"          when "00100", --Px
            "00011"          when "00101", --Py
            "00100"          when "01110", --Pz
            "10010"          when "00110", --k
            "01001"          when "00111", --1/T1
            "01000"          when "01000", --Qa
            "00101"          when "01001", --Qx
            "00110"          when "01010", --Qy
            "00111"          when "01011", --QZ
            "01010"          when "01100", --T2
            "01100"          when "01101", --aR
            "01101"          when "01111", --1
            "01110"          when "10000", --0
				(others => '0')  when others;

with op_a_sel select
op_a <= "10010" when "0001", --k
        "00001" when "0010", --aZ4
        "00010" when "0011", --x
        "00011" when "0100", --y
        "00100" when "0101", --Z
        "10001" when "0110", --M-2
        "00111" when "0111", --QZ
        "01101" when "1001", --1
        "01100" when "1000", --a
        (others => '0') when others;

idx_a    <= field_count when idx_a_sel = '1' else PC(G_N+1        -1 downto 0);
idx_dest <= PC(G_N+1        -1 downto 0);

--instruction set decoding
instr_op          <= mc_rom_out(2 downto 0);
msb_op            <= '1' when PC = "0000001" else '0';
mmm_sched_op_dest <= msb_op & mc_rom_out(26 downto 23);
mmm_sched_op_a    <= msb_op & mc_rom_out(22 downto 19);
mmm_sched_op_b    <= msb_op & mc_rom_out(18 downto 15);
mas_op_subtract   <= '1' when instr_op = "001" or instr_op = "101" else '0';

with instr_op select   
   mas_sched_op_dest <= msb_op & mc_rom_out(26 downto 23) when "100" | "101",
                   msb_op & mc_rom_out(14 downto 11) when others;
   
with instr_op select
   mas_sched_op_a <= msb_op & mc_rom_out(22 downto 19) when "100" | "101",
                 msb_op & mc_rom_out(10 downto 7) when others;
   
with instr_op select
   mas_sched_op_b <= msb_op & mc_rom_out(18 downto 15) when "100" | "101",
                 msb_op & mc_rom_out(6 downto 3) when others;
   
with instr_op select
   op_done <= mas_done when "100" | "101",
            mmm_done when others;

with instr_op select
   mas_start <= op_start when "000" | "001" | "100" | "101",
             '0' when others;
with instr_op select
   mmm_start <= op_start when "000" | "001" | "010" | "011",
             '0' when others;

with PC_next_sel select
   PC_next <=  (0 => '1', others => '0')  when "0001",
               (EPD_2P_START_ADDR)        when "0010",
               (EPA_PQ_START_ADDR)        when "0011",
               (MTON_START_ADDR)          when "0100",
               (NTOM_START_ADDR)          when "0101",
               (PTOA_START_ADDR)          when "0110",
               (PTOA_START_ADDR_p2)       when "0111",
               (INIT_P_START_ADDR)        when "1000",
               (EPD_2Q_START_ADDR)        when "1001",
               (EPA_QP_START_ADDR)        when "1010",
					(EPS_CQ_START_ADDR)        when "1011",
               (others => '0')            when others;
            
with field_count_next_sel select
   field_count_next <= (0 => '1', others => '0') when "01",
                       (1 => '1', others => '0') when "10",
                       (field_words_val) when "11",
                       (others => '0') when others;
--flags
field_count_zero <= '1' when field_count = field_count_zero_val else '0';
pc_equals_field_words_m_1 <= '1' when PC(field_words_l'length-1 downto 0) = field_words_m1 else '0';
pc_equals_field_words <= '1' when PC(field_words_l'length-1 downto 0) = field_words_l else '0';
s_empty <= '1' when shift_cnt = gw_m1 else '0';
shift_reg_msb_1 <= '1' when shift_reg(G_W-1) = '1' else '0';
shift_reg_msb_2 <= '1' when shift_reg(G_W-2) = '0' else '0';

mc_p_comb: process(mc_state, init_field, init_curve, start, di_valid, lock_ack, op_done, mmm_done, s_empty, pc_equals_field_words, pc_equals_field_words_m_1, field_count_zero, do_ready, first_one, init_curve_flag, shift_reg_msb_1, PC)
begin
   mc_nstate            <= mc_state;
   busy                 <= '1';
   PC_ld                <= '0';
   PC_en                <= '0';
   di_ready             <= '0';
   lock_req             <= '0';
   lock_release         <= '0';
   s_ld                 <= '0';
   s_en                 <= '0';
   idx_wr               <= '0';
   field_count_en       <= '0';
   field_count_rst      <= '0';
   op_start             <= '0';
   field_count_l        <= '0';
   PC_rst               <= '0';
   s_rst                <= '0';
   do_valid             <= '0';
   first_one_r          <= '0';
   first_one_s          <= '0';
   idx_a_sel            <= '0';
   init_curve_flag_s    <= '0';
   init_curve_flag_r    <= '0';
   field_size_reg_l     <= '0';
   op_dest_sel          <= (others => '0');
   data_dest_sel        <= (others => '0');
   op_a_sel             <= (others => '0');
   PC_next_sel          <= (others => '0');
   field_count_next_sel <= (others => '0');
   
    case mc_state is
    when IDLE =>
         busy        <= '0';
         PC_en       <= '0';
         first_one_r <= '1';
         PC_rst      <= '1';

        if (init_field = '1') then
            mc_nstate <= LOAD_FIELD_SIZE;
      elsif (init_curve = '1') then
         mc_nstate <= CURVE_DATA_LOCK;
      elsif (start = '1') then
         mc_nstate <= START_DATA_LOCK;
        end if;
    when LOAD_FIELD_SIZE =>
        di_ready <= '1';
        if (di_valid = '1') then
            field_size_reg_l <= '1';
            mc_nstate <= FIELD_DATA_LOCK;
        end if;
    when FIELD_DATA_LOCK =>
        lock_req <= '1';
        if (lock_ack = '1') then
            PC_rst <= '1';
         field_count_next_sel <= "01";
         field_count_l <= '1';
            mc_nstate <= LOAD_FIELD_DATA_1;
        end if;
    when LOAD_FIELD_DATA_1 =>
        di_ready <= '1';
      op_dest_sel <= "00001";
      data_dest_sel <= "011";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            mc_nstate <= LOAD_FIELD_DATA_2;
            end if;
        end if;
   when LOAD_FIELD_DATA_2 =>
        di_ready <= '1';
      --op_dest_sel <= "0000";
      data_dest_sel <= "011";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

         if (pc_equals_field_words = '1') then
            PC_rst <= '1';
            di_ready <= '0';
            idx_wr <= '0';
            mc_nstate <= FB_GEN_2;
            end if;
        end if;
   when FB_GEN_2 =>
      idx_wr <= '1';
      data_dest_sel <= "010";
      op_dest_sel <= "00010";
      PC_en <= '1';
      mc_nstate <= GEN_2;
   when GEN_2 =>
      idx_wr <= '1';
      --data_dest_sel <= "000";
      op_dest_sel <= "00010";
      PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         --PC_rst <= '1';
         lock_release <= '1';
         PC_next_sel <= "0001";
         PC_ld <= '1';
         mc_nstate <= START_M_2;
      end if;
   when START_M_2 =>
      op_start <= '1';
      mc_nstate <= WAIT_M_2;
   when WAIT_M_2 =>
      if (op_done = '1') then
         mc_nstate <= IDLE;
      end if;
   when CURVE_DATA_LOCK =>
        lock_req <= '1';
        if (lock_ack = '1') then
            PC_rst <= '1';
         --di_ready <= '1';
            mc_nstate <= LOAD_CURVE_DATA;
        end if;
    when LOAD_CURVE_DATA =>
        di_ready <= '1';
      data_dest_sel <= "011";
      op_dest_sel <= "01101";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            init_curve_flag_s <= '1';
            mc_nstate <= IDLE;
            lock_release <= '1';
            --di_ready <= '0';
            end if;
        end if;
   when START_DATA_LOCK =>
        lock_req <= '1';
        if (lock_ack = '1') then
            PC_rst <= '1';
         field_count_next_sel <= "10"; --2
         field_count_l <= '1';
         --di_ready <= '1';
            mc_nstate <= LOAD_START_DATA_1;
        end if;
    when LOAD_START_DATA_1 =>
        di_ready <= '1';
      data_dest_sel <= "011";
      op_dest_sel <= "00100";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            mc_nstate <= LOAD_START_DATA_2;
            end if;
        end if;
   when LOAD_START_DATA_2 =>
        di_ready <= '1';
      data_dest_sel <= "011";
      op_dest_sel <= "00101";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            mc_nstate <= LOAD_ELGAMAL_DATA;
            end if;
        end if;
	when LOAD_ELGAMAL_DATA =>
        if (elgamal_calc = '1') then
		      lock_release <= '1';
            mc_nstate <= FB_GEN_ELGAMAL_DATA;
			else
            mc_nstate <= LOAD_START_DATA_3;
			end if;	
		  			
   when LOAD_START_DATA_3 =>
         di_ready <= '1';
         data_dest_sel <= "011";	
         op_dest_sel <= "00110";
         if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            lock_release <= '1';
            mc_nstate <= FB_GEN_1_NTOM;
            end if;
        end if;

		when FB_GEN_ELGAMAL_DATA =>
      lock_req <= '1';
      data_dest_sel <= "101";
      op_dest_sel <= "00110";

      if (lock_ack = '1') then
         idx_wr <= '1';
         PC_en <= '1';
         mc_nstate <= GEN_ELGAMAL_DATA;
      end if;
   when GEN_ELGAMAL_DATA =>
      --data_dest_sel <= "000";
      op_dest_sel <= "00110";
      idx_wr <= '1';
      PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            lock_release <= '1';
            mc_nstate <= FB_GEN_1_NTOM;
      end if;

   when FB_GEN_1_NTOM =>
      lock_req <= '1';
      data_dest_sel <= "001";
      op_dest_sel <= "00111";

      if (lock_ack = '1') then
         idx_wr <= '1';
         PC_en <= '1';
         mc_nstate <= GEN_1_NTOM;
      end if;
   when GEN_1_NTOM =>
      --data_dest_sel <= "000";
      op_dest_sel <= "00111";
      idx_wr <= '1';
      PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         lock_release <= '1';
         PC_next_sel <= "0101";
         PC_ld <= '1';
         mc_nstate <= START_S1;
      end if;
		
   when START_S1 =>
      op_start <= '1';
      mc_nstate <= S1;
    when S1 =>
        if (mmm_done = '1') then
            PC_en <= '1';
         if (PC = NTOM_END_ADDRm1 and init_curve_flag = '0') then
            PC_rst <= '1';

            mc_nstate <= L_INIT_aZ4_P;
         else      
         if (PC = NTOM_END_ADDR ) then
            PC_rst <= '1';
            
--                init_curve_flag_r <= '1';
            mc_nstate <= WML_INIT_Q;
         else
            mc_nstate <= START_S1;
         end if;
         end if;
        end if;
   when L_INIT_aZ4_P => --aR    
         op_a_sel <= "1000";
         mc_nstate <= INIT_aZ4_P;            
   when INIT_aZ4_P => --aR
      op_dest_sel <= "00011";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         init_curve_flag_r <= '1';
         PC_rst <= '1';
         mc_nstate <= WML_INIT_Q;
      else
         mc_nstate <= L_INIT_aZ4_P;
      end if;             
   when WML_INIT_Q =>
      lock_req <= '1';
      if (lock_ack = '1') then
         PC_rst <= '1';
         mc_nstate <= L_INIT_a;
      end if;
   when L_INIT_a => --aR
      if (init_curve_flag = '0') then
          mc_nstate <= L_INIT_one;
      else    
         op_a_sel <= "0010";
         mc_nstate <= INIT_a;
      end if;            
   when INIT_a => --aR
      op_dest_sel <= "01101";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         init_curve_flag_r <= '1';
         PC_rst <= '1';
         mc_nstate <= L_INIT_one;
      else
         mc_nstate <= L_INIT_a;
      end if;
   when L_INIT_one => --1 in montgomery (R)
      op_a_sel <= "0101";
      mc_nstate <= INIT_one;   
   when INIT_one => --R
      op_dest_sel <= "01111";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         PC_rst <= '1';
         mc_nstate <= L_INIT_Q_1;
      else
         mc_nstate <= L_INIT_one;
      end if;      
   when L_INIT_Q_1 => --a
      op_a_sel <= "0010";
      mc_nstate <= INIT_Q_1;
   when INIT_Q_1 => --a
      op_dest_sel <= "01000";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then

            PC_rst <= '1';
         mc_nstate <= L_INIT_Q_2;
      else
         mc_nstate <= L_INIT_Q_1;
      end if;
   when L_INIT_Q_2 => --x
      op_a_sel <= "0011";
      mc_nstate <= INIT_Q_2;
   when INIT_Q_2 => --x
      op_dest_sel <= "01001";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

        
      if (pc_equals_field_words_m_1 = '1') then
         PC_rst <= '1';
         mc_nstate <= L_INIT_Q_3;
      else
         mc_nstate <= L_INIT_Q_2;
      end if;


        when L_INIT_Q_3 => --y
      op_a_sel <= "0100";


      mc_nstate <= INIT_Q_3;
   when INIT_Q_3 => --y
      op_dest_sel <= "01010";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         PC_rst <= '1';
         mc_nstate <= L_INIT_Q_4;
      else
         mc_nstate <= L_INIT_Q_3;
      end if;
   when L_INIT_Q_4 => --Z
      op_a_sel <= "0101";
      mc_nstate <= INIT_Q_4;
   when INIT_Q_4 => --Z
      op_dest_sel <= "01011";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         field_count_l <= '1';
         field_count_next_sel <= "11";
         lock_release <= '1';
       PC_ld <= '1';
         PC_next_sel <= "1000";
         mc_nstate <= L_INIT_P;


         else
         mc_nstate <= L_INIT_Q_4;
      end if;
   when L_INIT_P => --2*P

      op_start <= '1';
      mc_nstate <= INIT_P;
   when INIT_P =>
        if (op_done = '1') then
         if (PC = INIT_P_END_ADDR) then
               mc_nstate <= WML_S2;
         else
            mc_nstate <= L_INIT_P;
            PC_en <= '1';      
         end if;
        end if;        
    when WML_S2 =>
      lock_req <= '1';
      op_a_sel <= "0001";
      idx_a_sel <= '1';
      if (lock_ack = '1') then
         mc_nstate <= L_WML_S2;
      end if;
   when L_WML_S2 =>
      s_ld <= '1';
      lock_release <= '1';
      mc_nstate <= L_S2;
    when L_S2 => --filter k until first one
      if (first_one = '1') then
         if (shift_reg_msb_1 = '1') then        
         PC_ld <= '1';
         PC_next_sel <= "0011";
         mc_nstate <= START_S2_A_PQ;
       else
            PC_ld <= '1';
            PC_next_sel <= "1010";
            mc_nstate <= START_S2_A_QP;
         end if;            
      else --shift until 1 is detected
         if (shift_reg_msb_1 = '1') then
            if (shift_reg_msb_2 = '1') then
              PC_ld <= '1';
              PC_next_sel <= "1010";
              mc_nstate <= START_S2_A_QP;
            else              
              PC_ld <= '1';
              PC_next_sel <= "0011";
              mc_nstate <= START_S2_A_PQ;
            end if;
         end if;

         if (s_empty = '0') then --skips first_one
            s_en <= '1';
         else
            s_rst <= '1';
            if (shift_reg_msb_1 = '1') then
               first_one_s <= '1';
            end if;
            if (field_count_zero = '1') then
               first_one_r <= '1';
               field_count_l <= '1';
               field_count_next_sel <= "11";
               PC_rst <= '1';
					if (elgamal_calc = '1') then
						mc_nstate <= ELGAMAL_DATA_LOCK;
					else	
                  mc_nstate <= WML_INIT_T2;
					end if;	
            else
               field_count_en <= '1';
               mc_nstate <= WML_S2;
            end if;
         end if;
      end if;
         -- Q = P+Q
    when START_S2_A_PQ =>
      first_one_s <= '1';
      op_start <= '1';
      mc_nstate <= S2_A_PQ;
    when S2_A_PQ =>
        if (op_done = '1') then
         if (PC = EPA_PQ_END_ADDR) then
               PC_next_sel <= "0010";
               PC_ld <= '1';
               mc_nstate <= START_S2_D_P;

         else
            mc_nstate <= START_S2_A_PQ;
            PC_en <= '1';
         end if;
        end if;
      -- P = 2*P
   when START_S2_D_P  =>
      op_start <= '1';
      mc_nstate <= S2_D_P;
    when S2_D_P =>
        if (op_done = '1') then
         if (PC = EPD_2P_END_ADDR) then
            if (s_empty = '0') then
               s_en <= '1';
               mc_nstate <= L_S2;
            else
               s_rst <= '1';
               if (field_count_zero = '1') then
                  first_one_r <= '1';
                  field_count_l <= '1';
                  field_count_next_sel <= "11";
                  PC_rst <= '1';
						if (elgamal_calc = '1') then
							mc_nstate <= ELGAMAL_DATA_LOCK;
						else	
                     mc_nstate <= WML_INIT_T2;
						end if;	
               else
                  field_count_en <= '1';
                  mc_nstate <= WML_S2;
               end if;
            end if;
         else
            mc_nstate <= START_S2_D_P;
            PC_en <= '1';
         end if;
        end if;
        -- P = Q+P
    when START_S2_A_QP =>
      first_one_s <= '1';
      op_start <= '1';
      mc_nstate <= S2_A_QP;
    when S2_A_QP =>
        if (op_done = '1') then
         if (PC = EPA_QP_END_ADDR) then
               PC_next_sel <= "1001";
               PC_ld <= '1';
               mc_nstate <= START_S2_D_Q;
         else
            mc_nstate <= START_S2_A_QP;
            PC_en <= '1';
         end if;
        end if;
        -- Q = 2*Q
   when START_S2_D_Q  =>
      op_start <= '1';
      mc_nstate <= S2_D_Q;
    when S2_D_Q =>
        if (op_done = '1') then
         if (PC = EPD_2Q_END_ADDR) then
            if (s_empty = '0') then
               s_en <= '1';
               mc_nstate <= L_S2;
            else
               s_rst <= '1';
               if (field_count_zero = '1') then
                  first_one_r <= '1';
                  field_count_l <= '1';
                  field_count_next_sel <= "11";
                  PC_rst <= '1';
						if (elgamal_calc = '1') then
							mc_nstate <= ELGAMAL_DATA_LOCK;
						else	
                     mc_nstate <= WML_INIT_T2;
						end if;	
               else
                  field_count_en <= '1';
                  mc_nstate <= WML_S2;
               end if;
            end if;
         else
            mc_nstate <= START_S2_D_Q;
            PC_en <= '1';
         end if;
        end if;     
   when FB_GEN_1_MTON =>
      lock_req <= '1';
      data_dest_sel <= "001";
      op_dest_sel <= "00111";

      if (lock_ack = '1') then
         idx_wr <= '1';
         PC_en <= '1';
         mc_nstate <= GEN_1_MTON;
      end if;
   when GEN_1_MTON =>
      --data_dest_sel <= "000";
      op_dest_sel <= "00111";
      idx_wr <= '1';
      PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         lock_release <= '1';
         PC_next_sel <= "0100";
         PC_ld <= '1';
         mc_nstate <= START_S4;
      end if;




   when ELGAMAL_DATA_LOCK =>
        lock_req <= '1';
        if (lock_ack = '1') then
            PC_rst <= '1';
--         field_count_next_sel <= "10"; --2
--         field_count_l <= '1';
--         --di_ready <= '1';
            mc_nstate <= LOAD_ELGAMAL_DATA_1;
        end if;
		  
    when LOAD_ELGAMAL_DATA_1 =>
        di_ready <= '1';
      data_dest_sel <= "011";
      op_dest_sel <= "00100";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            mc_nstate <= LOAD_ELGAMAL_DATA_2;
            end if;
        end if;
		  
   when LOAD_ELGAMAL_DATA_2 =>
        di_ready <= '1';
      data_dest_sel <= "011";
      op_dest_sel <= "00101";
        if (di_valid = '1') then
            idx_wr <= '1';
            PC_en <= '1';

            if (pc_equals_field_words_m_1 = '1') then
            PC_rst <= '1';
            lock_release <= '1';
            mc_nstate <= FB_GEN_0;
            end if;
        end if;
		  
   when FB_GEN_0 =>
      idx_wr <= '1';
      data_dest_sel <= "110";
      op_dest_sel <= "10000";
      PC_en <= '1';
      mc_nstate <= GEN_0;
		
   when GEN_0 =>
      idx_wr <= '1';
      --data_dest_sel <= "000";
      op_dest_sel <= "10000";
      PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         --PC_rst <= '1';
         lock_release <= '1';
         PC_next_sel <= "1011";
         PC_ld <= '1';
         mc_nstate <= L_START_SUB_CQ;
      end if;      
		
  when L_START_SUB_CQ => -- C-Q

      op_start <= '1';
      mc_nstate <= START_SUB_CQ;
		
   when START_SUB_CQ =>
        if (op_done = '1') then
         if (PC = EPS_CQ_END_ADDR) then
               mc_nstate <= WML_INIT_T2;
         else
            mc_nstate <= L_START_SUB_CQ;
            PC_en <= '1';      
         end if;
        end if;
		  
   when WML_INIT_T2 =>
      lock_req <= '1';
      if (lock_ack = '1') then
         PC_rst <= '1';
         mc_nstate <= L_INIT_T2;
      end if;
   when L_INIT_T2 =>
      op_a_sel <= "1001";
      mc_nstate <= INIT_T2;
   when INIT_T2 => --T2
      op_dest_sel <= "01100";
      data_dest_sel <= "100";
        idx_wr <= '1';
        PC_en <= '1';

      if (pc_equals_field_words_m_1 = '1') then
         lock_release <= '1';
         mc_nstate <= WML_S3;
      else
         mc_nstate <= L_INIT_T2;
      end if;
   when WML_S3 =>
      lock_req <= '1';
      idx_a_sel <= '1';
      if (lock_ack = '1') then
         op_a_sel <= "0110";
         mc_nstate <= L_WML_S3;
      end if;
   when L_WML_S3 =>
      s_ld <= '1';
      idx_a_sel <= '1';
      lock_release <= '1';
      mc_nstate <= L_S3;
    when L_S3 => --filter k until first one
      idx_a_sel <= '1';
      if (first_one = '1') then
         PC_ld <= '1';
         PC_next_sel <= "0110";
         mc_nstate <= START_S3_S;
      else --shift until 1 is detected
         if (shift_reg_msb_1 = '1') then
            PC_ld <= '1';
            PC_next_sel <= "0110";
            mc_nstate <= START_S3_S;
         elsif (s_empty = '0') then --only skips if not first_one
            s_en <= '1';
         else
            s_rst <= '1';
            if (shift_reg_msb_1 = '1') then
               first_one_s <= '1';
            end if;

            if (field_count_zero = '1') then
               PC_next_sel <= "0111";
               PC_ld <= '1';
               mc_nstate <= START_S3_FINAL;
            else
               field_count_en <= '1';
               mc_nstate <= WML_S3;
            end if;
         end if;
      end if;
   when START_S3_S =>
      first_one_s <= '1';
      op_start <= '1';
      mc_nstate <= S3_S;
    when S3_S =>
        if (op_done = '1') then
         if (shift_reg_msb_1 = '1') then
            PC_en <= '1';
            mc_nstate <= START_S3_M;
         else
            if (s_empty = '0') then
               s_en <= '1';
               mc_nstate <= L_S3;
            else
               s_rst <= '1';
               if (field_count_zero = '1') then
                  PC_next_sel <= "0111";
                  PC_ld <= '1';
                  mc_nstate <= START_S3_FINAL;
               else
                  field_count_en <= '1';
                  mc_nstate <= WML_S3;
               end if;
            end if;
         end if;
        end if;
   when START_S3_M =>
      op_start <= '1';
      mc_nstate <= S3_M;
    when S3_M =>
        if (op_done = '1') then
         if (s_empty = '0') then
            s_en <= '1';
            mc_nstate <= L_S3;
         else
            s_rst <= '1';
            if (field_count_zero = '1') then
               PC_next_sel <= "0111";
               PC_ld <= '1';
               mc_nstate <= START_S3_FINAL;
            else
               field_count_en <= '1';
               mc_nstate <= WML_S3;
            end if;
         end if;
        end if;
    when START_S3_FINAL =>
        op_start <= '1';
      mc_nstate <= S3_FINAL;
   when S3_FINAL =>
      if (op_done = '1') then
         PC_en <= '1';
         if (PC = PTOA_END_ADDR) then
            PC_rst <= '1';
            mc_nstate <= FB_GEN_1_MTON;
         else
            mc_nstate <= START_S3_FINAL;
         end if;
      end if;
   when START_S4 =>
      op_start <= '1';
      mc_nstate <= S4;
   when S4 =>
      if (op_done = '1') then
         PC_en <= '1';
         if (PC = MTON_END_ADDR) then
            PC_rst <= '1';
            mc_nstate <= WML_OUTPUT_X;
         else
            mc_nstate <= START_S4;
         end if;
      end if;
    when WML_OUTPUT_X =>
      lock_req <= '1';
      if (lock_ack = '1') then
         mc_nstate <= W_OUTPUT_X;
      end if;
   when W_OUTPUT_X =>
      op_a_sel <= "0011";
      PC_en <= '1';
      mc_nstate <= OUTPUT_X;
   when OUTPUT_X => --T2
      if (do_ready = '1') then
         do_valid <= '1';
         op_a_sel <= "0011";
         PC_en <= '1';

         if (pc_equals_field_words = '1') then
            PC_rst <= '1';
            mc_nstate <= W_OUTPUT_Y;
         end if;
      end if;
   when W_OUTPUT_Y =>
      op_a_sel <= "0100";
      PC_en <= '1';
      mc_nstate <= OUTPUT_Y;
   when others => -- OUTPUT_Y
      if (do_ready = '1') then
         do_valid <= '1';
         op_a_sel <= "0100";
         PC_en <= '1';

         if (pc_equals_field_words = '1') then
            lock_release <= '1';
            PC_rst <= '1';
            mc_nstate <= IDLE;
         end if;
      end if;
    end case;
end process;

end architecture structure;
