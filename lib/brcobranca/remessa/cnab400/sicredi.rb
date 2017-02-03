# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    module Cnab400
      class Sicredi < Brcobranca::Remessa::Cnab400::Base
        attr_accessor :posto, :byte_idt, :convenio
        validates_presence_of :agencia, :conta_corrente, :convenio, :sequencial_remessa, :documento_cedente, message: 'não pode estar em branco.'
        # Remessa 400 - 8 digitos
        # Remessa 240 - 12 digitos
        validates_length_of :conta_corrente, is: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :convenio, is: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :agencia, is: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :posto, is: 2, message: 'deve ter 2 dígitos.'
        validates_length_of :byte_idt, is: 1, message: 'deve ter 1 dígito.'
        validates_length_of :sequencial_remessa, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        
        def initialize(campos = {})
          campos = {
            sequencial_remessa: '0000001'
          }.merge!(campos)
          super(campos)
        end
        
        def versao
          '2.00'
        end
        
        def data_geracao
          Date.current.strftime('%Y%m%d')
        end
        
        def convenio=(valor)
          @convenio = valor.to_s.rjust(5, '0') if valor
        end

        def cod_banco
          '748'
        end

        def nome_banco
          'SICREDI'.ljust(15, ' ')
        end
        
        def info_conta
          "#{convenio.to_s.rjust(5,'0')}#{documento_cedente.to_s.rjust(14,'0')}#{''.rjust(31, ' ')}"
        end
        
        def data_geracao
          Date.current.strftime('%Y%m%d')
        end

        # Complemento do header
        #
        # @return [String]
        #
        def complemento
          ''.rjust(273, ' ')
        end

        # Header do arquivo remessa
        #
        # @return [String]
        #
        def monta_header
          "01REMESSA01#{'COBRANCA'.format_size(15)}#{info_conta}#{cod_banco}#{nome_banco}#{data_geracao}#{''.rjust(8, ' ')}#{sequencial_remessa.to_s.rjust(7, '0')}#{complemento}#{versao}000001"
        end
        
        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                                     # identificacao transacao               9[01]
          detalhe << (carteira == "1" ? 'A' : 'C')                          # Tipo de cobrança     A - Com Registro X[01]                 
          detalhe << 'A'                                                    # Tipo de carteira  A - Simples         X[01]
          detalhe << 'A'                                                    # Tipo de impressao A - Normal          X[01]
          detalhe << ''.rjust(12, ' ')                                      # Espaço em branco                      X[12]  
          detalhe << 'A'                                                    # Tipo de Moeda    A - Real             X[01]
          detalhe << 'B'                                                    # Tipo de Desconto B - Percentural      X[01]
          detalhe << 'B'                                                    # Tipo de Juros    B - Percentural      X[01]
          detalhe << ''.rjust(28, ' ')                                      # Espaço em branco                      X[28]
          detalhe << nosso_numero(pagamento)                                # Nosso Numero                          9[09]
          detalhe << ''.rjust(6, ' ')                                       # Espaço em branco                      X[06]
          detalhe << pagamento.data_emissao.strftime('%Y%m%d')              # Data da instrução                     9[08]
          detalhe << ''.rjust(1, ' ')                                       # Espaço em branco                      X[01]
          detalhe << 'N'                                                    # Postagem do título                    X[01] “N” - Não postar e remeter o título para o beneficiário 
          detalhe << ''.rjust(1, ' ')                                       # Espaço em branco                      X[01]
          detalhe << 'B'                                                    # Emissão do Boleto   B - Beneficiario  X[01]
          detalhe << ''.rjust(2, ' ')                                       # Numero da parcela do carne            9[02]
          detalhe << ''.rjust(2, ' ')                                       # Numero do total sw parcelas no carne  9[02]
          detalhe << ''.rjust(4, ' ')                                       # Espaço em branco                      X[04]
          detalhe << ''.rjust(10, '0')                                      # Valor de desc. por dia de antecipação 9[10]
          detalhe << pagamento.formata_valor_multa(4)                       # % multa por pagamento em atraso       9[04]
          detalhe << ''.rjust(12, ' ')                                      # Espaço em branco                      X[12]
          detalhe << '01'                                                   # Instrução                             9[02]
          detalhe << pagamento.numero_documento.to_s.rjust(10, '0')         # Seu numero                            9[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    9[06]
          detalhe << pagamento.formata_valor                                # valor do documento                    9[13]
          detalhe << ''.rjust(9, ' ')                                       # Espaço em branco                      X[12]
          detalhe << 'A'                                                    # Especie de Documento                  X[01]  A -Duplicata Mercantil por Indicação
          detalhe << 'N'                                                    # aceite N - Não                        X[01]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       9[06]
          detalhe << ''.rjust(2, '0')                                       # Instrução de protesto automático      9[02]
          detalhe << ''.rjust(2, '0')                                       # Número de dias p/protesto automático  9[02]
          detalhe << pagamento.formata_valor_mora                           # Valor/% de juros por dia de atras     9[13]
          detalhe << ''.rjust(6, '0')                                       # Data limite p/concessão de desconto   9[06]
          detalhe << ''.rjust(13, '0')                                      # Valor/% do desconto                   9[13]
          detalhe << ''.rjust(13, '0')                                      # Espaço em branco                      X[13]
          detalhe << ''.rjust(13, '0')                                      # Valor do abatimento                   X[13]
          detalhe << Brcobranca::Util::Empresa.new(pagamento.documento_sacado, false).tipo  # tipo de identificacao da empresa      9[01]
          detalhe << ''.rjust(1, '0')                                       # Zero                                  X[01]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # Documento do sacado                   9[14]
          detalhe << pagamento.nome_sacado.format_size(40).ljust(40, ' ')   # nome do pagador                       X[40]
          detalhe << pagamento.endereco_sacado.format_size(40).ljust(40, ' ') # endereco do pagador                 X[40]
          detalhe << ''.rjust(5, '0')                                       # Código do pagador na coop. benefi     X[05]
          detalhe << ''.rjust(6, '0')                                       # Zeros                                 9[06]
          detalhe << ''.rjust(1, ' ')                                       # Espaço em branco                      X[01]
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
          detalhe << ''.rjust(5, '0')                                       # Código do pagador junto ao cliente    X[05]
          detalhe << ''.rjust(14, ' ')                                      # Doc. do Sacador/Avalista              X[14]
          detalhe << ''.rjust(41, ' ')                                      # Nome do Sacador/Avalista              X[14]
          detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06]
          detalhe
        end
        
        def monta_detalhe_multa(pagamento, sequencial)
          nil
        end
  
        def monta_trailer(sequencial)
          "91748#{convenio}#{''.rjust(384, ' ')}#{sequencial.to_s.rjust(6, '0')}"
        end
        
        private
        
        def nosso_numero(pagamento)
          "#{numero_documento_com_byte_idt(pagamento)}#{nosso_numero_dv(pagamento)}"
        end
        
        def numero_documento_com_byte_idt(pagamento)
          "#{pagamento.data_emissao.strftime('%y')}#{byte_idt}#{pagamento.nosso_numero}"
        end
        def nosso_numero_dv(pagamento)
          "#{agencia_posto_conta}#{numero_documento_com_byte_idt(pagamento)}".modulo11(mapeamento: mapeamento_para_modulo_11)
        end
        
        def agencia_posto_conta
          "#{agencia}#{posto}#{convenio}"
        end
        
        def mapeamento_para_modulo_11
          {
            10 => 0,
            11 => 0
          }
        end
      end
    end
  end
end
