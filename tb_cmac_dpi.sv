module tb_cmac_dpi;

  import "DPI-C" context function bit cmac_check(
    input  int unsigned idx,
    input  int unsigned ar,
    input  int unsigned ai,
    input  int unsigned br,
    input  int unsigned bi,
    input  bit          clear_acc,
    input  int unsigned got_zr,
    input  int unsigned got_zi
  );
  import "DPI-C" context function void cmac_gen_test(
    output int unsigned ar,
    output int unsigned ai,
    output int unsigned br,
    output int unsigned bi
  );

  logic        clk;
  logic        rst_n;
  logic        start_i;
  logic        flush_i;
  logic        done_o;
  logic [31:0] ar_i;
  logic [31:0] ai_i;
  logic [31:0] br_i;
  logic [31:0] bi_i;
  logic [31:0] zr_o;
  logic [31:0] zi_o;

  localparam int unsigned NTESTS = 100;

  cmac dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .start_i(start_i),
    .flush_i(flush_i),
    .done_o (done_o),
    .ar_i   (ar_i),
    .ai_i   (ai_i),
    .br_i   (br_i),
    .bi_i   (bi_i),
    .zr_o   (zr_o),
    .zi_o   (zi_o)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk;
  end

  task automatic apply_reset();
    begin
      rst_n   = 1'b0;
      start_i = 1'b0;
      flush_i = 1'b0;
      ar_i    = '0;
      ai_i    = '0;
      br_i    = '0;
      bi_i    = '0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic run_one(input int unsigned idx, output bit pass);
    int unsigned ar;
    int unsigned ai;
    int unsigned br;
    int unsigned bi;
    int unsigned got_zr;
    int unsigned got_zi;
    int unsigned timeout;
    begin
      cmac_gen_test(ar, ai, br, bi);

      @(posedge clk);
      ar_i    = ar;
      ai_i    = ai;
      br_i    = br;
      bi_i    = bi;
      start_i = 1'b1;

      @(posedge clk);
      start_i = 1'b0;

      timeout = 0;
      while (!done_o && timeout < 20) begin
        @(posedge clk);
        timeout++;
      end

      if (!done_o) begin
        $error("Timeout esperando done_o en test %0d", idx);
        pass = 1'b0;
      end else begin
        got_zr = zr_o;
        got_zi = zi_o;
        pass = cmac_check(
          idx,
          ar,
          ai,
          br,
          bi,
          idx == 0,
          got_zr,
          got_zi
        );
        if (!pass) begin
          $error("Test %0d FAIL", idx);
        end
      end

      @(posedge clk);
    end
  endtask

  initial begin
    int unsigned fails;
    bit pass;

    apply_reset();

    fails = 0;

    for (int unsigned i = 0; i < NTESTS; i++) begin
      run_one(i, pass);
      if (!pass) fails++;
    end

    if (fails == 0) begin
      $display("CMAC DPI TB: PASS (%0d tests)", NTESTS);
    end else begin
      $error("CMAC DPI TB: FAIL (%0d/%0d tests fallaron)", fails, NTESTS);
    end

    $finish;
  end

endmodule
