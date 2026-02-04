require 'sj_add_dc_functions/functions_family'
require 'sj_add_dc_functions/function'
require 'sj_add_dc_functions/functions_families'
require 'sketchup'
require 'su_dynamiccomponents'
require 'json'
require 'csv'

# DOCUMENTATION DE CETTE FAMILLE DE FONCTIONS.

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    functions_family = FunctionsFamily.new('120-array')
    functions_family.title = 'Array functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('Array', functions_family)
    function.add_parameter('name', 'Name of the new attribute that will contain the array in array format.')
    function.add_parameter('string', 'Comma separated values text.')
    function.description = 'Create an array from the values passed as parameters, separated by commas. The result is stored in an attribute in Array format.'
    functions_family.add_function(function)

    function = Function.new('Array_from_string', functions_family)
    function.add_parameter('string', 'String of values separated with a special char')
    function.add_parameter('index_special_char', 'Index of the special character. 0 for comma, 1 for semicolon, 2 for tabulation, 3 for spip.')
    function.add_parameter('name', 'Name of the new attribute that will contain the array in array format.')
    function.description = 'Converts a text string to an array. The special char serves as the separator. The result is stored in an attribute in Array format.'
    functions_family.add_function(function)

    function = Function.new('Array_random_from_string', functions_family)
    function.add_parameter('string', 'String of values separated with a special char')
    function.add_parameter('index_special_char', 'Index of the special character. 0 for comma, 1 for semicolon, 2 for tabulation, 3 for spip.')
    function.add_parameter('name', 'Name of the new attribute that will contain the array in array format.')
    function.description = 'Converts a text string to an array. The special character serves as a separator. The result is stored in an attribute in Array format. The board is randomized.'
    functions_family.add_function(function)

    function = Function.new('Array_from_csv', functions_family)
    function.add_parameter('path', 'File path')
    function.add_parameter('index_special_char', 'Index of the special character. 0 for comma, 1 for semicolon, 2 for tabulation, 3 for spip.')
    function.add_parameter('name', 'Name of the new attribute that will contain the array in array format.')
    function.description = 'Create an array from a CSV file. The result is stored in an attribute in array format.'
    functions_family.add_function(function)

    function = Function.new('Array_length', functions_family)
    function.add_parameter('array_name', 'Array name attribute.')
    function.description = 'Calculates the length of the array. Returns the number of values contained in the array.'
    functions_family.add_function(function)

    function = Function.new('Array_sum_to_index', functions_family)
    function.add_parameter('array_name', 'Array name attribute.')
    function.add_parameter('index', 'Index number, be careful the count of values starts at 0.')
    function.description = 'Calculates the cumulative sum of the array up to and including the index value.'
    functions_family.add_function(function)

    function = Function.new('Array_value', functions_family)
    function.add_parameter('array_name', 'Array name attribute.')
    function.add_parameter('index', 'Index number, be careful the count of values starts at 0.')
    function.add_parameter('index2', 'OPTIONAL, second index number to query the value of a nested array. Be careful the numbering starts at 0 !')
    function.description = 'Returns the value of an array corresponding to the index. For nested arrays you can fill in the index of the sub array.'
    functions_family.add_function(function)

    function = Function.new('Array_value_from_string', functions_family)
    function.add_parameter('string', 'String of values separated with a special char')
    function.add_parameter('index_special_char', 'Index of the special character. 0 for comma, 1 for semicolon, 2 for tabulation, 3 for spip.')
    function.add_parameter('index', 'Index number, be careful the count of values starts at 0.')
    function.description = 'Returns the value corresponding to the index of a string list delimited by a special char.'
    functions_family.add_function(function)

    function = Function.new('Array_Sort_Random', functions_family)
    function.add_parameter('array_name', 'Array name attribute.')
    function.description = 'Returns the randomized array'
    functions_family.add_function(function)

    function = Function.new('Donnut_path', functions_family)
    function.add_parameter('internal_radius', 'Internal radius')
    function.add_parameter('outer_radius ', 'Outer radius')
    function.add_parameter('angle', 'Angle described by curvature.')
    function.add_parameter('prefix', 'Prefix of the names of the arrays that will be created.')
    function.add_parameter('path', 'The path is composed by the ordered list of the junction direction of the sub-components (1 or -1) separated by commas.')
    function.description = "Create 4 attributes describing the coordinates of each copy of the donut's subcomponents. An array for X, Y coordinates, Z axis rotation and number of copies."
    functions_family.add_function(function)

    function = Function.new('Grid_path', functions_family)
    function.add_parameter('nbr_columns', 'Number of grid columns')
    function.add_parameter('nbr_rows', 'Number of grid rows')
    function.add_parameter('prefix', 'Prefix of the names of the arrays that will be created.')
    function.description = "Allows you to quickly model a sub-component grid. Returns 2 arrays with column and row number for each copy. As well as the number of copies. Each attribute name created is prefixed by the text passed as a parameter."
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
  

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function Usage: =array(string,name)
          # # return an array string is spliting by comma
          if not DCFunctionsV1.method_defined?(:array)
              def array(a)
                
                name = a[0]
                n=a.length
                i=1
                b=[]
                while i<n 
                    b[i-1] = a[i].to_f
                    i = i+1
                end
                #array = a.slice[1..-1]
                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"
                
                
                source_def.set_attribute( dcdict, name, b)
                source_def.set_attribute( dcdict, "_" + name + "_label",name)

                tr1 = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("has been created")

                return "Array #{name} #{tr1}"
              end
          end
          #fin Array

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY LENGTH
        #-----------------------------------------------------------------------------------------------------------------------  
          #Calcule de la longueur d'un array
          
          # # DC Function Usage: =array_length(array)
          # # returns the number of value in array
          if not DCFunctionsV1.method_defined?(:array_length)
              def array_length(*a)
                  #on récupère l'array passé en paramètre
                  array = a[0]
                  #on calcule la longueur de l'array
                  length = array.length              
              
                  return length
              end
          end
          #fin Array_length
  

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY SUM
        #-----------------------------------------------------------------------------------------------------------------------  
          # # DC Function Usage =array_sum_to_index() 
          # calcul la somme d'un array j'usqua l'index
          if not DCFunctionsV1.method_defined?(:array_sum_to_index)
              def array_sum_to_index(a)
                    array=a[0]
                    index = a[1].to_i
                    #if array[0].class.to_s == "String" || array.length == 0
                        #sum = 0
                    #else
                        n= array.length
              
                        if index >= n
                            index = n-1
                        end
                        i = 0 
                        sum = 0
                        while i <= index
                            sum = sum + array[i]        
                            i = i+1
                        end
                    #end
                    return sum
              end
          end
          #fin array_sum_to_index

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY VALUE
        #-----------------------------------------------------------------------------------------------------------------------
          # # DC Function Usage =array_value(array,index{,index2}) 
          # retourne la valeur correspondante à l'index
          if not DCFunctionsV1.method_defined?(:array_value)
            def array_value(a)
                array = a[0]
                index = a[1].to_i

                n = array.length            
                if index >= n
                    index = n-1
                elsif index <= -n
                    index = 0
                end
                # Si array simple niveau
                if a.length == 2
                    value = array[index]
                elsif a.length == 3
                    m = array[index].length
                    index2 = a[2].to_i
                    if index2 >= m
                        index2 = m-1
                    elsif index2 <= -m
                        index2 = 0
                    end
                    value = array[index][index2]
                end

                  return value
            end
        end
        #fin array_value_index

       

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION DONUT PATH 
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =Donut_path(radius_int,radius_ext,angle,string_path)
        # return 3 array with value for each segments position x position y rotation z and the number of copies
        if not DCFunctionsV1.method_defined?(:donut_path)
            def donut_path(a)
                # Recupération des variables passées en paramètres
                rint = a[0].to_f #internal radius
                rext = a[1].to_f #external radius
                angle = a[2].to_f #angle discribe by segment
                prefix = a[3] #prefix de attribut créés
                n=a.length
                i=4
                arr_path=[]
                while i<n 
                    arr_path[i-4] = a[i].to_f
                    i = i+1
                end
                #arr_path = a.slice(3..-1) # string array path whith 1 or -1 value representing the sens of rotation "[1,1,-1,-1,-1,1]"

                n = arr_path.length # longueur de l'array arr
                arr_x = [] # array contenant les coordonnées x pour chaque segment
                arr_y = [] # array contenant les coordonnées y pour chaque segment
                arr_rotz = [] # array contenant l'angle de rotation ROTZ pour chaque segment
                arr_sum = [] # array contenant la somme cumulée pour chaque segment

                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"

                # Calcul pour le premier segment du donut
                if arr_path[0] > 0
                    arr_x[0] = -rint
                    arr_rotz[0] = 0
                else
                    arr_x[0] = rext
                    arr_rotz[0] = 180-angle
                end
                arr_y[0] = 0
                arr_sum[0] = arr_path[0]

                # Calcul pour les segments suivants
                i = 1
    
                while i<n 
                    arr_sum[i] = arr_sum[i-1] + arr_path[i]
                    if arr_path[i] == arr_path[i-1]
                        arr_x[i] = arr_x[i-1]
                        arr_y[i] = arr_y[i-1]
                        if arr_path[i]>0
                            arr_rotz[i] = arr_rotz[i-1] + angle
                        else
                            arr_rotz[i] = arr_rotz[i-1] - angle
                        end
                    else
                        arr_x[i] = arr_x[i-1]+(Math.cos(arr_sum[i-1]*angle* Math::PI / 180)*(rint+rext)*arr_path[i-1])
                        
                        
                        if arr_path[i]>0
                            arr_y[i] = arr_y[i-1]-Math.sin(arr_sum[i-1]*angle* Math::PI / 180)*(rint+rext)                                                      
                            arr_rotz[i] = arr_sum[i-1]*angle
                        else
                            arr_y[i] = arr_y[i-1]+Math.sin(arr_sum[i-1]*angle* Math::PI / 180)*(rint+rext)                            
                            arr_rotz[i] =180+(arr_sum[i-1]-1)*angle
                        end
                    end
                    i = i+1
                end

                # Création ou mise à jour de 3 attributs aux format array
                source_def.set_attribute(dcdict,prefix+"_x", arr_x)
                source_def.set_attribute(dcdict,"_" + prefix + "_x_label", prefix + "_x")

                source_def.set_attribute(dcdict, prefix + "_y", arr_y)
                source_def.set_attribute(dcdict,"_" + prefix + "_y_label", prefix + "_y")

                source_def.set_attribute(dcdict, prefix + "_rotz", arr_rotz)
                source_def.set_attribute(dcdict,"_" + prefix + "_rot_z_label", prefix + "_rotz")

                # Création de l'attribut avec le nombre de copies
                source_def.set_attribute(dcdict, prefix+"_copies", n-1)
                source_def.set_attribute(dcdict, "_" + prefix + "_copies_label", prefix + "_copies")

                path = arr_path.join(',')

                return path
            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION GRID PATH 
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =grid_path(nbr_colonnes,nbr_rangees,prefix)
        # return 3 array with value for each segments position x position y rotation z and the number of copies
        if not DCFunctionsV1.method_defined?(:grid_path)
            def grid_path(a)
                # Recupération des variables passées en paramètres
                nc = a[0].to_i.abs #nombre de colonnes
                nr = a[1].to_i.abs #nombre de rangées
                prefix = a[2] #prefix des noms des attributs qui seront créés par la fonction

                # Initialisation de varibles

                c = [] #array du numéro de colonne pour chaque copies
                r = [] #array du numéro de rangée pour chaque copies               
                i = 0
                
                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"

                # Calcul

                n = (nc*nr).abs # nombre de copies
                while i<n
                    c[i] = i-((i/nc).floor(0))*nc
                    r[i] =(i/nc).floor(0)
                    i = i+1
                end

                # Retour fonction

                # Creation de 3 attributs
                source_def.set_attribute(dcdict,prefix+"_column", c)
                source_def.set_attribute(dcdict,"_"+prefix+"_column"+"_label", prefix+"_column")
                source_def.set_attribute(dcdict,prefix+"_rows", r)
                source_def.set_attribute(dcdict,"_"+prefix+"_rows"+"_label", prefix+"_rows")
                source_def.set_attribute(dcdict,prefix+"_copies", n-1)
                source_def.set_attribute(dcdict,"_"+prefix+"_copies"+"_label", prefix+"_copies")
                
                tr1 = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("Grid")
                tr2 = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("Arrays have been created")
                return "#{tr1} #{nc}x#{nr} #{tr2}"
            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY FROM STRING (Modified in v0.9.10)
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =array_from_string(string,char_delimiteur,name)
        # return 1 array with value from the string
        if not DCFunctionsV1.method_defined?(:array_from_string)
            def array_from_string(a)

                # Recupération des variables passées en paramètres
                string = a[0] #chaine de caractère source
                char = a[1].to_s #caractère de délimitation des valeurs
                name = a[2].to_s # nom de l'attribut Array à créer

                # Définition de variables
                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"

                # Calcul
                #string = source_def.get_attribute(dcdict,ref,"").to_s
                arr = string.split(char)

                # Retour de fonction               

                source_def.set_attribute(dcdict,name, arr)
                source_def.set_attribute(dcdict,"_"+ name +"_label", name)

                traduction = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("has been created from")
                return "Array #{name} #{traduction} #{string}"

            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY RANDOM FROM STRING (New in v0.9.10)
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =array_random_from_string(string,char_delimiteur,name)
        # return 1 array with value from the string
        if not DCFunctionsV1.method_defined?(:array_random_from_string)
            def array_random_from_string(a)

                # Recupération des variables passées en paramètres
                string = a[0] #chaine de caractère source
                char = a[1].to_s #caractère de délimitation des valeurs
                name = a[2].to_s # nom de l'attribut Array à créer

                # Définition de variables
                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"

                # Calcul
                #string = source_def.get_attribute(dcdict,ref,"").to_s
                arr = string.split(char)
                arr = SimJoubert::AddDCFunctions::array_shuffle(arr)

                # Retour de fonction               

                source_def.set_attribute(dcdict,name, arr)
                source_def.set_attribute(dcdict,"_"+ name +"_label", name)

                traduction = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("has been created from")
                return "Array #{name} #{traduction} #{string}"

            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY VALUE FROM STRING
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =array_value_from_string(string,char_delimiteur,index)
        # return index value from the string split in array
        if not DCFunctionsV1.method_defined?(:array_value_from_string)
            def array_value_from_string(a)

                # Recupération des variables passées en paramètres
                string = a[0] #chaine de caractère source
                char = a[1] #caractère de délimitation des valeurs
                index = a[2].to_i # index de la valeur

                # Définition de variables
                
                # Calcul
                value = string.split(char)[index]

                # Retour de fonction               

                
                return value

            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY SORT RANDOM v0.9.10
        #-----------------------------------------------------------------------------------------------------------------------
        #Melange un texte séparé mpar un caractère spéciale
        
        # # DC Function Usage: =array_sort_random(array)
        # # returns the number of the occurency of the string b in the string a
        if not DCFunctionsV1.method_defined?(:array_sort_random)
            def array_sort_random(a)

                # Recupération des variables passées en paramètres
                b = a[0]
                
                c = arr = SimJoubert::AddDCFunctions::array_shuffle(b)
                
                return c
            end
        end

        #-----------------------------------------------------------------------------------------------------------------------
        # FONCTION ARRAY FROM CSV
        #-----------------------------------------------------------------------------------------------------------------------
        # # DC Function usage =array_from_csv(url,name)
        # return an array from csv file
        if not DCFunctionsV1.method_defined?(:array_from_csv)
            def array_from_csv(a)

                # Recupération des variables passées en paramètres
                url = a[0] # url du fichier csv D://Folder/namefile.csv
                separator_index = a[1].to_i #Num du type de séparateur de données 0 =>"," 1=>";" 2=>"tabulation" 3=>"|"
                name = a[2] # nom de l'attribut array a créer

                # Définition de variables
                source_def = @source_entity.definition
                dcdict = "dynamic_attributes"
                separator_array = [",",";","\t","|"] # liste des types de séparateur de données

                if separator_index >= separator_array.length
                    separator_index = 0
                end

                separator = separator_array[separator_index]


                # Extrait des données du fichier CSV

                if File.exist?(url) == false
                    retour = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("ERROR File doesn't existe")
                else
                    table = CSV.parse(File.read(url,:encoding => 'windows-1252:utf-8'), col_sep: separator, headers: true )
                    table_n = table.length

                    if table_n < 1
                        retour = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("ERROR The file doesn't contain a value or is unreadable")
                    else
                        largeur = table[0].length
                        arr = []
                        if largeur == 1
                            i=0

                            while i<table_n
                                arr[i] = table[i][0]
                                i=i+1
                            end
                        else
                            i=0
                            while i<table_n
                                b = []
                                j = 0
                                while j < largeur
                                    b[j] = table[i][j]
                                    j = j+1
                                end
                                arr[i] = b
                                i = i+1
                            end
                        end
                        traduction = SimJoubert::AddDCFunctions::FunctionsFamilies.family('120-array').translate("from the csv file has been created")
                        retour = "Array #{name} #{traduction}"
                    end
                end

                # Création de l'attribut Array

                source_def.set_attribute(dcdict, name, arr)
                source_def.set_attribute(dcdict,"_"+ name +"_label", name)

                return retour

            end
        end

       

        










  
  end # class
end # if
