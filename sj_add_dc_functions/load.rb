require 'sj_add_dc_functions/functions_families'
require 'sj_add_dc_functions/help'
require 'sj_add_dc_functions/menu'
require 'sj_add_dc_functions/toolbar'


# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    FunctionsFamilies.load
    Help.rewrite_html_file
    Menu.add
    Toolbar.add
  end
end
