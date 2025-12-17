library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_Controlador is
    Port ( clk, reset : in STD_LOGIC;
           piso_actual : in INTEGER range 0 to 3;
           piso_llamada : in INTEGER range 0 to 3;
           hay_peticion : in STD_LOGIC;
           trigger_emergencia : in STD_LOGIC; -- Nueva entrada
           timer_done : in STD_LOGIC;
           
           motor : out STD_LOGIC_VECTOR(1 downto 0); 
           timer_start : out STD_LOGIC;
           timer_dur : out INTEGER;
           
           -- 0:P, 1:S, 2:b, 3:O, 4:C, 5:E, 6:BLINK
           estado_vis : out INTEGER range 0 to 6; 
           puerta_abierta : out STD_LOGIC); 
end FSM_Controlador;

architecture Behavioral of FSM_Controlador is
    -- Nuevos estados EMERG_WAIT y EMERG_BLINK
    type estados_t is (IDLE_OPEN, CERRANDO, SUBIENDO, BAJANDO, LLEGADA, ABRIENDO, EMERG_WAIT, EMERG_BLINK);
    signal estado : estados_t := IDLE_OPEN;
    signal objetivo : integer range 0 to 3 := 0;
    
    -- Señal auxiliar para no perder el objetivo tras emergencia (opcional, en este caso volvemos a idle)
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                estado <= IDLE_OPEN; objetivo <= 0; 
                motor <= "00"; timer_start <= '0';
            else
                timer_start <= '0'; 
                
                -- ============================================================
                -- PRIORIDAD ABSOLUTA: INTERRUPCIÓN DE EMERGENCIA (SW15)
                -- ============================================================
                if trigger_emergencia = '1' then
                    estado <= EMERG_WAIT;
                    motor <= "00"; -- Parada inmediata
                    timer_start <= '1'; timer_dur <= 2; -- 2 segundos mostrando E
                else
                    
                    -- MAQUINA DE ESTADOS NORMAL
                    case estado is
                        
                        -- ESTADO EMERGENCIA 1: MOSTRAR 'E' (2 seg)
                        when EMERG_WAIT =>
                            motor <= "00";
                            estado_vis <= 5; -- Codigo 'E'
                            puerta_abierta <= '0'; -- Asumimos cerrada o bloqueada
                            
                            if timer_done = '1' then
                                estado <= EMERG_BLINK;
                                timer_start <= '1'; timer_dur <= 3; -- 3 seg parpadeando
                            end if;

                        -- ESTADO EMERGENCIA 2: PARPADEO TOTAL (3 seg)
                        when EMERG_BLINK =>
                            motor <= "00";
                            estado_vis <= 6; -- Codigo BLINK
                            puerta_abierta <= '0';
                            
                            if timer_done = '1' then
                                -- FIN EMERGENCIA: Volver a normalidad (Puerta Abierta)
                                estado <= ABRIENDO; -- Pasamos por abriendo para encender LEDs
                                timer_start <= '1'; timer_dur <= 2;
                            end if;

                        -- ========================================================
                        -- ESTADOS NORMALES
                        -- ========================================================
                        
                        when IDLE_OPEN =>
                            motor <= "00";
                            estado_vis <= 3; -- 'O'
                            puerta_abierta <= '1'; 
                            
                            if hay_peticion = '1' then
                                if piso_llamada /= piso_actual then
                                    objetivo <= piso_llamada;
                                    estado <= CERRANDO;
                                    timer_start <= '1'; timer_dur <= 3; 
                                end if;
                            end if;

                        when CERRANDO =>
                            motor <= "00";
                            estado_vis <= 4; -- 'C'
                            puerta_abierta <= '0'; 
                            
                            if timer_done = '1' then
                                if objetivo > piso_actual then estado <= SUBIENDO;
                                elsif objetivo < piso_actual then estado <= BAJANDO;
                                else
                                    estado <= ABRIENDO;
                                    timer_start <= '1'; timer_dur <= 2;
                                end if;
                            end if;

                        when SUBIENDO =>
                            motor <= "01";
                            estado_vis <= 1; -- 'S'
                            puerta_abierta <= '0';
                            if piso_actual = objetivo then
                                motor <= "00";
                                estado <= LLEGADA; -- Vamos a P
                                timer_start <= '1'; timer_dur <= 2; 
                            end if;

                        when BAJANDO =>
                            motor <= "10";
                            estado_vis <= 2; -- 'b'
                            puerta_abierta <= '0';
                            if piso_actual = objetivo then
                                motor <= "00";
                                estado <= LLEGADA; -- Vamos a P
                                timer_start <= '1'; timer_dur <= 2; 
                            end if;
                            
                        when LLEGADA => -- Estado intermedio 'P' con puerta cerrada
                            motor <= "00";
                            estado_vis <= 0; -- 'P'
                            puerta_abierta <= '0'; 
                            
                            if timer_done = '1' then
                                estado <= ABRIENDO;
                                timer_start <= '1'; timer_dur <= 2;
                            end if;

                        when ABRIENDO =>
                            motor <= "00";
                            estado_vis <= 3; -- 'O'
                            puerta_abierta <= '1'; 
                            
                            if timer_done = '1' then
                                estado <= IDLE_OPEN;
                            end if;

                    end case;
                end if; -- Fin else emergencia
            end if;
        end if;
    end process;
end Behavioral;