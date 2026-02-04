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
    functions_family = FunctionsFamily.new('070-rotation')
    functions_family.title = 'Rotation functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetRotation', functions_family)
    function.add_parameter('axis', 'Axis letter, X, Y or Z.')
    function.add_parameter('angle', 'Value of the angle of rotation in degrees. Can be positive or negative.')
    function.add_parameter('lock', 'If lock = 1, the rotation takes place, otherwise it is not performed.')
    function.add_parameter('level', 'The rotation can be on the component that calls the function level = 0, or on its parent component level = 1, or the grand parent level = 2.')
    function.description = 'Allows incremental rotation of the component\'s existing transformation. The rotation takes place around the point of origin of the component targeted by the level attribute.<br> , Useful when called by the OnClic attribute.<br> , Example OnClic : Set("rot_result",SetRotation("z",90,1,1)<br> , Performs on a click, the rotation of the parent component around its Z axis by 90 degrees.'
    functions_family.add_function(function)

    function = Function.new('SetRotationOffSet', functions_family)
    function.add_parameter('axis', 'Axis letter, X, Y or Z.')
    function.add_parameter('angle', 'Value of the angle of rotation in degrees. Can be positive or negative.')
    function.add_parameter('lock', 'If lock = 1, the rotation takes place, otherwise it is not performed.')
    function.add_parameter('level', 'The rotation can be on the component that calls the function level = 0, or on its parent component level = 1, or the grand parent level = 2.')
    function.add_parameter('offset', 'The center of the rotation can be the origin point of the calling component offset = 0, of the parent component offset = 1, or of the grand parent offset = 2. The value of the offset cannot be greater than the value of the level.')
    function.description = 'Allows incremental rotation of the component\'s existing transformation. The rotation takes place around the origin point of the component targeted by the offset attribute. The rotation is performed on the component targeted by the Level attribute. Useful when it is called by the OnClic attribute, OnClic<br>Example: Set ("rot_result", SetRotation ("z", 90,1,1,0)<br>Performs on a click, the rotation of the parent component on its Z axis of 90 degrees with the origin of the component calling the function at the center of rotation).'
    functions_family.add_function(function)

    # TODO: Aliaser SetAttributRotation en SetAttributeRotation ?
    function = Function.new('SetAttributRotation', functions_family)
    function.add_parameter('level', '0 the component, 1 the parent, 2 the grandparent.')
    function.description = 'Create dynamic attributes to control a rotation when clicking on a child component.<br> , This function must be called from an attribute named "rot_ini".<br> , It creates 5 attributes: rot_x_angle, rot_y_angle, rot_z_angle, rot_view, rot_lock, then erases the formula of rot_ini and returns the message "Attributes created".<br> , If level = 0, the attributes are only created in the component, if level = 1, the attributes are created in the component and the parent component, with a return by formula of the values of the parent in the component.<br> , If level = 2 then ditto but on 3 level.'
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
      ##### FONCTIONS ROTATION ####
      #_____________________________________________________________________________________________________________________________
   
          #appliquer une rotation selon la transformation existante
          # # DC Function Usage =setrotation("Axe",Angle en degres,Verrou,Level) 
          if not DCFunctionsV1.method_defined?(:setrotation)
              def setrotation(a)
                  axe_name = ""
                  agle_value = 0
                  verrou = 1
                  level = 0
                  parent =""
                  ent_parent =""
                  ent_grand_parent = ""
                  parent_offset = ""
                  obj=""
  
                  #On declare une definition qui recherche l'instance parente d'un objet
                  def parentInstance_filters (obj, *filter)
                      # Filter est facultatif et peut-être multiple.
                      # Valeurs possibles (Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Edge, Sketchup::Face)
                      # Filter permet de racourcir le champ de recherche dans les entités
                      imax = filter.length
                      if obj == Sketchup.active_model
                          return  Sketchup.active_model
                      end
                      inst_parent = nil
                      parent_def= obj.parent                    
                      if parent_def == Sketchup.active_model
                          return  Sketchup.active_model
                      end                
                      parent_insts = parent_def.instances                
                      parent_insts.each { |inst|                
                          if imax == 0
                              sous_instances = inst.definition.entities
                              sous_instances.each do |ent|
                                  if ent == obj
                                  inst_parent = inst
                                  end
                              end
                          else
                              i = 0
                              while i < imax
                                  filteri = filter[i]
                                  sous_instances = inst.definition.entities.grep(filteri)
                                  sous_instances.each do |ent|
                                      if ent == obj
                                      inst_parent = inst
                                      end
                                  end
                                  i = i+1
                              end
                          end
                      }                    
                      return inst_parent
                  end
  
                  #on récupère le nom de l'axe passé en paramètre et mise en minuscule
                  axe_name = a[0].downcase
  
                  #on récupère la valeur de l'angle passé en paramètre et conversion en integer
                  angle_value = a[1].to_i
  
                  #on recupere l'etat du verrou qui bloque l'action de rotation utilité en cas de Redraw du composant
                  # actif=1, verrouillé <> de 1 on ne continue pas l'opération de transformation
                  verrou = a[2].to_i
                  if verrou == 1
  
  
                      # Rotion directement du composant parent ou du composant
                      # on récupère le paramètre de niveau, "level" pour le composant parent 0 ou omis pour le composant lui même
                      level = a[3].to_i
  
                      if level == nil || level == 0
                          obj = @source_entity
  
                      elsif level == 1 
                          obj = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                          parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                          if obj == Sketchup.active_model
                              obj = @source_entity
                              parent = ""
                          end
                      elsif level == 2
                          obj = parentInstance_filters(parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group),Sketchup::ComponentInstance,Sketchup::Group)
                          parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the grandparent component")
                          if obj == Sketchup.active_model
                              obj = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                              parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                              if obj == Sketchup.active_model
                                  obj = @source_entity
                                  parent = ""
                              end
                          end
                      end
  
                          
                      #on récupere la transformation de l'entite
                      transformation = obj.transformation
                      #on recupere l'origine du composant
                      point_origine = transformation.origin
  
                      if axe_name == "x"
                          axe = transformation.xaxis
                      elsif axe_name == "y"
                          axe = transformation.yaxis
                      else axe  = transformation.zaxis
                      end
  
                      rotation=Geom::Transformation.rotation( point_origine, axe, angle_value.degrees )
                      obj.transform!(rotation)
  
                      result_text = "Rotation axe #{axe_name} #{angle_value} #{parent}"
  
                  else
                      result_text = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("Rotation Locked")
                  end
                  
                  return result_text
              
              end
          end
  
          #appliquer une rotation selon la transformation existante selon un point de rotation qui peut être l'origine du declencheur,du parent du declenchaur ou le grand parent du déclencheur.
          # le niveau d'offset ne peut être supérieur au level cible
          # # DC Function Usage =setrotation("Axe",Angle en degres,Verrou,Level,offset) 
          if not DCFunctionsV1.method_defined?(:setrotationoffset)
              def setrotationoffset(a)
                  axe_name = ""
                  agle_value = 0
                  verrou = 1
                  level = 0
                  offset = 0
                  parent = ""
                  offset_parent = ""
                  ent_parent = ""
                  ent_grand_parent = ""
                  obj_target = ""
                  obj_offset = ""
  
                  #on récupère le nom de l'axe passé en paramètre et mise en minuscule
                  axe_name = a[0].downcase
  
                  #on récupère la valeur de l'angle passé en paramètre et conversion en integer
                  angle_value = a[1].to_i
  
                  #on recupere l'etat du verrou qui bloque l'action de rotation utilité en cas de Redraw du composant
                  # actif=1, verrouillé <> de 1 on ne continue pas l'opération de transformation
                  verrou = a[2].to_i
                  if verrou == 1
  
  
                      # Rotion directement du composant parent ou du composant
                      # on récupère le paramètre de niveau, "0" pour le composant parent 0 ou omis pour le composant lui même
                      level = a[3].to_i
  
                      def parentInstance_filters (obj, *filter)
                          # Filter est facultatif et peut-être multiple.
                          # Valeurs possibles (Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Edge, Sketchup::Face)
                          # Filter permet de racourcir le champ de recherche dans les entités
                          imax = filter.length
                          if obj == Sketchup.active_model
                              return  Sketchup.active_model
                          end
                          inst_parent = nil
                          parent_def= obj.parent                    
                          if parent_def == Sketchup.active_model
                              return  Sketchup.active_model
                          end                
                          parent_insts = parent_def.instances                
                          parent_insts.each { |inst|                
                              if imax == 0
                                  sous_instances = inst.definition.entities
                                  sous_instances.each do |ent|
                                      if ent == obj
                                      inst_parent = inst
                                      end
                                  end
                              else
                                  i = 0
                                  while i < imax
                                      filteri = filter[i]
                                      sous_instances = inst.definition.entities.grep(filteri)
                                      sous_instances.each do |ent|
                                          if ent == obj
                                          inst_parent = inst
                                          end
                                      end
                                      i = i+1
                                  end
                              end
                          }                    
                          return inst_parent
                      end
  
                      if level == nil || level == 0
                          obj_target = @source_entity
                          parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the component")
  
                      elsif level == 1 
                          obj_target = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                          parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                          if obj_target == Sketchup.active_model
                              obj_target = @source_entity
                              parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the component")
                          end
                      elsif level == 2
                          obj_target = parentInstance_filters(parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group),Sketchup::ComponentInstance,Sketchup::Group)
                          parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the grandparent component")
                          if obj_target == Sketchup.active_model
                              obj_target = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                              parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                              if obj_target == Sketchup.active_model
                                  obj_target = @source_entity
                                  parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the component")
                              end
                          end
                      end
  
                      offset = a[4].to_i
  
  
  
                      if offset == nil || offset == 0
                          offset_ent = @source_entity
                          offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("component")
      
                      elsif offset == 1 
                          offset_ent = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                          offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                          if offset_ent == Sketchup.active_model
                              offset_ent  = @source_entity
                              offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("component")
                          end
                      elsif offset == 2
                          offset_ent = parentInstance_filters(parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group),Sketchup::ComponentInstance,Sketchup::Group)
                          offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the grandparent component")
                          if obj_target == Sketchup.active_model
                              offset_ent = parentInstance_filters(@source_entity,Sketchup::ComponentInstance,Sketchup::Group)
                              offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("of the parent component")
                              if offset_ent == Sketchup.active_model
                                  offset_ent = @source_entity
                                  offset_parent = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("component")
                              end
                          end
                      end                        
  
                      #on récupere la transformation de l'objet ciblé par la rotation obj_target
                      transformation = obj_target.transformation
                      point_origine = transformation.origin
  
                      if offset == level
                          point_rotation = point_origine
                      else
                          #on recupere l'origine de entite offset
                          transformation_offset = offset_ent.transformation
                          point_offset = transformation_offset.origin
                          x = point_offset.x
                          y = point_offset.y
                          z = point_offset.z
  
                          vector = Geom::Vector3d.new(x, y, z)
                          vector2 = vector.transform(transformation)
  
  
                          point_rotation = point_origine.offset!(vector2)
  
                      end
  
                      if axe_name == "x"
                          axe = transformation.xaxis
                      elsif axe_name == "y"
                          axe = transformation.yaxis
                      else 
                          axe = transformation.zaxis
                      end
  
                      rotation = Geom::Transformation.rotation( point_origine, axe, angle_value.degrees )
                      obj_target.transform!(rotation)

                      traduction = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("center of rotation origin of")
                      result_text = "Rotation axe #{axe_name} #{angle_value} #{parent}, #{traduction} #{offset_parent}"
  
                  else
                      result_text = SimJoubert::AddDCFunctions::FunctionsFamilies.family('070-rotation').translate("Rotation Locked")
                  end
                  
                  return result_text
              
              end
          end
  
          #Creer les attributs dynamique pour une rotation par clic sur l'enfant fleche de rotation
          #A utiliser sur le composant qui doit tourner
          # # DC Function Usage =setattributrotation(nombre de level sur lequel appliquer en calscade les attribut 0,1 ou 2) 
          if not DCFunctionsV1.method_defined?(:setattributrotation)
              def setattributrotation(a)
                  level = a[0].to_i
                  
                  if level == nil
                      level = 0
                  elsif level >=2
                      level = 2
                  elsif level <= 0
                      level = 0
                  end
  
                  i = 0
  
                  while (i <= level)
                      
                      if i == 0
                          source_def = @source_entity.definition
                      elsif i == 1
                          source_def = @source_entity.parent
                      elsif i == 2
                          parent_ent = ""
                          parsource_def = @source_entity.parent
                          parent_inst = parsource_def.instances
                          parent_inst.each {|inst|
                              sous_insts = inst.definition.entities.grep(Sketchup::ComponentInstance)
                              sous_insts.each do |sous_inst|
                                  if sous_inst == @source_entity
                                      parent_ent = inst
                                  end
                              end
                          }
                          source_def = parent_ent.parent
                      end
                      
  
                      ## Création de l'attribut rot_x_angle
                      source_def.set_attribute("dynamic_attributes","rot_x_angle",90)
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_label","rot_x_angle")
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_formulaunits","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_units","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_access","LIST")
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_options","&1=1&5=5&15=15&45=45&90=90&180=180&")
                      source_def.set_attribute("dynamic_attributes","_rot_x_angle_formlabel","Rotation axe X incrément")
                      if i < level
                          source_def.set_attribute("dynamic_attributes","_rot_x_angle_formula","parent!rot_x_angle")
                      end
  
                      ## Création de l'attribut rot_y_angle
                      source_def.set_attribute("dynamic_attributes","rot_y_angle",90)
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_label","rot_y_angle")
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_formulaunits","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_units","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_access","LIST")
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_options","&1=1&5=5&15=15&45=45&90=90&180=180&")
                      source_def.set_attribute("dynamic_attributes","_rot_y_angle_formlabel","Rotation axe Y incrément")
                      if i < level
                          source_def.set_attribute("dynamic_attributes","_rot_y_angle_formula","parent!rot_y_angle")
                      end
  
                      ## Création de l'attribut rot_z_angle
                      source_def.set_attribute("dynamic_attributes","rot_z_angle",90)
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_label","rot_z_angle")
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_formulaunits","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_units","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_access","LIST")
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_options","&1=1&5=5&15=15&45=45&90=90&180=180&")
                      source_def.set_attribute("dynamic_attributes","_rot_z_angle_formlabel","Rotation axe Z incrément")
                      if i < level
                          source_def.set_attribute("dynamic_attributes","_rot_z_angle_formula","parent!rot_z_angle")
                      end
  
                      ## Création de l'attribut rot_view_arrow
                      source_def.set_attribute("dynamic_attributes","rot_view_arrow",1)
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_access","LIST")
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_label","rot_view_arrow")
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_formulaunits","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_units","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_formlabel","Affichage des flèches de rotation")
                      source_def.set_attribute("dynamic_attributes","_rot_view_arrow_options","&Afficher=1&Masquer=0&")
                      if i < level
                          source_def.set_attribute("dynamic_attributes","_rot_view_arrow_formula","parent!rot_view_arrow")
                      end
  
                      ## Création de l'attribut rot_lock
                      source_def.set_attribute("dynamic_attributes","rot_lock",1)
                      source_def.set_attribute("dynamic_attributes","_rot_lock_access","LIST")
                      source_def.set_attribute("dynamic_attributes","_rot_lock_label","rot_lock")
                      source_def.set_attribute("dynamic_attributes","_rot_lock_formulaunits","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_lock_units","STRING")
                      source_def.set_attribute("dynamic_attributes","_rot_lock_formlabel","Activer les flèches de rotation")
                      source_def.set_attribute("dynamic_attributes","_rot_lock_options","&Activer=1&verrouiller=0&")
                      if i < level
                          source_def.set_attribute("dynamic_attributes","_rot_lock_formula","parent!rot_lock")
                      end
  
                      i += 1
                  end 
                  #On supprime la formule rentrée dans rot_ini qui à appeller la création des attributs
                  @source_entity.definition.delete_attribute("dynamic_attributes","_rot_ini_formula")
                  @source_entity.delete_attribute("dynamic_attributes","_rot_ini_formula")
  
  
                  return "Attributs créés"
              end
          end
  
      end # class
end # if