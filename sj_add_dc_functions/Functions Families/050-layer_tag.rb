require 'sj_add_dc_functions/functions_family'
require 'sj_add_dc_functions/function'
require 'sj_add_dc_functions/functions_families'
require 'sketchup'
require 'su_dynamiccomponents'

# DOCUMENTATION DE CETTE FAMILLE DE FONCTIONS.

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    functions_family = FunctionsFamily.new('050-layer_tag')
    functions_family.title = 'Layers/Tags functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetLayer', functions_family)
    function.add_parameter('layerName', 'Type target layer name or type default to place on Layer0 - no tag')
    function.description = 'Place the instance on the layer passed as a parameter.<br>Copies of a component obtained with the copies attribute are placed by Sketchup on layer0 or without tag, even if the original component is on another layer.<br>This function will force the copies to be placed on the layers of your choice.<br>If the layer / tag does not exist, the function generates it for you!'
    functions_family.add_function(function)

    FunctionsFamilies.add_family(functions_family)
  end
end

# IMPLEMENTATION DE CETTE FAMILLE DE FONCTIONS.

if defined?($dc_observers)
  # Open SketchUp's Dynamic Component Functions (V1) class.
  # BUT only if DC extension is active...
      class DCFunctionsV1
          protected
          #_____________________________________________________________________________________________________________________________
          ##### FONCTIONS CALQUE/BALISE #### Modification V0.9.10
          #_____________________________________________________________________________________________________________________________
  
          # place l'instance sur le calque passé en paramètre
          # # DC Function Usage =setonlayer("nom du calque")
          if not DCFunctionsV1.method_defined?(:setlayer)
              def setlayer(a)
                  #on récupère le nom du calque passé en paramètre
                  layer_name = a[0]
                  if layer_name == nil || layer_name == "default"
                      # si le paramètre est vide alors calque0
                      layer = Sketchup.active_model.layers[0].name
                      layer_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('050-layer_tag').translate("Layer0 - no tag")
                  else
                      #On creer un calque avec le nom passé en paramètre il est créé s'il n'existe pas
                      layer = Sketchup.active_model.layers.add layer_name
                      layer_return = layer_name
                  end
                  #On tag l'instance du composant sur le calque
                  newlayer = @source_entity.layer = layer
                  return layer_return
              end
  
          end
      end # class
end # if
