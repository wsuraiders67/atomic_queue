-- _____________________________________________________________________________
--|
--|      sssssssss     nnnn nnnnnnn      cccccccccc
--|     sssssssssss    nnnnn    nnnn    cccccccccccc
--|     ssss   ssss    nnnn     nnnn    cccc    cccc    Sierra
--|     ssss           nnnn     nnnn    cccc    cccc    Nevada
--|      sssssssss     nnnn     nnnn    cccc            Corporation
--|            ssss    nnnn     nnnn    cccc    cccc
--|     ssss   ssss    nnnn     nnnn    cccc    cccc
--|     sssssssssss    nnnn     nnnn    cccccccccccc
--|      sssssssss     nnnn     nnnn     cccccccccc     Copyright 2018
--|_____________________________________________________________________________
--|
--|      //  //======  Sensor Systems and Technologies
--|     ||  ||   ||    2611 Commons Blvd
--|      \\  \\  ||    Beavercreek, OH 45431
--|       ||  || ||
--|      //  //  ||    937-431-2800
--|_____________________________________________________________________________
--|
--|       File             : cdc_sync_pulse
--|       Original Project : SS_FDK
--|       Original Author  : D. Simpson
--|       Original Date    : 02/16/2016, Craig McGillvary
--|       Last Modified    : 08/23/2018
--|_____________________________________________________________________________
--|
--|       File      : $Id: $
--|       Release   : $Name: $
--|       Updated   : $Date: $
--|_____________________________________________________________________________
--|
--|
--| DESCRIPTION:
--|
--|   This block is a general purpose clock domain crossing circuit for a pulse
--| signal.  A pulse on the input will result in one or two toggles (depending
--| on the value of G_INPUT_EVENT) of the toggle signal which crosses the clock
--| domain. Then a one shot detection is done in the destination clock.
--|
--|   It is intended to be useful for the majority of situations. It sets
--| attributes on the registers that implementation tools can use to create an
--| optimum synchronizer.  Currently, it uses Xilinx attributes to force the use
--| of flip flops, located in a single CLB. A naming convention is used to allow
--| an automated tool to generate a timing exception on the first stage
--| (f_dst_sync_meta_dat_reg). For example, such a Xilinx XDC constraint can be:
--|
--| set_max_delay -datapath_only -from [all_clocks] -to [get_pins -hierarchical
--|                                             {*f_???_sync_meta_???_reg*/D}] 5
--|
--|   The default setting of the generics configure it for the most common case,
--| a non-registered, 2-stage, rising edge pulse, synchronizer.  A reset or set
--| can be used, if necessary. If the input isn't already registered, the input
--| register generic should be used.  The input event can be changed to falling
--| edge or both rising and falling edges.  The output active level can be
--| changed to low.  Finally, more stages can be added to increase reliability
--| at the expense of latency.
--|
--|   When the trigger condition is detected, the CDC signal is toggled.  This
--| generates an active level pulse on the output for a single clock.  This
--| allows the maximum toggle rate (every clock) at the input to be supported.
--| it is up to the designer to ensure that the input to output clock frequency
--| ratio will ensure that the maximum toggle rate of the CDC signal will not
--| allow an undetected pulse by the internal synchronizer.  That is the maximum
--| toggle rate is smaller than the output clock frequency.
--|
--|   When using both edges G_INPUT_EVENT =2 and G_REGISTER_INPUT :=0 it is
--| possible to omit the i_src_clk port. In this case a toggle signals in the
--| src_clk domain can generate pulses in the destination clock domain.
--|
--|
--| INTERFACE:
--|
--|   i_src_clk   : Required clock of originating domain (source clock domain).
--|
--|   i_src_rst   : Optional active high, synchronous reset of the originating
--|                 domain.  If not needed, there is no need to connect it in
--|                 the instantiated port map.
--|
--|   i_src_set   : Optional active high, synchronous set of the originating
--|                 domain.  If not needed, there is no need to connect it in
--|                 the instantiated port map.
--|
--|   i_src_pulse  : Scalar pulse of originating clock domain.  If it is not a
--|                 registered signal (source is combinational logic), the
--|                 G_REGISTER_INPUT generic (see below) should be set to 1.
--|
--|   i_dst_clk   : Required clock of destination domain.
--|
--|   i_dst_rst   : Optional active high, synchronous reset of the destination
--|                 domain.  If not needed, there is no need to connect it.
--|
--|   i_dst_set   : Optional active high, synchronous set of the destination
--|                 domain.  If not needed, there is no need to connect it.
--|
--|   o_dst_pulse  : Synchronized scalar pulse in destination domain.
--|
--|
--| CONFIGURATION/GENERICS:
--|
--|   G_REGISTER_INPUT : When set to 1 adds one register stage to the input data
--|                   (i_src_data).  Set to 0 (DEFAULT) when the incoming signal
--|                   is already registered.
--|
--|   G_SYNC_STAGES : Defines the number of sync stages generated.  It can range
--|                   from 2 (DEFAULT) to 6.
--|
--|   G_INPUT_EVENT : Trigger for the pulse.  The default (0) is a rising edge.
--|                   Set to 1 for a falling edge trigger.  Set to 2 to generate
--|                   pulses on each edge.
--|
--|   G_OUTPUT_LEVEL : The default (1) active level of the output is high.  Set
--|                    to 0 for an active low output.
--|
--|
--| History:
--|
--|   09/29/2015: DLS - Changed a comment and the package name to cdc_pkg.
--|   06/06/2018: DLS - Changed the interface to be more user friendly.  That
--|                     is accomplished with fewer generics and default values
--|                     for optional inputs.
--|   04/15/2020: CDM - Add some correct instantiation templates in commments
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--|
--|  u_sync : entity work.cdc_sync_pulse
--|    port map( i_src_clk  => w_src_clock, i_src_pulse => w_src_sl, o_dst_pulse => w_dst_sl, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst : entity work.cdc_sync_pulse
--|    port map( i_src_clk  => w_src_clock, i_src_pulse => w_src_sl, o_dst_pulse => w_dst_sl, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_set : entity work.cdc_sync_pulse
--|    port map( i_src_clk  => w_src_clock, i_src_pulse => w_src_sl, o_dst_pulse => w_dst_sl, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|  u_sync_reg : entity work.cdc_sync_pulse
--|    generic map(  G_REGISTER_INPUT => 1 )
--|    port map( i_src_clk  => w_src_clock, i_src_pulse => w_src_sl, o_dst_pulse => w_dst_sl, i_dst_clk => w_dst_clock);
--|
--|  u_sync_toggle_no_src_clk : entity work.cdc_sync_pulse
--|    generic map(  G_OUTPUT_LEVEL => 1 )
--|    port map( i_src_pulse => w_src_toggle_sl, o_dst_pulse => w_dst_pulse_sl, i_dst_clk => w_dst_clock);
--|
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_sync_pulse is
  generic (
    -- 1=Register input
    G_REGISTER_INPUT    : integer range 0 to  1 := 0;
    G_SYNC_STAGES       : integer range 2 to  6 := 2;
    G_INPUT_EVENT       : integer range 0 to  2 := 0;
    G_OUTPUT_LEVEL      : integer range 0 to  1 := 1
  );

  port (
    ------------------- SOURCE CLOCK DOMAIN ----------------------
    i_src_clk           : in  std_logic := '0';
    i_src_rst           : in  std_logic := '0';              -- Sync to i_src_clk
    i_src_set           : in  std_logic := '0';              -- Sync to i_src_clk
    i_src_pulse         : in  std_logic;

    ----------------- DESTINATION CLOCK DOMAIN -------------------
    i_dst_clk           : in  std_logic;
    i_dst_rst           : in  std_logic := '0';              -- Sync to i_dst_clk
    i_dst_set           : in  std_logic := '0';              -- Sync to i_dst_clk
    o_dst_pulse         : out std_logic
  );

end cdc_sync_pulse;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_sync_pulse is

  --************************************************************************
  --
  --   When we are using rising edge or falling edge events then we want to initialize the toggle signal to '0',
  -- however when we detecting on both rising and falling edge we can't initialize the toggle signal because
  -- then there would be multiple drivers.
  --
  --************************************************************************
  function fn_init_toggle( i_input_event : natural range 0 to 2) return std_logic is
    begin
      if i_input_event = 2 then
        return('-');
      else
        return('0');
      end if;
  end function fn_init_toggle;

 ---------------------------
  -- Signal Declarations
  ---------------------------
  -- src_clk domain
  signal f_inreg                : std_logic;
  signal ff_inreg               : std_logic;
  signal f_src2dst_toggle       : std_logic := fn_init_toggle(G_INPUT_EVENT);  -- This is the CDC signal

  -- dst_clk domain
  -- The first stage is given a unique name to be used for timing exception
  -- generation (f_???_sync_meta_???.  The remaining stages are in the array.
  -- Attributes below prevent a shift register implementation of the array.
  signal f_dst_sync_meta_dat   : std_logic;
  signal f_dst_sync_stages_dat : std_logic_vector(G_SYNC_STAGES-1 downto 1);
  signal f_prev_value          : std_logic;

  ---------------------------
  -- Attribute Declarations
  ---------------------------

  attribute ASYNC_REG          : string;

  attribute ASYNC_REG     of  f_dst_sync_meta_dat    : signal is "TRUE";
  attribute ASYNC_REG     of  f_dst_sync_stages_dat  : signal is "TRUE";


begin


  ------------------------------------------------------------------------------
  -- Register the input if the generic is set.
  ------------------------------------------------------------------------------
  --
  --                         | |
  --                         |B|                      _______(sync
  --                         |O|               _____ /       stages)
  --   f_src2dst_toggle------|U|--------------| D Q |      _______
  --                         |N|              |     ||    |       |
  --                         |D| i_dst_clk----|>    |||---|ONESHOT|--> o_dst_pulse
  --                         |R|              |_____|||   |_______|
  --                         |Y|               |_____||
  --                         | |                |_____|
  ------------------------------------------------------------------------------

  NO_REG_IN : if (G_REGISTER_INPUT = 0) generate
  begin

    f_inreg <= i_src_pulse;

  end generate NO_REG_IN;


  RST_REG_IN : if (G_REGISTER_INPUT = 1) generate
  begin

    input_reg : process(i_src_clk)
    begin
      if (i_src_clk'event and i_src_clk ='1') then

        if    i_src_rst = '1' then
          f_inreg   <= '0';
        elsif i_src_set = '1' then
          f_inreg   <= '1';
        else
          f_inreg <= i_src_pulse;
        end if;

      end if;
    end process input_reg;

  end generate RST_REG_IN;

  delay_reg : process(i_src_clk)
  begin
    if (i_src_clk'event and i_src_clk ='1') then

      if    i_src_rst = '1' then
        ff_inreg   <= '0';
      elsif i_src_set = '1' then
        ff_inreg   <= '1';
      else
        ff_inreg <= f_inreg;
      end if;

    end if;
  end process delay_reg;

  --************************************************************************
  --
  -- When G_INPUT_EVENT = 0 then the c_src2dst_toggle changes on every rising edge of f_in_reg
  -- When G_INPUT_EVENT = 1 then the c_src2dst_toggle changes on every falling edge of f_in_reg
  -- When G_INPUT_EVENT = 2 then f_in_reg is assigned to c_src2dst_toggle which toggles on both edges
  --
  --************************************************************************
  TOGGLE_REG : if (G_INPUT_EVENT = 0 or G_INPUT_EVENT = 1) generate
    process( i_src_clk) is
    begin
      if (i_src_clk'event and i_src_clk ='1') then
        if G_INPUT_EVENT = 0 then
          if f_inreg = '1' and ff_inreg = '0' then
            if f_src2dst_toggle = '0' then
              f_src2dst_toggle <= '1';
            else
              f_src2dst_toggle <= '0';
            end if;
          end if;
        elsif G_INPUT_EVENT = 1 then
          if f_inreg = '0' and ff_inreg = '1' then
            if f_src2dst_toggle = '0' then
              f_src2dst_toggle <= '1';
            else
              f_src2dst_toggle <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;
  end generate TOGGLE_REG;

  TOGGLE_REG_N : if (G_INPUT_EVENT = 2) generate
    f_src2dst_toggle <=f_inreg;
  end generate TOGGLE_REG_N;
-------------------------------CLOCK DOMAIN BOUNDARY----------------------------

  ---------------------------
  -- Synchronizer
  ---------------------------

  sync_regs : process(i_dst_clk)
  begin
    if (i_dst_clk'event and i_dst_clk ='1') then

      if    i_dst_rst = '1' then
        f_dst_sync_meta_dat   <= '0';
        f_dst_sync_stages_dat <= (others => '0');
        f_prev_value <= '0';
      elsif i_dst_set = '1' then
        f_dst_sync_meta_dat   <= '1';
        f_dst_sync_stages_dat <= (others => '1');
        f_prev_value <= '1';
      else
        f_dst_sync_meta_dat       <= f_src2dst_toggle;
        f_dst_sync_stages_dat(1)  <= f_dst_sync_meta_dat;
        if (G_SYNC_STAGES > 2) then
          f_dst_sync_stages_dat(G_SYNC_STAGES-1 downto 2) <=
                              f_dst_sync_stages_dat(G_SYNC_STAGES-2 downto 1);
        end if;
        f_prev_value <= f_dst_sync_stages_dat(G_SYNC_STAGES-1);
      end if;

    end if;
  end process sync_regs;

  --************************************************************************
  --
  -- Do one-shot detection on toggle signal to generate pulse in destination clock domain
  --
  --************************************************************************
  process( i_dst_clk) is
  begin
    if (i_dst_clk'event and i_dst_clk = '1') then
      if (f_dst_sync_stages_dat(G_SYNC_STAGES-1) xor f_prev_value)= '1' then
        o_dst_pulse <= '1';
      else
        o_dst_pulse <= '0';
      end if;
    end if;
  end process;

end rtl;
