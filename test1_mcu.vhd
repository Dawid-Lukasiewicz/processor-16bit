library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test1_mcu is
--  Port ( );
end test1_mcu;

architecture Behavioral of test1_mcu is

component mcu is
  Port (
        Z: in std_logic;
        CLK: in std_logic;
        RESET: in std_logic;
        GPIO: out std_logic_vector(7 downto 0);
        IOADDR: out std_logic_vector(7 downto 0);
        IOOUT:  out std_logic_vector(7 downto 0);
        IOIN:   in std_logic_vector(7 downto 0);
        IOWR:   out std_logic;
        IORD:   out std_logic
        );
end component mcu;

constant CLK_period : time := 10 ns;

signal z : std_logic := '0';
signal clk : std_logic := '0';
signal reset : std_logic := '0';
signal gpio: std_logic_vector(7 downto 0) := "00000000";

signal ioaddr: std_logic_vector(7 downto 0) := "00000000";
signal ioout: std_logic_vector(7 downto 0) := "00000000";
signal ioin: std_logic_vector(7 downto 0) := "00000000";
signal iowr : std_logic := '0';
signal iord : std_logic := '0';

begin

    mcu1 : mcu port map(
                        Z => z,
                        CLK => clk,
                        RESET => reset,
                        GPIO => gpio,
                        IOADDR => ioaddr,
                        IOOUT => ioout,
                        IOIN => ioin,
                        IOWR => iowr,
                        IORD => iord
                        );

    CLK_process :process begin
            clk <= '0';
            wait for CLK_period/2;
            clk <= '1';
            wait for CLK_period/2;
        end process;

    test_process: process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        z <= '0';
        ioin <= x"0F";
        wait;
    end process;
end Behavioral;
