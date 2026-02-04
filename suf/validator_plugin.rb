# frozen_string_literal: true

require 'openssl'
require 'json'
require 'base64'
require 'date'
require 'time'
require 'net/http'
require 'uri'
require 'socket'
begin
  require 'win32ole'
rescue LoadError
end
require 'digest'
require 'fileutils'
require "uri"
require "open-uri"
require "tmpdir"
require "zlib"
require "rubygems/package"
require "open3"
require 'pathname'

module ValidatorPlugin
  class ShutdownObserver < Sketchup::AppObserver
    def onQuit
      # Record the shutdown time so it’s tied into subsequent offline log entries.
      ValidatorPlugin::LicenseValidator.note_shutdown(Time.now.utc)

      lic = ValidatorPlugin::LicenseValidator.load_license
      registration_code = nil
      if lic
        data_b = Base64.strict_decode64(lic["data"])
        registration_code = JSON.parse(data_b)["registration_code"] rescue nil
      end
      
      ValidatorPlugin::LicenseValidator.append_offline_log!(
        event_type: "app_shutdown",
        registration_code: registration_code,
        details: {}
      )

      ValidatorPlugin::LicenseValidator.release_license_from_exit
    end
  end

  class LicenseValidator
    SERVER_URL         = "https://license.artrocket.eu"
    OFFLINE_GRACE_DAYS = 7
    SECRET_PEPPER      = "v1.🍀-change-me-per-build"  # change per build
    @@registration_dialog_shown = false
    @@expiry_dialog_shown = false
    @@license_checked_out_id = nil
    @@license_checked_out    = false
    @@license_denied         = true
    @@last_shutdown_at       = nil
    @@registration_expired = false

    @@plugin_has_updates = false
    @@price_has_updates = false
    @@resource_has_updates = false
    @@thread = nil

    EMBEDDED_PUBKEY_PEM = <<~PEM.freeze
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp4lTFagwLEHGQps2SFuH
      BvKzEPcONkWguNaMB+fGjC+dneTHbfbzFVe7Hoy9ES4ZquFQyE+g3LQxD1/ceg4q
      jXICFJ9ppK4Uw/uGSnLH+PCNGpfh6LZ9xt5ENJ0d4UjMN8Wq0zf6/0d6rp5HGFJ7
      1thajH4t8Cxsi3blc7MbfMDwjUwAZM0ZNRX1J871OWFhuR8kqqjNkM50Ky3rj/Le
      qEYHvjZL2VWTnvupB6dmzXaQIX7tHvkTunnlqgOEIoKhnMpYvyOzN4BTq/DH4o4E
      hH1P4fSNEBq9LFUNCi3VTPCH15yf9hO24eyBx9kUKBZe7aR9hKWnbUHhcE23AQYY
      LQIDAQAB
      -----END PUBLIC KEY-----
    PEM

    class << self

      def start_time_tracker
        begin
          if Sketchup.active_model
            ValidatorPlugin::TimeTracker::Manager.instance #.instance.on_model_open_or_new(Sketchup.active_model)
          end
        rescue => e
          puts "[Time Tracker] Failed to auto-start: #{e.message}"
        end
      end
      # ---------- Paths ----------
      def plugin_path
        if defined?(Sketchup) && Sketchup.respond_to?(:find_support_file)
          Sketchup.find_support_file('Plugins') || "."
        else
          $LOAD_PATH.find { |str| str.to_s.downcase.include?('plugins') } || "."
        end
      end

      def cache_dir
        @cache_dir ||= File.expand_path(File.join(plugin_path, "suf"))
      end

      def offline_cache_path;       File.join(cache_dir, "offline_cache.json"); end
      def offline_auto_flag_path;   File.join(cache_dir, "offline_mode.auto.flag"); end # automatic toggle only
      def public_key_path;          File.join(cache_dir, "public.pem"); end
      def license_path;             File.join(cache_dir, "license.lic"); end
      def offline_logs_path;        File.join(cache_dir, "offline_usage.jsonl"); end
      def offline_logs_backup_path; File.join(cache_dir, "offline_usage.sent.jsonl"); end

      # ---------- Cert store ----------
      def default_cert_store
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        # If you ship a bundle, uncomment:
        # pem_path = File.join(cache_dir, "ca-bundle.crt")
        # store.add_file(pem_path) if File.exist?(pem_path)
        store
      end

      def plugin_has_updates
        @@plugin_has_updates
      end
      def price_has_updates
        @@price_has_updates
      end
      def resource_has_updates
        @@resource_has_updates
      end

      # ---------- Flags / helpers ----------
      def registration_expired?
        @@registration_expired
      end

      def license_denied
        @@license_denied
      end

      def license_denied=(value)
        @@license_denied = value
      end

      def license_checked_out
        @@license_checked_out
      end

      def ensure_cache_dir
        FileUtils.mkdir_p(cache_dir)
      end

      def public_key
        # raise "Missing public key at #{public_key_path}" unless File.exist?(public_key_path)
        # OpenSSL::PKey::RSA.new(File.read(public_key_path))
        OpenSSL::PKey::RSA.new(EMBEDDED_PUBKEY_PEM)
      end

      def load_license
        return nil unless File.exist?(license_path)
        JSON.parse(File.read(license_path))
      rescue JSON::ParserError
        nil
      end

      # ---------- Machine identity ----------
      def machine_id
        if defined?(WIN32OLE)
          begin wmi = WIN32OLE.connect("winmgmts://"); rescue; wmi = nil; end
          machine_guid = begin WIN32OLE.new('WScript.Shell').RegRead("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography\\MachineGuid"); rescue ""; end
          cpu_id = begin
            if wmi
              cpus = wmi.ExecQuery("SELECT ProcessorId FROM Win32_Processor")
              cpus.each { |cpu| break cpu.ProcessorId.to_s } || ""
            else
              ""
            end
          rescue; ""; end
          bios_serial = begin
            if wmi
              bioses = wmi.ExecQuery("SELECT SerialNumber FROM Win32_BIOS")
              bioses.each { |b| break b.SerialNumber.to_s } || ""
            else
              ""
            end
          rescue; ""; end
          raw = [machine_guid, cpu_id, bios_serial].join("|")
          return Digest::SHA256.hexdigest(raw) unless raw == "||"
        end
        fallback = begin
          host = Socket.gethostname rescue ""
          addrs = Socket.ip_address_list.map { |a| a.ip_address }.join(",") rescue ""
          [host, addrs].join("|")
        rescue
          "fallback"
        end
        Digest::SHA256.hexdigest(fallback)
      end

      # ---------- UI ----------
      def message(msg)
        defined?(UI) ? UI.messagebox(msg) : puts(msg)
      end

      # ---------- Shutdown timestamp plumbing ----------
      def note_shutdown(ts = Time.now.utc)
        @@last_shutdown_at = (ts.respond_to?(:utc) ? ts.utc : ts)
      end

      # ---------- Auto offline toggle (only) ----------
      def force_offline_auto?
        File.exist?(offline_auto_flag_path)
      end
      def set_force_offline_auto(value)
        ensure_cache_dir
        if value
          File.write(offline_auto_flag_path, "1")
        else
          File.delete(offline_auto_flag_path) if File.exist?(offline_auto_flag_path)
        end
      end

      # Effective offline state (auto only)
      def offline_effective?
        force_offline_auto?
      end

      # write_offline_cache!
      def write_offline_cache!(registration_code)
        ensure_cache_dir
        key = CryptoBox.key_for(machine_id: machine_id, registration_code: registration_code, pepper: SECRET_PEPPER)
        payload = {
          # round to minute to avoid ultra-precise times
          last_ok_at: Time.now.utc.to_i - (Time.now.utc.to_i % 60),
          machine: machine_id
        }
        box = CryptoBox.encrypt_json(payload, key)
        File.write(offline_cache_path, box, mode: "w")
      rescue
      end

      # offline_grace_valid?
      def offline_grace_valid?(registration_code)
        return false unless File.exist?(offline_cache_path)
        key = CryptoBox.key_for(machine_id: machine_id, registration_code: registration_code, pepper: SECRET_PEPPER)
        obj = CryptoBox.decrypt_json(File.read(offline_cache_path), key) rescue nil
        return false unless obj && obj["machine"] == machine_id && obj["last_ok_at"].is_a?(Integer)
        last_ok = Time.at(obj["last_ok_at"]).utc
        Time.now.utc <= last_ok + OFFLINE_GRACE_DAYS * 24 * 60 * 60
      end

      def offline_grace_expiry(registration_code)
        obj = begin
          key = CryptoBox.key_for(machine_id: machine_id, registration_code: registration_code, pepper: SECRET_PEPPER)
          CryptoBox.decrypt_json(File.read(offline_cache_path), key)
        rescue
          nil
        end
        return nil unless obj && obj["last_ok_at"].is_a?(Integer)
        Time.at(obj["last_ok_at"] + OFFLINE_GRACE_DAYS * 86_400)
      end


      # ---------- Auto-offline reachability ----------
