# -*- encoding: utf-8 -*-
#
require 'parseline'

module Brcobranca
  module Retorno
    module Cnab400
      # Formato de Retorno CNAB 400
      class Sicredi < Brcobranca::Retorno::Cnab400::Base
        extend ParseLine::FixedWidth # Extendendo parseline

        # Load lines
        def self.load_lines(file, options = {})
          default_options = { except: [1] } # por padrao ignora a primeira linha que é header
          options = default_options.merge!(options)
          super file, options
        end

        fixed_width_layout do |parse|
          parse.field :carteira, 13..13
          parse.field :byte_idt, 49..49
          parse.field :nosso_numero, 50..54
          parse.field :ocorrencia, 108..109
          parse.field :data_ocorrencia, 110..115
          parse.field :valor_titulo, 152..164
          parse.field :valor_pago, 253..265
          parse.field :sequencial, 394..399
        end
      end
    end
  end
end
