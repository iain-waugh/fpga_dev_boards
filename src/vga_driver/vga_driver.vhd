-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Project
-- Author(s)     : Iain Waugh
-- File Name     : vga_driver.vhd
--
-- A VGA output driver.
--   It has a pixel FIFO input that is 2^5 = 32 deep by default.
--
-- Use the CTA-861 Optimized Video Timing (OVT) Generator for values
--   https://www.cta.tech/Resources/Standards/CTA-861-OVT-Calculator
--
-- Build-time features:
--   Max X,Y resolution
--   Number of bits per RGB component
--
-- Run-time features:
--   Video timings
--   Picture size
--   Picture border (example use: aspect ration control)
--   Border colour
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity vga_driver is
  generic(
    G_MAX_SYNC  : natural := 100;
    G_MAX_PORCH : natural := 100;

    G_MAX_SIZE_X : natural := 1920;
    G_MAX_SIZE_Y : natural := 1200;

    G_BITS_RED   : natural := 5;
    G_BITS_GREEN : natural := 6;
    G_BITS_BLUE  : natural := 5;

    G_LOG2_PIXEL_FIFO_DEPTH : natural := 5
    );
  port(
    pixel_clk : in std_logic;

    -- Horizontal signals
    i_h_f_porch_time : in unsigned(num_bits(G_MAX_PORCH) - 1 downto 0);
    i_h_sync_time    : in unsigned(num_bits(G_MAX_SYNC) - 1 downto 0);
    i_h_b_porch_time : in unsigned(num_bits(G_MAX_PORCH) - 1 downto 0);

    -- Vertical signals
    i_v_f_porch_time : in unsigned(num_bits(G_MAX_PORCH) - 1 downto 0);
    i_v_sync_time    : in unsigned(num_bits(G_MAX_SYNC) - 1 downto 0);
    i_v_b_porch_time : in unsigned(num_bits(G_MAX_PORCH) - 1 downto 0);

    -- Un-addressable border size
    i_h_border_size : in unsigned(num_bits(G_MAX_SIZE_X) - 1 downto 0);
    i_v_border_size : in unsigned(num_bits(G_MAX_SIZE_Y) - 1 downto 0);

    -- Addressable video
    i_h_pic_size : in unsigned(num_bits(G_MAX_SIZE_X) - 1 downto 0);
    i_v_pic_size : in unsigned(num_bits(G_MAX_SIZE_Y) - 1 downto 0);

    -- What colour do you want the border to be?
    i_border_red   : in unsigned(G_BITS_RED - 1 downto 0);
    i_border_green : in unsigned(G_BITS_GREEN - 1 downto 0);
    i_border_blue  : in unsigned(G_BITS_BLUE - 1 downto 0);

    -- Pixel data and handshaking signals
    o_pixel_ready : out std_logic;  -- Can only take data when 'ready' is high
    o_p_fifo_half : out std_logic;  -- Goes high when the pixel FIFO is half empty
    i_pixel_red   : in  unsigned(G_BITS_RED - 1 downto 0);
    i_pixel_green : in  unsigned(G_BITS_GREEN - 1 downto 0);
    i_pixel_blue  : in  unsigned(G_BITS_BLUE - 1 downto 0);
    i_pixel_dval  : in  std_logic;      -- Pixel data is valid

    -- Video signals
    i_frame_sync : in  std_logic;  -- Effectively resets the frame counters
    o_frame_sync : out std_logic;  -- Pulses high at the start of a new frame

    -- Line interrupt
    i_int_at_line : in  unsigned(num_bits(G_MAX_SIZE_Y) - 1 downto 0) := (others => '0');
    o_line_int    : out std_logic;  -- Pulses high when a specified line is reached

    -- VGA Output signals
    o_vga_hs : out std_logic;
    o_vga_vs : out std_logic;

    o_vga_red   : out unsigned(G_BITS_RED - 1 downto 0);
    o_vga_green : out unsigned(G_BITS_GREEN - 1 downto 0);
    o_vga_blue  : out unsigned(G_BITS_BLUE - 1 downto 0);

    o_error : out std_logic
    );