# inside class << self
      def server_reachable?(timeout_open: 3, timeout_read: 5)
        begin
          uri  = URI("#{SERVER_URL}/security_check/password")
          body = { password: 'supersecret' }

          response = post_json(uri, body)
          if response&.code == "200"
            parsed = JSON.parse(response.body) rescue {}
            parsed['result'] == 'pass'
          else
            false
          end
        rescue => e
          false
        end
      end

      # Do NOT touch any manual flag (there is none). Only flips the auto flag.
      def handle_auto_offline_transition!(registration_code, is_silent: false)
        reachable = server_reachable?

        if reachable && force_offline_auto?
          set_force_offline_auto(false)
          begin
            upload_offline_logs!(registration_code)
            message("🌐 Server reachable again. Uploaded any offline logs and resumed online validation.") unless is_silent
            append_offline_log!(event_type: "auto_offline_recovered", registration_code: registration_code, details: {})
          rescue => e
            append_offline_log!(event_type: "auto_offline_recover_error", registration_code: registration_code, details: { error: e.message })
          end
        end

        if !reachable && !force_offline_auto?
          exp = offline_grace_expiry(registration_code)
          message("✅ Offline mode: valid until #{exp&.utc&.iso8601}") unless auto_offline_flag_present?
          set_force_offline_auto(true)
          message("⚠️ Server unreachable. Auto-enabled offline mode (#{OFFLINE_GRACE_DAYS}-day grace window).") unless is_silent
          append_offline_log!(event_type: "auto_offline_enabled", registration_code: registration_code, details: {})
        end

        reachable
      end

      def auto_offline_flag_present?
        plugins_dir = Sketchup.find_support_file('Plugins')
        flag_path   = File.join(plugins_dir, 'suf', 'offline_mode.auto.flag')
        File.exist?(flag_path)
      end

      def registration_dialog_shown?
        @@registration_dialog_shown
      end

      def expiry_dialog_shown?
        @@expiry_dialog_shown
      end

      # ---------- License verification flow ----------
      def verify_license(isSilent = false, floating: true)
        return true if license_checked_out
        lic = load_license
        unless lic
          show_registration_dialog unless registration_dialog_shown?
          return false
        end

        signature_b = Base64.strict_decode64(lic["signature"])
        data_b      = Base64.strict_decode64(lic["data"])

        unless public_key.verify(OpenSSL::Digest::SHA256.new, signature_b, data_b)
          message("License signature invalid.") unless isSilent
          return false
        end

        parsed = JSON.parse(data_b)
        $registration_code = registration_code = parsed["registration_code"]

        # Auto-toggle based on reachability + flush logs when recovering
        handle_auto_offline_transition!(registration_code, is_silent: isSilent)

        # Auto-offline path (no manual)
        if offline_effective?
          if offline_grace_valid?(registration_code)
            @@license_denied = true
            exp = offline_grace_expiry(registration_code)
            append_offline_log!(
              event_type: "offline_auto_active",
              registration_code: registration_code,
              details: { expires_at: exp&.utc&.iso8601 }
            ) unless isSilent
            return true
          else
            message("❌ Offline period expired. Please reconnect to validate.") unless isSilent
            append_offline_log!(event_type: "offline_expired", registration_code: registration_code)
            Process.exit!(0)
            return false
          end
        end

        # Online path
        begin
          ok = checkout_license(registration_code, is_silent: isSilent)
          if ok
            write_offline_cache!(registration_code)
            return true
          else
            return false
          end
        rescue => e
          if offline_grace_valid?(registration_code)
            @@license_denied = false
            exp = offline_grace_expiry(registration_code)
            message("⚠️ Server unreachable; using offline mode until #{exp&.utc&.iso8601}.") #unless isSilent
            append_offline_log!(event_type: "offline_fallback_ok", registration_code: registration_code, details: { error: "#{e.class}: #{e.message}", expires_at: exp&.utc&.iso8601 })
            set_force_offline_auto(true) # reflect state
            return true
          else
            message("❌ Couldn’t reach server and no offline days left (#{e.message}).") #unless isSilent
            append_offline_log!(event_type: "offline_fallback_denied", registration_code: registration_code, details: { error: "#{e.class}: #{e.message}" })
            return false
          end
        end
      rescue => e
        message("License check error: #{e.message}") #unless isSilent
        false
      end

      # ---------- HTTP helper ----------
      def post_json(uri, body)
        use_ssl = (uri.scheme == "https")

        Net::HTTP.start(
          uri.host, uri.port,
          use_ssl: use_ssl,
          open_timeout: 5,
          read_timeout: 10,
          write_timeout: 10
        ) do |http|
          if use_ssl
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            if defined?(OpenSSL::SSL::TLS1_2_VERSION)
              http.min_version = OpenSSL::SSL::TLS1_2_VERSION
            end
            http.cert_store  = default_cert_store
          end

          request = Net::HTTP::Post.new(
            uri.request_uri,
            { 'Content-Type' => 'application/json', 'User-Agent': 'ValidatorPlugin/1.0' }
          )
          request.body = JSON.dump(body)
          http.request(request)
        end
      end

      def append_offline_log!(event_type:, registration_code:, details: {})
        ensure_cache_dir
        started = @@last_shutdown_at && @@last_shutdown_at.to_i
        # Coarsen event time to minute
        ts = Time.now.utc.to_i - (Time.now.utc.to_i % 60)

        payload = {
          ts: ts,
          event: event_type.to_s,
          machine_id: machine_id,                # keep if you need it locally; or drop to minimize
          details: details,
          shutdown_observer_at: started
        }

        key = CryptoBox.key_for(machine_id: machine_id, registration_code: registration_code.to_s, pepper: SECRET_PEPPER)
        box = CryptoBox.encrypt_json(payload, key)

        File.open(offline_logs_path, "a") do |f|
          f.flock(File::LOCK_EX)
          f.puts(box)   # encrypted line, not plaintext
          f.flock(File::LOCK_UN)
        end
        cap_offline_log_size!
      rescue
      end

      def each_offline_log_decrypted(registration_code)
        return enum_for(__method__, registration_code) unless block_given?
        key = CryptoBox.key_for(machine_id: machine_id, registration_code: registration_code, pepper: SECRET_PEPPER)
        File.foreach(offline_logs_path, chomp: true) do |line|
          next if line.strip.empty?
          begin
            yield CryptoBox.decrypt_json(line, key)
          rescue
            # skip malformed lines
          end
        end
      end

      def cap_offline_log_size!(max_bytes: 512 * 1024)
        return unless File.exist?(offline_logs_path)
        return unless File.size(offline_logs_path) > max_bytes
        lines = File.readlines(offline_logs_path, chomp: true)
        keep = lines.last([lines.size / 2, 1].max)
        File.open(offline_logs_path, "w") { |f| f.puts(keep.join("\n")) }
      rescue
      end

      def upload_offline_logs!(registration_code)
        return false unless File.exist?(offline_logs_path)

        enc_lines = []
        File.open(offline_logs_path, "r") do |f|
          f.flock(File::LOCK_SH)
          f.each_line { |line| s = line.strip; enc_lines << s unless s.empty? }
          f.flock(File::LOCK_UN)
        end
        return false if enc_lines.empty?

        key = CryptoBox.key_for(
          machine_id: machine_id,
          registration_code: registration_code.to_s,
          pepper: SECRET_PEPPER
        )

        # --- helpers ---------------------------------------------------------
        normalize_time = lambda do |v|
          return nil if v.nil? || v == ""
          # already looks like ISO8601?
          if v.is_a?(String) && v.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
            v
          else
            # accept integers / numeric strings; handle sec/ms/us
            n =
              if v.is_a?(Numeric)
                v.to_f
              elsif v.is_a?(String) && v.strip.match?(/\A\d+\z/)
                v.to_f
              else
                # fallback: try Time.parse; if it fails, return as-is
                begin
                  return Time.parse(v.to_s).utc.iso8601
                rescue
                  return v
                end
              end
            # classify units
            if n >= 1e14 # microseconds
              n /= 1_000_000.0
            elsif n >= 1e12 # milliseconds
              n /= 1_000.0
            end
            Time.at(n).utc.iso8601
          end
        end
        # --------------------------------------------------------------------

        plaintext_lines = enc_lines.map do |s|
          obj = CryptoBox.decrypt_json(s, key) # expect a Hash

          # Normalize timestamps to ISO8601 strings for server compatibility
          if obj.is_a?(Hash)
            obj["ts"] = normalize_time.call(obj["ts"])
            obj["shutdown_observer_at"] = normalize_time.call(obj["shutdown_observer_at"])
          end

          JSON.dump(obj)  # send plaintext JSON (legacy shape)
        end

        uri  = URI("#{SERVER_URL}/upload_logs")
        body = {
          registration_code: Base64.strict_encode64(registration_code),
          data: plaintext_lines
        }

        resp = post_json(uri, body)
        if resp&.code == "200"
          FileUtils.rm_f(offline_logs_path)
          FileUtils.rm_f(offline_logs_backup_path)
          true
        else
          append_offline_log!(
            event_type: "upload_error",
            registration_code: registration_code,
            details: { code: resp&.code }
          ) rescue nil
          false
        end
      rescue => e
        append_offline_log!(
          event_type: "upload_error",
          registration_code: registration_code,
          details: { error: e.message }
        ) rescue nil
        false
      end

      # ---------- Registration dialog ----------
      def show_registration_dialog
        return unless defined?(UI)
        return if registration_dialog_shown?
        dlg = UI::HtmlDialog.new({
          dialog_title: "Register Product",
          preferences_key: "com.example.registration",
          scrollable: true,
          resizable: false,
          width: 400,
          height: 350,
          style: UI::HtmlDialog::STYLE_DIALOG
        })

        html = <<-HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: sans-serif; margin: 20px; }
              label, input { display: block; margin-bottom: 10px; }
              input[type="text"], input[type="password"] { width: 95%; padding: 8px; font-size: 14px; }
              button { padding: 8px 12px; font-size: 14px; margin-right: 6px; }
            </style>
          </head>
          <body>
            <h2>
            Please enter your registration code to proceed.<br>
            If you’re not a member, click <a href="https://artrocket.ro/cont" target="top">here</a> to register now.
            </h2>
            <label for="registration_code">Registration Code:</label>
            <input type="text" id="registration_code">
            <div>
              <button onclick="submitForm()">Submit</button>
            </div>

            <script>
              async function submitForm() {
                const registration_code = document.getElementById('registration_code').value.trim();
                if (!registration_code) { alert("Please enter a registration code."); return; }

                try {
                  const response = await fetch("https://artrocket.ro/?ar_license_api=" + encodeURIComponent(registration_code), {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ registration_code })
                  });

                  if (response.ok) {
                    const data = await response.json();
                    if (window.sketchup && window.sketchup.submitData) {
                      window.sketchup.submitData(JSON.stringify(data));
                    } else {
                      alert("Bridge to SketchUp missing.");
                    }
                  } else {
                    console.error("Activation failed:", response.status, response.statusText);
                    alert("❌ Activation failed. Code: " + response.status);
                  }
                } catch (err) {
                  console.error("Network error:", err);
                  alert("⚠️ Could not reach activation server.");
                }
              }
            </script>
          </body>
          </html>
        HTML

        dlg.set_html(html)

        dlg.add_action_callback("submitData") do |_, json_payload|
          begin
            data = json_payload

            # Verify payload BEFORE saving
            begin
              parsed = JSON.parse(data)
              sig_b  = Base64.strict_decode64(parsed["signature"])
              dat_b  = Base64.strict_decode64(parsed["data"])

              unless public_key.verify(OpenSSL::Digest::SHA256.new, sig_b, dat_b)
                message("❌ Activation failed: signature invalid")
                next
              end
            rescue => e
              message("❌ Activation failed: malformed payload (#{e.message})")
              next
            end

            ensure_cache_dir
            File.open(license_path, "w") { |f| f.write(data) }

            # Inform main server
            uri  = URI("#{SERVER_URL}/register")
            body = { encoded_data: Base64.strict_encode64(data) }
            resp = post_json(uri, body)

            if resp&.code == "200"
              message("✅ Activation successful! Please restart SketchUp to complete activation.")
              # Process.exit!(0)
            else
              message("❌ Activation failed (#{resp&.code})")
            end
          rescue => e
            UI.messagebox("⚠️ Failed to save license: #{e.message}")
          ensure
            dlg.close
          end
        end
        @@registration_dialog_shown = true
        dlg.show_modal
      end

      # ---------- License checkout & release ----------
      def checkout_license(registration_code, is_silent: false)
        uri  = URI("#{SERVER_URL}/checkout")
        body = { machine_id: machine_id, 
                 registration_code: Base64.strict_encode64(registration_code),
                 plugin: Base64.strict_encode64(ValidatorPlugin::Versioner.plugin_version),
                 price: Base64.strict_encode64(ValidatorPlugin::Versioner.price_version),
                 resource: Base64.strict_encode64(ValidatorPlugin::Versioner.resource_version)
               }

        unless @@license_checked_out
          response = post_json(uri, body)
          if response&.code == "200"
            @@license_checked_out    = true
            @@license_denied         = false
            parsed = JSON.parse(response.body) rescue {}
            @@license_checked_out_id = parsed['create_log']['id']
            @@plugin_has_updates = parsed['plugin_has_updates']
            @@price_has_updates = parsed['price_has_updates']
            @@resource_has_updates = parsed['resource_has_updates']

            update_plugin_icon = @@plugin_has_updates ? 'update_plugin_2.png' : 'update_plugin_1.png'
            update_price_icon = @@price_has_updates ? 'update_price_2.png' : 'update_price_1.png'
            update_resource_icon = @@resource_has_updates ? 'update_library_2' : 'update_library_1'
            if $Plugin_cmd
              $path_icons = $path_icons + '/style1'
              $Plugin_cmd.small_icon = $Plugin_cmd.large_icon = File.join($path_icons, update_plugin_icon)
              $Price_cmd.small_icon = $Price_cmd.large_icon = File.join($path_icons, update_price_icon)
              $Resource_cmd.small_icon = $Resource_cmd.large_icon = File.join($path_icons, update_resource_icon)
              $SU_Furniture_tb.add_item($Plugin_cmd)
              $SU_Furniture_tb.add_item($Price_cmd)
              $SU_Furniture_tb.add_item($Resource_cmd)
              $SU_Furniture_tb.show
            end

            write_offline_cache!(registration_code)
            true
          elsif response&.code == "202"
            parsed = JSON.parse(response.body) rescue {}
            @@license_checked_out    = true
            @@license_checked_out_id = parsed['create_log']['id']
            @@plugin_has_updates = parsed['plugin_has_updates']
            @@price_has_updates = parsed['price_has_updates']
            @@resource_has_updates = parsed['resource_has_updates']
            UIHelpers.show_expiry_message(
              title: "License expired",
              message: parsed['error'],
            ) { puts "User acknowledged expiry." } unless expiry_dialog_shown?
            @@expiry_dialog_shown = true
            @@registration_expired = false
          elsif response&.code == "203"
            parsed = JSON.parse(response.body) rescue {}
            # message("⚠️ #{ parsed['error'] }")
            UIHelpers.show_expiry_message(
              title: "License expired",
              message: parsed['error'],
            ) { puts "User acknowledged expiry." } unless expiry_dialog_shown?

            @@expiry_dialog_shown = true
            @@license_denied = true
            @@registration_expired = true
            false
          else
            @@license_denied = true
            message("❌ Floating license denied (#{response&.code})") unless is_silent
            Process.exit!(0)
            false
          end
        else
          true
        end
      rescue => e
        @@license_denied = true
        message("❌ License checkout error: #{e.message} #{e.backtrace}") unless is_silent
        Process.exit!(0)
        raise
      end

      def release_license_from_exit
        return unless @@license_checked_out
        registration_code = begin
          lic = load_license
          if lic
            data_b = Base64.strict_decode64(lic["data"])
            JSON.parse(data_b)["registration_code"]
          end
        rescue
          nil
        end
        uri  = URI("#{SERVER_URL}/release")
        body = {
          log_id: @@license_checked_out_id,
          machine_id: machine_id,
          registration_code: registration_code ? Base64.strict_encode64(registration_code) : nil
        }

        begin
          post_json(uri, body)
        rescue => e
          message("Error releasing license during shutdown: #{e.message}")
        ensure
          @@license_checked_out = false
        end
      end
    end

    def notification_id
      begin
        model = Sketchup.active_model
        path     = model.path            # full path to the current SKP ("" if never saved)
        filename = File.basename(path)   # e.g. "House.skp"
        name     = File.basename(path, '.*') # e.g. "House" (no extension)
        title    = model.title  

        uri  = URI("")
        body = { license_checked_out_id: @@license_checked_out_id, registration_code: $registration_code, title: title }

        response = post_json(uri, body)
        if response&.code == "200"
          parsed = JSON.parse(response.body) rescue {}
          parsed['id']
        else
          ''
        end
      rescue => e
        ''
      end
    end
  end

  module Updater
    class Error < StandardError; end
    extend self

    require "uri"
    require "net/http"
    require "open-uri"
    require "zlib"
    require "rubygems/package"
    require "fileutils"
    require "tmpdir"
    require "json"
    require "open3"

    # ----------------------------
    # Protection rules
    # ----------------------------
    PROTECTED_FILES = %w[license.lic offline_cache.json offline_usage.jsonl].map!(&:downcase).freeze
    PROTECTED_DIRS  = %w[rgloader].map!(&:downcase).freeze

    def protected_name?(name)
      n = name.to_s.downcase
      PROTECTED_FILES.include?(n) || PROTECTED_DIRS.include?(n)
    end

    # Is abs_path the protected file/dir itself OR anything within a protected dir?
    def protected_path?(abs_path, root)
      ap = File.expand_path(abs_path).downcase
      rt = (File.expand_path(root).downcase + File::SEPARATOR)
      return true if PROTECTED_FILES.include?(File.basename(ap))
      PROTECTED_DIRS.any? { |d| ap == (rt + d) || ap.start_with?(rt + d + File::SEPARATOR) }
    end

    # Is the root itself a protected dir? (guard against cleaning inside it)
    def protected_root?(root)
      ap   = File.expand_path(root).downcase
      base = File.basename(ap)
      PROTECTED_DIRS.include?(base)
    end

    # ----------------------------
    # Public APIs
    # ----------------------------
    def update_prices(bundle_url = "https://artrocket.s3.us-east-1.amazonaws.com/prices.tar.gz", verbose: false)
      uri = URI.parse(bundle_url)
      raise Error, "Only HTTPS URLs are supported" unless uri.scheme == "https"

      materials_root = Sketchup.find_support_file("Materials")
      raise Error, "SketchUp 'Materials' folder not found" unless materials_root && Dir.exist?(materials_root)
      dst_price = File.join(materials_root, "price")

      if defined?(UI::HtmlDialog)
        tmpdir      = Dir.mktmpdir("ar_prices-")
        tar_file    = File.join(tmpdir, File.basename(uri.path).to_s.empty? ? "prices.tar.gz" : File.basename(uri.path))
        extract_dir = File.join(tmpdir, "extract")

        steps = ["Prepare workspace","Download bundle","Extract files","Install Materials/price","Cleanup","Restart"]
        failed = false

        run_with_progress(title: "Updating Prices", steps: steps) do |i, _label, done|
          break if failed
          begin
            case i
            when 0
              log(verbose, "Preparing temp dir #{tmpdir}")
              FileUtils.mkdir_p(File.dirname(tar_file))
              FileUtils.rm_rf(extract_dir)
              @file_size = head_content_length(uri)
              set_download_progress(0.0, "Waiting to start…")
              done.call
            when 1
              log(verbose, "Downloading #{bundle_url} -> #{tar_file}")
              async_download(uri, tar_file) { done.call }
            when 2
              set_message("Extracting bundle…")
              set_download_message(" ")
              extract_tar_gz(tar_file, extract_dir, verbose: verbose)
              entries = Dir.glob(File.join(extract_dir, "{*,.*}"), File::FNM_DOTMATCH)
                          .reject { |p| [".",".."].include?(File.basename(p)) }
              raise Error, "Bundle appears empty" if entries.empty?
              @price_entries = entries
              done.call
            when 3
              set_message("Installing Materials/price…")
              safe_replace_dir!(dst_price, nil, verbose: verbose) # clears dst_price safely (not protected)
              FileUtils.mkdir_p(dst_price)
              @price_entries.each do |src|
                dest = File.join(dst_price, File.basename(src))
                FileUtils.cp_r(src, dest, remove_destination: false, preserve: false, verbose: verbose)
              end
              done.call
            when 4
              set_message("Cleaning up…")
              FileUtils.rm_rf(tmpdir)
              log(verbose, "Prices update complete")
              done.call
            when 5
              Sketchup.quit
            end
          rescue => e
            failed = true
            begin; FileUtils.rm_rf(tmpdir); rescue; end
            UI.messagebox("Prices update failed: #{e.class} - #{e.message}")
            done.call
          end
        end
        return true
      end

      # Fallback (no HtmlDialog)
      Dir.mktmpdir("ar_prices-") do |tmpdir|
        tar_file    = File.join(tmpdir, "prices.tar.gz")
        extract_dir = File.join(tmpdir, "extract")

        log(verbose, "Downloading #{bundle_url} -> #{tar_file}")
        URI.open(uri, "rb") { |io| File.open(tar_file, "wb") { |f| IO.copy_stream(io, f) } }

        extract_tar_gz(tar_file, extract_dir, verbose: verbose)
        entries = Dir.glob(File.join(extract_dir, "{*,.*}"), File::FNM_DOTMATCH)
                    .reject { |p| [".",".."].include?(File.basename(p)) }
        raise Error, "Bundle appears empty" if entries.empty?

        safe_replace_dir!(dst_price, nil, verbose: verbose)
        FileUtils.mkdir_p(dst_price)
        entries.each do |src|
          dest = File.join(dst_price, File.basename(src))
          FileUtils.cp_r(src, dest, remove_destination: false, preserve: false, verbose: verbose)
        end
      end
      true
    rescue => e
      raise Error, "update_prices failed: #{e.class}: #{e.message}"
    end

    def update_resource(bundle_url = "https://artrocket-eu.s3.eu-central-1.amazonaws.com/AR_RESOURCES.tar.gz", verbose: false)
      uri = URI.parse(bundle_url)
      raise Error, "Only HTTPS URLs are supported" unless uri.scheme == "https"

      # Expected remote checksum file, produced by:
      #   sha256sum AR_RESOURCES.tar.gz > AR_RESOURCES.tar.gz.sha256
      sha_uri = URI.parse(bundle_url + ".sha256")

      materials_root  = Sketchup.find_support_file("Materials")
      components_root = Sketchup.find_support_file("Components")
      templates_root  = Sketchup.find_support_file("Templates")
      raise Error, "SketchUp 'Materials' folder not found"  unless materials_root && Dir.exist?(materials_root)
      raise Error, "SketchUp 'Components' folder not found" unless components_root && File.dirname(components_root)
      raise Error, "SketchUp 'Templates' folder not found"  unless templates_root && File.dirname(templates_root)

      if defined?(UI::HtmlDialog)
        tmpdir      = Dir.mktmpdir("ar_resources-")
        tar_file    = File.join(tmpdir, File.basename(uri.path).to_s.empty? ? "AR_RESOURCES.tar.gz" : File.basename(uri.path))
        sha_file    = tar_file + ".sha256"
        extract_dir = File.join(tmpdir, "extract")

        steps = [
          "Prepare workspace",
          "Download checksum (.sha256)",
          "Download bundle",
          "Verify checksum",
          "Extract files",
          "Install Materials",
          "Install Components",
          "Install Templates",
          "Cleanup",
          "Restart"
        ]
        failed = false

        run_with_progress(title: "Updating Resources", steps: steps) do |i, _label, done|
          break if failed
          begin
            case i
            when 0
              log(verbose, "Preparing temp dir #{tmpdir}")
              FileUtils.mkdir_p(File.dirname(tar_file))
              FileUtils.rm_rf(extract_dir)
              # We track the big payload size for the main download progress
              @file_size = head_content_length(uri)
              set_download_progress(0.0, "Waiting to start…")
              done.call

            when 1
              # Download .sha256 first (small file) WITHOUT using the progress bar
              set_download_indeterminate(true, "Downloading checksum…")
              log(verbose, "Downloading #{sha_uri} -> #{sha_file}")
              begin
                download_file_blocking(sha_uri, sha_file)
              ensure
                # Keep the bar reserved for the big archive; reset to 0% visual
                set_download_indeterminate(false, "Waiting to start archive download…")
                set_download_progress(0.0, "Waiting to start…")
              end
              done.call

            when 2
              # Download archive
              log(verbose, "Downloading #{bundle_url} -> #{tar_file}")
              async_download(uri, tar_file) { done.call }

            when 3
              # Verify
              set_message("Verifying checksum…")
              set_download_message(" ")
              verify_checksum!(tar_file, sha_file)
              done.call

            when 4
              set_message("Extracting bundle…")
              set_download_message(" ")
              extract_tar_gz(tar_file, extract_dir, verbose: verbose)

              @src_materials_suf = File.join(extract_dir, "Materials")
              @src_components    = File.join(extract_dir, "Components")
              @src_templates     = File.join(extract_dir, "Templates")
              raise Error, "Bundle missing Materials" unless Dir.exist?(@src_materials_suf)
              raise Error, "Bundle missing Components"    unless Dir.exist?(@src_components)
              raise Error, "Bundle missing Templates"     unless Dir.exist?(@src_templates)
              done.call

            when 5
              set_message("Installing Materials…")
              safe_replace_dir!(materials_root, @src_materials_suf, verbose: verbose)
              done.call

            when 6
              set_message("Installing Components…")
              safe_replace_dir!(components_root, @src_components, verbose: verbose)
              done.call

            when 7
              set_message("Installing Templates…")
              safe_replace_dir!(templates_root, @src_templates, verbose: verbose)
              done.call

            when 8
              set_message("Cleaning up…")
              FileUtils.rm_rf(tmpdir)
              log(verbose, "Resource update complete")
              done.call

            when 9
              Sketchup.quit
            end
          rescue => e
            failed = true
            begin; FileUtils.rm_rf(tmpdir); rescue; end
            UI.messagebox("Resource update failed: #{e.class} - #{e.message}")
            done.call
          end
        end
        return true
      end

      # Fallback (no HtmlDialog)
      Dir.mktmpdir("ar_resources-") do |tmpdir|
        tar_file    = File.join(tmpdir, "AR_RESOURCES.tar.gz")
        sha_file    = tar_file + ".sha256"
        extract_dir = File.join(tmpdir, "extract")

        # 1) Download checksum file first
        log(verbose, "Downloading #{sha_uri} -> #{sha_file}")
        URI.open(sha_uri, "rb") { |io| File.open(sha_file, "wb") { |f| IO.copy_stream(io, f) } }

        # 2) Download archive
        log(verbose, "Downloading #{bundle_url} -> #{tar_file}")
        URI.open(uri, "rb") { |io| File.open(tar_file, "wb") { |f| IO.copy_stream(io, f) } }

        # 3) Verify checksum (certutil or Ruby)
        verify_checksum!(tar_file, sha_file)

        # 4) Extract & install
        extract_tar_gz(tar_file, extract_dir, verbose: verbose)

        src_materials_suf = File.join(extract_dir, "Materials")
        src_components    = File.join(extract_dir, "Components")
        src_templates     = File.join(extract_dir, "Templates")
        raise Error, "Bundle missing Materials/SUF" unless Dir.exist?(src_materials_suf)
        raise Error, "Bundle missing Components"    unless Dir.exist?(src_components)
        raise Error, "Bundle missing Templates"     unless Dir.exist?(src_templates)

        safe_replace_dir!(File.join(materials_root, "SUF"), src_materials_suf, verbose: verbose)
        safe_replace_dir!(components_root,            src_components,    verbose: verbose)
        safe_replace_dir!(templates_root,             src_templates,     verbose: verbose)
      end
      true
    rescue => e
      raise Error, "update_resource failed: #{e.class}: #{e.message}"
    end

    def update(source_url, _destination_path_ignored = nil, verbose: false, keep: [])
      uri = URI.parse(source_url)
      raise Error, "Only HTTP(S) URLs are supported" unless %w[http https].include?(uri.scheme)

      # ---------- Resolve install path: Plugins root ----------
      plugins_root = Sketchup.find_support_file("Plugins")
      raise Error, "SketchUp 'Plugins' folder not found" unless plugins_root && Dir.exist?(plugins_root)
      destination_path = plugins_root
      FileUtils.mkdir_p(destination_path)

      # ---------- NO bulk clean of Plugins root ----------
      # (We only overwrite conflicting names during install; protected/kept targets are skipped.)

      # Normalize keep list (caller-defined), relative to Plugins root (e.g., "suf/rgloader/**")
      keep_specs = Array(keep).compact.map!(&:to_s)

      if defined?(UI::HtmlDialog)
        # --- Async UI path ---
        tmpdir      = Dir.mktmpdir("updater-")
        base_name   = File.basename(uri.path.to_s)
        tar_file    = File.join(tmpdir, base_name.empty? ? "archive.tar.gz" : base_name)
        extract_dir = File.join(tmpdir, "extract")
        cleaned     = uri.path.to_s.sub(/\A\//, "").sub(/\.tar\.gz\z/i, "").sub(/\.tgz\z/i, "")

        steps = [
          "Prepare workspace",
          "Download archive",
          "Extract files",
          "Install to Plugins",
          "Cleanup",
          "Restart"
        ]

        failed = false

        run_with_progress(title: "Updating #{cleaned}", steps: steps) do |i, _label, done|
          break if failed
          begin
            case i
            when 0
              log(verbose, "Preparing temp dir #{tmpdir}")
              FileUtils.mkdir_p(File.dirname(tar_file))
              FileUtils.rm_rf(extract_dir)
              @file_size = head_content_length(uri)
              set_download_progress(0.0, "Waiting to start…")
              done.call

            when 1
              log(verbose, "Downloading #{source_url} -> #{tar_file}")
              async_download(uri, tar_file) { done.call }

            when 2
              set_message("Extracting files…")
              set_download_message(" ")
              FileUtils.mkdir_p(extract_dir)
              extract_tar_gz(tar_file, extract_dir, verbose: verbose)
              done.call

            when 3
              set_message("Installing to Plugins…")
              install_to_destination(extract_dir, destination_path, verbose: verbose, keep_specs: keep_specs)
              done.call

            when 4
              set_message("Cleaning up…")
              FileUtils.rm_rf(tmpdir)
              log(verbose, "Update complete")
              done.call

            when 5
              Sketchup.quit
            end
          rescue => e
            failed = true
            begin; FileUtils.rm_rf(tmpdir); rescue; end
            UI.messagebox("Update failed: #{e.class} - #{e.message}")
            done.call
          end
        end

        return true
      end

      # --- Fallback: synchronous behavior (no HtmlDialog) ---
      Dir.mktmpdir("updater-") do |tmpdir|
        tar_file    = File.join(tmpdir, File.basename(uri.path).to_s.empty? ? "archive.tar.gz" : File.basename(uri.path))
        extract_dir = File.join(tmpdir, "extract")

        log(verbose, "Downloading #{source_url} -> #{tar_file}")
        URI.open(uri, "rb") { |io| File.open(tar_file, "wb") { |f| IO.copy_stream(io, f) } }

        FileUtils.mkdir_p(extract_dir)
        extract_tar_gz(tar_file, extract_dir, verbose: verbose)
        install_to_destination(extract_dir, destination_path, verbose: verbose, keep_specs: keep_specs)
      end

      true
    rescue => e
      raise Error, e.message
    end

    # ----------------------------
    # Download (async)
    # ----------------------------
    def async_download(uri, tar_file, &on_done)
      kind, exe = detect_downloader
      if kind
        async_download_via_process(kind, exe, uri, tar_file, &on_done)
      else
        async_download_via_ruby(uri, tar_file, &on_done)
      end
    end

    def async_download_via_ruby(uri, tar_file, &on_done)
      FileUtils.mkdir_p(File.dirname(tar_file))
      total  = (@file_size && @file_size.to_i > 0) ? @file_size.to_i : 0
      copied = 0
      err    = nil
      rechecked_total = false

      set_download_indeterminate(true, "Connecting to server…")

      worker = Thread.new do
        begin
          URI.open(uri, "rb") do |io|
            if total <= 0
              begin
                hdr_len = io.respond_to?(:meta) ? io.meta["content-length"] : nil
                hdr_len = hdr_len.to_i if hdr_len
                total = hdr_len if hdr_len && hdr_len > 0
              rescue; end
            end

            set_download_indeterminate(false, "Downloading…")

            File.open(tar_file, "wb") do |out|
              bufsize     = 1024 * 256
              yield_every = 8 * 1024 * 1024
              last_yield  = 0
              while (chunk = io.read(bufsize))
                out.write(chunk)
                copied += chunk.bytesize
                if (copied - last_yield) >= yield_every
                  last_yield = copied
                  sleep 0
                end
              end
            end
          end
        rescue => e
          err = e
        end
      end

      timer = UI.start_timer(0.12, true) do
        begin
          bytes_file = (File.exist?(tar_file) && File.size?(tar_file)) || 0
          bytes      = [copied, bytes_file].max

          if (total.nil? || total <= 0) && bytes > 0 && !rechecked_total
            rechecked_total = true
            begin
              new_total = head_content_length(uri)
              total = new_total if new_total && new_total > 0
            rescue; end
          end

          if total && total > 0
            pct   = bytes.fdiv(total) * 100.0
            set_download_progress(pct, "Downloading… #{human_bytes(bytes)}/#{human_bytes(total)}")
          else
            set_download_progress(nil, "Downloading… #{human_bytes(bytes)}")
          end

          unless worker.alive?
            UI.stop_timer(timer)
            raise err if err
            set_download_progress(100.0, "Download complete")
            on_done.call if on_done
          end
        rescue => e
          UI.stop_timer(timer)
          worker.kill rescue nil
          raise e
        end
      end
    end
    private :async_download_via_ruby

    def async_download_via_process(kind, exe, uri, tar_file, &on_done)
      FileUtils.mkdir_p(File.dirname(tar_file))
      total   = (@file_size && @file_size.to_i > 0) ? @file_size.to_i : 0
      started = Time.now
      argv =
        if kind == :curl
          [exe, "-L", "--fail", "--silent", "--show-error", "--output", tar_file, uri.to_s]
        else
          [exe, "-q", "-O", tar_file, uri.to_s]
        end

      set_download_indeterminate(true, "Connecting to server…")

      wait_thr = nil
      begin
        stdin, stdout, stderr, wait_thr = Open3.popen3(*argv)
        [stdin, stdout, stderr].each { |io| io.close rescue nil }
      rescue => e
        raise Error, "Couldn't start #{kind}: #{e.message}"
      end

      timer = UI.start_timer(0.15, true) do
        begin
          bytes = File.size?(tar_file) || 0
          set_download_indeterminate(false, "Downloading…") if bytes > 0

          if (total <= 0) && (bytes > 0)
            begin
              new_total = head_content_length(uri)
              total = new_total if new_total && new_total > 0
            rescue; end
          end

          pct, msg = wget_style_readout(bytes, total, started)
          set_download_progress(pct, msg)

          unless wait_thr.alive?
            UI.stop_timer(timer)
            status = wait_thr.value
            raise Error, "#{kind} exited with #{status.exitstatus}" unless status.success?
            set_download_progress(100.0, "Download complete")
            on_done.call if on_done
          end
        rescue => e
          UI.stop_timer(timer)
          begin; Process.kill("KILL", wait_thr.pid) if wait_thr&.alive?; rescue; end
          raise e
        end
      end
    end
    private :async_download_via_process

    # ----------------------------
    # Driver (async-aware)
    # ----------------------------
    def run_with_progress(title:, steps:, &work_for_step)
      unless defined?(UI::HtmlDialog)
        UI.messagebox("UI::HtmlDialog is not available in this SketchUp version.\n(Needs SketchUp 2017 or newer.)")
        return
      end

      html = <<-HTML
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial; margin: 14px; }
          h1 { font-size: 14px; margin: 0 0 10px; }
          .bar-wrap { width: 100%; height: 16px; background: #eee; border-radius: 8px; overflow: hidden; box-shadow: inset 0 1px 2px rgba(0,0,0,.1); position: relative; }
          .bar { width: 0%; height: 100%; background: #48a868; transition: width .15s ease; }
          .meta { margin-top: 6px; font-size: 12px; color: #555; display:flex; justify-content:space-between; }
          .section { margin-top: 12px; }
          .label { font-size: 12px; color: #333; margin-bottom: 4px; }
          .msg { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 70%; }
          .pct { min-width: 64px; text-align: right; }
          @keyframes indeterminate { 0% { left: -40%; width: 40%; } 50% { left: 20%; width: 60%; } 100% { left: 100%; width: 80%; } }
          .indeterminate { position: absolute; height: 100%; background: linear-gradient(90deg, #3b82f6, #60a5fa, #3b82f6); animation: indeterminate 1.5s infinite linear; }
        </style>
      </head>
      <body>
        <h1>#{title}</h1>
        <div class="section">
          <div class="label">Overall steps</div>
          <div class="bar-wrap"><div class="bar" id="barSteps"></div></div>
          <div class="meta"><div class="msg" id="msgSteps">Starting…</div><div class="pct" id="pctSteps">0.00%</div></div>
        </div>
        <div class="section">
          <div class="label">File download</div>
          <div class="bar-wrap"><div class="bar" id="barDL"></div></div>
          <div class="meta"><div class="msg" id="msgDL">Waiting…</div><div class="pct" id="pctDL">0.00%</div></div>
        </div>
        <script>
          (function(){
            var lastStepPct=0,lastDlPct=0;
            window.setProgress=function(pct,msg){var b=document.getElementById('barSteps'),p=document.getElementById('pctSteps'),m=document.getElementById('msgSteps');if(typeof pct==='number'&&!isNaN(pct)){pct=Math.max(0,Math.min(100,pct));if(pct>=lastStepPct){lastStepPct=pct;b.style.width=pct+'%';p.textContent=pct.toFixed(2)+'%';}} if(msg!==undefined)m.textContent=msg;};
            window.setDownloadProgress=function(pct,msg){var b=document.getElementById('barDL'),p=document.getElementById('pctDL'),m=document.getElementById('msgDL');if(typeof pct==='number'&&!isNaN(pct)){pct=Math.max(0,Math.min(100,pct));if(pct>=lastDlPct){lastDlPct=pct;b.style.width=pct+'%';p.textContent=pct.toFixed(2)+'%';}} if(msg!==undefined)m.textContent=msg;};
            window.setDownloadIndeterminate=function(active,msg){var b=document.getElementById('barDL'),p=document.getElementById('pctDL'),m=document.getElementById('msgDL');b.className=active?'bar indeterminate':'bar';p.textContent=active?'':p.textContent;if(msg!==undefined)m.textContent=msg;};
            window.setMessage=function(msg){document.getElementById('msgSteps').textContent=msg;};
            window.setDownloadMessage=function(msg){document.getElementById('msgDL').textContent=msg;};
          })();
        </script>
      </body>
      </html>
      HTML

      dlg = $update_dlg = UI::HtmlDialog.new(
        dialog_title: title,
        preferences_key: "progress_#{title.gsub(/\s+/, '_')}",
        resizable: false,
        width: 420,
        height: 250,
        style: UI::HtmlDialog::STYLE_UTILITY
      )
      dlg.set_html(html)
      dlg.show

      @__dlg_set_message      = proc { |msg| dlg.execute_script("setMessage(#{JSON.dump(msg.to_s)})") }
      @__dlg_set_download     = proc { |pct, msg| dlg.execute_script("setDownloadProgress(#{pct.nil? ? 'null' : pct.to_f}, #{JSON.dump(msg.to_s)})") }
      @__dlg_set_download_msg = proc { |msg| dlg.execute_script("setDownloadMessage(#{JSON.dump(msg.to_s)})") }

      i = -1
      total = steps.length
      @__advancing = false
      next_step = nil

      next_step = -> do
        i += 1
        if i >= total
          dlg.execute_script("setProgress(100, #{JSON.dump('Done')})")
          UI.start_timer(0.25, false) { dlg.close }
          return
        end

        pct   = (i.to_f / total) * 100.0
        label = steps[i].to_s
        dlg.execute_script("setProgress(#{pct}, #{label.inspect})")

        done = -> do
          return if @__advancing
          @__advancing = true
          UI.start_timer(0.02, false) do
            @__advancing = false
            next_step.call
          end
        end

        begin
          work_for_step.call(i, label, done) if work_for_step
        rescue => e
          Sketchup.set_status_text("Error at step #{i + 1}: #{e.class} - #{e.message}")
          done.call
        end
      end

      next_step.call
    end

    def set_message(msg)              @__dlg_set_message&.call(msg.to_s) end
    def set_download_progress(pct,msg)@__dlg_set_download&.call(pct, msg) end
    def set_download_message(msg)     @__dlg_set_download_msg&.call(msg) end

    def set_download_indeterminate(active, msg)
      js_active = active ? "true" : "false"
      $update_dlg.execute_script("setDownloadIndeterminate(#{js_active}, #{JSON.dump(msg.to_s)})")
    end
    private :set_message, :set_download_progress, :set_download_message, :set_download_indeterminate

    # ----------------------------
    # Extract & Install
    # ----------------------------
    # def extract_tar_gz(tgz_path, dest_dir, verbose:)
    #   FileUtils.mkdir_p(dest_dir)
    #   log(verbose, "Extracting tar.gz -> #{dest_dir}")
    #   Zlib::GzipReader.open(tgz_path) do |gz|
    #     Gem::Package::TarReader.new(gz) { |tar| tar.each { |entry| write_tar_entry(entry, dest_dir) } }
    #   end
    # end

    # def extract_tar_gz(tgz_path, dest_dir, verbose:)
    #   FileUtils.mkdir_p(dest_dir)

    #   # Try system tar first — far more forgiving
    #   if (tar_exe = which("tar"))
    #     log(verbose, "Using system tar: #{tar_exe}")
    #     ok = system(tar_exe, "-xzf", tgz_path, "-C", dest_dir)
    #     return true if ok
    #     log(verbose, "system tar failed; falling back to Ruby")
    #   end

    #   # Ruby path with end-padding “repair”
    #   if gzip_file?(tgz_path)
    #     Zlib::GzipReader.open(tgz_path) do |gz|
    #       Tempfile.create(["ar_unpack", ".tar"]) do |tf|
    #         IO.copy_stream(gz, tf)
    #         pad = (512 - (tf.size % 512)) % 512
    #         tf.write("\0" * pad)
    #         tf.write("\0" * 1024) # two zero blocks = end-of-archive
    #         tf.flush; tf.rewind
    #         Gem::Package::TarReader.new(tf) { |tar| tar.each { |e| write_tar_entry(e, dest_dir) } }
    #       end
    #     end
    #   else
    #     # Plain .tar path
    #     File.open(tgz_path, "rb") do |io|
    #       # Also pad plain tars if needed to satisfy strict readers
    #       size = File.size(tgz_path)
    #       need = (512 - (size % 512)) % 512
    #       Tempfile.create(["ar_tar", ".tar"]) do |tf|
    #         IO.copy_stream(io, tf)
    #         tf.write("\0" * need)
    #         tf.write("\0" * 1024)
    #         tf.flush; tf.rewind
    #         Gem::Package::TarReader.new(tf) { |tar| tar.each { |e| write_tar_entry(e, dest_dir) } }
    #       end
    #     end
    #   end
    # rescue Gem::Package::TarReader::UnexpectedEOFError => e
    #   raise Error, "extract failed (TAR EOF) — archive is incomplete or corrupted: #{e.message}"
    # rescue Zlib::GzipFile::Error => e
    #   raise Error, "extract failed (GZIP) — not a .tar.gz or was auto-decoded by CDN: #{e.message}"
    # end


    # private :extract_tar_gz

    def extract_tar_gz(tgz_path, dest_dir, verbose:)
      FileUtils.mkdir_p(dest_dir)

      if Gem.win_platform?
        # --- Windows: bsdtar (System32\tar.exe) ---
        bsdtar = File.join(ENV.fetch('WINDIR', 'C:/Windows'), 'System32', 'tar.exe').gsub('\\','/')
        raise Error, "bsdtar not found at #{bsdtar}" unless File.exist?(bsdtar)

        # Your working combo: -xvf + UTF-8 headers; (-z not required for bsdtar)
        enc = 'CP1251'  # if you ever get a legacy archive, try 'CP1251' or 'CP866'
        env = { 'LC_ALL' => 'C.CP1251', 'LANG' => 'C.CP1251' } # harmless if ignored
        args = [bsdtar, '-xvf', tgz_path, '-C', dest_dir, '--options', "hdrcharset=#{enc}"]

        puts "[Updater] Using bsdtar: #{bsdtar}" if verbose
        out, err, st = Open3.capture3(env, *args)

        # Save bsdtar warnings/errors like `2> bsdtar.err.txt`
        err_path = File.join(dest_dir, 'bsdtar.err.txt')
        File.write(err_path, err) unless err.to_s.empty?

        raise Error, "bsdtar failed (#{st.exitstatus}): #{(err.empty? ? out : err).strip}" unless st.success?
      else
        # --- macOS/Linux: regular tar ---
        tar = which('tar') || 'tar'
        args = [tar, '-xzf', tgz_path, '-C', dest_dir, '--no-same-owner']
        puts "[Updater] Using tar: #{tar}" if verbose
        out, err, st = Open3.capture3(*args)
        raise Error, "tar failed (#{st.exitstatus}): #{(err.empty? ? out : err).strip}" unless st.success?
      end

      true
    end
    private :extract_tar_gz

    def write_tar_entry(entry, dest_dir)
      target = File.join(dest_dir, entry.full_name)
      if entry.directory?
        FileUtils.mkdir_p(target)
      elsif entry.file?
        FileUtils.mkdir_p(File.dirname(target))
        File.open(target, "wb") { |f| IO.copy_stream(entry, f) }
        FileUtils.chmod(entry.header.mode, target) if entry.header.mode
      elsif entry.header.typeflag == "2" # symlink
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.ln_s(entry.header.linkname, target, force: true)
      end
    end
    private :write_tar_entry

    # Non-destructive installer: copies entries one by one; only removes conflicting target if not protected or kept.
    # Non-destructive installer: merges directory contents and only replaces conflicting
    # targets that are NOT protected and NOT kept by the provided globs.
    def install_to_destination(prepared_root, destination_path, verbose: false, keep_specs: [])
      raise ArgumentError, "missing prepared_root" unless prepared_root && Dir.exist?(prepared_root)

      # If someone calls us with identical paths, just no-op safely.
      if File.expand_path(prepared_root) == File.expand_path(destination_path)
        log(verbose, "install_to_destination: prepared_root == destination_path; nothing to do.")
        return true
      end

      FileUtils.mkdir_p(destination_path)

      # Build a keeper that evaluates patterns relative to the destination root
      keeper = lambda do |abs|
        rel = begin
          Pathname.new(abs).relative_path_from(Pathname.new(destination_path)).to_s
        rescue
          File.basename(abs)
        end
        keep_specs.any? do |spec|
          if spec.include?('*') || spec.include?('?') || spec.include?('[')
            File.fnmatch?(spec, rel, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD)
          else
            rel.casecmp?(spec) || rel.start_with?(spec.end_with?('/') ? spec : "#{spec}/")
          end
        end
      end

      # Copy each top-level entry from the extracted bundle
      entries = Dir.glob(File.join(prepared_root, "{*,.*}"), File::FNM_DOTMATCH)
                  .reject { |p| [".",".."].include?(File.basename(p)) }

      entries.each do |src|
        dst = File.join(destination_path, File.basename(src))

        # If the top-level target itself is protected or kept, skip replacing it wholesale.
        if protected_path?(dst, destination_path)
          log(verbose, "Skipping protected target: #{dst}")
          next
        end
        if keeper.call(dst)
          log(verbose, "Skipping kept target: #{dst}")
          next
        end

        if File.directory?(src)
          # Merge the directory tree, honoring keep/protected at every node
          merge_copy_dir!(src, dst, destination_path, verbose, keeper)
        else
          # Single file/symlink
          FileUtils.mkdir_p(File.dirname(dst))
          if File.exist?(dst) || File.symlink?(dst)
            FileUtils.rm_rf(dst)
          end
          FileUtils.cp_r(src, dst, preserve: false, remove_destination: false, verbose: verbose)
        end
      end
      true
    end
    private :install_to_destination

    # Recursively merge + copy a directory tree from src_dir into dst_dir,
    # skipping any targets that are protected or match 'keep' patterns.
    def merge_copy_dir!(src_dir, dst_dir, destination_root, verbose, keeper)
      FileUtils.mkdir_p(dst_dir)

      Dir.glob(File.join(src_dir, "{*,.*}"), File::FNM_DOTMATCH).each do |entry|
        base = File.basename(entry)
        next if base == "." || base == ".."

        # Reconstruct the target path in destination
        rel_from_src = Pathname.new(entry).relative_path_from(Pathname.new(src_dir)).to_s
        target       = File.join(dst_dir, rel_from_src)

        # Respect protected/kept rules at the granular level
        if protected_path?(target, destination_root)
          log(verbose, "Skipping protected target: #{target}")
          next
        end
        if keeper.call(target)
          log(verbose, "Skipping kept target: #{target}")
          next
        end

        if File.directory?(entry) && !File.symlink?(entry)
          FileUtils.mkdir_p(target)
          merge_copy_dir!(entry, target, destination_root, verbose, keeper)
        else
          FileUtils.mkdir_p(File.dirname(target))
          if File.exist?(target) || File.symlink?(target)
            FileUtils.rm_rf(target)
          end
          FileUtils.cp_r(entry, target, preserve: false, remove_destination: false, verbose: verbose)
        end
      end
      true
    end
    private :merge_copy_dir!


    # Safe replace whole directory (used by resources/prices). If src_dir is nil, we just clear target.
    def safe_replace_dir!(target_dir, src_dir, verbose: false)
      # refuse to remove protected dirs
      if Dir.exist?(target_dir)
        parent = File.dirname(target_dir)
        if protected_path?(target_dir, parent)
          raise Error, "Refusing to remove protected directory: #{target_dir}"
        end
        FileUtils.rm_rf(target_dir)
      end
      return true unless src_dir # only clearing
      FileUtils.mkdir_p(File.dirname(target_dir))
      FileUtils.cp_r(src_dir, target_dir, remove_destination: false, preserve: false, verbose: verbose)
      true
    end
    private :safe_replace_dir!

    # ----------------------------
    # Utilities
    # ----------------------------
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.exist?(exe) && File.executable?(exe)
        end
      end
      nil
    end
    private :which

    def detect_downloader
      if (exe = which('curl'))
        [:curl, exe]
      elsif (exe = which('wget'))
        [:wget, exe]
      else
        nil
      end
    end
    private :detect_downloader

    def wget_style_readout(bytes, total, started_at)
      elapsed = [Time.now - started_at, 0.001].max
      speed   = bytes / elapsed.to_f
      speed_h = human_bytes(speed) + "/s"
      if total && total > 0
        pct = (bytes.to_f / total) * 100.0
        remaining = [total - bytes, 0].max
        eta_s = speed > 0 ? (remaining / speed).to_i : nil
        eta   = eta_s ? format("%02d:%02d", eta_s / 60, eta_s % 60) : "--:--"
        ["Downloading… #{human_bytes(bytes)}/#{human_bytes(total)}  #{speed_h}  eta #{eta}", pct]
      else
        ["Downloading… #{human_bytes(bytes)}  #{speed_h}", nil]
      end.then { |msg, pct| [pct, msg] }
    end
    private :wget_style_readout

    def head_content_length(uri, max_redirects: 5)
      raise "Too many redirects" if max_redirects < 0
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        resp = http.request_head(uri.request_uri)
        if resp.is_a?(Net::HTTPRedirection)
          location = resp["location"] or raise "Missing Location for redirect"
          next_uri = URI.join(uri, location)
          return head_content_length(next_uri, max_redirects: max_redirects - 1)
        end
        len = resp["content-length"]
        return len.to_i if len
      end
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Range"] = "bytes=0-0"
        resp = http.request(req)
        cr = resp["content-range"]
        if cr && (m = cr.match(%r{/(\d+)\z}))
          return m[1].to_i
        end
      end
      0
    rescue
      0
    end
    private :head_content_length

    def human_bytes(n)
      return "0 B" unless n && n > 0
      units = %w[B KB MB GB TB]
      i = 0
      num = n.to_f
      while num >= 1024 && i < units.length - 1
        num /= 1024.0; i += 1
      end
      format('%.1f %s', num, units[i])
    end
    private :human_bytes

    def log(verbose, msg)
      puts "[Updater] #{msg}" if verbose
    end
    private :log

    # ----------------------------
    # Checksum helpers
    # ----------------------------
    def parse_sha256_file(path)
      text = File.read(path)
      m = text.match(/\b([A-Fa-f0-9]{64})\b/)
      raise Error, "SHA256 file malformed: #{path}" unless m
      m[1].downcase
    rescue => e
      raise Error, "Failed to read/parse SHA256 file: #{e.message}"
    end
    private :parse_sha256_file

    def compute_sha256(file)
      Digest::SHA256.file(file).hexdigest
    rescue => e
      raise Error, "Checksum computation failed: #{e.message}"
    end

    private :compute_sha256

    def verify_checksum!(tar_file, sha_file)
      expected = parse_sha256_file(sha_file)
      actual   = compute_sha256(tar_file)
      raise Error, "Checksum mismatch:\n  expected: #{expected}\n  got:      #{actual}" unless expected == actual
      true
    end
    private :verify_checksum!

    # Small, blocking download (no progress updates)
    def download_file_blocking(uri, dst_path)
      FileUtils.mkdir_p(File.dirname(dst_path))
      URI.open(uri, "rb") { |io| File.open(dst_path, "wb") { |f| IO.copy_stream(io, f) } }
      true
    end
    private :download_file_blocking

  end


  module Versioner
    extend self
    require 'fileutils'

    def plugin_version
      materials_dir = Sketchup.find_support_file("Materials")
      plugins_dir = Sketchup.find_support_file("Plugins")
      raise "Materials folder not found" unless materials_dir && Dir.exist?(materials_dir)
      raise "Plugins folder not found" unless plugins_dir && Dir.exist?(plugins_dir)

      plugins_dir = File.join(plugins_dir, "suf")
      FileUtils.mkdir_p(plugins_dir)  # create if missing

      plugin_version_path = File.join(plugins_dir, "version.txt")

      # read file contents (UTF-8) if it exists; nil otherwise
      if File.exist?(plugin_version_path)
        File.read(plugin_version_path, mode: "rb", encoding: "UTF-8").strip
      else
        '1.0.0'
      end
    end

    def price_version
      price_dir = Sketchup.find_support_file("Materials")
      raise "Price folder not found" unless price_dir && Dir.exist?(price_dir)

      price_dir = File.join(price_dir, "price")
      FileUtils.mkdir_p(price_dir)  # create if missing

      price_version_path = File.join(price_dir, "version.txt")

      # read file contents (UTF-8) if it exists; nil otherwise
      if File.exist?(price_version_path)
        File.read(price_version_path, mode: "rb", encoding: "UTF-8").strip
      else
        '1.0.0'
      end
    end

    def resource_version
      resource_dir = Sketchup.find_support_file("Materials")
      raise "Resource folder not found" unless resource_dir && Dir.exist?(resource_dir)

      resource_dir = File.join(resource_dir, "suf")
      FileUtils.mkdir_p(resource_dir)  # create if missing

      resource_version_path = File.join(resource_dir, "version.txt")

      # read file contents (UTF-8) if it exists; nil otherwise
      if File.exist?(resource_version_path)
        File.read(resource_version_path, mode: "rb", encoding: "UTF-8").strip
      else
        '1.0.0'
      end
    end
  end

  module CryptoBox
    extend self
    require "openssl"
    require "base64"
    require "json"
    require "digest"

    # Derive a stable 32-byte key from local secrets.
    def key_for(machine_id:, registration_code:, pepper:)
      OpenSSL::Digest::SHA256.digest("#{machine_id}|#{registration_code}|#{pepper}")
    end

    # Returns JSON string: {"v":1,"alg":"AES-256-GCM","n":"...","ct":"...","tag":"..."}
    def encrypt_json(obj, key)
      json = JSON.dump(obj)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = key
      nonce = OpenSSL::Random.random_bytes(12)
      cipher.iv = nonce
      ct = cipher.update(json) + cipher.final
      tag = cipher.auth_tag
      JSON.dump({ v: 1, alg: "AES-256-GCM",
                  n: Base64.strict_encode64(nonce),
                  ct: Base64.strict_encode64(ct),
                  tag: Base64.strict_encode64(tag) })
    end

    def decrypt_json(enc_json, key)
      box = JSON.parse(enc_json)
      raise "bad box" unless box["v"] == 1 && box["alg"] == "AES-256-GCM"
      nonce = Base64.strict_decode64(box["n"])
      ct    = Base64.strict_decode64(box["ct"])
      tag   = Base64.strict_decode64(box["tag"])
      dec = OpenSSL::Cipher.new("aes-256-gcm")
      dec.decrypt
      dec.key = key
      dec.iv  = nonce
      dec.auth_tag = tag
      plain = dec.update(ct) + dec.final
      JSON.parse(plain)
    end
  end

#//////////////////////////////
# frozen_string_literal: true
  module UIHelpers
    # Show an HTML dialog informing the user about an expired license/trial.
    #
    # @param title [String]   Window title
    # @param message [String] Main message text (HTML-safe)
    # @yield                  Optional block called after user presses "OK"
    def self.show_expiry_message(title: "Trial expired",
                                 message: "Your trial has expired. Please activate to continue.",
                                 &on_ok)
      if defined?(UI::HtmlDialog)
        show_expiry_message_html_dialog(title, message, &on_ok)
      else
        show_expiry_message_web_dialog(title, message, &on_ok)
      end
    end

    # ---- HtmlDialog (SketchUp 2017+) ----
    def self.show_expiry_message_html_dialog(title, message, &on_ok)
      dlg = UI::HtmlDialog.new(
        dialog_title: message,
        preferences_key: "Artrocket Plugin",
        resizable: false,
        width: 550,
        height: 500,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Expiry page</title>
          <style>
            html, body, frameset, frame {
              width: 100%;
              height: 100%;
              margin: 0;
              padding: 0;
              border: 0;
            }
            body {
              background-color: #f0f0f0;
            }
          </style>
        </head>
          <frameset rows="100%">
            <frame src="https://artrocket.ro/expira" name="expiry_frame" scrolling="no" frameborder="0" />
          </frameset>
        </html>
      HTML

      dlg.set_html(html)
      dlg.add_action_callback("ok") do |_ctx|
        dlg.close
        on_ok.call if on_ok
      end
      dlg.center
      dlg.show
      dlg
    end
    private_class_method :show_expiry_message_html_dialog

    # ---- WebDialog (pre-2017 fallback) ----
    def self.show_expiry_message_web_dialog(title, message, &on_ok)
      dlg = UI::WebDialog.new(title, true, "MyPlugin_Expiry", 440, 260, 200, 200, true)
      dlg.set_size(550, 500)
      dlg.set_url("about:blank") # prevents external navigation warning

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Full Page Iframe</title>
          <style>
            html, body, frameset, frame {
              width: 100%;
              height: 100%;
              margin: 0;
              padding: 0;
              border: 0;
            }
            body {
              background-color: #f0f0f0;
            }
          </style>
        </head>
          <frameset rows="100%">
            <frame src="https://artrocket.ro/expira" name="expiry_frame" scrolling="no" frameborder="0" />
          </frameset>
        </body>
        </html>
      HTML

      # feed the HTML to the dialog
      dlg.set_html(html)

      # receive "ok" from the skp: scheme
      dlg.add_action_callback("ok") do |_|
        dlg.close
        on_ok.call if on_ok
      end

      dlg.center
      dlg.show
      dlg
    end
    private_class_method :show_expiry_message_web_dialog

    # --- Helpers ---
    def self.escape_html(str)
      str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
    private_class_method :escape_html

    def self.show_notification_html_dialog(title, message)
      dlg = UI::HtmlDialog.new(
        dialog_title: title,
        preferences_key: "Artrocket Plugin",
        resizable: false,
        width: 550,
        height: 500,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Expiry page</title>
          <style>
            html, body, frameset, frame {
              width: 100%;
              height: 100%;
              margin: 0;
              padding: 0;
              border: 0;
            }
            body {
              background-color: #f0f0f0;
            }
          </style>
        </head>
          <frameset rows="100%">
            <frame src="https://artrocket.ro/notification?id=#{message}registration_code=#{registration_code}" name="notification_frame" scrolling="no" frameborder="0" />
          </frameset>
        </html>
      HTML

      dlg.set_html(html)
      dlg.center
      dlg.show
      dlg
    end
    private_class_method :show_expiry_message_html_dialog

    def self.show_notification
      message = ValidatorPlugin::LicenseValidator.notification_id
      show_notification_html_dialog('Notification', message) if message
    end
  end

#//////////////////////////////

  module TimeTracker
    PLUGIN_NAME  = "Time Tracker".freeze
    PLUGIN_ID    = "time_tracker_plugin".freeze
    VERSION      = "1.1.0".freeze

    APP_DATA_DIR = File.join(Sketchup.find_support_file('Plugins'), PLUGIN_ID)
    DATA_FILE    = File.join(APP_DATA_DIR, 'global_time.json')

    unless defined?(@loaded)
      @loaded = true
      FileUtils.mkdir_p(APP_DATA_DIR) rescue nil

      # ----------------------------------------------------------------------------
      # Core manager
      # ----------------------------------------------------------------------------
      class Manager
        include Singleton if defined?(::Singleton)

        TICK_SEC = 1.0
        MAX_SESSIONS = 20

        def initialize
          @running          = false
          @timer_id         = nil
          @last_tick_at     = nil
          @session_started  = nil
          @session_elapsed  = 0.0
          @dialog           = nil
          ensure_store!
        end

        # ----------------------------- persistence & shared store ------------------
        def ensure_store!
          return if File.exist?(DATA_FILE)
          write_store!({
            'total_seconds' => 0.0,
            'last_update_at' => Time.now.to_f,
            'version' => VERSION,
            'sessions' => []
          })
        end

        def read_store
          begin
            raw = File.read(DATA_FILE)
            h = JSON.parse(raw)
            h.is_a?(Hash) ? h : {}
          rescue
            {}
          end
        end

        def write_store!(hash)
          tmp = DATA_FILE + '.tmp'
          begin
            File.open(tmp, 'w') { |f| f.write(JSON.generate(hash)) }
            FileUtils.mv(tmp, DATA_FILE)
          rescue
            # best-effort
          ensure
            begin; File.delete(tmp) if File.exist?(tmp); rescue; end
          end
        end

        # Add delta to shared file with a lock so multiple windows/instances do not double-count
        def add_global_delta!(delta)
          return if delta <= 0
          begin
            File.open(DATA_FILE, File::RDWR|File::CREAT, 0644) do |f|
              f.flock(File::LOCK_EX)
              raw = f.read
              h = raw && raw.size > 0 ? (JSON.parse(raw) rescue {}) : {}
              total = (h['total_seconds'] || 0.0).to_f
              last  = (h['last_update_at'] || Time.now.to_f).to_f
              now   = Time.now.to_f

              shared_delta = now - last
              shared_delta = 0.0 if shared_delta < 0
              shared_delta = [shared_delta, 600.0].min # cap per tick (sleep/resume safety)

              total += shared_delta
              h['total_seconds']  = total
              h['last_update_at'] = now

              f.rewind
              f.truncate(0)
              f.write(JSON.generate(h))
              f.flush
            end
          rescue
            # ignore
          end
        end

        def total_seconds
          (read_store['total_seconds'] || 0.0).to_f
        end

        def push_session_start!(time = Time.now)
          begin
            File.open(DATA_FILE, File::RDWR|File::CREAT, 0644) do |f|
              f.flock(File::LOCK_EX)
              raw = f.read
              h = raw && raw.size > 0 ? (JSON.parse(raw) rescue {}) : {}
              list = (h['sessions'] || []).map(&:to_s)
              list.unshift(time.iso8601)
              list = list.take(MAX_SESSIONS)
              h['sessions'] = list
              h['last_update_at'] ||= time.to_f
              f.rewind
              f.truncate(0)
              f.write(JSON.generate(h))
              f.flush
            end
          rescue
            # ignore
          end
        end

        def recent_sessions
          (read_store['sessions'] || []).map { |s| s.to_s }
        end

        # ----------------------------- timer control -------------------------------
        def start!
          return if @running
          @running = true
          @session_started = Time.now
          @session_elapsed = 0.0
          push_session_start!(@session_started)
          @last_tick_at    = Time.now
          @timer_id = UI.start_timer(TICK_SEC, true) { tick }
        end

        def stop!
          return unless @running
          UI.stop_timer(@timer_id) if @timer_id
          @timer_id = nil
          @running = false
          @last_tick_at = nil
        end

        def tick
          now = Time.now
          dt  = now - (@last_tick_at || now)
          @last_tick_at = now

          @session_elapsed += dt if dt > 0 && dt < 10
          add_global_delta!(dt)
          update_dialog
        end

        # ----------------------------- UI -----------------------------------------
        def show_dialog
          if @dialog && @dialog.visible?
            @dialog.bring_to_front
            return
          end

          @dialog = UI::HtmlDialog.new(
            dialog_title: PLUGIN_NAME,
            style: UI::HtmlDialog::STYLE_DIALOG,
            preferences_key: PLUGIN_ID + '.dialog',
            width: 380,
            height: 280,
            resizable: true
          )

          html = <<~HTML
            <!doctype html>
            <html>
            <head>
              <meta charset="utf-8" />
              <title>#{PLUGIN_NAME}</title>
              <style>
                html,body{margin:0;padding:0;font-family:Inter,Segoe UI,Arial,sans-serif;background:#0b1220;color:#e6edf3}
                .wrap{padding:14px}
                .h{font-weight:700;font-size:16px;margin-bottom:10px}
                .grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
                .card{background:#111a2b;border-radius:12px;padding:12px;box-shadow:0 1px 2px rgba(0,0,0,.2)}
                .lab{font-size:11px;opacity:.7;margin-bottom:6px}
                .val{font-size:20px;font-weight:700}
                .muted{font-size:11px;opacity:.7;margin-top:2px}
                .row{display:flex;gap:8px;align-items:center;margin:10px 0}
                button{background:#1f6feb;color:white;border:0;border-radius:8px;padding:8px 10px;cursor:pointer}
                button:active{transform:translateY(1px)}
                ul{list-style:none;padding:0;margin:8px 0 0 0}
                li{font-size:12px;opacity:.9;margin:2px 0}
              </style>
            </head>
            <body>
              <div class="wrap">
                <div class="h">Time Tracker</div>
                <div class="grid">
                  <div class="card">
                    <div class="lab">Current session</div>
                    <div id="session" class="val">00:00:00</div>
                    <div class="muted" id="started_at"></div>
                  </div>
                  <div class="card">
                    <div class="lab">Total (all SketchUp windows)</div>
                    <div id="total" class="val">00:00:00</div>
                    <div class="muted">Union of wall-clock time across all instances</div>
                  </div>
                </div>
                <div class="row">
                  <button onclick="sketchup && sketchup.reset && sketchup.reset()">Reset total…</button>
                </div>
                <div class="card">
                  <div class="lab">Recent session starts (local time)</div>
                  <ul id="recent"></ul>
                </div>
              </div>
              <script>
                function fmt(sec){sec=Math.max(0,Math.floor(sec));const h=String(Math.floor(sec/3600)).padStart(2,'0');const m=String(Math.floor((sec%3600)/60)).padStart(2,'0');const s=String(sec%60).padStart(2,'0');return `${h}:${m}:${s}`}
                function update(sess,total,startedISO,recent){
                  try{
                    document.getElementById('session').textContent=fmt(sess);
                    document.getElementById('total').textContent=fmt(total);
                    if(startedISO){
                      const d=new Date(startedISO);
                      document.getElementById('started_at').textContent='Started: '+d.toLocaleString();
                    }
                    const ul=document.getElementById('recent');
                    ul.innerHTML='';
                    (recent||[]).forEach(function(iso){ const li=document.createElement('li'); const d=new Date(iso); li.textContent=d.toLocaleString(); ul.appendChild(li); });
                  }catch(e){}
                }
              </script>
            </body>
            </html>
          HTML

          @dialog.set_html(html)

          @dialog.add_action_callback('reset') do |_d, _p|
            if UI.messagebox("Reset TOTAL time counter? This cannot be undone.", MB_YESNO) == IDYES
              write_store!({ 'total_seconds' => 0.0, 'last_update_at' => Time.now.to_f, 'version' => VERSION, 'sessions' => recent_sessions })
              update_dialog(force: true)
            end
          end

          @dialog.show
          update_dialog(force: true)
        end

        def update_dialog(force: false)
          return unless @dialog && @dialog.visible?
          sess   = @session_elapsed
          total  = total_seconds
          started = @session_started ? @session_started.iso8601 : ''
          recent = recent_sessions.to_json
          js = "update(#{sess.to_i},#{total.to_i},'#{started}',#{recent});"
          @dialog.execute_script(js) rescue nil
        end

        # ----------------------------- hooks --------------------------------------
        def on_model_open_or_new(_model)
          start!
          update_dialog(force: true)
        end

        def on_quit
          stop!
        end

        def open_ui
          show_dialog
        end
      end

      # ----------------------------------------------------------------------------
      # Observers
      # ----------------------------------------------------------------------------
      class AppObs < Sketchup::AppObserver
        def onNewModel(model)
          Manager.instance.on_model_open_or_new(model)
        end
        def onOpenModel(model)
          Manager.instance.on_model_open_or_new(model)
        end
        def onQuit
          Manager.instance.on_quit
        end
      end

      Sketchup.add_observer(AppObs.new)

      # ----------------------------------------------------------------------------
      # UI: Toolbar & Menu
      # ----------------------------------------------------------------------------
      cmd = UI::Command.new(PLUGIN_NAME) { Manager.instance.open_ui }
      cmd.tooltip = 'Show Time Tracker'
      cmd.status_bar_text = 'Show Time Tracker (live total time)'
      svg = 'data:image/svg+xml;utf8,' + <<~SVG.strip
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <circle cx="12" cy="13" r="9" fill="#1f6feb"/>
          <circle cx="12" cy="13" r="7" fill="white"/>
          <path d="M12 13V7" stroke="#1f6feb" stroke-width="2" stroke-linecap="round"/>
          <path d="M12 13l4 3" stroke="#1f6feb" stroke-width="2" stroke-linecap="round"/>
          <rect x="9" y="2" width="6" height="3" rx="1.5" fill="#1f6feb"/>
        </svg>
      SVG
      cmd.small_icon = cmd.large_icon = svg

      tb = UI::Toolbar.new(PLUGIN_NAME)
      tb.add_item(cmd)
      tb.restore if tb.get_last_state == TB_VISIBLE

      UI.menu('Plugins').add_item(PLUGIN_NAME) { Manager.instance.open_ui }

      # If a model is already open when the plugin loads
      begin
        if Sketchup.active_model
          Manager.instance.on_model_open_or_new(Sketchup.active_model)
        end
      rescue; end

      puts "[#{PLUGIN_NAME}] v#{VERSION} loaded. Toolbar: View → Toolbars → #{PLUGIN_NAME}"
    end
  end
end

# Keep a strong reference so GC can't collect it.
unless defined?($validator_shutdown_observer) && $validator_shutdown_observer
  $validator_shutdown_observer = ValidatorPlugin::ShutdownObserver.new
  Sketchup.add_observer($validator_shutdown_observer)
  puts "[ValidatorPlugin] App observer installed (#{$validator_shutdown_observer.object_id})"
end
