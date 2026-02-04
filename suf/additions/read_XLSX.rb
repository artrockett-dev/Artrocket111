module SU_Furniture
	class ReadXLSX
		def unzip_file(file,destination)
			begin
				SU_Furniture::Zip::ZipFile.open(file) do |zip_file|
					zip_file.each do |f|
						if !File.file?(File.join(destination,f.name.force_encoding("UTF-8")))
							f_path = File.join(destination,f.name)
							FileUtils.mkdir_p(File.dirname(f_path))
							f.extract(f_path)
						end
					end
				end
				return true
				rescue Exception => e
				p e
				return false
			end
		end#def
		def shared_strings_array(file_name,path)
		  strings_array = []
		  result = unzip_file(file_name,path)
			return strings_array if !result
			worksheet_path = File.join(File.join(path,'xl','sharedStrings.xml'))
			xml_file = File.new(worksheet_path,"r")
			content = xml_file.readlines
			xml_file.close
			materials = Report_lists.xml_value(content.join("").strip,"<sst","</sst>")
			if materials != ""
				material_array = Report_lists.xml_array(materials,"<si","</si>")
				material_array.each_with_index{|material,index|
				strings_array << Report_lists.xml_value(material,"<t>","</t>")
			}
		end
		#strings_array.each_with_index {|cont,index| p "#{index} : #{cont}"}
		return strings_array
		end#def
		def worksheets_hash(path,worksheets_path,strings_array,columns)
			worksheets_content_hash = {}
			full_path = Dir.glob(worksheets_path).find_all { |l| File.extname(l)[/(xml)/i] }
			worksheets_folders = full_path.find_all { |i| i.split(/[\/]/) }
			worksheets_folders = worksheets_folders.map { |f| f=File.basename(f,File.extname(f)) }
			worksheets_folders.each { |worksheet_folder|
				cell_hash = {}
				worksheet_path = File.join(path,'xl','worksheets',worksheet_folder+'.xml')
				xml_file = File.new(worksheet_path,"r")
				content = xml_file.readlines
				xml_file.close
				materials = Report_lists.xml_value(content.join("").strip.tr("\r",""),"<sheetData","</sheetData>")
				if materials != ""
					material_array = Report_lists.xml_array(materials,"<row","</row>")
					material_array.each_with_index{|material,index|
						material_columns = Report_lists.xml_array(material,"<c","</c>")
						filtered_array = []
						columns.each {|index| filtered_array << material_columns[index] if material_columns[index]}
						row_content = []
						first_value = ""
						filtered_array.each{|cont|
							if cont.include?('t="s"')
								value = strings_array[Report_lists.xml_value(cont,"<v>","</v>").to_i]
								else
								value = Report_lists.xml_value(cont,"<v>","</v>")
							end
							first_value = value if first_value == ""
							row_content << value
						}
						cell_hash[first_value] = row_content
					}
				end
				worksheets_content_hash[worksheet_folder] = cell_hash
			}
			return worksheets_content_hash
		end#def
		def read_file(file_name,columns)
		  base_name = File.basename(file_name,File.extname(file_name))
		  path = File.join(File.dirname(file_name),"document_"+base_name)
			worksheets_path = File.join(path,'xl','worksheets',"*")
			strings_array = shared_strings_array(file_name,path)
		  worksheets_content_hash = worksheets_hash(path,worksheets_path,strings_array,columns)
		  FileUtils.rm_rf(Dir.glob(path))
			return worksheets_content_hash
		end#def
	end
end
