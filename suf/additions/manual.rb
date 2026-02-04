module SU_Furniture
  class ManualBrowser
    def manual_dialog
		  UI.openURL(File.join(TEMP_PATH, 'SUF', 'manual.pdf'))
		end #def
	end # class ManualBrowser
end # module SU_Furniture
