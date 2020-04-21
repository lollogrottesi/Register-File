----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.04.2020 18:01:38
-- Design Name: 
-- Module Name: WindowRegisterFile - Structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use WORK.CONSTANTS.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

    
entity WindowRegisterFile is

    generic (M: integer := 6;        -- Number of global registers.
             N: integer := 5;        -- Number of registers in IN, OUT, LOCAL sections in window; dim(window) = 3*N.
             F: integer := 3;        -- Number of windows in register file. 
             word_l: integer := 64); -- Word length.
    port    (CLK: 	     IN std_logic;
             RESET:      IN std_logic;
             ENABLE:     IN std_logic;
             RD1: 	     IN std_logic;
             RD2: 	     IN std_logic;
             WR:         IN std_logic;
             -- Logic address have to address 3*N+M registers, one window and all globals. 
             ADD_WR:     IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
             ADD_RD1:    IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
             ADD_RD2:    IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
             DATAIN:     IN std_logic_vector(word_l-1 downto 0);
             OUT1: 	     OUT std_logic_vector(word_l-1 downto 0);
             OUT2: 	     OUT std_logic_vector(word_l-1 downto 0);
             --EXTERNAL WINDOW I/O SIGNALS TO MMU.
             CALL:       IN std_logic;
             RET:        IN std_logic;
             FILL:       OUT std_logic;
             SPILL:      OUT std_logic);
end WindowRegisterFile;

architecture Mixed of WindowRegisterFile is

component register_file is
    generic (total_reg: integer := 5;   -- Number of total register in the register file.
             word_l: integer := 64);    -- Word length per register.
    port ( CLK: 	IN std_logic;
           RESET: 	IN std_logic;
           ENABLE: 	IN std_logic;
           RD1: 	IN std_logic;
           RD2: 	IN std_logic;
           WR: 		IN std_logic;
           ADD_WR: 	IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
           ADD_RD1: IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
           ADD_RD2: IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
           DATAIN: 	IN std_logic_vector(word_l-1 downto 0);
           OUT1: 	OUT std_logic_vector(word_l-1 downto 0);
           OUT2: 	OUT std_logic_vector(word_l-1 downto 0));
end component;

--Define addresses length.
constant phy_addr_length :    integer := log2_ceil(2*N*F+M+N);
--constant windows_addr_length: integer := F;
constant logic_addr_length:   integer := log2_ceil(3*N+M);
constant global_addr_length : integer := log2_ceil(M);
--Control registers.
--subtype window_control_register is std_logic_vector(windows_addr_length-1 downto 0);      --Control register for window offset handling (from logical to physical). 
subtype physical_address is std_logic_vector(phy_addr_length-1 downto 0);                   --Total register address type, all RF is 2*N*F+M+1 registers.

signal CWP, SWP: physical_address := std_logic_vector(to_unsigned(M+3*N-1, phy_addr_length)); --(global_addr_length => '1' ,others => '0');   --At reset point at first window, 1 bit on last global address.
signal ctrl_register: std_logic_vector(F-1 downto 0) := (0=> '1', others =>'0');
signal CANSAVE, CANRESTORE: std_logic;
signal phy_addr_WR, phy_addr_RD1, phy_addr_RD2: physical_address := (others => '0'); 

begin

CANSAVE <= ctrl_register (F-1);
CANRESTORE <=  not ctrl_register (0);

total_RF: register_file generic map (2*N*F+M+1, word_l)  --N+F+M+1 = num_reg(total_RF).
                        port map (CLK, RESET, ENABLE, RD1, RD2, WR, phy_addr_WR, phy_addr_RD1, phy_addr_RD2, DATAIN, OUT1, OUT2);
        
Sequential:process(CLK, CALL, RET)
        begin
            if (CLK='1' and CLK'event) then
                if (CALL = '1') then
                    if (CANSAVE = '0') then
                        ctrl_register  <= std_logic_vector(shift_left(unsigned(ctrl_register), 1));
                        CWP <= std_logic_vector(unsigned(CWP) + 2*N);
                        SPILL <= '0';
                    else 
                        --CANSAVE <= std_logic_vector(shift_right(unsigned(CANSAVE), 1));
                        SPILL <= '1';
                    end if;
                if (RET = '1') then
                    if (CANRESTORE = '1') then
                        ctrl_register  <= std_logic_vector(rotate_right(unsigned(ctrl_register), 1));
                        CWP <= std_logic_vector(unsigned(CWP) - 2*N);
                    else
                        FILL <= '1';
                    end if;
                end if;    
                end if;
            end if;
        end process;

      
Datapath: process(CWP, SWP, ADD_WR, ADD_RD1, ADD_RD2)
        begin
          -- We are considering the first location (lower addresses) of the physical register the global one, so it coincde with the logicl if MSBs in this are zeros. 
          if (to_integer(unsigned(ADD_WR)) < M) then
          --Global address.
                phy_addr_WR(global_addr_length-1 downto 0) <= ADD_WR (global_addr_length-1 downto 0);
                phy_addr_WR(phy_addr_length-1 downto global_addr_length) <= (others => '0');
          else
          --Local window access.
          		--Physical addr = CWP - M - N*3 + logical_address + 1
          		--phy_addr_WR <= std_logic_vector(to_unsigned((to_integer(unsigned(CWP)) + to_integer(unsigned(ADD_WR)) - 3*N - M + 1), phy_addr_length)); 
          		phy_addr_WR <= std_logic_vector(unsigned(CWP) + unsigned(ADD_WR) - 3*N - M + 1);     
          end if;  
          
          if (to_integer(unsigned(ADD_RD1)) < M) then
          --Global address.
                phy_addr_RD1(global_addr_length-1 downto 0) <= ADD_RD1 (global_addr_length-1 downto 0);
                phy_addr_RD1(phy_addr_length-1 downto global_addr_length) <= (others => '0');
          else
          --Local window access.
          		--Physical addr = CWP - M - N*3 + logical_address + 1
          		phy_addr_RD1 <= std_logic_vector(unsigned(CWP) + unsigned(ADD_RD1) - 3*N - M + 1);
          end if; 
          
          if (to_integer(unsigned(ADD_RD2)) < M) then
          --Global address.
                phy_addr_RD2(global_addr_length-1 downto 0) <= ADD_RD2 (global_addr_length-1 downto 0);
                phy_addr_RD2(phy_addr_length-1 downto global_addr_length) <= (others => '0');
          else
          --Local window access.
          		--Physical addr = CWP - M - N*3 + logical_address + 1
          		phy_addr_RD2 <= std_logic_vector(unsigned(CWP) + unsigned(ADD_RD2) - 3*N - M + 1);
          end if; 
        end process Datapath;
end Mixed;
