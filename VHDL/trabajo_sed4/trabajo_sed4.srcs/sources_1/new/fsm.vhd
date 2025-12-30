library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_Controlador is
    Port ( clk, reset : in STD_LOGIC;
           piso_actual, piso_llamada : in INTEGER range 0 to 3;
           hay_peticion, trigger_hab : in STD_LOGIC;
           habitacion_in, hab_actual : in INTEGER range 1 to 4;
           sw_sobrecarga, trigger_emergencia, timer_done : in STD_LOGIC;
           motor, motor_hor : out STD_LOGIC_VECTOR(1 downto 0);
           timer_start : out STD_LOGIC;
           timer_dur : out INTEGER;
           estado_vis : out INTEGER range 0 to 8; 
           puerta_abierta : out STD_LOGIC;
           play_musica, play_puerta, play_alarma, play_error : out STD_LOGIC); 
end FSM_Controlador;

architecture Behavioral of FSM_Controlador is
    type estados_t is (IDLE_OPEN, CERRANDO, SUBIENDO, BAJANDO, MOVIENDO_HOR, LLEGADA, ABRIENDO, EMERG_WAIT, EMERG_BLINK, SOBRECARGA);
    signal estado : estados_t := IDLE_OPEN;
    signal obj_p : integer range 0 to 3 := 0;
    signal obj_h : integer range 1 to 4 := 1;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then estado <= IDLE_OPEN; 
            else
                timer_start <= '0'; play_musica <= '0'; play_puerta <= '0'; play_alarma <= '0'; play_error <= '0';
                motor <= "00"; motor_hor <= "00"; timer_dur <= 2;
                
                if trigger_emergencia = '1' then 
                    estado <= EMERG_WAIT; 
                    timer_start <= '1'; 
                    timer_dur <= 1; -- 1 Segundo mostrando la 'E'
                else
                    case estado is
                        when IDLE_OPEN =>
                            estado_vis <= 3; puerta_abierta <= '1'; 
                            if sw_sobrecarga = '1' then estado <= SOBRECARGA;
                            elsif hay_peticion = '1' and piso_llamada /= piso_actual then
                                obj_p <= piso_llamada; estado <= CERRANDO; timer_start <= '1';
                            elsif trigger_hab = '1' and habitacion_in /= hab_actual then
                                obj_h <= habitacion_in; estado <= CERRANDO; timer_start <= '1';
                            end if;
                        when SOBRECARGA =>
                            estado_vis <= 7; puerta_abierta <= '1'; play_error <= '1';
                            if sw_sobrecarga = '0' then estado <= IDLE_OPEN; end if;
                        when CERRANDO =>
                            estado_vis <= 4; puerta_abierta <= '0';
                            if sw_sobrecarga = '1' then estado <= SOBRECARGA;
                            elsif timer_done = '1' then
                                if piso_actual /= obj_p then
                                    if obj_p > piso_actual then estado <= SUBIENDO; else estado <= BAJANDO; end if;
                                elsif hab_actual /= obj_h then estado <= MOVIENDO_HOR;
                                else estado <= ABRIENDO; timer_start <= '1'; end if;
                            end if;
                        when SUBIENDO =>
                            motor <= "01"; estado_vis <= 1; play_musica <= '1';
                            if piso_actual = obj_p then estado <= LLEGADA; timer_start <= '1'; end if;
                        when BAJANDO =>
                            motor <= "10"; estado_vis <= 2; play_musica <= '1';
                            if piso_actual = obj_p then estado <= LLEGADA; timer_start <= '1'; end if;
                        when MOVIENDO_HOR =>
                            estado_vis <= 8; play_musica <= '1';
                            if obj_h > hab_actual then motor_hor <= "01"; else motor_hor <= "10"; end if;
                            if hab_actual = obj_h then estado <= LLEGADA; timer_start <= '1'; end if;
                        when LLEGADA => 
                            estado_vis <= 0; if timer_done = '1' then estado <= ABRIENDO; timer_start <= '1'; end if;
                        when ABRIENDO =>
                            estado_vis <= 3; puerta_abierta <= '1'; play_puerta <= '1';
                            if timer_done = '1' then estado <= IDLE_OPEN; end if;
                        when EMERG_WAIT =>
                            estado_vis <= 5; -- Mostrar E
                            if timer_done = '1' then 
                                estado <= EMERG_BLINK; 
                                timer_start <= '1'; 
                                timer_dur <= 2; -- 2 Segundos parpadeando
                            end if;
                        when EMERG_BLINK =>
                            estado_vis <= 6; -- Estado de parpadeo total
                            play_alarma <= '1'; 
                            if timer_done = '1' then estado <= ABRIENDO; timer_start <= '1'; end if;
                    end case;
                end if;
            end if;
        end if;
    end process;
end Behavioral;