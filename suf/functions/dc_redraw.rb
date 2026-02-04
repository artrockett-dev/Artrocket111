
module SU_Furniture
  class RedrawComponents
		def initialize()
			@conv = DCConverter.new
			@dictionary_name = "dynamic_attributes"
      @forced_config_values = {}
			@entity_pointers = {}
			@formula_results = {}
			@formula_errors = {}
			@puts_errors = {}
			@color_list = []
			color_array = Sketchup::Color.names
			color_array.each { |color_name| @color_list.push color_name.downcase }
			@instance_attributes = Hash[
				"x", true,
				"y", true,
				"z", true,
				"rotx", true,
				"roty", true,
				"rotz", true,
				"copy", true,
				"copies", true,
				"_iscollapsed", true
      ]
			@default_sorts = Hash[
				# METADATA
				"name", 10,
				"summary", 20,
				"description", 30,
				"itemcode", 50,
				# SIZE AND POSITION
				"x", 70,
				"y", 80,
				"z", 90,
				"lenx", 100,
				"leny", 110,
				"lenz", 120,
				"rotx", 130,
				"roty", 140,
				"rotz", 150,
				# BEHAVIORS
				"material", 160,
				"scaletool", 175,
				"hidden", 180,
				"onclick", 190,
				"copies", 200,
				# FORM DESIGN
				"imageurl", 210,
				"dialogwidth", 230,
				"dialogheight", 240
      ]
			@count_of_entities = 0
			@instance_cache_prefix = '_inst_'
			@exception_array = []
			@without_array = ["x","y","z","rotx","roty","rotz","description","su_info"]
    end
    
		def translate(string_to_translate)
			$dc_strings.GetString(string_to_translate)
    end
    
		def redraw_entities_with_Progress_Bar(entities,run_all_formulas=false)
		  if entities && entities != []
			  DCProgressBar::clear()
				entities.each { |entity| redraw(entity) }
				DCProgressBar::clear()
      end
    end
    
		def redraw(entity,progress_bar_visible=true,att_arr=[],exc_arr=[])
      $dc_observers.get_latest_class.redraw(entity,progress_bar_visible)
    end #def
		
    def run_visible_attributes_formulas(entity)
      get_visible_attributes_with_formula(entity).keys.each { |attribute_name|
        $dc_observers.get_latest_class.run_formula(entity,attribute_name)
      }
    end
		
		def run_all_formulas(entity)
			get_attributes_with_formula(entity).keys.each { |attribute_name|
				$dc_observers.get_latest_class.run_formula(entity,attribute_name)
      }
    end
		
    def get_formula_result(entity,name)
      $dc_observers.get_latest_class.get_formula_result(entity,name)
    end
    
		def get_attribute_value(entity,name)
      $dc_observers.get_latest_class.get_attribute_value(entity,name)
    end
		
		def get_live_value(entity,name)
      $dc_observers.get_latest_class.get_live_value(entity,name)
    end
		
    def get_visible_attributes_with_formula(entity)
			list_with_formula = {}
			if entity.is_a?(Sketchup::ComponentInstance)
				attribute_entity = entity.definition
				else
				attribute_entity = entity
      end      
      if attribute_entity.attribute_dictionaries
        if attribute_entity.attribute_dictionaries[@dictionary_name]
          dictionary = attribute_entity.attribute_dictionaries[@dictionary_name]
          dictionary.keys.each { |key|
            if dictionary[key] && key[0..0] == '_' && key[0..@instance_cache_prefix.length-1] != @instance_cache_prefix
              formula_index = key.rindex(/_formula/)
              if formula_index == key.length-8 && dictionary[key].downcase =~ /setaccess/i
                source_key = key[1..formula_index-1]
                list_with_formula[source_key] = dictionary[key]
              end
            end
          }
        end
      end
      return list_with_formula
    end
    
		def get_attributes_with_formula(entity)
			list = {}
			list_with_formula = {}
			if entity.is_a?(Sketchup::ComponentInstance)
				attribute_entities = [entity,entity.definition]
				else
				attribute_entities = [entity]
      end
			attribute_entities.each { |attribute_entity|
				if attribute_entity.attribute_dictionaries
					if attribute_entity.attribute_dictionaries[@dictionary_name]
						dictionary = attribute_entity.attribute_dictionaries[@dictionary_name]
						dictionary.keys.each { |key|
							if dictionary[key] && key[0..0] == '_' && key[0..@instance_cache_prefix.length-1] != @instance_cache_prefix
								formula_index = key.rindex(/_formula/)
								if formula_index == key.length-8
									source_key = key[1..formula_index-1]
									list[source_key] = second_if_empty(@default_sorts[source_key], source_key)
									list_with_formula[source_key] = dictionary[key]
                end
              end
            }
          end
        end
      }
			return_list = {}
			nested_array = list.sort {|a,b|
				if a[1].to_i == a[1]
					a[1] = a[1].to_s.rjust(20,'0')
        end
				if b[1].to_i == b[1]
					b[1] = b[1].to_s.rjust(20,'0')
        end
				a[1].casecmp(b[1])
      }
			nested_array.each { |sub_array|
				return_list[sub_array[0]] = list_with_formula[sub_array[0]]
      }
			return return_list
    end
		
		def get_attribute_formula(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_formula')
    end
		
		def get_attribute_label(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_label')
    end
		
		def get_attribute_units(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_units')
    end
		
		def get_attribute_formlabel(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_formlabel')
    end
		
		def get_attribute_access(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_access')
    end
		
		def get_attribute_options(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_options')
    end
		
		def get_attribute_error(entity,name)
			return get_cascading_attribute(entity,'_'+name+'_error')
    end
		
		def get_attribute_formulaunits(entity, name, return_defaults = false)
			name = name.downcase
			formulaunits = get_cascading_attribute(entity, '_' + name + '_formulaunits')
			if !return_defaults
				return formulaunits
				elsif formulaunits
				return formulaunits
				elsif @conv.reserved_attribute_group[name]
				group = @conv.reserved_attribute_group[name]
				if group == 'LENGTH'
					length_units = get_entity_lengthunits(entity)
					if length_units
						return length_units
						else
						return 'INCHES'
          end
					else
					return @conv.groups_hash[group]['base']
        end
				else
				return 'STRING'
      end
    end
		
		def get_cascading_attribute(entity,name)
			name = name.downcase
			if entity.is_a?(Sketchup::ComponentInstance)
				value = entity.get_attribute(@dictionary_name, name)
				value = entity.definition.get_attribute @dictionary_name, name if !value
				return value
				elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::Model) ||
				entity.is_a?(Sketchup::ComponentDefinition)
				return entity.get_attribute(@dictionary_name, name)
				else
				return nil
      end
    end
		
		def get_entity_lengthunits(entity, use_default = false)
			length_units = get_attribute_value(entity,'_lengthunits')
			if !length_units && use_default
				if has_dc_attribute_dictionary(entity)
					length_units = "INCHES"
					else
					length_units = get_default_authoring_units()
        end
      end
			return length_units
    end
		
		def has_dc_attribute_dictionary(entity)
			if entity.attribute_dictionaries
				if entity.attribute_dictionaries[@dictionary_name]
					return true
        end
      end
			if entity.is_a?(Sketchup::ComponentInstance)
				if entity.definition.attribute_dictionaries
					if entity.definition.attribute_dictionaries[@dictionary_name]
						return true
          end
        end
      end
			return false
    end
		
		def get_default_authoring_units
			units = get_default_units
			if units == "FEET"
				units = "INCHES"
				elsif units != "INCHES" && units != "CENTIMETERS"
				units = "CENTIMETERS"
      end
			return units
    end
		
		def second_if_nan(val1,val2)
			if val1.to_s == "NaN"
				return val2
				else
				return val1
      end
    end
		
		def store_nominal_size(entity,target_lenx,target_leny,target_lenz)
			if entity.is_a?(Sketchup::Group)
				attribute_entity = entity
				else
				attribute_entity = entity.definition
      end
			attribute_entity.set_attribute @dictionary_name, '_lenx_nominal', target_lenx
			attribute_entity.set_attribute @dictionary_name, '_leny_nominal', target_leny
			attribute_entity.set_attribute @dictionary_name, '_lenz_nominal', target_lenz
    end
		
		def second_if_empty(val1,val2)
			if !val1
				return val2
				else
				return val1
      end
    end
		
		def set_attribute_error(entity,name,error)
			name = name.downcase
			metadata_entity = entity.definition
			delete_cascading_attribute(entity,'_'+name+'_error')
			metadata_entity.set_attribute @dictionary_name, '_'+name+'_error', error
    end
		
		def set_attribute(entity, name, value, formula=nil, label=nil, access=nil, options=nil, formlabel=nil, units=nil, error=nil, formulaunits=nil, name_prefix='', can_delete_formlabel=false)
			name = name.downcase
			metadata_entity = entity.definition
			if !entity.is_a?(Sketchup::ComponentDefinition)
				if get_live_value(entity,name)
					value = second_if_empty(value,get_attribute_value(entity,name))
        end
      end
			delete_cascading_attribute(entity,name)
			metadata_entity.set_attribute @dictionary_name, name_prefix + name, value
			entity.set_attribute @dictionary_name, name_prefix + name, value
			if formula == 'ERASEFORMULA'
				delete_cascading_attribute(entity,'_'+name+'_formula')
				delete_cascading_attribute(entity,'_'+name+'_error')
				elsif formula
				delete_cascading_attribute(entity,'_'+name+'_formula')
				delete_cascading_attribute(entity,'_'+name+'_error')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_formula', formula
      end
			
			if label
				delete_cascading_attribute(entity,'_'+name+'_label')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_label', label
      end
			if access
				delete_cascading_attribute(entity,'_'+name+'_access')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_access', access
      end
			if options
				delete_cascading_attribute(entity,'_'+name+'_options')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_options', options
      end
			
			if formlabel
				delete_cascading_attribute(entity,'_'+name+'_formlabel')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_formlabel', formlabel
				elsif can_delete_formlabel
				delete_cascading_attribute(entity,'_'+name+'_formlabel')
      end
			
			if units
				delete_cascading_attribute(entity,'_'+name+'_units')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_units', units
      end
			if error
				delete_cascading_attribute(entity,'_'+name+'_error')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_error', error
      end
			if formulaunits == 'DEFAULT'
				delete_cascading_attribute(entity,'_'+name+'_formulaunits')
				elsif formulaunits
				delete_cascading_attribute(entity,'_'+name+'_formulaunits')
				metadata_entity.set_attribute @dictionary_name, name_prefix +
				'_'+name+'_formulaunits', formulaunits
      end
    end
		
		def delete_cascading_attribute(entity,name)
			name = name.downcase
			entity.delete_attribute(@dictionary_name, name)
			if entity.is_a?(Sketchup::ComponentInstance)
				entity.definition.delete_attribute(@dictionary_name, name)
      end
    end
		
		def fix_float(f)
			return ((f.to_f*10000000.0).round/10000000.0)
    end
		
		def chop_quotes(reference)
			if (reference[0..0] == '"') &&
				(reference[reference.length-1..reference.length-1] == '"')
				return reference[1..reference.length-2]
				else
				return reference
      end
    end
		
		def make_unique_if_needed(instance)
			if instance.is_a?(Sketchup::ComponentInstance)
				if instance.definition.count_instances > 1
					if children_have_behaviors(instance)
						instance.make_unique
						instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if instance.parent.is_a?(Sketchup::ComponentDefinition)
          end
        end
      end
    end
		
		def copy_number_of(entity)
			if entity.name =~ /copy \d+$/
				copy = entity.name[entity.name.index("copy ")+5..999].to_f
				return copy
				else
				return 0.0
      end
    end
		
		def name_of_copy(base_name,copy_number)
			return base_name.to_s + " copy " + copy_number.to_i.to_s.rjust(3,'0')
    end
		
		def refresh_thumbnails(entity)
			if entity.is_a?(Sketchup::ComponentInstance)
				entity.definition.refresh_thumbnail
				refresh_thumbnails(entity.parent)
				elsif entity.is_a?(Sketchup::ComponentDefinition)
				entity.refresh_thumbnail
				entity.instances.each { |instance|
					refresh_thumbnails(instance.parent)
        }
				elsif entity.is_a?(Sketchup::Group)
				refresh_thumbnails(entity.parent)
      end
    end
		
		def update_last_sizes(entity)
			parent = entity.parent
			if parent
				if has_dc_attribute_dictionary(parent)
					if parent.is_a?(Sketchup::ComponentDefinition)
						parent.invalidate_bounds
						parent.instances.each {|instance|
							lenx,leny,lenz = instance.scaled_size
							instance.set_last_size(lenx, leny, lenz)
							update_last_sizes(instance)
            }
						elsif parent.is_a?(Sketchup::Group)
						lenx,leny,lenz = parent.scaled_size
						parent.set_last_size(lenx, leny, lenz)
						update_last_sizes(parent)
          end
        end
      end
    end
		
		def set_attribute_formula(entity,name,formula)
			name = name.downcase
			if @instance_attributes[name] || entity.is_a?(Sketchup::Group)
				metadata_entity = entity
				else
				metadata_entity = entity.definition
      end
			delete_cascading_attribute(entity,'_'+name+'_formula')
			delete_cascading_attribute(entity,'_'+name+'_error')
			metadata_entity.set_attribute @dictionary_name, '_'+name+'_formula', formula
    end
		
		def clear_instance_cache(entity, start_operation = true)
			if start_operation
				Sketchup.active_model.start_operation translate('Save As'), true, false, true
      end
			if entity.is_a?(Sketchup::ComponentInstance)
				get_instance_cache_list(entity).each { |name|
					entity.definition.delete_attribute @dictionary_name, name
        }
      end
			if start_operation
				Sketchup.active_model.commit_operation
      end
    end
		
		def get_instance_cache_list(entity)
			list = []
			if entity.is_a?(Sketchup::ComponentInstance)
				attribute_entity = entity.definition
				if attribute_entity.attribute_dictionaries
					if attribute_entity.attribute_dictionaries[@dictionary_name]
						dictionary = attribute_entity.attribute_dictionaries[@dictionary_name]
						dictionary.keys.each { |key|
							if key[0..@instance_cache_prefix.length-1] == @instance_cache_prefix
								list.push key
              end
            }
          end
        end
      end
			return list
    end
		
  end # class
	
end # module
