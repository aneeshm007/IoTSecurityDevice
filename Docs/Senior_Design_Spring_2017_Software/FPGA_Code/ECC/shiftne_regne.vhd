-------------------------------------------------------------------------------
--! @file       shiftne_regne.vhd
--! @brief      Generic register component with variable right 
--!             shifting capability
--!
--! @author     Ahmad Salman
--! @copyright  Copyright (c) 2016 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity shiftne_regne is
    GENERIC ( N : INTEGER := 128; SHIFT : INTEGER := 2 );
    PORT (
        clk     : in    STD_LOGIC;
        rstn    : in    STD_LOGIC;
        R       : in    STD_LOGIC_VECTOR( N - 1 downto 0);
        E       : in    STD_LOGIC;
        S       : in    STD_LOGIC;
        
        Q       : buffer STD_LOGIC_VECTOR( N - 1 downto 0)
    );
end shiftne_regne;

architecture shiftne_regne of shiftne_regne is
begin
    PROCESS(clk, rstn)
        BEGIN
            IF rstn = '0' THEN
                Q <= (OTHERS => '0');
            ELSIF (clk'EVENT AND clk = '1')  THEN
                IF E = '1' THEN
                    Q <= R ;
                ELSIF S = '1' THEN
                    Q <= Q(SHIFT - 1 downto 0) & Q( N - 1 downto SHIFT);
                END IF;
            END IF ;
            
    END PROCESS ;
end shiftne_regne;
