library IEEE;
use IEEE.std_logic_1164.all;
use std.env.finish;

entity det_ir_tb is
end det_ir_tb;

architecture tb of det_ir_tb is
begin
    estimulo_eval: process
        variable pass: boolean := true;
        ----
    begin
        ----
        if pass then
            report "Receptor remoto [PASS]";
        else
            report "Receptor remoto [FAIL]"
                severity failure;
        end if;
        finish;
    end process;
    --report "Receptor remoto [PASS]";
end tb;