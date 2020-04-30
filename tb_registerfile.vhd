library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use WORK.CONSTANTS.ALL;

entity TBREGISTERFILE is
end TBREGISTERFILE;

architecture TESTA of TBREGISTERFILE is

       constant M: integer := 8;        -- Number of global registers.
       constant N: integer := 2;        -- Number of registers in IN, OUT, LOCAL sections in window; dim(window) = 3*N.
       constant F: integer := 4;        -- Number of windows in register file. 
       constant word_l: integer := 8;  -- Word length.	
       
       signal CLK: std_logic := '0';
       signal RESET: std_logic;
       signal ENABLE: std_logic;
       signal RD1: std_logic;
       signal RD2: std_logic;
       signal WR: std_logic;
       signal ADD_WR: std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
       signal ADD_RD1: std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
       signal ADD_RD2: std_logic_vector(log2_ceil(3*N+M)-1 downto 0);
       signal DATAIN: std_logic_vector(word_l-1 downto 0);
       signal OUT1: std_logic_vector(word_l-1 downto 0);
       signal OUT2: std_logic_vector(word_l-1 downto 0);
       signal OUTMMU: std_logic_vector(word_l-1 downto 0);
       signal INMMU: std_logic_vector(word_l-1 downto 0);
       signal CALL, RET, FILL, SPILL: std_logic;
       
