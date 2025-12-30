library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Detector_Entradas is
    Port ( clk : in STD_LOGIC;
           sw_reset : in STD_LOGIC; 
           switches_pisos : in STD_LOGIC_VECTOR(3 downto 0);
           switches_hab : in STD_LOGIC_VECTOR(3 downto 0); 
           botones : in STD_LOGIC_VECTOR(3 downto 0);
           piso_llamada : out INTEGER range 0 to 3;
           habitacion_detectada : out INTEGER range 0 to 4; 
           nueva_peticion : out STD_LOGIC;
           trigger_hab : out STD_LOGIC; 
           trigger_emergencia : out STD_LOGIC);
end Detector_Entradas;

architecture Behavioral of Detector_Entradas is
    signal in_pisos_sync, in_pisos_prev : std_logic_vector(7 downto 0);
    signal in_hab_sync, in_hab_prev : std_logic_vector(3 downto 0);
    signal sw_res_sync, sw_res_prev : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            in_pisos_sync <= switches_pisos & botones;
            in_pisos_prev <= in_pisos_sync;
            in_hab_sync <= switches_hab;
            in_hab_prev <= in_hab_sync;
            sw_res_sync <= sw_reset;
            sw_res_prev <= sw_res_sync;
            
            nueva_peticion <= '0'; trigger_emergencia <= '0'; trigger_hab <= '0';

            if sw_res_sync /= sw_res_prev then trigger_emergencia <= '1'; end if;

            if (in_pisos_sync(7)/=in_pisos_prev(7)) or (in_pisos_sync(3)='1' and in_pisos_prev(3)='0') then
                piso_llamada <= 3; nueva_peticion <= '1';
            elsif (in_pisos_sync(6)/=in_pisos_prev(6)) or (in_pisos_sync(2)='1' and in_pisos_prev(2)='0') then
                piso_llamada <= 2; nueva_peticion <= '1';
            elsif (in_pisos_sync(5)/=in_pisos_prev(5)) or (in_pisos_sync(1)='1' and in_pisos_prev(1)='0') then
                piso_llamada <= 1; nueva_peticion <= '1';
            elsif (in_pisos_sync(4)/=in_pisos_prev(4)) or (in_pisos_sync(0)='1' and in_pisos_prev(0)='0') then
                piso_llamada <= 0; nueva_peticion <= '1';
            end if;
            
            if in_hab_sync(0) /= in_hab_prev(0) then habitacion_detectada <= 1; trigger_hab <= '1';
            elsif in_hab_sync(1) /= in_hab_prev(1) then habitacion_detectada <= 2; trigger_hab <= '1';
            elsif in_hab_sync(2) /= in_hab_prev(2) then habitacion_detectada <= 3; trigger_hab <= '1';
            elsif in_hab_sync(3) /= in_hab_prev(3) then habitacion_detectada <= 4; trigger_hab <= '1';
            end if;
        end if;
    end process;
end Behavioral;