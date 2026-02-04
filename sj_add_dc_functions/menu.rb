


require 'sketchup'
require 'sj_add_dc_functions/help'

# Espace de noms de l'auteur.
module SimJoubert
  # S'il n'est pas déjà défini :
  unless const_defined?('AUTHOR_MENU')
    # Ajoute le sous-menu de l'auteur dans le menu des extensions SketchUp.
    AUTHOR_MENU = UI.menu('Plugins').add_submenu('SimJoubert Tools')
    MYPLUGINS_MENU = AUTHOR_MENU.add_submenu("-=My plugins=-")
    MYPLUGINS_MENU.add_item('Discover my plugins') do
      UI.openURL('https://www.sketchup.simjoubert.com/my-plugins')
    end
    MYPLUGINS_MENU.add_separator
    AUTHOR_MENU.add_separator

  end
  # Espace de noms du plugin.
  module AddDCFunctions
    # Menu.
    module Menu
      # Ajoute le sous-menu du plugin dans le sous-menu de l'auteur.
      def self.add
        plugin_menu = AUTHOR_MENU.add_submenu(NAME)
        plugin_menu.add_item(TRANSLATE['Functions list']) { Help.show_html_dialog }
        plugin_lien = MYPLUGINS_MENU.add_item('page '+ NAME) {UI.openURL "https://www.sketchup.simjoubert.com/my-plugins/1-plugins/4-sj-add-dc-functions.html"}
      end
    end
  end
end
