require 'fileutils'
require 'json'
require 'sketchup'
require 'sj_add_dc_functions/functions_families'

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    # Une famille de fonctions pour les composants dynamiques SketchUp.
    class FunctionsFamily
      # Accès en lecture au titre (traduit) de cette famille, son auteur, ses fonctions et son ID :
      attr_reader(:title, :author, :functions, :id)

      # Initialise la traduction.
      def init_translation
        @translation = {}

        # Le chemin du fichier de traduction de cette famille de fonctions est déduit de son ID.
        # Exemple sur une installation de SketchUp en français : "010-text" => "010-text.fr.json"
        translation_file = File.join(FunctionsFamilies::DIR, "#{@id}.#{Sketchup.get_locale}.json")

        return unless File.exist?(translation_file)

        begin
          @translation = JSON.parse(File.read(translation_file))
        rescue JSON::ParserError
          UI.messagebox("Error: Translation file isn't a valid JSON. Check: #{translation_file}")
        end
      end

      # Construit un objet de type `FunctionsFamily`.
      #
      # @param [String] id Identifiant de cette famille de fonctions. Exemple : "010-text"
      # @raise [ArgumentError]
      def initialize(id)
        raise ArgumentError, 'ID must be a String.' unless id.is_a?(String)

        @id = id
        @title = ''
        @author = ''
        @functions = []
        init_translation
      end

      # Traduit une chaîne de caractères pour cette famille de fonctions, si elle a été traduite.
      #
      # @param [String] string La chaîne à traduire.
      # @raise [ArgumentError]
      #
      # @return [String] La chaîne traduite ou le cas échéant la chaîne fournie en entrée.
      def translate(string)
        raise ArgumentError, 'String expected.' unless string.is_a?(String)

        return @translation[string] if @translation.key?(string)

        string
      end

      # Définit le titre de cette famille de fonctions.
      #
      # @param [String] title Exemple : "Text functions"
      # @raise [ArgumentError]
      def title=(title)
        raise ArgumentError, 'Title must be a String.' unless title.is_a?(String)

        @title = translate(title) # Si possible, le titre est traduit.
      end

      # Définit l'auteur de cette famille de fonctions.
      #
      # @param [String] author Exemple : "Simon Joubert"
      # @raise [ArgumentError]
      def author=(author)
        raise ArgumentError, 'Author must be a String.' unless author.is_a?(String)

        @author = author
      end

      # Ajoute une fonction dans cette famille de fonctions.
      #
      # @param [Function] function
      # @raise [ArgumentError]
      def add_function(function)
        raise ArgumentError, "Function must be a #{Function.name}." unless function.is_a?(Function)

        @functions.push(function)
      end
    end
  end
end
