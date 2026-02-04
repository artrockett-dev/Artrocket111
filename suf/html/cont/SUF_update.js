var comp_list_for_load = [];
var path_list_for_load = [];
var path_all_images = {};
var path_new_images = {};
var select_path_images = [];
var main_tab = '';
function get_comp_list(s){
    let comp_array = s[0];
    let mat_array = s[1];
	let telegram_comp_array = s[2];
    let tab_array = ["Components","Materials","Telegram"];
    let level = 1;
    $( "<div/>", { "id": "tabs"+level, "class": "tabs" }).appendTo("body");
    let content = '';
    for (let i=0; i<tab_array.length; i++) {
        content += '<input type="radio" level="'+level+'" name="tab-btn1" class="tab-btn1" main_tab="'+tab_array[i]+'" id="tab-btn-'+level+(i+1)+'" value=""><label for="tab-btn-'+level+(i+1)+'">'+tab_array[i]+'</label>';
	}
    for (let i=0; i<tab_array.length; i++) {
        content += '<div class="content-'+level+'" id="content-'+level+(i+1)+'"></div>';
	}
    $(content).appendTo("#tabs"+level);
    
    let tab_hash = {};
    let child_tab_array = [];
    for (let i=0; i<comp_array.length; i++) {
        var param_array = comp_array[i].split("<=>");
        let tab_name = param_array[0];
        if (child_tab_array.indexOf(tab_name.split("/")[0])==-1){child_tab_array.push(tab_name.split("/")[0])}
        if (tab_hash[tab_name]) { tab_hash[tab_name].push(param_array[1]+"<=>"+param_array[2]+"<=>"+param_array[3]+"<=>"+param_array[4]+"<=>"+param_array[5]) }
        else { tab_hash[tab_name] = [param_array[1]+"<=>"+param_array[2]+"<=>"+param_array[3]+"<=>"+param_array[4]+"<=>"+param_array[5]] }
        
	}
    append_tabs(level+1,child_tab_array,level+"1",tab_hash);
	
	tab_hash = {};
    child_tab_array = [];
    for (let i=0; i<telegram_comp_array.length; i++) {
        var param_array = telegram_comp_array[i].split("<=>");
        let tab_name = param_array[0];
        if (child_tab_array.indexOf(tab_name.split("/")[0])==-1){child_tab_array.push(tab_name.split("/")[0])}
        if (tab_hash[tab_name]) { tab_hash[tab_name].push(param_array[1]+"<=>"+param_array[2]+"<=>"+param_array[3]+"<=>"+param_array[4]+"<=>"+param_array[5]) }
        else { tab_hash[tab_name] = [param_array[1]+"<=>"+param_array[2]+"<=>"+param_array[3]+"<=>"+param_array[4]+"<=>"+param_array[5]] }
        
	}
    append_tabs(level+3,child_tab_array,level+"3",tab_hash);
    
    tab_hash = {};
    for (let i=0; i<mat_array.length; i++) {
        var param_array = mat_array[i].split("<=>");
        let tab_name = param_array[0];
        if (tab_hash[tab_name]) { tab_hash[tab_name].push(param_array[1]+"<=>"+param_array[2]) }
        else { tab_hash[tab_name] = [param_array[1]+"<=>"+param_array[2]] }
	}
    
    var images = [];
    Object.keys(tab_hash).forEach(function (key) {
        images.push('<div class="materials" id="'+key+'"><img src="cont/style/images_folder.png" title="'+key+'">'+key+'</div>' );
	});
    $("<div/>",{"id": "materials-wrap", html: images.join("")}).appendTo("#content-"+level+2);
    
    
    let footer_content = '';
    footer_content += '<input type="submit" id="update_select" class="footer_button" value="Обновить выбранные" onclick="update_select();" disabled="true" >';
    footer_content += '<input type="submit" id="update_select_path" class="footer_button" value="Обновить новые из текущей папки" onclick="update_select_path();" disabled="true">';
    footer_content += '<input type="submit" id="update_all_library" class="footer_button" value="Обновить всю библиотеку" onclick="update_all_library();" disabled="true">';
    footer_content += '<input type="submit" id="place_component" class="footer_button" value="Поместить выбранный компонент в сцену" onclick="place_component();" disabled="true">';
	footer_content += '<input type="submit" id="place_telegram_component" class="footer_button" value="Поместить выбранный компонент в сцену" onclick="place_telegram_component();" disabled="true">';
	footer_content += '<input type="submit" id="save_telegram_model" class="footer_button" value="Сохранить модель" onclick="save_telegram_model();" disabled="true">';
    $( "<div/>", { "id": "footer", html: footer_content }).appendTo("body")
	$('#progress-bar').css("display",'none');
	$('#update_all_library').css("display",'none');
	$('#update_select').css("display",'none');
	$('#update_select_path').css("display",'none');
	$('#place_component').css("display",'none');
	$('#place_telegram_component').css("display",'none');
	$('#save_telegram_model').css("display",'none');
}
function append_tabs(level,tab_array,parent_div,tab_hash) {
    $( "<div/>", { "id": "tabs"+parent_div, "class": "tabs" }).appendTo('#content-'+parent_div);
    for (let i=0; i<tab_array.length; i++) {
        let content = '<input type="radio" level="'+level+'" name="tab-btn2" class="tab-btn2" id="tab-btn-'+level+(i+1)+'" value=""><label for="tab-btn-'+level+(i+1)+'">'+tab_array[i]+'</label>';
        $(content).appendTo("#tabs"+parent_div);
	}
    for (let i=0; i<tab_array.length; i++) {
        content = '<div class="content-'+level+'" id="content-'+level+(i+1)+'"></div>';
        $(content).appendTo("#tabs"+parent_div);
        path_name_id = append_images(tab_array[i],"#content-"+level+(i+1),tab_hash);
        path_all_images["#content-"+level+(i+1)] = path_name_id[0];
        path_new_images["#content-"+level+(i+1)] = path_name_id[1];
	}
}
function append_images(tab_name,parent_div,tab_hash) {
    var images = [];
    var path_name_id = [];
    var new_images = [];
    Object.keys(tab_hash).forEach(function (key) {
        if (key.indexOf(tab_name) != -1) {
            let img_array = tab_hash[key];
            for (let j=0; j<img_array.length; j++) {
			    let array = img_array[j].split("<=>");
                let name = array[0];
                let id = array[1];
				let src = array[2];
				let date = array[3];
                let label = array[4];
				images.push('<div class="components '+(label ? label : "")+'"  id="'+key+'/'+name+'" skp="'+key+"<=>"+name+"<=>"+id+'"><img src="'+src+'" title="'+key+'/'+name.replace(/\.[^/.]+$/, "")+(label=="kl" ? "\nДоступно при покупке кухонной библиотеки.\nНажмите для перехода на сайт." : "")+(label=="newer" ? "\nДоступна новая версия." : "")+(label=="new" ? "\nНовый компонент." : "")+'">'+name.replace(/\.[^/.]+$/, "")+'</div>' );
                path_name_id.push(key+"<=>"+name+"<=>"+id);
                if (label) { new_images.push(key+"<=>"+name+"<=>"+id); }
			}
		}
	})
    $("<div/>",{"id": "components-wrap", html: images.join("")}).appendTo(parent_div);
    return [path_name_id,new_images];
}
$(document).on( "click", ".tab-btn1", function() {
    window.scrollTo(0, 0);
	let id = $(this).prop('id');
	let content = "content-"+id.split("-")[2]; // кнопка верхняя
	$(".content-1").each(function() {
	    if (content == $(this).prop('id')) { $(this).css("display","block"); }
		else { $(this).css("display","none"); }
	});
	$(".tab-btn2").each(function() {
		let this_id = $(this).prop('id');
		if (+this_id[this_id.length - 2] != +content[content.length - 1]+1) {
			$(this).prop("checked", false);
			comp_list_for_load = [];
	        path_list_for_load = [];
		}
	});
	
	document.getElementById('update_select').disabled = true;
	document.getElementById('place_component').disabled = true;
	document.getElementById('place_telegram_component').disabled = true;
	document.getElementById('save_telegram_model').disabled = true;
    main_tab = $(this).attr('main_tab');
    if (main_tab=="Materials") {
	    $('#update_all_library').css("display",'inline-block');
		$('#update_select').css("display",'inline-block');
        $('#update_all_library').val('Загрузить и обновить всю библиотеку с текстурами');
        $('#update_select').val('Загрузить и обновить выбранные папки с текстурами');
        $('#update_select_path').css("display",'none');
        $('#place_component').css("display",'none');
		$('#place_telegram_component').css("display",'none');
		$('#save_telegram_model').css("display",'none');
        $(".components").each(function() { $(this).removeClass("active");});
        document.getElementById('update_all_library').disabled = false;
		$(".content-2").each(function() { $(this).css("display","none"); });
		$(".content-4").each(function() { $(this).css("display","none"); });
        } else if (main_tab=="Components") {
		$('#update_all_library').css("display",'inline-block');
		$('#update_select').css("display",'inline-block');
        $('#update_all_library').val('Обновить все новые компоненты');
        $('#update_select').val('Обновить выбранные компоненты');
        $('#update_select_path').css("display",'inline-block');
        $('#place_component').css("display",'inline-block');
		$('#place_telegram_component').css("display",'none');
		$('#save_telegram_model').css("display",'none');
        $(".materials").each(function() { $(this).removeClass("active");});
        let all_components = [];
        Object.keys(path_new_images).forEach(function (key) {
            all_components = all_components.concat(path_new_images[key]);
		})
        if (all_components == 0) { document.getElementById('update_all_library').disabled = true; }
        else { document.getElementById('update_all_library').disabled = false; }
		$(".content-4").each(function() { $(this).css("display","none"); });
		} else if (main_tab=="Telegram") {
		$('#update_all_library').css("display",'none');
		$('#update_select').css("display",'none');
		$('#update_select_path').css("display",'none');
		$('#place_component').css("display",'none');
		$('#place_telegram_component').css("display",'inline-block');
		$('#save_telegram_model').css("display",'inline-block');
		$(".materials").each(function() { $(this).removeClass("active");});
		$(".components").each(function() { $(this).removeClass("active");});
		$(".content-2").each(function() { $(this).css("display","none"); });
	}
});
$(document).on( "click", ".tab-btn2", function() {
    window.scrollTo(0, 0);
    $(".content-2").each(function() { $(this).css("display","none"); });
	$(".content-4").each(function() { $(this).css("display","none"); });
    let content = "#content-"+$(this).prop('id').split("-")[2];
    $(content).css("display", "block");
    select_path_images = path_new_images[content];
	if (select_path_images.length == 0) { document.getElementById('update_select_path').disabled = true; }
	else { document.getElementById('update_select_path').disabled = false; }
});
$(document).on( "click", ".components", function() {
    let this_component = this;
    if ($(this_component).hasClass("kl")) {sketchup.open_site();}
    else {
        let component = $(this_component).attr('skp');
        if ($(this_component).hasClass("active")) { $(this_component).removeClass("active"); comp_list_for_load = comp_list_for_load.filter(function(f) { return f !== component })}
        else {$(this_component).addClass("active"); comp_list_for_load.push(component);}
        if (comp_list_for_load.length == 0) {
            document.getElementById('update_select').disabled = true;
            document.getElementById('place_component').disabled = true;
			document.getElementById('place_telegram_component').disabled = true;
			document.getElementById('save_telegram_model').disabled = true;
		}
        else {
            document.getElementById('update_select').disabled = false;
            if (comp_list_for_load.length == 1) {
				document.getElementById('place_component').disabled = false;
				document.getElementById('place_telegram_component').disabled = false;
				document.getElementById('save_telegram_model').disabled = false;
				} else {
				document.getElementById('place_component').disabled = true;
				document.getElementById('place_telegram_component').disabled = true;
				document.getElementById('save_telegram_model').disabled = true;
			}
		}
	}
});
function update_select(){
    if (main_tab=="Components") { sketchup.update_components(comp_list_for_load); }
    else { sketchup.update_materials(path_list_for_load); }
    comp_list_for_load = [];
    path_list_for_load = [];
}
function update_select_path(){
    sketchup.update_components(select_path_images);
}
function update_all_library(){
    let all_components = [];
    Object.keys(path_new_images).forEach(function (key) {
        all_components = all_components.concat(path_new_images[key]);
	})
    sketchup.update_components(all_components);
}
function place_component(){
    sketchup.place_component(comp_list_for_load);
}
function place_telegram_component(){
    sketchup.place_telegram_component(comp_list_for_load);
}
function save_telegram_model(){
    sketchup.save_telegram_model(comp_list_for_load);
}
$(document).on( "click", ".materials", function() {
    let this_path = this;
    let path = $(this_path).attr('id');
    if ($(this_path).hasClass("active")) { $(this_path).removeClass("active"); path_list_for_load = path_list_for_load.filter(function(f) { return f !== path })}
    else {$(this_path).addClass("active"); path_list_for_load.push(path);}
    if (path_list_for_load.length == 0) {
        document.getElementById('update_select').disabled = true;
        document.getElementById('place_component').disabled = true;
	}
    else {
        document.getElementById('update_select').disabled = false;
        if (path_list_for_load.length == 1) { document.getElementById('place_component').disabled = false; }
        else { document.getElementById('place_component').disabled = true; }
	}
    console.log(path_list_for_load)
});
function loaded(name){
    document.getElementById(name).classList.remove("active");
    document.getElementById(name).classList.remove("new");
    document.getElementById(name).classList.remove("newer");
    document.getElementById('update_select').disabled = true;
    document.getElementById('place_component').disabled = true;
	document.getElementById('place_telegram_component').disabled = true;
	document.getElementById('save_telegram_model').disabled = true;
    comp_list_for_load = [];
    path_list_for_load = [];
}
function loaded_all_mat(){
    alert("Textures have been updated")
}
function showBar(){
	document.getElementById('progress-bar').style.display = "block";
	document.getElementById('progress-fill').style.width = "0%";
	document.getElementById('progress-text').innerText = "Ожидание загрузки...";
}
function updateProgress(message) {
	document.getElementById('progress-text').innerText = message;
	const bar = document.getElementById('progress-fill');
	let width = 0;
	const interval = setInterval(() => {
		width += 5;
		bar.style.width = `${width}%`;
		if (width >= 90) clearInterval(interval);
	}, 300);
}
function completeProgress(message) {
	document.getElementById('progress-fill').style.width = "100%";
	document.getElementById('progress-text').innerText = message;
}
function showStatus(message) {
	document.getElementById('progress-fill').style.width = "100%";
	document.getElementById('progress-text').innerText = message;
	const interval = setTimeout (() => {
		document.getElementById('progress-bar').style.display = "none";
	}, 5000);
}
