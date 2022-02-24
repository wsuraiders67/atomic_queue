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
--|       File             : cdc_sync_vector
--|       Original Project : MISD 
--|       Original Author  : D. Simpson
--|       Original Date    : 09/11/2015
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
--| signal.  It is intended to be useful for the majority of situations. It sets
--| attributes on the registers that implementation tools can use to create an
--| optimum synchronizer.  Currently, it uses Xilinx attributes to force the use
--| of flip flops, located in a single CLB. A naming convention is used to allow
--| a simple timing exception. For example, such a Xilinx XDC constraint can be:
--|
--| set_false_path -to [get_cells -hierarchical {*f_pseudo_const_reg*}]
--|
--|   The default setting of the generics configure it for the most common case,
--| a 2-stage synchronizer.  A reset or set can be used, if necessary.  An extra
--| register stage can be added to the input for timing critical designs.   Note,
--| if the input is a binary count, the gen_count_sync will likely be a better
--| choice.  For the general case where more than one bit can change each source
--| clock, special handshaking must be utilized such that the data bits remain
--| coherent.
--|
--|   Special cases exists where a synchronizer is not required to cross the
--| clock domain boundary.  Such a case is when the signal (scalar or vector)
--| is considered to be a "pseudo-constant."  Here the destination clock domain
--| has special provisions that prevent the pseudo-constant signal from being
--| sampled while it is changing.  In order to distinguish between such a case
--| and a signal which inadvertently crosses a clock domain, a different block
--| exists which infers a single flip flop (per bit) with an instance name that
--| can be used to generate a timing exception.  Refer to the "Also See"
--| section below. 
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
--|   i_src_data  : Signal of originating clock domain.
--|
--|   i_dst_clk   : Clock of the destination domain.
--|
--|   i_dst_rst   : Optional active high, synchronous reset of the destination domain.
--|
--|   i_dst_set   : Optional active high, synchronous set of the destination domain.
--|
--|   o_dst_data  : Synchronized signal in destination domain.  It is the same
--|                 width as the input data (i_src_data).
--|
--|
--| CONFIGURATION/GENERICS:
--|
--|   G_REGISTER_INPUT : When set to 1 adds an extra register stage to the input
--|                   data (i_src_data) to remove a combinational path (>2 LUTs,
--|                   a function of the bus width) on the input.  If no timing
--|                   issues exist, set to 0 (DEFAULT).
--|
--|   G_SYNC_STAGES : Defines the number of sync stages generated.  It can range
--|                   from 2 (DEFAULT) to 6.  
--|
--|
--| Also see:
--|
--|   cdc_sync_scalar: Used to synchronize a scalar signal.
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
--|   09/29/2015: DLS - Changed the package name to cdc_pkg.
--|   06/06/2018: DLS - Changed the interface to be more user friendly.  That
--|                     is accomplished with fewer generics and default values
--|                     for optional inputs.
--|
--|_____________________________________________________________________________
--|
--| Instantiation Templates:
--| 
--|  u_sync : entity work.cdc_sync_vector
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst : entity work.cdc_sync_vector
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_set : entity work.cdc_sync_vector
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock, i_src_set => w_src_set,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|  u_sync_reg : entity work.cdc_sync_vector
--|    generic map(  G_REGISTER_INPUT => 1 )              
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock);
--|
--|  u_sync_rst_reg : entity work.cdc_sync_vector
--|    generic map(  G_REGISTER_INPUT => 1 )              
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_3stage_rst : entity work.cdc_sync_vector
--|    generic map(  G_SYNC_STAGES => 3 )              
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock, i_src_rst => w_src_reset,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock, i_dst_rst => w_dst_reset);
--|
--|  u_sync_4stage_set_reg : entity work.cdc_sync_vector
--|    generic map(  G_REGISTER_INPUT => 1, G_SYNC_STAGES => 4 )              
--|    port map( i_src_data => w_src_vec, i_src_clk => w_src_clock, i_src_set => w_src_set,
--|              o_dst_data => w_dst_vec, i_dst_clk => w_dst_clock, i_dst_set => w_dst_set);
--|
--|_____________________________________________________________________________


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_misc.or_reduce;


