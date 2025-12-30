library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Simulador_Planta is
    Port ( clk, reset : in STD_LOGIC;
           en_1hz : in STD_LOGIC;
           motor : in STD_LOGIC_VECTOR(1 downto 0); 
           motor_hor : in STD_LOGIC_VECTOR(1 downto 0); 
           piso_actual : out INTEGER range 0 to 3;
           hab_actual : out INTEGER range 1 to 4);
end Simulador_Planta;

architecture Behavioral of Simulador_Planta is
    signal p_reg : integer range 0 to 3 := 0;
    signal h_reg : integer range 1 to 4 := 1;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then p_reg <= 0; h_reg <= 1;
            elsif en_1hz = '1' then
                if motor = "01" and p_reg < 3 then p_reg <= p_reg + 1;
                elsif motor = "10" and p_reg > 0 then p_reg <= p_reg - 1;
                end if;
                if motor_hor = "01" and h_reg < 4 then h_reg <= h_reg + 1;
                elsif motor_hor = "10" and h_reg > 1 then h_reg <= h_reg - 1;
                end if;
            end if;
        end if;
    end process;
    piso_actual <= p_reg; hab_actual <= h_reg;
end Behavioral;