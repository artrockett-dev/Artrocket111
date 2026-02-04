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
    functions_family = FunctionsFamily.new('100-boolean')
    functions_family.title = 'Boolean operations functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('GetBooleanChildren', functions_family)
    function.add_parameter('lock', 'If 1 the operation is carried out otherwise frozen.')
    function.add_parameter('operator', 'Name of the boolean operation in English: union, substract, intersect.')
    function.add_parameter('resultName', 'Name of the group resulting from the operation.')
    function.add_parameter('volume1Name', 'Name of group or component definition or instance volume 1.')
    function.add_parameter('volume2Name', 'Name of group or component definition or instance volume 2.')
    function.add_parameter('copyVolume1', 'If 1 works on a copy of volume 1, otherwise volume 1 will be destroyed by the operation.')
    function.add_parameter('copyVolume2', 'If 1 works on a copy of volume 2, otherwise volume 2 will be destroyed by the operation.')
    function.description = 'Performs a boolean operation of sub-component volume 1 through subcomponent volume 2. The group, the result of the operation is renamed according to the parameter resultName.'
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
          ##### FONCTIONS OPERATIONS BOOLEENNES####
          #_____________________________________________________________________________________________________________________________
      
          # # DC Function Usage =GetBooleanChild(lock,operation,Nom du groupe resultat, Nom volume 1, Nom Volume 2) 
          # realise une opération booleenne à l'interieur du composant des sous composant volume 1 par le sous composant volume 2 et groupe le résulat 
          if not DCFunctionsV1.method_defined?(:getbooleanchildren)
              def getbooleanchildren(a)
                  # si lock !=1 pas d'opération
                  lock = a[0].to_i
                  # union ou substract
                  operator = a[1].to_s
                  # nom du group resultat de l'opération'
                  resultat_name = a[2].to_s
                  volume1_name = a[3].to_s
                  volume2_name = a[4].to_s
                  # si conserver = 1 alors travail sur des copies (non destructif)
                  copy_volume1 = a[5].to_i
                  copy_volume2 = a[6].to_i
  
                  #initialisation des variables
                  volume1_source=volume2_source=old_resultat=""
  
                  # on parcours les entités du composant à la recherche de volume1 et volume 2
  
                  com_def = @source_entity.definition
                  ents = com_def.entities
  
                  # Recherche dans les sous composants
                  ents.grep(Sketchup::ComponentInstance){ |inst|
                      name = inst.definition.name
                      if name == volume1_name || inst.name == volume1_name
                          volume1_source = inst
                      elsif name == volume2_name || inst.name == volume2_name
                          volume2_source = inst
                      end
                  }
                  # Recherche dans les sous groupes
                  ents.grep(Sketchup::Group){ |group|
                      name = group.name
                      if name == resultat_name
                          old_resultat = group
                      elsif name == volume1_name
                          volume1_source = group
                      elsif name == volume2_name
                          volume2_source = group
                      end
  
                  }
  
                  #test si on dois réaliser l'opération booléenne
                  if lock != 1
                      if volume1_source != ""
                          if volume1_source.description == "Boolean DC Result"
                              volume1_source.hidden = true
                          else
                              volume1_source.hidden = false
                          end
                      end
  
                      if volume2_source != ""
                          if volume2_source.description == "Boolean DC Result"
                              volume2_source.hidden = true
                          else
                              volume2_source.hidden = false
                          end
                      end
  
                      if old_resultat != ""
                          old_resultat.hidden = true
                      end                   
  
                      return SimJoubert::AddDCFunctions::FunctionsFamilies.family('100-boolean').translate("Frozen operation")
                  end
  
                 
                 
  
                  # on test le resultat de la recherche de volume 1 et volume 2
  
                  if volume1_source == ""                  
                      return SimJoubert::AddDCFunctions::FunctionsFamilies.family('100-boolean').translate("Volume 1 not existing")
                  end
                  if volume2_source == ""
                      return SimJoubert::AddDCFunctions::FunctionsFamilies.family('100-boolean').translate("Volume 2 not existing")
                  end
  
                  if old_resultat != ""
                      # On supprime l'ancien résultat
                      old_resultat.erase!
                  end
  
                  # Si copy_volume1 = 1 on travail sur une copies de volume 1
                  if copy_volume1 == 1
                      volume1 = volume1_source.copy                
                  else
                      volume1 = volume1_source
                  end
  
                  # Si copy_volume2 = 1 on travail sur une copies de volume 2
                  if copy_volume2 == 1
                      volume2 = volume2_source.copy                
                  else
                      volume2 = volume2_source
                  end
                  
  
                  # Opération Booléenne 
                  if operator == "substract"
                      result = volume2.subtract(volume1)
                  elsif operator == "union"
                      result = volume2.union(volume1)
                  elsif operator == "intersect"
                      result = volume2.intersect(volume1)
                  end
                  
                  # Test du résultat
                  if result == nil
                      return "Aucun résultat"
                  end
  
                  # On renomme le résultat
                  result.name = resultat_name
                  result.description = "Boolean DC Result"
  
                  # On cache les sources de volume 1 et volume 2 si on a travaillé sur des copies
                  if copy_volume1 == 1
                      volume1_source.hidden = true
                  end
                  if copy_volume2 == 1
                      volume2_source.hidden = true
                  end
                  
                  # on retourne le nom du résultat
                  return resultat_name
                  
              end
          end
      end # class
end # if