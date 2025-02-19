#
require 'active_support/core_ext/string/filters'
require 'active_support/inflector/transliterate'

module Brcobranca
  # Métodos auxiliares de formatação de strings
  module FormatacaoString
    # Formata o tamanho da string
    # para o tamanho passado
    # se a string for menor, adiciona espacos a direita
    # se a string for maior, trunca para o num. de caracteres
    #
    def format_size(size)
      if self.size > size
        ActiveSupport::Inflector.transliterate(truncate(size, omission: ''))
      else
        ActiveSupport::Inflector.transliterate(ljust(size, ' '))
      end
    end

    def truncate(truncate_at)
      return dup unless length > truncate_at

      (self[0, truncate_at]).to_s
    end

    def remove_accents
      tr(
        'ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž',
        'AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz'
      )
    end
  end
end

[String].each do |klass|
  klass.class_eval { include Brcobranca::FormatacaoString }
end
