require 'sketchup.rb'
require 'extensions.rb'
require 'langhandler.rb'
version_required = 18
module SU_Furniture
  
  PLUGIN_ID       = 'ART ROCKET'.freeze
  PLUGIN_NAME     = 'ART_ROCKET'.freeze
  PLUGIN_VERSION  = '3.0.0'.freeze
  if Sketchup.read_default("SUF", "TEMP_PATH")
    TEMP_PATH = Sketchup.read_default("SUF", "TEMP_PATH")
    else
    TEMP_PATH = File.expand_path(ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'])
  end
  FILENAMESPACE = File.basename("suf", "suf_loader")
  path = __FILE__
  path.force_encoding("UTF-8") if path.respond_to?(:force_encoding)
  PATH_ROOT     = File.dirname(path).freeze
  PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
  PATH_ICONS    = $path_icons = File.join(PATH, 'icons').freeze
  PATH_COMP     = File.join(File.dirname(PATH_ROOT), "Components/SUF")
  PATH_MAT      = File.join(File.dirname(PATH_ROOT), "Materials/SUF")
  PATH_PRICE    = File.join(File.dirname(PATH_ROOT), "Materials/price")
  
  unless file_loaded?(__FILE__)
    loader = File.join( PATH, "suf_loader" )
    # loader = SUF_Native.run_tool
    SUF = SketchupExtension.new(PLUGIN_NAME, loader)
    SUF.description = 'Plugin '+PLUGIN_NAME
    SUF.version     = PLUGIN_VERSION
    SUF.copyright   = 'AR'
    SUF.creator     = 'AR'
    Sketchup.register_extension(SUF, true)
    
  end
end

file_loaded(__FILE__)