end vga_driver;

architecture vga_driver_rtl of vga_driver is

  -- The sequence for both horizontal and vertical is:
  --    front porch  sync  back porch   left/top border    picture     right/bottom border  
  --  |-------------|----|------------|-----------------|------------|---------------------|
  --
  type t_video_state is (f_porch, sync, b_porch, b_border, pic, f_border);
  signal h_state    : t_video_state := sync;
  signal v_state_d1 : t_video_state := sync;
  signal h_state_d1 : t_video_state := sync;

  signal frame_start : std_logic := '0';

  signal h_sync_count : unsigned(num_bits(G_MAX_SYNC) - 1 downto 0) := (others => '0');
  signal v_sync_count : unsigned(num_bits(G_MAX_SYNC) - 1 downto 0) := (others => '0');

  signal h_porch_count : unsigned(num_bits(G_MAX_PORCH) - 1 downto 0) := (others => '0');
  signal v_porch_count : unsigned(num_bits(G_MAX_PORCH) - 1 downto 0) := (others => '0');

  signal h_border_count : unsigned(num_bits(G_MAX_SIZE_X) - 1 downto 0) := (others => '0');
  signal v_border_count : unsigned(num_bits(G_MAX_SIZE_Y) - 1 downto 0) := (others => '0');

  signal h_pic_count : unsigned(num_bits(G_MAX_SIZE_X) - 1 downto 0) := (others => '0');
  signal v_pic_count : unsigned(num_bits(G_MAX_SIZE_Y) - 1 downto 0) := (others => '0');

  signal pixel_fifo_reset : std_logic;
  signal pixel_in_data    : std_logic_vector(G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE - 1 downto 0);
  signal pixel_out_data   : std_logic_vector(G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE - 1 downto 0);
  signal pixel_fifo_full  : std_logic;
  signal pixel_fifo_empty : std_logic;
  signal pic_valid_d1     : std_logic;
  signal pic_valid_d2     : std_logic;
  signal blank_valid_d1   : std_logic;
  signal blank_valid_d2   : std_logic;

  signal wr_error : std_logic;
  signal rd_error : std_logic;

