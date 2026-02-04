require 'sketchup'
require 'extensions'

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    # Version du plugin.
    VERSION = '0.9.10'
    # Les notes de versions sont consultables dans le fichier "sj_AddDCFunctions/CHANGELOG.txt"

    # Traduction du plugin selon la langue d'installation de SketchUp.
    TRANSLATE = LanguageHandler.new('sj_add_dc_functions.translation')
    # Voir : "sj_AddDCFunctions/Resources/#{Sketchup.get_locale}/sj_AddDCFunctions.translation"

    # Nom du plugin.
    NAME = 'Add DC Functions'
    # Dossier du plugin
    FOLDER = 'sj_add_dc_functions'
    # Menu du plugin
    MENU_NAME = 'Add DC Functions'
	  # Description du plugin
    description = TRANSLATE["Add additional calculation functions for dynamic component formulas." ]
    copy_year = "2022"
    AUTHOR = "Simon Joubert"

    extension = SketchupExtension.new(
      FOLDER,
      FOLDER + '/load.rb'
    )
		
    extension.version     = VERSION
    extension.creator     = AUTHOR
    extension.copyright   = "© #{copy_year} #{extension.creator}"
    extension.description = description + TRANSLATE[' Access it via Plugins '] + "> SimJoubert Tools > " + MENU_NAME + TRANSLATE[', or toollbar '] + NAME
    Sketchup.register_extension(
      extension,
      true # load_at_start
    )
	
  end

end
