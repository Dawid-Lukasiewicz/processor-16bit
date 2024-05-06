library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity mcu is
  Port (
        Z:      in std_logic;
        CLK:    in std_logic;
        RESET:  in std_logic;
        GPIO:   out std_logic_vector(7 downto 0);
        IOADDR: out std_logic_vector(7 downto 0);
        IOOUT:  out std_logic_vector(7 downto 0);
        IOIN:   in std_logic_vector(7 downto 0);
        IOWR:   out std_logic;
        IORD:   out std_logic
        );
end mcu;

architecture Behavioral of mcu is

signal PC: std_logic_vector(7 downto 0) := x"00";

signal IR: std_logic_vector(15 downto 0);
alias OPCODE: std_logic_vector(7 downto 0) is IR(15 downto 8);
alias ARG: std_logic_vector(7 downto 0) is IR(7 downto 0);

signal SREG: std_logic_vector(7 downto 0) := x"00";
alias SREG_C: std_logic is SREG(0);
alias SREG_Z: std_logic is SREG(1);
alias SREG_N: std_logic is SREG(2);
alias SREG_V: std_logic is SREG(3);
alias SREG_S: std_logic is SREG(4);
alias SREG_H: std_logic is SREG(5);
alias SREG_T: std_logic is SREG(6);
alias SREG_I: std_logic is SREG(7);

signal INPR: std_logic_vector(3 downto 0);

-- Instrucktion code: 			xxxxx
-- Register instructions: 		1xxxx
-- Constant Val intructions: 	0xxxx

--CP Rd, Rs
constant MC_CP: std_logic_vector(15 downto 0)  := "1000000000------";
constant C_CP: std_logic_vector(9 downto 0)    := "1000000000";
--CPI Rd, K
constant MC_CPI: std_logic_vector(15 downto 0)  := "00000-----------";
constant C_CPI: std_logic_vector(4 downto 0)    := "00000";
--MOV Rd, Rs
constant MC_MOV: std_logic_vector(15 downto 0)  := "1000100000------";
constant C_MOV: std_logic_vector(9 downto 0)    := "1000100000";
-- LDI Rd, K
constant MC_LDI: std_logic_vector(15 downto 0)  := "00001-----------";
constant C_LDI: std_logic_vector(4 downto 0)    := "00001";
--LD Rd, Rs
constant MC_LD: std_logic_vector(15 downto 0)  := "1001000000------";
constant C_LD: std_logic_vector(9 downto 0)    := "1001000000";
--LDS Rd, K
constant MC_LDS: std_logic_vector(15 downto 0)  := "00010-----------";
constant C_LDS: std_logic_vector(4 downto 0)    := "00010";
--ST Rd, Rs
constant MC_ST: std_logic_vector(15 downto 0)  := "1001100000------";
constant C_ST: std_logic_vector(9 downto 0)    := "1001100000";
--STS K, Rs
constant MC_STS: std_logic_vector(15 downto 0)  := "00011-----------";
constant C_STS: std_logic_vector(4 downto 0)    := "00011";
--BCLR K
constant MC_BCLR: std_logic_vector(15 downto 0)     := 	"00100000--------";
constant C_BCLR: std_logic_vector(7 downto 0)      := 	"00100000";
--BSET K
constant MC_BSET: std_logic_vector(15 downto 0)     := 	"00101000--------";
constant C_BSET: std_logic_vector(7 downto 0)      := 	"00101000";
--ADC Rd, Rs
constant MC_ADC: std_logic_vector(15 downto 0)  := "1010000000------";
constant C_ADC: std_logic_vector(9 downto 0)    := "1010000000";
--ADCI Rd, K
constant MC_ADCI: std_logic_vector(15 downto 0)  := "00111-----------";
constant C_ADCI: std_logic_vector(4 downto 0)    := "00111";
--SBC Rd, Rs
constant MC_SBC: std_logic_vector(15 downto 0)  := "1010100000------";
constant C_SBC: std_logic_vector(9 downto 0)    := "1010100000";
--SBCI Rd, K
constant MC_SBCI: std_logic_vector(15 downto 0)  := "01000-----------";
constant C_SBCI: std_logic_vector(4 downto 0)    := "01000";
--MUL Rd, Rs
constant MC_MUL: std_logic_vector(15 downto 0)  := "1011000000------";
constant C_MUL: std_logic_vector(9 downto 0)    := "1011000000";
--MULS Rd, Rs
constant MC_MULS: std_logic_vector(15 downto 0)  := "1011100000------";
constant C_MULS: std_logic_vector(9 downto 0)    := "1011100000";
--BRBS S, K
constant MC_BRBS: std_logic_vector(15 downto 0)     := 	"01001-----------";
constant C_BRBS: std_logic_vector(4 downto 0)      := 	"01001";
--BRBC S, K
constant MC_BRBC: std_logic_vector(15 downto 0)     := 	"01010-----------";
constant C_BRBC: std_logic_vector(4 downto 0)      := 	"01010";

