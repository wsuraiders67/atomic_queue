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
--|       File             : cdc_sync_count
--|       Original Project : MISD 
--|       Original Author  : D. Simpson
--|       Original Date    : 09/16/2015
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
--|   This block is a general purpose clock domain crossing circuit for a vector
--| signal.  It is intended to be used for binary counters. It marks the registers
--| with attributes that the implementation tools can use to create an optimum
--| synchronizer.  Currently, it uses Xilinx attributes to force the use of flip
--| flops and locate them in a single CLB.  A naming convention is used to allow
--| a tool to generate a timing exception on the first stage (sync_meta_reg*).
--| For example, a Xilinx XDC constraint can be written as:
--|
--| set_max_delay -datapath_only -from [all_clocks] -to [get_pins -hierarchical
--|                                             {*f_???_sync_meta_???_reg*/D}] 5
--|
--|   Binary counts which can only change by +/- 1 each source clock can be
--| coverted to gray code, where only one bit changes at a time.  Such a signal
--| can be synchronized without loss of coherency.  This is the process used by
--| this block.  The input count is converted to gray code and registered. This
--| only adds a single LUT before the input register, so there is no need to
--| offer a registered input version.  This count can then be synchronzied just
--| like a scalar.  The output of the sychronizer is then converted back to 
--| binary.  Since this conversion can require several levels of LUTs (it is a
--| function of the count width), an output register option exists.
--|
--|   The default setting of the generics configure it for the most common case,
--| a 2-stage synchronizer.  A reset or set can be used, if necessary.  Note,
--| if the input is not a binary count, or can change by more than i+/- 1 in one
--| source clock, the cdc_sync_vector block should be used.  An output register
--| may also be added if a significant output load exists, since a LUT follows
--| the synchronizer for gray code to binary conversion.
--|
--|   Special cases exists where a synchronizer is not required to cross the
--| clock domain boundary.  Such a case is when the signal (scalar or vector)
--| is considered to be a "pseudo-constant."  Here the destination clock domain
--| has special provisions that prevent the pseudo-constant signal from being
--| sampled while it is changing.  In order to distinguish between such a case
--| and a signal which inadvertently crosses a clock domain, a different block
--| exists which infers a single flip-flop (per bit) with an instance name that
--| can be used to generate a timing exception.  Refer to the "Also See" section
--| below. 
--|
--|
--| INTERFACE:
--|
--|   i_src_clk   : Clock of originating domain (source clock domain).
--|
--|   i_src_rst   : Optional active high, synchronous reset of the originating domain.
--|
--|   i_src_set   : Optional active high, synchronous set of the originating domain.
--|
--|   i_src_data  : Count of the originating clock domain.
--|
--|   i_dst_clk   : Clock of the destination domain.
--|
--|   i_dst_rst   : Optional active high, synchronous reset of the destination domain.
--|
--|   i_dst_set   : Optional active high, synchronous set of the destination domain.
--|
--|   o_dst_data  : Synchronized count in the destination domain.  It must be the
--|                 same width as the input data (i_src_data).
--|
--|
--| CONFIGURATION/GENERICS:
--|
--|   G_REGISTER_OUTPUT : When set to 1 adds a register stage to the output data
--|                   (o_dst_data).  Set to 0 (DEFAULT) if a LUT following the
--|                   synchronizer is acceptable.
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
--|   09/29/2015: DLS - Changed the package name to cdc_pkg.
--|   06/06/2018: DLS - Changed the interface to be more user friendly.  That
--|                     is accomplished with fewer generics and default values
--|                     for optional inputs.
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--| 
--|  u_sync : entity work.cdc_sync_count
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst : entity work.cdc_sync_count
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_set : entity work.cdc_sync_count
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock, i_src_set => w_src_set,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|  u_sync_reg : entity work.cdc_sync_count
--|    generic map(  G_REGISTER_OUTPUT => 1 )              
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst_reg : entity work.cdc_sync_count
--|    generic map(  G_REGISTER_OUTPUT => 1 )              
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_3stage_rst : entity work.cdc_sync_count
--|    generic map(  G_SYNC_STAGES => 3 )              
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_4stage_set_reg : entity work.cdc_sync_count
--|    generic map(  G_REGISTER_OUTPUT => 1, G_SYNC_STAGES => 4 )              
--|    port map( i_src_data => w_src_cnt, i_src_clk => w_src_clock, i_src_set => w_src_set,
--|              o_dst_data => w_dst_cnt, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;


-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_sync_count is
  generic (
    -- 1=Register output
    G_REGISTER_OUTPUT             : integer range 0 to    1 := 0;
    G_SYNC_STAGES                 : integer range 2 to    6 := 2                 
  );

  port (
    ------------------- SOURCE CLOCK DOMAIN ----------------------
    i_src_clk                     : in  std_logic;
    i_src_rst                     : in  std_logic := '0';         -- Sync to i_src_clk
    i_src_set                     : in  std_logic := '0';         -- Sync to i_src_clk
    i_src_data                    : in  std_logic_vector;

    ----------------- DESTINATION CLOCK DOMAIN -------------------
    i_dst_clk                     : in  std_logic;
    i_dst_rst                     : in  std_logic := '0';         -- Sync to i_dst_clk
    i_dst_set                     : in  std_logic := '0';         -- Sync to i_dst_clk
    o_dst_data                    : out std_logic_vector
  );

end cdc_sync_count;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_sync_count is


  ---------------------------
  -- Type Declarations
  ---------------------------
  type at_gslvg  is array(G_SYNC_STAGES-1 downto 1) of std_logic_vector(i_src_data'range);


  ---------------------------
  -- Signal Declarations
  ---------------------------
  -- src_clk domain
  signal c_src_data_gc         : std_logic_vector(i_src_data'range)    := (others => '0');
  signal f_src2dst_data        : std_logic_vector(i_src_data'range)    := (others => '0');

  -- dst_clk domain
  -- The first stage is given a unique name to be used for timing exception
  -- generation (f_???_sync_meta_???.  The remaining stages are in this array.
  signal f_dst_sync_meta_dat   : std_logic_vector(i_src_data'range);
  signal f_dst_sync_stages_dat : at_gslvg;
  signal f_sync_out_gc         : std_logic_vector(i_src_data'range);
  signal c_sync_out_bin        : std_logic_vector(i_src_data'range);


  ---------------------------
  -- Attribute Declarations
  ---------------------------
  -- ASYNC_REG attribute also prevents a shift register implementation
  attribute ASYNC_REG          : string;

  attribute ASYNC_REG     of  f_dst_sync_meta_dat    : signal is "TRUE";  
  attribute ASYNC_REG     of  f_dst_sync_stages_dat  : signal is "TRUE";  


begin


  bin2gray : process(i_src_data)
  begin
    c_src_data_gc(i_src_data'left) <= i_src_data(i_src_data'left);

    for i in  i_src_data'left-1 downto i_src_data'right  loop
      c_src_data_gc(i) <= i_src_data(i+1) xor i_src_data(i);
    end loop;

  end process bin2gray;


  input_regs : process(i_src_clk)
  begin
    if (i_src_clk'event and i_src_clk ='1') then

      if    i_src_rst = '1' then
        f_src2dst_data <= (others => '0');
      elsif i_src_set = '1' then
        f_src2dst_data <= (others => '1');
      else
        f_src2dst_data <= c_src_data_gc;
      end if;
    end if;
  end process input_regs;


-------------------------------CLOCK DOMAIN BOUNDARY----------------------------


  ---------------------------
  -- Synchronizer
  ---------------------------

  sync_regs : process(i_dst_clk)
  begin
    if (i_dst_clk'event and i_dst_clk ='1') then

      if    i_dst_rst = '1' then
        f_dst_sync_meta_dat   <= (others => '0');
        f_dst_sync_stages_dat <= (others => (others => '0'));
      elsif i_dst_set = '1' then
        f_dst_sync_meta_dat   <= (others => '1');
        f_dst_sync_stages_dat <= (others => (others => '1'));
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


  f_sync_out_gc <= f_dst_sync_stages_dat(G_SYNC_STAGES-1);


  gray2bin : process(f_sync_out_gc)
    variable bin_temp : std_logic_vector(i_src_data'range);
  begin
    bin_temp(i_src_data'left) := f_sync_out_gc(i_src_data'left);

    for i in  i_src_data'left-1 downto i_src_data'right  loop
      bin_temp(i) := bin_temp(i+1) xor f_sync_out_gc(i);
    end loop;

    c_sync_out_bin   <= bin_temp;

  end process gray2bin;


  ---------------------------
  -- Register Output?
  ---------------------------

  NO_OUT_REGS : if (G_REGISTER_OUTPUT = 0) generate
  begin

    o_dst_data <= c_sync_out_bin;

  end generate NO_OUT_REGS;


  OUT_REGS : if (G_REGISTER_OUTPUT = 1) generate
  begin

    output_regs : process(i_dst_clk)
    begin
      if (i_dst_clk'event and i_dst_clk ='1') then

        if    i_dst_rst = '1' then
          o_dst_data <= (o_dst_data'range => '0');
        elsif i_dst_set = '1' then
          o_dst_data <= (o_dst_data'range => '1');
        else
          o_dst_data <= c_sync_out_bin;
        end if;

      end if;
    end process output_regs;

  end generate OUT_REGS;


end rtl;
