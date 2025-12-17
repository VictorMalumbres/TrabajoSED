library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Detector_Entradas is
    Port ( clk : in STD_LOGIC;
           sw_reset : in STD_LOGIC; -- SW[15]
           switches : in STD_LOGIC_VECTOR(3 downto 0);
           botones : in STD_LOGIC_VECTOR(3 downto 0);
           piso_llamada : out INTEGER range 0 to 3;
           nueva_peticion : out STD_LOGIC;
           trigger_emergencia : out STD_LOGIC); -- Señal de disparo de emergencia
end Detector_Entradas;

architecture Behavioral of Detector_Entradas is
    signal inputs_sync, inputs_prev : std_logic_vector(7 downto 0);
    signal sw_res_sync, sw_res_prev : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Sincronización
            inputs_sync <= switches & botones;
            inputs_prev <= inputs_sync;
            
            sw_res_sync <= sw_reset;
            sw_res_prev <= sw_res_sync;
            
            nueva_peticion <= '0';
            piso_llamada <= 0; 
            trigger_emergencia <= '0';

            -- 1. DETECCIÓN DE EMERGENCIA (Cualquier cambio en SW15)
            if sw_res_sync /= sw_res_prev then
                trigger_emergencia <= '1';
            end if;

            -- 2. DETECCIÓN DE LLAMADAS (Toggle Switch o Botón)
            if (inputs_sync(7) /= inputs_prev(7)) or (inputs_sync(3)='1' and inputs_prev(3)='0') then
                piso_llamada <= 3; nueva_peticion <= '1';
            elsif (inputs_sync(6) /= inputs_prev(6)) or (inputs_sync(2)='1' and inputs_prev(2)='0') then
                piso_llamada <= 2; nueva_peticion <= '1';
            elsif (inputs_sync(5) /= inputs_prev(5)) or (inputs_sync(1)='1' and inputs_prev(1)='0') then
                piso_llamada <= 1; nueva_peticion <= '1';
            elsif (inputs_sync(4) /= inputs_prev(4)) or (inputs_sync(0)='1' and inputs_prev(0)='0') then
                piso_llamada <= 0; nueva_peticion <= '1';
            end if;
        end if;
    end process;
end Behavioral;