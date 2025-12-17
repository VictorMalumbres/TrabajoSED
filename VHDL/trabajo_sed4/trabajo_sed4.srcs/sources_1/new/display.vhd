library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controlador_Display is
    Port ( clk, en_disp, en_blink, en_anim : in STD_LOGIC;
           piso : in INTEGER range 0 to 3;
           estado_vis : in INTEGER range 0 to 6;
           puerta_abierta : in STD_LOGIC;
           
           seg : out STD_LOGIC_VECTOR(6 downto 0);
           an : out STD_LOGIC_VECTOR(7 downto 0);
           leds : out STD_LOGIC_VECTOR(15 downto 0));
end Controlador_Display;

architecture Behavioral of Controlador_Display is
    signal mux : integer range 0 to 3 := 0;
    signal led_level : integer range 0 to 16 := 0;
    signal blink_state : std_logic := '0';
begin
    
    -- Generador de parpadeo (flip-flop simple usando en_blink)
    process(clk)
    begin
        if rising_edge(clk) then
            if en_blink = '1' then
                blink_state <= not blink_state;
            end if;
        end if;
    end process;

    -- Multiplexado Display
    process(clk)
    begin
        if rising_edge(clk) then
            if en_disp = '1' then
                if mux = 3 then mux <= 0; else mux <= mux + 1; end if;
                
                an <= "11111111"; 
                
                -- MODO PARPADEO TOTAL (EMERGENCIA FASE 2)
                if estado_vis = 6 then
                    -- Encendemos todos los anodos y segmentos si blink_state es 1
                    if blink_state = '1' then
                        an <= "00000000"; -- Todos los digitos activos
                        seg <= "0000000"; -- Todos los segmentos (8)
                    else
                        an <= "11111111"; -- Todos apagados
                    end if;
                
                -- MODOS NORMALES Y EMERGENCIA 'E'
                else
                    case mux is
                        when 0 => -- Piso (Derecha)
                            an(0) <= '0';
                            case piso is
                                when 0 => seg <= "1000000"; -- 0
                                when 1 => seg <= "1111001"; -- 1
                                when 2 => seg <= "0100100"; -- 2
                                when 3 => seg <= "0110000"; -- 3
                                when others => seg <= "1111111";
                            end case;
                        when 1 => -- Letra F
                            an(1) <= '0'; seg <= "0001110";
                        when 2 => -- Guion
                            an(2) <= '0'; seg <= "0111111";
                        when 3 => -- Estado (Izquierda)
                            an(3) <= '0';
                            case estado_vis is
                                when 0 => seg <= "0001100"; -- P (Parado)
                                when 1 => seg <= "0010010"; -- S (Subiendo)
                                when 2 => seg <= "0000011"; -- b (Bajando)
                                when 3 => seg <= "1000000"; -- O (Open)
                                when 4 => seg <= "1000110"; -- C (Close)
                                when 5 => seg <= "0000110"; -- E (Emergency/Error)
                                when others => seg <= "1111111";
                            end case;
                    end case;
                end if;
            end if;
            
            -- Animación LEDs
            if en_anim = '1' then
                if puerta_abierta = '1' then
                    if led_level < 16 then led_level <= led_level + 1; end if;
                else
                    if led_level > 0 then led_level <= led_level - 1; end if;
                end if;
            end if;
            
            for i in 0 to 15 loop
                if i < led_level then leds(i) <= '1'; else leds(i) <= '0'; end if;
            end loop;
        end if;
    end process;
end Behavioral;