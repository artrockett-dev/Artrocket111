# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'
require 'csv'
require 'cgi'
require 'su_dynamiccomponents' rescue require 'dynamiccomponents'

class DCFunctionsV1
  DEBUG = false

  unless method_defined?(:includes)
    protected

    def _dbg(msg)
      puts(msg) if DEBUG
    end

    # нормализация текста (Юникод: буквы/цифры остаются)
    def _norm(str)
      str.to_s.downcase
          .gsub(/%20/i, ' ')
          .tr('_-', '  ')
          .gsub(/[^\p{L}\p{N} ]/u, ' ')
          .squeeze(' ')
          .strip
    end

    # CSV-split
    def _split_args(line)
      csv_line = line.to_s.tr(';', ',')
      CSV.parse_line(csv_line, col_sep: ',', quote_char: '"')
         &.map { |s| s.to_s.strip.gsub(/\A['"]|['"]\z/, '') }
    rescue
      nil
    end

    # основная функция INCLUDES
    def includes(args)
      _dbg "\n— INCLUDES raw args: #{args.inspect}"

      # 1) разобрать аргументы
      if args.size > 4
        raw_src = args[0]
        key     = args[1]
        yes_v   = args[2..-2].join(',')
        no_v    = args[-1]
      elsif args.size == 1 && args[0].is_a?(String) && args[0][/[,;]/]
        raw_src, key, yes_v, no_v = _split_args(args[0]) || []
      else
        raw_src = args[0]
        key     = args[1]
        yes_v   = args[2] || '1'
        no_v    = args[3] || '0'
      end
      key ||= ''
      _dbg "  parsed → value=#{raw_src.inspect}, key=#{key.inspect}, yes=#{yes_v.inspect}, no=#{no_v.inspect}"

      # 2) если raw_src выглядит как имя атрибута — читаем его значение
      if raw_src.is_a?(String) && raw_src =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
        val = @source_entity.get_attribute('dynamic_attributes', raw_src, nil)
        _dbg "  attr lookup #{raw_src} → #{val.inspect}"
        raw_src = val unless val.nil?
      end

      # 3) нормализация
      src_norm = _norm(raw_src)
      key_norm = _norm(key)
      words    = key_norm.split(' ')
      _dbg "  norm value='#{src_norm}', key='#{key_norm}', words=#{words}"

      # 4) поиск
      found =
        if key_norm.empty?
          false
        elsif src_norm.include?(key_norm)
          true
        else
          words.all? { |w| src_norm.include?(w) }
        end
      _dbg "  FOUND? #{found}"

      # 5) результат
      result = found ? yes_v : no_v
      result = CGI.unescape(result.to_s) if result.is_a?(String) && result.include?('%')
      result = result.to_f if result.to_s =~ /\A-?\d+(?:\.\d+)?\z/
      _dbg "  → return #{result.inspect}"
      result

    rescue => e
      puts "!! INCLUDES ERROR: #{e.class}: #{e.message}\n#{e.backtrace.first}"
      0
    end
  end
end

# Неблокирующее уведомление можно оставить в логах, без messagebox:
UI.start_timer(1, false) do
  unless defined?(::Sketchup) && (defined?($dc_observers) || defined?(DCObserver) || Object.const_defined?(:DCFunctionsV1))
    puts '[INCLUDES] Dynamic Components not detected — the function may not be callable.'
  end
end
