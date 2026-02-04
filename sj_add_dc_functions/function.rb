require 'sj_add_dc_functions/functions_family'

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions

    def self.array_shuffle(array)
      array_rand = array.sort_by{rand}
      return array_rand
    end


    # Une fonction pour les composants dynamiques SketchUp.
    class Function
      # Accès en lecture au nom, à la description (traduite) et aux paramètres (traduits) de cette fonction :
      attr_reader(:name, :description, :parameters)

      # Construit un objet de type `Function`.
      #
      # @param [String] name Nom de cette fonction. Il doit être unique. Exemple : "Occurrence"
      # @param [FunctionsFamily] family Famille de cette fonction. Utilisée pour la traduction.
      # @raise [ArgumentError]
      def initialize(name, family)
        raise ArgumentError, 'Name must be a String.' unless name.is_a?(String)
        raise ArgumentError, "Family must be a #{FunctionsFamily.name}." unless family.is_a?(FunctionsFamily)

        @name = name # TODO: S'assurer de l'unicité de ce nom de fonction, toutes familles confondues ?
        @family = family
        @description = ''
        @parameters = []
      end

      # Définit la description de cette fonction.
      #
      # @param [String] description Exemple : "Allows you to obtain the number of occurrences..."
      # @raise [ArgumentError]
      def description=(description)
        raise ArgumentError, 'Description must be a String.' unless description.is_a?(String)

        @description = @family.translate(description) # Si possible, la description est traduite.
      end

      # Ajoute un paramètre à cette fonction.
      #
      # @param [String] name Nom du paramètre. Exemple : "text"
      # @param [String] description Description du paramètre. Exemple : "Text on which the search..."
      # TODO: Ajouter un argument `type` ? Exemple : "Integer"
      # @raise [ArgumentError]
      def add_parameter(name, description)
        raise ArgumentError, 'Name must be a String.' unless name.is_a?(String)
        raise ArgumentError, 'Description must be a String.' unless description.is_a?(String)

        @parameters.push({
                           # Si possible, le nom et la description sont traduits.
                           name: @family.translate(name),
                           description: @family.translate(description)
                         })
      end

      # Renvoie la signature (traduite) de cette fonction. Exemple : OCCURRENCE(texte, chaine)
      #
      # @return [String]
      def signature
        parameters_names = []

        @parameters.each do |parameter|
          parameters_names.push(parameter[:name].to_s)
        end

        "#{@name.upcase}(#{parameters_names.join(', ')})"
      end
    end
  end
end
