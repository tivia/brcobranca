# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    module Cnab400
      class Caixa < Brcobranca::Remessa::Cnab400::Base
        validates_presence_of :agencia, message: 'não pode estar em branco.'
        validates_presence_of :documento_cedente, message: 'não pode estar em branco.'
        validates_length_of :agencia, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :codigo_beneficiario, maximum: 6, message: 'deve ter 6 dígitos.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :carteira, maximum: 2, message: 'deve ter no máximo 2 dígitos.'
        
        attr_accessor :codigo_beneficiario
        
        def initialize(campos = {})
          campos = { aceite: 'N' }.merge!(campos)
          super(campos)
        end
        
        def finalizador
        
          "\n"
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def codigo_beneficiario=(valor)
          @codigo_beneficiario = valor.to_s.rjust(6, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(2, '0') if valor
        end
        
        def sequencial_remessa=(valor)
          @sequencial_remessa = valor.to_s.rjust(5, '0')
        end

        def cod_banco
          '104'
        end

        def nome_banco
          'C ECON FEDERAL'.ljust(15, ' ')
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO            TAMANHO
          # agencia          4
          # complemento      2
          # conta corrente   5
          # digito da conta  1
          # complemento      8
          "#{agencia}#{codigo_beneficiario}#{''.rjust(10, ' ')}"
        end

        # Complemento do header
        # (no caso do Itau, sao apenas espacos em branco)
        #
        # @return [String]
        #
        def complemento
          "#{''.rjust(289, ' ')}#{sequencial_remessa}"
        end
        
        # Detalhe do arquivo
        #
        # @param pagamento [PagamentoCnab400]
        #   objeto contendo as informacoes referentes ao boleto (valor, vencimento, cliente)
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #
        def monta_detalhe(pagamento, sequencial)
            raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

            detalhe = '1'                                                     # identificacao transacao               9[01]
            detalhe << Brcobranca::Util::Empresa.new(documento_cedente).tipo  # tipo de identificacao da empresa      9[02]
            detalhe << documento_cedente.to_s.rjust(14, '0')                  # cpf/cnpj da empresa                   9[14]
            detalhe << agencia                                                # agencia                               9[04]
            detalhe << codigo_beneficiario                                    # codigo do beneficiario                9[06]
            detalhe << '2'                                                    # Identificação de emissão do boleto    9[01]
            detalhe << '0'                                                    # Identificação da Entrega/Distrib.     9[01]
            detalhe << '00'                                                   # Comissão de Permanência               9[02]
            detalhe << pagamento.numero_documento.to_s.rjust(25, '0')         # Identificação do Título na Empresa    X[25]
            detalhe << '14'                                                   # Modalidade do Nosso Numero            9[02]
            detalhe << pagamento.nosso_numero.to_s.rjust(15, '0')             # Nosso numero                          9[15]
            detalhe << ''.rjust(3, ' ')                                        # preenchimneto em branco               X[03]
            detalhe << ''.rjust(30, ' ')                                       # mensagem no boleto                    X[30]
            detalhe << carteira                                               # carteira                              9[02]
            detalhe << '01'                                                   # codigo de ocorrencia                  9[02]
            detalhe << pagamento.numero_documento.to_s.rjust(10, '0')           # numero da cobranca                    X[10]
            detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    9[06]
            detalhe << pagamento.formata_valor                                # valor do documento                    9[13]
            detalhe << cod_banco                                              # banco de compensacao                  9[03]
            detalhe << ''.rjust(5, '0')                                       # agencia cobradora                     9[05]
            detalhe << '01'                                                   # especie  do titulo                    X[02]
            detalhe << aceite                                                 # aceite (A/N)                          X[01]
            detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       9[06]
            detalhe << '02'                                                   # 1a instrucao - deixar zero            X[02]
            detalhe << ''.rjust(2, '0')                                       # 2a instrucao - deixar zero            X[02]
            detalhe << pagamento.formata_valor_mora                           # valor mora ao dia                     9[13]
            detalhe << pagamento.formata_data_desconto                        # data limite para desconto             9[06]
            detalhe << pagamento.formata_valor_desconto                       # valor do desconto                     9[13]
            detalhe << pagamento.formata_valor_iof                            # valor do iof                          9[13]
            detalhe << pagamento.formata_valor_abatimento                     # valor do abatimento                   9[13]
            detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02]
            detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # documento do pagador                  9[14]
            detalhe << pagamento.nome_sacado.format_size(40)                  # nome do pagador                       X[30]
            detalhe << pagamento.endereco_sacado.format_size(40)              # endereco do pagador                   X[40]
            detalhe << pagamento.bairro_sacado.format_size(12)                # bairro do pagador                     X[12]
            detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
            detalhe << pagamento.cidade_sacado.format_size(15)                # cidade do pagador                     X[15]
            detalhe << pagamento.uf_sacado                                    # uf do pagador                         X[02]  
            detalhe << pagamento.formata_data_multa                           # data para pagamento de multa          9[06] 
            detalhe << pagamento.formata_valor_multa_em_reais                 # valor da multa                        9[10]
            detalhe << pagamento.nome_avalista.format_size(22)                # nome do sacador/avalista              X[22]
            detalhe << ''.rjust(2, '0')                                       # 3a instrucao - deixar zero            X[02]
            detalhe << '60'                                                   # Núm. dias p/ início do prot./ dev     9[02]
            detalhe << '1'                                                    # codigo da moeda                       9[01]    
            detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06]
            detalhe.to_ascii
        end
        
        def monta_detalhe_multa(pagamento, sequencial)
          nil
        end
      end
    end
  end
end
