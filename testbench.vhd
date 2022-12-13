library IEEE;
use IEEE.std_logic_1164.all;
use std.env.finish;

entity receptor_remoto_tb is
end receptor_remoto_tb;

architecture tb of receptor_remoto_tb is
    -- Declaracion de componente a probar
    component receptor_remoto is
        port(
            rst        : in std_logic; 
            infrarrojo : in std_logic;
            hab        : in std_logic;
            clk        : in std_logic;
            valido     : out std_logic;
            dir        : out std_logic_vector (7 downto 0);
            cmd        : out std_logic_vector (7 downto 0));
    end component;
    -- Declaraciones
    -- Constantes
    constant T_H         : time  := 93.75 us; --T_CLK = T_L + T_H = 187.5 us
    constant T_L         : time  := T_H;
    constant T_PULSO     : time  := 562.5 us;
    constant T_BURST     : time  := 16*T_PULSO;
    constant T_INICIO    : time  := 8*T_PULSO;
    constant T_UNO       : time  := 3*T_PULSO;
    constant T_CERO      : time  := T_PULSO;
    --- Señales
    signal rst_in        : std_logic; 
    signal infrarrojo_in : std_logic;
    signal hab_in        : std_logic;
    signal clk_in        : std_logic;
    signal valido_out    : std_logic;
    signal dir_out       : std_logic_vector (7 downto 0);
    signal cmd_out       : std_logic_vector (7 downto 0);
----
begin
    DUT : receptor_remoto port map (
        rst        =>rst_in       ,
        infrarrojo =>infrarrojo_in,
        hab        =>hab_in       ,
        clk        =>clk_in       ,
        valido     =>valido_out   ,
        dir        =>dir_out      ,
        cmd        =>cmd_out      );
    reloj: process
    begin
        clk_in <= '0';
        wait for T_L;
        clk_in <= '1';
        wait for T_H;
    end process;
    estimulo_eval: process
        variable pass: boolean := true;
        --- Mensaje
        constant MSG_ADDR : std_logic_vector (7 downto 0) := "00010000";
        constant MSG_CMD  : std_logic_vector (7 downto 0) := "01011010";
    begin
        -- Reset
        infrarrojo_in <= '1';
        hab_in <= '1';
        rst_in <= '1';
        wait for 2 ms;
        rst_in <= '0';
        wait for 2.5 ms;
        -- Prueba : Estado al reset
        if valido_out /= '0' then
            report   "Salida valido esperada '0' obtenida "
                   & std_logic'image(valido_out)
                   severity error;
            pass := false;
        end if;
        if dir_out /= x"00" then
            report   "Salida dir esperada 00000000 obtenida "
                   & to_string(dir_out)
                   severity error;
            pass := false;
        end if;
        if cmd_out /= x"00" then
            report   "Salida cmd esperada 00000000 obtenida "
                   & to_string(cmd_out)
                   severity error;
            pass := false;
        end if;
        -- Mensaje
            -- Inicio
        infrarrojo_in <= '0';
        wait for T_BURST;
        infrarrojo_in <= '1';
        wait for T_INICIO;
            -- Datos
        for i in 0 to 7 loop
            infrarrojo_in <= '0';
            wait for T_PULSO;
            infrarrojo_in <= '1';
            if MSG_ADDR(i) = '1' then
                wait for T_UNO;
            else
                wait for T_CERO;
            end if;
        end loop;
        for i in 0 to 7 loop
            infrarrojo_in <= '0';
            wait for T_PULSO;
            infrarrojo_in <= '1';
            if not MSG_ADDR(i) = '1' then
                wait for T_UNO;
            else
                wait for T_CERO;
            end if;
        end loop;
        for i in 0 to 7 loop
            infrarrojo_in <= '0';
            wait for T_PULSO;
            infrarrojo_in <= '1';
            if MSG_CMD(i) = '1' then
                wait for T_UNO;
            else
                wait for T_CERO;
            end if;
        end loop;
        for i in 0 to 7 loop
            infrarrojo_in <= '0';
            wait for T_PULSO;
            infrarrojo_in <= '1';
            if not MSG_CMD(i) = '1' then
                wait for T_UNO;
            else
                wait for T_CERO;
            end if;
        end loop;
            -- Fin
        infrarrojo_in <= '0';
        wait for T_PULSO;
        infrarrojo_in <= '1';
        wait for 4.5 ms;
        -- Prueba : comando válido recibido
        if valido_out /= '1' then
            report   "Salida valido esperada '1' obtenida "
                   & std_logic'image(valido_out)
                   severity error;
            pass := false;
        end if;
        if dir_out /= x"10" then
            report   "Salida dir esperada 00010000 obtenida "
                   & to_string(dir_out)
                   severity error;
            pass := false;
        end if;
        if cmd_out /= x"5A" then
            report   "Salida cmd esperada 01011010 obtenida "
                   & to_string(cmd_out)
                   severity error;
            pass := false;
        end if;

        if pass then
            report "Receptor remoto [PASS]";
        else
            report "Receptor remoto [FAIL]"
                severity failure;
        end if;
        finish;
    end process;
end tb;