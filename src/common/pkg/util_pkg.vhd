-------------------------------------------------------------------------------
--
-- Copyright (c) 2015 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Common Code
-- Author(s)     : Iain Waugh
-- File Name     : util_pkg.vhd
--
-- Utilities package for common functions
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package util_pkg is

  -- Maths functions
  function clog2(x : natural) return natural;

  function maximum(l, r : integer) return integer;
  function minimum(l, r : integer) return integer;

  -- Bit ordering functions
  function swap_bit(slv  : std_logic_vector) return std_logic_vector;
  function swap_byte(slv : std_logic_vector) return std_logic_vector;

  -- Misc functions
  function ones(x  : natural)  return std_logic_vector;
  function ones(x  : unsigned) return unsigned;
  function zeros(x : natural)  return std_logic_vector;
  function zeros(x : unsigned) return unsigned;

  -- Type conversion functions
  function to_integer(sl : std_logic) return integer;

  -- Logic functions
  function and_all(slv  : std_logic_vector) return std_logic;
  function nand_all(slv : std_logic_vector) return std_logic;
  function or_all(slv   : std_logic_vector) return std_logic;
  function nor_all(slv  : std_logic_vector) return std_logic;
  function xor_all(slv  : std_logic_vector) return std_logic;
  function xnor_all(slv : std_logic_vector) return std_logic;

end util_pkg;

package body util_pkg is

  -------------------------------------------------------------------------
  -- Maths functions
  -------------------------------------------------------------------------

  -- Ceiling LOG2 = number of bits required to represent the natural input
  function clog2 (x : natural) return natural is
    variable temp : natural := x;
    variable n    : natural := 1;
  begin
    while temp > 1 loop
      temp := temp / 2;
      n    := n+1;
    end loop;
    return n;
  end clog2;

  function maximum(l, r : integer) return integer is
  begin
    if l > r then return l; else return r; end if;
  end maximum;

  function minimum(l, r : integer) return integer is
  begin
    if l < r then return l; else return r; end if;
  end minimum;

  -------------------------------------------------------------------------
  -- Bit Ordering functions
  -------------------------------------------------------------------------
  function swap_bit(slv : std_logic_vector) return std_logic_vector is
  begin
    assert (false) report "Function not written yet" severity failure;
    return slv;
  end swap_bit;

  function swap_byte(slv : std_logic_vector) return std_logic_vector is
  begin
    assert (false) report "Function not written yet" severity failure;
    return slv;
  end swap_byte;

  -------------------------------------------------------------------------
  -- Misc functions
  -------------------------------------------------------------------------
  function ones(x : natural) return std_logic_vector is
    variable slv : std_logic_vector(x - 1 downto 0) := (others => '1');
  begin
    return slv;
  end ones;
  function ones(x : unsigned) return unsigned is
    variable u : unsigned(x'range) := (others => '1');
  begin
    return u;
  end ones;

  function zeros(x : natural) return std_logic_vector is
    variable slv : std_logic_vector(x - 1 downto 0) := (others => '0');
  begin
    return slv;
  end zeros;
  function zeros(x : unsigned) return unsigned is
    variable u : unsigned(x'range) := (others => '0');
  begin
    return u;
  end zeros;

  -------------------------------------------------------------------------
  -- Type Conversion functions
  -------------------------------------------------------------------------
  function to_integer(sl : std_logic) return integer is
  begin
    if (sl = '0') then
      return 0;
    else
      return 1;
    end if;
  end to_integer;


  -------------------------------------------------------------------------
  -- Logic functions
  -------------------------------------------------------------------------

  function and_all(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '1';
    for i in slv'range loop
      r := r and slv(i);
    end loop;
    return r;
  end and_all;

  function nand_all(slv : std_logic_vector) return std_logic is
  begin
    return not and_all(slv);
  end nand_all;

  function or_all(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '0';
    for i in slv'range loop
      r := r or slv(i);
    end loop;
    return r;
  end or_all;

  function nor_all(slv : std_logic_vector) return std_logic is
  begin
    return not or_all(slv);
  end nor_all;

  function xor_all(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '0';
    for i in slv'range loop
      r := r xor slv(i);
    end loop;
    return r;
  end xor_all;

  function xnor_all(slv : std_logic_vector) return std_logic is
  begin
    return not xor_all(slv);
  end xnor_all;

end util_pkg;
