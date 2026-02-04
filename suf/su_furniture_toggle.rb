# su_furniture_toggle.rb
# Extensions → SU Furniture with SAFE MODE toggle for Entities.

# Default to not showing the menu unless explicitly disabled elsewhere
$su_furniture_toggle = false unless defined?($su_furniture_toggle)

unless defined?(SU_FURNITURE_MENU_BUILT_SAFE)
  if $su_furniture_toggle
    SU_FURNITURE_MENU_BUILT_SAFE = true

    root = (UI.menu('Extensions') rescue UI.menu('Plugins'))
    m = root.add_submenu('SU Furniture')

    def ensure_loaded
      begin
        require 'su_furniture'
      rescue LoadError
        path = File.join(Sketchup.find_support_file('Plugins'), 'su_furniture.rb')
        load path if File.exist?(path)
      end
    end

    m.add_item('Enable (All)') { ensure_loaded; SU_Furniture.add_remove_observers(1) }
    m.add_item('Disable (All)'){ ensure_loaded; SU_Furniture.add_remove_observers(0) }
    m.add_item('Status'){ ensure_loaded; UI.messagebox("state=#{SU_Furniture.observers_state}") }
    m.add_separator

    # Per-observer toggles
    {
      'Selection' => :selection,
      'Entities'  => :entities,
      'Layers'    => :layers,
      'Pages'     => :pages,
      'Tools'     => :tools
    }.each do |label, key|
      m.add_item("Toggle #{label}") {
        ensure_loaded
        cur = SU_Furniture.get_enabled(key)
        SU_Furniture.set_enabled(key, !cur)
        UI.messagebox("#{label} enabled = #{SU_Furniture.get_enabled(key)}")
      }
    end

    m.add_separator
    m.add_item('Entities SAFE MODE (toggle)'){
      ensure_loaded
      cur = SU_Furniture.safe_mode_entities?
      SU_Furniture.set_safe_mode_entities(!cur)
      UI.messagebox("Entities SAFE MODE = #{SU_Furniture.safe_mode_entities?}")
    }

    m.add_item('Reload SU_Furniture'){
      ensure_loaded
      path = File.join(Sketchup.find_support_file('Plugins'), 'su_furniture.rb')
      load path if File.exist?(path)
      UI.messagebox('Reloaded')
    }
  end
end
