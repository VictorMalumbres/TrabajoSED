library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_Controlador is
    Port ( clk, reset : in STD_LOGIC;
           piso_actual : in INTEGER range 0 to 3;
           piso_llamada : in INTEGER range 0 to 3;
           hay_peticion : in STD_LOGIC;
           trigger_emergencia : in STD_LOGIC; 
           timer_done : in STD_LOGIC;
           
           motor : out STD_LOGIC_VECTOR(1 downto 0); 
           timer_start : out STD_LOGIC;
           timer_dur : out INTEGER;
           
           estado_vis : out INTEGER range 0 to 6; 
           puerta_abierta : out STD_LOGIC;
           
           -- Señales de Audio
           play_musica : out STD_LOGIC;
           play_puerta : out STD_LOGIC); 
end FSM_Controlador;

architecture Behavioral of FSM_Controlador is
    type estados_t is (IDLE_OPEN, CERRANDO, SUBIENDO, BAJANDO, LLEGADA, ABRIENDO, EMERG_WAIT, EMERG_BLINK);
    signal estado : estados_t := IDLE_OPEN;
    signal objetivo : integer range 0 to 3 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                estado <= IDLE_OPEN; objetivo <= 0; 
                motor <= "00"; timer_start <= '0';
            else
                timer_start <= '0'; 
                play_musica <= '0'; -- Por defecto apagado
                play_puerta <= '0'; -- Por defecto apagado
                
                if trigger_emergencia = '1' then
                    estado <= EMERG_WAIT;
                    motor <= "00"; 
                    timer_start <= '1'; timer_dur <= 2; 
                else
                    case estado is
                        when EMERG_WAIT =>
                            motor <= "00"; estado_vis <= 5; puerta_abierta <= '0';
                            if timer_done = '1' then
                                estado <= EMERG_BLINK;
                                timer_start <= '1'; timer_dur <= 3; 
                            end if;

                        when EMERG_BLINK =>
                            motor <= "00"; estado_vis <= 6; puerta_abierta <= '0';
                            if timer_done = '1' then
                                estado <= ABRIENDO; -- Salimos abriendo
                                timer_start <= '1'; timer_dur <= 2;
                            end if;

                        when IDLE_OPEN =>
                            motor <= "00"; estado_vis <= 3; puerta_abierta <= '1'; 
                            if hay_peticion = '1' then
                                if piso_llamada /= piso_actual then
                                    objetivo <= piso_llamada;
                                    estado <= CERRANDO;
                                    timer_start <= '1'; timer_dur <= 3; 
                                end if;
                            end if;

                        when CERRANDO =>
                            motor <= "00"; estado_vis <= 4; puerta_abierta <= '0'; 
                            if timer_done = '1' then
                                if objetivo > piso_actual then estado <= SUBIENDO;
                                elsif objetivo < piso_actual then estado <= BAJANDO;
                                else
                                    estado <= ABRIENDO;
                                    timer_start <= '1'; timer_dur <= 2;
                                end if;
                            end if;

                        when SUBIENDO =>
                            motor <= "01"; estado_vis <= 1; puerta_abierta <= '0';
                            play_musica <= '1'; -- ACTIVAR MUSICA
                            if piso_actual = objetivo then
                                motor <= "00";
                                estado <= LLEGADA; 
                                timer_start <= '1'; timer_dur <= 2; 
                            end if;

                        when BAJANDO =>
                            motor <= "10"; estado_vis <= 2; puerta_abierta <= '0';
                            play_musica <= '1'; -- ACTIVAR MUSICA
                            if piso_actual = objetivo then
                                motor <= "00";
                                estado <= LLEGADA; 
                                timer_start <= '1'; timer_dur <= 2; 
                            end if;
                            
                        when LLEGADA => 
                            motor <= "00"; estado_vis <= 0; puerta_abierta <= '0'; 
                            if timer_done = '1' then
                                estado <= ABRIENDO;
                                timer_start <= '1'; timer_dur <= 2; 
                            end if;

                        when ABRIENDO =>
                            motor <= "00"; estado_vis <= 3; puerta_abierta <= '1'; 
                            play_puerta <= '1'; -- SONIDO DING-DONG (2 seg)
                            if timer_done = '1' then
                                estado <= IDLE_OPEN;
                            end if;
                    end case;
                end if; 
            end if;
        end if;
    end process;
end Behavioral;

-- ==============================================================================
-- 7. CONTROLADOR DE VISUALIZACIÓN 
-- ==============================================================================
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
    process(clk)
    begin
        if rising_edge(clk) then
            if en_blink = '1' then blink_state <= not blink_state; end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if en_disp = '1' then
                if mux = 3 then mux <= 0; else mux <= mux + 1; end if;
                an <= "11111111"; 
                if estado_vis = 6 then -- Emergencia Blink
                    if blink_state = '1' then
                        an <= "00000000"; seg <= "0000000"; 
                    else an <= "11111111"; end if;
                else
                    case mux is
                        when 0 => -- Piso
                            an(0) <= '0';
                            case piso is
                                when 0 => seg <= "1000000"; when 1 => seg <= "1111001"; 
                                when 2 => seg <= "0100100"; when 3 => seg <= "0110000"; 
                                when others => seg <= "1111111";
                            end case;
                        when 1 => an(1) <= '0'; seg <= "0001110"; -- F
                        when 2 => an(2) <= '0'; seg <= "0111111"; -- -
                        when 3 => -- Estado
                            an(3) <= '0';
                            case estado_vis is
                                when 0 => seg <= "0001100"; -- P
                                when 1 => seg <= "0010010"; -- S
                                when 2 => seg <= "0000011"; -- b
                                when 3 => seg <= "1000000"; -- O
                                when 4 => seg <= "1000110"; -- C
                                when 5 => seg <= "0000110"; -- E
                                when others => seg <= "1111111";
                            end case;
                    end case;
                end if;
            end if;
            
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