require 'fileutils'
require 'erb'
require 'sketchup'
require 'sj_add_dc_functions/functions_families'

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    SESSION = Hash.new
    # Aide à propos des fonctions pour les composants dynamiques SketchUp.
    module Help
      # Chemin absolu vers le dossier des dialogues HTML.
      DIALOGS_DIR = File.join(__dir__, 'HTML Dialogs')

      # Réécrit le fichier HTML d'aide. Ceci permet de produire une documentation portable, hébergeable sur un site.
      def self.rewrite_html_file
        erb_file = File.join(DIALOGS_DIR, 'help.html.erb')
        renderer = ERB.new(File.read(erb_file))
        html_file = File.join(DIALOGS_DIR, 'help.html')
        # Grâce au binding la méthode `FunctionsFamilies.families` sera accessible depuis le fichier "help.html.erb".
        File.write(html_file, renderer.result(binding))
      end

      # Affiche le dialogue HTML d'aide.
      def self.show_html_dialog
        SESSION[:webkey] = "Aide"
        dialog = UI::HtmlDialog.new(
          dialog_title: "#{NAME} #{VERSION}",
          preferences_key: 'sj_add_dc_functions_Help',
          scrollable: true,
          width: 600,
          height: 400
        )
        # On remplit le dialogue HTML avec le fichier HTML écrit sur le disque par la méthode `Help.rewrite_html_file`.
        dialog.set_url(File.join(DIALOGS_DIR, 'help.html'))
        dialog.set_can_close { SESSION[:webkey] == nil }
				SESSION[:webkey] = nil
        dialog.center
        dialog.show
      end
    end
  end
end
