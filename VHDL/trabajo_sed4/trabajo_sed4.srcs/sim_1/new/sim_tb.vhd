library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Simulador_Planta_TB is
-- Entidad vacía
end Simulador_Planta_TB;

architecture Behavioral of Simulador_Planta_TB is

    -- 1. Declaración del Componente
    component Simulador_Planta
        Port ( 
            clk         : in STD_LOGIC;
            reset       : in STD_LOGIC;
            en_1hz      : in STD_LOGIC;
            motor       : in STD_LOGIC_VECTOR(1 downto 0); 
            motor_hor   : in STD_LOGIC_VECTOR(1 downto 0); 
            piso_actual : out INTEGER range 0 to 3;
            hab_actual  : out INTEGER range 1 to 4
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb       : std_logic := '0';
    signal reset_tb     : std_logic := '0';
    signal en_1hz_tb    : std_logic := '0';
    signal motor_tb     : std_logic_vector(1 downto 0) := "00";
    signal motor_h_tb   : std_logic_vector(1 downto 0) := "00";

    -- Señales de Observación
    signal piso_act_tb  : integer range 0 to 3;
    signal hab_act_tb   : integer range 1 to 4;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: Simulador_Planta 
        port map (
            clk         => clk_tb,
            reset       => reset_tb,
            en_1hz      => en_1hz_tb,
            motor       => motor_tb,
            motor_hor   => motor_h_tb,
            piso_actual => piso_act_tb,
            hab_actual  => hab_act_tb
        );

    -- 4. Generación de Reloj (100 MHz)
    clk_process : process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- 5. Generación de pulsos en_1hz (Simulamos 1 pulso cada 100ns para rapidez)
    en_1hz_process : process
    begin
        en_1hz_tb <= '0';
        wait for 90 ns;
        en_1hz_tb <= '1';
        wait for 10 ns;
    end process;

    -- 6. Proceso de Estímulos
    stim_proc: process
    begin
        report "INICIO TEST SIMULADOR PLANTA";
        reset_tb <= '1';
        wait for 50 ns;
        reset_tb <= '0';
        wait for 50 ns;

        -- PRUEBA 1: Movimiento Vertical Ascendente (0 a 3)
        report "Prueba 1: Motor SUBIR (01)";
        motor_tb <= "01"; 
        wait for 400 ns; -- Esperamos 4 pulsos de en_1hz
        motor_tb <= "00";
        
        -- PRUEBA 2: Límite superior (Intentar subir más allá del piso 3)
        report "Prueba 2: Forzar subida en piso 3";
        motor_tb <= "01";
        wait for 200 ns;
        motor_tb <= "00";

        -- PRUEBA 3: Movimiento Horizontal (Hab 1 a 4)
        report "Prueba 3: Motor Horizontal DERECHA (01)";
        motor_h_tb <= "01";
        wait for 400 ns;
        motor_h_tb <= "00";

        -- PRUEBA 4: Movimiento Vertical Descendente (3 a 0)
        report "Prueba 4: Motor BAJAR (10)";
        motor_tb <= "10";
        wait for 400 ns;
        motor_tb <= "00";

        -- PRUEBA 5: Movimiento Horizontal Izquierda (4 a 1)
        report "Prueba 5: Motor Horizontal IZQUIERDA (10)";
        motor_h_tb <= "10";
        wait for 400 ns;
        motor_h_tb <= "00";

        report "FIN DE LA SIMULACION";
        wait;
    end process;

end Behavioral;