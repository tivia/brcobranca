# -*- encoding: utf-8 -*-
#
require 'parseline'

module Brcobranca
  module Retorno
    module Cnab400
      # Formato de Retorno CNAB 400
      class Caixa < Brcobranca::Retorno::Cnab400::Base
        extend ParseLine::FixedWidth # Extendendo parseline

        # Load lines
        def self.load_lines(file, options = {})
          default_options = { except: [1] } # por padrao ignora a primeira linha que é header
          options = default_options.merge!(options)
          super file, options
        end

        fixed_width_layout do |parse|
          parse.field :agencia_sem_dv, 17..20 # 
          
          # :dac, 28..28 #digito de auto conferencia ag/conta empresa
          parse.field :convenio, 21..26
          
          # :nosso_numero,62..69 # identificacao do titulo no banco
          parse.field :nosso_numero, 58..74
          
          # :carteira, 107..107 #código da carteira
          parse.field :carteira, 106..107

          parse.field :ocorrencia, 108..109 # código de ocorrencia
          
          parse.field :data_ocorrencia, 110..115  # data de ocorrencia no banco (ddmmaa) # data de ocorrencia no banco (ddmmaa)
          
          parse.field :data_vencimento, 146..151 
          
          # :valor_do_titulo, 152..164 #valor nominal do titulo (ultimos 2 digitos, virgula decimal assumida)
          parse.field :valor_titulo, 152..164
          
          # :valor_principal, 253..265 #valor lancado em conta corrente (ultimos 2 digitos, virgula decimal assumida)
          parse.field :valor_pago, 253..265

          # :juros_mora_multa, 266..278 #valor de mora e multa pagos pelo sacado (ultimos 2 digitos, virgula decimal assumida)
          parse.field :juros_mora, 266..278
          
          # :juros_mora_multa, 266..278 #valor de mora e multa pagos pelo sacado (ultimos 2 digitos, virgula decimal assumida)
          parse.field :valor_multa, 279..291
          
          parse.field :sequencial, 394..399
        end
      end
    end
  end
end
