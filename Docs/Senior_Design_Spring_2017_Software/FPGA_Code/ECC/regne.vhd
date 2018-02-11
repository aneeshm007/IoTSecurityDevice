-------------------------------------------------------------------------------
--! @file       regne.vhd
--! @brief      Generic register component
--!
--! @author     Ahmad Salman
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY regne IS
    GENERIC ( N : INTEGER := 64 );
    PORT (
        clk     : IN    STD_LOGIC;
        rstn    : IN    STD_LOGIC;
        R       : IN    STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        E       : IN    STD_LOGIC;
        Q       : OUT   STD_LOGIC_VECTOR(N-1 DOWNTO 0)
    );
END regne;

ARCHITECTURE Behavior OF regne IS   
BEGIN
    PROCESS(clk, rstn)
        BEGIN
            IF rstn = '0' THEN
                Q <= (OTHERS => '0');
            ELSIF (clk'EVENT AND clk = '1')  THEN
                IF E = '1' THEN
                    Q <= R ;
                END IF;
            END IF ;
    END PROCESS ;
END Behavior ;
