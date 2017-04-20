# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Sicoob do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 22.0,
                                       data_vencimento: Date.current,
                                       nosso_numero: 135369,
                                       documento_sacado: '00007381997614',
                                       nome_sacado: 'FRANCINE FREIRE DE CARVALHO',
                                       endereco_sacado: 'RUA PRIMEIRO DE MARÃO, AO LADO DA UBCNTRO',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '35260000',
                                       cidade_sacado: 'CENTRAL DE MINA',
                                       uf_sacado: 'MG')
  end
  let(:params) do
    { carteira: '01',
      agencia: '3027',
      conta_corrente: '00027377',
      digito_conta: '5',
      convenio: '94870',
      empresa_mae: 'E SANTOS SOUZA - PROVEDOR DE I',
      documento_cedente: '01980276560,',
      pagamentos: [pagamento] }
  end
  let(:sicoob) { subject.class.new(params) }

  context 'validacoes dos campos' do
    context '@agencia' do
      it 'deve ser invalido se nao possuir uma agencia' do
        objeto = subject.class.new(params.merge!(agencia: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        sicoob.agencia = '12345'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@digito_conta' do
      it 'deve ser invalido se nao possuir um digito da conta corrente' do
        objeto = subject.class.new(params.merge!(digito_conta: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Digito conta não pode estar em branco.')
      end

      it 'deve ser invalido se a carteira tiver mais de 1 digito' do
        sicoob.digito_conta = '12'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Digito conta deve ter 1 dígito.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se nao possuir uma conta corrente' do
        objeto = subject.class.new(params.merge!(conta_corrente: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Conta corrente não pode estar em branco.')
      end

      it 'deve ser invalido se a conta corrente tiver mais de 8 digitos' do
        sicoob.conta_corrente = '123456789'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Conta corrente deve ter 8 dígitos no máximo.')
      end
    end

    context '@carteira' do
      it 'deve ser invalido se nao possuir uma carteira' do
        objeto = subject.class.new(params.merge!(carteira: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Carteira não pode estar em branco.')
      end

      it 'deve ser invalido se a carteira tiver mais de 1 digito' do
        sicoob.carteira = '123'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Carteira deve ter 2 dígitos no máximo.')
      end
    end

    context '@sequencial_remessa' do
      it 'deve ser invalido se nao possuir um num. sequencial de remessa' do
        objeto = subject.class.new(params.merge!(sequencial_remessa: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Sequencial remessa não pode estar em branco.')
      end

      it 'deve ser invalido se sequencial de remessa tiver mais de 7 digitos' do
        sicoob.sequencial_remessa = '12345678'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Sequencial remessa deve ter 7 dígitos.')
      end
    end

    context '@convenio' do
      it 'deve ser invalido se nao possuir um convenio' do
        objeto = subject.class.new(params.merge!(convenio: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Convenio não pode estar em branco.')
      end

      it 'deve ser invalido se convenio tiver mais de 9 digitos' do
        sicoob.convenio = '1234567890'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Convenio não deve ser maior que 7 dígitos.')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 756' do
      expect(sicoob.cod_banco).to eq '756'
    end

    it 'nome_banco deve ser BANCOOBCED com 15 posicoes' do
      nome_banco = sicoob.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'BANCOOBCED'
    end

    it 'complemento deve ter 287 brancos' do
      complemento = sicoob.complemento
      expect(complemento.size).to eq 287
    end

    it 'info_conta deve ter 20 posicoes' do
      expect(sicoob.info_conta.size).to eq 20
    end

    it 'identificacao da empresa deve ter as informacoes nas posicoes corretas' do
      id_empresa = sicoob.info_conta
      expect(id_empresa[0..3]).to eq '3027' # agencia
      expect(id_empresa[4]).to eq '9' # digito_agencia
      expect(id_empresa[5..13]).to eq '000094870' # convenio
      expect(id_empresa[14..19]).to eq '      ' # brancos
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = sicoob.monta_header
        expect(header[1]).to eq '1' # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA' # literal da operacao
         expect(header[11..18]).to eq 'COBRANÇA' # literal da operacao
        expect(header[26..45]).to eq sicoob.info_conta # informacoes da conta
        expect(header[76..78]).to eq '756' # codigo do banco
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = sicoob.monta_detalhe pagamento, 1
        expect(detalhe[62..72]).to eq '00000135369' # nosso numero
        expect(detalhe[73]).to eq '4' # digito nosso numero
        expect(detalhe[74..75]).to eq '01' # parcela
        expect(detalhe[120..125]).to eq Date.current.strftime('%d%m%y') # data de vencimento
        expect(detalhe[126..138]).to eq '0000000002200' # valor do documento
        expect(detalhe[220..233]).to eq '00007381997614' # documento do pagador
        expect(detalhe[234..273].strip).to eq 'FRANCINE FREIRE DE CARVALHO' # nome do pagador
        expect(detalhe[274..310].strip).to eq 'RUA PRIMEIRO DE MARAO, AO LADO DA UBC' # endereco do pagador
      end
    end

    #context 'arquivo' do
    #  before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
    #  after { Timecop.return }

      #it { expect(sicoob.gera_arquivo).to eq(read_remessa('remessa-sicoob-cnab400.rem', sicoob.gera_arquivo)) }
    #end
  end
end
