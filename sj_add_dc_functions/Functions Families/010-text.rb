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
    functions_family = FunctionsFamily.new('010-text')
    functions_family.title = 'Text functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('Occurrence', functions_family)
    function.add_parameter('text', 'Text on which the search will be carried out.')
    function.add_parameter('string', 'Character string to find.')
    function.description = 'Allows you to obtain the number of occurrences of a character string(s) in a text.'
    functions_family.add_function(function)

    function = Function.new('NoteAddDcFunctions', functions_family)
    function.add_parameter('attributeName', 'Name of the attribute that called the function.')
    function.description = 'Adds a warning at the end of the component description visible in the dynamic component options panel and in the description of the skp file if you save the component. <br> , WARNING, this component uses non native Sketchup calculation functions !!! <br> , It requires the installation of the sj_AddDCFunctions plugin!'
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
      ##### FONCTIONS TEXTE ####
      #_____________________________________________________________________________________________________________________________
      
        #--------------------------------------------
        # FONCTION NOTEADDDCFUNCTIONS
        #--------------------------------------------
          # # DC Function Usage: =NoteAddDCFUNCTIONS()
          # # returns the number of the occurency of the string b in the string a
          if not DCFunctionsV1.method_defined?(:noteadddcfunctions)
              def noteadddcfunctions(a)
                  attribut = a[0]
                  note_html = "<p><b><i><font color=\"red\">Attention ce composant utilise des fonctions de calcul non natives de Sketchup !!!<br>Il requiert l'instalation du plugin sj_AddDCFunctions!</font></i></b></p>"
                  note_skp = "Attention ce composant utilise des fonctions de calcul non natives de Sketchup ! Il requiert l'instalation du plugin sj_AddDCFunctions !"
                  source_def = @source_entity.definition
                  dcdict = "dynamic_attributes"
  
                  #Description skp
                  description_skp = source_def.description
                  if description_skp == ""
                      description_skp = note_skp
                  else
                      description_skp = description_skp + " " +note_skp
                  end
                  source_def.description = description_skp
                  
                  
                  #Attribut description
                  description = source_def.get_attribute( dcdict, "description","")
                  if description == ""
                      description = note_html
                  else
                      description = description +"<br>"+note_html
                  end
                  source_def.set_attribute( dcdict, "description",description)
  
                  # On efface la formule de l'attribut appelant
                  source_def.delete_attribute(dcdict, "_"+attribut+"_formula")                
              
                  # TODO: Traduire la chaîne écrite en dur ci-dessous et dans les autres "family.rb" avec un code comme ceci :
                  # return SimJoubert::AddDCFunctions::FunctionsFamilies.family('010-text').translate('Warning note created')
                  return SimJoubert::AddDCFunctions::FunctionsFamilies.family('010-text').translate('Warning note created')
              end
          end
  
        #--------------------------------------------
        # FONCTION OCCURENCES
        #--------------------------------------------
          #Calcule du nombre d'occurences d'une chaine de caractères dans un texte
          
          # # DC Function Usage: =occurence(texte,texte recherche)
          # # returns the number of the occurency of the string b in the string a
          if not DCFunctionsV1.method_defined?(:occurrence)
              def occurrence(a)
                  #on récupère le texte source passé en paramètre
                  texte = a[0]
                  #on récupère la chaine de texte à recherchée passée en paramètre
                  chaine = a[1]
  
                  
              
                  return texte.count(chaine)
              end
          end
          #fin occurence
  
  
        #--------------------------------------------
        # FONCTION NUMTOSTRING
        #--------------------------------------------
          # # DC Function Usage =numtostring() 
          # Converti un nombre en texte
          if not DCFunctionsV1.method_defined?(:numtostring)
              def numtostring(a)
                  string=a[0].to_s
                  return "#{string}"
              end
          end

        
  
  end # class
end # if
