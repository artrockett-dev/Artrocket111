# encoding: UTF-8
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.
Sketchup.require(File.join(__dir__, 'core'))

module ARLIB
  module ComponentsContents
    extend self
    def get_folder_contents(folder, search_query = nil)
      ARLIB::ContentBrowser.get_folder_contents(folder, search_query)
    end
  end
end