begin  -- vga_driver_rtl

  ----------------------------------------------------------------------
  -- Assertion checks for correct input values
  -- pragma translate_off
  process
  begin
    wait for 10 ns;
    assert i_h_sync_time /= 0 report "Sync time cannot be zero" severity error;
    assert i_v_sync_time /= 0 report "Sync time cannot be zero" severity error;

    assert i_h_b_porch_time /= 0 report "HB Porch time cannot be zero" severity error;
    assert i_h_f_porch_time /= 0 report "HF Porch time cannot be zero" severity error;
    assert i_v_b_porch_time /= 0 report "VB Porch time cannot be zero" severity error;
    assert i_v_f_porch_time /= 0 report "VF Porch time cannot be zero" severity error;

    assert i_h_border_size + i_h_pic_size >= 640
      report "Min width (including border) is 640" &
      "; you have " & integer'image(to_integer(i_h_border_size + i_h_pic_size)) severity warning;
    assert i_v_border_size + i_v_pic_size >= 480
      report "Min height (including border) is 480" &
      "; you have " & integer'image(to_integer(i_v_border_size + i_v_pic_size)) severity warning;

    assert i_h_border_size + i_h_pic_size < G_MAX_SIZE_X + 1
      report "Max width (including border) is " & integer'image(G_MAX_SIZE_X) &
      "; you have " & integer'image(to_integer(i_h_border_size + i_h_pic_size)) severity warning;
    assert i_v_border_size + i_v_pic_size < G_MAX_SIZE_Y + 1
      report "Max height (including border) is " & integer'image(G_MAX_SIZE_Y) &
      "; you have " & integer'image(to_integer(i_v_border_size + i_v_pic_size)) severity warning;
    wait;
  end process;
  -- pragma translate_on


  ----------------------------------------------------------------------
  -- Horizontal state machine
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      if i_frame_sync = '1' then
        h_sync_count <= (others => '0');
        h_state      <= sync;
        h_state_d1   <= sync;
      else
        case h_state is
          when sync =>
            if h_sync_count < i_h_sync_time then
              h_sync_count <= h_sync_count + 1;
            else
              h_porch_count <= (others => '0');
              h_state       <= b_porch;
            end if;

          when b_porch =>
            if h_porch_count < i_h_b_porch_time then
              h_porch_count <= h_porch_count + 1;
            else
              -- Only go to the blank state if it's non-zero time
              if i_h_border_size /= 0 then
                h_border_count <= (others => '0');
                h_state        <= b_border;
              else
                h_pic_count <= (others => '0');
                h_state     <= pic;
              end if;
            end if;

          when b_border =>
            if h_border_count < i_h_border_size(i_h_border_size'high - 1 downto 1) then
              -- Count up half-way
              h_border_count <= h_border_count + 1;
            else
              h_pic_count <= (others => '0');
              h_state     <= pic;
            end if;

          when pic =>
            if h_pic_count < i_h_pic_size then
              h_pic_count <= h_pic_count + 1;
            else
              -- Only go to the blank state if it's non-zero time
              if i_h_border_size /= 0 then
                h_state <= f_border;
              else
                h_porch_count <= (others => '0');
                h_state       <= f_porch;
              end if;
            end if;

          when f_border =>
            if h_border_count < i_h_border_size then
              h_border_count <= h_border_count + 1;
            else
              h_porch_count <= (others => '0');
              h_state       <= f_porch;
            end if;

          when others =>                -- 'f_porch' state
            if h_porch_count < i_h_f_porch_time then
              h_porch_count <= h_porch_count + 1;
            else
              h_sync_count <= (others => '0');
              h_state      <= sync;
            end if;

        end case;

        h_state_d1 <= h_state;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- Vertical state machine
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      if i_frame_sync = '1' then
        v_sync_count <= (others => '0');
        v_state_d1   <= sync;

        frame_start <= '0';
      else
        -- Assign a default value for 'frame_start' here
        frame_start <= '0';

        -- Only tick the vertical state machine around when the
        -- horizontal state goes from 'front porch' to 'sync'
        if h_state_d1 = f_porch and h_state = sync then
          case v_state_d1 is
            when sync =>
              if v_sync_count < i_v_sync_time then
                v_sync_count <= v_sync_count + 1;
              else
                v_porch_count <= (others => '0');
                v_state_d1    <= b_porch;
              end if;

            when b_porch =>
              if v_porch_count < i_v_b_porch_time then
                v_porch_count <= v_porch_count + 1;
              else
                -- Only go to the blank state if it's non-zero time
                if i_v_border_size /= 0 then
                  v_border_count <= (others => '0');
                  v_state_d1     <= b_border;
                else
                  v_pic_count <= (others => '0');
                  v_state_d1  <= pic;
                end if;
              end if;

            when b_border =>
              if v_border_count < i_v_border_size(i_v_border_size'high - 1 downto 1) then
                -- Count up half-way
                v_border_count <= v_border_count + 1;
              else
                v_pic_count <= (others => '0');
                v_state_d1  <= pic;
              end if;

            when pic =>
              if v_pic_count < i_v_pic_size then
                v_pic_count <= v_pic_count + 1;
              else
                -- Only go to the blank state if it's non-zero time
                if i_v_border_size /= 0 then
                  v_state_d1 <= f_border;
                else
                  v_porch_count <= (others => '0');
                  v_state_d1    <= f_porch;
                end if;
              end if;

            when f_border =>
              if v_border_count < i_v_border_size then
                v_border_count <= v_border_count + 1;
              else
                v_porch_count <= (others => '0');
                v_state_d1    <= f_porch;
              end if;

            when others =>              -- 'f_porch' state
              if v_porch_count < i_v_f_porch_time then
                v_porch_count <= v_porch_count + 1;
              else
                v_sync_count <= (others => '0');
                v_state_d1   <= sync;

                frame_start <= '1';
              end if;

          end case;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- Create an interrupt pulse when we get to the programmed line
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      o_line_int <= '0';
      if h_state_d1 = sync and h_state = b_porch then
        -- Create an interrupt if we're at the line of interest
        if v_pic_count = i_int_at_line and v_state_d1 = pic then
          o_line_int <= '1';
        end if;
      end if;
    end if;
  end process;

----------------------------------------------------------------------
-- Handle pixel input and output with a fifo
-- Note: The FIFO gets reset at the start of each frame
  pixel_fifo_reset <= i_frame_sync or frame_start;

  pixel_in_data <= std_logic_vector(i_pixel_red) &
                   std_logic_vector(i_pixel_green) &
                   std_logic_vector(i_pixel_blue);

  pic_valid_d1 <= '1' when h_state_d1 = pic and v_state_d1 = pic
                  else '0';

  blank_valid_d1 <= '1' when h_state_d1 = b_border or h_state_d1 = f_border or
                    v_state_d1 = b_border or v_state_d1 = f_border
                    else '0';

  pixel_fifo : entity work.fifo_sync
    generic map (
      G_DATA_WIDTH => G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE,
      G_LOG2_DEPTH => G_LOG2_PIXEL_FIFO_DEPTH,

      G_REGISTER_OUT => true,

      -- RAM styles:
      -- Xilinx: "block", "distributed", "registers" or "uram"
      -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
      -- Lattice: "registers", "distributed" or "block_ram"
      G_RAM_STYLE => "distributed")
    port map (
      -- Clock and Reset signals
      clk => pixel_clk,
      rst => pixel_fifo_reset,

      -- Write ports
      i_wr_data        => pixel_in_data,
      i_wr_en          => i_pixel_dval,
      o_wr_almost_full => open,
      o_wr_full        => pixel_fifo_full,
      o_wr_error       => wr_error,

      -- Read ports
      o_rd_almost_empty => o_p_fifo_half,
      o_rd_empty        => pixel_fifo_empty,
      i_rd_en           => pic_valid_d1,
      o_rd_data         => pixel_out_data,
      o_rd_error        => rd_error,

      -- Set fill level ports to be half-full/empty
      i_wr_full_limit  => unsigned('1' & to_unsigned(0, G_LOG2_PIXEL_FIFO_DEPTH - 1)),
      i_rd_empty_limit => unsigned('1' & to_unsigned(0, G_LOG2_PIXEL_FIFO_DEPTH - 1))
      );

----------------------------------------------------------------------
-- Generate strobes
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      if h_state_d1 = sync then
        o_vga_hs <= '1';
      else
        o_vga_hs <= '0';
      end if;

      if v_state_d1 = sync then
        o_vga_vs <= '1';
      else
        o_vga_vs <= '0';
      end if;
    end if;
  end process;

----------------------------------------------------------------------
-- Register the outputs and hold the RGB output low when we're not
-- within the addressable display area
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      pic_valid_d2   <= pic_valid_d1;
      blank_valid_d2 <= blank_valid_d1;
    end if;
  end process;

  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      o_frame_sync <= frame_start;

      if pic_valid_d2 = '1' then
        o_vga_red   <= unsigned(pixel_out_data(G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE - 1 downto G_BITS_GREEN + G_BITS_BLUE));
        o_vga_green <= unsigned(pixel_out_data(G_BITS_GREEN + G_BITS_BLUE - 1 downto G_BITS_BLUE));
        o_vga_blue  <= unsigned(pixel_out_data(G_BITS_BLUE - 1 downto 0));
      elsif blank_valid_d2 = '1' then
        o_vga_red   <= i_border_red;
        o_vga_green <= i_border_green;
        o_vga_blue  <= i_border_blue;
      else
        o_vga_red   <= (others => '0');
        o_vga_green <= (others => '0');
        o_vga_blue  <= (others => '0');
      end if;

    end if;
  end process;
  o_pixel_ready <= not pixel_fifo_full;
  o_error       <= wr_error or rd_error;

end vga_driver_rtl;
