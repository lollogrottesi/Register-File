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
use WORK.CONSTANTS.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity WindowRegisterFile is

    generic (M: integer := 6;        -- Address global registers, num(global regs) = 2**M. 
             N: integer := 5;        -- Address IN, OUT, LOCAL in window, dim(window) = 3*(2**N).
             F: integer := 3;        -- Address of windows, num(windows) = 2**F.
             word_l: integer := 64); -- Word length.
    port    (CLK: 	     IN std_logic;
             RESET:      IN std_logic;
             ENABLE:     IN std_logic;
             RD1: 	     IN std_logic;
             RD2: 	     IN std_logic;
             WR:         IN std_logic;
             --IF we assume 2**N << 2**M, simply use M+1 bits.
             --Asuming 2**N = 2**M easy case.
             --External register := (2**N)*3 + 2**M => (2**N)*4 + 2**M =>  2**(N+2) + 2**M
             --Num bit for windows addressing := N+F+2.
             --Num bit for global addresssing := M
             --Total address := M&(N+2) => std_logic_vector(M+N+1 downto 0).  
             ADD_WR:     IN std_logic_vector(M+N+1 downto 0);
             ADD_RD1:    IN std_logic_vector(M+N+1 downto 0);
             ADD_RD2:    IN std_logic_vector(M+N+1 downto 0);
             DATAIN:     IN std_logic_vector(word_l-1 downto 0);
             OUT1: 	     OUT std_logic_vector(word_l-1 downto 0);
             OUT2: 	     OUT std_logic_vector(word_l-1 downto 0);
             --EXTERNAL WINDOW I/O SIGNALS.
             CALL:       IN std_logic;
             RET:        IN std_logic;
             FILL:       IN std_logic;
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
           ADD_WR: 	IN std_logic_vector(log2(total_reg)-1 downto 0);
           ADD_RD1: IN std_logic_vector(log2(total_reg)-1 downto 0);
           ADD_RD2: IN std_logic_vector(log2(total_reg)-1 downto 0);
           DATAIN: 	IN std_logic_vector(word_l-1 downto 0);
           OUT1: 	OUT std_logic_vector(word_l-1 downto 0);
           OUT2: 	OUT std_logic_vector(word_l-1 downto 0));
end component;

--Control registers.
subtype control_register is std_logic_vector(N+F downto 0);
signal CWP, SWP: control_register;
signal phy_addr_WR, phy_addr_RD1, phy_addr_RD2: control_register; 
--Selection signals.
signal enable_windows, enable_global: std_logic;
signal window_word_addr, global_word_addr: std_logic;
begin
-- Rivedere i 2 bit da usare...
enable_global <= (ADD_WR(1) and ADD_WR(0)) or (ADD_RD1(1) and ADD_RD1(0)) or (ADD_RD2(1) and ADD_RD2(0));
enable_windows <= not enable_global; 

RF_windows : register_file generic map (N+F+1, word_l)  --2**(N+1+F) = num_reg(total_RF) - num_reg(global).
                   port map (CLK, RESET, enable_windows, RD1, RD2, WR, phy_addr_WR, phy_addr_RD1, phy_addr_RD2, DATAIN, OUT1, OUT2);
RF_global: register_file generic map (M, word_l)        --Gloabal register file.
                   port map (CLK, RESET, enable_global, RD1, RD2, WR, ADD_WR(M+N+F downto N+F+1), ADD_RD1(M+N+F downto N+F+1), ADD_RD2(M+N+F downto N+F+1), DATAIN, OUT1, OUT2);

    process(enable_windows, CWP, SWP, RD1, RD2, WR, DATAIN, CALL, RET, FILL, ADD_WR, ADD_RD1, ADD_RD2)
    begin
        if (enable_windows = '1') then
            phy_addr_WR <=  std_logic_vector(unsigned(CWP) + unsigned(ADD_WR(N+F+1 downto 0)));
            phy_addr_RD1 <= std_logic_vector(unsigned(CWP) + unsigned(ADD_RD1(N+F+1 downto 0)));
            phy_addr_RD2 <= std_logic_vector(unsigned(CWP) + unsigned(ADD_RD2(N+F+1 downto 0))); 
        end if;
    end process;
end Mixed;
