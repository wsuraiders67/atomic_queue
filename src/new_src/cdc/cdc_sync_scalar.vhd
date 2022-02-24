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
--|       File             : cdc_sync_scalar
--|       Original Project : MISD 
--|       Original Author  : D. Simpson
--|       Original Date    : 09/09/2015
--|       Last Modified    : 06/06/2018
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
--|   This block is a general purpose clock domain crossing circuit for a scalar
--| signal.  It is intended to be useful for the majority of situations. It sets
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
--| a non-registered, 2-stage synchronizer.  A reset or set can be used, if necessary.
--| If the input is not already registered, the input register generic should be
--| used.  Finally, more stages can be added to increase reliability at the expense
--| of latency.
--|
--|   Special cases exists where a synchronizer is not required to cross the
--| clock domain boundary.  Such a case is when the signal is considered to be a
--| "pseudo-constant."  Here the destination clock domain has special provisions
--| that prevent the pseudo-constant signal from being sampled while it changes.
--| In order to distinguish between such a case and a signal which inadvertently
--| crosses a clock domain, a different block exists which infers a single flip
--| flop with an instance name that can be used to generate a timing exception.
--| Refer to the "Also See" section below. 
--|
--|
--| INTERFACE:
--|
--|   i_src_clk   : Clock of originating domain (source domain).  It is only
--|                 used if the input is registered (G_REGISTER_INPUT=1).  If
--|                 G_REGISTER_INPUT=0, there is no need to connect it.
--|
--|   i_src_rst   : Active high, synchronous reset of originating clock domain.
--|                 It is optional and only used if the input is registered
--|                 (G_REGISTER_INPUT=1).  If not needed, there is no need to
--|                 connect it in the instantiated port map.
--|
--|   i_src_set   : Active high, synchronous set of originating clock domain.
--|                 It is optional and only used if the input is registered
--|                 (G_REGISTER_INPUT=1).  If not needed, there is no need to
--|                 connect it in the instantiated port map.
--|
--|   i_src_data  : Scalar signal of originating clock domain.  If it is not a
--|                 registered signal (source is combinational logic), the
--|                 G_REGISTER_INPUT generic (see below) may be set to 1.
--|
--|   i_dst_clk   : Clock of destination domain.  This must be connected.
--|
--|   i_dst_rst   : Active high, synchronous reset of destination domain.  This
--|                 is optional.  If not needed, there is no need to connect it.
--|
--|   i_dst_set   : Active high, synchronous set of destination domain.  This
--|                 is optional.  If not needed, there is no need to connect it.
--|
--|   o_dst_data  : Synchronized scalar signal in destination domain.
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
--|
--| Also see:
--|
--|   cdc_sync_vector: Used to synchronize a vector (or bus), which is not the
--|                    output of a counter.  One value can change to any other
--|                    value in a single source clock.
--|
--|   cdc_sync_count:  Used to synchronize a binary count. It converts the count
--|                    to gray code, synchronizes and converts back to binary.
--|                    In this way, the output is always valid.  Note, if the 
--|                    input clock is faster than the output and the count can 
--|                    change at a rate faster than the output clock, some
--|                    counts may be skipped on the output.  The assumption made
--|                    is that the input count can only change by one, up or
--|                    down, each source clock.
--|
--|   cdc_pseudo_const: Used to cross clock domains where a synchronizer is not
--|                    required.  It infers a register with an instance name
--|                    (f_pseudo_const_reg*) that can be used by a tool to auto-
--|                    generate a timing exception.  It communicates that the
--|                    crossing is intentional.
--|
--|   cdc_reset_bridge: Used to synchronize an asynchronous reset. 
--|
--|   Asynchronous FIFO: A FIFO from a vendor library is an easy and low risk
--|                    method to pass data between clock domains.  It also has
--|                    the highest bandwidth of the options here.  It will
--|                    likely have the largest area impact, however.
--|
--| History:
--|
--|   09/29/2015: DLS - Changed a comment and the package name to cdc_pkg.
--|   06/06/2018: DLS - Changed the interface to be more user friendly.  That
--|                     is accomplished with fewer generics and default values
--|                     for optional inputs.
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--| 
--|  u_sync : entity work.cdc_sync_scalar
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst : entity work.cdc_sync_scalar
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_set : entity work.cdc_sync_scalar
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|  u_sync_reg : entity work.cdc_sync_scalar
--|    generic map(  G_REGISTER_INPUT => 1 )              
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_src_clk => w_src_clock);
--|
--|  u_sync_rst_reg : entity work.cdc_sync_scalar
--|    generic map(  G_REGISTER_INPUT => 1 )              
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_src_clk => w_src_clock, i_src_rst => w_src_reset, i_dst_rst => w_dst_reset);
--|
--|  u_sync_3stage_rst : entity work.cdc_sync_scalar
--|    generic map(  G_SYNC_STAGES => 3 )              
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_4stage_set_reg : entity work.cdc_sync_scalar
--|    generic map(  G_REGISTER_INPUT => 1, G_SYNC_STAGES => 4 )              
--|    port map( i_src_data => w_src_sl, o_dst_data => w_dst_sl, i_dst_clk => w_dst_clock, i_src_clk => w_src_clock, i_src_set => w_src_set, i_dst_set => w_dst_set);
--|
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;


