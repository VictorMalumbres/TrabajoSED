library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controlador_Display_TB is
-- Entidad vacía
end Controlador_Display_TB;

architecture Behavioral of Controlador_Display_TB is

    -- 1. Declaración del Componente
    component Controlador_Display
        Port ( 
            clk, en_disp, en_blink, en_anim : in STD_LOGIC;
            piso           : in INTEGER range 0 to 3;
            habitacion     : in INTEGER range 1 to 4; 
            estado_vis     : in INTEGER range 0 to 8;
            puerta_abierta : in STD_LOGIC;
            seg            : out STD_LOGIC_VECTOR(6 downto 0);
            an             : out STD_LOGIC_VECTOR(7 downto 0);
            leds           : out STD_LOGIC_VECTOR(15 downto 0);
            rgb_leds       : out STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb        : std_logic := '0';
    signal en_disp_tb    : std_logic := '0';
    signal en_blink_tb   : std_logic := '0';
    signal en_anim_tb    : std_logic := '0';
    signal piso_tb       : integer range 0 to 3 := 0;
    signal hab_tb        : integer range 1 to 4 := 1;
    signal st_vis_tb     : integer range 0 to 8 := 3; -- Empezamos en IDLE (3)
    signal puerta_tb     : std_logic := '1';

    -- Señales de Observación
    signal seg_tb        : std_logic_vector(6 downto 0);
    signal an_tb         : std_logic_vector(7 downto 0);
    signal leds_tb       : std_logic_vector(15 downto 0);
    signal rgb_tb        : std_logic_vector(5 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: Controlador_Display 
        port map (
            clk => clk_tb, en_disp => en_disp_tb, en_blink => en_blink_tb, en_anim => en_anim_tb,
            piso => piso_tb, habitacion => hab_tb, estado_vis => st_vis_tb,
            puerta_abierta => puerta_tb, seg => seg_tb, an => an_tb,
            leds => leds_tb, rgb_leds => rgb_tb
        );

    -- 4. Generación de Reloj y Ticks rápidos para simulación
    clk_process : process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Ticks de simulación (mucho más rápidos que en la realidad)
    ticks: process
    begin
        en_disp_tb <= '1'; en_blink_tb <= '1'; en_anim_tb <= '1';
        wait for CLK_PERIOD;
        en_disp_tb <= '0'; en_blink_tb <= '0'; en_anim_tb <= '0';
        wait for CLK_PERIOD * 4; -- Cada 5 ciclos hay un tick
    end process;

    -- 5. Proceso de Estímulos
    stim_proc: process
    begin
        report "INICIO TEST CONTROLADOR DISPLAY";
        
        -- PRUEBA 1: Estado Reposo (Piso 0, Hab 1, Puerta Abierta)
        -- Debe mostrar: H-01 y O-F0. RGB: Verde
        piso_tb <= 0; hab_tb <= 1; st_vis_tb <= 3; puerta_tb <= '1';
        wait for 500 ns; -- Tiempo para ver varios ciclos de multiplexación

        -- PRUEBA 2: Movimiento (Piso 2, Hab 1, Subiendo, Puerta Cerrada)
        -- Debe mostrar: H-01 y S-F2. RGB: Rojo
        report "Prueba 2: Subiendo al Piso 2";
        piso_tb <= 2; st_vis_tb <= 1; puerta_tb <= '0';
        wait for 500 ns;

        -- PRUEBA 3: Sobrecarga (Switch 4 activo)
        -- Debe mostrar: L (Load). RGB: Amarillo
        report "Prueba 3: Sobrecarga";
        st_vis_tb <= 7; puerta_tb <= '1';
        wait for 500 ns;

        -- PRUEBA 4: Emergencia Parpadeante (Estado 6)
        -- Debe parpadear TODO el display (encendido total / apagado total)
        report "Prueba 4: Emergencia Crítica (Parpadeo)";
        st_vis_tb <= 6;
        wait for 1 us;

        report "FIN DE LA SIMULACION";
        wait;
    end process;

end Behavioral;