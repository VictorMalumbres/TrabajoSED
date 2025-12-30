library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Temporizador is
    Port ( clk, reset : in STD_LOGIC;
           en_1hz : in STD_LOGIC;
           start : in STD_LOGIC;        
           duracion : in INTEGER;       
           fin_tiempo : out STD_LOGIC); 
end Temporizador;

architecture Behavioral of Temporizador is
    signal contador : integer range 0 to 10 := 0;
    signal activo : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                contador <= 0; activo <= '0'; fin_tiempo <= '0';
            else
                fin_tiempo <= '0'; 
                if start = '1' then
                    contador <= 0; activo <= '1';
                elsif activo = '1' and en_1hz = '1' then
                    if contador >= duracion - 1 then
                        fin_tiempo <= '1'; activo <= '0';
                    else contador <= contador + 1; end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;