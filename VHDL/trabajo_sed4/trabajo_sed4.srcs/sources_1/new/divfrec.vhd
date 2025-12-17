library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Divisor_Frecuencia is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           en_1hz : out STD_LOGIC;    -- 1 seg (Motor/Timer)
           en_disp : out STD_LOGIC;   -- 1 kHz (Refresco Display)
           en_blink : out STD_LOGIC;  -- 5 Hz (Parpadeo Emergencia)
           en_anim : out STD_LOGIC);  -- 20 Hz (LEDs Puerta)
end Divisor_Frecuencia;

architecture Behavioral of Divisor_Frecuencia is
    signal c_1hz : integer range 0 to 100000000 := 0;
    signal c_disp : integer range 0 to 100000 := 0;
    signal c_blink : integer range 0 to 20000000 := 0; -- 5Hz
    signal c_anim : integer range 0 to 5000000 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                c_1hz <= 0; c_disp <= 0; c_blink <= 0; c_anim <= 0;
                en_1hz <= '0'; en_disp <= '0'; en_blink <= '0'; en_anim <= '0';
            else
                -- 1 Hz
                if c_1hz = 99999999 then c_1hz <= 0; en_1hz <= '1';
                else c_1hz <= c_1hz + 1; en_1hz <= '0'; end if;
                
                -- Display Refresh
                if c_disp = 99999 then c_disp <= 0; en_disp <= '1';
                else c_disp <= c_disp + 1; en_disp <= '0'; end if;

                -- Blink (Parpadeo)
                if c_blink = 9999999 then c_blink <= 0; en_blink <= '1'; -- Genera pulso
                else c_blink <= c_blink + 1; en_blink <= '0'; end if;

                -- Animación LED
                if c_anim = 4999999 then c_anim <= 0; en_anim <= '1';
                else c_anim <= c_anim + 1; en_anim <= '0'; end if;
            end if;
        end if;
    end process;
end Behavioral;