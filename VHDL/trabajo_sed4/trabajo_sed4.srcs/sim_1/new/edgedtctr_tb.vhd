library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Detector_Entradas_TB is
-- Entidad de prueba vacía
end Detector_Entradas_TB;

architecture Behavioral of Detector_Entradas_TB is

    -- 1. Declaración del Componente
    component Detector_Entradas
        Port ( 
            clk                  : in STD_LOGIC;
            sw_reset             : in STD_LOGIC;
            switches_pisos       : in STD_LOGIC_VECTOR(3 downto 0);
            switches_hab         : in STD_LOGIC_VECTOR(3 downto 0);
            botones              : in STD_LOGIC_VECTOR(3 downto 0);
            piso_llamada         : out INTEGER range 0 to 3;
            habitacion_detectada : out INTEGER range 0 to 4;
            nueva_peticion       : out STD_LOGIC;
            trigger_hab          : out STD_LOGIC;
            trigger_emergencia   : out STD_LOGIC
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb        : std_logic := '0';
    signal sw_reset_tb   : std_logic := '0';
    signal sw_pisos_tb   : std_logic_vector(3 downto 0) := (others => '0');
    signal sw_hab_tb     : std_logic_vector(3 downto 0) := (others => '0');
    signal botones_tb    : std_logic_vector(3 downto 0) := (others => '0');

    -- Señales de Observación
    signal piso_ll_tb    : integer range 0 to 3;
    signal hab_det_tb    : integer range 0 to 4;
    signal n_peticion_tb : std_logic;
    signal t_hab_tb      : std_logic;
    signal t_emerg_tb    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: Detector_Entradas 
        port map (
            clk                  => clk_tb,
            sw_reset             => sw_reset_tb,
            switches_pisos       => sw_pisos_tb,
            switches_hab         => sw_hab_tb,
            botones              => botones_tb,
            piso_llamada         => piso_ll_tb,
            habitacion_detectada => hab_det_tb,
            nueva_peticion       => n_peticion_tb,
            trigger_hab          => t_hab_tb,
            trigger_emergencia   => t_emerg_tb
        );

    -- 4. Generación de Reloj
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de Estímulos
    stim_proc: process
    begin
        report "INICIO TESTBENCH DETECTOR DE ENTRADAS";
        wait for 40 ns;

        -- PRUEBA 1: Detectar pulsación de botón (Piso 1)
        report "Prueba 1: Pulsando botón U (Piso 1)";
        botones_tb(1) <= '1'; -- Simulamos que el usuario pulsa
        wait for 50 ns;       -- Mantenemos pulsado varios ciclos
        botones_tb(1) <= '0'; -- Soltamos
        -- Deberías ver n_peticion_tb a '1' solo 1 ciclo y piso_ll_tb = 1
        wait for 50 ns;

        -- PRUEBA 2: Detectar cambio en Switch de Habitación (Hab 4)
        report "Prueba 2: Activando SW de Habitación 4";
        sw_hab_tb(3) <= '1'; 
        wait for 50 ns;
        -- Deberías ver t_hab_tb a '1' solo 1 ciclo y hab_det_tb = 4
        wait for 50 ns;

        -- PRUEBA 3: Detector de Emergencia (Cambio en SW15)
        report "Prueba 3: Activando Emergencia (Toggle SW15)";
        sw_reset_tb <= '1';
        wait for 50 ns;
        -- Deberías ver t_emerg_tb a '1' solo 1 ciclo
        wait for 50 ns;

        -- PRUEBA 4: Prioridad (Pulsar dos botones a la vez)
        report "Prueba 4: Pulsando Piso 3 y Piso 0 a la vez";
        botones_tb(3) <= '1';
        botones_tb(0) <= '1';
        wait for 50 ns;
        botones_tb <= (others => '0');

        wait for 100 ns;
        report "FIN DE LA SIMULACION";
        wait;
    end process;

end Behavioral;