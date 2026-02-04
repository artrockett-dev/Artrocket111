
module SU_Furniture
  class ListsEasyKitchen
    def EasyKitchen(entity)
      su_type = ""
      su_info = nil
      item_code = entity.definition.get_attribute("dynamic_attributes", "itemcode", "0")
      su_info,su_type = EasyKitchen_entities(item_code) if item_code != "0" && !item_code.include?("Версия")
      return su_info,su_type if su_info
    end#def
    def EasyKitchen_entities(item_code)
      unit = "кв.м"
      item_code_array = item_code.split("/")
      name = item_code_array[2]
      material_name = item_code_array[3]
      count = item_code_array[4]
      item_code_array[5] ? width = item_code_array[5] : width = ""
      name = name+" "+width.gsub(",",".").to_s if item_code_array[1] && item_code_array[1].include?("Фурнитура")
      item_code_array[6].to_f ? height = item_code_array[6].to_f : height = ""
      item_code_array[7] ? thickness = item_code_array[7] : thickness = ""
      su_type = item_code_array[1]
      return nil,su_type if !su_type
      su_type = "frontal" if su_type.include?("МДФ")
      su_type = "carcass" if su_type.include?("ЛДСП")
      su_type = "back" if su_type.include?("ХДФ")
      su_type = "glass" if su_type.include?("Стекло")
      if su_type.include?("Фурнитура") then su_type = "furniture"; unit = "шт" end
      if su_type.include?("Столешница") then su_type = "worktop"; unit = "м" end
      if su_type.include?("Скинали") then su_type = "fartuk"; unit = "м" end
      if su_type.include?("Погонаж") && item_code_array[0].include?("Подсветка") then su_type = "furniture"; unit = "м"; count = item_code_array[5].to_f/1000 end
      su_type = "hidden_handle" if su_type.include?("Погонаж") && item_code_array[0].include?("GOLA")
      su_type = "skirting" if su_type.include?("Погонаж") && item_code_array[2].include?("Бортик")
      su_type = "plinth" if su_type.include?("Погонаж") && item_code_array[2].include?("Плинтус")
      if su_type.include?("Погонаж") || su_type.include?("hidden_handle")
        su_type = "profil"
        if item_code_array[2].include?("Боковой") || item_code_array[2].downcase.include?("вертикальный") && item_code_array[0].include?("Двери-купе")
          item_code_array[5].to_f/1000 > 2.65 ? count = 1 : count = 0.5
          unit = "шт"
          else
          count = item_code_array[5].to_f/1000
          unit = "м"
        end
      end
      if item_code.include?("ХДФ") || item_code.include?("Стекло")
        z1 = "0"
        z2 = "0"
        y1 = "0"
        y2 = "0"
        else
        item_code_array[8] ? z1 = item_code_array[8] : z1 = "0"
        item_code_array[9] ? z2 = item_code_array[9] : z2 = "0"
        item_code_array[10] ? y1 = item_code_array[10] : y1 = "0"
        item_code_array[11] ? y2 = item_code_array[11] : y2 = "0"
        width = width.to_f + y1.to_f + y2.to_f
        height = height.to_f + z1.to_f + z2.to_f
      end
      su_info = "/"+name+"//"+width.to_f.round(0).to_s+"/"+height.to_f.round(0).to_s+"/"+thickness+"//"+material_name+"/"+count.to_s+"/"+count.to_s+"/"+unit+"/"+z1+"/0/"+z2+"/0/"+y1+"/0/"+y2+"/0"
      return su_info,su_type
    end#def
  end #end Class
end #module
