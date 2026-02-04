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
    functions_family = FunctionsFamily.new('030-dimension')
    functions_family.title = 'Dimension functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('Volume', functions_family)
    function.add_parameter('unit', 'Possible units are: pc3, m3, dm3, cm3, l, dl, cl, ml, dam3, hm3 and km3.')
    function.add_parameter('valueIfNotSolid', 'Return value if the volume could not be defined, because the component is not solid. Maybe text or a number.')
    function.add_parameter('rounded', 'Number of decimal places.')
    function.description = 'Returns the volume of the solid component, converted and rounded.<br> , If the component is not solid, the value of the "valueIfNotSolid" parameter is returned.'
    functions_family.add_function(function)

    # TODO: Aliaser Aire en Area ?
    function = Function.new('Aire', functions_family)
    function.add_parameter('unit', 'Possible units are: pc2, m2, dm2, cm2, mm2, dam2, hm2 and km2.')
    function.add_parameter('rounding', 'Number of decimal places.')
    function.description = 'Calculation of the area of the component faces.'
    functions_family.add_function(function)

    function = Function.new('ProfilBuilder', functions_family)
    function.add_parameter('unit', 'Possible units are: pc, m, dm, cm, mm, dam, hm and km.')
    function.add_parameter('rounding', 'Number of decimal places.')
    function.description = 'Calculation of the length of the profil make with Profil Builder plugin.'
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
          ##### FONCTIONS VOLUME, AIRE, LONGUEUR ####
          #_____________________________________________________________________________________________________________________________
  
          #calule du volume du composant
          # format attendu VOLUME(unité, arrondi)
          # DC Function Usage: =volume(unité, valeur si composant non solide,  arrondi) ou =volume(unité, valeur si composant non solide)
          if not DCFunctionsV1.method_defined?(:volume)
              def volume(a)
                  #calcule du taux de conversion pouce cube en m3 par multiplication
                  metrique = 0.0254 * 0.0254 * 0.0254
                  #on récupère les valeur passées dans l'array a paramètre
                  unite = a[0].downcase
                  valeursinonsolide = a[1]
                  arrondi = a[2]
                  
                  # calcule du volume en pouce cubique
                  vol = @source_entity.volume
                  # calcule du volume en m3
                  vol_m = vol*metrique
  
                  #conversion du volume selon le paramètre d'unité passé
                  if unite == "pc3"
                  vol_c = vol
                  elsif unite == "m3"
                  vol_c = vol_m
                  elsif unite == "dm3"
                  vol_c = vol_m * 1000
                  elsif unite == "cm3"
                  vol_c = vol_m * 1000000
                  elsif unite == "mm3"
                  vol_c = vol_m * 1000000000
                  elsif unite == "l"
                  vol_c = vol_m * 1000
                  elsif unite == "dl"
                  vol_c = vol_m * 10000
                  elsif unite == "cl"
                  vol_c = vol_m * 100000
                  elsif unite == "ml"
                  vol_c = vol_m * 1000000
                  elsif unite == "dam3"
                  vol_c = vol_m * 0.001
                  elsif unite == "hm3"
                  vol_c = vol_m * 0.000001
                  elsif unite == "km3"
                  vol_c = vol_m * 0.000000001
                  end
  
                  
                  #Arrondi du volume convertie selon le paramètre du nombre de digit après la virgule
                  #si non renseigné renvoi la convertion brute
                  if arrondi == nil
                  vol_a = vol_c
                  else
                  vol_a = sprintf( "%.#{arrondi}f",vol_c)
                  end
                  
                  # si le composant n'est pas solide et na donc pas de volume la valeur retournée sera -1
                  if vol == -1
                  vol_a = valeursinonsolide
                  end
  
                  #retourne la valeur du volume convertie et arrondie
                  return vol_a
              end
          end
          #FIN VOLUME
          
          
  
          #calule de l'aire des faces du composant
          # format attendu AIRE(unité, arrondi)
          # DC Function Usage: =aire(unité, arrondi) ou =aire(unité)
          if not DCFunctionsV1.method_defined?(:aire)
              def aire(a)
                    #calcule du taux de conversion pouce carré en m² par multiplication
                    metrique = 0.0254 * 0.0254
                    #on récupère les valeur passées dans l'array a paramètre
                    unite = a[0].downcase
                    arrondi = a[1]
    
                    # calcule de l'aire en inch
                    #somme recurssive de toutes les faces de l'instance
                    ents = @source_entity.definition.entities
                    tr = @source_entity.transform
                    aire_i = 0
                    faces = ents.grep(Sketchup::Face)
                    faces.each do |face|
                        surface = face.area(tr)
                        aire_i = aire_i + surface
                    end
                  #conversion de l'aire selon le paramètre d'unité passé
                  #si unité non renseigné renvoi l'aire en pouce carré
                    aire_m = aire_i * metrique
                    if unite == "pc2"
                        air_c = aire_i
                    elsif unite == "m2"
                        aire_c = aire_m
                    elsif unite == "dm2"
                        aire_c = aire_m * 100
                    elsif unite == "cm2"
                        aire_c = aire_m * 10000
                    elsif unite == "mm2"
                        aire_c = aire_m * 1000000
                    elsif unite == "dam2"
                        aire_c = aire_m / 100
                    elsif unite == "hm2"
                        aire_c = aire_m / 10000
                    elsif unite == "km2"
                        aire_c = aire_m / 1000000
                    elsif unite == "ha"
                        aire_c = aire_m / 1000
                    elsif unite == "a"
                        aire_c = aire_m / 100
                    end
  
                    #Arrondi de l'aire convertie selon le paramètre du nombre de digit après la virgule
                    #si non renseigné renvoi la convertion brute
                    if arrondi == nil
                        aire_a = aire_c
                    else
                        aire_a = sprintf( "%.#{arrondi}f",aire_c)
                    end
                    #retourne la valeur de l'aire convertie et arrondie
                    return aire_a
              end
          end
          #FIN AIRE

          #calule longueur du profilbuilder
          # format attendu PROFILBUILBER(unité, arrondi)
          # 
          if not DCFunctionsV1.method_defined?(:profilbuilder)
            def profilbuilder(a)
                #calcule du taux de conversion pouce en m par multiplication
                metrique = 0.0254
                #on récupère les valeur passées dans l'array a paramètre
                unite = a[0].downcase
                arrondi = a[1]

                chain =  @source_entity.definition.get_attribute("ProfileBuilder","chain","[]")
                chain = eval(chain)
                if chain.length == 0
                    chain_dist = 0
                else
                    dist_arr = []
                    i = 0
                    imax = chain.length
                    while i<imax

                        if chain[i].is_a?(Array) && i<imax
                            if chain[i+1].is_a?(Array)
                                point1 = Geom::Point3d.new(chain[i])
                                point2 = Geom::Point3d.new(chain[i+1])
                                dist_arr[i] = point1.distance(point2)
                            else
                                dist_arr[i] = 0
                            end
                        elsif chain[i].is_a?(Hash)
                            if chain[i][:type] == "Arc"
                                dist_arr[i] = ( 2 * chain[i][:radius] * Math::sin( ( ( chain[i][:endAngle] - chain[i][:startAngle] ) / chain[i][:numSegments] ) / 2 ) ) * chain[i][:numSegments]
                            
                            elsif chain[i][:type] == "Curve"
                                points = chain[i][:points]
                                j = 0
                                jmax = points.length
                                points_dist = []
                                while j < jmax-1
                                    point1 = Geom::Point3d.new(points[j])
                                    point2 = Geom::Point3d.new(points[j+1])
                                    points_dist[j] = point1.distance(point2)
                                    j = j + 1
                                end
                                dist_arr[i] = points_dist.sum
                            end
                           
                        end
                        i = i + 1
                    end
                    chain_dist = dist_arr.sum
                end
                dist_m = chain_dist*metrique
                dist_p = chain_dist

                if unite == "pc"
                    dist = dist_p
                elsif unite == "m"
                    dist = dist_m
                elsif unite == "dm"
                    dist = dist_m * 10
                elsif unite == "cm"
                    dist = dist_m * 100
                elsif unite == "mm"
                    dist = dist_m * 1000
                elsif unite == "dam"
                    dist = dist_m / 10
                elsif unite == "hm"
                    dist = dist_m / 100
                elsif unite == "km"
                    dist = dist_m / 1000
                end

                #Arrondi de la distance convertie selon le paramètre du nombre de digit après la virgule
                  #si non renseigné renvoi la convertion brute
                  if arrondi == nil
                    dist_a = dist
                else
                    dist_a = sprintf( "%.#{arrondi}f",dist)
                end
                #retourne la longueur convertie et arrondie
                return dist_a







            end
        end
  
    end # class
end # if
