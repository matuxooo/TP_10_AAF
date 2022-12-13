library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ffd_pkg.all;

entity det_tiempo is
    generic (
        constant N : natural := 4);
    port(
        rst : in std_logic;
        pulso : in std_logic;
        hab : in std_logic;
        clk : in std_logic;
        med : out std_logic;
        tiempo : out std_logic_vector (N-1 downto 0));
end det_tiempo;

architecture solucion of det_tiempo is
    signal cuenta_act, cuenta_sig : std_logic_vector(N-1 downto 0);
    signal tiempo_act, tiempo_sig : std_logic_vector (N-1 downto 0);
    signal med_act, med_sig : std_logic_vector (0 downto 0);

    subtype estados is std_logic_vector(0 downto 0);
    signal estado_act, estado_sig : estados;
    constant espera : estados := "0";
    constant cuenta : estados := "1";
    
begin     
    flipflop_estado: ffd
    generic map(N => 1)
    port map(rst => rst, hab => hab, clk => clk, D=> estado_sig, Q=>estado_act);

    flipflop_cuentaInterna : ffd
    generic map (N => N)
        port map(rst => rst, hab => hab, clk => clk, D => cuenta_sig, Q =>cuenta_act);

    flipflop_tiempo : ffd
    generic map (N => N ) 
        port map(rst => rst, hab => hab, clk => clk,D=>tiempo_sig, Q=>tiempo_act);

    flipflop_med : ffd
    generic map (N => 1 ) 
        port map(rst => rst, hab => hab, clk => clk, D=> med_sig,Q=> med_act);


    salidas :  process (all)
    begin
        case (estado_act) is
        when espera =>
            if pulso = '1' then
                tiempo_sig<= tiempo_act;
                med_sig<=med_act;
            else
                tiempo_sig <= tiempo_act;
                med_sig(0)<='0';
            end if;
        when others => 
            if pulso = '1' then
                tiempo_sig<= cuenta_act;
                med_sig (0)<= '1' ;
            else
                tiempo_sig <= tiempo_act;
                med_sig<=med_act;
            end if;
        end case;
    end process;


    contador :  process (all)
    begin
        case (estado_act) is 
        when cuenta =>
            if pulso = '0' and (unsigned(cuenta_act) /= 0)  then
                cuenta_sig <= std_logic_vector(unsigned (cuenta_act) + 1);
            else
                cuenta_sig <= cuenta_act;
            end if;
        when others => 
            if pulso = '0' then 
                cuenta_sig <= (0=>'1', others => '0');
            else 
                cuenta_sig <= cuenta_act;
            end if;
        end case;
    end process;

    process (all)
    begin
        case(estado_act) is
        when espera =>
            if pulso = '0' then
                estado_sig <=cuenta;
            else
                estado_sig <=espera;
            end if;
        when cuenta =>
            if pulso = '0' then
                estado_sig <= cuenta;
            else
                estado_sig <= espera;
            end if;
        when others=>
            estado_sig<= espera;
        end case ;
    end process;

    tiempo <= tiempo_act;
    med <=med_act(0);

end solucion;