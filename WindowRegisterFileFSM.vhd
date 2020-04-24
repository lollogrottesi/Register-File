----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2020 16:43:06
-- Design Name: 
-- Module Name: WindowRegisterFileFSM - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use WORK.CONSTANTS.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity WindowRegisterFileFSM is
    generic (M: integer := 6;        -- Number of global registers.
             N: integer := 5;        -- Number of registers in IN, OUT, LOCAL sections in window; dim(window) = 3*N.
             F: integer := 3;        -- Number of windows in register file. 
             word_l: integer := 64); -- Word length.
    port   (CLK: 	    IN std_logic;
            RESET:      IN std_logic;
            ENABLE:     IN std_logic;
            RD1: 	    IN std_logic;
            RD2: 	    IN std_logic;
            WR:         IN std_logic;
    -- Logic address have to address 3*N+M registers, one window and all globals. 
            ADD_WR:     IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
            ADD_RD1:    IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
            ADD_RD2:    IN std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
            DATAIN:     IN std_logic_vector(word_l-1 downto 0);
            OUT1: 	    OUT std_logic_vector(word_l-1 downto 0);
            OUT2: 	    OUT std_logic_vector(word_l-1 downto 0);
    --EXTERNAL WINDOW I/O SIGNALS TO MMU.
            CALL:       IN std_logic;
            RET:        IN std_logic;
            IN_FROM_MMU:IN std_logic_vector(word_l-1 downto 0);
            FILL:       OUT std_logic;
            SPILL:      OUT std_logic;
            OUT_TO_MMU: OUT std_logic_vector(word_l-1 downto 0));
end WindowRegisterFileFSM;

architecture Behavioral of WindowRegisterFileFSM is

    component register_file is
        generic (total_reg: integer := 5;   -- Number of total register in the register file.
                 word_l: integer := 64);    -- Word length per register.
        port    (CLK: 	IN std_logic;
                RESET: 	IN std_logic;
                ENABLE: IN std_logic;
                RD1: 	IN std_logic;
                RD2: 	IN std_logic;
                WR: 	IN std_logic;
                ADD_WR: IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
                ADD_RD1:IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
                ADD_RD2:IN std_logic_vector(log2_ceil(total_reg)-1 downto 0);
                DATAIN: IN std_logic_vector(word_l-1 downto 0);
                OUT1: 	OUT std_logic_vector(word_l-1 downto 0);
                OUT2: 	OUT std_logic_vector(word_l-1 downto 0));
    end component;

--Define addresses length.
constant phy_addr_length:     integer := log2_ceil(2*N*F+M+N);
constant logic_addr_length:   integer := log2_ceil(3*N+M);
constant global_addr_length:  integer := log2_ceil(M);
constant window_addr_length:  integer := log2_ceil(3*N*F);
constant n_local:             integer := 2*N*F+N;
--Control registers.
subtype physical_address is std_logic_vector(phy_addr_length-1 downto 0);--Total register address type, all RF is 2*N*F+M+1 registers.
subtype logical_address is std_logic_vector(logic_addr_length-1 downto 0);

signal CWP: physical_address := (others=> '0');
signal SWP: physical_address := std_logic_vector(to_unsigned(2*N*F-N ,phy_addr_length));
signal ctrl_register: std_logic_vector(F-1 downto 0) := (0=> '1', others =>'0');
signal CANSAVE, CANRESTORE: std_logic;
signal tmp_ADD_RD1: logical_address;
signal phy_addr_WR, phy_addr_RD1, phy_addr_RD2: physical_address := (others => '0'); 
type Statetype is (s0, idle, call_state, ret_state, spill_state);
signal c_state, n_state : Statetype := s0;
signal c_cnt, n_cnt: std_logic_vector(window_addr_length-1 downto 0) := (others => '0'); 
signal tmp_in, tmp_out1, tmp_out2: std_logic_vector(word_l-1 downto 0);

begin
  RF: register_file generic map (2*N*F+N+M, word_l)  --N+F+M+1 = num_reg(total_RF).
        port map (CLK, RESET, ENABLE, RD1, RD2, WR, phy_addr_WR, phy_addr_RD1, phy_addr_RD2, tmp_in, tmp_out1, tmp_out2);   

CANSAVE <= '1';

