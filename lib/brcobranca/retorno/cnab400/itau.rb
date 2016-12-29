# -*- encoding: utf-8 -*-
#
require 'parseline'

module Brcobranca
  module Retorno
    module Cnab400
      # Formato de Retorno CNAB 400
      # Baseado em: http://download.itau.com.br/bankline/layout_cobranca_400bytes_cnab_itau_mensagem.pdf
      class Itau < Brcobranca::Retorno::Cnab400::Base
        extend ParseLine::FixedWidth # Extendendo parseline

        # Load lines
        def self.load_lines(file, options = {})
          
          default_options = { except: [1] } # por padrao ignora a primeira linha que é header
          options = default_options.merge!(options)
          super file, options
        end

        fixed_width_layout do |parse|
          
         # :agencia, 17..20 #agencia mantenedora da conta
          parse.field :agencia_sem_dv, 17..20 # FIXME - SEM DIV
          
          parse.field :cedente_com_dv, 23..28
          
          # :nosso_numero,62..69 # identificacao do titulo no banco
          parse.field :nosso_numero, 62..69
          
          # :carteira, 107..107 #código da carteira
          parse.field :carteira, 82..84

          parse_field :ocorrencia, 108..109 # código de ocorrencia
          parse_field :data_ocorrencia, 110..115  # data de ocorrencia no banco (ddmmaa)
          
          # :vencimento, 146..151 #data de vencimento do titulo (ddmmaa)
          parse.field :data_vencimento, 146..151

          # :valor_do_titulo, 152..164 #valor nominal do titulo (ultimos 2 digitos, virgula decimal assumida)
          parse.field :valor_titulo, 152..164
          
          # :valor_principal, 253..265 #valor lancado em conta corrente (ultimos 2 digitos, virgula decimal assumida)
          parse.field :valor_pago, 253..265

          # :juros_mora_multa, 266..278 #valor de mora e multa pagos pelo sacado (ultimos 2 digitos, virgula decimal assumida)
          parse.field :juros_mora, 266..278
          
          # :numero_sequencial, 394..399 #numero sequencial no arquivo
          parse.field :sequencial, 394..399
        end
      end
    end
  end
end
