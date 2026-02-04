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
    functions_family = FunctionsFamily.new('130-suite')
    functions_family.title = 'Math suite functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('Suite_Fibonacci', functions_family)
    function.add_parameter('n', 'The index of the suite to be calculated')
    function.description = 'Return the result of the Fibonacci suite for the index pass in parameter'
    functions_family.add_function(function)

    function = Function.new('Suite_Sum', functions_family)
    function.add_parameter('n', 'The index of the suite to be calculated')
    function.description = 'Return the result of the sum  of the integer between 0 and the terme pass in parameter'
    functions_family.add_function(function)

    function = Function.new('Suite_Factorial', functions_family)
    function.add_parameter('n', 'The index of the suite to be calculated')
    function.description = 'The factorial of an integer is the product of all integers that are less than or equal to the integer.<br>Return the factorial of the index pass in parameter.'
    functions_family.add_function(function)

    function = Function.new('Suite_Custom', functions_family)
    function.add_parameter('n', 'The index of the suite to be calculated')
    function.add_parameter('function_f', 'The literal calculation of the function f(n) to be evaluated. <br>You will use the symbol <b>n</b> for the value of the term,<br>the symbol <b>fm</b> for the result of f(n-1).<br>Example: (n+5)/(fm-1)')
    function.add_parameter('f0', 'The result for f(0)')
    function.description = 'Function that allows finding the result of a customizable mathematical function, which involves in its resolution the result of the same function for the previous integer.'
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
        # FONCTION SUITE_FIBONACCI
        #--------------------------------------------
          # # DC Function Usage: =Suite_Fibonacci(n)
          # # returns the result of the Fibonacci suite for the terme n
          if not DCFunctionsV1.method_defined?(:suite_fibonacci)
              def suite_fibonacci(a)
                # On récupère le terme  passé en paramètre
                  n = a[0].to_i
                # On initialise le total
                  tn2 = 0
                  tn1 = 1
                # On réalise une boucle de 0 à n
                  for i in 0..n
                    tn = tn1+tn2
                    tn2 = tn1
                    tn1 = tn
                  end
                # On retourne le resultat
                  return tn1
              end
          end
  
        #--------------------------------------------
        # FONCTION SUITE_SUM
        #--------------------------------------------
          # # DC Function Usage: =suite_sum(n)
          # # returns the sum of the number beetween 0 to n
          if not DCFunctionsV1.method_defined?(:suite_sum)
              def suite_sum(a)
                #on récupère le terme  passé en paramètre
                  n = a[0].to_i
                # On initialise le total
                  t = 0
                # On réalise une boucle de 0 à n
                  for i in 0..n
                    t = t+i
                  end
                # On retourne le resultat
                  return t
              end
          end
  
  
        #--------------------------------------------
        # FONCTION SUITE_FACTORIAL
        #--------------------------------------------
          # Calcule le factoriel d'un nombre
          
          # # DC Function Usage: =Suite_Factorial(n)
          # # the factorial of an integer is the product of all integers that are less than or equal to the integer.
          if not DCFunctionsV1.method_defined?(:suite_factorial)
            def suite_factorial(a)
              #on récupère le terme  passé en paramètre
                n = a[0].to_i
              # On initialise le total
                t = 1 # 0!=1
              # On réalise une boucle de 0 à n
                for i in 0..n.abs()
                  if i == 0
                    t = 1
                  else
                    if n<0
                      t = t*(i)
                    else
                      t = t*i
                    end
                  end
                end
              # On retourne le resultat
                return t
            end
        end

      #--------------------------------------------
        # FONCTION SUITE_CUSTOM
        #--------------------------------------------
          # Calcule le résultat d'une suite
          
          # # DC Function Usage: =Suite_Custom(n,fonction,fo)
          # # the factorial of an integer is the product of all integers that are less than or equal to the integer.
          if not DCFunctionsV1.method_defined?(:suite_custom)
            def suite_custom(a)
              #on récupère le terme  passé en paramètre
                n = a[0].to_i.abs()
              # On récupère la fonction
                fc = a[1].to_s
                fc = fc.gsub("n","i")
                fc = fc.gsub("fm","t")
              # On récupère la valeur de f(0)
                t = a[2].to_f
              # On initialise le total
                #t = fz
              # On réalise une boucle de 0 à n
                for i in 1..n
                  t = eval(fc)
                end
              # On retourne le resultat
                return t
            end
        end

        
  
  end # class
end # if
