# -*- encoding: utf-8 -*-
#

require_relative '../../../spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Sicredi do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.current,
                                       nosso_numero: '09394',
                                       documento_sacado: '12345678901',
                                       nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                                       endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'Santa rita de cássia maria da silva',
                                       uf_sacado: 'SP')
  end
  let(:params) do
    { agencia: '0306',
      conta_corrente: '78817',
      convenio: '78817',
      carteira: 'A',
      empresa_mae: 'LIGNET',
      documento_cedente: '06153965000109',
      posto: '05',
      byte_idt: '4',
      pagamentos: [pagamento] }
  end
  let(:sicredi) { subject.class.new(params) }

  context 'validacoes dos campos' do
    context '@agencia' do
      it 'deve ser invalido se nao possuir uma agencia' do
        objeto = subject.class.new(params.merge!(agencia: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        sicredi.agencia = '12345'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se nao possuir uma conta corrente' do
        objeto = subject.class.new(params.merge!(conta_corrente: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Conta corrente não pode estar em branco.')
      end

      it 'deve ser invalido se a conta corrente tiver mais de 5 digitos' do
        sicredi.conta_corrente = '123456789'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Conta corrente deve ter 5 dígitos.')
      end
    end
    
    context '@sequencial_remessa' do
      it 'deve ser invalido se nao possuir um num. sequencial de remessa' do
        objeto = subject.class.new(params.merge!(sequencial_remessa: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Sequencial remessa não pode estar em branco.')
      end

      it 'deve ser invalido se sequencial de remessa tiver mais de 7 digitos' do
        sicredi.sequencial_remessa = '12345678'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Sequencial remessa deve ter 7 dígitos.')
      end
    end

    context '@convenio' do
      it 'deve ser invalido se nao possuir um convenio' do
        objeto = subject.class.new(params.merge!(convenio: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Convenio não pode estar em branco.')
      end

      it 'deve ser invalido se convenio tiver mais de 5 digitos' do
        sicredi.convenio = '1234567890'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Convenio deve ter 5 dígitos.')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 748' do
      expect(sicredi.cod_banco).to eq '748'
    end

    it 'nome_banco deve ser Sicredi com 15 posicoes' do
      nome_banco = sicredi.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'SICREDI'
    end

    it 'complemento deve ter 273 brancos' do
      complemento = sicredi.complemento
      expect(complemento.size).to eq 273
    end

    it 'info_conta deve ter 50 posicoes' do
      expect(sicredi.info_conta.size).to eq 50
    end

    it 'identificacao da empresa deve ter as informacoes nas posicoes corretas' do
      id_empresa = sicredi.info_conta
      expect(id_empresa[0..4]).to eq '78817' # codigo do beneficiario
      expect(id_empresa[5..18]).to eq '06153965000109' # digito_agencia
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = sicredi.monta_header
        expect(header[1]).to eq '1' # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA' # literal da operacao
        expect(header[26..75]).to eq sicredi.info_conta # informacoes da conta
        expect(header[76..78]).to eq '748' # codigo do banco
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = sicredi.monta_detalhe pagamento, 1
        expect(detalhe[47..55]).to eq '174093944' # nosso numero
        expect(detalhe[120..125]).to eq Date.current.strftime('%d%m%y') # data de vencimento
        expect(detalhe[126..138]).to eq '0000000019990' # valor do documento
        expect(detalhe[220..233]).to eq '00012345678901'  # documento do pagador
        expect(detalhe[234..273]).to eq 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN' # nome do pagador
        expect(detalhe[274..313]).to eq 'RUA RIO GRANDE DO SUL Sao paulo Minas ca' # endereco do pagador
      end
    end

    # context 'arquivo' do
    #   before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
    #   after { Timecop.return }

    #   it { expect(sicredi.gera_arquivo).to eq(read_remessa('remessa-sicredi-cnab400.rem', sicredi.gera_arquivo)) }
    # end
  end
end
