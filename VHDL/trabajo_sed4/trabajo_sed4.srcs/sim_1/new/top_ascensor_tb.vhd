library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_ASCENSOR_TB is
-- La entidad del testbench está vacía
end TOP_ASCENSOR_TB;

architecture Behavioral of TOP_ASCENSOR_TB is

    -- 1. Declaración del Componente (Debe coincidir con tu TOP V3)
    component TOP_ASCENSOR
    Port ( CLK100MHZ : in STD_LOGIC;
           CPU_RESETN : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR(15 downto 0); -- Ahora es de 16 bits
           BTNC, BTNU, BTND, BTNL : in STD_LOGIC;
           LED : out STD_LOGIC_VECTOR(15 downto 0);
           SEG : out STD_LOGIC_VECTOR(6 downto 0);
           AN  : out STD_LOGIC_VECTOR(7 downto 0)
           );
    end component;

    -- 2. Señales para conectar
    signal CLK100MHZ : std_logic := '0';
    signal CPU_RESETN : std_logic := '0';
    signal SW : std_logic_vector(15 downto 0) := (others => '0');
    signal BTNC, BTNU, BTND, BTNL : std_logic := '0';
    
    -- Salidas para observar
    signal LED : std_logic_vector(15 downto 0);
    signal SEG : std_logic_vector(6 downto 0);
    signal AN  : std_logic_vector(7 downto 0);

    -- Periodo de reloj
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la Unidad Bajo Prueba (UUT)
    uut: TOP_ASCENSOR Port Map (
          CLK100MHZ => CLK100MHZ,
          CPU_RESETN => CPU_RESETN,
          SW => SW,
          BTNC => BTNC,
          BTNU => BTNU,
          BTND => BTND,
          BTNL => BTNL,
          LED => LED,
          SEG => SEG,
          AN => AN
        );

    -- 4. Proceso de Reloj
    clk_process :process
    begin
        CLK100MHZ <= '0';
        wait for CLK_PERIOD/2;
        CLK100MHZ <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de Estímulos (Pruebas)
    stim_proc: process
    begin		
        -- ============================================================
        -- IMPORTANTE: Para que esta simulación funcione rápido, 
        -- debes haber reducido las constantes en 'Divisor_Frecuencia'.
        -- (ej. c_1hz contar hasta 10 en lugar de 100000000)
        -- ============================================================

        report "INICIO DE SIMULACION";
        
        -- Reset del sistema
        CPU_RESETN <= '0'; -- Reset activo
        wait for 100 ns;	
        CPU_RESETN <= '1'; -- Soltamos reset
        wait for 100 ns;

        -- Estado inicial: Piso 0, Puerta Abierta

        -- ------------------------------------------------------------
        -- PRUEBA 1: MOVIMIENTO NORMAL AL PISO 2
        -- ------------------------------------------------------------
        report "PRUEBA 1: Llamada Normal al Piso 2";
        BTND <= '1';      -- Pulsamos BTN Piso 2
        wait for 200 ns;
        BTND <= '0';      -- Soltamos
        
        -- Esperamos secuencia: Cerrar(3s) -> Subir(4s) -> Llegada(2s) -> Abrir(2s)
        -- Tiempo total simulado estimado: ~1200 ticks de reloj lento
        wait for 6000 ns; 

        -- ------------------------------------------------------------
        -- PRUEBA 2: EMERGENCIA DESDE REPOSO (IDLE)
        -- ------------------------------------------------------------
        report "PRUEBA 2: Activar Emergencia (SW15) en Reposo";
        
        SW(15) <= '1'; -- Activamos Switch de Emergencia
        
        -- El sistema debe pasar a EMERG_WAIT ('E') por 2s
        -- Luego a EMERG_BLINK (Parpadeo) por 3s
        -- Luego volver a ABRIENDO -> IDLE
        wait for 6000 ns; 

        -- ------------------------------------------------------------
        -- PRUEBA 3: EMERGENCIA DURANTE MOVIMIENTO (CRÍTICA)
        -- ------------------------------------------------------------
        report "PRUEBA 3: Interrupción de Emergencia mientras sube";
        
        -- Primero, mandamos al ascensor al piso 0 para tener recorrido
        BTNC <= '1'; wait for 200 ns; BTNC <= '0';
        wait for 6000 ns; -- Esperar a que baje y abra puerta

        -- Ahora mandamos al Piso 3
        report "   -> Subiendo al piso 3...";
        BTNL <= '1'; wait for 200 ns; BTNL <= '0';
        
        -- Esperamos un poco a que termine de cerrar la puerta y empiece a subir.
        -- Sabremos que sube cuando motor sea "01".
        wait for 2000 ns; 

        report "   -> !!! EMERGENCIA ACTIVADA !!!";
        SW(15) <= '0'; -- Cambiamos el switch (Toggle detecta cambio, 1->0 tambien vale)
        
        -- AQUÍ DEBES OBSERVAR EN LA ONDA QUE 'motor' SE PONE A "00" INMEDIATAMENTE
        wait for 5000 ns; -- Dejar que termine la secuencia de emergencia

        report "FIN DE LA SIMULACION";
        wait;
    end process;

end Behavioral;