component WindowRegisterFileFSM is
    generic (M: integer := 6;        -- Number of global registers.
             N: integer := 5;        -- Number of registers in IN, OUT, LOCAL sections in window; dim(window) = 3*N.
             F: integer := 3;        -- Number of windows in register file. 
             word_l: integer := 64); -- Word length.
    port    (CLK: 	    IN std_logic;
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
end component;

--Test signalas.
--signal tmp_address: unsigned (log2_ceil(3*N+M)-1 downto 0);
--signal tmp_data_in: 
begin 

DUT: WindowRegisterFileFSM generic map(M, N, F, word_l)
                        port map(CLK, RESET, ENABLE, RD1, RD2, WR, ADD_WR, ADD_RD1, ADD_RD2, DATAIN, OUT1, OUT2, CALL, RET, INMMU, FILL , SPILL, OUTMMU);

	PCLOCK : process(CLK)
	begin
		CLK <= not(CLK) after 0.5 ns;	
	end process;
	
	PCTEST: process
	begin
	   RESET <= '1';
	   ENABLE <= '0';
	   RD1 <= '0';
	   RD2 <= '0';
	   WR <= '0';
	   CALL <= '0';
	   RET <= '0';
	   INMMU <= (others => '0');
	   ADD_WR <= (others => '0');
	   ADD_RD1 <= (others => '0');
	   ADD_RD2 <= (others => '0');
	   DATAIN <= (others => '0');
	   wait until clk = '1' and clk'event;
	   RESET <= '0';
	   ENABLE <= '1'; 
	   wait until clk = '1' and clk'event;
	   --Write all globals register.
	   WR <= '0';
	   RD1 <= '0';
	   DATAIN <= (0=> '1', others => '0');
	   wait until clk = '1' and clk'event;
	   
	   CALL <= '1';
	   wait until clk = '1' and clk'event;
	   CALL <= '0';
	   wait until clk = '1' and clk'event;
	   CALL <= '1';
	   wait until clk = '1' and clk'event;
	   CALL <= '0';
	   wait until clk = '1' and clk'event;
	   CALL <= '1';
	   wait until clk = '1' and clk'event;
	   CALL <= '0';
	   wait until clk = '1' and clk'event;
	   CALL <= '1';
	   wait until clk = '1' and clk'event;
	   CALL <= '0';
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   INMMU <= (others => '1');
	   wait until clk = '1' and clk'event;
	   RET <= '1';
	   wait until clk = '1' and clk'event;
	   RET <= '0';
	   wait until clk = '1' and clk'event;
	   RET <= '1';
	   wait until clk = '1' and clk'event;
	   RET <= '0';
	   wait until clk = '1' and clk'event;
	   RET <= '1';
	   wait until clk = '1' and clk'event;
	   RET <= '0';
	   wait until clk = '1' and clk'event;
	   RET <= '1';
	   wait until clk = '1' and clk'event;
	   RET <= '0';
	   
	   wait until clk = '1' and clk'event;
       wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;
	   wait until clk = '1' and clk'event;

       RESET <= '1';
	   ENABLE <= '0';
	   RD1 <= '0';
	   RD2 <= '0';
	   WR <= '0';
	   CALL <= '0';
	   RET <= '0';
	   INMMU <= (others => '0');
	   ADD_WR <= (others => '0');
	   ADD_RD1 <= (others => '0');
	   ADD_RD2 <= (others => '0');
	   DATAIN <= (others => '0');
	   wait until clk = '1' and clk'event;
	   RESET <= '0';
	   ENABLE <= '1'; 
	   wait until clk = '1' and clk'event;
	   --Write all globals register.
	   WR <= '1';
	   RD1 <= '0';
	   DATAIN <= (0=> '1', others => '0');
	   wait until clk = '1' and clk'event;
	   
       init_globals:for i in 0 to M-2 loop
	       ADD_WR <= std_logic_vector(unsigned (ADD_WR)+1);
	       wait until clk = '1' and clk'event;
           ADD_RD1 <= std_logic_vector(unsigned(ADD_RD1)+1);
           wait until clk = '1' and clk'event;
	       assert (unsigned(OUT1) = unsigned(DATAIN)) report "Error globals write or read";
	   end loop init_globals;

       DATAIN <= (others => '1');
            ADD_WR <= std_logic_vector(unsigned (ADD_WR)+3);
            wait until clk = '1' and clk'event;
            ADD_RD1 <= std_logic_vector(unsigned (ADD_RD1)+3);
            wait until clk = '1' and clk'event;
       init_all_windows: for window in 0 to F-2 loop
        init_all_local_in_first_window: for local in 0 to (2*N)-2 loop
            ADD_WR <= std_logic_vector(unsigned(ADD_WR)+1);
            wait until clk = '1' and clk'event;
            ADD_RD1 <= std_logic_vector(unsigned(ADD_RD1)+1);
            wait until clk = '1' and clk'event;
            assert (unsigned(OUT1) = unsigned(DATAIN)) report "Error globals write or read";
       end loop init_all_local_in_first_window;
            CALL <= '1';
            wait until clk = '1' and clk'event;
            ADD_WR <= std_logic_vector(to_unsigned(M+2, ADD_WR'length));
            CALL <= '0';
            wait until clk = '1' and clk'event;
            ADD_RD1 <= std_logic_vector(to_unsigned(M+2, ADD_WR'length));
            wait until clk = '1' and clk'event;
        end loop init_all_windows;
        nit_all_local_in_first_window: for local in 0 to (2*N)-2 loop
            ADD_WR <= std_logic_vector(unsigned(ADD_WR)+1);
            wait until clk = '1' and clk'event;
            ADD_RD1 <= std_logic_vector(unsigned(ADD_RD1)+1);
            wait until clk = '1' and clk'event;
            assert (unsigned(OUT1) = unsigned(DATAIN)) report "Error globals write or read";
       end loop nit_all_local_in_first_window;
       wait until clk = '1' and clk'event;
	wait;   
	end process;


--	RESET <= '1','0' after 5 ns;
--	ENABLE <= '1';
--	CALL <= '0';
--	RET <= '0';
--	WR <= '0','1' after 6 ns, '0' after 7 ns, '1' after 10 ns, '0' after 20 ns;
--	RD1 <= '1','0' after 5 ns, '1' after 13 ns, '0' after 20 ns; 
--	RD2 <= '0','1' after 17 ns;
--	ADD_WR <= (0=> '1', others => '0'), (1=> '0', others => '1') after 9 ns;
--	ADD_RD1 <= (2=> '1', others => '0'), (0=> '1', others => '0') after 9 ns;
--	ADD_RD2<= (0 => '1', others => '0'), (1=> '0', others => '1') after 9 ns;
--	DATAIN<= (0=> '1', others => '0'),(others => '1') after 8 ns;

end TESTA;

