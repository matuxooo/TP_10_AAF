Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ffd_pkg.all;

entity receptor_remoto is 
    port (
        clk :in std_logic;
        rst :in std_logic;
        infrarrojo: in std_logic;
        hab : in std_logic;
        valido : out std_logic;
        dir : out std_logic_vector(7 downto 0);
        cmd : out std_logic_vector(7 downto 0)
    );
end receptor_remoto;

architecture solucion of receptor_remoto is
    signal Ts,Tp :                                  std_logic_vector(7 downto 0);
    signal Mpulse, Mspace, pulsos, trama_valida :   std_logic;
    signal inicio, bit_0, bit_1:                    std_logic;
    signal not_infrarrojo :                         std_logic;
    
    signal Med_act, Med_sig :           std_logic_vector(0 downto 0);
    signal cuenta_act, cuenta_sig :         std_logic_vector(7 downto 0);
    signal registro_act, registro_sig : std_logic_vector (31 downto 0);
    signal valido_act, valido_sig   :   std_logic_vector(0 downto 0);
    signal dir_act, dir_sig     :       std_logic_vector(7 downto 0);
    signal cmd_act, cmd_sig     :       std_logic_vector(7 downto 0);

    --Nombre de estados
    subtype estado_t is std_logic_vector(1 downto 0);
    signal estado_act, estado_sig : estado_t;
    constant e_espera : estado_t        := "00";
    constant e_recepcion : estado_t     := "01";
    constant e_recepcion_1 : estado_t    := "10";

    component det_tiempo is
        generic (
            constant N : natural := 4);
        port(
            rst : in std_logic;
            pulso : in std_logic;
            hab : in std_logic;
            clk : in std_logic;
            med : out std_logic;
            tiempo : out std_logic_vector (N-1 downto 0));
    end component;

