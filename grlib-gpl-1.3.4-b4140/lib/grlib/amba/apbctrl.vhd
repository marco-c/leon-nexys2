------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2013, Aeroflex Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
-----------------------------------------------------------------------------   
-- Entity:      apbctrl
-- File:        apbctrl.vhd
-- Author:      Jiri Gaisler - Gaisler Research
-- Description: AMBA AHB/APB bridge with plug&play support
------------------------------------------------------------------------------ 

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.config_types.all;
use grlib.config.all;
use grlib.amba.all;
use grlib.stdlib.all;
-- pragma translate_off
use grlib.devices.all;
use std.textio.all;
-- pragma translate_on

entity apbctrl is
  generic (
    hindex      : integer := 0;
    haddr       : integer := 0;
    hmask       : integer := 16#fff#;
    nslaves     : integer range 1 to NAPBSLV := NAPBSLV;
    debug       : integer range 0 to 2 := 2;
    icheck      : integer range 0 to 1 := 1;
    enbusmon    : integer range 0 to 1 := 0;
    asserterr   : integer range 0 to 1 := 0;
    assertwarn  : integer range 0 to 1 := 0;
    pslvdisable : integer := 0;
    mcheck      : integer range 0 to 1 := 1;
    ccheck      : integer range 0 to 1 := 1
    );
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahbi    : in  ahb_slv_in_type;
    ahbo    : out ahb_slv_out_type;
    apbi    : out apb_slv_in_type;
    apbo    : in  apb_slv_out_vector
  );
end;

architecture rtl of apbctrl is

constant apbmax : integer := 19;

constant VERSION   : amba_version_type := 0;

constant hconfig : ahb_config_type := (
  0 => ahb_device_reg ( 1, 6, 0, VERSION, 0),
  4 => ahb_membar(haddr, '0', '0', hmask),
  others => zero32);

constant IOAREA : std_logic_vector(11 downto 0) := 
        conv_std_logic_vector(haddr, 12);
constant IOMSK  : std_logic_vector(11 downto 0) := 
        conv_std_logic_vector(hmask, 12);

type reg_type is record
  haddr   : std_logic_vector(apbmax downto 0);   -- address bus
  hwrite  : std_logic;                       -- read/write
  hready  : std_logic;                       -- ready
  penable : std_logic;
  psel    : std_logic;
  prdata  : std_logic_vector(31 downto 0);   -- read data
  pwdata  : std_logic_vector(31 downto 0);   -- write data
  state   : std_logic_vector(1 downto 0);   -- state
  cfgsel  : std_ulogic;
end record;

constant RESET_ALL : boolean := GRLIB_CONFIG_ARRAY(grlib_sync_reset_enable_all) = 1;
constant RES : reg_type :=
  (haddr => (others => '0'), hwrite => '0', hready => '1', penable => '0',
   psel => '0', prdata => (others => '0'), pwdata => (others => '0'),
   state => (others => '0'), cfgsel => '0');

signal r, rin : reg_type;
--pragma translate_off
signal lapbi  : apb_slv_in_type;
--pragma translate_on

