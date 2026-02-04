module SU_Furniture
  class SUFLanguage

    def initialize(strings_file_name, lang)
      unless strings_file_name.is_a?(String)
        raise ArgumentError, 'must be a String'
      end
      @lang = lang
      @strings = Hash.new { |hash, key| key }
      parse(strings_file_name, lang)
    end
    
    def [](key)
      value = @strings[key]
      if value.is_a?(String)
        value = value.dup
      end
      return value
    end
    alias :GetString :[]
    
    def language
      return @lang
    end
    
    def strings
      return @strings
    end
    alias :GetStrings :strings
    
    def strings_file
      @strings_file ? @strings_file.dup : nil
    end
    
    private
    
    def parse(strings_file_name, lang)
      
      strings_file = File.join(PATH, 'Resources', lang, strings_file_name)
      if strings_file.nil?
        return false
      end
      
      @strings_file = strings_file
      
      @language_folder = File.expand_path(File.dirname(strings_file))
      
      File.open(strings_file, 'r:BOM|UTF-8') { |lang_file|
        entry_string = ''
        in_comment_block = false
        lang_file.each_line { |line|

          if !line.lstrip.start_with?('//')

            if line.include?('/*')
              in_comment_block = true
            end
            if in_comment_block
              if line.include?('*/')
                in_comment_block = false
              end
              else
              entry_string += line
            end
          end
          
          if entry_string.include?(';')
            pattern = /^\s*"(.+)"="(.+)"\s*;\s*(?:\/\/.*)*$/
            result = pattern.match(entry_string)
            if result && result.size == 3
              key = result[1]
              value = result[2]
              @strings[key] = value
            end
            entry_string.clear
          end
        } 
      }
      return true
    end
    
  end # class
end # module SU_Furniture
