# encoding: UTF-8
# Plugins/ar_addons/loader
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# All rights reserved. Internal use by ART ROCKET is permitted; ownership remains with the author.

module ARAddons
  VERSION  = '1.05'.freeze
  BASE_DIR = File.expand_path(File.dirname(__FILE__))

  DEBUG = false

  # порядок важен: сначала базовые модули/UI, затем наблюдатели
  SUBFOLDERS = %w[
    ar_startup
    ar_library
    ar_redraw
    ar_tags
    ar_functions
    ar_rebuild
  ].freeze

  module Utils
    module_function

    def log(msg)
      return unless ARAddons::DEBUG
      puts "[ARAddons] #{msg}"
    end

    def file_url(path)
      'file:///' + path.to_s.gsub('\\','/')
    end

    def active_lang_base
      if defined?(::ARAddons) && defined?(::ARAddons::ARStartup) && defined?(::ARAddons::ARStartup::Reader)
        (::ARAddons::ARStartup::Reader.active_lang_base rescue 'ru')
      else
        'ru'
      end
    end

    def shared_icon(name)
      File.join(ARAddons::BASE_DIR, 'icons', name.to_s)
    end

    def cache_dir
      base =
        if Sketchup.platform == :platform_win
          (ENV['LOCALAPPDATA'] || ENV['APPDATA'] || Dir.tmpdir)
        else
          File.join(Dir.home, 'Library', 'Application Support', 'SketchUp') rescue Dir.tmpdir
        end
      dir = File.join(base.to_s, 'SUF_ARAddons')
      begin
        require 'fileutils'
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
      rescue
      end
      dir
    end
  end

  module Registry
    module_function

    def root_menu
      @root_menu ||= ::UI.menu('Extensions').add_submenu('ART Rocket · Add-ons')
    rescue
      ::UI.menu('Extensions')
    end

    def toolbar
      @toolbar_proxy ||= ToolbarProxy.new
    end

    def __buffer_add(cmd)
      @buffer ||= []
      @buffer << cmd
      cmd
    end

    def build_toolbar!
      @buffer ||= []
      return if @buffer.empty?

      @toolbar ||= ::UI::Toolbar.new('AR Add-ons')

      first, middle, startup = [], [], []
      @buffer.each do |cmd|
        if cmd.instance_variable_get(:@__ar_role) == :startup
          startup << cmd
        elsif cmd.instance_variable_get(:@__ar_order) == :first
          first << cmd
        else
          middle << cmd
        end
      end

      (first + middle + startup).each do |cmd|
        begin
          @toolbar.add_item(cmd)
        rescue
        end
      end

      begin
        @toolbar.restore if @toolbar.get_last_state == ::TB_VISIBLE
      rescue
      end

      @buffer.clear
      @toolbar_proxy = @toolbar
    end

    class ToolbarProxy
      def add_item(cmd)
        ARAddons::Registry.__buffer_add(cmd)
      end

      # чтобы не падали случайные вызовы методов панели до сборки
      def method_missing(*)
        nil
      end

      def respond_to_missing?(*)
        true
      end
    end
  end

  # ---------- FirstRun ----------
  module FirstRun
    extend self
    KEYSPACE = 'com.sketchup.ARAddons'.freeze

    def installed_version
      Sketchup.read_default(KEYSPACE, 'version', nil)
    rescue
      nil
    end

    def first_install_or_upgrade?(current_version)
      (installed_version.to_s != current_version.to_s)
    end

    def mark_installed!(current_version)
      begin
        Sketchup.write_default(KEYSPACE, 'version', current_version.to_s)
        Sketchup.write_default(KEYSPACE, 'installed_at', Time.now.utc.iso8601)
      rescue
      end
    end

    def maybe_show_startup!(current_version)
      return unless first_install_or_upgrade?(current_version)
      mark_installed!(current_version)
      ::UI.start_timer(0.25, false) do
        begin
          mod = (::ARAddons::ARStartup rescue nil)
          if mod
            if mod.respond_to?(:show_dialog)
              mod.show_dialog
            elsif mod.respond_to?(:open)
              mod.open
            elsif mod.respond_to?(:show)
              mod.show
            elsif mod.const_defined?(:UI) && mod::UI.respond_to?(:show)
              mod::UI.show
            end
          end
        rescue => e
          ARAddons::Utils.log("FirstRun show failed: #{e.class}: #{e.message}")
        end
      end
    end
  end

  # ---------- Guard ----------
  # (оставлено без изменений; не добавляет новой защиты помимо существующей логики)
  module Guard
    extend self
    require 'json'
    require 'time'
    require 'tmpdir'

    # Поставь вашу реальную дату.
    CUTOFF_UTC = Time.utc(2026, 1, 1)
    CACHE_FILE = File.join(ARAddons::Utils.cache_dir, 'guard_time.json')
    HTTP_SOURCES = [
      'https://www.google.com/generate_204',
      'https://www.cloudflare.com/',
      'https://www.microsoft.com/'
    ].freeze

    def log(msg)
      ARAddons::Utils.log("[Guard] #{msg}")
    end

    def read_cached_utc
      return nil unless File.file?(CACHE_FILE)
      data = JSON.parse(File.read(CACHE_FILE)) rescue nil
      t = data && data['last_seen_utc']
      t ? Time.parse(t).utc : nil
    rescue
      nil
    end

    def write_cached_utc(t_utc)
      return unless t_utc.is_a?(Time)
      File.write(CACHE_FILE, JSON.pretty_generate({ 'last_seen_utc' => t_utc.utc.iso8601 })) rescue nil
    rescue
      nil
    end

    def now_local_utc
      Time.now.utc
    end

    # онлайн-время: корректный use_ssl для Ruby 2.7/3.x
    def now_online_utc(timeout: 2.5)
      require 'net/http'
      require 'uri'
      require 'openssl'
      HTTP_SOURCES.each do |url|
        begin
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE # time ping; для боевой лицензии лучше VERIFY_PEER + pinning
          end
          http.open_timeout = timeout
          http.read_timeout = timeout
          path = uri.request_uri.to_s
          path = '/' if path.empty?
          res = http.request(Net::HTTP::Get.new(path))
          date_hdr = res['date'] || res['Date']
          if date_hdr && !date_hdr.to_s.strip.empty?
            t = Time.httpdate(date_hdr).utc rescue nil
            return t if t
          end
        rescue => e
          log("online time failed for #{url}: #{e.class}: #{e.message}")
        end
      end
      nil
    rescue => e
      log("online time error: #{e.class}: #{e.message}")
      nil
    end

    def effective_now_utc
      t_local  = now_local_utc
      t_cache  = read_cached_utc
      t_online = now_online_utc
      eff = [t_local, t_cache, t_online].compact.max
      write_cached_utc(eff) rescue nil
      eff
    end

    def expired?
      eff = effective_now_utc
      log("effective_now_utc=#{eff&.iso8601} cutoff=#{CUTOFF_UTC.iso8601}")
      eff && eff >= CUTOFF_UTC
    end

    def deny!
      msg_en = "AR Add-ons has expired.\nThe plugin has been disabled as of 2026-01-01.\nUpdate the plugin to the latest version or contact support."
      begin
        ::UI.messagebox(msg_en)
      rescue
        puts "[ARAddons] #{msg_en}"
      end
    end

    def check_only!
      deny! if expired?
      true
    end

    def allowed_to_boot?
      !expired?
    end
  end

  # ---------- Legal/About (неблокирующее информирование) ----------
  module Legal
    HOLDER  = 'Artiom Gurduz'.freeze
    YEAR    = '2025'.freeze
    LICENSE_MAIN = File.join(ARAddons::BASE_DIR, 'LICENSE')
    LICENSE_ART  = File.join(ARAddons::BASE_DIR, 'LICENSE-ART-ROCKET.txt')

    module_function

    def license_text
      path = File.exist?(LICENSE_ART) ? LICENSE_ART : LICENSE_MAIN
      File.read(path, encoding: 'UTF-8') rescue "© #{YEAR} #{HOLDER}. All rights reserved."
    end

    def show_about
      UI.messagebox("AR Add-ons / DVNX\n© #{YEAR} #{HOLDER}\nOwnership remains with the author.\nThis copy may be provided to ART ROCKET for internal use.")
    end

    def show_license
      UI.messagebox(license_text)
    end
  end

  # ---------- Loader ----------
  module Loader
    module_function

    def load_all
      Utils.log("Boot v#{VERSION}…")

      SUBFOLDERS.each do |name|
        dir = File.join(BASE_DIR, name)
        next unless File.directory?(dir)

        entry_base = File.join(dir, 'main')   # без .rb
        begin
          Sketchup.require(entry_base)        # подхватит .rb/.rbs/.rbe
          Utils.log("loaded #{name}")
        rescue LoadError => e
          Utils.log("skip #{name} — cannot load main (#{e.message})")
        rescue => e
          ::UI.messagebox("Failed to load #{name}:\n#{e.class}: #{e.message}")
          puts "[ARAddons] load #{name} error:\n#{e.full_message}" if ARAddons::DEBUG
        end
      end

      ARAddons::Registry.build_toolbar!

      # Добавляем пункт(ы) меню с информацией о праве и лицензии (неблокирующие)
      begin
        m = ARAddons::Registry.root_menu
        m.add_item('AR Add-ons — About'){ ARAddons::Legal.show_about }
        m.add_item('AR Add-ons — License'){ ARAddons::Legal.show_license }
      rescue
      end

      ARAddons::FirstRun.maybe_show_startup!(ARAddons::VERSION)
      Utils.log('Boot done.')
    end
  end

  # ---------- Boot ----------
  module Boot
    module_function
    @loaded_once = false

    class AppObs < Sketchup::AppObserver
      def onNewModel(model)
        ARAddons::Boot.__on_model_event(model, :new)
      end

      def onOpenModel(model)
        ARAddons::Boot.__on_model_event(model, :open)
      end
    end

    def __on_model_event(_model, kind)
      ARAddons::Utils.log("Model event: #{kind}")
      ARAddons::Guard.check_only!
      return if @loaded_once
      if ARAddons::Guard.allowed_to_boot?
        __delayed_boot!
      else
        ARAddons::Guard.deny!
      end
    rescue => e
      ARAddons::Utils.log("AppObs error: #{e.class}: #{e.message}")
    end

    def __delayed_boot!
      delay = (rand * 0.23) + 0.12
      ARAddons::Utils.log("Boot timer: #{delay.round(3)}s")
      ::UI.start_timer(delay, false) do
        begin
          if ARAddons::Guard.allowed_to_boot?
            ARAddons::Loader.load_all
            @loaded_once = true
          else
            ARAddons::Guard.deny!
          end
        rescue => e
          ARAddons::Utils.log("Boot timer error: #{e.class}: #{e.message}")
        end
      end
    end

    def start!
      begin
        Sketchup.add_observer(AppObs.new)
      rescue => e
        ARAddons::Utils.log("add_observer failed: #{e.class}: #{e.message}")
      end
      ::UI.start_timer(0.0, false) { __on_model_event(Sketchup.active_model, :initial) }
    end
  end
end

ARAddons::Boot.start!
