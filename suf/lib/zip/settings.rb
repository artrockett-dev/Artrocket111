module SU_Furniture
	module Zip
		class << self
			def options
				@options ||= {
					:on_exist_proc => false,
					:continue_on_exist_proc => false
				}
			end
		end
	end
end