--Instrukcje logiczne:
--AND Rd, Rs - iloczyn logiczny rejestr�w Rs i Rd (Rd ? Rd and Rs),
constant MC_AND: std_logic_vector(15 downto 0)     := 	"1100100000------";
constant C_AND: std_logic_vector(9 downto 0)      := 	"1100100000";
--ANDI Rd, K - iloczyn logiczny rejestru Rd i sta�ej 8-bitowej K (Rd ? Rd and K),
constant MC_ANDI: std_logic_vector(15 downto 0)     := 	"01011-----------";
constant C_ANDI: std_logic_vector(4 downto 0)      := 	"01011";
--OR Rd, Rs - suma logiczna rejestr�w Rs i Rd (Rd ? Rd or Rs),
constant MC_OR: std_logic_vector(15 downto 0)     := 	"1101000000------";
constant C_OR: std_logic_vector(9 downto 0)      := 	"1101000000";
--ORI Rd, K - suma logiczna rejestru Rd i sta�ej 8-bitowej K (Rd ? Rd or K),
constant MC_ORI: std_logic_vector(15 downto 0)     := 	"01100-----------";
constant C_ORI: std_logic_vector(4 downto 0)      := 	"01100";
--XOR Rd, Rs - alternatywa roz��czna rejestr�w Rs i Rd (Rd ? Rd xor Rs),
constant MC_XOR: std_logic_vector(15 downto 0)     := 	"1101100000------";
constant C_XOR: std_logic_vector(9 downto 0)      := 	"1101100000";
--XORI Rd, K - alternatywa roz��czna rejestru Rd i sta�ej 8-bitowej K (Rd ? Rd xor K).
constant MC_XORI: std_logic_vector(15 downto 0)     := 	"01101-----------";
constant C_XORI: std_logic_vector(4 downto 0)      := 	"01101";

--NOP
constant MC_NOP: std_logic_vector(15 downto 0) := 	"11100000--------";
constant C_NOP: std_logic_vector(7 downto 0) := 	"11100000";
--OUTP K
constant MC_OUTP1: std_logic_vector(15 downto 0) := 	"01110000--------";
constant C_OUTP1: std_logic_vector(7 downto 0) := 	"01110000";
--B K
constant MC_B: std_logic_vector(15 downto 0) := 	"01111000--------";
constant C_B: std_logic_vector(7 downto 0) := 		"01111000";
--BZ K
constant MC_BZ: std_logic_vector(15 downto 0) := 	"11100000--------";
constant C_BZ: std_logic_vector(7 downto 0) := 		"11100000";
--OUTP Rs, K
constant MC_OUTP: std_logic_vector(15 downto 0) := 	"11101-----------";
constant C_OUTP: std_logic_vector(4 downto 0) :=    "11101";
--INP Rd, K
constant MC_INP: std_logic_vector(15 downto 0) := 	"11110-----------";
constant C_INP: std_logic_vector(4 downto 0) := 	"11110";

