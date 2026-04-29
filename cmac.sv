module cmac (
	input  logic        clk,
	input  logic        rst_n,
	input  logic        start_i,
	input  logic        flush_i,
	output logic        done_o,
	input  logic [31:0] ar_i,   // parte real de A
	input  logic [31:0] ai_i,   // parte imag de A
	input  logic [31:0] br_i,   // parte real de B
	input  logic [31:0] bi_i,   // parte imag de B
	output logic [31:0] zr_o,   // parte real de Z
	output logic [31:0] zi_o    // parte imag de Z
);

  	logic [31:0] in_re_1, in_re_2, out_re, accum_re, cmul_re;
    logic [31:0] in_im_1, in_im_2, out_im, accum_im, cmul_im;
    logic [31:0] mul_1_out, mul_2_out, mul_3_out, mul_4_out;
  	logic op1_type, op2_type; // add = 0, sub = 1

  	typedef enum logic [1:0] {
        IDLE,
        MUL,
		ADDSUB,
		ACUM
    } state_read;
    state_read state_r;

	fp_mul32_lite u_mul_ac (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (ar_i),
		.b_i  (br_i),
		.res_o(mul_1_out)
	);

	fp_mul32_lite u_mul_bd (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (ai_i),
		.b_i  (bi_i),
		.res_o(mul_2_out)
	);

	fp_mul32_lite u_mul_ad (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (ar_i),
		.b_i  (bi_i),
		.res_o(mul_3_out)
	);

	fp_mul32_lite u_mul_bc (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (ai_i),
		.b_i  (br_i),
		.res_o(mul_4_out)
	);

	// -----------------------
	//   zr = ac - bd
	//   zi = ad + bc
	// -----------------------
	fp_addsub32_lite u_add_sub_real (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (in_re_1),
		.b_i  (in_re_2),
		.sub_i(op1_type),
		.res_o(out_re)
	);

	fp_addsub32_lite u_add_sub_imag (
		.clk  (clk),
		.rst_n(rst_n),
		.a_i  (in_im_1),
		.b_i  (in_im_2),
		.sub_i(op2_type),
		.res_o(out_im)
	);


	always_comb begin
		in_re_1 = mul_1_out;
		in_re_2 = mul_2_out;
		in_im_1 = mul_3_out;
		in_im_2 = mul_4_out;
		op1_type = 1'b1; // ac - bd
		op2_type = 1'b0; // ad + bc

		if ((state_r == ADDSUB) || (state_r == ACUM)) begin
			in_re_1 = cmul_re;
			in_re_2 = accum_re;
			in_im_1 = cmul_im;
			in_im_2 = accum_im;
			op1_type = 1'b0; // accum_re + (ac - bd)
			op2_type = 1'b0; // accum_im + (ad + bc)
		end
	end


	// FSM de control
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			state_r <= IDLE;
			done_o <= 0;
            accum_re <= 0;
            accum_im <= 0;
            cmul_re <= 0;
            cmul_im <= 0;
            zr_o <= 0;
            zi_o <= 0;

        end else if (flush_i) begin
			state_r <= IDLE;
			done_o <= 0;
            accum_re <= 0;
            accum_im <= 0;
            cmul_re <= 0;
            cmul_im <= 0;
            zr_o <= 0;
            zi_o <= 0;

		end else begin
			case (state_r)
				IDLE: begin
					done_o <= 0;
					if (start_i) begin
						state_r <= MUL;
					end
				end
				MUL: begin
                    cmul_re <= out_re;
                    cmul_im <= out_im;
					state_r <= ADDSUB;
				end
				ADDSUB: begin
					state_r <= ACUM;
				end
				ACUM: begin
                    accum_re <= out_re;
                    accum_im <= out_im;
                    zr_o <= out_re;
                    zi_o <= out_im;
					state_r <= IDLE;
					done_o <= 1;
				end
				default: state_r <= IDLE;
			endcase
		end
	end
    
endmodule
