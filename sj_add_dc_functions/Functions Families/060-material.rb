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
    functions_family = FunctionsFamily.new('060-material')
    functions_family.title = 'Materials functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetMaterial', functions_family)
    function.add_parameter('materialName', 'Material name or "default" to return to the default material.')
    function.description = 'Applies the material passed in parameter to the component. The difference with the Material attribute is the possibility of reverting to the default material if the value is set to "default".'
    functions_family.add_function(function)

    function = Function.new('SetMaterialKelvin', functions_family)
    function.add_parameter('temperature', 'Value between 60 and 8000 K')
    function.description = 'Create and apply the material corresponding to the kelvin temperature passed in parameter.<br>Converted the temperature in RGB value, Thanks to an algorithm.<br>Very useful for lighting scenes.<br>Returns the name of the material created.'
    functions_family.add_function(function)

    function = Function.new('SetMaterialFaces', functions_family)
    function.add_parameter('frontMaterial', 'Front face Material name or "default" to return to the default material.')
    function.add_parameter('backMaterial', 'Back face Material name or "default" to return to the default material.')
    function.description = 'Used to apply a material to the faces inside the component. <br>Parameters for each side of the face. <br>Useful for Boolean operations.'
    functions_family.add_function(function)

    function = Function.new('SetMaterialFrontFaces', functions_family)
    function.add_parameter('materialName', 'Material name or "default" to return to the default material.')
    function.description = 'Used to apply a material to the front faces inside the component.'
    functions_family.add_function(function)

    function = Function.new('SetMaterialBackFaces', functions_family)
    function.add_parameter('materialName', 'Material name or "default" to return to the default material.')
    function.description = 'Used to apply a material to the back faces inside the component.'
    functions_family.add_function(function)

    function = Function.new('setMaterialFacePlane', functions_family)
    function.add_parameter('facePlane', 'Plane of the faces XY, i_XY, XZ, i_XZ, YZ, i_YZ. or all')
    function.add_parameter('frontMaterial', 'Front face Material name or "default" to return to the default material.')
    function.add_parameter('backMaterial', 'Back face Material name or "default" to return to the default material.')
    function.description = 'Used to apply a material to the faces coplanar with the plane passed as a parameter, inside the component. <br>Settings for each side of the face. Can be useful in carpentry to apply a plating material on a field, or simply respect the grain, the grain and the cross grain of the wood. <br>If no valid plane is defined, the material is applied to all faces. <br>If the material is not found, returns the default material.'
    functions_family.add_function(function)

    function = Function.new('SetMaterialEdges', functions_family)
    function.add_parameter('materialName', 'Material name or "default" to return to the default material.')
    function.description = 'Allows to apply a material to the segments inside the component! <br> Practical for Boolean operations.'
    functions_family.add_function(function)

    function = Function.new('ChangeMaterialTexture', functions_family)
    function.add_parameter('materialName', 'Material name target')
    function.add_parameter('path', 'Path folder that contain textures')
    function.add_parameter('texture_file', 'file name with extention')
    function.description = 'Allows to change the texture of the target material. Very useful to have different textures for one material.'
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
          #### FONCTIONS MATIERES ####
          #_____________________________________________________________________________________________________________________________
  
              # applique la matiere au composant
              # # DC Function Usage =setmaterial("matiere") 
              if not DCFunctionsV1.method_defined?(:setmaterial)
                  def setmaterial(a)
                      #on récupère le nom de la matière en paramètre
                      material_name = a[0]
                                      
                      if material_name == "default" || material_name == nil || material_name == ""
                          @source_entity.material = nil
                          material_name = "Default"
                      else
                          @source_entity.material = material_name
                      end
                      return material_name
                  end
              end
  
              # applique la matiere aux faces du composant
              # # DC Function Usage =setmaterialfaces("front matiere", "back matiere") 
              if not DCFunctionsV1.method_defined?(:setmaterialfaces)
                  def setmaterialfaces(a)
                      #on récupère le nom des matières en paramètre
                      material_name = a[0]
                      back_material_name = a[1]
  
                      def materialfind(materialname)
                          mat_find = nil
                          materials = Sketchup.active_model.materials                
                          materials.each {|mat|
                              if mat.name == materialname
                                  mat_find = mat.name                      
                              end
                          }
                          mat_find
                      end
  
                      if material_name == "default"
                          material_name = nil
                          material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                      else
                          material_name = materialfind(material_name)
                          material_return = material_name
                          if material_name == nil
                              material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                          end
                      end
  
                      if back_material_name == "default"
                          back_material_name = nil
                          back_material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                      else
                          back_material_name = materialfind(back_material_name)
                          back_material_return = back_material_name
                          if back_material_name == nil
                              back_material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                          end
                      end
                      
  
                      ents = @source_entity.definition.entities
                      faces = ents.grep(Sketchup::Face)
                      faces.each do |face|
                          face.material = material_name
                          face.back_material = back_material_name
                      end
  
                      
                      return "Front #{material_return} Back #{back_material_return}"
                  end
              end
  
              # applique la matiere aux front faces du composant
              # # DC Function Usage =setmaterialfrontfaces("front matiere") 
              if not DCFunctionsV1.method_defined?(:setmaterialfrontfaces)
                  def setmaterialfrontfaces(a)
                      #on récupère le nom de la matière en paramètre
                      material_name = a[0]
                      
                      def materialfind(materialname)
                          mat_find = nil
                          materials = Sketchup.active_model.materials                
                          materials.each {|mat|
                              if mat.name == materialname
                                  mat_find = mat.name                      
                              end
                          }
                          mat_find
                      end
  
                      if material_name == "default"
                          material_name = nil
                          material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                      else
                          material_name = materialfind(material_name)
                          material_return = material_name
                          if material_name == nil
                              material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                          end
                      end
  
                      ents = @source_entity.definition.entities
                      faces = ents.grep(Sketchup::Face)
                      faces.each do |face|
                          face.material = material_name
                      end
  
                      
                      return "Front #{material_return}"
                  end
              end
  
              # applique la matiere aux back faces du composant
              # # DC Function Usage =setmaterialbackfaces("back matiere") 
              if not DCFunctionsV1.method_defined?(:setmaterialbackfaces)
                  def setmaterialbackfaces(a)
                      #on récupère le nom de la matière en paramètre
                      material_name = a[0]
                      
                      def materialfind(materialname)
                          mat_find = nil
                          materials = Sketchup.active_model.materials                
                          materials.each {|mat|
                              if mat.name == materialname
                                  mat_find = mat.name                      
                              end
                          }
                          mat_find
                      end
  
                      if material_name == "default"
                          material_name = nil
                          material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                      else
                          material_name = materialfind(material_name)
                          material_return = material_name
                          if material_name == nil
                              material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                          end
                      end
  
                      ents = @source_entity.definition.entities
                      faces = ents.grep(Sketchup::Face)
                      faces.each do |face|
                          face.back_material = material_name
                      end
  
                      
                      return "Back_faces #{material_return}"
                  end
              end
  
              # applique la matiere aux arretes du composant
              # # DC Function Usage =setmaterialedges("matiere") 
              if not DCFunctionsV1.method_defined?(:setmaterialedges)
                  def setmaterialedges(a)
                      #on récupère le nom de la matière passé en paramètre
                      material_name = a[0]
                      
                      def materialfind(materialname)
                          mat_find = nil
                          materials = Sketchup.active_model.materials                
                          materials.each {|mat|
                              if mat.name == materialname
                                  mat_find = mat.name                      
                              end
                          }
                          mat_find
                      end
  
                      if material_name == "default"
                          material_name = nil
                          material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                      else
                          material_name = materialfind(material_name)
                          material_return = material_name
                          if material_name == nil
                              material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                          end
                      end
  
                      ents = @source_entity.definition.entities
                      edges = ents.grep(Sketchup::Edge)
                      edges.each do |edge|
                          edge.material = material_name
                      end
  
                      
                      return "Edge \: #{material_return}"
                  end
              end
  
              # applique la matiere au composant selon Temperature Kelvin
              # Source Ancien Alogarithme https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
              # Source nouvel alogarithme https://www.zombieprototypes.com/?p=210
              # # DC Function Usage =setmaterialkelvin("temperature") 
              if not DCFunctionsV1.method_defined?(:setmaterialkelvin)
                  def setmaterialkelvin(a)
                      #on récupère les valeurs passées en paramètre
                      temperature_k = a[0].to_f
                      temperature = temperature_k/100
                      temperature_ks = sprintf("%0f",temperature_k).to_i
                      red = 0.to_f
                      green = 0.to_f
                      blue = 0.to_f
                      material_name = "Défault"           
  
  
                      #Calcule de red
                      if temperature <= 66
                          red = 255
                      else
                          # Ancien alogarithme
                          # red = temperature - 60
                          # red = 329.698727446 * (red ^ -0.1332047592)
  
                          # Nouveau alogarithme
                          red = temperature - 55
                          red = 351.97690566805693 + 0.114206453784165 * red + -40.25366309332127 * Math.log(red)
                          if red < 0
                              red = 0
                          elsif red > 255
                              red = 255
                          end
                      end
  
                      #calcule de green:
  
                      if temperature <= 66
                          # Ancien alogarithme
                          # green = temperature
                          # green = 99.4708025861 * Math.log(green) - 161.1195681661
  
                          # Nouveau alogarithme
                          green = temperature-2
                          green = -155.25485562709179 - 0.44596950469579133 * green + 104.49216199393888 * Math.log(green)
  
                          if green < 0
                              green = 0
                          elsif green > 255
                              green = 255
                          end
                      else
                          # Ancien alogarithme
                          # green = temperature - 60
                          # green = 288.1221695283 * (green ^ -0.0755148492)
  
                          # Nouveau alogarithme
                          green = temperature-50
                          green = 325.4494125711974 + 0.07943456536662342 * green - 28.0852963507957 * Math.log(green)
  
                          if green < 0
                              green = 0
                          elsif green > 255
                              green = 255
                          end
                      end
  
                      #Calcul de blue
                      if temperature >= 66
                          blue = 255
                      else
  
                          if temperature <= 19
                              blue = 0
                          else
                              # Ancien alogarithme
                              #blue = temperature - 10
                              #blue = 138.5177312231 * Math.log(blue) - 305.0447927307
  
                              # Nouveau alogarithme
                              blue = temperature - 10
                              blue = -254.76935184120902 + 0.8274096064007395 * blue + 115.67994401066147 * Math.log(blue)
  
                              if blue < 0
                                  blue = 0
                              elsif blue > 255
                                  blue = 255
                              end
                          end
  
                      end
  
                      red = sprintf("%.0f",red).to_i
                      green = sprintf("%.0f",green).to_i
                      blue = sprintf("%.0f",blue).to_i
  
                      
                      
                      
  
  
  
                  
                      if temperature == nil
                          material_name = "Défault"
                      else
                          mat_find = 0
                          model = Sketchup.active_model
                          materials = model.materials                
                          material_name = "KELVIN_#{temperature_ks}"
                          materials.each {|mat|
                              if mat.name == material_name
                                  mat_find = 1
                                  material_find = mat
                              end
                          }
                          if mat_find == 0
                              material_k = materials.add(material_name)
                              color_from_rgb = Sketchup::Color.new(red, green, blue)
                              material_k.color = color_from_rgb
                          end
                              source_def = @source_entity.definition
                              source_def.instances.each {|inst|
                                  inst.material = material_name
                              }
                              source_def.material = material_name
                          
                      
                              
                          
  
                      end
                      return material_name
                  end
              end
            
            # Change la texture d'une matière
            # # DC Function Usage =changematerialtexture("matiere","path ","file") 
            if not DCFunctionsV1.method_defined?(:changematerialtexture)
                def changematerialtexture(a)
                    #on récupère le nom du calque passé en paramètre
                    material_name = a[0]
                    path = a[1]
                    texture_file = a[2]
                    return_value =""
                    famille = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material')

                    model = Sketchup.active_model
                    materials = model.materials
                    material = materials.find{|m| m.name==material_name}

                    if material == nil
                        return_value = famille.translate("Material not find")
                    else
                        if File.directory?(path) == false
                            return_value = famille.translate("Path directory not valid")
                        else
                            if File.file?(File.join(path,texture_file)) == false
                                return_value = famille.translate("Texture file not find")
                            else
                                texture = material.texture="#{path}/#{texture_file}"
                                return_value = texture_file
                            end
                        end
                    end

                    return return_value
                end
            end

            # applique une matière à toutes les faces du plan passé passé en paramètre
            # # DC Function Usage =setmaterialfaceplane("plane","matiere front face", "matière back face") 
            if not DCFunctionsV1.method_defined?(:setmaterialfaceplane)
                def setmaterialfaceplane(a)
                    #on récupère les paramètres
                    plane = a[0].to_s
                    material_name = a[1].to_s
                    back_material_name = a[2].to_s

                    def materialfind(materialname)
                        mat_find = nil
                        materials = Sketchup.active_model.materials                
                        materials.each {|mat|
                            if mat.name == materialname
                                mat_find = mat.name                      
                            end
                        }
                        mat_find
                    end

                    if material_name == "default"
                        material_name = nil
                        material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                    else
                        material_name = materialfind(material_name)
                        material_return = material_name
                        if material_name == nil
                            material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                        end
                    end

                    if back_material_name == "default"
                        back_material_name = nil
                        back_material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("default material")
                    else
                        back_material_name = materialfind(back_material_name)
                        back_material_return = back_material_name
                        if back_material_name == nil
                            back_material_return = SimJoubert::AddDCFunctions::FunctionsFamilies.family('060-material').translate("non-existent material")
                        end
                    end

                    #Selection du vecteur normal selon le plan passé en paramètre
                    if plane == "XY"
                        norm = [0,0,1]
                      elsif plane == "i_XY"
                        norm = [0,0,-1]
                      elsif plane == "XZ"
                        norm = [0,1,0]
                      elsif plane == "i_XZ"
                        norm = [0,-1,0]
                      elsif plane == "YZ"
                        norm = [1,0,0]
                      elsif plane == "i_YZ"
                        norm = [-1,0,0]
                      else
                        norm ="all"
                      end
                    

                    ents = @source_entity.definition.entities
                    faces = ents.grep(Sketchup::Face)
                    unless norm == "all"
                        facesselect = faces.select{|f| f.normal==norm}
                        plan_return = "faces plane #{plane}"
                    else
                        facesselect = faces
                        plan_return = "all faces"                        
                    end

                    facesselect.each do |face|
                        face.material = material_name
                        face.back_material = back_material_name
                    end

                    
                    return "#{plan_return} Front #{material_return} Back #{back_material_return}"


                end
            end

          
  
      end # class
end # if