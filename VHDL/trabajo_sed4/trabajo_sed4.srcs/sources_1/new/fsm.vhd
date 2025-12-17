library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_Controlador is
    Port ( clk, reset : in STD_LOGIC;
           piso_actual : in INTEGER range 0 to 3;
           piso_llamada : in INTEGER range 0 to 3;
           hay_peticion : in STD_LOGIC;
           timer_done : in STD_LOGIC;
           
           motor : out STD_LOGIC_VECTOR(1 downto 0); 
           timer_start : out STD_LOGIC;
           timer_dur : out INTEGER;
           
           -- 0:P, 1:S, 2:b, 3:O, 4:C
           estado_vis : out INTEGER range 0 to 4; 
           puerta_abierta : out STD_LOGIC); 
end FSM_Controlador;

architecture Behavioral of FSM_Controlador is
    -- Añadido estado LLEGADA
    type estados_t is (IDLE_OPEN, CERRANDO, SUBIENDO, BAJANDO, LLEGADA, ABRIENDO);
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
                
                case estado is
                    -- ESTADO REPOSO: PUERTA ABIERTA, MUESTRA 'O' (Open)
                    when IDLE_OPEN =>
                        motor <= "00";
                        estado_vis <= 3; -- Muestra 'O'
                        puerta_abierta <= '1'; 
                        
                        if hay_peticion = '1' then
                            if piso_llamada /= piso_actual then
                                objetivo <= piso_llamada;
                                estado <= CERRANDO;
                                timer_start <= '1'; timer_dur <= 3; -- 3 seg cerrando
                            end if;
                        end if;

                    when CERRANDO =>
                        motor <= "00";
                        estado_vis <= 4; -- Muestra 'C'
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
                        estado_vis <= 1; -- Muestra 'S'
                        puerta_abierta <= '0';
                        if piso_actual = objetivo then
                            -- AL LLEGAR, PARAMOS Y VAMOS A LLEGADA ('P')
                            motor <= "00";
                            estado <= LLEGADA;
                            timer_start <= '1'; timer_dur <= 2; -- Esperar 2 seg en 'P'
                        end if;

                    when BAJANDO =>
                        motor <= "10";
                        estado_vis <= 2; -- Muestra 'b'
                        puerta_abierta <= '0';
                        if piso_actual = objetivo then
                            motor <= "00";
                            estado <= LLEGADA;
                            timer_start <= '1'; timer_dur <= 2; -- Esperar 2 seg en 'P'
                        end if;
                        
                    -- NUEVO ESTADO INTERMEDIO: P (Parado) antes de abrir
                    when LLEGADA =>
                        motor <= "00";
                        estado_vis <= 0; -- Muestra 'P'
                        puerta_abierta <= '0'; -- Puerta aun cerrada
                        
                        if timer_done = '1' then
                            estado <= ABRIENDO;
                            timer_start <= '1'; timer_dur <= 2; -- Ahora abrimos 'O'
                        end if;

                    when ABRIENDO =>
                        motor <= "00";
                        estado_vis <= 3; -- Muestra 'O'
                        puerta_abierta <= '1'; 
                        
                        if timer_done = '1' then
                            estado <= IDLE_OPEN;
                        end if;

                end case;
            end if;
        end if;
    end process;
end Behavioral;