begin
  comb : process(ahbi, apbo, r, rst)
  variable v : reg_type;
  variable psel   : std_logic_vector(0 to 31);   
  variable pwdata : std_logic_vector(31 downto 0);
  variable apbaddr : std_logic_vector(apbmax downto 0);
  variable apbaddr2 : std_logic_vector(31 downto 0);
  variable pirq : std_logic_vector(NAHBIRQ-1 downto 0);
  variable nslave : integer range 0 to nslaves-1;
  variable bnslave : std_logic_vector(3 downto 0);
  begin

    v := r; v.psel := '0'; v.penable := '0'; psel := (others => '0');
    pirq := (others => '0'); 

    -- detect start of cycle
    if (ahbi.hready = '1') then
      if ((ahbi.htrans = HTRANS_NONSEQ) or (ahbi.htrans = HTRANS_SEQ)) and
          (ahbi.hsel(hindex) = '1')
      then
        v.hready := '0'; v.hwrite := ahbi.hwrite; 
        v.haddr(apbmax downto 0) := ahbi.haddr(apbmax downto 0); 
        v.state := "01"; v.psel := not ahbi.hwrite;
      end if;
    end if;

    case r.state is
    when "00" => null;          -- idle
    when "01" =>
      if r.hwrite = '0' then v.penable := '1'; 
      else v.pwdata := ahbreadword(ahbi.hwdata, r.haddr(4 downto 2)); end if;
      v.psel := '1'; v.state := "10";
    when others =>
      if r.penable = '0' then v.psel := '1'; v.penable := '1'; end if;
      v.state := "00"; v.hready := '1';
    end case;

    psel := (others => '0');

    for i in 0 to nslaves-1 loop
      if ((apbo(i).pconfig(1)(1 downto 0) = "01") and
        ((apbo(i).pconfig(1)(31 downto 20) and apbo(i).pconfig(1)(15 downto 4)) = 
        (r.haddr(19 downto  8) and apbo(i).pconfig(1)(15 downto 4))))
      then psel(i) := '1'; end if;
    end loop;

    bnslave(0) := psel(1) or psel(3) or psel(5) or psel(7) or
                  psel(9) or psel(11) or psel(13) or psel(15);
    bnslave(1) := psel(2) or psel(3) or psel(6) or psel(7) or
                  psel(10) or psel(11) or psel(14) or psel(15);
    bnslave(2) := psel(4) or psel(5) or psel(6) or psel(7) or
                  psel(12) or psel(13) or psel(14) or psel(15);
    bnslave(3) := psel(8) or psel(9) or psel(10) or psel(11) or
                  psel(12) or psel(13) or psel(14) or psel(15);
    nslave := conv_integer(bnslave);

    if (r.haddr(19 downto  12) = "11111111") then 
     v.cfgsel := '1'; psel := (others => '0'); v.penable := '0';
    else v.cfgsel := '0'; end if;

    v.prdata := apbo(nslave).prdata;

    if r.cfgsel = '1' then
      v.prdata := apbo(conv_integer(r.haddr(6 downto 3))).pconfig(conv_integer(r.haddr(2 downto 2)));
      if nslaves <= conv_integer(r.haddr(6 downto 3)) then
        v.prdata := (others => '0');
      end if;
    end if;

    for i in 0 to nslaves-1 loop pirq := pirq or apbo(i).pirq; end loop;

    -- AHB respons
    ahbo.hready <= r.hready;
    ahbo.hrdata <= ahbdrivedata(r.prdata);
    ahbo.hirq   <= pirq;

    if (not RESET_ALL) and (rst = '0') then
      v.penable := RES.penable; v.hready := RES.hready;
      v.psel := RES.psel; v.state := RES.state;
      v.hwrite := RES.hwrite;
-- pragma translate_off
      v.haddr := RES.haddr;
-- pragma translate_on
    end if;

    rin <= v;

    -- drive APB bus
    apbaddr2 := (others => '0');
    apbaddr2(apbmax downto 0) := r.haddr(apbmax downto 0);
    apbi.paddr   <= apbaddr2;
    apbi.pwdata  <= r.pwdata;
    apbi.pwrite  <= r.hwrite;
    apbi.penable <= r.penable;
    apbi.pirq    <= ahbi.hirq;
    apbi.testen  <= ahbi.testen;
    apbi.testoen <= ahbi.testoen;
    apbi.scanen <= ahbi.scanen;
    apbi.testrst <= ahbi.testrst;
    apbi.testin  <= ahbi.testin;

    apbi.psel <= (others => '0');
    for i in 0 to nslaves-1 loop apbi.psel(i) <= psel(i) and r.psel; end loop;
    
--pragma translate_off
    lapbi.paddr   <= apbaddr2;
    lapbi.pwdata  <= r.pwdata;
    lapbi.pwrite  <= r.hwrite;
    lapbi.penable <= r.penable;
    lapbi.pirq    <= ahbi.hirq;

    for i in 0 to nslaves-1 loop lapbi.psel(i) <= psel(i) and r.psel; end loop;
--pragma translate_on

  end process;

  ahbo.hindex <= hindex;
  ahbo.hconfig <= hconfig;
  ahbo.hsplit <= (others => '0');
  ahbo.hresp  <= HRESP_OKAY;

  reg : process(clk)
  begin
    if rising_edge(clk) then
      r <= rin;
      if RESET_ALL and rst = '0' then
        r <= RES;
      end if;
    end if;
  end process;

