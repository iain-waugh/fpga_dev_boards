-------------------------------------------------------------------------------
--
-- Copyright (c) 2015 Iain Waugh
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

  -- Numerical transforms
  function bin_to_gray(slv : std_logic_vector) return std_logic_vector;
  function gray_to_bin(slv : std_logic_vector) return std_logic_vector;
 
  -- Misc functions
  function all_ones(x  : natural) return std_logic_vector;
  function all_ones(x  : unsigned) return unsigned;
  function all_zeros(x : natural) return std_logic_vector;
  function all_zeros(x : unsigned) return unsigned;

  -- Type conversion functions
  -- The "to_01" function is used to get rid of simulation warnings with
  -- the output from uninitialised RAMs.
  function to_01(slv : std_logic_vector) return std_logic_vector;
  function to_01(sl  : std_logic) return std_logic;

  function to_integer(sl  : std_logic) return integer;
  function to_std_logic(x : boolean) return std_logic;

  -- Logic functions
  function and_reduce(slv  : std_logic_vector) return std_logic;
  function nand_reduce(slv : std_logic_vector) return std_logic;
  function or_reduce(slv   : std_logic_vector) return std_logic;
  function nor_reduce(slv  : std_logic_vector) return std_logic;
  function xor_reduce(slv  : std_logic_vector) return std_logic;
  function xnor_reduce(slv : std_logic_vector) return std_logic;

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
  -- Numerical transforms
  -------------------------------------------------------------------------
  function bin_to_gray(slv : std_logic_vector) return std_logic_vector is
    variable v_slv : std_logic_vector(slv'range) := (others => '0');
  begin
    v_slv := slv;
    v_slv := v_slv xor '0' & v_slv(v_slv'high downto v_slv'low+1);
    return v_slv;
  end bin_to_gray;

  function gray_to_bin(slv : std_logic_vector) return std_logic_vector is
    variable v_slv : std_logic_vector(slv'range) := (others => '0');
  begin
    v_slv := slv;
    for i in v_slv'high - 1 downto 0 loop
      v_slv(i) := v_slv(i+1) xor v_slv(i);
    end loop;
    return v_slv;
  end gray_to_bin;
  
  -------------------------------------------------------------------------
  -- Misc functions
  -------------------------------------------------------------------------
  function all_ones(x : natural) return std_logic_vector is
    variable slv : std_logic_vector(x - 1 downto 0) := (others => '1');
  begin
    return slv;
  end all_ones;
  function all_ones(x : unsigned) return unsigned is
    variable u : unsigned(x'range) := (others => '1');
  begin
    return u;
  end all_ones;

  function all_zeros(x : natural) return std_logic_vector is
    variable slv : std_logic_vector(x - 1 downto 0) := (others => '0');
  begin
    return slv;
  end all_zeros;
  function all_zeros(x : unsigned) return unsigned is
    variable u : unsigned(x'range) := (others => '0');
  begin
    return u;
  end all_zeros;

  -------------------------------------------------------------------------
  -- Type Conversion functions
  -------------------------------------------------------------------------
  function to_01(slv : std_logic_vector) return std_logic_vector is
    variable v_result : std_logic_vector(slv'range);
  begin
    for i in v_result'range loop
      v_result(i) := to_01(slv(i));
    end loop;
    return v_result;
  end function to_01;

  function to_01(sl : std_logic) return std_logic is
  begin
    case to_x01(sl) is
      when '1'    => return '1';
      when others => return '0';
    end case;
  end function to_01;

  function to_integer(sl : std_logic) return integer is
  begin
    if (sl = '0') then
      return 0;
    else
      return 1;
    end if;
  end to_integer;

  function to_std_logic(x : boolean) return std_logic is
  begin
    if (x = false) then
      return '0';
    else
      return '1';
    end if;
  end to_std_logic;

  -------------------------------------------------------------------------
  -- Logic functions
  -------------------------------------------------------------------------

  function and_reduce(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '1';
    for i in slv'range loop
      r := r and slv(i);
    end loop;
    return r;
  end and_reduce;

  function nand_reduce(slv : std_logic_vector) return std_logic is
  begin
    return not and_reduce(slv);
  end nand_reduce;

  function or_reduce(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '0';
    for i in slv'range loop
      r := r or slv(i);
    end loop;
    return r;
  end or_reduce;

  function nor_reduce(slv : std_logic_vector) return std_logic is
  begin
    return not or_reduce(slv);
  end nor_reduce;

  function xor_reduce(slv : std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '0';
    for i in slv'range loop
      r := r xor slv(i);
    end loop;
    return r;
  end xor_reduce;

  function xnor_reduce(slv : std_logic_vector) return std_logic is
  begin
    return not xor_reduce(slv);
  end xnor_reduce;

end util_pkg;
