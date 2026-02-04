require 'fileutils'

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    # Familles de fonctions pour les composants dynamiques SketchUp.
    module FunctionsFamilies
      # Chemin absolu vers le dossier des familles de fonctions.
      DIR = File.join(__dir__, 'Functions Families')

      @families = []

      # Charge en mémoire les familles de fonctions.
      def self.load
        # Chaque famille de fonctions est documentée et implémentée dans un fichier Ruby qui lui est propre.
        # Ces fichiers sont chargés par ordre alphanumérique. Exemple : "010-text.rb", "020-text_3d.rb", etc.
        Dir[File.join(DIR, '*.rb')].sort.each do |family_ruby_file|
          require family_ruby_file
        end
      end

      # Ajoute une famille de fonctions.
      #
      # @param [FunctionsFamily] family
      # @raise [ArgumentError]
      def self.add_family(family)
        raise ArgumentError, "Family must be a #{FunctionsFamily.name}." unless family.is_a?(FunctionsFamily)

        @families.push(family)
      end

      # Renvoie les familles de fonctions, par ordre d'ajout.
      def self.families
        @families
      end

      # Retrouve une famille de fonctions via son identifiant.
      #
      # @param [String] id Identifiant de la famille de fonctions recherchée. Exemple : "050-layer_tag"
      # @raise [ArgumentError]
      #
      # @return [FunctionsFamily, nil]
      def self.family(id)
        raise ArgumentError, 'ID must be a String.' unless id.is_a?(String)

        @families.each do |family|
          return family if family.id == id
        end

        nil
      end
    end
  end
end
