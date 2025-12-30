library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Divisor_Frecuencia_TB is
-- Entidad de prueba vacía
end Divisor_Frecuencia_TB;

architecture Behavioral of Divisor_Frecuencia_TB is

    -- 1. Declaración del componente
    component Divisor_Frecuencia
        Port ( 
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            en_1hz   : out STD_LOGIC;
            en_disp  : out STD_LOGIC;
            en_blink : out STD_LOGIC;
            en_anim  : out STD_LOGIC
        );
    end component;

    -- 2. Señales internas
    signal clk_tb      : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal en_1hz_tb   : std_logic;
    signal en_disp_tb  : std_logic;
    signal en_blink_tb : std_logic;
    signal en_anim_tb  : std_logic;

    -- Reloj de 100MHz (10ns de periodo)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la unidad bajo prueba (UUT)
    uut: Divisor_Frecuencia 
        port map (
            clk      => clk_tb,
            reset    => reset_tb,
            en_1hz   => en_1hz_tb,
            en_disp  => en_disp_tb,
            en_blink => en_blink_tb,
            en_anim  => en_anim_tb
        );

    -- 4. Proceso de generación del reloj
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de estímulos
    stim_proc: process
    begin
        -- Inicialización con Reset
        reset_tb <= '1';
        wait for 50 ns;
        reset_tb <= '0';
        
        -- Nota: Para ver algo en la simulación sin cambiar el código original,
        -- tendrías que correr la simulación por milisegundos.
        -- Para pruebas rápidas, reduce los valores de los contadores en la entidad.
        
        report "Simulación en marcha... esperando ticks.";
        
        -- Dejamos correr la simulación
        -- Si has reducido los contadores a valores pequeños (ej. 10, 20, 50, 100)
        -- en 2000 ns verás muchos pulsos.
        wait for 2000 ns; 

        report "Simulación finalizada.";
        wait;
    end process;

end Behavioral;