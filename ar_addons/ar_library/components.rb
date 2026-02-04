# encoding: UTF-8
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.
Sketchup.require(File.join(__dir__, 'core'))

module ARLIB
  module Components
    extend self

    # Путь к корню компонентов внутри Components/ARLIB
    ASSETS_FOLDER = Paths.components_root

    def get_folder_contents(folder_path = nil, search_query = nil)
      folder_path ||= ASSETS_FOLDER
      ContentBrowser.get_folder_contents(folder_path, search_query)
    end

    # Тонкие обертки (для совместимости старого фронтенда)
    def add_component(_dialog, component_path)
      LibraryOps.add_component(component_path)
    end

    def replace_component(_dialog, component_path)
      LibraryOps.replace_component(component_path)
    end
  end
end
