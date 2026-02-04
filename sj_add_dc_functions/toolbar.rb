require 'sketchup'
require 'sj_add_dc_functions/help'

# Espace de noms de l'auteur.
module SimJoubert

  #On creer une barre d'outils SJ_DC_Tools 
	# S'il n'est pas déjà défini :
	unless const_defined?('AUTHOR_DC_TOOLBAR')
		AUTHOR_DC_TOOLBAR = UI::Toolbar.new('SJ_DC_Tools')
	end

  # Espace de noms du plugin.
  module AddDCFunctions
    # Barre d'outils.
    module Toolbar
      # Chemin absolu vers le dossier des icônes de la barre d'outils.
      ICONS_DIR = File.join(__dir__, 'Toolbar Icons')

      # Retourne la bonne extension pour une icône de la barre d'outils en fonction de l'OS (macOS, Windows).
      #
      # @return [String]
      def self.icon_extension
        Sketchup.platform == :platform_osx ? 'pdf' : 'svg'
      end

      # Ajoute une barre d'outils dans SketchUp.
      def self.add
        
        command = UI::Command.new('help') { Help.show_html_dialog }
        command.small_icon = command.large_icon = File.join(ICONS_DIR, "help.#{icon_extension}")
        command.tooltip = TRANSLATE["Functions list"]
        command.status_bar_text =  TRANSLATE['Displays a dialog box with the list of functions added by the plugin.']
        AUTHOR_DC_TOOLBAR.add_item(command)
				AUTHOR_DC_TOOLBAR.show
      end
    end
  end
end
