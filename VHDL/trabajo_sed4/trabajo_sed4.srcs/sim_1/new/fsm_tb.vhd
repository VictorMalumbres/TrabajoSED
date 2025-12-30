library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_Controlador_TB is
-- Entidad vacía
end FSM_Controlador_TB;

architecture Behavioral of FSM_Controlador_TB is

    -- 1. Declaración del Componente
    component FSM_Controlador
        Port ( 
            clk, reset : in STD_LOGIC;
            piso_actual, piso_llamada : in INTEGER range 0 to 3;
            hay_peticion, trigger_hab : in STD_LOGIC;
            habitacion_in, hab_actual : in INTEGER range 1 to 4;
            sw_sobrecarga, trigger_emergencia, timer_done : in STD_LOGIC;
            motor, motor_hor : out STD_LOGIC_VECTOR(1 downto 0);
            timer_start : out STD_LOGIC;
            timer_dur : out INTEGER;
            estado_vis : out INTEGER range 0 to 8; 
            puerta_abierta : out STD_LOGIC;
            play_musica, play_puerta, play_alarma, play_error : out STD_LOGIC
        );
    end component;

    -- 2. Señales de Estímulo
    signal clk_tb : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal p_act_tb : integer range 0 to 3 := 0;
    signal p_ll_tb : integer range 0 to 3 := 0;
    signal h_pet_tb : std_logic := '0';
    signal t_hab_tb : std_logic := '0';
    signal h_in_tb : integer range 1 to 4 := 1;
    signal h_act_tb : integer range 1 to 4 := 1;
    signal sw_sob_tb : std_logic := '0';
    signal t_emerg_tb : std_logic := '0';
    signal t_done_tb : std_logic := '0';

    -- Señales de Observación
    signal motor_tb, motor_h_tb : std_logic_vector(1 downto 1); -- Simplificado para vista
    signal t_start_tb : std_logic;
    signal st_vis_tb : integer range 0 to 8;
    signal door_tb : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancia de la UUT
    uut: FSM_Controlador port map (
        clk => clk_tb, reset => reset_tb,
        piso_actual => p_act_tb, piso_llamada => p_ll_tb,
        hay_peticion => h_pet_tb, trigger_hab => t_hab_tb,
        habitacion_in => h_in_tb, hab_actual => h_act_tb,
        sw_sobrecarga => sw_sob_tb, trigger_emergencia => t_emerg_tb,
        timer_done => t_done_tb,
        motor => open, motor_hor => open, -- Usamos open si no queremos mapear salidas vectoriales aquí
        timer_start => t_start_tb, timer_dur => open,
        estado_vis => st_vis_tb, puerta_abierta => door_tb,
        play_musica => open, play_puerta => open, play_alarma => open, play_error => open
    );

    -- 4. Generador de Reloj
    clk_process : process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de Estímulos
    stim_proc: process
    begin
        report "--- INICIO TEST FSM ---";
        reset_tb <= '1'; wait for 50 ns;
        reset_tb <= '0'; wait for 50 ns;

        -- PRUEBA 1: Ciclo Vertical (Piso 0 a Piso 2)
        report "P1: Llamada Piso 2";
        p_ll_tb <= 2; h_pet_tb <= '1';
        wait for 20 ns; h_pet_tb <= '0';
        -- Debe estar en CERRANDO (st=4). Simulamos que el timer de cerrar termina:
        wait for 40 ns; t_done_tb <= '1'; wait for 10 ns; t_done_tb <= '0';
        -- Ahora debe estar en SUBIENDO (st=1). Simulamos llegada al piso 2:
        wait for 100 ns; p_act_tb <= 2;
        -- Debe estar en LLEGADA (st=0). Simulamos fin de timer:
        wait for 40 ns; t_done_tb <= '1'; wait for 10 ns; t_done_tb <= '0';
        -- Debe estar en ABRIENDO (st=3). Simulamos fin de timer:
        wait for 40 ns; t_done_tb <= '1'; wait for 10 ns; t_done_tb <= '0';

        -- PRUEBA 2: Sobrecarga
        report "P2: Activando Sobrecarga en IDLE";
        sw_sob_tb <= '1'; wait for 100 ns;
        -- Debería estar en estado 7 (L). Intentamos llamar a un piso:
        p_ll_tb <= 3; h_pet_tb <= '1'; wait for 20 ns; h_pet_tb <= '0';
        -- El estado NO debe cambiar de 7.
        wait for 100 ns;
        sw_sob_tb <= '0'; -- Quitamos sobrecarga
        wait for 100 ns;

        -- PRUEBA 3: Ciclo Horizontal (Hab 1 a Hab 4)
        report "P3: Llamada Hab 4";
        h_in_tb <= 4; t_hab_tb <= '1';
        wait for 20 ns; t_hab_tb <= '0';
        -- CERRANDO (st=4) -> Timer:
        wait for 40 ns; t_done_tb <= '1'; wait for 10 ns; t_done_tb <= '0';
        -- MOVIENDO_HOR (st=8). Simulamos llegada a Hab 4:
        wait for 100 ns; h_act_tb <= 4;
        -- LLEGADA (st=0) -> Timer:
        wait for 40 ns; t_done_tb <= '1'; wait for 10 ns; t_done_tb <= '0';
        -- ABRIENDO (st=3)...

        report "--- FIN TEST FSM ---";
        wait;
    end process;

end Behavioral;