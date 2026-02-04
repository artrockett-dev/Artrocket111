
module SU_Furniture
  
  class ListsSDCF #*****************************************************************
    
    def sdcf_info(entity)
      su_info = nil
      su_type = nil
      aaa_info = entity.definition.get_attribute("dynamic_attributes", "aaa_info", "0")
      if !entity.hidden? && aaa_info != "0" && aaa_info != " " && aaa_info != ""
        aaa_info_array = aaa_info.split(",")
        name = aaa_info_array[0].gsub('"','')
        width = aaa_info_array[1].gsub('"','')
        height = aaa_info_array[2].gsub('"','')
        thickness = aaa_info_array[3].gsub('"','')
        material_name = aaa_info_array[5].gsub('"','')
        z1_texture = material_name
        z2_texture = material_name
        y1_texture = material_name
        y2_texture = material_name
        rotate = aaa_info_array[6].gsub(' ','')
        count = aaa_info_array[8].gsub('"','')
        unit = aaa_info_array[9].gsub('"','')
        if aaa_info.include?("Фасад") || aaa_info.include?("Материал")
          su_type = aaa_info.split(",")[7].gsub('"','')
          su_type = "frontal" if su_type.include?("Фасад")
          su_type = "carcass" if su_type.include?("Материал")
          su_type = "back" if su_type.include?("ХДФ")
          su_type = "glass" if su_type.include?("Стекло")
          su_type = "furniture" if su_type.include?("Фурнитура")
          xx_lenz = entity.definition.get_attribute("dynamic_attributes", "xx_lenz").to_mm.round(0).to_s
          xx_leny = entity.definition.get_attribute("dynamic_attributes", "xx_leny").to_mm.round(0).to_s
          if aaa_info.include?("ХДФ") || aaa_info.include?("Стекло")
            z1 = "0"
            z2 = "0"
            y1 = "0"
            y2 = "0"
            else
            z1_name = aaa_info.split(",")[14].gsub('"','')
            z1 = z1_name
            z1 = z1_name[0..z1_name.index("_")-1] if z1_name.index("_") != nil
            z1_texture = z1_name[z1_name.index("_")+1..z1_name.length-1] if z1_name.index("_") != nil
            z2_name = aaa_info.split(",")[16].gsub('"','')
            z2 = z2_name
            z2 = z2_name[0..z2_name.index("_")-1] if z2_name.index("_") != nil
            z2_texture = z2_name[z2_name.index("_")+1..z2_name.length-1] if z2_name.index("_") != nil
            y1_name = aaa_info.split(",")[10].gsub('"','')
            y1 = y1_name
            y1 = y1_name[0..y1_name.index("_")-1] if y1_name.index("_") != nil
            y1_texture = y1_name[y1_name.index("_")+1..y1_name.length-1] if y1_name.index("_") != nil
            y2_name = aaa_info.split(",")[12].gsub('"','')
            y2 = y2_name
            y2 = y2_name[0..y2_name.index("_")-1] if y2_name.index("_") != nil
            y2_texture = y2_name[y2_name.index("_")+1..y2_name.length-1] if y2_name.index("_") != nil
          end
          su_info = "/"+name+"/"+su_type+"/"+width+"/"+height+"/"+thickness+"//"+material_name+"/"+"1"+"/"+count+"/кв.м/"+z1+"/"+z1_texture+"/"+z2+"/"+z2_texture+"/"+y1+"/"+y1_texture+"/"+y2+"/"+y2_texture
          elsif aaa_info.include?("Фурнитура")
          su_type = "furniture"
          su_info = "/"+name+"/"+su_type+"/"+width+"/"+height+"/"+thickness+"//"+material_name+"/"+"1"+"/"+count+"/шт/"+"0"+"//"+"0"+"//"+"0"+"//"+"0"
        end
      end
      return su_info,su_type
    end#def
    
  end #end Class 
  
end #module
