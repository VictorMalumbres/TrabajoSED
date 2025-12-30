library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controlador_Display is
    Port ( clk, en_disp, en_blink, en_anim : in STD_LOGIC;
           piso : in INTEGER range 0 to 3;
           habitacion : in INTEGER range 1 to 4; 
           estado_vis : in INTEGER range 0 to 8;
           puerta_abierta : in STD_LOGIC;
           seg : out STD_LOGIC_VECTOR(6 downto 0);
           an : out STD_LOGIC_VECTOR(7 downto 0);
           leds : out STD_LOGIC_VECTOR(15 downto 0);
           rgb_leds : out STD_LOGIC_VECTOR(5 downto 0)); 
end Controlador_Display;

architecture Behavioral of Controlador_Display is
    signal mux : integer range 0 to 7 := 0; 
    signal led_level : integer range 0 to 16 := 0;
    signal blink_state : std_logic := '0';
    
    signal an_s    : std_logic_vector(7 downto 0);
    signal seg_s   : std_logic_vector(6 downto 0);
    signal rgb_s   : std_logic_vector(5 downto 0);
    signal leds_s  : std_logic_vector(15 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if en_blink = '1' then blink_state <= not blink_state; end if;
            if en_disp = '1' then
                if mux = 7 then mux <= 0; else mux <= mux + 1; end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            -- LOGICA DE EMERGENCIA PRIORITARIA (PARPADEO TOTAL)
            if estado_vis = 6 then
                if blink_state = '1' then
                    an_s <= "00000000";  -- Todos los displays encendidos
                    seg_s <= "0000000"; -- Todos los segmentos encendidos (incluido el punto si fuera necesario)
                else
                    an_s <= "11111111";  -- Todos los displays apagados
                    seg_s <= "1111111"; -- Todos los segmentos apagados
                end if;
            else
                -- LOGICA NORMAL DE MULTIPLEXACIÓN
                case mux is
                    when 0 => an_s <= "11111110";
                        case piso is
                            when 0 => seg_s <= "1000000"; when 1 => seg_s <= "1111001"; 
                            when 2 => seg_s <= "0100100"; when others => seg_s <= "0110000";
                        end case;
                    when 1 => an_s <= "11111101"; seg_s <= "0001110"; -- F
                    when 2 => an_s <= "11111011"; seg_s <= "0111111"; -- -
                    when 3 => an_s <= "11110111"; 
                        case estado_vis is
                            when 0 => seg_s <= "0001100"; -- P
                            when 1 => seg_s <= "0010010"; -- S
                            when 2 => seg_s <= "0000011"; -- b
                            when 3 => seg_s <= "1000000"; -- O
                            when 4 => seg_s <= "1000110"; -- C
                            when 5 => seg_s <= "0000110"; -- E (EMERGENCIA FIJA)
                            when 7 => seg_s <= "1000111"; -- L
                            when others => seg_s <= "0001001"; -- H
                        end case;
                    when 4 => an_s <= "11101111";
                        case habitacion is
                            when 1 => seg_s <= "1111001"; when 2 => seg_s <= "0100100"; 
                            when 3 => seg_s <= "0110000"; when others => seg_s <= "0011001";
                        end case;
                    when 5 => an_s <= "11011111"; seg_s <= "1000000"; -- 0
                    when 6 => an_s <= "10111111"; seg_s <= "0111111"; -- -
                    when 7 => an_s <= "01111111"; seg_s <= "0001001"; -- H
                    when others => an_s <= "11111111"; seg_s <= "1111111";
                end case;
            end if;

            -- SEMÁFORO RGB
            case estado_vis is
                when 1 | 2 | 4 | 8 => rgb_s <= "100100"; -- ROJO
                when 5 | 6 => -- AZUL PARPADEANTE
                    if blink_state = '1' then rgb_s <= "001001"; else rgb_s <= "000000"; end if;
                when 7 => rgb_s <= "110110"; -- AMARILLO
                when others => rgb_s <= "010010"; -- VERDE
            end case;

            -- PUERTAS (LEDS)
            if en_anim = '1' then
                if puerta_abierta = '1' then
                    if led_level < 16 then led_level <= led_level + 1; end if;
                else
                    if led_level > 0 then led_level <= led_level - 1; end if;
                end if;
            end if;
            for i in 0 to 15 loop
                if i < led_level then leds_s(i) <= '1'; else leds_s(i) <= '0'; end if;
            end loop;
        end if;
    end process;

    an <= an_s;
    seg <= seg_s;
    rgb_leds <= rgb_s;
    leds <= leds_s;
end Behavioral;