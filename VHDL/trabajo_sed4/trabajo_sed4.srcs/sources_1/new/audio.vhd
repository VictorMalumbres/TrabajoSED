library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Controlador_Audio is
    Port ( clk : in STD_LOGIC;
           enable_music, enable_door, enable_alarm, enable_overload : in STD_LOGIC;
           audio_out, audio_sd : out STD_LOGIC);   
end Controlador_Audio;

architecture Behavioral of Controlador_Audio is
    signal counter_freq, current_period, tempo_cnt : integer := 0;
    signal audio_toggle : std_logic := '0';
    signal note_index : integer range 0 to 3 := 0;
begin
    audio_sd <= '1'; 
    process(clk)
    begin
        if rising_edge(clk) then
            tempo_cnt <= tempo_cnt + 1;
            if enable_alarm = '1' then
                if tempo_cnt < 25000000 then current_period <= 250000;
                elsif tempo_cnt < 50000000 then current_period <= 0;
                else tempo_cnt <= 0; end if;
            elsif enable_overload = '1' then
                if tempo_cnt < 15000000 then current_period <= 450000; -- Tono grave
                elsif tempo_cnt < 30000000 then current_period <= 0;
                else tempo_cnt <= 0; end if;
            elsif enable_door = '1' then
                if tempo_cnt < 25000000 then current_period <= 95556; else current_period <= 127553; end if;
            elsif enable_music = '1' then
                if tempo_cnt > 10000000 then 
                    tempo_cnt <= 0; if note_index = 3 then note_index <= 0; else note_index <= note_index + 1; end if;
                end if;
                case note_index is
                    when 0 => current_period <= 191113; when 1 => current_period <= 151686;
                    when 2 => current_period <= 127553; when others => current_period <= 151686;
                end case;
            else current_period <= 0; tempo_cnt <= 0; end if;
            
            if current_period > 0 then
                counter_freq <= counter_freq + 1;
                if counter_freq >= current_period then counter_freq <= 0; audio_toggle <= not audio_toggle; end if;
                audio_out <= audio_toggle;
            else audio_out <= '0'; counter_freq <= 0; end if;
        end if;
    end process;
end Behavioral;