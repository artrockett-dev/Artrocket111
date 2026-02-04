# coding: utf-8
require 'sketchup.rb'
require 'extensions.rb'

module ARADDONS
  PLUGIN_NAME    = 'AR ADDONS'.freeze
  PLUGIN_VERSION = '1.03'.freeze

  # Регистрируем бандл как одно расширение; точка входа: ar_addons/loader.rb
  ex = SketchupExtension.new(PLUGIN_NAME, File.join('ar_addons', 'loader'))
  ex.description = 'ART ROCKET'
  ex.version     = PLUGIN_VERSION
  ex.copyright   = '2025 AG'
  ex.creator     = 'ARTIOM GURDUZ'

  Sketchup.register_extension(ex, true)
end


















