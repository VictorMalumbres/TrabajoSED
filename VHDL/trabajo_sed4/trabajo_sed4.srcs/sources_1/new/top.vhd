library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_ASCENSOR is
    Port ( CLK100MHZ : in STD_LOGIC;
           CPU_RESETN : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR(15 downto 0); 
           BTNC, BTNU, BTND, BTNL : in STD_LOGIC;   
           LED : out STD_LOGIC_VECTOR(15 downto 0); 
           SEG : out STD_LOGIC_VECTOR(6 downto 0);  
           AN  : out STD_LOGIC_VECTOR(7 downto 0);
           AUD_PWM, AUD_SD : out STD_LOGIC;
           LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B : out STD_LOGIC);
end TOP_ASCENSOR;

architecture Structural of TOP_ASCENSOR is
    signal rst : std_logic;
    signal t_1, t_d, t_a, t_b, n_p, t_h, t_e, tm_s, tm_d, d_o, mus, d_s, alm, err : std_logic;
    signal p_o, p_a : integer range 0 to 3;
    signal h_o, h_a : integer range 1 to 4;
    signal st : integer range 0 to 8;
    signal tm_dur : integer;
    signal m_v, m_h : std_logic_vector(1 downto 0);
    signal rgb : std_logic_vector(5 downto 0);
    signal btns_vec : std_logic_vector(3 downto 0); -- Solución error línea 28
begin
    rst <= not CPU_RESETN;
    btns_vec <= BTNL & BTND & BTNU & BTNC; -- Concatenación segura fuera del port map

    U_Div: entity work.Divisor_Frecuencia port map(CLK100MHZ, rst, t_1, t_d, t_b, t_a);
    
    U_In: entity work.Detector_Entradas port map(
        clk => CLK100MHZ, 
        sw_reset => SW(15), 
        switches_pisos => SW(3 downto 0), 
        switches_hab => SW(8 downto 5), 
        botones => btns_vec, 
        piso_llamada => p_o, 
        habitacion_detectada => h_o, 
        nueva_peticion => n_p, 
        trigger_hab => t_h, 
        trigger_emergencia => t_e
    );
    
    U_FSM: entity work.FSM_Controlador port map(
        clk => CLK100MHZ, reset => rst, piso_actual => p_a, piso_llamada => p_o, 
        hay_peticion => n_p, trigger_hab => t_h, habitacion_in => h_o, hab_actual => h_a, 
        sw_sobrecarga => SW(4), trigger_emergencia => t_e, timer_done => tm_d, motor => m_v, 
        motor_hor => m_h, timer_start => tm_s, timer_dur => tm_dur, estado_vis => st, 
        puerta_abierta => d_o, play_musica => mus, play_puerta => d_s, play_alarma => alm, play_error => err
    );
    
    U_Tmr: entity work.Temporizador port map(CLK100MHZ, rst, t_1, tm_s, tm_dur, tm_d);
    U_Plant: entity work.Simulador_Planta port map(CLK100MHZ, rst, t_1, m_v, m_h, p_a, h_a);
    U_Audio: entity work.Controlador_Audio port map(CLK100MHZ, mus, d_s, alm, err, AUD_PWM, AUD_SD);
    U_Vis: entity work.Controlador_Display port map(CLK100MHZ, t_d, t_b, t_a, p_a, h_a, st, d_o, SEG, AN, LED, rgb);

    LED17_R <= rgb(5); LED17_G <= rgb(4); LED17_B <= rgb(3);
    LED16_R <= rgb(2); LED16_G <= rgb(1); LED16_B <= rgb(0);
end Structural;