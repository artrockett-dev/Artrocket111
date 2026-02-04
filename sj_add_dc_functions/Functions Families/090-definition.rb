require 'sj_add_dc_functions/functions_family'
require 'sj_add_dc_functions/function'
require 'sj_add_dc_functions/functions_families'
require 'sketchup'
require 'su_dynamiccomponents'
require 'csv'

# DOCUMENTATION DE CETTE FAMILLE DE FONCTIONS.

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    functions_family = FunctionsFamily.new('090-definition')
    functions_family.title = 'Definitions functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('SetNameDefinition', functions_family)
    function.add_parameter('newName', 'New name for the definition.')
    function.description = 'Makes a component instance unique and gives it a new name passed as a parameter.'
    functions_family.add_function(function)

    function = Function.new('ResetScale', functions_family)
    function.description = 'Allows you to reset the scale of the instance and return to scale 1:1. Can only be called from an OnClick.'
    functions_family.add_function(function)

    function = Function.new('Options_from_csv', functions_family)
    function.add_parameter('path', "Path to file. Local access &quot; C:&#x2F;&#x2F;Folder&#x2F;File.csv &quot; or for network access &quot; &#x5C;&#x5C;Machine&#x5C;&#x5C;Folder&#x5C;&#x5C;File.csv&quot;")
    function.add_parameter('index_special_char', 'Index of the special character that separates the values. 0 => comma, 1 => semicolon, 2 => tabulation, => for spip.' )
    function.add_parameter('attribute_name', 'Name of the target attribute that will receive the list of options')
    function.description = "Create a list of options for the target attribute from the values contained in the CSV file. 1ʳᵉ column Options, 2ᵉ column Values. The file can have the extension .csv or .txt with carriage return. The values can be separated by commas, semicolons, tabs or spip"
    functions_family.add_function(function)

    function = Function.new('Switch_access_attribute', functions_family)
    function.add_parameter('condition', 'Formula that returns true or false')
    function.add_parameter('attribute_name', 'Name of the target attribute, whose access meta-attribute will be modified')
    function.add_parameter('access_true', "Index of the access property if the condition is true. In the list 0 => none, 1 => read only, 2 => entry, 3 => option list")
    function.add_parameter('access_false', "Index of the access property if the condition is false. In the list 0 => none, 1 => read only, 2 => entry, 3 => option list")
    function.description = "Modifies the _access meta-attribute of the conditional attribute. Allows you to modify the appearance of the attribute in the dynamic components option panel."
    functions_family.add_function(function)

    function = Function.new('Switch_access_attribute_begin', functions_family)
    function.add_parameter('condition', 'Formula that returns true or false')
    function.add_parameter('begin_attribute_name', "Starting characters of the name of the targeted attributes, whose access meta-attributes will be modified")
    function.add_parameter('access_true', "Index of the access property if the condition is true. In the list 0 => none, 1 => read only, 2 => entry, 3 => option list")
    function.add_parameter('access_false', "Index of the access property if the condition is false. In the list 0 => none, 1 => read only, 2 => entry, 3 => option list")
    function.description = "Modifies the _access meta-attribute of attributes whose name begins with and according to a condition. Allows you to modify the appearance of the attribute in the option panel of dynamic components."
    functions_family.add_function(function)

    function = Function.new('Switch_access_attribute_multi', functions_family)
    function.add_parameter('condition', 'Formula that returns true or false')
    function.add_parameter('string_parameter_group', 'Group of 3 parameters, the whole is in quotes. &quot; attribute_name , access_true , access_false &quot;. Each group is separated by a comma. At least one group is expected.')
    function.description = "Modifies the _access meta-attribute of several attributes according to a common condition. Allows to modify the appearance of the attribute in the option panel of the dynamic components."
    functions_family.add_function(function)

    function = Function.new('GetPersistentId', functions_family)
    function.description = "Retrieves the persistent identifier of the instance"
    functions_family.add_function(function)

    function = Function.new('GetAttribute_FromPersistentId', functions_family)
    function.add_parameter('id', 'The persistent identifier of the targeted instance')
    function.add_parameter('attribute', 'Name of the attribute sought')
    function.add_parameter('default_value', "Default value, if attribute not found")
    function.description = "Retrieves the attribute value of a model instance defined by its persistent identifier. Returns a default value, if the attribute is not found."
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

        #--------------------------------------------
        # FONCTION SETNAMEDEFINITION
        #--------------------------------------------
        # # DC Function Usage =setnamedefinition() 
        # Change le nom de la définition du composant
          if not DCFunctionsV1.method_defined?(:setnamedefinition)
            def setnamedefinition(a)
              @source_entity.make_unique
              inst_def = @source_entity.definition
              name=a[0]
              inst_def.name = name
              return name
            end
          end
          
        #--------------------------------------------
        # FONCTION RESETSCALE
        #--------------------------------------------
        # Modification d'un composant texte 3d        
        # # DC Function Usage: =resetscale()        
          if not DCFunctionsV1.method_defined?(:resetscale)
            def resetscale(a)
              obj = @source_entity
              family = SimJoubert::AddDCFunctions::FunctionsFamilies.family('090-definition')
              tr_matrix = obj.transformation.to_a
              xscale = tr_matrix[0]
              yscale = tr_matrix[5]
              zscale = tr_matrix[10]
              tr_reset_scale = Geom::Transformation.scaling(1.0/xscale, 1.0/yscale, 1.0/zscale)
              obj.transform!(tr_reset_scale)
              return family.translate("Scale Reset")
            end
          end # fin resetscale()

        #--------------------------------------------
        # FONCTION OPTIONS_FROM_CSV
        #--------------------------------------------
        # DC Function usage =options_from_csv(url,separator,name)
        # return an array from csv file
          if not DCFunctionsV1.method_defined?(:options_from_csv)
            def options_from_csv(a)

              # Recupération des variables passées en paramètres
              url = a[0] # url du fichier csv D://Folder/namefile.csv
              separator_index = a[1].to_i #Num du type de séparateur de données 0 =>"," 1=>";" 2=>"tabulation" 3=>"|"
              name = a[2] # nom de l'attribut dont il faut définir la liste d'option

              # Définition de variables
              source_def = @source_entity.definition
              dcdict = "dynamic_attributes"
              family = SimJoubert::AddDCFunctions::FunctionsFamilies.family('090-definition')
              separator_array = [",",";","\t","\|"] # liste des types de séparateur de données

              if separator_index >= separator_array.length
                  separator_index = 0 #On définit la virgule comme séparateur par défaut
              end
              separator = separator_array[separator_index]

              # Extraction des données du fichier CSV

              # On test si le le premier carctère est ~ signifiant qu'il s'agit d'une url relative au repertoire du modele
              if url[0] == "~"
                model_folder = File.dirname(File.realpath(Sketchup.active_model.path)) # on récupère le dossier d'enregistrement du modèle
                if File.exist?model_folder # On test si le dossier du modèle existe 
                  path = url.slice(1..-1) # on retire le premier caractère de l'url relative
                  url = File.absolute_path(path, model_folder) # on transforme l'url relative en url absolue
                else
                  retour = family.translate("ERROR The Sketchup model must be save befor") # erreur le modèle n'a pas de dossier d'enregistrement
                end
              end
              

              ## On test l'existe du fichier dont le chemin d'accès est url
              if File.exist?(url) == false
                  retour = family.translate("ERROR File doesn't existe")
              else
              ## Lecture du fichier dans la variable table
                table = CSV.parse(File.read(url,:encoding => 'windows-1252:utf-8'), col_sep: separator, headers: true )
                table_n = table.length

                ## On test la presence d'enregistrement
                if table_n < 1
                    retour = family.translate("ERROR The file doesn't contain a value or is unreadable")
                else
                  largeur = table[0].length
                  arr = []
                  ## Si la table n'a qu'une seule colonne
                  ## option = value
                  if largeur == 1
                    i = 0

                    while i<table_n
                      option = table[i][0]
                      value = table[i][0]
                      if i == 0
                        value0 = value
                      end
                        arr[i] = "#{option}=#{value}"
                        i +=1
                    end
                  ## Si la table à plusieurs colonnes
                  ## option (1er colonne) et value (2eme colonne)
                  else
                    i = 0
                    while i<table_n
                      option = table[i][0]
                      value = table[i][1]
                      if i == 0
                        value0 = value
                      end
                      arr[i] = "#{option}=#{value}"
                      i +=1
                    end
                  end
                  retour = family.translate("Options for the attribute %{name} from the CSV file has been created")
                  retour %= {:name => name}
                  
                  ## On combine l'array sous forme de chaine avec "&" comme séparateur d'option
                  options = "&"+arr.join("&")+"&"
                end
              end

              name_minus = name.downcase

              # Création et mise à jour de l'attribut
              ## On definit la valeur de l'attribut name
              source_def.set_attribute(dcdict, name_minus, value0)

              ## Si le méta_attribut label n'est pas déja définit on le définit
              unless source_def.get_attribute(dcdict, "_" + name_minus + "_label", false)
                source_def.set_attribute(dcdict, "_" + name_minus + "_label", name)
              end

              ## Si le méta_attribut formlabel n'est pas définit on le définit
              unless source_def.get_attribute(dcdict, "_" + name_minus + "_formlabel", false)
                source_def.set_attribute(dcdict, "_" +name_minus + "_formlabel", name)
              end

              ## On définit les méta_attributs options et access
              source_def.set_attribute(dcdict,"_"+ name_minus +"_options", options)
              source_def.set_attribute(dcdict,"_"+ name_minus +"_access", "LIST")

              return retour

            end
          end

        #--------------------------------------------
        # FONCTION SWITCH_ACCESS_ATTRIBUTE
        #--------------------------------------------
        # Modififie selon une condition le méta attribut _access pour un attribut       
        # # DC Function Usage: = switch_access_attribute(condition , "Attribute_name", access_true, access_false)     
          if not DCFunctionsV1.method_defined?(:switch_access_attribute)
            def switch_access_attribute(a)

              # Recupération des variables passées en paramètres
              cond = a[0] # condition
              name = a[1].downcase # Attribute name target
              access_true = a[2].to_i # index access_array si condition est vrai
              access_false = a[3].to_i # index access_array si condition est vrai

              # Déclaration de variables
              access_array = ["NONE","VIEW","TEXTBOX","LIST"]
              source_def = @source_entity.definition
              dcdict = "dynamic_attributes"
              family = SimJoubert::AddDCFunctions::FunctionsFamilies.family('090-definition')

              # Calcul
              if cond == 1 # si la condition est vrai
                if access_true > 3
                  access = access_array[0]
                else
                  access = access_array[access_true]
                end
              else # si la condition est fausse
                if access_false > 3
                  access = access_array[0]
                else
                  access = access_array[access_false]
                end
              end
              
              # Modification de l'affichage de l'attribut dans le panneau option du composant
              unless source_def.get_attribute(dcdict, name ,false)
                  result = family.translate("No attribute match") #"Aucune correspondance d'attribut"
              else
                  source_def.set_attribute(dcdict, "_" + name + "_access" , access)
                  result = family.translate("%{name} access mode %{access}")
                  result %= {:name => name, :access => access}
              end

              return result
            end
          end # Fin switch_access_attribute

        #--------------------------------------------
        # FONCTION SWITCH_ACCESS_ATTRIBUTE_BEGIN
        #--------------------------------------------
        # Modififie selon une condition le méta attribut _access pour tout les attribut dont le nom commence par        
        # # DC Function Usage: =switch_access("condition","begin_name","access_true","access_false")     
          if not DCFunctionsV1.method_defined?(:switch_access_attribute_begin)
            def switch_access_attribute_begin(a)

              # Recupération des variables passées en paramètres
              cond = a[0] # condition
              search_name = a[1].downcase # Attribute name target
              access_true = a[2].to_i # index access_array si condition est vrai
              access_false = a[3].to_i # index access_array si condition est vrai

              # Déclaration de variables
              access_array = ["NONE","VIEW","TEXTBOX","LIST"]
              source_def = @source_entity.definition
              dcdict = "dynamic_attributes"
              family = SimJoubert::AddDCFunctions::FunctionsFamilies.family('090-definition')

              # Calcul access
              if cond == 1 # si la condition est vrai
                if access_true > 3
                  access = access_array[0]
                else
                  access = access_array[access_true]
                end
              else # si la condition est fausse
                if access_false > 3
                  access = access_array[0]
                else
                  access = access_array[access_false]
                end
              end

              # Recherche des attribut dont le nom commence par search_name
              sl = search_name.length-1 # longueur du texte recherché

              attrdicts = source_def.attribute_dictionaries # ensemble des dictionnaire pour la définition du composant
              attrdict_dc = attrdicts[dcdict] # dictionnaire dcdict pour la définition
              keys = attrdict_dc.keys # Array des noms d'attribut pour le composant dans le dictionnaire dcdict

              find = []
              n = keys.length
              i = 0
              # Boucle sur chaque attribut et test s'il commence par 
              while i<n
                if keys[i].slice(0..sl).downcase == search_name
                  find << keys[i] # s'il match alors ajout à l'array find
                end
                i +=1
              end

              # Calcul de la valeur de retour
              fl = find.length # nombre d'attributs trouvés

              if fl < 1
                  result = family.translate("No attribute match") #"Aucune correspondance d'attribut"
              elsif fl == 1
                  result = family.translate("%{fl} attribute begin by %{search_name} access mode %{access}")
                  result %= { :fl => fl, :search_name => search_name , :access => access}
              else
                result = family.translate("%{fl} attributes begin by %{search_name} access mode %{access}")
                result %= { :fl => fl, :search_name => search_name , :access => access}
              end

              # Boucle sur chaque attribut trouvé et modification du meta attribut access
              i = 0
              while i<fl
                name = find[i]
                source_def.set_attribute(dcdict, "_" + name + "_access" , access)
                i +=1
              end
                
              return result
            end
          end # fin switch_access_attribute_begin

       
        #--------------------------------------------
        # FONCTION SWITCH_ACCESS_ATTRIBUTE_MULTI
        #--------------------------------------------
        # Modififie selon une condition les méta attribut _access pour plusieurs attributs     
        # # DC Function Usage: =switch_access_attribute_multi("condition","name,access_true,access_false"{,"name,access_true,access_false",...})     
          if not DCFunctionsV1.method_defined?(:switch_access_attribute_multi)
            def switch_access_attribute_multi(a)

               # Recupération des variables passées en paramètres
              cond = a[0].to_i # Condition
              string_array = a.slice(1..-1) # Array of sub array "attribute_name ; access_true ; access_false" , ".;.;." , ".;.;."
                
              # Déclaration de variables
              access_array = ["NONE","VIEW","TEXTBOX","LIST"]
              source_def = @source_entity.definition
              dcdict = "dynamic_attributes"
              family = SimJoubert::AddDCFunctions::FunctionsFamilies.family('090-definition')

              # On test l'éxistance de valeur
              n = string_array.length # nombre de groupes de parametres access
              if n<1
                  result = family.translate("No attribute access parameters")
              else
                # Initialisation de variable pour la boucle sur chaque groupe de paramètres renseignés
                i = 0 # compteur de boucle
                error = 0 # compteur erreur
                success = 0 # compteur success

                while i<n
                  sub_array = string_array[i].split(",") # On transforme en array le groupe n° i

                  if sub_array.length <3 # 3 valeurs sont attendues,  s'il y en a moins alors erreur
                    error +=1
                  else
                    # Recupération des variables passées en paramètres                  
                    name = sub_array[0].downcase # Attribute name target
                    access_true = sub_array[1].to_i # index access_array if true
                    access_false = sub_array[2].to_i # index access_array if false

                    if cond == 1 # si la condition est vrai
                      if access_true >3
                        access_true = 0
                      end
                      access = access_array[access_true]
                    else # la condition est fausse
                      if access_false >3
                        access_false = 0
                      end
                      access = access_array[access_false]
                    end              
                    
                    # test de l'existance de l'attribut et modification de son meta attribut _access
                    unless source_def.get_attribute(dcdict, name , false)
                      error +=1
                    else
                      source_def.set_attribute(dcdict, "_" + name + "_access" , access)
                      success +=1 
                    end

                        
                  end
                  i +=1
                end # fin de la boucle

                result = family.translate("%{success} attributes modifying access and %{error} errors on %{n}")
                result %= {:success => success, :error => error, :n => n}
              end


              return result
          end
        end # fin switch_access_attribute_multi

        #--------------------------------------------
        # FONCTION GetPersistentID v 9.10
        #--------------------------------------------
        # Recupère l'identifiant persistant de l'instance    
        # # DC Function Usage: =getpersistentid()     
        if not DCFunctionsV1.method_defined?(:getpersistentid)
          def getpersistentid(a)
            id = @source_entity.persistent_id
            return id
          end
        end

        #--------------------------------------------
        # FONCTION GetAttributeFromPersistentId v 9.10
        #--------------------------------------------
        # Récupère la valeur d'un attribut d'une instance définit par son persitent id     
        # # DC Function Usage: =GetAttribute_FromPersistentId(persistent_id, attribut_name, value if not define)     
        if not DCFunctionsV1.method_defined?(:getattribute_frompersistentid)
          def getattribute_frompersistentid(a)
            # On récupère les paramètres
            id = a[0].to_i
            attribut = a[1].to_s
            default = a[2].to_s

            model= Sketchup.active_model
            dcdict = "dynamic_attributes"
            inst = model.find_entity_by_persistent_id(id)
            value = inst.get_attribute(dcdict,attribut,default)
            return value
          end
        end


  
  end # class
end # if
  