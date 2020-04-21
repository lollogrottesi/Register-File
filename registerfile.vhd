library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use WORK.CONSTANTS.ALL;

entity register_file is
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
end register_file;

architecture A of register_file is

    -- suggested structure
    subtype REG_ADDR is integer range 0 to total_reg-1;  -- using integer type, define address.
    subtype WORD is std_logic_vector(word_l-1 downto 0); -- define word length.
	type REG_ARRAY is array(REG_ADDR) of WORD;           -- define type ragister.
    --Current register and Next register signal instantiation. 
    signal c_reg, n_reg: REG_ARRAY;
    --Next outputs values.
	signal next_OUT1, next_OUT2: WORD;
	signal write_op: std_logic;
begin 

--Case wr=1 and rst=1 must be handled to we defined write_op signal to avoid conflicts.
write_op <= (not RESET) and WR; 

sync_process:
    process(CLK)
    begin
        if (CLK='1' and CLK'event) then
            if (RESET = '1') then--Synchronous reset.
                c_reg <= (others => (others => '0'));
                OUT1 <= (others => 'Z');
                OUT2 <= (others => 'Z');
            else
                --Update all signals
                c_reg <= n_reg;
                OUT1 <= next_OUT1;
                OUT2 <= next_OUT2;
            end if;
        end if;
    end process sync_process;

comb_process:
    process (c_reg, ENABLE, RD1, RD2, write_op, ADD_WR, ADD_RD1, ADD_RD2, DATAIN)
    begin
    
        if (ENABLE = '0') then
            next_OUT1 <= (others => 'Z');
            next_OUT2 <= (others => 'Z');
            n_reg <= c_reg;
        else
            if (write_op = '1') then
                n_reg(to_integer(unsigned(ADD_WR))) <= DATAIN;
            else
                n_reg <= c_reg;
            end if;
                
            if (RD1 = '1') then
                next_OUT1 <= c_reg(to_integer(unsigned(ADD_RD1)));
            else
                next_OUT1 <= (others => 'Z');
            end if;
                
            if (RD2 = '1') then
                next_OUT2 <= c_reg(to_integer(unsigned(ADD_RD2)));
            else
                next_OUT2 <= (others => 'Z');
            end if;
        end if;    
    end process comb_process;
end A;

----


configuration CFG_RF_BEH of register_file is
  for A
  end for;
end configuration;
