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
--|       File             : cdc_pseudo_const
--|       Original Project : MISD 
--|       Original Author  : D. Simpson
--|       Original Date    : 09/18/2015
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
--|   This block is intended to be used for signals which cross a clock domain,
--| but will not be sampled in the destination clock domain while changing. Some
--| outside mechanism must exist to ensure that this condition is met, any time
--| the signal changes, not only during the initial setting.  Signals that fall
--| into this category are referred to as a "pseudo-constant" and do not require
--| synchronization, which saves design resources.  This block is merely a place
--| holder, intended to be the single point gateway into the destination clock
--| domain.  It is useful in distinguishing between an intended absence of a
--| synchronizer and an unintended clock domain crossing, thus documenting the
--| designers intent.  It is simply a register stage with a naming convention
--| that allows it to be detected, and can be used to automate the application
--| of a timing exception.  For example, a Xilinx XDC constraint can be written:
--|
--| set_false_path -to [get_cells -hierarchical {*f_pseudo_const_reg*}]
--|
--|   The default setting of the generic configures it for the most common case,
--| a 1-bit wide register with no reset or set.  A reset or set can be connected.
--| If both are connected the reset has precedence.  
--|
--|   Different blocks exist which can be used for the more general case where
--| the signal cannot be guaranteed to be stable before being sampled.  Refer to
--| the "Also See" section below for descriptions.  
--|
--|
--| INTERFACE:
--|
--|   i_data  : Signal of originating clock domain, scalar or vector.  If vector,
--|             the width is automatically found. When synchronizing a scalar,
--|             the i_data port on the instantiation can be mapped as follows:
--|
--|                        i_data(0)  =>  my_scalar_cdc_signal,
--|
--|   i_clk   : Clock of destination domain.
--|
--|   i_rst   : Active high, synchronous reset of the destination domain.  If
--|             not connected, it will default to '0' (unused).
--|
--|   i_set   : Active high, synchronous set of the destination domain.  If
--|             not connected, it will default to '0' (unused).
--|
--|   o_data  : Synchronized signal in destination domain.  It is the same
--|             width as the input data (i_data).
--|
--|
--| CONFIGURATION/GENERICS:
--|
--|   G_PIPE_LEVELS : Defines the number of pipeline register levels to be added
--|                   after the pseudo_constant "synchronizer".  It can range
--|                   from 0 (DEFAULT) to 6.  
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
--|   cdc_reset_bridge: Used to synchronize an asynchronous reset. 
--|
--|   Asynchronous FIFO: A FIFO from a vendor library is an easy and low risk
--|                    method to pass data between clock domains.  It also has
--|                    the highest bandwidth of the options here.  It will
--|                    likely have the largest area impact, however.
--| History:
--|
--|   09/29/2015: DLS - Changed the package name to cdc_pkg.
--|   06/06/2018: DLS - Changed the interface to be more user friendly.  That
--|                     is accomplished with fewer generics and default values
--|                     for optional inputs.
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--| 
--|  u_psync_scalar : entity lib_common.cdc_pseudo_const
--|    port map( i_data(0) => w_src_sl, o_data(0) => w_dst_sl, i_clk => w_myclk);
--| 
--|  u_psync_scalar_rst : entity lib_common.cdc_pseudo_const
--|    port map( i_data(0) => w_src_sl, o_data(0) => w_dst_sl, i_clk => w_myclk, i_rst => w_myrst);
--| 
--|  u_psync : entity lib_common.cdc_pseudo_const
--|    port map( i_data => w_src_slv, o_data => w_dst_slv, i_clk => w_myclk);
--| 
--|  u_psync_rst : entity lib_common.cdc_pseudo_const
--|    port map( i_data => w_src_slv, o_data => w_dst_slv, i_clk => w_myclk, i_rst => w_myrst);
--| 
--|  u_psync_set : entity lib_common.cdc_pseudo_const
--|    port map( i_data => w_src_slv, o_data => w_dst_slv, i_clk => w_myclk, i_set => w_myrst);
--| 
--|  u_psync_pipe : entity lib_common.cdc_pseudo_const
--|    generic map(  G_PIPE_LEVELS => 3 )              
--|    port map( i_data => w_src_slv, o_data => w_dst_slv, i_clk => w_myclk);
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;


-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_pseudo_const is
  generic (
    G_PIPE_LEVELS       : natural := 0                 
  );

  port (
    ------------------- SOURCE CLOCK DOMAIN ----------------------
    i_data              : in  std_logic_vector;

    ----------------- DESTINATION CLOCK DOMAIN -------------------
    i_clk               : in  std_logic;
    i_rst               : in  std_logic := '0';               -- Sync to i_clk
    i_set               : in  std_logic := '0';               -- Sync to i_clk
    
    o_data              : out std_logic_vector
  );

end cdc_pseudo_const;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_pseudo_const is

  ---------------------------
  -- Signal Declarations
  ---------------------------
  -- dst_clk domain
  -- The pseudo reg is given a unique name used for timing exception generation
  signal f_pseudo_const        : std_logic_vector(i_data'range);
  
  type at_slv_width is array (natural range<>) of std_logic_vector(i_data'range);
  signal f_dst_pipe            : at_slv_width(G_PIPE_LEVELS downto 0);


  ---------------------------
  -- Attribute Declarations
  ---------------------------
  -- The ASYNC_REG attribute can also be used for timing exception generation
  attribute ASYNC_REG          : string;
  attribute SHREG_EXTRACT      : string;  

  attribute ASYNC_REG     of  f_pseudo_const        : signal is "TRUE";  

  attribute SHREG_EXTRACT of  f_dst_pipe            : signal is "NO";

begin


  ----------------------------------------------------------------------------
  -- Pseudo_const should never go metastable because the data is guaranteed
  -- to be stable prior to sampling the "synchronizer" input.
  ----------------------------------------------------------------------------
  pseudo_reg : process(i_clk)
  begin
    if (i_clk'event and i_clk ='1') then

      if    i_rst = '1' then
        f_pseudo_const  <= (others => '0');
      elsif i_set = '1' then
        f_pseudo_const  <= (others => '1');
      else
        f_pseudo_const  <= i_data;
      end if;

    end if;
  end process pseudo_reg;


  ----------------------------------------------------------------------------
  -- Add more pipeline stages to synchronizer if requested
  ----------------------------------------------------------------------------
  f_dst_pipe(0) <= f_pseudo_const;

  SYNC_PIPE : if G_PIPE_LEVELS > 0 generate
  begin
    pipe_stages : process(i_clk)
    begin
      if (i_clk'event and i_clk ='1') then

        if i_rst = '1' then
          f_dst_pipe(G_PIPE_LEVELS downto 1)  <= (others => (others => '0'));
        elsif i_set = '1' then
          f_dst_pipe(G_PIPE_LEVELS downto 1)  <= (others => (others => '1'));
        else
          f_dst_pipe(G_PIPE_LEVELS downto 1) <= f_dst_pipe(G_PIPE_LEVELS-1 downto 0);
        end if;
       
      end if;
    end process pipe_stages;
  end generate SYNC_PIPE;


  ----------------------------------------------------------------------------
  -- Assign end of pipeline to the output
  ----------------------------------------------------------------------------
  o_data <= f_dst_pipe(G_PIPE_LEVELS);

end rtl;
