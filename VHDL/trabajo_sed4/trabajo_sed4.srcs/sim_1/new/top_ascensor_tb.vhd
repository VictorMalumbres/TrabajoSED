library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_ASCENSOR_TB is
-- Entidad vacía para Testbench
end TOP_ASCENSOR_TB;

architecture Behavioral of TOP_ASCENSOR_TB is

    -- 1. Declaración del Componente
    component TOP_ASCENSOR
        Port ( 
            CLK100MHZ : in STD_LOGIC;
            CPU_RESETN : in STD_LOGIC;
            SW : in STD_LOGIC_VECTOR(15 downto 0); 
            BTNC, BTNU, BTND, BTNL : in STD_LOGIC;   
            LED : out STD_LOGIC_VECTOR(15 downto 0); 
            SEG : out STD_LOGIC_VECTOR(6 downto 0);  
            AN  : out STD_LOGIC_VECTOR(7 downto 0);
            AUD_PWM, AUD_SD : out STD_LOGIC;
            LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B : out STD_LOGIC
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb       : std_logic := '0';
    signal rst_n_tb     : std_logic := '0';
    signal sw_tb        : std_logic_vector(15 downto 0) := (others => '0');
    signal btnc_tb      : std_logic := '0'; -- Piso 0
    signal btnu_tb      : std_logic := '0'; -- Piso 1
    signal btnd_tb      : std_logic := '0'; -- Piso 2
    signal btnl_tb      : std_logic := '0'; -- Piso 3
    
    -- Señales de Observación
    signal led_tb       : std_logic_vector(15 downto 0);
    signal seg_tb       : std_logic_vector(6 downto 0);
    signal an_tb        : std_logic_vector(7 downto 0);
    signal aud_pwm_tb   : std_logic;
    signal aud_sd_tb    : std_logic;
    signal led16_r_tb, led16_g_tb, led16_b_tb : std_logic;
    signal led17_r_tb, led17_g_tb, led17_b_tb : std_logic;

    -- Configuración de Reloj (100MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: TOP_ASCENSOR 
        Port Map (
            CLK100MHZ => clk_tb,
            CPU_RESETN => rst_n_tb,
            SW => sw_tb,
            BTNC => btnc_tb,
            BTNU => btnu_tb,
            BTND => btnd_tb,
            BTNL => btnl_tb,
            LED => led_tb,
            SEG => seg_tb,
            AN => an_tb,
            AUD_PWM => aud_pwm_tb,
            AUD_SD => aud_sd_tb,
            LED16_R => led16_r_tb, LED16_G => led16_g_tb, LED16_B => led16_b_tb,
            LED17_R => led17_r_tb, LED17_G => led17_g_tb, LED17_B => led17_b_tb
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
        -- Inicialización
        report "--- INICIANDO SIMULACION DEL ASCENSOR 2025 ---";
        rst_n_tb <= '0';
        sw_tb <= (others => '0');
        wait for 100 ns;
        rst_n_tb <= '1';
        wait for 100 ns;

        -- PRUEBA 1: Movimiento Vertical al Piso 2
        report "Prueba 1: Pulsando BTND (Piso 2)";
        btnd_tb <= '1';
        wait for 200 ns;
        btnd_tb <= '0';
        -- Esperar a que la FSM pase por CERRANDO -> SUBIENDO -> LLEGADA -> ABRIENDO
        -- NOTA: En simulación, ajusta los contadores del Divisor para que esto no tarde ms.
        wait for 2 us; 

        -- PRUEBA 2: Movimiento Horizontal a Habitación 3 (SW 8-5)
        report "Prueba 2: Seleccionando Habitación 3 (SW7=1)";
        sw_tb(7) <= '1'; -- Activamos el bit correspondiente a Hab 3 (SW 8,7,6,5)
        wait for 200 ns;
        sw_tb(7) <= '0';
        wait for 2 us;

        -- PRUEBA 3: Simulación de Sobrecarga (SW4)
        report "Prueba 3: Activando Sobrecarga (SW4)";
        sw_tb(4) <= '1';
        wait for 1 us;
        -- Aquí el RGB debería ser Amarillo y el Display mostrar 'L'
        sw_tb(4) <= '0';
        report "Sobrecarga desactivada.";
        wait for 500 ns;

        -- PRUEBA 4: Emergencia Crítica (SW15)
        report "Prueba 4: EMERGENCIA ACTIVADA (SW15)";
        sw_tb(15) <= '1';
        wait for 500 ns;
        -- Debería entrar en EMERG_WAIT y luego parpadeo total
        wait for 2 us;
        sw_tb(15) <= '0';
        report "Emergencia desactivada.";

        wait for 5 us;
        report "--- SIMULACION FINALIZADA CON EXITO ---";
        wait;
    end process;

end Behavioral;