-- pragma translate_off

  mon0 : if enbusmon /= 0 generate
    mon :  apbmon 
      generic map(
        asserterr   => asserterr,
        assertwarn  => assertwarn,
        pslvdisable => pslvdisable,
        napb        => nslaves)
      port map(
        rst         => rst,
        clk         => clk,
        apbi        => lapbi,
        apbo        => apbo,
        err         => open);
  end generate;

  diag : process
  type apb_memarea_type is record
     start : std_logic_vector(31 downto 20);
     stop  : std_logic_vector(31 downto 20);
  end record;
  type memmap_type is array (0 to nslaves-1) of apb_memarea_type;
  variable k : integer;
  variable mask : std_logic_vector(11 downto 0);
  variable device : std_logic_vector(11 downto 0);
  variable devicei : integer;
  variable vendor : std_logic_vector( 7 downto 0);
  variable vendori : integer;
  variable iosize : integer;
  variable iounit : string(1 to 5) := "byte ";
  variable memstart : std_logic_vector(11 downto 0) := IOAREA and IOMSK;
  variable L1 : line := new string'("");
  variable memmap : memmap_type;
  begin
    wait for 3 ns;
    if debug > 0 then
      print("apbctrl: APB Bridge at " & tost(memstart) & "00000 rev 1");
    end if;
    for i in 0 to nslaves-1 loop
      vendor := apbo(i).pconfig(0)(31 downto 24); 
      vendori := conv_integer(vendor);
      if vendori /= 0 then
        if debug > 1 then
          device := apbo(i).pconfig(0)(23 downto 12); 
          devicei := conv_integer(device);
          std.textio.write(L1, "apbctrl: slv" & tost(i) & ": " &                
           iptable(vendori).vendordesc  & iptable(vendori).device_table(devicei));
          std.textio.writeline(OUTPUT, L1);
          mask := apbo(i).pconfig(1)(15 downto 4);
          k := 0;
          while (k<15) and (mask(k) = '0') loop k := k+1; end loop;      
          iosize := 256 * 2**k; iounit := "byte ";
          if (iosize > 1023) then iosize := iosize/1024; iounit := "kbyte"; end if;
          print("apbctrl:       I/O ports at " & 
            tost(memstart & (apbo(i).pconfig(1)(31 downto 20) and
                             apbo(i).pconfig(1)(15 downto 4))) &
                "00, size " & tost(iosize) & " " & iounit);
          if mcheck /= 0 then
            memmap(i).start := (apbo(i).pconfig(1)(31 downto 20) and
                                apbo(i).pconfig(1)(15 downto 4));
            memmap(i).stop := memmap(i).start + 2**k;
          end if;
        end if;
        assert (apbo(i).pindex = i) or (icheck = 0)
        report "APB slave index error on slave " & tost(i) &
          ". Detected index value " & tost(apbo(i).pindex) severity failure;
        if mcheck /= 0 then
          for j in 0 to i loop
            if memmap(i).start /= memmap(i).stop then
              assert ((memmap(i).start >= memmap(j).stop) or
                      (memmap(i).stop <= memmap(j).start) or (i = j))
                report "APB slave " & tost(i) & " memory area" &  
                " intersects with APB slave " & tost(j) & " memory area."
                severity failure;
            end if;
          end loop;
        end if;
      else
        for j in 0 to NAPBCFG-1 loop
          assert (apbo(i).pconfig(j) = zx or ccheck = 0)
            report "APB slave " & tost(i) & " appears to be disabled, " &
            "but the config record is not driven to zero"
            severity warning;
        end loop;
      end if;
    end loop;
    if nslaves < NAPBSLV then
      for i in nslaves to NAPBSLV-1 loop
        for j in 0 to NAPBCFG-1 loop
          assert (apbo(i).pconfig(j) = zx or ccheck = 0)
            report "APB slave " & tost(i) & " is outside the range of decoded " &
            "slave indexes but the config record is not driven to zero"
            severity warning;
        end loop;  -- j
      end loop;  -- i
    end if;
    wait;
  end process;
-- pragma translate_on

end;

