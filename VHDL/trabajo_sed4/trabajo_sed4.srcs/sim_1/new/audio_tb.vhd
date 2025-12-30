library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Controlador_Audio_TB is
-- Entidad vacía
end Controlador_Audio_TB;

architecture Behavioral of Controlador_Audio_TB is

    -- 1. Declaración del Componente
    component Controlador_Audio
        Port ( 
            clk             : in STD_LOGIC;
            enable_music    : in STD_LOGIC;
            enable_door     : in STD_LOGIC;
            enable_alarm    : in STD_LOGIC;
            enable_overload : in STD_LOGIC;
            audio_out       : out STD_LOGIC;
            audio_sd        : out STD_LOGIC
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb             : std_logic := '0';
    signal en_music_tb        : std_logic := '0';
    signal en_door_tb         : std_logic := '0';
    signal en_alarm_tb        : std_logic := '0';
    signal en_overload_tb     : std_logic := '0';

    -- Señales de Observación
    signal audio_out_tb       : std_logic;
    signal audio_sd_tb        : std_logic;

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: Controlador_Audio 
        port map (
            clk             => clk_tb,
            enable_music    => en_music_tb,
            enable_door     => en_door_tb,
            enable_alarm    => en_alarm_tb,
            enable_overload => en_overload_tb,
            audio_out       => audio_out_tb,
            audio_sd        => audio_sd_tb
        );

    -- 4. Generación de Reloj
    clk_process : process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de Estímulos
    stim_proc: process
    begin
        report "INICIO TEST CONTROLADOR DE AUDIO";
        wait for 100 ns;

        -- PRUEBA 1: Sonido de Puerta (Tono agudo fijo)
        report "Prueba 1: Habilitando Sonido de Puerta";
        en_door_tb <= '1';
        wait for 1 ms; -- Tiempo suficiente para ver varios ciclos de la onda cuadrada
        en_door_tb <= '0';
        wait for 100 ns;

        -- PRUEBA 2: Alarma de Emergencia (Tono intermitente)
        report "Prueba 2: Habilitando Alarma de Emergencia";
        en_alarm_tb <= '1';
        wait for 2 ms; 
        en_alarm_tb <= '0';
        wait for 100 ns;

        -- PRUEBA 3: Sobrecarga (Tono grave)
        report "Prueba 3: Habilitando Sonido de Sobrecarga (Grave)";
        en_overload_tb <= '1';
        wait for 1 ms;
        en_overload_tb <= '0';
        wait for 100 ns;

        -- PRUEBA 4: Música de ascensor (Melodía que cambia de tono)
        report "Prueba 4: Habilitando Música (Cambio de notas)";
        en_music_tb <= '1';
        -- Para ver el cambio de nota rápido en simulación, recuerda 
        -- reducir temporalmente 'tempo_cnt > 10000000' en el código original.
        wait for 5 ms;
        en_music_tb <= '0';

        report "FIN DE LA SIMULACION";
        wait;
    end process;

end Behavioral;