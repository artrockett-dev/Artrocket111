# encoding: UTF-8
# Plugins/ar_addons/ar_functions/main
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.


module ARAddons
  module ARFunctions
    DEBUG = false
    module_function

    def log(msg)
      puts "[ARFunctions] #{msg}" if DEBUG
    end

    # Пытаемся убедиться, что Dynamic Components подгружены до функций.
    # Это внешнее расширение — грузим через стандартный require.
    def ensure_dc_loaded
      return true if defined?(DCFunctionsV1)
      begin
        require 'su_dynamiccomponents'
      rescue LoadError
        begin
          require 'dynamiccomponents' # без .rb — так же корректно
        rescue LoadError
          log 'Dynamic Components not found (continue anyway)'
          return false
        end
      end
      defined?(DCFunctionsV1)
    end

    def load_functions!
      ensure_dc_loaded

      dir = __dir__
      # Берём только файлы в ТЕКУЩЕЙ папке, без подпапок.
      # Разрешаем .rb, .rbe, .rbs. main.* пропускаем.
      Dir.glob(File.join(dir, '*')).sort.each do |path|
        next unless File.file?(path)
        base = File.basename(path)
        next if base =~ /\Amain\.(rb|rbe|rbs)?\z/i
        next unless base =~ /\.(rb|rbe|rbs)\z/i

        load_base = path.sub(/\.(rb|rbe|rbs)\z/i, '') # убираем расширение
        begin
          Sketchup.require(load_base)
          log "loaded function file: #{base}"
        rescue LoadError => e
          log "SKIP #{base}: #{e.class}: #{e.message}"
        rescue => e
          log "ERROR in #{base}: #{e.class}: #{e.message}"
          puts e.backtrace.first(8).join("\n") if DEBUG
        end
      end

      # Короткий отчёт о наличии DCFunctionsV1 после загрузки
      if defined?(DCFunctionsV1)
        inst_methods = DCFunctionsV1.instance_methods(false)
        log "DCFunctionsV1 ready; custom methods: #{inst_methods.map(&:to_s).join(', ')}"
      else
        log 'DCFunctionsV1 is not defined (DC extension missing?)'
      end
    end
  end
end

# Грузим все функции при подключении модуля
ARAddons::ARFunctions.load_functions!
