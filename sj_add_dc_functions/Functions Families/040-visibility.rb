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
    functions_family = FunctionsFamily.new('040-visibility')
    functions_family.title = 'Visibility functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetVisibilityEdges', functions_family)
    function.add_parameter('hidden', 'yes = 1, no = 0')
    function.add_parameter('soft', 'yes = 1, no = 0')
    function.add_parameter('smooth', 'yes = 1, no = 0')
    function.description = 'Allows you to configure the display of edges inside the component (hidden, softened, smooth).'
    functions_family.add_function(function)

    function = Function.new('SetHiddenEdges', functions_family)
    function.add_parameter('hidden', 'yes = 1, no = 0')
    function.description = 'Allows you to hide or reveal the ungrouped edges of a component.'
    functions_family.add_function(function)

    function = Function.new('SetHiddenFaces', functions_family)
    function.add_parameter('hidden', 'yes = 1, no = 0')
    function.description = 'Allows you to hide or reveal the ungrouped faces of a component.'
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
      ##### FONCTIONS DEFINITION ####
      #_____________________________________________________________________________________________________________________________
    
          # Definition de létat des arretes        
          # # DC Function Usage: =setvisibilityedges("hidden 0/1","smooth 0/1", "soft 0/1")        
          if not DCFunctionsV1.method_defined?(:setvisibilityedges)
              def setvisibilityedges(a)
                  p_hidden = a [0].to_i
                  p_smooth = a[1].to_i
                  p_soft = a[2].to_i
                  t_hidden = ""
                  t_smooth =""
                  t_soft = ""
  
                  if p_hidden == 1
                      b_hidden = true
                      t_hidden = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("hidden")
                  else
                      b_hidden = false                    
                  end
  
                  if p_smooth == 1
                      b_smooth = true
                      t_smooth = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("smooth")
                  else 
                      b_smooth = false                    
                  end
  
                  if p_soft == 1
                      b_soft = true
                      t_soft = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("soft")
                  else 
                      b_soft = false                    
                  end
  
                  ents = @source_entity.definition.entities
                  edges = ents.grep(Sketchup::Edge)
                  edges.each do |edge|
                      edge.hidden = b_hidden
                      edge.smooth = b_smooth
                      edge.soft = b_soft
                  end
  
                  return "Edge #{t_hidden}#{t_smooth} #{t_soft} "
  
              end
          end
  
          # Definition de létat des arretes        
          # # DC Function Usage: =SethiddenEdges("hidden 0/1")        
          if not DCFunctionsV1.method_defined?(:sethiddenedges)
              def sethiddenedgess(a)
                  p_hidden = a [0].to_i
                  t_hidden = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("visible")
                  if p_hidden == 1
                      b_hidden = true
                      t_hidden = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("hidden")
                  else
                      b_hidden = false                    
                  end
  
  
                  ents = @source_entity.definition.entities
                  edges = ents.grep(Sketchup::Edge)
                  edges.each do |edge|
                      edge.hidden = b_hidden
                  end
  
                  return "edge #{t_hidden}"
  
              end
          end
  
          # Definition de létat des faces        
          # # DC Function Usage: =sethiddenfaces("hidden 0/1")        
          if not DCFunctionsV1.method_defined?(:sethiddenfaces)
              def sethiddenfaces(a)
                  p_hidden = a [0].to_i
                  t_hidden = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("visible")
                  if p_hidden == 1
                      b_hidden = true
                      t_hidden = SimJoubert::AddDCFunctions::FunctionsFamilies.family('040-visibility').translate("hidden")
                  else
                      b_hidden = false                    
                  end
  
  
                  ents = @source_entity.definition.entities
                  faces = ents.grep(Sketchup::Face)
                  faces.each do |face|
                      face.hidden = b_hidden
                  end
  
                  return "Face #{t_hidden}"
  
              end
          end
  
           # Evaluation d'une chaine et retourne l'attribut        
          # # DC Function Usage: =GetEval("stringA" & "stringB")  => stringAstringB as a variable      
          if not DCFunctionsV1.method_defined?(:geteval)
              def geteval(a)
                  string = a[0]
                  return eval(string)
              end
          end

          
  
  end # class
end # if
  