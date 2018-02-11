-------------------------------------------------------------------------------
--! @file       ECC_Mult_LW_Top.vhd
--! @brief      ECC Multiplier LightWeight Top
--!
--! @author     Ahmad Salman
--!             Ahmed Ferozpuri
--!             Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ECC_Mult_LW_Top is
    generic (
        G_N                 : integer := 5;
        G_W                 : integer := 16;
        G_PE                : integer := 2
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
        di_data             : in  std_logic_vector(G_W          -1 downto 0);
        do_ready            : in  std_logic;
        busy                : out std_logic;
        di_ready            : out std_logic;
        do_valid            : out std_logic;
        do_data             : out std_logic_vector(G_W          -1 downto 0);
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
end entity ECC_Mult_LW_Top;

architecture structure of ECC_Mult_LW_Top is
    --! MAS
    signal mas_start            : std_logic;
    signal mas_busy             : std_logic;
    signal mas_done             : std_logic;
    signal mas_op_subtract      : std_logic;
    signal mas_sched_op_a       : std_logic_vector(5           -1 downto 0);
    signal mas_sched_op_b       : std_logic_vector(5           -1 downto 0);
    signal mas_sched_op_dest    : std_logic_vector(5           -1 downto 0);
    signal mas_op_a             : std_logic_vector(5           -1 downto 0);
    signal mas_op_b             : std_logic_vector(5           -1 downto 0);
    signal mas_op_dest          : std_logic_vector(5           -1 downto 0);
    signal mas_lock_req         : std_logic;
    signal mas_lock_ack         : std_logic;
    signal mas_lock_release     : std_logic;
    signal mas_idx_a            : std_logic_vector(G_N+1       -1 downto 0);
    signal mas_idx_b            : std_logic_vector(G_N+1       -1 downto 0);
    signal mas_idx_dest         : std_logic_vector(G_N+1       -1 downto 0);
    signal mas_idx_wr           : std_logic;
    signal mas_data_dest        : std_logic_vector(G_W         -1 downto 0);
    --! MMM
    signal mmm_start            : std_logic;
    signal mmm_done             : std_logic;
    signal mmm_sched_op_a       : std_logic_vector(5           -1 downto 0);
    signal mmm_sched_op_b       : std_logic_vector(5           -1 downto 0);
    signal mmm_sched_op_dest    : std_logic_vector(5           -1 downto 0);
    signal mmm_op_a             : std_logic_vector(5           -1 downto 0);
    signal mmm_op_b             : std_logic_vector(5           -1 downto 0);
    signal mmm_op_dest          : std_logic_vector(5           -1 downto 0);
    signal mmm_lock_req         : std_logic;
    signal mmm_lock_ack         : std_logic;
    signal mmm_lock_release     : std_logic;
    signal mmm_idx_a            : std_logic_vector(G_N+1       -1 downto 0);
    signal mmm_idx_b            : std_logic_vector(G_N+1       -1 downto 0);
    signal mmm_idx_dest         : std_logic_vector(G_N+1       -1 downto 0);
    signal mmm_idx_wr           : std_logic;
    signal mmm_data_dest        : std_logic_vector(G_W         -1 downto 0);
    --! MMM and MAS comm
    signal mmm2mas_start        : std_logic;
    signal mmm2mas_op_dest      : std_logic_vector(5           -1 downto 0);
    signal mmm2mas_reduce       : std_logic;
    --! MC
    signal field_size           : std_logic_vector(3           -1 downto 0);
    signal field_words          : std_logic_vector(G_N+1       -1 downto 0);
    signal mc_op_a              : std_logic_vector(5           -1 downto 0);
    signal mc_op_b              : std_logic_vector(5           -1 downto 0);
    signal mc_op_dest           : std_logic_vector(5           -1 downto 0);
    signal mc_lock_req          : std_logic;
    signal mc_lock_ack          : std_logic;
    signal mc_lock_release      : std_logic;
    signal mc_idx_a             : std_logic_vector(G_N+1       -1 downto 0);
    signal mc_idx_b             : std_logic_vector(G_N+1       -1 downto 0);
    signal mc_idx_dest          : std_logic_vector(G_N+1       -1 downto 0);
    signal mc_idx_wr            : std_logic;
    signal mc_data_dest         : std_logic_vector(G_W         -1 downto 0);
    --! Memory Controller
    signal data_a               : std_logic_vector(G_W         -1 downto 0);
    signal data_b               : std_logic_vector(G_W         -1 downto 0);
begin
    u_mas: entity work.MAS_LW
    generic map(
        G_N                         => G_N                  ,
        G_W                         => G_W
    )
    port map (
        --! Global
        rstn                        => rstn                 ,
        clk                         => clk                  ,
        --! Main Control
        start                       => mas_start            ,
        busy                        => mas_busy             ,
        done                        => mas_done             ,
        op_subtract                 => mas_op_subtract      ,
        sched_op_a                  => mas_sched_op_a       ,
        sched_op_b                  => mas_sched_op_b       ,
        sched_op_dest               => mas_sched_op_dest    ,
        field_size                  => field_size           ,
        field_words                 => field_words          ,
        --! MMM
        mmm_start                   => mmm2mas_start        ,
        mmm_op_dest                 => mmm2mas_op_dest      ,
        mmm_reduce                  => mmm2mas_reduce       ,
        --! Memory controller
        lock_ack                    => mas_lock_ack         ,
        lock_req                    => mas_lock_req         ,
        lock_release                => mas_lock_release     ,
        op_a                        => mas_op_a             ,
        op_b                        => mas_op_b             ,
        op_dest                     => mas_op_dest          ,
        idx_a                       => mas_idx_a            ,
        idx_b                       => mas_idx_b            ,
        idx_dest                    => mas_idx_dest         ,
        idx_wr                      => mas_idx_wr           ,
        data_a                      => data_a               ,
        data_b                      => data_b               ,
        data_dest                   => mas_data_dest
    );

    u_mmm: entity work.MMM_LW
    generic map(
        G_N                         => G_N                  ,
        G_W                         => G_W                  ,
        G_PE                        => G_PE
    )
    port map (
        --! Global
        rstn                        => rstn                 ,
        clk                         => clk                  ,
        --! Main Control
        start                       => mmm_start            ,
        done                        => mmm_done             ,
        sched_op_a                  => mmm_sched_op_a       ,
        sched_op_b                  => mmm_sched_op_b       ,
        sched_op_dest               => mmm_sched_op_dest    ,
        field_size                  => field_size           ,
        --! MAS-Comm
        mas_busy                    => mas_busy             ,
        mas_start                   => mmm2mas_start        ,
        mas_op_dest                 => mmm2mas_op_dest      ,
        mas_reduce                  => mmm2mas_reduce       ,
        --! Memory controller
        lock_ack                    => mmm_lock_ack         ,
        lock_req                    => mmm_lock_req         ,
        lock_release                => mmm_lock_release     ,
        op_a                        => mmm_op_a             ,
        op_b                        => mmm_op_b             ,
        op_dest                     => mmm_op_dest          ,
        idx_a                       => mmm_idx_a            ,
        idx_b                       => mmm_idx_b            ,
        idx_dest                    => mmm_idx_dest         ,
        idx_wr                      => mmm_idx_wr           ,
        data_a                      => data_a               ,
        data_b                      => data_b               ,
        data_dest                   => mmm_data_dest
    );

    u_mc: entity work.ECC_Mult_LW_Scheduler
    generic map (
        G_N                         => G_N                  ,
        G_W                         => G_W
    )
    port map (
        --! Global
        rstn                        => rstn                 ,
        clk                         => clk                  ,
        --! External
        elgamal_calc                => elgamal_calc,
        start                       => start                ,
        init_field                  => init_field           ,
        init_curve                  => init_curve           ,
        busy                        => busy                 ,
        di_valid                    => di_valid             ,
        di_ready                    => di_ready             ,
        di_data                     => di_data              ,
        do_valid                    => do_valid             ,
        do_ready                    => do_ready             ,
        do_data                     => do_data              ,
        --! MAS
        mas_sched_op_a              => mas_sched_op_a       ,
        mas_sched_op_b              => mas_sched_op_b       ,
        mas_sched_op_dest           => mas_sched_op_dest    ,
        mas_start                   => mas_start            ,
        mas_done                    => mas_done             ,
        mas_op_subtract             => mas_op_subtract      ,
        --! MMMM
        mmm_sched_op_a              => mmm_sched_op_a       ,
        mmm_sched_op_b              => mmm_sched_op_b       ,
        mmm_sched_op_dest           => mmm_sched_op_dest    ,
        mmm_start                   => mmm_start            ,
        mmm_done                    => mmm_done             ,
        --! MAS & MMM
        field_size                  => field_size           ,
        field_words                 => field_words          ,
        --! Memory controller
        lock_ack                    => mc_lock_ack          ,
        lock_req                    => mc_lock_req          ,
        lock_release                => mc_lock_release      ,
        op_a                        => mc_op_a              ,
        op_b                        => mc_op_b              ,
        op_dest                     => mc_op_dest           ,
        idx_a                       => mc_idx_a             ,
        idx_b                       => mc_idx_b             ,
        idx_dest                    => mc_idx_dest          ,
        idx_wr                      => mc_idx_wr            ,
        data_a                      => data_a               ,
        data_b                      => data_b               ,
        data_dest                   => mc_data_dest
    );

    u_memctrl: entity work.Mem_Ctrl_LW
    generic map (
        G_N                         => G_N                  ,
        G_W                         => G_W
    )
    port map (
        --! Global
        rstn                        => rstn                 ,
        clk                         => clk                  ,
        --! MAS
        mas_lock_ack                => mas_lock_ack         ,
        mas_lock_req                => mas_lock_req         ,
        mas_lock_release            => mas_lock_release     ,
        mas_op_a                    => mas_op_a             ,
        mas_op_b                    => mas_op_b             ,
        mas_op_dest                 => mas_op_dest          ,
        mas_idx_a                   => mas_idx_a            ,
        mas_idx_b                   => mas_idx_b            ,
        mas_idx_dest                => mas_idx_dest         ,
        mas_idx_wr                  => mas_idx_wr           ,
        mas_data_dest               => mas_data_dest        ,
        --! MMM
        mmm_lock_ack                => mmm_lock_ack         ,
        mmm_lock_req                => mmm_lock_req         ,
        mmm_lock_release            => mmm_lock_release     ,
        mmm_op_a                    => mmm_op_a             ,
        mmm_op_b                    => mmm_op_b             ,
        mmm_op_dest                 => mmm_op_dest          ,
        mmm_idx_a                   => mmm_idx_a            ,
        mmm_idx_b                   => mmm_idx_b            ,
        mmm_idx_dest                => mmm_idx_dest         ,
        mmm_idx_wr                  => mmm_idx_wr           ,
        mmm_data_dest               => mmm_data_dest        ,
        --! MC
        field_size                  => field_size           ,
        field_words                 => field_words          ,
        mc_lock_ack                 => mc_lock_ack          ,
        mc_lock_req                 => mc_lock_req          ,
        mc_lock_release             => mc_lock_release      ,
        mc_op_a                     => mc_op_a              ,
        mc_op_b                     => mc_op_b              ,
        mc_op_dest                  => mc_op_dest           ,
        mc_idx_a                    => mc_idx_a             ,
        mc_idx_b                    => mc_idx_b             ,
        mc_idx_dest                 => mc_idx_dest          ,
        mc_idx_wr                   => mc_idx_wr            ,
        mc_data_dest                => mc_data_dest         ,
        --! Memory data
        data_a                      => data_a               ,
        data_b                      => data_b               ,
        --! RAM-1
        ram1_addr_a                 => ram1_addr_a          ,
        ram1_data_a                 => ram1_data_a          ,
        ram1_addr_b                 => ram1_addr_b          ,
        ram1_data_b                 => ram1_data_b          ,
        ram1_wr_data                => ram1_wr_data         ,
        ram1_wr_en                  => ram1_wr_en           ,
        --! RAM-2
        ram2_addr_a                 => ram2_addr_a          ,
        ram2_data_a                 => ram2_data_a          ,
        ram2_addr_b                 => ram2_addr_b          ,
        ram2_data_b                 => ram2_data_b          ,
        ram2_wr_data                => ram2_wr_data         ,
        ram2_wr_en                  => ram2_wr_en
    );
end architecture structure;