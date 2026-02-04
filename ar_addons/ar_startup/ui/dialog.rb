# encoding: UTF-8
# ar_startup/ui/dialog
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.
require 'json'

module ARAddons
  module ARStartup
    module UI
      module Dialog
        extend self

        @dlg = nil
        @callbacks_wired = false

        def show
          # если уже открыто — просто вперёд
          if @dlg && @dlg.visible?
            begin
              @dlg.bring_to_front
            rescue
            end
            return
          end

          width  = 520
          height = 360
          title  = 'Startup Settings'

          @dlg ||= ::UI::HtmlDialog.new(
            dialog_title: title,
            preferences_key: 'ARStartup/StartupSettings',
            resizable: false,
            width: width,
            height: height,
            style: ::UI::HtmlDialog::STYLE_DIALOG
          )

          @dlg.set_on_closed do
            @callbacks_wired = false
            @dlg = nil
          end

          # мосты
          ARAddons::ARStartup::BridgeWiring.wire_dialog!(@dlg)

          logo_path = ARAddons::Utils.shared_icon('logo.png')
          logo_url  = File.exist?(logo_path) ? ('file:///' + logo_path.gsub('\\','/')) : ''

          unless @callbacks_wired
            @dlg.add_action_callback('getCurrent') do |_ctx, _|
              payload = {
                lang: ARAddons::ARStartup::Reader.active_lang_base,
                coef: ARAddons::ARStartup::Reader.cost_coef,
                curr: ARAddons::ARStartup::Reader.display_currency
              }
              @dlg.execute_script("window.__applyCurrent(#{JSON.generate(payload)});")
            end

            @dlg.add_action_callback('saveSettings') do |_ctx, json|
              begin
                data = JSON.parse(json.to_s)
                ok = ARAddons::ARStartup::Reader.write_settings(
                  lang: data['lang'],
                  coef: data['coef'],
                  curr: data['curr']
                )
                if ok
                  payload = {
                    lang: ARAddons::ARStartup::Reader.active_lang_base,
                    coef: ARAddons::ARStartup::Reader.cost_coef,
                    curr: ARAddons::ARStartup::Reader.display_currency
                  }
                  @dlg.execute_script("window.__applyCurrent(#{JSON.generate(payload)});")
                  ::UI.messagebox("Startup settings applied.\nPlease restart SketchUp.")
                end
              rescue => e
                ::UI.messagebox("Failed to save settings:\n#{e.message}")
              end
            end

            @callbacks_wired = true
          end

          root = File.expand_path(File.dirname(__FILE__))
          tpl  = File.read(File.join(root, 'settings.html'), encoding: 'UTF-8')
          css  = File.read(File.join(root, 'settings.css'),  encoding: 'UTF-8')
          js   = File.read(File.join(root, 'settings.js'),   encoding: 'UTF-8')

          @dlg.set_html(
            tpl
              .gsub('{{STYLE}}',    "<style>\n#{css}\n</style>")
              .gsub('{{SCRIPT}}',   "<script>\n#{js}\n</script>")
              .gsub('{{LOGO_URL}}', logo_url)
          )

          @dlg.show
        end
      end
    end
  end
end
