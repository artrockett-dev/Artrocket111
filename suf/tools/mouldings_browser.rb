module SU_Furniture
  module ComponentBrowser
    extend self
    def make_browser
      @model = Sketchup.active_model
      head = <<-HEAD
        <html><head>
        <meta charset="utf-8">
        <title>Drop Comps</title>
        <style>
        body { font:caption; margin:1mm; color: #696969; background-color: #383838; padding: 3px; }
        button{ text-align: left; width:180px; height:150px; cursor:pointer; background-color: transparent; border: 1px solid #ebe0e0;}
        img { width:162px; height:144px; border: 0; top:4px; }
        .container div { position: relative; background-color: transparent; width: 160px; height: 50px; bottom: 20px; padding: 3px; }
        #selected_moulding { display: none; }
        </style>
        </head>
        <body>
      HEAD
      body = ''
      dir = PATH_COMP+"/Профили"
      dir_arr = Dir.new(PATH_COMP+"/Профили").entries
      dir_arr.map! { |d| d = d.encode("utf-8") }
      skps = dir_arr.reject { |s| s unless s =~ /\.skp/ }
      return if skps.count == 0
      skps.each { |name|
        basename = name.sub('.skp', '')
        img_name = basename + '.png'
        skp = File.join(dir, name)
        img = File.join(dir, img_name)
        Sketchup.save_thumbnail(skp, img)
        col = 'inherit'
        body << %(
        <div class="container">
        <button style="background-color: #{col};" onclick="importSkp('#{basename.encode("utf-8")}');" >
        <img src="#{img.encode("utf-8")}" ><div>#{basename}</div></button></div>
        )
      }
      body << %( <input type="text" id="selected_moulding" value=''> )
      tail = <<-TAIL
        <script>
        function importSkp(name) {
        document.getElementById("selected_moulding").value=name;
        window.location='skp:import_skp@'+name; }
        </script>
        </body></html>
      TAIL
      html = head + body + tail
      @dlg.close if @dlg && (@dlg.visible?)
      @dlg = UI::WebDialog.new(File.basename(dir), true, false, 210, 600, 50, 112, true)
      
      @dlg.add_action_callback('import_skp') { |web_dialog,action_name|
        Draw_mouldings.comp_name(web_dialog.get_element_value("selected_moulding"))
        @dlg.close
        Sketchup.active_model.select_tool( Draw_mouldings ) 
      }
      @dlg.set_html(html)
      OSX ? @dlg.show() : @dlg.show_modal()
    end
  end
end#end Module
