# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Retorno::Cnab400::Itau do
  before do
    @arquivo = File.join(File.dirname(__FILE__), '..', '..', '..', 'arquivos', 'CNAB400ITAU.RET')
  end

  it 'Ignora primeira linha que é header' do
    pagamentos = described_class.load_lines(@arquivo)
    pagamento = pagamentos.first
    expect(pagamento.sequencial).to eql('000002')
  end

  it 'Transforma arquivo de retorno em objetos de retorno retornando somente as linhas de pagamentos de títulos sem registro' do
    pagamentos = described_class.load_lines(@arquivo)
    expect(pagamentos.size).to eq(53) # deve ignorar a primeira linha que é header
    pagamento = pagamentos.first
    expect(pagamento.agencia_sem_dv).to eql('0730')
    expect(pagamento.cedente_com_dv).to eql('035110')
    expect(pagamento.nosso_numero).to eql('00000011')
    expect(pagamento.carteira).to eql('109')
    expect(pagamento.data_vencimento).to eql('000000')
    expect(pagamento.valor_titulo).to eql('0000000004000')
    expect(pagamento.valor_pago).to eql('0000000003790')
    expect(pagamento.sequencial).to eql('000002')
  end
end
