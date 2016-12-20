# -*- encoding: utf-8 -*-
#

require_relative '../../../spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Caixa do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.current,
                                       nosso_numero: 123,
                                       documento_sacado: '12345678901',
                                       nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                                       endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'Santa rita de cássia maria da silva',
                                       uf_sacado: 'SP')
  end
  let(:params) do
    { carteira: '01',
      agencia: '3206',
      codigo_beneficiario: '270272',
      digito_conta: '1',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      documento_cedente: '12345678910',
      pagamentos: [pagamento] }
  end
  let(:caixa) { subject.class.new(params) }

  context 'validacoes dos campos' do
    context '@agencia' do
      it 'deve ser invalido se nao possuir uma agencia' do
        object = subject.class.new(params.merge!(agencia: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        caixa.agencia = '12345'
        expect(caixa.invalid?).to be true
        expect(caixa.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end
    
    context '@carteira' do
      it 'deve ser invalido se nao possuir uma carteira' do
        object = subject.class.new(params.merge!(carteira: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Carteira não pode estar em branco.')
      end

      it 'deve ser invalido se a carteira tiver mais de 2 digitos' do
        caixa.carteira = '011'
        expect(caixa.invalid?).to be true
        expect(caixa.errors.full_messages).to include('Carteira deve ter no máximo 2 dígitos.')
      end
    end

    context '@documento_cedente' do
      it 'deve ser invalido se nao possuir o documento cedente' do
        object = subject.class.new(params.merge!(documento_cedente: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Documento cedente não pode estar em branco.')
      end

      it 'deve ser invalido se o documento do cedente nao tiver entre 11 e 14 digitos' do
        caixa.documento_cedente = '123'
        expect(caixa.invalid?).to be true
        expect(caixa.errors.full_messages).to include('Documento cedente deve ter entre 11 e 14 dígitos.')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 104' do
      expect(caixa.cod_banco).to eq '104'
    end

    it 'nome_banco deve ser C ECON FEDERAL com 15 posicoes' do
      nome_banco = caixa.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'C ECON FEDERAL'
    end

    it 'complemento deve retornar 294 caracteres' do
      expect(caixa.complemento.size).to eq 294
    end

    it 'info_conta deve retornar com 20 posicoes as informacoes da conta' do
      info_conta = caixa.info_conta
      expect(info_conta.size).to eq 20
      expect(info_conta[0..3]).to eq '3206' # num. da agencia
      expect(info_conta[4..9]).to eq '270272' # num. da conta
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = caixa.monta_header
        expect(header[1]).to eq '1' # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA' # literal da operacao
        expect(header[26..45]).to eq caixa.info_conta # informacoes da conta
        expect(header[76..78]).to eq '104' # codigo do banco
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = caixa.monta_detalhe pagamento, 1
        expect(detalhe[58..72]).to eq '000000000000123' # nosso numero
        expect(detalhe[120..125]).to eq Date.current.strftime('%d%m%y') # data de vencimento
        expect(detalhe[126..138]).to eq '0000000019990' # valor do titulo
        expect(detalhe[142..146]).to eq '00000' # agência cobradora
        expect(detalhe[156..157]).to eq '00' # instrução 1
        expect(detalhe[158..159]).to eq '00' # instrução 2
        expect(detalhe[220..233]).to eq '00012345678901' # documento do pagador
        expect(detalhe[234..273]).to eq 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN' # nome do pagador
      end
    end

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(caixa.gera_arquivo).to eq(read_remessa('remessa-caixa-cnab400.rem', caixa.gera_arquivo)) }
    end
  end
end
