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
--|       File             : cdc_reset_bridge
--|       Original Project : MISD 
--|       Original Author  : D. Simpson
--|       Original Date    : 03/13/2017
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
--|   This block is a special purpose clock domain crossing circuit for an
--| asynchronous reset or set signal.  Although the negating (trailing) edge is
--| synchronous to the clock, the asserting (leading) edge is asynchronous.
--| This is useful in applications that require an asyncronous reset.  It sets
--| attributes on the registers that implementation tools can use to create an
--| optimum synchronizer.  Currently, it uses Xilinx attributes to force the use
--| of flip flops, located in a single CLB. A naming convention is used to allow
--| an automated tool to generate a timing exception on the synchronizer stages
--| (f_dst_sync_meta_rst_reg). For example, such a Xilinx XDC constraint can be:
--|
--| set_max_delay -datapath_only -from [all_clocks] -to [get_pins -hierarchical
--|                                                   f_dst_sync_*_rst_reg/PRE}] 5
--| set_max_delay -datapath_only -from [all_clocks] -to [get_pins -hierarchical
--|                                                   f_dst_sync_*_rst_reg/CLR}] 5
--|
--| More stages can be added to increase reliability at the expense of area.
--|
--|
--| INTERFACE:
--|
--|   i_async_rst : Asynchronous reset input.  It defaults to active high, but
--|                 this can be changed with the G_ACTIVE_LEVEL generic.
--|
--|   i_dst_clk   : Clock of destination domain.
--|
--|   o_async_rst : Synchronized reset in the destination domain.  The active
--|                 level is set with the G_ACTIVE_LEVEL generic and will be
--|                 same as the input level.
--|
--|
--| CONFIGURATION/GENERICS:
--|
--|   G_ACTIVE_LEVEL : Reset active level of the input and output.
--|                   '0'- Output reset state is low.
--|                   '1'- (DEFAULT) Output reset state is high.
--|
--|   G_SYNC_STAGES : Defines the number of sync stages generated.  It can range
--|                   from 2 (DEFAULT) to 6.  
--|
--|
--| Also see:
--|
--|   cdc_sync_scalar: Used to synchronize a scalar signal.
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
--|   Asynchronous FIFO: A FIFO from a vendor library is an easy and low risk
--|                    method to pass data between clock domains.  It also has
--|                    the highest bandwidth of the options here.  It will
--|                    likely have the largest area impact, however.
--|
--| History:
--|
--|   03/13/2017: DLS - Initial revision.
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--| 
--|  u_rst_sync : entity work.cdc_reset_bridge
--|    port map( i_async_rst => w_src_async_reset, o_async_rst => w_dst_async_reset, i_dst_clk => w_dst_clock);
--|
--|  u_rst_n_sync : entity work.cdc_reset_bridge
--|    generic map(  G_ACTIVE_LEVEL => '0' )              
--|    port map( i_async_rst => w_src_async_reset_n, o_async_rst => w_dst_async_reset_n, i_dst_clk => w_dst_clock);
--|
--|  u_rst_3stage_sync : entity work.cdc_reset_bridge
--|    generic map(  G_SYNC_STAGES => 3 )              
--|    port map( i_async_rst => w_src_async_reset, o_async_rst => w_dst_async_reset, i_dst_clk => w_dst_clock);
--|
--|  u_rst_n_4stage_sync : entity work.cdc_reset_bridge
--|    generic map(  G_ACTIVE_LEVEL => '0', G_SYNC_STAGES => 4 )              
--|    port map( i_async_rst => w_src_async_reset_n, o_async_rst => w_dst_async_reset_n, i_dst_clk => w_dst_clock);
--|
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;


-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_reset_bridge is
  generic (
    G_ACTIVE_LEVEL      : std_logic            := '1';
    G_SYNC_STAGES       : integer range 2 to 8 := 2                 
  );

  port (
    i_async_rst         : in  std_logic;

    ----------------- DESTINATION CLOCK DOMAIN -------------------
    i_dst_clk           : in  std_logic;
    o_async_rst         : out std_logic
  );

end cdc_reset_bridge;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_reset_bridge is

  ---------------------------
  -- Signal Declarations
  ---------------------------
  -- dst_clk domain
  -- The first stage is given a unique name to be used for timing exception
  -- generation (f_???_sync_meta_???.  The remaining stages are in the array.
  signal f_dst_sync_meta_rst   : std_logic := G_ACTIVE_LEVEL;
  signal f_dst_sync_stages_rst : std_logic_vector(G_SYNC_STAGES-1 downto 1) :=
                                                     (others => G_ACTIVE_LEVEL);

  ---------------------------
  -- Attribute Declarations
  ---------------------------

  attribute ASYNC_REG     : string;

  attribute ASYNC_REG     of  f_dst_sync_meta_rst    : signal is "TRUE";  
  attribute ASYNC_REG     of  f_dst_sync_stages_rst  : signal is "TRUE";  


begin

  sync_regs : process(i_dst_clk, i_async_rst)
  begin
    if (i_async_rst = G_ACTIVE_LEVEL) then
      f_dst_sync_meta_rst   <= G_ACTIVE_LEVEL;
      f_dst_sync_stages_rst <= (others => G_ACTIVE_LEVEL);
    elsif (i_dst_clk'event and i_dst_clk ='1') then
      f_dst_sync_meta_rst       <= not G_ACTIVE_LEVEL;
      f_dst_sync_stages_rst(1)  <= f_dst_sync_meta_rst;
      if (G_SYNC_STAGES > 2) then
        f_dst_sync_stages_rst(G_SYNC_STAGES-1 downto 2) <= 
                              f_dst_sync_stages_rst(G_SYNC_STAGES-2 downto 1);
      end if;
    end if;
  end process;

  o_async_rst <= f_dst_sync_stages_rst(G_SYNC_STAGES-1);

end rtl;