-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity  cdc_sync_vector is
  generic (
    -- 1=Register input
    G_REGISTER_INPUT              : integer range 0 to    1 := 0;
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

end cdc_sync_vector;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of cdc_sync_vector is


  ---------------------------
  -- Type Declarations
  ---------------------------
  type at_gslvg  is array(G_SYNC_STAGES-1 downto 1) of std_logic_vector(i_src_data'range);


  ---------------------------
  -- Signal Declarations
  ---------------------------
  -- src_clk domain
  signal f_src_hold_input      : std_logic := '0';
  signal f_src_data            : std_logic_vector(i_src_data'range)    := (others => '0');
  signal f_src2dst_data        : std_logic_vector(i_src_data'range)    := (others => '0');
  signal c_src_input_changed   : std_logic_vector(i_src_data'range);
  signal f_src2dst_valid_tog   : std_logic := '0';
  signal f_src_sync_meta_rdy   : std_logic := '0';
  signal f_src_sync_stages_rdy : std_logic_vector(G_SYNC_STAGES-1 downto 1) := (others => '0');
  signal f_src_ready_delay     : std_logic := '0';
  signal c_src_ready_pulse     : std_logic;

  -- dst_clk domain
  -- The output reg is given a unique name used for timing exception generation
  signal f_pseudo_const        : std_logic_vector(i_src_data'range);
  signal c_dst_valid_pulse     : std_logic := '0';
  signal f_dst_sync_meta_val   : std_logic := '0';
  signal f_dst_sync_stages_val : std_logic_vector(G_SYNC_STAGES-1 downto 1) := (others => '0');
  signal f_dst_valid_delay     : std_logic := '0';
  signal f_dst2src_ready_tog   : std_logic := '0';

  ---------------------------
  -- Attribute Declarations
  ---------------------------

  -- Attributes below prevent a shift register synchronizer implementation.
  attribute ASYNC_REG     : string;

  attribute ASYNC_REG     of  f_dst_sync_meta_val   : signal is "TRUE";  
  attribute ASYNC_REG     of  f_dst_sync_stages_val : signal is "TRUE";  

  attribute ASYNC_REG     of  f_src_sync_meta_rdy   : signal is "TRUE";  
  attribute ASYNC_REG     of  f_src_sync_stages_rdy : signal is "TRUE";  

  attribute ASYNC_REG     of  f_pseudo_const        : signal is "TRUE";  

begin


  ------------------------------------------------------------------------------
  -- Register the input if the generic is set.
  ------------------------------------------------------------------------------
  -- A "hold" register is added to the input:
  --                                    | |
  --                                    |B|                    
  --                 _____f_src2dst_data|O|                 _____
  -- i_src_data ----| D Q |-------------|U|----------------| D Q |--- i_dst_data
  --                |     |             |N|f_dst_valid ----|CE   |
  --  i_src_clk ----|>    |             |D|                |     |
  --                |_____|             |R|  i_dst_clk ----|>    |
  --                                    |Y|                |_____|
  --                                    | |
  ------------------------------------------------------------------------------

  NO_REG_IN : if (G_REGISTER_INPUT = 0) generate
  begin

    f_src_data <= i_src_data;

  end generate NO_REG_IN;


  REG_IN : if ( G_REGISTER_INPUT = 1 ) generate
  begin

    input_reg : process(i_src_clk)
    begin
      if (i_src_clk'event and i_src_clk ='1') then

        if    i_src_rst = '1' then
          f_src_data <= (others => '0');
        elsif i_src_set = '1' then
          f_src_data <= (others => '1');
        else
          f_src_data <= i_src_data;
        end if;

      end if;
    end process input_reg;

  end generate REG_IN;


  hold_reg : process(i_src_clk)
  begin
    if (i_src_clk'event and i_src_clk ='1') then
      if    i_src_rst = '1' then
        f_src2dst_data <= (others => '0');
      elsif i_src_set = '1' then
        f_src2dst_data <= (others => '1');
      elsif (f_src_hold_input = '0') then
        f_src2dst_data <= f_src_data;
      end if;
    end if;
  end process hold_reg;


  ---------------------------
  -- CDC Handshake Logic
  ---------------------------

  -- Compare input to the input register, set flags for each bit that changed.
  c_src_input_changed <= f_src_data xor f_src2dst_data;

  -- Create a ready pulse from the returning ready toggle signal.
  c_src_ready_pulse   <= f_src_ready_delay xor 
                                         f_src_sync_stages_rdy(G_SYNC_STAGES-1);

  src_dom : process(i_src_clk)
  begin
    if (i_src_clk'event and i_src_clk ='1') then

      if ( i_src_rst = '1' or i_src_set = '1' ) then
        f_src_hold_input       <= '0';
        f_src2dst_valid_tog    <= '0';
        f_src_sync_meta_rdy    <= '0';
        f_src_sync_stages_rdy  <= (others => '0');
        f_src_ready_delay      <= '0';
      else

        if (c_src_ready_pulse = '1') then
          f_src_hold_input <= '0';
        else
          if (or_reduce(c_src_input_changed) = '1') then
            f_src_hold_input <= '1';
          end if;
        end if;

        if (f_src_hold_input = '0') then
          if (or_reduce(c_src_input_changed) = '1') then
            f_src2dst_valid_tog <= not f_src2dst_valid_tog;
          end if;
        end if;

        f_src_sync_meta_rdy       <= f_dst2src_ready_tog;
        f_src_sync_stages_rdy(1)  <= f_src_sync_meta_rdy;
        if (G_SYNC_STAGES > 2) then
          f_src_sync_stages_rdy(G_SYNC_STAGES-1 downto 2) <= 
                                f_src_sync_stages_rdy(G_SYNC_STAGES-2 downto 1);
        end if;
        f_src_ready_delay         <= f_src_sync_stages_rdy(G_SYNC_STAGES-1);

      end if;  -- i_src_rst

    end if;
  end process src_dom;

  -- Create a valid pulse from the valid toggle signal.
  c_dst_valid_pulse   <= f_dst_valid_delay xor 
                                         f_dst_sync_stages_val(G_SYNC_STAGES-1);

-------------------------------CLOCK DOMAIN BOUNDARY----------------------------

  dst_dom : process(i_dst_clk)
  begin
    if (i_dst_clk'event and i_dst_clk ='1') then

      if ( i_dst_rst = '1' or i_dst_set = '1' ) then
        f_dst_sync_meta_val    <= '0';
        f_dst_sync_stages_val  <= (others => '0');
        f_dst_valid_delay      <= '0';
        f_dst2src_ready_tog    <= '0';
      else

        f_dst_sync_meta_val       <= f_src2dst_valid_tog;
        f_dst_sync_stages_val(1)  <= f_dst_sync_meta_val;
        if (G_SYNC_STAGES > 2) then
          f_dst_sync_stages_val(G_SYNC_STAGES-1 downto 2) <= 
                                f_dst_sync_stages_val(G_SYNC_STAGES-2 downto 1);
        end if;
        f_dst_valid_delay         <= f_dst_sync_stages_val(G_SYNC_STAGES-1);

        if (c_dst_valid_pulse = '1') then
          f_dst2src_ready_tog <= not f_dst2src_ready_tog;
        end if;

      end if;  -- i_dst_rst

    end if;
  end process dst_dom;


  ---------------------------
  -- Reset Output?
  ---------------------------

  output_reg : process(i_dst_clk)
  begin
    if (i_dst_clk'event and i_dst_clk ='1') then

      if    i_dst_rst = '1' then
        f_pseudo_const  <= (others => '0');
      elsif i_dst_set = '1' then
        f_pseudo_const  <= (others => '1');
      elsif (c_dst_valid_pulse = '1') then
        f_pseudo_const  <= f_src2dst_data;
      end if;

    end if;
  end process output_reg;


  -- pseudo_const should never go metastable because the data is guaranteed
  -- to be stable prior to sampling the "synchronizer" input.
  o_dst_data <= f_pseudo_const;


end rtl;
