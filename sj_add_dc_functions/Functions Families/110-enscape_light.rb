require 'sj_add_dc_functions/functions_family'
require 'sj_add_dc_functions/function'
require 'sj_add_dc_functions/functions_families'
require 'sketchup'
require 'su_dynamiccomponents'
require 'fileutils'

# DOCUMENTATION DE CETTE FAMILLE DE FONCTIONS.

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    functions_family = FunctionsFamily.new('110-enscape_light')
    functions_family.title = 'Enscape light functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetEnscapeSpotLight', functions_family)
    function.add_parameter('angle', 'Value of the opening angle of the apex cone in degrees.')
    function.add_parameter('power', 'Power of the light source in Candela.')
    function.description = 'Adjusts Enscape light settings for SpotLights.'
    functions_family.add_function(function)

    function = Function.new('SetEnscapeDiskLight', functions_family)
    function.add_parameter('radius', 'Disc radius in centimeters.')
    function.add_parameter('power', 'Power of the luminous surface in Lumen.')
    function.description = 'Adjust Enscape light settings for DiskLights.'
    functions_family.add_function(function)

    function = Function.new('SetEnscapeRectangularLight', functions_family)
    function.add_parameter('width', 'Width in centimeters.')
    function.add_parameter('length', 'Length in centimeters.')
    function.add_parameter('power', 'Power of the luminous surface in Lumen.')
    function.description = 'Adjust Enscape light settings for RectangularLights.'
    functions_family.add_function(function)

    function = Function.new('SetEnscapePointLight', functions_family)
    function.add_parameter('radius', 'Radius of the sphere in centimeters.')
    function.add_parameter('power', 'Power of the light source in Candela.')
    function.description = 'Adjust Enscape light settings for PointLights.'
    functions_family.add_function(function)

    function = Function.new('SetEnscapeLinearLight', functions_family)
    function.add_parameter('length', 'Length of the tube in centimeters.')
    function.add_parameter('power', 'Power of the light source in Candela.')
    function.description = 'Adjust Enscape light settings for LinearLights.'
    functions_family.add_function(function)

    function = Function.new('SetEnscapeProxyFileName', functions_family)
    function.add_parameter('path', 'Length of the tube in centimeters.')
    function.add_parameter('filename', 'Power of the light source in Candela.')
    function.description = 'Set the skp model file name for an Enscape proxy.'
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
          ##### FONCTIONS ENSCAPE LIGHT####
          #_____________________________________________________________________________________________________________________________
  
          # # DC Function Usage =SetEnscapeSpotLight(angle en degres, puissance en candella) 
          # Ajuste les paramètres de lumière Enscape pour  les SpotLight
          if not DCFunctionsV1.method_defined?(:setenscapespotlight)
              def setenscapespotlight(a)
                  angle_d = a[0].to_f
                  power_c = a[1].to_s
  
                  angle_r = angle_d*0.017453
                  angle_rs = angle_r.to_s
                  source_def = @source_entity.definition
                  
                  par_o = source_def.get_attribute("Enscape.Light","LightData", 0)
                  if par_o == 0
                      return "No Light"
                  else
                      par_m = '<?xml version="1.0"?>
                      <SketchupLight xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="SketchupSpotLight">
                      <Luminosity>' + power_c +'</Luminosity>
                      <BeamAngle>' + angle_rs + '</BeamAngle>
                      </SketchupLight>'
                      source_def.set_attribute("Enscape.Light", "LightData", par_m)      
                  end
  
                  return "Power #{power_c}, Angle #{angle_d}"
              end
          end
  
          # # DC Function Usage =SetEnscapeDiskLight(Rayon de la source lumineuse, Puissance lumineuse en lumen) 
          # Ajuste les paramètres de lumière Enscape pour les Disklight
          if not DCFunctionsV1.method_defined?(:setenscapedisklight)
              def setenscapedisklight(a)
                  rayon_cm = a[0].to_f
                  power_l = a[1].to_s
                  #conversion rayon cm en inch
                  rayon_i = rayon_cm*39.370078740157/100
                  rayon_is = rayon_i.to_s
                  source_def = @source_entity.definition
                  
                  par_o = source_def.get_attribute("Enscape.Light","LightData", 0)
                  if par_o == 0
                      return "No Light"
                  else
                      par_m = '<?xml version="1.0"?>
                      <SketchupLight xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="SketchupDiskLight">
                      <Luminosity>' + power_l +'</Luminosity>
                      <LightSourceRadius>' + rayon_is + '</LightSourceRadius>
                      </SketchupLight>'
                      source_def.set_attribute("Enscape.Light", "LightData", par_m)      
                  end
  
                  return "Power #{power_l}, Radius #{rayon_cm}"
              end
          end 
          
          # # DC Function Usage =SetEnscapeRectangularLight(largeur de la source lumineuse, longeur de la source lumineuse, Puissance lumineuse en lumen) 
          # Ajuste les paramètres de lumière Enscape pour les Rectangularlight
          if not DCFunctionsV1.method_defined?(:setenscapeRectangularlight)
              def setenscaperectangularlight(a)
                  largeur_cm = a[0].to_f
                  longeur_cm = a[1].to_f
                  power_l = a[2].to_s
                  #conversion rayon cm en inch
                  largeur_i = largeur_cm*39.370078740157/100
                  largeur_is = largeur_i.to_s
                  longeur_i = longeur_cm*39.370078740157/100
                  longeur_is = longeur_i.to_s
  
                  source_def = @source_entity.definition
                  
                  par_o = source_def.get_attribute("Enscape.Light","LightData", 0)
                  if par_o == 0
                      return "No Light"
                  else
                      par_m = '<?xml version="1.0"?>
                      <SketchupLight xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="SketchupRectangularLight">
                      <Luminosity>' + power_l +'</Luminosity>
                      <Width>' + largeur_is + '</Width>
                      <Length>' + longeur_is + '</Length>
                      </SketchupLight>'
  
                      source_def.set_attribute("Enscape.Light", "LightData", par_m)      
                  end
  
                  return "Power #{power_l}, Largeur #{largeur_cm}, Longeur #{longeur_cm}"
              end
          end 
          
          # # DC Function Usage =SetEnscapePointLight(Rayon de la source lumineuse, Puissance lumineuse en candela) 
          # Ajuste les paramètres de lumière Enscape pour les Pointlight
          if not DCFunctionsV1.method_defined?(:setenscapepointlight)
              def setenscapepointlight(a)
                  rayon_cm = a[0].to_f
                  power_c = a[1].to_s
                  #conversion rayon cm en inch
                  rayon_i = rayon_cm*39.370078740157/100
                  rayon_is = rayon_i.to_s
                  source_def = @source_entity.definition
                  
                  par_o = source_def.get_attribute("Enscape.Light","LightData", 0)
                  if par_o == 0
                      return "No Light"
                  else
                      par_m = '<?xml version="1.0"?>
                      <SketchupLight xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="SketchupPointLight">
                      <Luminosity>' + power_c +'</Luminosity>
                      <LightSourceRadius>' + rayon_is + '</LightSourceRadius>
                      </SketchupLight>'
                      source_def.set_attribute("Enscape.Light", "LightData", par_m)      
                  end
  
                  return "Power #{power_c}, Radius #{rayon_cm}"
              end
          end 
  
          # # DC Function Usage =SetEnscapeLinearLight(longeur de la source lumineuse, Puissance lumineuse en candella) 
          # Ajuste les paramètres de lumière Enscape pour les LinearLight
          if not DCFunctionsV1.method_defined?(:setenscapelinearlight)
              def setenscapelinearlight(a)
                  
                  longeur_cm = a[0].to_f
                  power_c = a[1].to_s
                  #conversion rayon cm en inch
                  longeur_i = longeur_cm*39.370078740157/100
                  longeur_is = longeur_i.to_s
  
                  source_def = @source_entity.definition
                  
                  par_o = source_def.get_attribute("Enscape.Light","LightData", 0)
                  if par_o == 0
                      return "No Light"
                  else
                      par_m = '<?xml version="1.0"?>
                      <SketchupLight xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="SketchupLinearLight">
                      <Luminosity>' + power_c +'</Luminosity>
                      <Length>' + longeur_is + '</Length>
                      </SketchupLight>'
  
                      source_def.set_attribute("Enscape.Light", "LightData", par_m)      
                  end
  
                  return "Power #{power_c}, Longueur #{longeur_cm}"
              end
          end

          
          # # DC Function Usage =SetEnscapeProxyFileName(chemin vers le dossier contenant le modele, nom du fichier .skp avec son extenssion) 
          # défini le modèle qui est substitué par le proxy pratique pour faire des variantes de couleurs ...
          if not DCFunctionsV1.method_defined?(:setenscapeproxyfilename)
            def setenscapeproxyfilename(a)

                #on récupère le nom du calque passé en paramètre
                path = a[0]
                filename = a[1]
                url = File.join(path,filename)
                dico = "Enscape.Proxy"
                attribut = "FileName"
                source_def = @source_entity.definition
                return_value =""
                famille = SimJoubert::AddDCFunctions::FunctionsFamilies.family('110-enscape_light')

                if File.directory?(path) == false
                    return_value = famille.translate("Error Invalid Path")
                else
                    if File.file?(url) == false
                        return_value = famille.translate("skp file not find")
                    else
                        source_def.set_attribute(dico,attribut,url)
                        return_value = filename
                    end
                end

                return return_value




                

            end
        end
  
          
      end # class
end # if 
          