Address_traslation:        
    process (ADD_WR, ADD_RD1, ADD_RD2)
    begin
        if (unsigned (ADD_WR) < 3*N) then
            --Local address.
            phy_addr_WR <= std_logic_vector((unsigned(ADD_WR) + unsigned (CWP)) mod n_local);
        else
            --Global. ADDR_WR + 2*N*F - 2*N = global_address.
            phy_addr_WR <= std_logic_vector(to_unsigned((to_integer(unsigned(ADD_WR)) + 2*N*F-2*N), phy_addr_length));
        end if;
        
        if (unsigned (ADD_RD1) < 3*N) then
            --Local address.
            phy_addr_RD1 <= std_logic_vector((unsigned(tmp_ADD_RD1) + unsigned (CWP)) mod n_local);
        else
            --Global. ADDR_RD1 + 2*N*F - 2*N = global_address.
            phy_addr_RD1 <= std_logic_vector(to_unsigned((to_integer(unsigned(tmp_ADD_RD1)) + 2*N*F-2*N), phy_addr_length));
        end if;      
        
       if (unsigned (ADD_RD2) < 3*N) then
            --Local address.
            phy_addr_RD2 <= std_logic_vector((unsigned(ADD_RD2) + unsigned (CWP)) mod n_local);
        else
            --Global. ADDR_RD2 + 2*N*F - 2*N = global_address.
            phy_addr_RD2 <= std_logic_vector(to_unsigned((to_integer(unsigned(ADD_RD2)) + 2*N*F-2*N), phy_addr_length));
        end if;  
    end process Address_traslation;   
     
--Final state machine.    
sync_process_FSM:
    process(CLK, RESET)
    begin
        if (CLK='1'and CLK'event) then
            if (RESET='1') then
                c_state <= s0;
                c_cnt <= (others =>'0');
            else
                c_state <= n_state;
                c_cnt <= n_cnt;
            end if;
        end if;
    end process sync_process_FSM;
    
comb_process_FSM:
    process(c_state, c_cnt, RET, CALL, IN_FROM_MMU, DATAIN, ADD_RD1, tmp_out1, tmp_out2)
    begin
        case c_state is
            when s0 =>
                CWP <= (others =>'0');
                SWP <= std_logic_vector(to_unsigned(2*N*F-N ,phy_addr_length));
                tmp_in <= DATAIN;
                tmp_ADD_RD1 <= ADD_RD1;
                OUT1 <= tmp_out1;
                OUT2 <= tmp_out2;
                n_cnt <= c_cnt;
                n_state <= idle;
                SPILL <= '0';
                FILL <= '0';
            when idle =>
                SPILL <= '0';
                FILL <= '0';
                tmp_in <= DATAIN;
                tmp_ADD_RD1 <= ADD_RD1;
                OUT1 <= tmp_out1;
                OUT2 <= tmp_out2; 
                n_cnt <= c_cnt;
                if (CALL = '1') then
                    n_state <= call_state;
                    CWP <= std_logic_vector((unsigned (CWP) + 2*N) mod n_local);
                    --Update CANSAVE.
                elsif (RET = '1') then
                    n_state <= ret_state;
                else
                    n_state <= c_state;    
                end if; 
                
            when call_state =>
                OUT2 <= tmp_out2;
                if (CANSAVE = '1') then
                --Normal call.
                    tmp_ADD_RD1 <= ADD_RD1;
                    tmp_in <= DATAIN;
                    OUT1 <= tmp_out1; 
                    n_state <= idle;
                    n_cnt <= c_cnt;    
                else
                --SPILL.
                    --SPILL FIRST LOCAL. 
                    n_cnt <= std_logic_vector(unsigned(c_cnt) + 1);
                    SWP <= std_logic_vector((unsigned (SWP) + 2*N) mod n_local);   
                    tmp_in <= DATAIN;
                    tmp_ADD_RD1 <= std_logic_vector((unsigned (SWP) + 2*N) mod n_local);
                    OUT_TO_MMU <= tmp_out1;
                    OUT1 <= (others =>'Z');   
                    SPILL <= '1'; 
                    --COUNT REST LOCALS.
                    n_state <= spill_state;
                end if;
            when spill_state =>
                if (unsigned (c_cnt) < 2*N) then
                    SPILL <= '1';
                    n_cnt <= std_logic_vector(unsigned(c_cnt) + 1);
                    tmp_ADD_RD1 <= std_logic_vector((unsigned (SWP) + unsigned (c_cnt)) mod n_local);
                    n_state <= c_state;
                else
                    n_state <= idle;
                    SPILL <= '0';
                    OUT1 <= tmp_out1;
                end if;
            when others=>
                tmp_in <= DATAIN;
                tmp_ADD_RD1 <= ADD_RD1;
                OUT1 <= tmp_out1;
                OUT2 <= tmp_out2; 
                c_cnt <= n_cnt;
        end case;
    end process comb_process_FSM;    
    
end Behavioral;
