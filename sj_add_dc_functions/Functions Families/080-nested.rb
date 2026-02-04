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
    functions_family = FunctionsFamily.new('080-nested')
    functions_family.title = 'Parent/child attribute functions'
    functions_family.author = 'Simon Joubert'

    # TODO: Aliaser ChildrenSumAttribut en ChildrenSumAttribute ?
    function = Function.new('ChildrenSumAttribut', functions_family)
    function.add_parameter('attribute', 'Name of the searched attribute.')
    function.description = 'Realizes the sum of the components / child groups on the attribute passed in parameter. Only child entities with this attribute are summed.'
    functions_family.add_function(function)

    # TODO: Aliaser ChildrenSumSiAttribut en ChildrenSumIfAttribute ?
    function = Function.new('ChildrenSumSiAttribut', functions_family)
    function.add_parameter('attribute', 'Name of the attribute that will be summed, if the comparison is true.')
    function.add_parameter('conditionalAttribute', 'Name of the child attribute on which a comparison will be performed.')
    function.add_parameter('operator', 'Comparison operator: <strong>e</strong> for equal, <strong>i</strong>for less, <strong>s</strong> for greater and <strong>d</strong> for different. By composition <strong>ie</strong> for less than or equal and <strong>se</strong> for greater or equal.')
    function.add_parameter('value', 'Comparison value. If it is a text only the operators <strong>e</strong> and <strong>d</strong> are authorized.')
    function.description = "Sum of the components / child groups on the attribute passed in parameters. For each child entities, if the conditional attribute / value comparison is true then the attribute is summed, otherwise 0.<br> , Example: Sum of the LenX attribute if the material is red.<br> , ChildrenSumSiAttribut (\"LenX\", \"Material\", \"e\", \"Red\")<br> , Example: Sum of the LenX attribute if the LenZ height greater than 3.<br> , ChildrenSumSiAttribute (\"LenX\", \"LenZ\", \"s\", 3)"
    functions_family.add_function(function)

    # TODO: Aliaser ParentAttribut en ParentAttribute ?
    function = Function.new('ParentAttribut', functions_family)
    function.add_parameter('attribute', 'Name of the searched attribute.')
    function.add_parameter('mode', "Two possible modes \"path\" or \"value\".")
    function.description = 'Returns the value or the path of a parent attribute according to the chosen mode.<br>It is convenient to replace the parent component name reference so that you can copy the subcomponent to another parent without error in calculations.'
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
          ##### FONCTIONS NESTED ####
          #_____________________________________________________________________________________________________________________________
      
          # Somme des composants / groupes  enfants sur l'attribut passé en paramètre 
          # format attendu CHILDRENSUMATTRIBUT(ATTRIBUT)
          # DC Function Usage: =childrensumattribut(attribut)
          if not DCFunctionsV1.method_defined?(:childrensumattribut)
              def childrensumattribut(a)
                  #on récupère le nom de l'attribut passé en paramètre
                  attribut = a[0].downcase
                  #on récupère toutes les entitiées enfant du composant
                  ents = @source_entity.definition.entities
                  #on initialise la valeur de la variable parent sum
                  parentsum = 0
  
                  #on boucle sur chaque entités enfant qui est une instance de composant
                  #on récupère si present la valeur de l'attribut
                  ents.grep(Sketchup::ComponentInstance){ |inst|
                  inst_d = inst.definition
                  unless inst.get_attribute("dynamic_attributes", attribut, false)
                      inst_value = inst_d.get_attribute("dynamic_attributes", attribut, "0")
                  else
                      inst_value = inst.get_attribute("dynamic_attributes", attribut, "0")
                  end
                  #on convertie la valeur en nombre flotant
                  inst_value_f = inst_value.to_f
                  #on increment la variable parent sum de la valeur trouvée
                  parentsum = parentsum + inst_value_f
  
                  }
                  #on boucle sur chaque entités enfant qui est un groupe
                  #on récupère si present la valeur de l'attribut
                  ents.grep(Sketchup::Group ){ |inst|
                      inst_value = inst.get_attribute("dynamic_attributes", attribut, "0")
                      #on convertie la valeur en nombre flotant
                      inst_value_f = inst_value.to_f
                      #on increment la variable parent sum de la valeur trouvée
                      parentsum = parentsum + inst_value_f
                  
                  }
                  #retourne la somme de l'attribut cherchée dans les composants et groupes enfants
                  return parentsum
              end
          end
          #fin Somme des composants / groupes  enfants sur l'attribut passé en paramètre 
  
  
              # Somme des composants / groupes  enfants sur l'attribut passé en paramètre si 
          # format attendu CHILDRENSUMSIATTRIBUT(ATTRIBUT)
          # DC Function Usage: =childrensumsiattribut(attribut à sommer, attribut conditionel , opérateur, valeur)
          if not DCFunctionsV1.method_defined?(:childrensumsiattribut)
              def childrensumsiattribut(a)
                  #on récupère le nom de l'attribut passé en paramètre
                  attribut = a[0].downcase
                  attributcondition = a[1].downcase
                  operateur = a[2].downcase
                  valeur = a[3]
                  #on récupère toutes les entitiées enfant du composant
                  ents = @source_entity.definition.entities
                  #on initialise la valeur de la variable parent sum
                  parentsum = 0
  
                  #on boucle sur chaque entités enfant qui est une instance de composant
                  #on récupère si present la valeur de l'attribut
                  ents.grep(Sketchup::ComponentInstance){ |inst|
                  inst_d = inst.definition
  
                  #on recupère l'attribut de condition
                  unless inst.get_attribute("dynamic_attributes", attributcondition, false)
                      inst_cond = inst_d.get_attribute("dynamic_attributes", attributcondition, nil)
                  else
                      inst_cond = inst.get_attribute("dynamic_attributes", attributcondition, nil)
                  end
  
                  unless inst_cond == nil
  
                      if operateur == "e"
                      if inst_cond == valeur
                          cond = true
                      end
                      elsif operateur == "i"
                      if inst_cond < valeur
                          cond = true
                      end
                      elsif operateur == "ie"
                      if inst_cond <= valeur
                          cond = true
                      end
                      elsif operateur == "s"
                      if inst_cond > valeur
                          cond = true
                      end
                      elsif operateur == "se"
                      if inst_cond >= valeur
                          cond = true
                      end
                      elsif operateur == "d"
                      if inst_cond != valeur
                          cond = true
                      end
                      end
  
                      if cond == true
  
                      unless inst.get_attribute("dynamic_attributes", attribut, false)
                          inst_value = inst_d.get_attribute("dynamic_attributes", attribut, "0")
                      else
                          inst_value = inst.get_attribute("dynamic_attributes", attribut, "0")
                      end
                      #on convertie la valeur en nombre flotant
                      inst_value_f = inst_value.to_f
                      #on increment la variable parent sum de la valeur trouvée
                      parentsum = parentsum + inst_value_f
                      end
                  end
                  }
                  
                  #on boucle sur chaque entités enfant qui est un groupe
                  #on récupère si present la valeur de l'attribut
                  ents.grep(Sketchup::Group ){ |inst|
                      inst_cond = inst.get_attribute("dynamic_attributes", attributcondition, nil)
                      unless inst_cond == nil
  
                      if operateur == "e"
                          if inst_cond == valeur
                          cond = true
                          end
                      elsif operateur == "i"
                          if inst_cond < valeur
                          cond = true
                          end
                      elsif operateur == "ie"
                          if inst_cond <= valeur
                          cond = true
                          end
                      elsif operateur == "s"
                          if inst_cond > valeur
                          cond = true
                          end
                      elsif operateur == "se"
                          if inst_cond >= valeur
                          cond = true
                          end
                      elsif operateur == "d"
                          if inst_cond != valeur
                          cond = true
                          end
                      end
  
                      if cond == true
  
                          inst_value = inst.get_attribute("dynamic_attributes", attribut, "0")
                          #on convertie la valeur en nombre flotant
                          inst_value_f = inst_value.to_f
                          #on increment la variable parent sum de la valeur trouvée
                          parentsum = parentsum + inst_value_f
                      end
                      end
                  
                  }
                  #retourne la somme de l'attribut cherchée dans les composants et groupes enfants
                  return parentsum
              end
          end
          #fin Somme des composants / groupes  enfants sur l'attribut passé en paramètre 
  
  
          # Retourne l'attribut du composant parent valeur ou chemin
          # format attendu PARENTATTRIBUT(ATTRIBUT, MODE)
          # DC Function Usage: =parentattribut(attribut,"path" or "value")
          if not DCFunctionsV1.method_defined?(:parentattribut)
              def parentattribut(a)
                  #on récupère le nom de l'attribut passé en paramètre
                  attribut = a[0].downcase
                  #on récupère le mode passé en paramètre
                  mode = a[1].downcase
                  #on récupère le parent
                  ent_parent = @source_entity.parent
  
                  if mode == "path"
                  # on rècupère le nom du parent
                  ent_parent_name = ent_parent.get_attribute("dynamic_attributes","_name",ent_parent.name)
                  #on construit le chemin 
                  attribut_path = "#{ent_parent_name}\"&\"!\"&\"#{attribut}"
                  return_value = attribut_path
                  elsif mode == "value"
                  #on récupère la valeur de l'attribut parent
                  attribut_value = ent_parent.get_attribute("dynamic_attributes", attribut, "")
                  return_value = attribut_value
                  end
                  # retourne selon le mode le path ou la valeur
                  return return_value
              end
          end
          # fin parentattribut
  
      end # class
end # if