alias ARG_R: std_logic_vector(5 downto 0) is IR(5 downto 0);
alias ARG_R1: std_logic_vector(2 downto 0) is ARG_R(5 downto 3);
alias ARG_R2: std_logic_vector(2 downto 0) is ARG_R(2 downto 0);

--8 bit argument
alias ARG_K1: std_logic_vector(2 downto 0) is IR(10 downto 8);
alias ARG_K2: std_logic_vector(7 downto 0) is IR(7 downto 0);

-- Pami�� Read Only Memory (ROM),128 komórki o długości słowa 16 bit
type rom_t is array (0 to 127) of std_logic_vector(15 downto 0);
-- Przykładowe odwoływanie się do pamięci w ROM
-- PC - program counter jako indeks
-- IR <= ROM(to_integer(unsigned(PC)));
constant ROM: rom_t := (
-- Test program 2
--                    C_LDI & "001" & x"35", -- za�adowanie warto�ci x35 do rejestru R1
--                    C_LDI & "100" & x"79", -- za�adowanie warto�ci x79 do rejestru R4
--                    C_MOV & "101" & "001", -- przes�anie zawarto�ci rejestru R1 do rejestru R5
--                    C_LDI & "001" & x"02", -- za�adowanie warto�ci x02 do rejestru R1
--                    C_ST & "001" & "100", -- zapisanie zawarto�ci rejestru R4 do pami�ci RAM
--                     -- pod adres zawarty w R1 (adres x02)
--                    C_STS & "100" & x"05", -- zapisanie zawarto�ci rejestru R4 do pami�ci RAM
--                     -- pod adres x05
--                    C_LD & "110" & "001", -- za�adowanie warto�ci z pami�ci RAM spod adresu
--                     -- zawartego w rejestrze R1 do rejestru R6
--                    C_LDS & "111" & x"05", -- za�adowanie warto�ci z pami�ci RAM spod adresu
--                     -- x05 do rejestru R7
--                    C_B & x"00", -- skok na poczatek programu
--                    others => x"0000"
-- Test program 3
--					Testowanie por�wniania
					C_BCLR & x"FF",			-- Wyzeruj SREG
					C_LDI & "000" & x"04",	-- Za�aduj 4 do R0
					C_LDI & "001" & x"04",	-- Za�aduj 4 do R1
					C_CP & "000" & "001",	-- Por�wnaj R0 do R1
					C_BCLR & x"FF",			-- Wyzeruj SREG
					C_CPI & "000" & x"04",	-- Por�wnaj R0 do 4

--					Mno�enie 2 * 10
					C_BCLR & x"ff",
                    C_LDI & "001" & x"05", -- za�adowanie warto�ci x05=5 do rejestru R1
                    C_LDI & "011" & x"02", -- za�adowanie warto�ci�ci x02=2 do rejestru R3
                    C_MUL & "001" & "011", -- mno�enie R1 * R3 = x0a=10
                    C_STS  & "000" & x"00", -- przenie�� warto�ci mno�enia z R0 do RAM0

--                  Mno�enie 2 * 130
					C_BCLR & x"ff",
                    C_LDI & "010" & x"82", -- za�adowanie warto�ci x82=130 do rejestru R2
                    C_MUL & "010" & "011", -- mno�enie R2 * R3
                    C_STS  & "000" & x"02", -- przenie� warto�co mno�enia z R0 do RAM2
                    C_STS  & "001" & x"03", -- przenie� warto�ci mno�enia z R1 do RAM3

--                  Mno�enie -2 * 50
					C_BCLR & x"ff",
                    C_LDI & "010" & x"32", -- za�adowanie warto�ci x32=50 do rejestru R2
					C_LDI & "011" & x"FE", -- za�adowanie warto�ci -2 (11111110) do rejestru R3
					C_MULS & "010" & "011", -- mno�enie ze znakiem R2 * R3 = 50*(-2)=-100
                    C_STS  & "000" & x"05", -- przenie� warto�� mno�enia z R0 do RAM5
                    C_STS  & "001" & x"06", -- przenie� warto�� mno�enia z R1 do RAM6

--  				Dodawanie w p�tli 6 razy
					C_BCLR & x"FF",			-- Wyczy�� bit Z rejestru SREG
					C_LDI & "101" & x"00",	-- Ustawienie licznika na 0 w R5
					C_LDI & "111" & x"06",	-- Wpisanie 6 do R7
					C_LDI & "110" & x"02",	-- Wpisanie 2 do R6
					C_STS & "111" & x"08",	-- Zapisanie pocz�tkowej warto�ci R7 pod RAM8
					C_ADC & "111" & "110",	-- Operacja dodawania R7 += R6
					C_ADCI & "101" & x"01",	-- Inkrementacja licznika z R5
					C_CPI & "101" & x"06",	-- Sprawdzenie czy licznik z R5 == 6
					C_BRBC & "001" & x"FD", -- Je�eli SREG_Z == 0 to cofnij o 3 instrukcj�
					C_STS & "111" & x"09",	-- Zapisanie ko�cowej warto�ci R7 pod RAM9

--					Operacje dodawania i odejmowania
                    C_LDI & "100" & x"0A", 	-- za�adowanie warto�ci 10 do rejestru R4
                    C_LDI & "101" & x"0C", 	-- za�adowanie warto�ci 12 do rejestru R5
                    C_SBC & "101" & "100",	-- Operacja 12 -= 10
                    C_ADCI & "101" & x"04", -- Operacja 2 += 4
                    C_SBCI & "101" & x"02",	-- Operacja 6 -= 2
                    C_STS & "101" & x"0A",	-- Zapisanie ko�cowej warto�ci R5 pod RAM10

					-- Test C_AND
					C_LDI & "000" & x"0F",   -- �adowanie 0x0F do R0
					C_LDI & "001" & x"3C",   -- �adowanie 0x3C do R1
					C_AND & "000" & "001",   -- Wykonanie R0 AND R1, wynik w R0
					C_STS & "000" & x"0C",   -- Zapis wyniku z R0 do RAM na adres 12

					-- Test C_ANDI
					C_LDI & "000" & x"0F",   -- �adowanie 0xAA do R0
					C_ANDI & "000" & x"3C",  -- Wykonanie R0 AND 0x55, wynik w R0
					C_STS & "000" & x"0D",   -- Zapis wyniku z R0 do RAM na adres 13

					-- Test C_OR
					C_LDI & "000" & x"33",   -- �adowanie 0x33 do R0
					C_LDI & "001" & x"CC",   -- �adowanie 0xCC do R1
					C_OR & "000" & "001",   -- Wykonanie R0 OR R1, wynik w R0
					C_STS & "000" & x"0E",   -- Zapis wyniku z R0 do RAM na adres 14

					-- Test MC_ORI
					C_LDI & "000" & x"F0",   -- �adowanie 0xF0 do R0
					C_ORI & "000" & x"0F",  -- Wykonanie R0 OR 0x0F, wynik w R0
					C_STS & "000" & x"0F",   -- Zapis wyniku z R0 do RAM na adres 15

					-- Test MC_XOR
					C_LDI & "000" & x"AA",   -- �adowanie 0xAA do R0
					C_LDI & "001" & x"55",   -- �adowanie 0x55 do R1
					C_XOR & "000" & "001",  -- Wykonanie R0 XOR R1, wynik w R0
					C_STS & "000" & x"10",   -- Zapis wyniku z R0 do RAM na adres 16

					-- Test MC_XORI
					C_LDI & "000" & x"AA",   -- �adowanie 0xAA do R0
					C_XORI & "000" & x"55",  -- Wykonanie R0 XOR 0x55, wynik w R0
					C_STS & "000" & x"11",   -- Zapis wyniku z R0 do RAM na adres 17

--                  Potegowanie
					C_BCLR & x"FF",			-- Wyczy�� bit Z rejestru SREG
					C_LDI & "011" & x"00",	-- Ustawienie licznika na 0 w R3
					C_LDI & "111" & x"06",	-- Wpisanie 4 do R7 - wyk�adnik
					C_LDI & "110" & x"02",	-- Wpisanie 2 do R6 - potegowana
					C_LDI & "000" & x"01",  -- Wpisanie pocz�tkowej warto�ci do rejestru wynikowego
					C_MUL & "000" & "110",  -- Pot�gowanie wynik *= potegowana
					C_ADCI & "011" & x"01",	-- Inkrementacja licznika z R3
					C_CPI & "011" & x"04",	-- Sprawdzenie czy licznik z R3 == 4
					C_BRBC & "001" & x"FD", -- Je�eli SREG_Z == 0 to cofnij o 3 instrukcj�
					C_STS & "000" & x"13",	-- Zapisanie wyniku do R7 pod RAM19

--					Wys�anie warto�ci na OUT
                    C_LDI  & "101" & x"2F", -- Wpisanie do R5 warto�ci 2F
                    C_OUTP & "101" & x"11", -- Na adres GPIO 0x11 warto�ci z R5

--					Otrzymanie warto�ci na IN
                    C_LDI  & "101" & x"47", -- Wpisanie do R5 warto�ci 2F
                    C_INP & "101" & x"77", -- Na adres GPIO 0x11 warto�ci z R5


                    C_B & x"00", -- skok do początku programu
                    others => x"0000"
                    );

