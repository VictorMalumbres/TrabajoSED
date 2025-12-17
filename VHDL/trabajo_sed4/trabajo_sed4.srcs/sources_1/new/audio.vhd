library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controlador_Audio is
    Port ( clk : in STD_LOGIC;
           enable_music : in STD_LOGIC; -- '1' cuando el ascensor se mueve
           enable_door : in STD_LOGIC;  -- '1' cuando la puerta se abre
           audio_out : out STD_LOGIC;   -- Salida PWM (AUD_PWM)
           audio_sd : out STD_LOGIC);   -- Enable Amplificador (AUD_SD)
end Controlador_Audio;

architecture Behavioral of Controlador_Audio is
    -- Frecuencias de notas musicales (Periodo = 100MHz / Frecuencia)
    constant DO_NOTE : integer := 191113; -- ~523 Hz
    constant MI_NOTE : integer := 151686; -- ~659 Hz
    constant SOL_NOTE : integer := 127553; -- ~783 Hz
    constant DO_HIGH : integer := 95556;  -- ~1046 Hz
    
    signal counter_freq : integer := 0;
    signal current_period : integer := 0;
    signal audio_toggle : std_logic := '0';
    
    -- Secuenciador de melodía
    signal tempo_cnt : integer := 0; -- Para cambiar de nota
    signal note_index : integer range 0 to 7 := 0;
    
begin
    audio_sd <= '1'; -- Encender siempre el amplificador
    
    process(clk)
    begin
        if rising_edge(clk) then
            -- 1. Secuenciador (Elige la nota)
            tempo_cnt <= tempo_cnt + 1;
            
            if enable_door = '1' then
                -- Sonido Puerta: "Ding-Dong" (Alto -> Bajo)
                -- Cambia de nota cada 0.25 segundos (25M ciclos)
                if tempo_cnt < 25000000 then
                    current_period <= DO_HIGH; -- Ding
                elsif tempo_cnt < 50000000 then
                    current_period <= SOL_NOTE; -- Dong
                else
                    current_period <= 0; -- Silencio
                end if;
                
            elsif enable_music = '1' then
                -- Musica Ascensor: Arpegio continuo
                -- Cambia nota cada 0.15 segundos
                if tempo_cnt > 15000000 then
                    tempo_cnt <= 0;
                    if note_index = 3 then note_index <= 0; else note_index <= note_index + 1; end if;
                end if;
                
                case note_index is
                    when 0 => current_period <= DO_NOTE;
                    when 1 => current_period <= MI_NOTE;
                    when 2 => current_period <= SOL_NOTE;
                    when 3 => current_period <= MI_NOTE;
                    when others => current_period <= 0;
                end case;
                
            else
                -- Silencio total
                current_period <= 0;
                tempo_cnt <= 0;
                note_index <= 0;
            end if;
            
            -- 2. Generador de Tono (PWM 50%)
            if current_period > 0 then
                counter_freq <= counter_freq + 1;
                if counter_freq >= current_period then
                    counter_freq <= 0;
                    audio_toggle <= not audio_toggle;
                end if;
                audio_out <= audio_toggle;
            else
                audio_out <= '0';
                counter_freq <= 0;
            end if;
            
        end if;
    end process;
end Behavioral;