begin
    not_infrarrojo<=not(infrarrojo);

    --Memoria de estados
    Med: ffd
    generic map(N=>1)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => Med_act,
            D => Med_sig
        );
    
    flipflop_estado: ffd
    generic map(N => 2)
    port map(
        rst => rst,
        hab => hab,
        clk => clk,
        Q   => estado_act,
        D   => estado_sig
    );    

    contador_interno: ffd
    generic map(N=>8)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => cuenta_act,
            D => cuenta_sig
        ); 

    registro_desplazamiento: ffd
    generic map(N=>32)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => registro_act,
            D => registro_sig
        );
    
    salida_valido: ffd
    generic map(N=>1)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => valido_act,
            D => valido_sig
        );

    salida_dir: ffd
    generic map(N=>8)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => dir_act,
            D => dir_sig
        );
    salida_cmd: ffd
    generic map(N=>8)
        port map(
            rst => rst,
            hab => hab,
            clk => clk,
            Q => cmd_act,
            D => cmd_sig
        );
     
        
    --Medidores de pulsos
    contador_pulso: det_tiempo 
    generic map(N=>8)
        port map(
            rst=>rst,
            hab=>hab,
            clk=>clk,
            pulso=>infrarrojo,
            med=>Mpulse,
            tiempo=>Tp
        );
    contador_espacio: det_tiempo
    generic map(N=>8)
        port map(
            rst=>rst,
            hab=>hab,
            clk=>clk,
            pulso=>not_infrarrojo,
            med=>Mspace,
            tiempo=>Ts
        );
        
    
    proceso_estados: process(all)
    begin
        case(estado_act) is
            when e_espera =>
                if inicio='1' and pulsos='1' then
                    estado_sig<=e_recepcion_1;
                else
                    estado_sig<=e_espera;
                end if;
            when e_recepcion_1 =>
                if unsigned(cuenta_act)<32 and pulsos='0' then
                    estado_sig<=e_recepcion;
                elsif pulsos='0' and unsigned(cuenta_act)=32 and trama_valida /= '1' then
                    estado_sig<=e_espera;
                else
                    estado_sig<=e_recepcion_1;     --no muy seguro de mandarlo ahí
                end if;
            when e_recepcion =>
                if bit_1='1' and pulsos='1' then
                    estado_sig<=e_recepcion_1;
                elsif bit_0='1' and pulsos='1' then
                    estado_sig<=e_recepcion_1;
                elsif inicio='1' and pulsos='1' then
                    estado_sig<=e_recepcion_1;
                else
                    estado_sig<=e_recepcion;   --tampoco seguro de mandar acá    
                end if;
            when others =>
                    estado_sig<=e_espera;                                            
        end case;        
    end process;

    proceso_contador: process(all)
    begin
        case (estado_act) is
            when e_espera =>
                if inicio='1' and pulsos='1' then
                    cuenta_sig<=(others=>'0');
                else
                    cuenta_sig<=cuenta_act;
                end if;
            when e_recepcion_1 =>
                cuenta_sig<=cuenta_act;
            when e_recepcion =>
                if bit_1='1' and pulsos='1' then
                    cuenta_sig<=std_logic_vector(unsigned(cuenta_act)+1);
                elsif bit_0='1' and pulsos='1' then
                    cuenta_sig<=std_logic_vector(unsigned(cuenta_act)+1);                
                elsif inicio='1' and pulsos='1' then
                    cuenta_sig<=(others=>'0');
                else
                    cuenta_sig<=cuenta_act;
                end if;
            when others =>
                cuenta_sig<=cuenta_act;
        end case;                    
    end process;

    proceso_registro_de_desplazamiento: process(all)
    begin
        case (estado_act) is
            when e_espera =>
                registro_sig<=registro_act;
            when e_recepcion =>
                if bit_1='1' and pulsos='1' then
                    registro_sig<='1' & registro_act(31 downto 1);
                elsif bit_0='1' and pulsos='1' then
                    registro_sig<='0' & registro_act(31 downto 1);
                else
                    registro_sig<=registro_act;
                end if;    
            when others =>    --e_recepcion_1
                registro_sig<=registro_act;
            end case;                        
    end process; 
    
    proceso_salidas: process(all)
    begin
        case (estado_act) is
            when e_espera =>
                if inicio='1' and pulsos='1' then
                    valido_sig<="0";
                    dir_sig<=dir_act;
                    cmd_sig<=cmd_act;
                else
                    valido_sig<=valido_act;
                    dir_sig<=dir_act;
                    cmd_sig<=cmd_act;
                end if;
            when e_recepcion =>
                valido_sig<=valido_act;
                dir_sig<=dir_act;
                cmd_sig<=cmd_act;
            when e_recepcion_1 =>
                if pulsos='0' and unsigned(cuenta_act)=32 and trama_valida='1' then
                    valido_sig<="1";
                    dir_sig<=registro_act(7 downto 0);
                    cmd_sig<=registro_act(23 downto 16);
                else
                    valido_sig<=valido_act;
                    dir_sig<=dir_act;
                    cmd_sig<=cmd_act;
                end if;
            when others => 
                valido_sig<=valido_act;
                dir_sig<=dir_act;
                cmd_sig<=cmd_act;                           
        end case;
    end process;

    --Conexion de salidas
    valido<=valido_act(0);
    cmd<=cmd_act;
    dir<=dir_act;   
    
    --Señales intermedias
    Med_sig(0)<=Mspace; 
    pulsos<= Med_sig(0) and not(Med_act(0));
    
    trama_valida<=  '1' when (not(registro_act(31 downto 24))=registro_act(23 downto 16)) and (not(registro_act(15 downto 8))=registro_act(7 downto 0))
                        else '0';
    inicio<='1' when unsigned(Ts)>20 and unsigned(Ts)<26 and unsigned(Tp)<52 and unsigned(Tp)>42
                else '0';                         
    bit_1<='1'  when unsigned(Ts)>7 and unsigned(Ts)<10 and unsigned(Tp)<4 and unsigned(Tp)>1
                else '0';  
    bit_0<='1'  when unsigned(Ts)>1 and unsigned(Ts)<4 and unsigned(Tp)<4 and unsigned(Tp)>1
                else '0';    
                
                
   
end solucion;
        