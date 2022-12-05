Library IEEE;
use IEEE.std_logic_1164.all;

entity det_ir is 
    port (
        clk :in std_logic;
        rst :in std_logic;
        infrarrojo: in std_logic;
        hab : in std_logic;
        valido : out std_logic;
        dir : out std_logic_vector(7 downto 0);
        cmd : out std_logic_vector(7 downto 0)
    );
end det_ir;

architecture solucion of det_ir is
begin
end solucion;
        