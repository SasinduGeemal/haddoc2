library ieee;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;

library work;
	use work.cnn_types.all;
    use work.params.all;

entity cnn_process is
    generic(
        PIXEL_SIZE    :   integer ;
        IMAGE_WIDTH   :   integer
    );

    port(
        clk	          : in  std_logic;
        reset_n	      : in  std_logic;
        enable        : in  std_logic;

        in_data       : in  std_logic_vector (PIXEL_SIZE - 1 downto 0);
        in_dv         : in  std_logic;
        in_fv         : in  std_logic;

        out1_data     : out std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out1_dv       : out std_logic;
        out1_fv       : out std_logic;

        out2_data     : out std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out2_dv       : out std_logic;
        out2_fv       : out std_logic;

        out3_data     : out std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out3_dv       : out std_logic;
        out3_fv       : out std_logic
    );
end entity;

architecture STRUCTURAL of cnn_process is

    --------------------------------------------------------------------------------
    -- COMPONENTS
    --------------------------------------------------------------------------------

    component firstLayer is
    generic(
        PIXEL_SIZE    :   integer;
        IMAGE_WIDTH   :   integer;
        KERNEL_SIZE   :   integer;
        NB_OUT_FLOWS  :   integer;
        W_CONV_PARAMS :   pixel_matrix;
        N_CONV_PARAMS :   pixel_array
    );

    port(
        clk	          :   in  std_logic;
        reset_n	      :   in  std_logic;
        enable        :   in  std_logic;
        in_data       :   in  std_logic_vector (0 to PIXEL_SIZE - 1);
        in_dv         :   in  std_logic;
        in_fv         :   in  std_logic;
        out_data      :   out pixel_array      (0 to NB_OUT_FLOWS - 1);
        out_dv        :   out std_logic_vector (0 to NB_OUT_FLOWS - 1);
        out_fv        :   out std_logic_vector (0 to NB_OUT_FLOWS - 1)
    );
    end component;

    --------------------------------------------------------------------------------

    component convLayer
    generic(
        PIXEL_SIZE    :   integer;
        IMAGE_WIDTH   :   integer;
        KERNEL_SIZE   :   integer;
        NB_IN_FLOWS   :   integer;
        NB_OUT_FLOWS  :   integer;
        W_CONV_PARAMS :   pixel_matrix;
        N_CONV_PARAMS :   pixel_array
    );

    port(
        clk	          : in  std_logic;
        reset_n	      : in  std_logic;
        enable        : in  std_logic;
        in_data       : in  pixel_array     (0 to NB_IN_FLOWS - 1);
        in_dv         : in  std_logic_vector(0 to NB_IN_FLOWS - 1);
        in_fv         : in  std_logic_vector(0 to NB_IN_FLOWS - 1);
        out_data      : out pixel_array     (0 to NB_OUT_FLOWS - 1);
        out_dv        : out std_logic_vector(0 to NB_OUT_FLOWS - 1);
        out_fv        : out std_logic_vector(0 to NB_OUT_FLOWS - 1)
    );
    end component;

    --------------------------------------------------------------------------------

    component poolLayer
    generic(
        PIXEL_SIZE    :   integer;
        IMAGE_WIDTH   :   integer;
        KERNEL_SIZE   :   integer;
        NB_OUT_FLOWS  :   integer
    );

    port(
        clk	          : in  std_logic;
        reset_n	      : in  std_logic;
        enable        : in  std_logic;
        in_data       : in  pixel_array      (0 to NB_OUT_FLOWS - 1);
        in_dv         : in  std_logic_vector (0 to NB_OUT_FLOWS - 1);
        in_fv         : in  std_logic_vector (0 to NB_OUT_FLOWS - 1);
        out_data      : out pixel_array      (0 to NB_OUT_FLOWS - 1);
        out_dv        : out std_logic_vector (0 to NB_OUT_FLOWS - 1);
        out_fv        : out std_logic_vector (0 to NB_OUT_FLOWS - 1)
    );
    end component;


    --------------------------------------------------------------------------------
    -- SIGNALS
    --------------------------------------------------------------------------------
    signal conv1_data : pixel_array      (0 to CONV1_LAYER_SIZE - 1);
    signal conv1_dv   : std_logic_vector (0 to CONV1_LAYER_SIZE - 1);
    signal conv1_fv   : std_logic_vector (0 to CONV1_LAYER_SIZE - 1);

    signal pool1_data : pixel_array      (0 to POOL1_LAYER_SIZE - 1);
    signal pool1_dv   : std_logic_vector (0 to POOL1_LAYER_SIZE - 1);
    signal pool1_fv   : std_logic_vector (0 to POOL1_LAYER_SIZE - 1);

    signal conv2_data : pixel_array      (0 to CONV2_LAYER_SIZE - 1);
    signal conv2_dv   : std_logic_vector (0 to CONV2_LAYER_SIZE - 1);
    signal conv2_fv   : std_logic_vector (0 to CONV2_LAYER_SIZE - 1);

    signal pool2_data : pixel_array      (0 to POOL2_LAYER_SIZE - 1);
    signal pool2_dv   : std_logic_vector (0 to POOL2_LAYER_SIZE - 1);
    signal pool2_fv   : std_logic_vector (0 to POOL2_LAYER_SIZE - 1);

    --------------------------------------------------------------------------------
    -- BEGIN STRUCTURAL DESCRIPTION
    --------------------------------------------------------------------------------
    begin

        -- CONV1 -------------------------------------------------------------------
        conv1: firstLayer
        generic map(
            PIXEL_SIZE    => PIXEL_SIZE,
            IMAGE_WIDTH   => CONV1_IMAGE_WIDTH,
            NB_OUT_FLOWS  => CONV1_LAYER_SIZE,
            KERNEL_SIZE   => CONV1_KERNEL_SIZE,
            W_CONV_PARAMS => CONV1_KERNEL_VALUE,
            N_CONV_PARAMS => CONV1_KERNEL_NORM
        )
        port map(
            clk	          => clk,
            reset_n	      => reset_n,
            enable        => enable,
            in_data       => in_data,
            in_dv         => in_dv,
            in_fv         => in_fv,
            out_data      => conv1_data,
            out_dv        => conv1_dv,
            out_fv        => conv1_fv
        );


        -- POOL1 -------------------------------------------------------------------
        pool1: poolLayer
        generic map(
            PIXEL_SIZE    => PIXEL_SIZE,
            IMAGE_WIDTH   => POOL1_IMAGE_WIDTH,
            NB_OUT_FLOWS  => POOL1_LAYER_SIZE,
            KERNEL_SIZE   => POOL1_KERNEL_SIZE
        )
        port map(
            clk	          => clk,
            reset_n	      => reset_n,
            enable        => enable,
            in_data       => conv1_data,
            in_dv         => conv1_dv,
            in_fv         => conv1_fv,
            out_data      => pool1_data,
            out_dv        => pool1_dv,
            out_fv        => pool1_fv
        );

        -- CONV2 -------------------------------------------------------------------
        conv2 : convLayer
        generic map(
            PIXEL_SIZE    => PIXEL_SIZE,
            IMAGE_WIDTH   => CONV2_IMAGE_WIDTH,
            NB_IN_FLOWS   => POOL1_LAYER_SIZE,
            NB_OUT_FLOWS  => CONV2_LAYER_SIZE,
            KERNEL_SIZE   => CONV2_KERNEL_SIZE,
            W_CONV_PARAMS => CONV2_KERNEL_VALUE,
            N_CONV_PARAMS => CONV2_KERNEL_NORM
        )
        port map(
            clk	          =>  clk,
            reset_n	      =>  reset_n,
            enable        =>  enable,
            in_data       =>  pool1_data,
            in_dv         =>  pool1_dv,
            in_fv         =>  pool1_fv,
            out_data      =>  conv2_data,
            out_dv        =>  conv2_dv,
            out_fv        =>  conv2_fv
        );

        -- POOL2 -------------------------------------------------------------------
        pool2: poolLayer
        generic map(
            PIXEL_SIZE    => PIXEL_SIZE,
            IMAGE_WIDTH   => POOL2_IMAGE_WIDTH,
            NB_OUT_FLOWS  => POOL2_LAYER_SIZE,
            KERNEL_SIZE   => POOL2_KERNEL_SIZE
        )
        port map(
            clk	          => clk,
            reset_n	      => reset_n,
            enable        => enable,
            in_data       => conv2_data,
            in_dv         => conv2_dv,
            in_fv         => conv2_fv,
            out_data      => pool2_data,
            out_dv        => pool2_dv,
            out_fv        => pool2_fv
        );

        -- DISPLAY ONLY : DO NOT GENERATE ------------------------------------------
        out1_data <= pool2_data(0);
        out1_dv   <= pool2_dv(0);
        out1_fv   <= pool2_fv(0);
        out2_data <= pool2_data(1);
        out2_dv   <= pool2_dv(1);
        out2_fv   <= pool2_fv(1);
        out3_data <= pool2_data(2);
        out3_dv   <= pool2_dv(2);
        out3_fv   <= pool2_fv(2);

end architecture;