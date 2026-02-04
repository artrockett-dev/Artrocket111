# encoding: UTF-8
# ar_startup/bridge — мост языка + работа с parameters.dat/.txt
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'json'
require 'fileutils'

module ARAddons
  module ARStartup
    module Reader
      SUPPORTED   = %w[en ro ru].freeze
      LOCALE_MAP  = { 'en' => 'en-EN', 'ro' => 'ro-RO', 'ru' => 'ru-RU' }.freeze
      FILENAME_CANDIDATES = ['parameters.dat', 'parameters.txt'].freeze
      LANGUAGE_SELECT_ORDER = [
        ['ro-RO', 'Română'],
        ['ru-RU', 'Русский'],
        ['en-EN', 'English']
      ].freeze

      # Валюты
      FX_ALLOWED = %w[MDL EUR USD RON].freeze
      FX_SYMBOL  = { 'MDL' => 'MDL', 'EUR' => 'EUR', 'USD' => 'USD', 'RON' => 'RON' }.freeze

      module_function

      # ---------- utils ----------
      def sanitize(v)
        v.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '').gsub(/[\r\n]+/, '').strip
      end

      # ---------- paths ----------
      def candidate_paths
        la = ENV['LOCALAPPDATA'].to_s
        ra = ENV['APPDATA'].to_s
        bases = []
        bases << File.join(la, 'Temp', 'SUF', 'Default') unless la.empty?
        unless ra.empty?
          app_root = File.expand_path('..', ra)
          bases << File.join(app_root, 'Local', 'Temp', 'SUF', 'Default')
        end
        bases << File.join(Dir.home, 'AppData', 'Local', 'Temp', 'SUF', 'Default')
        paths = []
        bases.uniq.each do |base|
          FILENAME_CANDIDATES.each { |fn| paths << File.join(base, fn) }
        end
        paths.uniq
      end

      def dat_path
        existing = candidate_paths.select { |p| File.file?(p) }
        return nil if existing.empty?
        existing.max_by { |p| File.mtime(p) rescue Time.at(0) }
      end

      def write_target_path
        current = dat_path
        return current if current
        la = ENV['LOCALAPPDATA'].to_s
        base = la.empty? ? File.join(Dir.home, 'AppData', 'Local') : la
        dest = File.join(base, 'Temp', 'SUF', 'Default', 'parameters.dat')
        FileUtils.mkdir_p(File.dirname(dest)) rescue nil
        dest
      end

      # ---------- read ----------
      def read_dat_lines
        path = dat_path
        return [] unless path && File.exist?(path)
        raw = File.binread(path)
        str = begin
          raw.force_encoding('UTF-8')
          raw.valid_encoding? ? raw : raw.encode('UTF-8', 'Windows-1251', invalid: :replace, undef: :replace, replace: '')
        rescue
          raw
        end
        # не сохраняем финальную пустую строку, чтобы не плодить пустые строки при перезаписи
        str.split(/\r?\n/).map { |l| l.encode('UTF-8', invalid: :replace, undef: :replace, replace: '') }
      rescue => e
        puts "[ARStartup] read_dat_lines error: #{e.message}"
        []
      end

      def active_locale_full
        line = read_dat_lines.find { |l| l.lstrip.start_with?('Language=') }
        return nil unless line
        if (m = line.match(/Language\s*=\s*(?:language\s*=)?\s*([a-z]{2})(?:-([A-Za-z]{2}))?/i))
          base = m[1].downcase
          tail = m[2] ? m[2] : base.upcase
          return "#{base}-#{tail}"
        end
        nil
      rescue => e
        puts "[ARStartup] active_locale_full error: #{e.message}"
        nil
      end

      def active_lang_base
        full = active_locale_full
        if full && (m = full.match(/^([a-z]{2})/i))
          base = m[1].downcase
          return base if SUPPORTED.include?(base)
        end
        'ru'
      end

      def cost_coef
        line = read_dat_lines.find { |l| l.include?('cost_coef') }
        return '1.00' unless line
        m = line.match(/cost_coef\s*=\s*([0-9]+(?:[.,][0-9]+)?)/i)
        v = m && m[1]
        v ? v.tr(',', '.') : '1.00'
      rescue => e
        puts "[ARStartup] cost_coef error: #{e.message}"
        '1.00'
      end

      # ---------- FX: read ----------
      # Текущая валюта отображения. Поддерживаются два формата:
      # 1) Новый:  "Валюта=display_currency=EUR=SELECT=&MDL^MDL&EUR^€&USD^$&RON^RON"
      # 2) Старый: "display_currency=EUR"
      def display_currency
        lines = read_dat_lines
        line = lines.find { |l| l.include?('display_currency') }
        return 'EUR' unless line

        if (m = line.match(/display_currency\s*=\s*([A-Z]{3})(?:\s*=\s*SELECT)?/))
          cur = sanitize(m[1]).upcase
          return FX_ALLOWED.include?(cur) ? cur : 'EUR'
        end
        'EUR'
      rescue => e
        puts "[ARStartup] display_currency error: #{e.message}"
        'EUR'
      end

      # Курсы (опционально): fx_rates=MDL:1,EUR:19.05,USD:17.55,RON:4.7
      def fx_rates
        line = read_dat_lines.find { |l| l.lstrip.start_with?('fx_rates=') }
        rates = { 'MDL' => 1.0, 'EUR' => 18.9, 'USD' => 17.3, 'RON' => 4.7 }
        if line && (m = line.match(/fx_rates\s*=\s*([^\r\n]+)/))
          m[1].split(/\s*,\s*/).each do |pair|
            if (mm = pair.match(/\A([A-Z]{3})\s*:\s*([0-9]+(?:\.[0-9]+)?)\z/))
              k = mm[1]; v = mm[2].to_f
              rates[k] = v if FX_ALLOWED.include?(k)
            end
          end
        end
        rates
      rescue => e
        puts "[ARStartup] fx_rates error: #{e.message}"
        { 'MDL' => 1.0, 'EUR' => 18.9, 'USD' => 17.3, 'RON' => 4.7 }
      end

      # ---------- builders ----------
      # Строка языка в нужном формате (с ведущим & после SELECT=)
      def build_language_line(full_locale)
        tail = LANGUAGE_SELECT_ORDER.map { |code, title| "&#{code}^#{title}" }.join
        "Language=language=#{full_locale}=SELECT=#{tail}"
      end

      # Новый формат строки валюты (как у языка, через =SELECT= и с ведущим &)
      def build_currency_line(curr)
        options = FX_ALLOWED.map { |c| "&#{c}^#{(FX_SYMBOL[c] || c)}" }.join
        "Валюта=display_currency=#{curr}=SELECT=#{options}"
      end

      # ---------- write ----------
      def write_settings(lang:, coef:, curr: nil)
        lang = sanitize(lang).downcase
        coef = sanitize(coef).tr(',', '.')

        begin
          f = coef.to_f
          f = 1.0 if f < 1.0
          coef = format('%.2f', f.round(2))
        rescue
          coef = '1.00'
        end

        base = SUPPORTED.include?(lang) ? lang : 'ru'
        full = LOCALE_MAP[base] || "#{base}-#{base.upcase}"

        curr = sanitize(curr || display_currency).upcase
        curr = 'EUR' unless FX_ALLOWED.include?(curr)

        dest  = write_target_path
        lines = File.exist?(dest) ? read_dat_lines : []

        # Удаляем пустые/пробельные строки, чтобы не было "пустой строки" перед валютой
        lines.reject! { |l| l.nil? || l.strip.empty? }

        # Language (первая встреченная строка Language= заменяется; дубликаты удаляются)
        new_lang_line = build_language_line(full)
        first_idx = nil
        lines.each_with_index { |l, i| first_idx ||= i if l.lstrip.start_with?('Language=') }
        if first_idx
          lines[first_idx] = new_lang_line
          dups = []
          lines.each_with_index { |l, i| dups << i if i != first_idx && l.lstrip.start_with?('Language=') }
          dups.reverse_each { |i| lines.delete_at(i) }
        else
          lines << new_lang_line
        end

        # Coef
        cost_idx = lines.index { |l| l.include?('cost_coef') }
        if cost_idx
          if lines[cost_idx] =~ /(cost_coef\s*=\s*)([0-9]+(?:[.,][0-9]+)?)/i
            lines[cost_idx] = lines[cost_idx].sub(/(cost_coef\s*=\s*)([0-9]+(?:[.,][0-9]+)?)/i, "\\1#{coef}")
          else
            prefix = lines[cost_idx][/^.*?cost_coef/i] ? lines[cost_idx][/^.*?cost_coef/i].sub(/cost_coef/i,'cost_coef') : 'Коэффициент=cost_coef'
            suffix = lines[cost_idx][/(=INPUT.*)\z/] || '=INPUT'
            lines[cost_idx] = "#{prefix}=#{coef}#{suffix}"
          end
        else
          lines << "Коэффициент=cost_coef=#{coef}=INPUT"
        end

        # Currency — удаляем любые старые варианты и пишем новый SELECT-формат (без пустых строк вокруг)
        lines.delete_if { |l| l && l.include?('display_currency') }
        lines << build_currency_line(curr)

        # На всякий случай ещё раз уберём пустые строки и дубликаты display_currency
        lines.reject! { |l| l.nil? || l.strip.empty? }
        seen = false
        lines = lines.reject do |l|
          if l.include?('display_currency')
            if seen
              true
            else
              seen = true
              false
            end
          else
            false
          end
        end

        File.open(dest, 'wb') do |f|
          data = lines.join("\n")
          f.write(data.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''))
        end
        true
      rescue => e
        ::UI.messagebox("Failed to write parameters.dat:\n#{e.message}")
        puts "[ARStartup] write_settings error: #{e.message}"
        false
      end
    end

    # — Общий «мост» для HtmlDialog/WebDialog
    module BridgeWiring
      def self.wire_dialog!(dlg)
        return if dlg.instance_variable_defined?(:@__ar_lang_wired)

        # язык
        dlg.add_action_callback('getActiveLang') do |ctx, _payload|
          begin
            base = ARAddons::ARStartup::Reader.active_lang_base
            receiver = (ctx.respond_to?(:execute_script) ? ctx : dlg)
            receiver.execute_script("window.__setActiveLang('#{base}');")
          rescue => e
            puts "[ARStartup] callback error: #{e.message}"
          end
        end

        # FX: отдать валюту и курсы
        dlg.add_action_callback('getFxSettings') do |ctx, _|
          begin
            payload = {
              base:  'MDL',
              show:  ARAddons::ARStartup::Reader.display_currency,
              rates: ARAddons::ARStartup::Reader.fx_rates
            }
            receiver = (ctx.respond_to?(:execute_script) ? ctx : dlg)
            receiver.execute_script("window.__applyFxSettings && window.__applyFxSettings(#{JSON.generate(payload)});")
          rescue => e
            puts "[ARStartup] getFxSettings error: #{e.message}"
          end
        end

        # FX: записать выбранную валюту в parameters (в новом SELECT-формате)
        dlg.add_action_callback('setDisplayCurrency') do |_ctx, cur|
          begin
            c = ARAddons::ARStartup::Reader.sanitize(cur).upcase
            if Reader::FX_ALLOWED.include?(c)
              ARAddons::ARStartup::Reader.write_settings(
                lang: ARAddons::ARStartup::Reader.active_lang_base,
                coef: ARAddons::ARStartup::Reader.cost_coef,
                curr: c
              )
            end
          rescue => e
            puts "[ARStartup] setDisplayCurrency error: #{e.message}"
          end
        end

        dlg.instance_variable_set(:@__ar_lang_wired, true)
      end
    end

    module HtmlDialogPatch
      def set_url(url);  ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(url);  end
      def set_html(h);   ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(h);    end
      def set_file(p);   ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(p);    end
      def show;          ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super;       end
    end

    module WebDialogPatch
      def set_url(url);  ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(url);  end
      def set_html(h);   ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(h);    end
      def set_file(p);   ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super(p);    end
      def show;          ARAddons::ARStartup::BridgeWiring.wire_dialog!(self); super;       end
    end
  end
end

# Подмешиваем патчи глобально — ОБЯЗАТЕЛЬНО из корня ::UI
::UI::HtmlDialog.prepend(ARAddons::ARStartup::HtmlDialogPatch)
::UI::WebDialog.prepend(ARAddons::ARStartup::WebDialogPatch) if defined?(::UI::WebDialog)
