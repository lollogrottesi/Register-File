----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.04.2020 10:38:38
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

package CONSTANTS is 
function log2 (arg: integer) return integer;
end CONSTANTS;




package body CONSTANTS is
    function log2 (arg: integer) return integer is
        variable temp : integer := arg;
        variable result : integer := 0;
    begin
        while temp > 1 loop
            result := result + 1;
            temp := temp / 2;
        end loop;
        return result;
    end function log2;
end CONSTANTS;


