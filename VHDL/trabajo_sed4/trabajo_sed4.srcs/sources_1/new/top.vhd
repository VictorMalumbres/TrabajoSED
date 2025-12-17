library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_ASCENSOR is
    Port ( CLK100MHZ : in STD_LOGIC;
           CPU_RESETN : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR(3 downto 0);    
           BTNC, BTNU, BTND, BTNL : in STD_LOGIC;   
           
           LED : out STD_LOGIC_VECTOR(15 downto 0); 
           SEG : out STD_LOGIC_VECTOR(6 downto 0);  
           AN  : out STD_LOGIC_VECTOR(7 downto 0)   
           );
end TOP_ASCENSOR;

architecture Structural of TOP_ASCENSOR is
    signal rst_sys : std_logic;
    signal tick_1hz, tick_disp, tick_anim : std_logic;
    signal btns_vector : std_logic_vector(3 downto 0);
    signal piso_obj, piso_act : integer range 0 to 3;
    signal nueva_pet : std_logic;
    signal tmr_start, tmr_done : std_logic;
    signal tmr_dur : integer;
    signal motor_cmd : std_logic_vector(1 downto 0);
    signal st_vis : integer range 0 to 4;
    signal door_open : std_logic;

begin
    rst_sys <= not CPU_RESETN; 
    btns_vector <= BTNL & BTND & BTNU & BTNC; 

    U_Div: entity work.Divisor_Frecuencia
        port map(clk=>CLK100MHZ, reset=>rst_sys, en_1hz=>tick_1hz, en_disp=>tick_disp, en_anim=>tick_anim);

    U_In: entity work.Detector_Entradas
        port map(clk=>CLK100MHZ, switches=>SW, botones=>btns_vector, 
                 piso_llamada=>piso_obj, nueva_peticion=>nueva_pet);

    U_FSM: entity work.FSM_Controlador
        port map(clk=>CLK100MHZ, reset=>rst_sys,
                 piso_actual=>piso_act, piso_llamada=>piso_obj, hay_peticion=>nueva_pet,
                 timer_done=>tmr_done, motor=>motor_cmd, 
                 timer_start=>tmr_start, timer_dur=>tmr_dur,
                 estado_vis=>st_vis, puerta_abierta=>door_open);

    U_Tmr: entity work.Temporizador
        port map(clk=>CLK100MHZ, reset=>rst_sys, en_1hz=>tick_1hz,
                 start=>tmr_start, duracion=>tmr_dur, fin_tiempo=>tmr_done);

    U_Plant: entity work.Simulador_Planta
        port map(clk=>CLK100MHZ, reset=>rst_sys, en_1hz=>tick_1hz,
                 motor=>motor_cmd, piso_actual=>piso_act);

    U_Vis: entity work.Controlador_Display
        port map(clk=>CLK100MHZ, en_disp=>tick_disp, en_anim=>tick_anim,
                 piso=>piso_act, estado_vis=>st_vis, puerta_abierta=>door_open,
                 seg=>SEG, an=>AN, leds=>LED);

end Structural;