-- Pami�� Random Access Memory (RAM), 32 kom�rki o d�ugo�ci 8 bit
-- Uwaga:
-- - maksymalnie mo�e by� 255 kom�rek ze wzgl�du na 8 bitowe rejestry
type ram_array is array (0 to 31) of std_logic_vector(7 downto 0);
signal RAM: ram_array;

-- Rejestry procesora, 8 kom�rek po 8 bit�w
-- Uwaga:
-- - przechowuj� zmienne tymczasowe
type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
signal R: reg_array;

type state_t is (S_FETCH, S_EX);
signal state: state_t;

begin
    process (RESET, CLK)
    variable src1_8b, src2_8b: signed(7 downto 0);
	variable src1_u8b, src2_u8b: unsigned(7 downto 0);

    variable res_9b: signed(8 downto 0);
    variable res_8b: signed(7 downto 0);
    variable res_16b: signed(15 downto 0);
    variable res_u16b: unsigned(15 downto 0);

	variable index, pc_move, pc_curr, pc_res: integer;

	variable src1_int, src2_int, res_int: integer;

    begin
    if RESET = '1' then
        IR <= x"0000";
        PC <= x"00";
        SREG <= x"00";
    elsif rising_edge(CLK) then
        case state is
            when S_FETCH =>
                IR <= ROM(to_integer(unsigned(PC)));
                state <= S_EX;

                if std_match(IR, MC_OUTP) then
                    IOWR <= '1';
                else
                    IOWR <= '0';
                end if;
                if std_match(IR, MC_INP) then
                    IORD <= '1';
                    INPR(0) <= '1';
                    INPR(3 downto 1) <= ARG_K1;
                else
                    IORD <= '0';
                end if;

            when S_EX =>
                PC <= std_logic_vector(unsigned(PC) + 1);
                -- Obs�uga INP
                if INPR(0) = '1' then
                    R( to_integer(unsigned( INPR(3 downto 1) )) ) <= IOIN;
                    INPR(0) <= '0';
                end if;
                if std_match(IR, MC_NOP) then
                elsif std_match(IR, MC_OUTP1) then
                    GPIO <= ARG;
                elsif std_match(IR, MC_B ) then
                    PC <= ARG;
                elsif std_match(IR, MC_BZ) then
                    if Z = '1' then
                        PC <= ARG;
                    else
                        PC <= std_logic_vector(unsigned(PC) + 1);
                    end if;
                elsif std_match(IR, MC_CP) then
                	src1_8b := signed(R(to_integer(unsigned(ARG_R1))));
                	src2_8b := signed(R(to_integer(unsigned(ARG_R2))));
                	res_8b := src1_8b - src2_8b;
                	if res_8b = x"00" then
                		SREG_Z  <= '1';
                	end if;
                elsif std_match(IR, MC_CPI) then
                	src1_8b := signed(R(to_integer(unsigned(ARG_K1))));
                	src2_8b := signed(ARG_K2);
                	res_8b := src1_8b - src2_8b;
                	if res_8b = x"00" then
                		SREG_Z  <= '1';
                	end if;
                elsif std_match(IR, MC_MOV) then
                    R(to_integer(unsigned(ARG_R1))) <= R(to_integer(unsigned(ARG_R2)));
                elsif std_match(IR, MC_LDI) then
                    R(to_integer(unsigned(ARG_K1))) <= ARG_K2;
                elsif std_match(IR, MC_LDS) then
                    R(to_integer(unsigned(ARG_K1))) <= RAM(to_integer(unsigned(ARG_K2)));
                elsif std_match(IR, MC_STS) then
                    RAM(to_integer(unsigned(ARG_K2))) <= R(to_integer(unsigned(ARG_K1)));
                elsif std_match(IR, MC_ST) then
                    RAM(to_integer(unsigned( R(to_integer(unsigned(ARG_R1)))  ))) <= R(to_integer(unsigned(ARG_R2)));
                elsif std_match(IR, MC_BCLR) then
                    SREG <= SREG and (not ARG_K2);
                elsif std_match(IR, MC_BSET) then
                    SREG <= SREG or ARG_K2;
                elsif std_match(IR, MC_BRBS) then
                	index := to_integer(unsigned(ARG_K1));
                	if SREG(index) =  '1' then
                		pc_move := to_integer(signed(ARG_K2));
                		pc_curr := to_integer(unsigned(PC));
                		pc_res := pc_curr + pc_move;
						PC <= std_logic_vector(to_unsigned(pc_res, PC'length));
					end if;
                elsif std_match(IR, MC_BRBC) then
                	index := to_integer(unsigned(ARG_K1));
                	if SREG(index) =  '0' then
                		pc_move := to_integer(signed(ARG_K2));
                		pc_curr := to_integer(unsigned(PC));
                		pc_res := pc_curr + pc_move;
						PC <= std_logic_vector(to_unsigned(pc_res, PC'length));
					end if;
                elsif std_match(IR, MC_ADC) then
                    src1_8b := signed(R(to_integer(unsigned(ARG_R1))));
                    src2_8b := signed(R(to_integer(unsigned(ARG_R2))));
                    res_9b := "00000000" & SREG_C;
                    res_9b := res_9b + ('0' & src1_8b) + ('0' & src2_8b);
                    SREG_C <= res_9b(8);
                    R(to_integer(unsigned(ARG_R1))) <= std_logic_vector(res_9b(7 downto 0));
                elsif std_match(IR, MC_ADCI) then
                    src1_8b := signed(R(to_integer(unsigned(ARG_K1))));
                    src2_8b := signed(ARG_K2);
                    res_9b := "00000000" & SREG_C;
                    res_9b := res_9b + ('0' & src1_8b) + ('0' & src2_8b);
                    SREG_C <= res_9b(8);
                    R(to_integer(unsigned(ARG_K1))) <= std_logic_vector(res_9b(7 downto 0));
                elsif std_match(IR, MC_SBC) then
                    src1_8b := signed(R(to_integer(unsigned(ARG_R1))));
                    src2_8b := signed(R(to_integer(unsigned(ARG_R2))));
                    res_9b := "00000000" & SREG_C;
                    res_9b := (('0' & src1_8b) - ('0' & src2_8b)) -res_9b;
                    SREG_C <= res_9b(8);
                    R(to_integer(unsigned(ARG_R1))) <= std_logic_vector(res_9b(7 downto 0));
                elsif std_match(IR, MC_SBCI) then
                    src1_8b := signed(R(to_integer(unsigned(ARG_K1))));
                    src2_8b := signed(ARG_K2);
                    res_9b := "00000000" & SREG_C;
                    res_9b := (('0' & src1_8b) - ('0' & src2_8b)) - res_9b;
                    SREG_C <= res_9b(8);
                    R(to_integer(unsigned(ARG_K1))) <= std_logic_vector(res_9b(7 downto 0));
                elsif std_match(IR, MC_MUL) then
                    src1_u8b := unsigned(R(to_integer(unsigned(ARG_R1))));
                    src2_u8b := unsigned(R(to_integer(unsigned(ARG_R2))));
                    res_u16b := src1_u8b * src2_u8b;
                    SREG_C <= res_u16b(15);
                    R(1) <= std_logic_vector(res_u16b(15 downto 8));
                    R(0) <= std_logic_vector(res_u16b(7 downto 0));
                elsif std_match(IR, MC_MULS) then
					src1_int := to_integer(signed(R(to_integer(unsigned(ARG_R1)))));
					src2_int := to_integer(signed(R(to_integer(unsigned(ARG_R2)))));
					res_int := src1_int * src2_int;
					res_16b := to_signed(res_int, 16);
					SREG_C <= res_16b(15);
                    R(1) <= std_logic_vector(res_16b(15 downto 8));
                    R(0) <= std_logic_vector(res_16b(7 downto 0));
                elsif std_match(IR, MC_AND) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_R1) ) ) );
                	src2_8b := signed( R( to_integer( unsigned(ARG_R2) ) ) );
                	res_8b := src1_8b and src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_R1) ) ) <= std_logic_vector(res_8b);
 				elsif std_match(IR, MC_ANDI) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_K1) ) ) );
                	src2_8b := signed( ARG_K2 );
                	res_8b := src1_8b and src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_K1) ) ) <= std_logic_vector(res_8b);
                elsif std_match(IR, MC_OR) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_R1) ) ) );
                	src2_8b := signed( R( to_integer( unsigned(ARG_R2) ) ) );
                	res_8b := src1_8b or src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_R1) ) ) <= std_logic_vector(res_8b);
                elsif std_match(IR, MC_ORI) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_K1) ) ) );
                	src2_8b := signed( ARG_K2 );
                	res_8b := src1_8b or src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_K1) ) ) <= std_logic_vector(res_8b);
                elsif std_match(IR, MC_XOR) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_R1) ) ) );
                	src2_8b := signed( R( to_integer( unsigned(ARG_R2) ) ) );
                	res_8b := src1_8b xor src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_R1) ) ) <= std_logic_vector(res_8b);
                elsif std_match(IR, MC_XORI) then
                	src1_8b := signed( R( to_integer( unsigned(ARG_K1) ) ) );
                	src2_8b := signed( ARG_K2 );
                	res_8b := src1_8b xor src2_8b;
                	SREG_N <= res_8b(7);
                	SREG_V <= '0';
                	SREG_S <= SREG_N xor SREG_V;
                	if res_8b = x"00" then SREG_Z <= '1'; else SREG_Z <= '0'; end if;
                	R( to_integer( unsigned(ARG_K1) ) ) <= std_logic_vector(res_8b);
                elsif std_match(IR, MC_OUTP) then
                    IOADDR  <= ARG_K2;
                    IOOUT   <= R( to_integer( unsigned( ARG_K1 ) ) );
                elsif std_match(IR, MC_INP) then
                    IOADDR  <= ARG_K2;
                end if;
                state <= S_FETCH;
        end case;
    end if;
    end process;
end Behavioral;