-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_sync_scalar is
  generic (
    -- 1=Register input
    G_REGISTER_INPUT    : integer range 0 to    1 := 0;
    G_SYNC_STAGES       : integer range 2 to    6 := 2                 
  );

  port (
    ------------------- SOURCE CLOCK DOMAIN ----------------------
    i_src_clk           : in  std_logic := '0';
    i_src_rst           : in  std_logic := '0';              -- Sync to i_src_clk
    i_src_set           : in  std_logic := '0';              -- Sync to i_src_clk
    i_src_data          : in  std_logic;

    ----------------- DESTINATION CLOCK DOMAIN -------------------
    i_dst_clk           : in  std_logic;
    i_dst_rst           : in  std_logic := '0';              -- Sync to i_dst_clk
    i_dst_set           : in  std_logic := '0';              -- Sync to i_dst_clk
    o_dst_data          : out std_logic
  );

end cdc_sync_scalar;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_sync_scalar is

  ---------------------------
  -- Signal Declarations
  ---------------------------
  -- src_clk domain
  signal f_src2dst_data        : std_logic;

  -- dst_clk domain
  -- The first stage is given a unique name to be used for timing exception
  -- generation (f_???_sync_meta_???.  The remaining stages are in the array.
  -- Attributes below prevent a shift register implementation of the array.
  signal f_dst_sync_meta_dat   : std_logic;
  signal f_dst_sync_stages_dat : std_logic_vector(G_SYNC_STAGES-1 downto 1);


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
  --                                    | |
  --                                    |B|                      _______(sync
  --                 _____f_src2dst_data|O|               _____ /       stages)
  -- i_src_data ----| D Q |-------------|U|--------------| D Q |
  --                |     |             |N|              |     ||
  --  i_src_clk ----|>    |             |D| i_dst_clk----|>    |||--- i_dst_data
  --                |_____|             |R|              |_____|||
  -- (optional)_____/                   |Y|               |_____||
  --                                    | |                |_____|
  ------------------------------------------------------------------------------

  NO_REG_IN : if (G_REGISTER_INPUT = 0) generate
  begin

    f_src2dst_data <= i_src_data;

  end generate NO_REG_IN;


  RST_REG_IN : if (G_REGISTER_INPUT = 1) generate
  begin

    input_reg : process(i_src_clk)
    begin
      if (i_src_clk'event and i_src_clk ='1') then

        if    i_src_rst = '1' then
          f_src2dst_data   <= '0';
        elsif i_src_set = '1' then
          f_src2dst_data   <= '1';
        else
          f_src2dst_data <= i_src_data;
        end if;

      end if;
    end process input_reg;

  end generate RST_REG_IN;


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
      elsif i_dst_set = '1' then
        f_dst_sync_meta_dat   <= '1';
        f_dst_sync_stages_dat <= (others => '1');
      else
        f_dst_sync_meta_dat       <= f_src2dst_data;
        f_dst_sync_stages_dat(1)  <= f_dst_sync_meta_dat;
        if (G_SYNC_STAGES > 2) then
          f_dst_sync_stages_dat(G_SYNC_STAGES-1 downto 2) <= 
                              f_dst_sync_stages_dat(G_SYNC_STAGES-2 downto 1);
        end if;
      end if;

    end if;
  end process sync_regs;

  o_dst_data <= f_dst_sync_stages_dat(G_SYNC_STAGES-1);

end rtl;
