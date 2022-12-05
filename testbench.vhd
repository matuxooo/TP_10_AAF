library IEEE;
use IEEE.std_logic_1164.all;
use std.env.finish;

entity det_ir_tb is
end det_ir_tb;

architecture tb of det_ir_tb is
--Instanciacion del componente
    component det_ir is 
    port (
        clk :in std_logic;
        rst :in std_logic;
        infrarrojo: in std_logic;
        hab : in std_logic;
        valido : out std_logic;
        dir : out std_logic_vector(7 downto 0);
        cmd : out std_logic_vector(7 downto 0)
    );
    end component;
    
    --Señales
    signal clk:         std_logic;
    signal rst:         std_logic;
    signal infrarrojo:  std_logic;
    signal hab:         std_logic;
    signal valido:      std_logic;
    signal dir:         std_logic_vector(7 downto 0);
    signal cmd:         std_logic_vector(7 downto 0);
    
begin

    DUT : det_ir port map(
        clk=>         clk,   
        rst=>         rst,       
        infrarrojo=>  infrarrojo,  
        hab=>         hab,
        valido=>      valido,     
        dir=>         dir,   
        cmd=>         cmd     
    );
    reloj: process
    begin
        clk <= '0';
        wait for 93.75 us;
        clk <= '1';
        wait for 93.75 us;
    end process; 

    estimulo: process
    begin
        infrarrojo <= '1';
        rst <= '1';
        hab <= '1';
        wait for 200 us;
        rst <= '0';
        wait for 800 us;
        -- trama ir
        
        finish;
    end process;
    --PARA DESCOMENTAR (Crtl+K, Ctrl+U)
    -- estimulo_eval: process
    --     variable pass: boolean := true;
    --     ----
    -- begin
    --     ----
    --     if pass then
    --         report "Receptor remoto [PASS]";
    --     else
    --         report "Receptor remoto [FAIL]"
    --             severity failure;
    --     end if;
    --     finish;
    -- end process;
    
end tb;