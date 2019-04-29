/*
Implementação da Tabela de Predição
*/

`ifndef _table
`define _table

module PredictionTable(input clk, input [31:0] pc4, baddr_s2, pc4_s2, input WRt, WRp, C, output H, P, output [31:0] Target);
reg [59:0] memory[0:15];//Inicializa memória com 16 linhas e 59 bits por linha
wire [59:0] line_value;
wire [25:0] tag;
reg H,P;
reg [31:0] Target;
wire [1:0] ValorPredicao;

parameter TABELA = "tabela.txt";  // Arquivo para inicializar tabela
initial begin
	$readmemh(TABELA, memory, 0, 15);
end

assign line_value = memory[pc4[5:2]];//Acessa uma linha da memória para verificação
assign tag = line_value[59:34];//Pega a TAG que está registrada nessa linha
assign ValorPredicao = line_value[33:32];

always @(posedge clk ) begin
    if (WRt && WRp)//Se não estava registrado o BEQ...
        case(C)
            1'b0: memory[pc4_s2[5:2]] <= {pc4_s2[31:6],2'b01,baddr_s2};//Grava na linha da memória os novos valores, sendo eles: TAG, predição e endereço para desvio
            1'b1: memory[pc4_s2[5:2]] <= {pc4_s2[31:6],2'b10,baddr_s2};
        endcase
    else if(WRp)//Se estava registrado, mas errou na predição...
        case(ValorPredicao)
            2'b11: if(C==0) memory[pc4_s2[5:2]][33:32] <= 2'b10;
            2'b10: if(C==1) memory[pc4_s2[5:2]][33:32] <= 2'b11;
                   else memory[pc4_s2[5:2]][33:32] <= 2'b01;
            2'b01: if(C==1) memory[pc4_s2[5:2]][33:32] <= 2'b10;
                   else memory[pc4_s2[5:2]][33:32] <= 2'b00;
            2'b00: if(C==1) memory[pc4_s2[5:2]][33:32] <= 2'b01;
        endcase
end

always @ (*) begin
  if(tag == pc4[31:6]) /* Se a TAG da linha é a mesma de PC + 4*/begin
    H <= 1'b1;//Deu HIT!
    P <= line_value[33];//Verifica a predição
    Target <= line_value[31:0];//Manda o endereço para desviar na Busca
  end
  else
    H <= 1'b0;//Caso não encontrou a TAG na tabela. Os valores de P e Target não importam
end



endmodule

`endif
