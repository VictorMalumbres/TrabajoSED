library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Simulador_Planta is
    Port ( clk, reset : in STD_LOGIC;
           en_1hz : in STD_LOGIC;
           motor : in STD_LOGIC_VECTOR(1 downto 0);
           piso_actual : out INTEGER range 0 to 3);
end Simulador_Planta;

architecture Behavioral of Simulador_Planta is
    signal piso_reg : integer range 0 to 3 := 0;
    signal contador_segundos : integer range 0 to 10 := 0; 
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                piso_reg <= 0;
                contador_segundos <= 0;
            elsif en_1hz = '1' then
                if motor /= "00" then
                    contador_segundos <= contador_segundos + 1;
                    -- Esperar 2 segundos antes de cambiar
                    if contador_segundos >= 1 then 
                        contador_segundos <= 0; 
                        if motor = "01" and piso_reg < 3 then 
                            piso_reg <= piso_reg + 1;
                        elsif motor = "10" and piso_reg > 0 then 
                            piso_reg <= piso_reg - 1;
                        end if;
                    end if;
                else
                    contador_segundos <= 0;
                end if;
            end if;
        end if;
    end process;
    piso_actual <= piso_reg;
end Behavioral;