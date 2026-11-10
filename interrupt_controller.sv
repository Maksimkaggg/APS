module interrupt_controller(
  input  logic              clk_i,
  input  logic              rst_i,
  input  logic        exception_i,
  input  logic          irq_req_i,
  input  logic              mie_i,
  input  logic             mret_i,

  output logic          irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic              irq_o
);

assign irq_cause_o = 32'h8000_0010;

//reg exc_h
logic   set_exc;
logic     exc_h;
logic reset_exc;
logic    in_exc;

assign in_exc    = set_exc & ~reset_exc;
assign set_exc   =  exception_i | exc_h;
assign reset_exc =               mret_i;

always_ff @(posedge clk_i) begin
	if(rst_i) begin
		exc_h <=     '0;
	end
	else begin
		exc_h <= in_exc;
	end
end

//irq_ret_o
assign irq_ret_o = mret_i & ~set_exc;


// reg irq_h
logic   set_irq;
logic     irq_h;
logic    in_irq;

assign set_irq   =        irq_o | irq_h;
assign in_irq =    ~irq_ret_o & set_irq;


always_ff @(posedge clk_i) begin
	if(rst_i) begin
		irq_h <=      '0;
	end
	else begin
		irq_h <=  in_irq;
	end
end


assign irq_o = (irq_req_i & mie_i) & ~(set_exc | irq_h);



endmodule