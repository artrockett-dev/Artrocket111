document.addEventListener('DOMContentLoaded', function() {
    sketchup.get_data("read_param");
}, false);
window.onerror = function(message, url, lineNumber) {
    alert("Ошибка: " + message + "\n(" + url.split("/")[url.split("/").length - 1] + ": " + lineNumber + ")");
};
var fixHelper = function(e, ui) {
	ui.children().each(function() { $(this).width($(this).width()); });
	return ui;
};
var fastener_name_list_array = [];
var template_list_array = [];
var hinge_name_list_array = [];
var drawer_name_list_array = [];
var accessories_name_list_array = [];
var groove_name_list_array = [];
var fastener_hash = {};
var template_hash = {};
var template_value_array = {};
var hinge_hash = {};
var drawer_hash = {};
var accessories_hash = {};
var groove_hash = {};
var lists_array = [];
var texts_array = [];
var worktop_array = [];
var fartuk_array = [];
var frontal_array = [];
var freza_array = [];
var component_array = [];
var material_array = [];
var lists_name_array = [];
var all_parameters = "";
var active_fastener = "";
var active_hinge_type = "";
var active_hinge_producer = "";
var active_hinge_name = "";
var active_drawer = "";
var active_drawer_depth = "";
var active_accessories = "";
var active_groove = "";
var plugin_version = "4";
var deadline = "0";
var deaddate = new Date();
var thickness = 16;
var clipboard_text = "";
function fasteners_parameters(s) {
    fastener_hash = {};
    for (let i = 0; i < s.length; i++) {
        fastener_param = {};
        param = s[i].split(",");
        for (let j = 0; j < param.length; j++) {
            fastener_param[param[j].split("=>")[0]] = param[j].split("=>")[1];
		}
        fastener_hash[param[0].split("=>")[1]] = fastener_param;
	}
    //console.log(fastener_hash)
}
function template_parameters(s) {
    template_hash = {};
    for (let i = 0; i < s.length; i++) {
        template_hash[s[i].split("=")[1]] = s[i];
		if (template_list_array.indexOf(s[i].split("=")[1]) == -1) {
            template_list_array = template_list_array.concat(s[i].split("=")[1]);
		}
	}
    //console.log(template_hash)
	//console.log(template_list_array)
}
function hole_map(map,hole_param) {
    if (hole_param) {
        hole_parameters = hole_param.split("&");
        for (let k = 0; k <= hole_parameters.length; k++) {
            if ((hole_parameters[k]) && (hole_parameters[k])!="") {
                map["axis"+(k+1)] = hole_parameters[k].split(";")[0];
                map["diam"+(k+1)] = hole_parameters[k].split(";")[1];
                map["depth"+(k+1)] = hole_parameters[k].split(";")[2];
                map["x"+(k+1)] = hole_parameters[k].split(";")[3];
                map["y"+(k+1)] = hole_parameters[k].split(";")[4];
                map["z"+(k+1)] = hole_parameters[k].split(";")[5];
                map["multiple"+(k+1)] = hole_parameters[k].split(";")[6];
                map["multiple_dist"+(k+1)] = hole_parameters[k].split(";")[7];
                map["list_name"+(k+1)] = hole_parameters[k].split(";")[8];
                map["color"+(k+1)] = hole_parameters[k].split(";")[9];
			}
		}
	}
    return map;
}
function hinge_parameters(s) {
    hinge_hash = {};
    for (let i = 0; i < s.length; i++) {
        hinge_param = {};
        param = s[i].split("<=>");
        for (let j = 1; j < param.length; j++) {
            let producer = param[j].split("=")[0];
            let hinge_list = slice_into_chunks(param[j].split("=").slice(1),2);
            let hinge_name_hash = {};
            for (let k = 0; k < hinge_list.length; k++) {
                holes = {};
                holes["name"] = hinge_list[k][0];
                holes = hole_map(holes,hinge_list[k][1]);
                hinge_name_hash[hinge_list[k][0]] = holes;
			}
            hinge_param[producer] = hinge_name_hash;
		}
        hinge_hash[param[0].split("=")[0]+", "+param[0].split("=")[1]] = hinge_param;
	}
    //console.log(hinge_hash)
}
function slice_into_chunks(arr, chunk_size) {
    let res = [];
    for (let i = 0; i < arr.length; i += chunk_size) {
        let chunk = arr.slice(i, i + chunk_size);
        res.push(chunk);
	}
    return res;
}
function drawer_parameters(s) {
    drawer_hash = {};
    for (let i = 0; i < s.length; i++) {
        drawer_param = {};
        if (s[i]!=""){
            param = s[i].split(",");
            drawer_param[param[1].split("=>")[0]] = param[1].split("=>")[1];
            drawer_param[param[2].split("=>")[0]] = param[2].split("=>")[1];
            for (let j = 3; j < param.length; j++) {
                holes = {};
                hole_param = param[j].split("=>")[1];
                holes = hole_map(holes,hole_param);
                drawer_param[param[j].split("=>")[0]] = holes;
			}
            drawer_hash[param[0].split("=>")[1]] = drawer_param;
		}
	}
    //console.log(drawer_hash)
}
function accessories_parameters(s) {
    accessories_hash = {};
    for (let i = 0; i < s.length; i++) {
        holes = {};
        hole_param = s[i].split("=>")[1];
        holes = hole_map(holes,hole_param);
        accessories_hash[s[i].split("=>")[0].replace('\t','')] = holes;
	}
    //console.log(accessories_hash)
}
function groove_parameters(s) {
    groove_hash = {};
    for (let i = 0; i < s.length; i++) {
        holes = {};
        hole_param = s[i].split("=>")[1];
        if (hole_param) {
            hole_parameters = hole_param.split("&");
            for (let k = 0; k <= hole_parameters.length; k++) {
                if (hole_parameters[k]) {
                    holes["x"+(k+1)] = hole_parameters[k].split(";")[0];
                    holes["y"+(k+1)] = hole_parameters[k].split(";")[1];
				}
			}
		}
        groove_hash[s[i].split("=>")[0]] = holes;
	}
    //console.log(groove_hash)
}
function lists_parameters(s) {
    lists_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){lists_array.push(s[i].split("="));}
	}
    //console.log(lists_array)
}
function texts_parameters(s) {
    texts_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){texts_array.push(s[i].split("="));}
	}
    //console.log(texts_array)
}
function worktop_parameters(s) {
    worktop_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){worktop_array.push(s[i].split("=>"));}
	}
    //console.log(worktop_array)
}
function fartuk_parameters(s) {
    fartuk_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){fartuk_array.push(s[i].split("=>"));}
	}
    //console.log(fartuk_array)
}
function frontal_parameters(s) {
    frontal_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){frontal_array.push(s[i].split("=>"));}
	}
    //console.log(frontal_array)
}
function freza_parameters(s) {
    freza_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){freza_array.push(s[i].split("="));}
	}
    //console.log(freza_array)
}
function component_parameters(s) {
    component_array = [];
    for (let i = 0; i < s.length; i++) {
        if(s[i]!=""){component_array.push(s[i].split("=").map(x => x.replace(/"/g,'')));}
	}
    //console.log(component_array)
}
function material_parameters(s) {
    material_array = [];
    for (let i = 0; i < s.length; i++) {
	    if(s[i]!=""){material_array.push(s[i].split("=").map(x => x.replace(/"/g,'')));}
	}
    //console.log(material_array)
}
function parameters(s,hinge="",hinge_producer=""){
    if (all_parameters == "") { all_parameters = s; }
    $('#parameter_table').empty();
    var content='';
    var table = document.getElementById("parameter_table");
    var menu = "Общие";
    let number_menu = 0;
    let menu_buttons = document.getElementsByClassName("param_menu");
    //console.log(s)
    for (let i = 0; i < s.length; i++) {
        if (s[i].indexOf("plugin_version") != -1) {
            plugin_version = s[i].split("plugin_version")[1];
            s.splice(i,1);
		}
	}
    for (let i = 0; i < s.length; i++) {
        if (s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) {
            menu = s[i].split("=")[0];
            menu_buttons[number_menu].innerHTML = menu;
            number_menu += 1;
		}
		
        if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 2)) { //Присадка
            // верхняя часть
			let fastener_image = "./cont/style/fastener_image.png";
            let row_main = table.insertRow(table.rows.length);
            let cell=row_main.insertCell(0);
            cell.innerHTML='<td>' + s[i].split("=")[0] + '</td>';
            cell=row_main.insertCell(1);
            cell.innerHTML='<td><input class="menu_row" number_menu="'+s[i].split("=")[2]+'" type="text" disabled="true" value="' + s[i].split("=")[0] + '"></input></td>';
            row_main = table.insertRow(table.rows.length);
            row_main.style.borderBottom = "1px solid grey";
            row_main.setAttribute("menu_name",menu);
            // установка крепежа
            cell=row_main.insertCell(0);
            cell.style = "width: 117px; vertical-align: middle;";
            cell.innerHTML='<td><label>' + s[i+1].split("=")[0] + '</label></td>';
            cell=row_main.insertCell(1);
            cell.style = "width: 30px";
            content=select_content(1,s[i+1].split("=")[1],s[i+1].split("=")[4].split("&"),s[i+1].split("=")[2],"150","","");
            cell.innerHTML=content;
            // установка размеров
            cell=row_main.insertCell(2);
            cell.style = "width: 133px; vertical-align: middle;";
            cell.innerHTML='<td><fastener_label>' + s[i+2].split("=")[0] + '</fastener_label></td>';
            cell=row_main.insertCell(3);
            cell.style = "width: 120px";
            content=select_content(1,s[i+2].split("=")[1],s[i+2].split("=")[4].split("&"),s[i+2].split("=")[2],"140","","");
            cell.innerHTML=content;
            // база для размеров
            cell=row_main.insertCell(4);
            cell.style = "width: 127px; vertical-align: middle;";
            cell.innerHTML='<td><fastener_label>' + s[i+3].split("=")[0] + '</fastener_label></td>';
            cell=row_main.insertCell(5);
            cell.style = "width: 30px";
            content=select_content(1,s[i+3].split("=")[1],s[i+3].split("=")[4].split("&"),s[i+3].split("=")[2],"120","","");
            cell.innerHTML=content;
            // тип в названии отверстия
            cell=row_main.insertCell(6);
            cell.style = "width: 165px; vertical-align: middle;";
            cell.innerHTML='<td><fastener_label>' + s[i+4].split("=")[0] + '</fastener_label></td>';
            cell=row_main.insertCell(7);
            cell.style = "width: 30px";
            content=select_content(1,s[i+4].split("=")[1],s[i+4].split("=")[4].split("&"),s[i+4].split("=")[2],"50","","");
            cell.innerHTML=content;
            // нижняя часть
            row_main = table.insertRow(table.rows.length);
            row_main.setAttribute("menu_name",menu);
            // левая часть
            cell=row_main.insertCell(0);
            cell.innerHTML='<table id="fastener_name_table" class="sortable-table"></table>';
            cell.style = "width: 250px";
            let fastener_name_table = document.getElementById("fastener_name_table");
            // список крепежа
			if (( active_fastener != "") && (!fastener_hash[active_fastener])) { active_fastener = ""; }
            for (let key in fastener_hash) {
                if (active_fastener=="") { active_fastener = fastener_hash[key]["fastener_name"]; }
                if (fastener_hash[key]["visible"] == "true") { 
                    visible_img = "./cont/style/visible.png"
                    } else { 
                    visible_img = "./cont/style/invisible.png"
				}
                row = fastener_name_table.insertRow(fastener_name_table.rows.length);
                
                cell=row.insertCell(0);
                cell.innerHTML='<td><img fastener_name="'+fastener_hash[key]["fastener_name"]+'" class="select_image" visible="true" src='+visible_img+' alt="select" title="Видимость в списке" onclick="change_visible(this);"></td>';
                
                cell=row.insertCell(1);
                if (fastener_hash[key]["active"] == "true") {
                    active_fastener = fastener_hash[key]["fastener_name"];
                    row.style.backgroundColor = 'orange'
                    cell.innerHTML='<td><label_fastener id="name_column"><b>'+fastener_hash[key]["fastener_name"]+'</b></label_fastener></td>';
                    } else {
                    cell.innerHTML='<td><label_fastener fastener_name="'+fastener_hash[key]["fastener_name"]+'" class="pointer" id="name_column" onclick="change_active(this)">'+fastener_hash[key]["fastener_name"]+'</label_fastener></td>';
				}
                cell=row.insertCell(2);
                cell.innerHTML='<td><span class="span-handle">↕</span></td>';
                cell=row.insertCell(3);
                cell.innerHTML='<td><img fastener_name="'+fastener_hash[key]["fastener_name"]+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select" title="Скопировать крепеж" onclick="copy_fastener(this);"></td>';
                cell=row.insertCell(4);
                cell.innerHTML='<td><img fastener_name="'+fastener_hash[key]["fastener_name"]+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" title="Удалить крепеж" onclick="delete_fastener(this);"></td>';
			}
            // правая часть
            cell=row_main.insertCell(1);
            cell.innerHTML='<table id="fastener_table"></table>';
            let fastener_table = document.getElementById("fastener_table");
            // изображение
            row = fastener_table.insertRow(fastener_table.rows.length);
            cell=row.insertCell(0);
            cell.innerHTML='<td><img id="fastener_image" src='+fastener_image+' alt="IMG"></td>';
            // настройки крепежа (название...)
            row = fastener_table.insertRow(fastener_table.rows.length);
            cell=row.insertCell(0);
            content='<label>Name</label><input class="fastener_input" id="fastener_name" type="text" value="'+fastener_hash[active_fastener]["fastener_name"]+'"></input><label>L</label><input class="fastener_input" type="text" id="fastener_L" value="'+(fastener_hash[active_fastener]["fastener_L"]?fastener_hash[active_fastener]["fastener_L"]:"")+'"></input><label>L1</label><input class="fastener_input" type="text" id="fastener_L1" value="'+(fastener_hash[active_fastener]["fastener_L1"]?fastener_hash[active_fastener]["fastener_L1"]:"")+'"></input><label>L2</label><input class="fastener_input" type="text" id="fastener_L2" value="'+(fastener_hash[active_fastener]["fastener_L2"]?fastener_hash[active_fastener]["fastener_L2"]:"")+'"></input><label>C</label><input title="1/2 - крепеж ставится посередине" class="fastener_input" type="text" id="fastener_C" value="'+(fastener_hash[active_fastener]["fastener_C"]?fastener_hash[active_fastener]["fastener_C"]:"")+'"></input><label>dside_C</label><input title="1/2 - крепеж ставится посередине" class="fastener_input" type="text" id="dside_C" value="'+(fastener_hash[active_fastener]["dside_C"]?fastener_hash[active_fastener]["dside_C"]:"")+'"></input><label>min_dist</label><input class="fastener_input" type="text" id="min_dist" value="'+(fastener_hash[active_fastener]["min_dist"]?fastener_hash[active_fastener]["min_dist"]:"")+'"></input><label>multiple</label><input class="fastener_input" type="text" id="multiple" value="'+(fastener_hash[active_fastener]["multiple"]?fastener_hash[active_fastener]["multiple"]:"")+'"></input><label>dist</label><input class="fastener_input" type="text" id="multiple_dist" value="'+(fastener_hash[active_fastener]["multiple_dist"]?fastener_hash[active_fastener]["multiple_dist"]:"")+'"></input>';
            cell.innerHTML=content;
            // настройки крепежа (диаметр, глубина...)
            for (let k = 1; k <= 7; k++) {
                row = fastener_table.insertRow(fastener_table.rows.length);
                cell=row.insertCell(0);
                content = "";
                content += '<label>p</label><input style="width: 29px" class="fastener_input" id="fastener_pD'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_pD"+k]?fastener_hash[active_fastener]["fastener_pD"+k]:"")+'"></input>';
                content += '<label>D'+k+'</label><input style="width: 17px" class="fastener_input" id="fastener_D'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k]?fastener_hash[active_fastener]["fastener_D"+k]:"")+'"></input>x<input class="fastener_input" id="fastener_D'+k+'_depth" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k+"_depth"]?fastener_hash[active_fastener]["fastener_D"+k+"_depth"]:"")+'"></input>';
                content += '<label style="width: 22px; display: inline-block">D'+k+'1</label><input style="width: 17px" class="fastener_input" id="fastener_D'+k+'1" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k+"1"]?fastener_hash[active_fastener]["fastener_D"+k+"1"]:"")+'"></input>x<input class="fastener_input" id="fastener_D'+k+'1_depth" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k+"1_depth"]?fastener_hash[active_fastener]["fastener_D"+k+"1_depth"]:"")+'"></input>';
                content += '<label>D'+k+'2</label><input style="width: 17px" class="fastener_input" id="fastener_D'+k+'2" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k+"2"]?fastener_hash[active_fastener]["fastener_D"+k+"2"]:"")+'"></input>x<input class="fastener_input" id="fastener_D'+k+'2_depth" type="text" value="'+(fastener_hash[active_fastener]["fastener_D"+k+"2_depth"]?fastener_hash[active_fastener]["fastener_D"+k+"2_depth"]:"")+'"></input>';
                content += '<label style="padding-left: 10px">p</label><input style="width: 29px" class="fastener_input" id="fastener_pdside'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_pdside"+k]?fastener_hash[active_fastener]["fastener_pdside"+k]:"")+'"></input>';
                content += '<label style="padding-left: 2px">dside'+k+'</label><input style="width: 17px" class="fastener_input" id="fastener_dside'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_dside"+k]?fastener_hash[active_fastener]["fastener_dside"+k]:"")+'"></input>x<input class="fastener_input" id="fastener_dside'+k+'_depth" type="text" value="'+(fastener_hash[active_fastener]["fastener_dside"+k+"_depth"]?fastener_hash[active_fastener]["fastener_dside"+k+"_depth"]:"")+'"></input>';
                content += '<label style="padding-left: 10px">p</label><input style="width: 29px" class="fastener_input" id="fastener_pd'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_pd"+k]?fastener_hash[active_fastener]["fastener_pd"+k]:"")+'"></input>';
                content += '<label style="padding-left: 2px">d'+k+'</label><input style="width: 17px" class="fastener_input" id="fastener_d'+k+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_d"+k]?fastener_hash[active_fastener]["fastener_d"+k]:"")+'"></input>x<input class="fastener_input" id="fastener_d'+k+'_depth" type="text" value="'+(fastener_hash[active_fastener]["fastener_d"+k+"_depth"]?fastener_hash[active_fastener]["fastener_d"+k+"_depth"]:"")+'"></input>';
                content += '<label>n'+(k-1)+'</label><input style="width: 17px" class="fastener_input" id="fastener_n'+(k-1)+'" type="text" value="'+(fastener_hash[active_fastener]["fastener_n"+(k-1)]?fastener_hash[active_fastener]["fastener_n"+(k-1)]:"")+'"></input>';
                let count = 0;
                let list_name = fastener_hash[active_fastener]["list_name"+k];
                if (list_name) {
                    if (list_name.indexOf(';') != -1) {
                        list_name = list_name.split(';');
                        for (var l = 0; l < list_name.length-1; l++) {
                            count += +list_name[l].split('~')[1];
						}
                        } else {
                        count = 1;
                        list_name = [list_name+"~1"]; 
					}
				}
                content += '<label>-</label><input onclick="edit_list_name(this);" class="list_name" id="list_name'+k+'" type="submit" value="Edit list ('+count.toString()+')"></input>';
                
                rgb = (fastener_hash[active_fastener]["color"+k]?fastener_hash[active_fastener]["color"+k].split("."):[100,100,100])
                let color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
                content += '<input type="color" value="'+color+'" rgb_value="'+rgb+'" class="fastener_color" id="color'+k+'">';
                cell.innerHTML=content;
			}
		} 
        
        else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 3)) { //Шаблон
		    table.style.tableLayout = "fixed";
            let row_main = table.insertRow(table.rows.length);
            let cell=row_main.insertCell(0);
            cell.innerHTML='<td>' + s[i].split("=")[0] + '</td>';
            cell=row_main.insertCell(1);
            cell.innerHTML='<td><input class="menu_row" number_menu="'+s[i].split("=")[2]+'" type="text" disabled="true" value="' + s[i].split("=")[0] + '"></input></td>';
            
            let fastener_name_option_array = ["^"];
            for (let key2 in fastener_hash) {
                fastener_name_option_array = fastener_name_option_array.concat(key2+"^"+key2);
			}
            let template_option_array = ["^","template1^Правило 1","template2^Правило 2","template3^Правило 3","template4^Правило 4","template5^Правило 5","template6^Правило 6","template7^Правило 7"]
            for (let key in template_hash) {
                row = table.insertRow(table.rows.length);
                row.setAttribute("menu_name",menu);
                row.classList.add("template_row");
                cell=row.insertCell(0);
                arr = template_hash[key];
                if ((arr.split("=")[1].toLowerCase().indexOf("header") == -1 ) && (arr.split("=")[1].toLowerCase().indexOf("common") == -1 ) && ((arr.split("=")[1].toLowerCase().indexOf("horizontal") != -1 ) || (arr.split("=")[1].toLowerCase().indexOf("vertical") != -1 ) || (arr.split("=")[1].toLowerCase().indexOf("frontal") != -1 ))) {
                    content='<td><input id="input_'+arr.split("=")[1]+'" type="text" class="template_input" value="' + arr.split("=")[0] + '" ></input></td>';
                    content+='<td><img template_name="'+arr.split("=")[1]+'" style="padding-left: 10px" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" title="Удалить строку" onclick="delete_template(this);"></td>';
                    } else {
                    content='<td><label_template template_name="'+arr.split("=")[0]+'" id="template_type_column">'+arr.split("=")[0]+'</label_template></td>';
                    if (arr.split("=")[1].toLowerCase().indexOf("common") != -1 ) { content+='<td><img template_name="'+arr.split("=")[1]+'" style="padding-left: 10px" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select" title="Новая строка" onclick="new_template(this);"></td>';}
				}
                cell.innerHTML=content;
                cell.style= "vertical-align: top";
				
                if (arr.split("=")[3].toLowerCase().indexOf("select") != -1 ) {
                    if (arr.split("=")[4] == "fastener_list") { var option_array = fastener_name_option_array;
					} else { var option_array = arr.split("=")[4].split("&"); }
					cell=row.insertCell(1);
                    content=select_content(1,arr.split("=")[1],option_array,arr.split("=")[2],"318",arr.split("=")[4],"");
                    cell.innerHTML=content;
					
                    } else if (arr.split("=")[3].toLowerCase().indexOf("input") != -1 ) {
					
					cell=row.insertCell(1);
                    content='<td><input style="width: 310px; " id="' + arr.split("=")[1];
                    content+='" type="text" value="' + arr.split("=")[2] + '"></input></td>';
                    cell.innerHTML=content;
                    if (arr.split("=")[1].indexOf("template")!=-1) {
					template_value_array[arr.split("=")[1]] = arr.split("=")[2]; }
					
                    } else if (arr.split("=")[1].toLowerCase().indexOf("header") != -1) {
					
					cell.style="text-align: center;"
					cell=row.insertCell(1);
                    row.style.borderTop = "1px solid grey"
                    content='<td><label_edge_vendor id="' + arr.split("=")[1] + '">'+arr.split("=")[2]+'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 212px; max-width: 212px; min-width: 212px;";
                    cell=row.insertCell(2);
                    content='<td><label_edge_vendor>'+ arr.split("=")[3] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 95px; max-width: 95px; min-width: 95px;";
                    cell=row.insertCell(3);
                    content='<td><label_edge_vendor title="Положение от края">'+ arr.split("=")[4] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 36px; max-width: 36px; min-width: 36px;";
					cell=row.insertCell(4);
                    content='<td><label_edge_vendor title="Позиция начала\nП - Перед\nЗ - Зад\nН - Низ\nВ - Верх\nНе отмечено - Текущая">'+ arr.split("=")[5] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
					cell.style="text-align: center; width: 54px; max-width: 54px; min-width: 54px; padding-right: 5px;";
                    cell=row.insertCell(5);
                    content='<td><label_edge_vendor>'+ arr.split("=")[6] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 212px; max-width: 212px; min-width: 212px;";
                    cell=row.insertCell(6);
                    content='<td><label_edge_vendor>'+ arr.split("=")[7] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 95px; max-width: 95px; min-width: 95px;";
                    cell=row.insertCell(7);
                    content='<td><label_edge_vendor title="Положение от края">'+ arr.split("=")[8] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 37px; max-width: 37px; min-width: 37px;";
					cell=row.insertCell(8);
                    content='<td><label_edge_vendor title="Позиция начала\nЛ - Лево\nП - Право\nН - Низ\nВ - Верх\nНе отмечено - Текущая">'+ arr.split("=")[9] +'</label_edge_vendor></td>';
                    cell.innerHTML=content;
                    cell.style="text-align: center; width: 47px; max-width: 47px; min-width: 47px;";
					
                    } else {
					
					cell=row.insertCell(1);
                    content=select_content(0,arr.split("=")[1],fastener_name_option_array,arr.split("=")[2],"212","","");
                    cell.innerHTML=content;
                    
                    cell=row.insertCell(2);
                    content=select_content(0,arr.split("=")[1]+"2",template_option_array,arr.split("=")[3],"95","","change_template");
                    cell.innerHTML=content;
                    
                    cell=row.insertCell(3);
                    content='<td><input style="width: 30px;" id="'+arr.split("=")[1]+"3"+'" type="text" value="' + arr.split("=")[4] + '" template_position="3"></input></td>';
                    cell.innerHTML=content;
                    
					cell = row.insertCell(4);
					cell.style.width = "56px";
					cell.style.minWidth = "56px";
					cell.style.maxWidth = "56px";
					let checked1 = (arr.split("=")[5] === "1") ? "checked" : "";
					let checked2 = (arr.split("=")[5] === "2") ? "checked" : "";
					content = `<div style="display: flex; gap: 1px; align-items: center; padding-right: 10px;">
					<input style="width: 20px;" class="template_checkbox" type="checkbox" id="${arr.split("=")[1]}_4_1" ${checked1}>
					<input style="width: 20px;" class="template_checkbox" type="checkbox" id="${arr.split("=")[1]}_4_2" ${checked2}>
					</div>`;
					cell.innerHTML = content;
					
					cell=row.insertCell(5);
                    content=select_content(0,arr.split("=")[1]+"5",fastener_name_option_array,arr.split("=")[6],"212","","");
                    cell.innerHTML=content;
					
					cell = row.insertCell(6);
					content = select_content(0, arr.split("=")[1] + "6", template_option_array, arr.split("=")[7], "95", "", "change_template2");
					cell.innerHTML = content;
					
					cell = row.insertCell(7);
					content = '<input style="width: 30px;" id="' + arr.split("=")[1] + "7" + '" type="text" value="' + arr.split("=")[8] + '" template_position="6">';
					cell.innerHTML = content;
					
					cell = row.insertCell(8);
					cell.style.width = "46px";
					cell.style.minWidth = "46px";
					cell.style.maxWidth = "46px";
					let checked3 = (arr.split("=")[9] === "1") ? "checked" : "";
					let checked4 = (arr.split("=")[9] === "2") ? "checked" : "";
					content = `<div style="display: flex; gap: 1px; align-items: center;">
					<input style="width: 20px;" class="template_checkbox" type="checkbox" id="${arr.split("=")[1]}_8_1" ${checked3}>
					<input style="width: 20px;" class="template_checkbox" type="checkbox" id="${arr.split("=")[1]}_8_2" ${checked4}>
					</div>`;
					cell.innerHTML = content;
				}
			}
		}
        
        else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 4)) { //Петли
            let row_main = table.insertRow(table.rows.length);
            let cell=row_main.insertCell(0);
            cell.innerHTML='<td>' + s[i].split("=")[0] + '</td>';
            cell=row_main.insertCell(1);
            cell.innerHTML='<td><input class="menu_row" number_menu="'+s[i].split("=")[2]+'" type="text" disabled="true" value="' + s[i].split("=")[0] + '"></input></td>';
            
            row_main = table.insertRow(table.rows.length);
            row_main.setAttribute("menu_name",menu);
            cell=row_main.insertCell(0);
            cell.innerHTML='<table id="hinge_type_table"></table>';
            cell.style = "width: 200px";
            let hinge_type_table = document.getElementById("hinge_type_table");
            row = hinge_type_table.insertRow(hinge_type_table.rows.length);
            
            cell=row.insertCell(0);
            cell.innerHTML='<td><label_hinge_header id="hinge_type_header"><b>Тип:</b></label_hinge_header></td>';
			if (( active_hinge_type != "") && (!hinge_hash[active_hinge_type])) { active_hinge_type = ""; }
            for (let key in hinge_hash) {
                row = hinge_type_table.insertRow(hinge_type_table.rows.length);
                cell=row.insertCell(0);
                if ((hinge == "") && (active_hinge_type == "")) { active_hinge_type = key; }
                if (active_hinge_type == key) { row.style.backgroundColor = 'orange'; }
                cell.innerHTML='<td><label_hinge hinge_producer="'+key+'" class="pointer" id="hinge_type_column" onclick="change_active_hinge_type(this)">'+key+'</label_hinge></td>';
			}
            
            cell=row_main.insertCell(1);
            cell.innerHTML='<table id="hinge_producer_table" class="sortable-table"></table>';
            cell.style = "width: 200px";
            let hinge_producer_table = document.getElementById("hinge_producer_table");
            let header = hinge_producer_table.createTHead();
            header_row = header.insertRow(hinge_producer_table.rows.length);
            header_row.innerHTML='<tr><th><label_hinge_header id="hinge_name_header"><b>Список:</b></label_hinge_header></th></tr>';
            let body = hinge_producer_table.createTBody();
			if (( active_hinge_producer != "") && (!hinge_hash[active_hinge_type][active_hinge_producer])) { active_hinge_producer = ""; }
            for (let key in hinge_hash[active_hinge_type]) {
                row = body.insertRow(body.rows.length);
                row.innerHTML='<tr><td><img title="Редактировать название" class="edit_image" onclick="edit_hinge_producer(this);" hinge_producer="'+key+'" src="./cont/style/edit_name.png" alt="select"></td>';
                row.innerHTML+='<td><label_hinge hinge_producer="'+key+'" class="pointer" onclick="change_active_hinge_producer(this)">'+key+'</label_hinge></td>';
                row.innerHTML+='<td><span class="span-handle">↕</span></td>';
                row.innerHTML+='<td><img title="Скопировать" hinge_producer="'+key+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_hinge(this);"></td>';
                row.innerHTML+='<td><img title="Удалить" hinge_producer="'+key+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_hinge(this);"></td></tr>';
                if ((hinge_producer == "") && (active_hinge_producer == "")) { active_hinge_producer = key; }
                if (active_hinge_producer == key) { row.style.backgroundColor = 'orange'; }
			}
            
            cell=row_main.insertCell(2);
            cell.innerHTML='<table id="hinge_table"></table>';
            let hinge_table = document.getElementById("hinge_table");
            let hinge_table_row = hinge_table.insertRow(hinge_table.rows.length);
            
            
            cell=hinge_table_row.insertCell(0);
            cell.innerHTML='<table id="cup_plate_table"></table>';
            let cup_plate_table = document.getElementById("cup_plate_table");
            row = cup_plate_table.insertRow(cup_plate_table.rows.length);
            cell=row.insertCell(0);
            let active_hinge_map = hinge_hash[active_hinge_type][active_hinge_producer];
		    if ((active_hinge_name=="") || (!active_hinge_map[active_hinge_name])) { active_hinge_name = active_hinge_map[Object.keys(active_hinge_map)[0]]["name"]; }
            let active_hinge_name_hash = active_hinge_map[active_hinge_name];
            if (active_hinge_type.indexOf("планки")==-1) {
                
                let cup_image = "./cont/style/cup_image.png";
                cell.innerHTML='<td><img id="cup_image" src='+cup_image+' alt="IMG"></td>';
                row = cup_plate_table.insertRow(cup_plate_table.rows.length);
                cell=row.insertCell(0);
                let C = "";
                if (active_hinge_name_hash["axis1"]=="-X") {
					coordinate = "A";
					if (active_hinge_type.indexOf("фальш")!=-1) { coordinate_value = (active_hinge_name_hash["y1"]?-1*(+active_hinge_name_hash["y1"]+22):""); }
					else { coordinate_value = (active_hinge_name_hash["y1"]?-1*(+active_hinge_name_hash["y1"]+37):""); }
				}
				else { coordinate = "x1"; coordinate_value = (active_hinge_name_hash["x1"]?active_hinge_name_hash["x1"]:""); }
				content='<label>D</label><input style="width: 20px" class="hinge_input" id="diam1" type="text" value="'+(active_hinge_name_hash["diam1"]?active_hinge_name_hash["diam1"]:"")+'"></input><label>x</label><input style="width: 20px" class="hinge_input" id="depth1" type="text" value="'+(active_hinge_name_hash["depth1"]?active_hinge_name_hash["depth1"]:"")+'"></input><label>C</label><input style="width: 30px" class="hinge_input" id="C" type="text" value="'+C+'" disabled></input><label>A</label><input style="width: 30px" class="hinge_input" id="'+coordinate+'" type="text" value="'+coordinate_value+'"></input><label>-</label><input style="width: 90px" class="hinge_input" id="list_name1" type="text" value="'+(active_hinge_name_hash["list_name1"]?active_hinge_name_hash["list_name1"]:"")+'"></input>';
				rgb = (active_hinge_name_hash["color1"]?active_hinge_name_hash["color1"].split("."):[100,100,100])
				color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
				content += '<input type="color" style="width: 35px" value="'+color+'" rgb_value="'+rgb+'" class="param_color" id="color1">';
				cell.innerHTML=content;
				
				row = cup_plate_table.insertRow(cup_plate_table.rows.length);
				cell=row.insertCell(0);
				content='<label style="width: 25px">d </label><input style="width: 20px" class="hinge_input" id="diam2" type="text" value="'+(active_hinge_name_hash["diam2"]?active_hinge_name_hash["diam2"]:"")+'"></input><label>x</label><input style="width: 20px" class="hinge_input" id="depth2" type="text" value="'+(active_hinge_name_hash["depth2"]?active_hinge_name_hash["depth2"]:"")+'"></input><label>N</label><input style="width: 30px" class="hinge_input" id="N" type="text" value="'+(active_hinge_name_hash["x2"]?(active_hinge_name_hash["axis2"]=="-Y"?(+active_hinge_name_hash["x2"]-(active_hinge_name_hash["x1"]?(+active_hinge_name_hash["x1"]):0)):(active_hinge_name_hash["y1"]?(+active_hinge_name_hash["y1"]-(+active_hinge_name_hash["y2"])):0)):"")+'"></input><label>L</label><input style="width: 30px" class="hinge_input" id="multiple_dist2" type="text" value="'+(active_hinge_name_hash["multiple_dist2"]?active_hinge_name_hash["multiple_dist2"]:"")+'"></input><label>-</label><input style="width: 90px" class="hinge_input" id="list_name2" type="text" value="'+(active_hinge_name_hash["list_name2"]?active_hinge_name_hash["list_name2"]:"")+'"></input>';
				rgb = (active_hinge_name_hash["color2"]?active_hinge_name_hash["color2"].split("."):[100,100,100])
				color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
				content += '<input type="color" style="width: 35px" value="'+color+'" rgb_value="'+rgb+'" class="param_color" id="color2">';
				cell.innerHTML=content;
				
				} else {
				
				let plate_image = "./cont/style/plate_image.png";
				cell.innerHTML='<td><img id="plate_image" src='+plate_image+' alt="IMG"></td>';
				row = cup_plate_table.insertRow(cup_plate_table.rows.length);
				cell=row.insertCell(0);
				
				content='<label>d1</label><input style="width: 20px" class="hinge_input" id="diam1" type="text" value="'+(active_hinge_name_hash["diam1"]?active_hinge_name_hash["diam1"]:"")+'"></input><label>x</label><input style="width: 20px" class="hinge_input" id="depth1" type="text" value="'+(active_hinge_name_hash["depth1"]?active_hinge_name_hash["depth1"]:"")+'"></input><label>n1</label><input style="width: 22px" class="hinge_input" id="n1" type="text" value="'+(active_hinge_name_hash["y1"]?(+active_hinge_name_hash["y1"]+37):"")+'"></input><label>L1</label><input style="width: 22px" class="hinge_input" id="multiple_dist1" type="text" value="'+(active_hinge_name_hash["multiple_dist1"]?active_hinge_name_hash["multiple_dist1"]:"")+'"></input><label>-</label><input style="width: 90px" class="hinge_input" id="list_name1" type="text" value="'+(active_hinge_name_hash["list_name1"]?active_hinge_name_hash["list_name1"]:"")+'"></input>';
				rgb = (active_hinge_name_hash["color1"]?active_hinge_name_hash["color1"].split("."):[100,100,100])
				color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
				content += '<input type="color" style="width: 35px" value="'+color+'" rgb_value="'+rgb+'" class="param_color" id="color1">';
				cell.innerHTML=content;
				
				row = cup_plate_table.insertRow(cup_plate_table.rows.length);
				cell=row.insertCell(0);
				content='<label>d2</label><input style="width: 20px" class="hinge_input" id="diam3" type="text" value="'+(active_hinge_name_hash["diam3"]?active_hinge_name_hash["diam3"]:"")+'"></input><label>x</label><input style="width: 20px" class="hinge_input" id="depth3" type="text" value="'+(active_hinge_name_hash["depth3"]?active_hinge_name_hash["depth3"]:"")+'"></input><label>n2</label><input style="width: 22px" class="hinge_input" id="n2" type="text" value="'+(active_hinge_name_hash["y2"]?(+active_hinge_name_hash["y2"]+20):"")+'"></input><label>n3</label><input style="width: 22px" class="hinge_input" id="y3" type="text" value="'+(active_hinge_name_hash["y3"]?+active_hinge_name_hash["y3"]-(+active_hinge_name_hash["y2"]):"")+'"></input><label>-</label><input style="width: 90px" class="hinge_input" id="list_name2" type="text" value="'+(active_hinge_name_hash["list_name2"]?active_hinge_name_hash["list_name2"]:"")+'"></input>';
				rgb = (active_hinge_name_hash["color2"]?active_hinge_name_hash["color2"].split("."):[100,100,100])
				color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
				content += '<input type="color" style="width: 35px" value="'+color+'" rgb_value="'+rgb+'" class="param_color" id="color2">';
				cell.innerHTML=content;
				
			}
			
			hinge_table_row = hinge_table.insertRow(hinge_table.rows.length);
			cell=hinge_table_row.insertCell(0);
			content = '<label>Name</label><select style="width: 450px;" class="hinge_input" id="hinge_producer" onchange="change_hinge_name(this)" type="text">';
			for (let key in active_hinge_map) {
				content=content.concat('<option value="'+key.split("<#>")[0].replace(/\|/g,",")+'">'+key.split("<#>")[0].replace(/\|/g,",")+'</option>');
			}
			content=content.concat('</select>');
			content=content.concat('<input type="submit" onclick="edit_hinge_name_list(this);" style="width: 80px;text-align: center; margin-left: 5px;" id="edit_hinge_name_list" value="Edit list ('+Object.keys(active_hinge_map).length+')"><input type="submit" style="width: 40px;text-align: center;" id="copy_parameters" title="Скопировать параметры отверстий" value="Copy"><input type="submit" style="width: 40px;text-align: center;" id="paste_parameters" title="Вставить параметры отверстий" value="Paste">');
			cell.innerHTML=content;
			document.getElementById("hinge_producer").value = active_hinge_name.split("<#>")[0].replace(/\|/g,",");
		}
		
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 5)) { //Направляющие
			let row_main = begin_table(table,menu,s[i].split("=")[2]);
			
			let cell=row_main.insertCell(0);
			cell.innerHTML='<table id="drawer_name_table" class="sortable-table"></table>';
			cell.style = "width: 300px";
			let name_table = document.getElementById("drawer_name_table");
			if (( active_drawer != "") && (!drawer_hash[active_drawer])) { active_drawer = ""; }
			for (let key in drawer_hash) {
				row = name_table.insertRow(name_table.rows.length);
				cell=row.insertCell(0);
				if (active_drawer == "") { active_drawer = key; }
				if (active_drawer == key) { row.style.backgroundColor = 'orange'; }
				cell.innerHTML='<td><label_drawer drawer_name="'+key+'" class="pointer" id="drawer_type_column" onclick="change_active_drawer(this)">'+key+'</label_drawer></td>';
				cell=row.insertCell(1);
				cell.innerHTML='<td><span class="span-handle">↕</span></td>';
				cell=row.insertCell(2);
				cell.innerHTML='<td><img drawer_name="'+key+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select" title="Скопировать" onclick="copy_drawer(this);"></td>';
				cell=row.insertCell(3);
				cell.innerHTML='<td><img drawer_name="'+key+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" title="Удалить" onclick="delete_drawer(this);"></td>';
			}
			
			let drawer_image = "./cont/style/drawer_image.png";
			cell=row_main.insertCell(1);
			cell.innerHTML='<table id="drawer_table"></table>';
			let drawer_table = document.getElementById("drawer_table");
			row = drawer_table.insertRow(drawer_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<td><img id="drawer_image" src='+drawer_image+' alt="IMG"></td>';
			if ((active_drawer_depth == "") || !drawer_hash[active_drawer][active_drawer_depth]) { active_drawer_depth = "500" }
			active_drawer_map = drawer_hash[active_drawer][active_drawer_depth];
			if (active_drawer_map===undefined){active_drawer_map={};}
			let active_drawer_depth_list = drawer_hash[active_drawer]["depth_list"];
			row = drawer_table.insertRow(drawer_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<label>Name</label><input class="drawer_input" id="drawer_name" type="text" value="'+active_drawer+'"></input>';
			cell.style = "width: 445px";
			cell=row.insertCell(1);
			content='<label>Depth</label><select id="active_drawer_depth" onchange="change_active_drawer_depth(this)" type="text">';
			var option_array = active_drawer_depth_list.split("&");
			for (var j = 0; j < option_array.length; j++) {
				if (option_array[j] != "") { content=content.concat('<option value="'+option_array[j]+'">'+option_array[j]+'</option>'); }
			}
			content=content.concat('</select>');
			cell.innerHTML=content;
			cell.style = "width: 100px";
			document.getElementById("active_drawer_depth").value = active_drawer_depth;
			
			cell=row.insertCell(2);
			content='<label>Symmetrical Holes</label><select id="symmetrical_holes" onchange="change_symmetrical_holes(this)" type="text">';
			content=content.concat('<option value="yes">Yes</option><option value="no">No</option>');
			content=content.concat('</select><input type="submit" style="width: 40px;text-align: center;" id="copy_parameters" title="Скопировать параметры отверстий\nдля текущей глубины" value="Copy"><input type="submit" style="width: 40px;text-align: center;" id="paste_parameters" title="Вставить параметры отверстий\nдля текущей глубины" value="Paste">');
			cell.innerHTML=content;
			cell.style = "width: 260px";
			document.getElementById("symmetrical_holes").value = drawer_hash[active_drawer]["symmetrical_holes"];
			param_list(drawer_table,active_drawer_map,"drawer_input");
			
			row = drawer_table.insertRow(drawer_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<label>Depth list</label><input class="depth_list_input" id="depth_list_input" type="text" value="'+active_drawer_depth_list+'"></input>';
		}
		
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 6)) { //Фурнитура
			let row_main = begin_table(table,menu,s[i].split("=")[2]);
			let cell=row_main.insertCell(0);
			cell.innerHTML='<table id="accessories_name_table" class="sortable-table"></table>';
			cell.style = "width: 250px";
			let name_table = document.getElementById("accessories_name_table");
			if (( active_accessories != "") && (!accessories_hash[active_accessories])) { active_accessories = ""; }
			for (let key in accessories_hash) {
				row = name_table.insertRow(name_table.rows.length);
				cell=row.insertCell(0);
				if (active_accessories == "") { active_accessories = key; }
				if (active_accessories == key) { row.style.backgroundColor = 'orange'; }
				cell.innerHTML='<td><label_accessories accessories_name="'+key+'" class="pointer" id="accesories_type_column" onclick="change_active_accessories(this)">'+key+'</label_accessories></td>';
				cell=row.insertCell(1);
				cell.innerHTML='<td><span class="span-handle">↕</span></td>';
				cell=row.insertCell(2);
				cell.innerHTML='<td><img accessories_name="'+key+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select" title="Скопировать" onclick="copy_accessories(this);"></td>';
				cell=row.insertCell(3);
				cell.innerHTML='<td><img accessories_name="'+key+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" title="Удалить" onclick="delete_accessories(this);"></td>';
			}
			
			let accessories_image = "./cont/style/accessories_image.png";
			cell=row_main.insertCell(1);
			cell.innerHTML='<table id="accessories_table"></table>';
			let accessories_table = document.getElementById("accessories_table");
			row = accessories_table.insertRow(accessories_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<td><img id="accessories_image" src='+accessories_image+' alt="IMG"></td>';
			
			row = accessories_table.insertRow(accessories_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<label>Name</label><input class="accessories_input" id="accessories_name" type="text" value="'+active_accessories+'"></input><input type="submit" style="width: 40px;text-align: center;" id="copy_parameters" title="Скопировать параметры отверстий" value="Copy"><input type="submit" style="width: 40px;text-align: center;" id="paste_parameters" title="Вставить параметры отверстий" value="Paste">';
			cell.style = "width: 630px";
			
			param_list(accessories_table,accessories_hash[active_accessories],"accessories_input");
		}
		
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 7)) { //Пазы
			let row_main = table.insertRow(table.rows.length);
			let cell=row_main.insertCell(0);
			cell.innerHTML='<td>' + s[i].split("=")[0] + '</td>';
			cell=row_main.insertCell(1);
			cell.innerHTML='<td><input class="menu_row" number_menu="'+s[i].split("=")[2]+'" type="text" disabled="true" value="' + s[i].split("=")[0] + '"></input></td>';
			row_main = table.insertRow(table.rows.length);
			row_main.style.borderBottom = "1px solid grey";
			row_main.setAttribute("menu_name",menu);
			cell=row_main.insertCell(0);
			cell.style = "width: 100px; vertical-align: middle;";
			cell.innerHTML='<td><label>' + s[i+1].split("=")[0] + '</label></td>';
			
			cell=row_main.insertCell(1);
			cell.style = "width: 50px";
			var option_array = s[i+1].split("=")[4].split("&");
			content=select_content(1,s[i+1].split("=")[1],option_array,s[i+1].split("=")[2],"150","","");
			cell.innerHTML=content;
			
			cell=row_main.insertCell(2);
			cell.style = "width: 300px; vertical-align: middle;";
			cell.innerHTML='<td><fastener_label>' + s[i+2].split("=")[0] + '</fastener_label></td>';
			
			cell=row_main.insertCell(3);
			cell.style = "width: 50px";
			var option_array = s[i+2].split("=")[4].split("&");
			content=select_content(1,s[i+2].split("=")[1],option_array,s[i+2].split("=")[2],"150","","");
			cell.innerHTML=content;
			
			row_main = table.insertRow(table.rows.length);
			row_main.setAttribute("menu_name",menu);
			
			cell=row_main.insertCell(0);
			cell.innerHTML='<table id="groove_name_table" class="sortable-table"></table>';
			cell.style = "width: 250px";
			let name_table = document.getElementById("groove_name_table");
            if (( active_groove != "") && (!groove_hash[active_groove])) { active_groove = ""; }
			for (let key in groove_hash) {
				row = name_table.insertRow(name_table.rows.length);
				cell=row.insertCell(0);
				if (active_groove == "") { active_groove = key; }
				if (active_groove == key) { row.style.backgroundColor = 'orange'; }
				cell.innerHTML='<td><label_groove groove_name="'+key+'" class="pointer" id="groove_type_column" onclick="change_active_groove(this)">'+key+'</label_groove></td>';
				cell=row.insertCell(1);
				cell.innerHTML='<td><span class="span-handle">↕</span></td>';
				cell=row.insertCell(2);
				cell.innerHTML='<td><img groove_name="'+key+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select" title="Скопировать" onclick="copy_groove(this);"></td>';
				cell=row.insertCell(3);
				cell.innerHTML='<td><img groove_name="'+key+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" title="Удалить" onclick="delete_groove(this);"></td>';
			}
			
			cell=row_main.insertCell(1);
			cell.innerHTML='<table id="groove_table"></table>';
			let groove_table = document.getElementById("groove_table");
			row = groove_table.insertRow(groove_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<td><div class="wrap"><canvas id="groove_image" width="820" height="500px"></canvas><input id="thickness" value="'+thickness+'"></input>мм</div></td>';
			canvas = document.getElementById('groove_image');
			draw_lines(canvas,groove_hash[active_groove]);
			
			row = groove_table.insertRow(groove_table.rows.length);
			cell=row.insertCell(0);
			cell.innerHTML='<label>Name</label><input class="groove_input" id="groove_name" type="text" value="'+active_groove+'"></input>';
			cell.style = "width: 305px";
			
			row = groove_table.insertRow(groove_table.rows.length);
			cell=row.insertCell(0);
			content = ""
			for (let k = 1; k <= 4; k++) {
				content=content.concat('<label>X'+k+'</label><input class="groove_input" id="x'+k+'" type="text" value="'+(groove_hash[active_groove]["x"+k]?groove_hash[active_groove]["x"+k]:"")+'"></input><label>Y'+k+'</label><input class="groove_input" id="y'+k+'" type="text" value="'+(groove_hash[active_groove]["y"+k]?groove_hash[active_groove]["y"+k]:"")+'"></input>');
			}
			cell.innerHTML=content;
		}
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 10)) { // Списки
			let row_main = begin_table(table,menu,s[i].split("=")[2]);
			let cell=row_main.insertCell(0);
			cell.innerHTML='<table id="lists_table" class="sortable-table"></table>';
			let lists_table = document.getElementById("lists_table");
			let header = lists_table.createTHead();
			header_row = header.insertRow(lists_table.rows.length);
			header_row.innerHTML='<th></th><th></th><th></th><th><label_lists_header id="lists_header"><b>Название группы</b></label_lists_header></th><th><b>Ед.</b></th><th><b>Части</b></th><th><b>Группировать</b></th><th><b>В списках</b></th><th><b>Экспорт</b></th><th><b>Расчет</b></th>';
			header_row.style.borderBottom = "1px solid grey";
			let body = lists_table.createTBody();
			for (var j = 0; j < lists_array.length; j++) {
				let list_index = j;
				row = body.insertRow(body.rows.length);
				row.innerHTML='<td><span class="span-handle">↕</span></td>';
				row.innerHTML+='<td><img title="Скопировать" lists_name="lists'+list_index.toString()+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_list(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" lists_name="lists'+list_index.toString()+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_list(this);"></td>';
				row.innerHTML+='<td><input style="width: 400px;" class="lists_input" title="Нельзя использовать символы:\n ; ~ | =" lists_name="lists'+list_index.toString()+'" value="'+lists_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 40px;" class="lists_input" lists_name="lists'+list_index.toString()+'" value="'+lists_array[j][2]+'"></input></td>';
				
				let count = 0;
				let list_name = lists_array[j][3];
				if (list_name) { count = list_name.split(';').length-1; }
				
				row.innerHTML+='<td><input onclick="edit_lists(this);" class="list_button" id="lists'+list_index.toString()+'" lists_name="lists'+list_index.toString()+'" type="submit" value="Edit list ('+count.toString()+')"></input></td>'
				
				option_array = ["Совпадение всех частей^Совпадение всех частей","Если есть в списке^Если есть в списке"];
				row.innerHTML+=select_content(0,"group__lists"+list_index.toString(),option_array,lists_array[j][4],"176","","lists_select");
				
				option_array = ["Нет^Нет","Группа^Группа","Части^Части"];
				row.innerHTML+=select_content(0,"smeta__lists"+list_index.toString(),option_array,lists_array[j][5],"70","","lists_select");
				row.innerHTML+=select_content(0,"export_lists"+list_index.toString(),option_array,lists_array[j][6],"70","","lists_select");
				
				option_array = ["Не считать^Не считать","Цена группы^Цена группы","Цена частей^Цена частей"];
				row.innerHTML+=select_content(0,"price__lists"+list_index.toString(),option_array,lists_array[j][7],"102","","lists_select");
			}
		}
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 11)) { // Текст
			let row_main = begin_table(table,menu,s[i].split("=")[2]);
			let cell=row_main.insertCell(0);
			cell.innerHTML='<table id="texts_table"></table>';
			let texts_table = document.getElementById("texts_table");
			let header = texts_table.createTHead();
			header_row = header.insertRow(texts_table.rows.length);
			header_row.innerHTML='<th></th><th></th><th><label_texts_header id="texts_header"><b>Элемент</b></label_texts_header></th><th><b>Текст</b></th>';
			header_row.style.borderBottom = "1px solid grey";
			let body = texts_table.createTBody();
			for (var j = 0; j < texts_array.length; j++) {
				let text_index = j;
				row = body.insertRow(body.rows.length);
				row.className = "texts";
				row.innerHTML+='<td><img title="Скопировать" texts_name="text'+text_index.toString()+'" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" texts_name="text'+text_index.toString()+'" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 270px;" disabled texts_name="text'+text_index.toString()+'" value="'+texts_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 727px;" texts_name="text'+text_index.toString()+'" value="'+texts_array[j][2]+'" title="Условные обозначения: \n%P - Позиция панели\n%K - Код модуля\n%N - Наименование панели\n%L - Длина панели\n%W - Ширина панели\n%T - Толщина панели\n%M - Материал панели\n%C - Количество панелей\n%n - Перевод строки\nМежду символами +"></input></td>';
			}
			
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th><th></th><th style="text-align: left;"><label_texts_header id="worktop_header"><b>Название столешниц в смете:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Производитель</b></label_texts_header></th><th><b>Текст</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < worktop_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "worktop";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 270px;" value="'+worktop_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 727px;" value="'+worktop_array[j][1]+'" title="Условные обозначения: \nname - Название\nlength - Длина\nwidth - Ширина\n<-> - Список размеров\nthickness - Толщина\nmaterial - Материал\nМежду символами ;"></input></td>';
			}
			
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th><th></th><th style="text-align: left;"><label_texts_header id="fartuk_header"><b>Название фартуков в смете:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Производитель</b></label_texts_header></th><th><b>Текст</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < fartuk_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "fartuk";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 270px;" value="'+fartuk_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 727px;" value="'+fartuk_array[j][1]+'" title="Условные обозначения: \nname - Название\nlength - Длина\nwidth - Ширина\n<-> - Мин и макс размеры\nthickness - Толщина\nmaterial - Материал\nМежду символами ;"></input></td>';
			}
			
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th><th></th><th style="text-align: left;"><label_texts_header id="frontal_header"><b>Название фасадов в смете:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Категория</b></label_texts_header></th><th><b>Текст</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < frontal_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "frontal";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 270px;" disabled value="'+frontal_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 727px;" value="'+frontal_array[j][1]+'" title="Условные обозначения: \nmaterial - Материал\nthickness - Толщина\nsupplier - Производитель\nmilling - Фрезеровка\npatina - Патина\nМежду символами ;"></input></td>';
			}
			
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th><th></th><th style="text-align: left;"><label_texts_header id="frontal_header"><b>Список фрезеровок:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Фрезеровка</b></label_texts_header></th><th><b>Список</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < freza_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "freza";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 270px;" value="'+freza_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><textarea style="width: 727px;" value="'+freza_array[j][1]+'">'+freza_array[j][1]+'</textarea></td>';
			}
			
		}
		
		else if ((s[i].split("=")[1].toLowerCase().indexOf("menu") != -1) && (s[i].split("=")[2] == 12)) { // Окно
			let row_main = begin_table(table,menu,s[i].split("=")[2]);
			let cell=row_main.insertCell(0);
			cell.innerHTML='<table id="window_table"></table>';
			let window_table = document.getElementById("window_table");
			let body = window_table.createTBody();
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th style="text-align: left;"><label_texts_header id="window_header"><b>Компоненты:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Категория</b></label_texts_header></th><th><b>Текст в окне</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < component_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "component";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_window_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_window_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 80px;" title="Element для вставки в модель\nОстальные для замены" value="'+component_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 80px;" value="'+component_array[j][1]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 330px; display: none;" disabled value=""></input></td>';
				row.innerHTML+='<td><input style="width: 130px; display: none;" disabled value=""></input></td>';
				row.innerHTML+='<td><input style="width: 360px; display: none;" disabled value=""></input></td>';
			}
			
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th></th>';
			header_row = body.insertRow(body.rows.length);
			header_row.innerHTML='<th style="text-align: left;"><label_texts_header id="window_header"><b>Материалы:</b></label_texts_header></th>';
			row = body.insertRow(body.rows.length);
			row.innerHTML='<th></th><th></th><th><label_texts_header><b>Категория</b></label_texts_header></th><th><b>Текст в окне</b></th><th><b>Папки</b></th><th><b>Стандарт</b></th><th><b>Стандартные текстуры</b></th>';
			row.style.borderBottom = "1px solid grey";
			for (var j = 0; j < material_array.length; j++) {
				row = body.insertRow(body.rows.length);
			    row.className = "material";
				row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_window_text(this);"></td>';
				row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_window_text(this);"></td>';
				row.innerHTML+='<td><input style="width: 80px;" value="'+material_array[j][0]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 80px;" value="'+material_array[j][1]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 330px;" value="'+material_array[j][2]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 130px;" value="'+material_array[j][3]+'"></input></td>';
				row.innerHTML+='<td><input style="width: 360px;" value="'+material_array[j][4]+'"></input></td>';
			}
		}
		
		else if ((s[i].split("=")[1].toLowerCase().indexOf("fastener_position") == -1) && (s[i].split("=")[1].toLowerCase().indexOf("fastener_dimension") == -1) && (s[i].split("=")[1].toLowerCase().indexOf("dimension_base") == -1) && (s[i].split("=")[1].toLowerCase().indexOf("type_hole") == -1) && (s[i].split("=")[1].toLowerCase().indexOf("groove_material") == -1) && (s[i].split("=")[1].toLowerCase().indexOf("groove_offset") == -1)) {
			let row = table.insertRow(table.rows.length);
			let cell=row.insertCell(0);
			if ((s[i].split("=")[1].toLowerCase().indexOf("edge_width") != -1) && (s[i].split("=")[1].toLowerCase().indexOf("edge_width_header") == -1)) {
				cell.innerHTML='<td><begin_label>от</begin_label><input class="mat_thick" id="mat_thick" type="text" value="' + s[i].split("=")[0] + '"></input><begin_label>до</begin_label><input class="mat_thick" id="mat_thick" type="text" value="' + s[i].split("=")[2] + '"></input></td>';
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_trim") != -1) {
				let color_param = s[i].split("=")[4];
				content='<td><begin_label>'+s[i].split("=")[0].slice(0,3)+'</begin_label><input class="edge_type" id="edge_type" type="text" value="' + s[i].split("=")[0].slice(4) + '"></input>';
				if (color_param && color_param != "no") {
					let rgb = s[i].split("=")[4].split(",");
					let color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
					content += '<input type="color" value="'+color+'" rgb_value="'+rgb+'" class="color_well" id="color_well">'
				}
				content += '</td>';
				cell.innerHTML = content;
				} else {
				cell.innerHTML='<td>' + s[i].split("=")[0] + '</td>';
				cell.style= "vertical-align: middle";
			}
			cell=row.insertCell(1);
			if (s[i].split("=")[1].indexOf("menu") != -1) {
				content='<td><input class="menu_row" number_menu="'+s[i].split("=")[2]+'" type="text" disabled="true" value="' + s[i].split("=")[0] + '"></input></td>';
				cell.innerHTML=content;
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_header") != -1) {
				row.setAttribute("menu_name",menu);
				content='<td><label_edge_header id="edge_header">'+ s[i].split("=")[2] + '</label_edge_header></td>';
				cell.innerHTML=content;
				cell=row.insertCell(2);
				content='<td><label_edge_header>'+ s[i].split("=")[3] + '</label_edge_header></td>';
				cell.innerHTML=content;
				if (s[i].split("=")[4]) {
					cell=row.insertCell(3);
					content='<td><label_edge_header>'+ s[i].split("=")[4] + '</label_edge_header></td>';
					cell.innerHTML=content;
				}
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_width_header") != -1) {
				row.setAttribute("menu_name",menu);
				row.style.borderTop = "1px solid grey"
				content='<td><label_edge_width class="edge_width_header" id="edge_width_header">'+ s[i].split("=")[2] + '</label_edge_width></td>';
				cell.innerHTML=content;
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_width") != -1) {
				row.setAttribute("menu_name",menu);
				content='<td><input class="edge_width" id="' + s[i].split("=")[1] + '" type="text" value="' + s[i].split("=")[3] + '"></input></td>';
				cell.innerHTML=content;
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_vendor_header") != -1) {
				row.setAttribute("menu_name",menu);
				row.style.borderTop = "1px solid grey";
				content='<td><label_edge_vendor id="edge_vendor_header">'+ s[i].split("=")[2] + '</label_edge_vendor></td>';
				cell.innerHTML=content;
				cell.style="padding-left: 5px";
				cell.style="padding-right: 38px";
				cell=row.insertCell(2);
				content='<td><label_edge_vendor>'+ s[i].split("=")[3] +'</label_edge_vendor></td>';
				cell.innerHTML=content;
				cell.style="padding-left: 5px";
				cell.style="padding-right: 5px";
				cell=row.insertCell(3);
				content='<td><label_edge_vendor>'+ s[i].split("=")[4] +'</label_edge_vendor></td>';
				cell.innerHTML=content;
				cell.style="padding-left: 5px";
				cell.style="padding-right: 5px";
				cell=row.insertCell(4);
				content='<td><label_edge_vendor>'+ s[i].split("=")[5] +'</label_edge_vendor></td>';
				cell.innerHTML=content;
				cell.style="padding-left: 5px";
				cell.style="padding-right: 5px";
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_vendor") != -1) {
				var option_array = ["1^1","2^2","3^3","4^4","5^5","6^6","7^7"];
				row.setAttribute("menu_name",menu);
				content='<td><input class="edge_vendor_size" id="edge_vendor" type="text" value="' + s[i].split("=")[2] + '"></input></td>';
				cell.innerHTML=content;
				cell=row.insertCell(2);
				content=select_content(0,s[i].split("=")[0]+"1",option_array,s[i].split("=")[3],"48","","");
				cell.innerHTML=content;
				cell=row.insertCell(3);
				content=select_content(0,s[i].split("=")[0]+"2",option_array,s[i].split("=")[4],"55","","");
				cell.innerHTML=content;
				cell=row.insertCell(4);
				content=select_content(0,s[i].split("=")[0]+"3",option_array,s[i].split("=")[5],"48","","");
				cell.innerHTML=content;
				} else if (s[i].split("=")[1].toLowerCase().indexOf("edge_trim") != -1) {
				row.setAttribute("menu_name",menu);
				if ((s[i].split("=")[1].indexOf("4trim") != -1) || (s[i].split("=")[1].indexOf("1trim") != -1) || (s[i].split("=")[1].indexOf("2trim") != -1)) {
					content='<td><input disabled="disabled" id="' + s[i].split("=")[1] + '" style="width: 54px;" class="edge_row" type="text" value="' + s[i].split("=")[2] + '"></input></td>';
					} else {
					content='<td><input id="' + s[i].split("=")[1] + '" style="width: 54px;" class="edge_row" type="text" value="' + s[i].split("=")[2] + '"></input></td>';
				}
				cell.innerHTML=content;
				cell=row.insertCell(2);
				content='<td><input id="' + s[i].split("=")[1] + '" style="width: 60px;" class="edge_row" type="text" value="' + s[i].split("=")[3] + '"></input></td>';
				cell.innerHTML=content;
				if (s[i].split("=")[4]) {
					cell=row.insertCell(3);
					if ((s[i].split("=")[1].indexOf("4trim") != -1) || (s[i].split("=")[1].indexOf("1trim") != -1) || (s[i].split("=")[1].indexOf("2trim") != -1)) {
						content='<td><input disabled="disabled" id="' + s[i].split("=")[1] + '" style="width: 36px;" class="edge_row" type="text" title="Символ в таблицах при экспорте\nРавно значению выше" value="' + s[i-1].split("=")[5] + '"></input></td>';
						} else {
						content='<td><input id="' + s[i].split("=")[1] + '" style="width: 36px;" class="edge_row" type="text" title="Символ в таблицах при экспорте\nНельзя использовать символ |" value="' + s[i].split("=")[5] + '"></input></td>';
					}
					cell.innerHTML=content;
				}
				} else if (s[i].split("=")[3].toLowerCase().indexOf("input") != -1) {
				row.setAttribute("menu_name",menu);
				content='<td><input id="' + s[i].split("=")[1];
				if (s[i].split("=")[1].indexOf("path") != -1) {
					content+='" title="'+s[i].split("=")[2]+'" type="text" value="' + s[i].split("=")[2] + '"</input></td>';
					} else {
					content+='" type="text" value="' + s[i].split("=")[2] + '"></input></td>';
				}
				cell.innerHTML=content;
				} else if (s[i].split("=")[3].toLowerCase().indexOf("select") != -1 ) {
				row.setAttribute("menu_name",menu);
				var option_array = s[i].split("=")[4].split("&");
				content=select_content(1,s[i].split("=")[1],option_array,s[i].split("=")[2],"208","","");
				cell.innerHTML=content;
			}
		}
	}
	
	$('.sortable-table tbody').sortable({
		helper: fixHelper
	});
	$('.sortable-table tbody').sortable({
		stop: function( event, ui ) {
			fastener_name_list();
			drawer_name_list();
			hinge_name_list();
			accessories_name_list();
			groove_name_list();
			lists_name_list();
			document.getElementById('apply').disabled = false;
			document.getElementById('apply').value = "Сохранить изменения";
		}
	});
	
	let row_main = table.insertRow(table.rows.length);
	let cell=row_main.insertCell(0);
	cell.innerHTML='<td>' + 'Инфо' + '</td>';
	row_main = table.insertRow(table.rows.length);
	row_main.setAttribute("menu_name","Инфо");
	cell=row_main.insertCell(0);
	cell.innerHTML='<td>Плагин SUF для проектирования мебели.</td>';
	row_main = table.insertRow(table.rows.length);
	row_main.setAttribute("menu_name","Инфо");
	cell=row_main.insertCell(0);
	cell.innerHTML='<td>Версия: <b>' + plugin_version + '</b></td>';
	
	let menu_items = document.getElementsByClassName("param_menu");
	let menu_name = "";
	for (var i = 0; i < menu_items.length; i++) {
		if (menu_items[i].classList.contains('active')) { menu_name = menu_items[i].innerText; break; }
	}
	show_menu_rows (menu_name);
	fastener_name_list();
	drawer_name_list();
	hinge_name_list();
	accessories_name_list();
	groove_name_list();
	lists_name_list();
}
function begin_table(table,name,number) {
    let row_main = table.insertRow(table.rows.length);
    let cell=row_main.insertCell(0);
    cell.innerHTML='<td>' + name + '</td>';
    cell=row_main.insertCell(1);
    cell.innerHTML='<td><input class="menu_row" number_menu="'+number+'" type="text" disabled="true" value="' + name + '"></input></td>';
    row_main = table.insertRow(table.rows.length);
    row_main.setAttribute("menu_name",name);
    return row_main;
}
function select_content(begin,id,option_array,value,width,options,class_name) {
    content='<td><select options="'+options+'" class="'+class_name+'" style="width: '+width+'px;" id="'+id+'" type="text">';
    for (var i = begin; i < option_array.length; i++) {
        content=content.concat('<option'+(option_array[i].split("^")[0]==value ? " selected" : "")+' value="'+option_array[i].split("^")[0]+'">'+option_array[i].split("^")[1]+'</option>');
	}
    content=content.concat('</select></td>');
    return content;
}
function edit_list_name(list) {
    let list_name = fastener_hash[active_fastener][list.id];
    if (!list_name) {list_name = ""}
    if (list_name.indexOf(';') == -1) { list_name = list_name+"~1"; }
    sketchup.get_data('edit_list_name|'+list.id+'|'+list_name+'|fastener');
}
function edit_hinge_name_list(list) {
	let active_hinge_map = hinge_hash[active_hinge_type][active_hinge_producer];
    let list_name = "";
    for (let key in active_hinge_map) {
        list_name += key.replace(/\|/g,",")+"~1;";
	}
    sketchup.get_data('edit_list_name|'+list.id+'|'+list_name+'|hinge');
}
function edit_lists(list) {
    let list_name = "";
    for (var i = 0; i < lists_array.length; i++) {
        if (lists_array[i][1]==list.id) {
            list_name = lists_array[i][3];
            break;
		}
	}
    if (list_name.indexOf(';') == -1) { list_name = list_name+"~1"; }
    sketchup.get_data('edit_list_name|'+list.id+'|'+list_name+'|lists');
}
function save_name_list(s) {
    let name_arr = s[1].split(';');
    if ((name_arr != []) && (name_arr[0] != "") && (s[2].indexOf('hinge') != -1)) {
	    let first_hinge_name = "";
        first_hinge_param = hinge_hash[active_hinge_type][active_hinge_producer][Object.keys(hinge_hash[active_hinge_type][active_hinge_producer])[0]]
        new_hinge_hash = {};
        for (var i = 0; i < name_arr.length-1; i++) {
            let name = name_arr[i].split('~')[0].replace(/,/g,"|");
			if (first_hinge_name == "") { first_hinge_name = name; }
            for (let key in hinge_hash[active_hinge_type][active_hinge_producer]) {
                if (hinge_hash[active_hinge_type][active_hinge_producer][name]) {new_hinge_hash[name] = hinge_hash[active_hinge_type][active_hinge_producer][name]; }
                else {
				    let clone = {};
                    for (let key in first_hinge_param) { clone[key] = first_hinge_param[key]; }
                    new_hinge_hash[name] = clone; new_hinge_hash[name]["name"] = name;
				}
			}
		}
		active_hinge_name = first_hinge_name;
        hinge_hash[active_hinge_type][active_hinge_producer] = new_hinge_hash;
	}
    if (s[2].indexOf('fastener') != -1) { fastener_hash[active_fastener][s[0]] = s[1]; }
    if (s[2].indexOf('lists') != -1) {
        for (var i = 0; i < lists_array.length; i++) {
            if (lists_array[i][1]==s[0]) { lists_array[i][3] = s[1]; }
		}
	}
    let count = 0;
    for (var i = 0; i < name_arr.length-1; i++) { count += +name_arr[i].split('~')[1] }
    document.getElementById(s[0]).value = 'Edit list ('+count+')';
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function param_list(table,map,class_name) {
    for (let k = 1; k <= 7; k++) {
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        content='<label>Axis'+k+'</label><input class="'+class_name+'" id="axis'+k+'" type="text" value="'+(map["axis"+k]?map["axis"+k]:"")+'"></input><label>d'+k+'</label><input class="'+class_name+'" id="diam'+k+'" type="text" value="'+(map["diam"+k]?map["diam"+k]:"")+'"></input><label>x</label><input class="'+class_name+'" id="depth'+k+'" type="text" value="'+(map["depth"+k]?map["depth"+k]:"")+'"></input><label>X'+k+'</label><input  title="+ в начале:\nк значению добавляется LenX" class="'+class_name+'" id="x'+k+'" type="text" value="'+(map["x"+k]?map["x"+k]:"")+'"></input><label>Y'+k+'</label><input  title="+ в начале:\nк значению добавляется LenY" class="'+class_name+'" id="y'+k+'" type="text" value="'+(map["y"+k]?map["y"+k]:"")+'"></input><label>Z'+k+'</label><input title="+ в начале:\nк значению добавляется LenZ" class="'+class_name+'" id="z'+k+'" type="text" value="'+(map["z"+k]?map["z"+k]:"")+'"></input><label>multiple'+k+'</label><input class="'+class_name+'" id="multiple'+k+'" type="text" value="'+(map["multiple"+k]?map["multiple"+k]:"")+'"></input><label>dist'+k+'</label><input class="'+class_name+'" id="multiple_dist'+k+'" type="text" value="'+(map["multiple_dist"+k]?map["multiple_dist"+k]:"")+'"></input><label>-</label><input class="'+class_name+'" id="list_name'+k+'" type="text" value="'+(map["list_name"+k]?map["list_name"+k]:"")+'"></input>';
        rgb = (map["color"+k]?map["color"+k].split("."):[100,100,100])
        let color = "#" + ((1 << 24) + (parseInt(rgb[0],10) << 16) + (parseInt(rgb[1],10) << 8) + parseInt(rgb[2],10)).toString(16).slice(1);
        content += '<input type="color" style="width: 35px" value="'+color+'" rgb_value="'+rgb+'" class="param_color" id="color'+k+'">';
        cell.innerHTML=content;
	}
}
function change_visible(fastener) {
    let visible = "true";
    let param = fastener_hash[fastener.getAttribute("fastener_name")];
    if (param["visible"] == "true") { param["visible"] = "false"; } else { param["visible"] = "true";}
    fastener_hash[fastener.getAttribute("fastener_name")] = param;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function change_active(fastener) {
    for (let key in fastener_hash) { fastener_hash[key]["active"] = "false"; }
    let param = fastener_hash[fastener.getAttribute("fastener_name")];
    param["active"] = "true";
    fastener_hash[fastener.getAttribute("fastener_name")] = param;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function fastener_name_list() {
    fastener_name_list_array = [];
    let fastener_name_table = document.getElementById("fastener_name_table");
    for (let row of fastener_name_table.rows) {
        fastener_name_list_array = fastener_name_list_array.concat(row.cells[1].innerText);
	}
}
function copy_fastener(fastener) {
    let e_row = fastener.parentNode.parentNode;
    let row_index = e_row.rowIndex+1;
    let fastener_name = fastener.getAttribute("fastener_name");
    for (let key in fastener_hash) { fastener_hash[key]["active"] = "false"; }
    let param = fastener_hash[fastener_name];
    fastener_name_list_array.splice(row_index,0,fastener_name+"_copy");
    let new_fastener_hash = {};
    for (let fastener_name_of_list of fastener_name_list_array) {
        new_param = {};
        if (fastener_name_of_list == fastener_name+"_copy") {
            new_fastener_hash[fastener_name_of_list] = new_param;
            for (let key in fastener_hash[fastener_name]) {
                new_param[key] = fastener_hash[fastener_name][key];
			}
            new_param["fastener_name"] = fastener_name+"_copy";
            new_param["active"] = "true";
            } else {
            new_fastener_hash[fastener_name_of_list] = fastener_hash[fastener_name_of_list];
		} 
	}
    fastener_hash = new_fastener_hash;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_fastener(fastener) {
    let e_row = fastener.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let fastener_name = fastener.getAttribute("fastener_name");
    fastener_name_list_array.splice(row_index,1);
    if (fastener_hash[fastener_name]["active"] == "true") {
        key_index = Object.keys(fastener_hash).indexOf(fastener_name);
        delete fastener_hash[fastener_name];
        fastener_hash[Object.keys(fastener_hash)[key_index]]["active"] = "true";
	} else { delete fastener_hash[fastener_name]; }
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function new_template(e) {
    let template_name = e.getAttribute("template_name");
    let type = template_name.replace("_common","");
    let type_count = -1;
    var row_index = template_list_array.indexOf(template_name);
    for (let template_name_of_list of template_list_array) {
        if (template_name_of_list.indexOf(type) != -1) { type_count += 1; }
	}
    template_list_array.splice(row_index+type_count,0,"Новая Панель");
    let new_template_hash = {};
    for (var i = 0; i < template_list_array.length; i++) {
        let template_name_of_list = template_list_array[i];
        if (template_name_of_list == "Новая Панель") {
            let arr = template_hash[template_name].split("=");
            template_list_array[i] = arr[1].replace("_common","")+type_count;
            new_template_hash[arr[1].replace("_common","")+type_count] = "Новая Панель="+arr[1].replace("_common","")+type_count+"="+arr[2]+"="+arr[3]+"="+arr[4]+"="+arr[5]+"="+arr[6]+"="+arr[7]+"="+arr[8]+"="+arr[9];
		} 
        else { new_template_hash[template_name_of_list] = template_hash[template_name_of_list]; }
	}
    template_hash = new_template_hash;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_template(e) {
    let template_name = e.getAttribute("template_name");
    var row_index = template_list_array.indexOf(template_name);
    template_list_array.splice(row_index,1);
    delete template_hash[template_name];
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
$(document).on( "change", ".template_input", function() {
    if (this.value != "") {
        let template_name = this.id.substring(6);
        let arr = template_hash[template_name].split("=");
        template_hash[template_name] = this.value+"="+arr[1]+"="+arr[2]+"="+arr[3]+"="+arr[4]+"="+arr[5]+"="+arr[6]+"="+arr[7];
	}
})
$(document).on( "change", ".change_template", function() {
    let e_row = this.parentNode.parentNode;
    e_row.cells[3].childNodes[0].value = (template_value_array[this.value]?template_value_array[this.value]:"");
})
$(document).on( "change", ".change_template2", function() {
    let e_row = this.parentNode.parentNode;
    e_row.cells[7].childNodes[0].value = (template_value_array[this.value]?template_value_array[this.value]:"");
})
$(document).on( "change", ".template_checkbox", function() {
	console.log(this.id)
	let neighboring_id = this.id.slice(0, -1) + (this.id.endsWith("1") ? "2" : "1");
    document.getElementById(neighboring_id).checked = false;
})
function drawer_name_list() {
    drawer_name_list_array = [];
    let drawer_name_table = document.getElementById("drawer_name_table");
    let rows = drawer_name_table.rows;
    for (var i = 0; i < rows.length; i++) {
        drawer_name_list_array = drawer_name_list_array.concat(rows[i].cells[0].innerText);
	}
}
function copy_drawer(drawer) {
	let e_row = drawer.parentNode.parentNode;
	let row_index = e_row.rowIndex+1;
	let drawer_name = drawer.getAttribute("drawer_name");
	let param = drawer_hash[drawer_name];
	drawer_name_list_array.splice(row_index,0,drawer_name+"_copy")
	active_drawer = drawer_name+"_copy";
	let new_drawer_hash = {};
	for (let drawer_name_of_list of drawer_name_list_array) {
		new_param = {};
		if (drawer_name_of_list == drawer_name+"_copy") {
			new_drawer_hash[drawer_name_of_list] = new_param;
			for (let key in drawer_hash[drawer_name]) {
				new_param[key] = drawer_hash[drawer_name][key];
			}
			} else {
			new_drawer_hash[drawer_name_of_list] = drawer_hash[drawer_name_of_list];
		} 
	}
	drawer_hash = new_drawer_hash;
	parameters(all_parameters,active_hinge_type);
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
}
function delete_drawer(drawer) {
    let e_row = drawer.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let drawer_name = drawer.getAttribute("drawer_name");
    drawer_name_list_array.splice(row_index,1);
    delete drawer_hash[drawer_name];
    if (active_drawer == drawer_name) { active_drawer = ""; }
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function accessories_name_list() {
    accessories_name_list_array = [];
    let accessories_name_table = document.getElementById("accessories_name_table");
    let rows = accessories_name_table.rows;
    for (var i = 0; i < rows.length; i++) {
        accessories_name_list_array = accessories_name_list_array.concat(rows[i].cells[0].innerText);
	}
}
function copy_accessories(accessories) {
    let e_row = accessories.parentNode.parentNode;
    let row_index = e_row.rowIndex+1;
    let accessories_name = accessories.getAttribute("accessories_name");
    let param = accessories_hash[accessories_name];
    accessories_name_list_array.splice(row_index,0,accessories_name+"_copy")
    active_accessories = accessories_name+"_copy";
    let new_accessories_hash = {};
    for (let accessories_name_of_list of accessories_name_list_array) {
        new_param = {};
        if (accessories_name_of_list == accessories_name+"_copy") {
            new_accessories_hash[accessories_name_of_list] = new_param;
            for (let key in accessories_hash[accessories_name]) {
                new_param[key] = accessories_hash[accessories_name][key];
			}
            } else {
            new_accessories_hash[accessories_name_of_list] = accessories_hash[accessories_name_of_list];
		} 
	}
    accessories_hash = new_accessories_hash;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_accessories(accessories) {
    let e_row = accessories.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let accessories_name = accessories.getAttribute("accessories_name");
    accessories_name_list_array.splice(row_index,1);
    delete accessories_hash[accessories_name];
    if (active_accessories == accessories_name) { active_accessories = ""; }
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function groove_name_list() {
    groove_name_list_array = [];
    let groove_name_table = document.getElementById("groove_name_table");
    let rows = groove_name_table.rows;
    for (var i = 0; i < rows.length; i++) {
        groove_name_list_array = groove_name_list_array.concat(rows[i].cells[0].innerText);
	}
}
function copy_groove(groove) {
    let e_row = groove.parentNode.parentNode;
    let row_index = e_row.rowIndex+1;
    let groove_name = groove.getAttribute("groove_name");
    let param = groove_hash[groove_name];
    groove_name_list_array.splice(row_index,0,groove_name+"_copy")
    active_groove = groove_name+"_copy";
    let new_groove_hash = {};
    for (let groove_name_of_list of groove_name_list_array) {
        new_param = {};
        if (groove_name_of_list == groove_name+"_copy") {
            new_groove_hash[groove_name_of_list] = new_param;
            for (let key in groove_hash[groove_name]) {
                new_param[key] = groove_hash[groove_name][key];
			}
            } else {
            new_groove_hash[groove_name_of_list] = groove_hash[groove_name_of_list];
		} 
	}
    groove_hash = new_groove_hash;
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_groove(groove) {
    let e_row = groove.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let groove_name = groove.getAttribute("groove_name");
    groove_name_list_array.splice(row_index,1);
    delete groove_hash[groove_name];
    if (active_groove == groove_name) { active_groove = ""; }
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
$(document).on( "change", ".groove_input", function() {
	if (this.value != " ") {
		let new_name = this.value;
		if ((this.id=="groove_name")&&(new_name!=active_groove)) {
			new_name = new_name.split(' ').filter(n => n).join(' ');
			new_name = new_name.replace(/,/g,"|");
			new_groove_hash = {};
			for (let key in groove_hash) {
				if (key==active_groove) { new_groove_hash[new_name] = groove_hash[active_groove]; }
				else { new_groove_hash[key] = groove_hash[key]; }
			}
			groove_hash = new_groove_hash;
			groove_name_list_array.forEach(function(item, i) { if (item == active_groove) groove_name_list_array[i] = new_name; });
			active_groove=new_name;
			} else {
			groove_hash[active_groove][this.id] = new_name;
			canvas = document.getElementById('groove_image');
			draw_lines(canvas,groove_hash[active_groove])
		}
	}
});
function draw_lines(canvas,pts){
	const ctx = canvas.getContext('2d');
	ctx.clearRect(0, 0, canvas.width, canvas.height);
	ctx.beginPath();
	ctx.fillStyle = "white";
	ctx.fillRect(0, 0, 820, 500);
	ctx.stroke();
	ctx.font = '20px Arial';
	ctx.fillStyle = 'Black';
	ctx.fillText('0', 50, 90);
	ctx.fillText('X', 130, 90);
	ctx.fillText('Y', 50, 160);
	ctx.lineWidth = 1; // толщина линии
	ctx.strokeStyle = "black";
	ctx.beginPath();
	// оси координат
	ctx.moveTo(130, 100); //передвигаем перо
	ctx.lineTo(80, 100); //рисуем линию
	ctx.lineTo(80, 150); //рисуем линию
	// правая стрелка
	ctx.moveTo(120, 95); //передвигаем перо
	ctx.lineTo(130, 100); //рисуем линию
	ctx.lineTo(120, 105); //рисуем линию
	// левая стрелка
	ctx.moveTo(75, 140); //передвигаем перо
	ctx.lineTo(80, 150); //рисуем линию
	ctx.lineTo(85, 140); //рисуем линию
	// панель
	y2 = 120+thickness*10
	ctx.moveTo(700, 120); //передвигаем перо
	ctx.lineTo(100, 120); //рисуем линию
	ctx.lineTo(100, y2); //рисуем линию
	ctx.lineTo(700, y2); //рисуем линию
	ctx.bezierCurveTo(680, 120+(y2-120)/3, 720, 120+((y2-120)/3)*2, 700, 120);
	ctx.stroke();
	// паз
	ctx.lineWidth = 3; // толщина линии
	ctx.strokeStyle = "red";
	ctx.beginPath();
	x_arr = [];
	y_arr = [];
	for (let key in pts) {
		if (key.indexOf("x")!=-1) {x_arr.push(pts[key])}
		if (key.indexOf("y")!=-1) {y_arr.push(pts[key])}
	}
	ctx.moveTo(100+x_arr[0]*10, 120+y_arr[0]*10); //передвигаем перо
	for (var i = 1; i < x_arr.length; i++) {
		ctx.lineTo(100+x_arr[i]*10, 120+y_arr[i]*10); //рисуем линию
	}
	ctx.lineTo(100+x_arr[0]*10, 120+y_arr[0]*10); //рисуем линию
	ctx.stroke();
}
$(document).on( "change", "#thickness", function() {
	thickness = this.value;
	canvas = document.getElementById('groove_image');
	draw_lines(canvas,groove_hash[active_groove]);
});
function lists_name_list() {
    lists_name_array = [];
    let lists_table = document.getElementById("lists_table");
    let rows = lists_table.rows;
    for (var i = 1; i < rows.length; i++) {
        lists_name_array = lists_name_array.concat(rows[i].cells[3].childNodes[0].value);
	}
    let new_list_array = [];
    for (var i = 0; i < lists_name_array.length; i++) {
        for (var j = 0; j < lists_array.length; j++) {
            if (lists_array[j][0]==lists_name_array[i]) {
                new_list_array.push(lists_array[j]);
			}
		}
	}
    lists_array = new_list_array;
}
function copy_list(list) {
    let e_row = list.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let lists_name = list.getAttribute("lists_name");
    let new_arr = [];
    let index = 0;
	//console.log(lists_array)
    for (var i = 0; i < lists_array.length; i++) {
        if (lists_array[i][1]==lists_name) {
            index = i+1;
            new_arr = Array.from(lists_array[i]);
            break;
		}
	}
    new_arr[0] = new_arr[0]+"_copy";
    lists_array.splice(index,0,new_arr);
    for (var i = 0; i < lists_array.length; i++) {
        lists_array[i][1] = "lists"+i.toString();
	}
    parameters(all_parameters,active_hinge_type);
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_list(list) {
    let e_row = list.parentNode.parentNode;
    let row_index = e_row.rowIndex;
    let lists_name = list.getAttribute("lists_name");
    if (lists_array.length>1){
        lists_name_array.splice(row_index-1,1);
        for (var i = 0; i < lists_array.length; i++) {
            if (lists_array[i][1]==lists_name) {
                lists_array.splice(i, 1);
			}
		}
        for (var i = 0; i < lists_array.length; i++) {
            lists_array[i][1] = "lists"+i.toString();
		}
        parameters(all_parameters,active_hinge_type);
        document.getElementById('apply').disabled = false;
        document.getElementById('apply').value = "Сохранить изменения";
	}
}


function copy_text(text) {
    let e_row = text.parentNode.parentNode;
	let row_index = e_row.rowIndex;
	let e_row_class = e_row.className;
	let texts_table = document.getElementById("texts_table");
    if (!e_row.cells[2].childNodes[0].disabled){
		let row = texts_table.insertRow(row_index+1);
		row.className = e_row_class;
		row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_text(this);"></td>';
		row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_text(this);"></td>';
		row.innerHTML+='<td><input style="width: 270px;" value="'+e_row.cells[2].childNodes[0].value+"_copy"+'"></input></td>';
		if (e_row_class == "freza") {
			row.innerHTML+='<td><textarea style="width: 727px;" value="'+e_row.cells[3].childNodes[0].value+'">'+e_row.cells[3].childNodes[0].value+'</textarea></td>';
			} else if (e_row_class == "frontal") {
			row.innerHTML+='<td><input style="width: 727px;" value="'+e_row.cells[3].childNodes[0].value+'" title="Условные обозначения: \nmaterial - Материал\nthickness - Толщина\nsupplier - Производитель\nmilling - Фрезеровка\npatina - Патина\nМежду символами ;"></input></td>';
			} else {
			row.innerHTML+='<td><input style="width: 727px;" value="'+e_row.cells[3].childNodes[0].value+'" title="Условные обозначения: \nname - Название\nlength - Длина\nwidth - Ширина\n<-> - Список размеров\nthickness - Толщина\nmaterial - Материал\nМежду символами ;"></input></td>';
		}
	}
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_text(text) {
    let e_row = text.parentNode.parentNode;
	let row_index = e_row.rowIndex;
	let e_row_class = e_row.className;
    let texts_rows = document.getElementsByClassName(e_row_class);
	let texts_table = document.getElementById("texts_table");
    if ((texts_rows.length>1)&&(!e_row.cells[2].childNodes[0].disabled)){
	    texts_table.deleteRow(row_index);
        document.getElementById('apply').disabled = false;
        document.getElementById('apply').value = "Сохранить изменения";
	}
}
function copy_window_text(text) {
    let e_row = text.parentNode.parentNode;
	let row_index = e_row.rowIndex;
	let e_row_class = e_row.className;
	let window_table = document.getElementById("window_table");
    if (!e_row.cells[2].childNodes[0].disabled){
		let row = window_table.insertRow(row_index+1);
		row.className = e_row_class;
		row.innerHTML+='<td><img title="Скопировать" class="copy_image" visible="true" src="./cont/style/new_by_copy.png" alt="select"  onclick="copy_window_text(this);"></td>';
		row.innerHTML+='<td><img title="Удалить" class="delete_image" visible="true" src="./cont/style/delete_element.png" alt="select" onclick="delete_window_text(this);"></td>';
		row.innerHTML+='<td><input style="width: 80px;" value="'+e_row.cells[2].childNodes[0].value+"_copy"+'"></input></td>';
		row.innerHTML+='<td><input style="width: 80px;" value="'+e_row.cells[3].childNodes[0].value+'"></input></td>';
	}
    document.getElementById('apply').disabled = false;
    document.getElementById('apply').value = "Сохранить изменения";
}
function delete_window_text(text) {
    let e_row = text.parentNode.parentNode;
	let row_index = e_row.rowIndex;
	let e_row_class = e_row.className;
    let texts_rows = document.getElementsByClassName(e_row_class);
	let window_table = document.getElementById("window_table");
    if ((texts_rows.length>1)&&(!e_row.cells[2].childNodes[0].disabled)){
	    window_table.deleteRow(row_index);
        document.getElementById('apply').disabled = false;
        document.getElementById('apply').value = "Сохранить изменения";
	}
}
$(document).on( "change", ".lists_input", function() {
    let e_cell = this.parentNode;
    let lists_name = this.getAttribute("lists_name");
    for (var i = 0; i < lists_array.length; i++) {
        if (lists_array[i][1]==lists_name) {
            if (e_cell.cellIndex==3) { lists_array[i][0] = this.value; }
            else if (e_cell.cellIndex==4) { lists_array[i][2] = this.value; }
		}
	}
});
$(document).on( "change", ".lists_select", function() {
    let lists_name = this.id.substring(7);
    for (var i = 0; i < lists_array.length; i++) {
        if (lists_array[i][1]==lists_name) {
            if (this.id.indexOf("group")!=-1){ lists_array[i][4] = this.value; }
            else if (this.id.indexOf("smeta")!=-1){ lists_array[i][5] = this.value; }
            else if (this.id.indexOf("export")!=-1){ lists_array[i][6] = this.value; }
            else if (this.id.indexOf("price")!=-1){ lists_array[i][7] = this.value; }
		}
	}
});
$(document).on( "change", ".fastener_input", function() {
    if (this.value == "") { delete fastener_hash[active_fastener][this.id]; }
    else if (this.value != " ") { fastener_hash[active_fastener][this.id] = this.value; }
});
$(document).on( "change", ".fastener_color", function() {
    let bigint = parseInt(this.value.split('#')[1], 16);
    let r = (bigint >> 16) & 255;
    let g = (bigint >> 8) & 255;
    let b = bigint & 255;
    rgb = r+"."+g+"."+b;
    fastener_hash[active_fastener][this.id] = rgb;
});
$(document).on( "change", ".param_color", function() {
    let bigint = parseInt(this.value.split('#')[1], 16);
    let r = (bigint >> 16) & 255;
    let g = (bigint >> 8) & 255;
    let b = bigint & 255;
    rgb = r+"."+g+"."+b;
    let table_id = this.parentNode.parentNode.parentNode.parentNode.id;
    if (table_id=="cup_plate_table") {
        hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name][this.id] = rgb;
        if ((this.id=="color2") && ("color3" in hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name])) { hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name]["color3"] = rgb; }
	}
    else if (table_id=="drawer_table") { drawer_hash[active_drawer][active_drawer_depth][this.id] = rgb;}
    else if (table_id=="accessories_table") { accessories_hash[active_accessories][this.id] = rgb;}
});
$(document).on( "click", "#copy_parameters", function() {
    let table_id = this.parentNode.parentNode.parentNode.parentNode.id;
    if (table_id=="hinge_table") { copy_board(hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name]);}
    else if (table_id=="drawer_table") { copy_board(drawer_hash[active_drawer][active_drawer_depth]);}
    else if (table_id=="accessories_table") { copy_board(accessories_hash[active_accessories]);}
});
function copy_board(s) {
    clipboard_text = param_array("",s);
}
$(document).on( "click", "#paste_parameters", function() {
    let table_id = this.parentNode.parentNode.parentNode.parentNode.id;
    holes = {};
    holes = hole_map(holes,clipboard_text);
    holes["name"] = hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name]["name"];
    if (table_id=="hinge_table") { hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name] = holes;}
    if (table_id=="drawer_table") { drawer_hash[active_drawer][active_drawer_depth] = holes;}
    if (table_id=="accessories_table") { accessories_hash[active_accessories] = holes;}
    parameters(all_parameters);
});
function change_active_hinge_type(elem) {
    active_hinge_type = elem.getAttribute("hinge_producer");
    active_hinge_name="";
    parameters(all_parameters,active_hinge_type);
}
function change_active_hinge_producer(elem) {
    let row = elem.parentNode.parentNode;
    let cell = row.cells[1].childNodes[0];
    let elm_tag = cell.childNodes[0].tagName;
    if(elm_tag && elm_tag.toLowerCase() == 'input')	{return false;}
    active_hinge_producer = elem.getAttribute("hinge_producer");
    active_hinge_name="";
    parameters(all_parameters,active_hinge_type,active_hinge_producer);
}
function change_hinge_name(elem) {
    if (elem.value != " ") {
        active_hinge_name = elem.value.replace(/,/g,"|");
        parameters(all_parameters,active_hinge_type,active_hinge_producer);
	}
}
$(document).on( "change", ".hinge_input", function() {
    if (this.value != " ") {
        new_value = this.value.split(' ').filter(n => n).join(' ');
		if ((this.id.indexOf("diam")!=-1)||(this.id.indexOf("depth")!=-1)||(this.id.indexOf("multiple_dist")!=-1)||(this.id=="C")||(this.id=="x1")||(this.id=="N")||(this.id=="A")||(this.id=="n1")||(this.id=="n2")) { new_value = new_value.replace(/,/g,"."); }
        let param_name = this.id;
        let active_hinge = hinge_hash[active_hinge_type][active_hinge_producer][active_hinge_name];
        if (this.id=="A") {
		    param_name = "y1";
		    if (active_hinge_type.indexOf("фальш")!=-1) {
				new_value = (-1*(+new_value+22)).toString();
				} else {
				new_value = (-1*(+new_value+37)).toString();
			}
		}
        else if (this.id=="N") {
			active_hinge["axis2"] = active_hinge["axis1"];
			if (active_hinge["axis1"]=="-Y") {
				active_hinge["y2"] = active_hinge["y1"];
				active_hinge["multiple2"] = "2";
				param_name = "x2";
				new_value = +new_value+(active_hinge["x1"]?(+active_hinge["x1"]):0);
				} else {
				active_hinge["x2"] = "0";
				active_hinge["multiple2"] = "2";
				param_name = "y2";
				new_value = +active_hinge["y1"]-(+new_value);
			}
		}
		else if (this.id=="multiple_dist1") { active_hinge["z1"] = (-1*(+new_value/2)).toString(); }
		
        else if (this.id=="multiple_dist2") { active_hinge["z2"] = (-1*(+new_value/2)).toString(); }
        else if (this.id=="n1") {param_name = "y1"; new_value = +new_value-37; }
		
		else if (this.id=="diam3") {active_hinge["diam2"] = new_value.toString(); active_hinge["axis2"] = "-X"; }
		else if (this.id=="depth3") {active_hinge["depth2"] = new_value.toString(); active_hinge["axis2"] = "-X"; }
        else if (this.id=="n2") {param_name = "y2"; new_value = +new_value-20; active_hinge["x2"] = "0"; active_hinge["z2"] = "0"; active_hinge["multiple2"] = "1"; active_hinge["multiple_dist2"] = "0";}
		else if (this.id=="y3") { active_hinge["axis3"] = "-X"; active_hinge["x3"] = "0"; active_hinge["z3"] = "0"; active_hinge["multiple3"] = "1"; active_hinge["multiple_dist3"] = "0";}
		
        else if (this.id=="hinge_producer") {param_name = "name"; }
        active_hinge[param_name] = new_value.toString();
		console.log(active_hinge)
	}
});
function edit_hinge_producer(elem) {
	let row = elem.parentNode.parentNode;
	let row_index = row.rowIndex;
	let cell = row.cells[1].childNodes[0];
	let elm_tag = cell.childNodes[0].tagName;
	if(elm_tag && elm_tag.toLowerCase() == 'input')	{return false;}
	let active_hinge_hash = hinge_hash[active_hinge_type];
	let old_val = cell.innerHTML;
	let old_param = hinge_hash[active_hinge_type][old_val];
	$(cell).empty().append('<input type="text" id="edit" value="'+old_val+'" />');
	$('#edit').focus();
	$('#edit').select();
	$('#edit').blur(function()	{
		let val = $(this).val();
		val = val.split(' ').filter(n => n).join(' ');
		$(this).parent().empty().html(val);
		delete hinge_hash[active_hinge_type][old_val];
		hinge_name_list_array.splice(hinge_name_list_array.indexOf(old_val),1);
		hinge_hash[active_hinge_type][val] = old_param;
		hinge_name_list_array.splice(row_index-1,0,val);
		hinge_name_list();
		if(active_hinge_producer==old_val){active_hinge_producer=val;}
	});
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
}
function copy_hinge(hinge) {
	let row = hinge.parentNode.parentNode;
	let row_index = row.rowIndex;
	let hinge_producer = hinge.getAttribute("hinge_producer");
	let active_hinge_hash = hinge_hash[active_hinge_type];
	hinge_param = {};
	for (let i = 0; i < hinge_name_list_array.length; i++) {
		hinge_param[hinge_name_list_array[i]] = active_hinge_hash[hinge_name_list_array[i]];
		if (hinge_name_list_array[i]==hinge_producer){hinge_param[hinge_producer+"_copy"] = active_hinge_hash[hinge_name_list_array[i]];}
	}
	hinge_name_list_array.splice(row_index,0,hinge_producer+"_copy");
	active_hinge_producer = hinge_producer+"_copy";
	hinge_hash[active_hinge_type] = hinge_param;
	active_hinge_name = "";
	parameters(all_parameters,active_hinge_type);
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
}
function delete_hinge(hinge) {
	let hinge_producer = hinge.getAttribute("hinge_producer");
	delete hinge_hash[active_hinge_type][hinge_producer];
	active_hinge_name = "";
	parameters(all_parameters,active_hinge_type);
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
}
function hinge_name_list() {
	hinge_name_list_array = [];
	let hinge_producer_table = document.getElementById("hinge_producer_table");
	let rows = hinge_producer_table.rows;
	for (var i = 1; i < rows.length; i++) {
		hinge_name_list_array = hinge_name_list_array.concat(rows[i].cells[1].innerText);
	}
	let active_hinge_hash = hinge_hash[active_hinge_type];
	hinge_param = {};
	for (let i = 0; i < hinge_name_list_array.length; i++) {
		hinge_param[hinge_name_list_array[i]] = active_hinge_hash[hinge_name_list_array[i]];
	}
	hinge_hash[active_hinge_type] = hinge_param;
}
function change_active_drawer(elem) {
	active_drawer = elem.getAttribute("drawer_name");
	parameters(all_parameters);
}
function change_active_drawer_depth(elem) {
	active_drawer_depth = elem.value;
	parameters(all_parameters);
}
function change_symmetrical_holes(elem) {
	symmetrical_holes = elem.value;
	drawer_hash[active_drawer]["symmetrical_holes"] = symmetrical_holes;
	parameters(all_parameters);
}
function change_active_accessories(elem) {
	active_accessories = elem.getAttribute("accessories_name");
	parameters(all_parameters);
}
function change_active_groove(elem) {
	active_groove = elem.getAttribute("groove_name");
	parameters(all_parameters);
}
$(document).on( "change", ".depth_list_input", function() {
	if (this.value != " ") {
		let depth_list = this.value;
		let new_drawer_hash = {};
		new_drawer_hash["depth_list"] = depth_list;
		new_drawer_hash["symmetrical_holes"] = drawer_hash[active_drawer]["symmetrical_holes"];
		let depth_list_arr = depth_list.split("&");
		for (var i = 0; i < depth_list_arr.length; i++) {
			if (drawer_hash[active_drawer][depth_list_arr[i]]){new_drawer_hash[depth_list_arr[i]] = drawer_hash[active_drawer][depth_list_arr[i]]}
			else{new_drawer_hash[depth_list_arr[i]] = {}}
		}
		drawer_hash[active_drawer] = new_drawer_hash;
	}
});
$(document).on( "change", ".drawer_input", function() {
	if (this.value != " ") {
		let new_name = this.value;
		if ((this.id=="drawer_name")&&(new_name!=active_drawer)) {
			new_name = new_name.split(' ').filter(n => n).join(' ');
			new_name = new_name.replace(/,/g,"|");
			new_drawer_hash = {};
			for (let key in drawer_hash) {
				if (key==active_drawer) { new_drawer_hash[new_name] = drawer_hash[active_drawer]; }
				else { new_drawer_hash[key] = drawer_hash[key]; }
			}
			drawer_hash = new_drawer_hash;
			drawer_name_list_array.forEach(function(item, i) { if (item == active_drawer) drawer_name_list_array[i] = new_name; });
			active_drawer=new_name;
		}
		else {
			if (drawer_hash[active_drawer][active_drawer_depth]===undefined) { drawer_hash[active_drawer][active_drawer_depth] = {}; }
			drawer_hash[active_drawer][active_drawer_depth][this.id] = new_name;
		}
	}
});
$(document).on( "change", ".accessories_input", function() {
	if (this.value != " ") {
		let new_name = this.value;
		if ((this.id=="accessories_name")&&(new_name!=active_accessories)) {
			new_name = new_name.split(' ').filter(n => n).join(' ');
			new_name = new_name.replace(/,/g,"|");
			new_accessories_hash = {};
			for (let key in accessories_hash) {
				if (key==active_accessories) { new_accessories_hash[new_name] = accessories_hash[active_accessories]; }
				else { new_accessories_hash[key] = accessories_hash[key]; }
			}
			accessories_hash = new_accessories_hash;
			accessories_name_list_array.forEach(function(item, i) { if (item == active_accessories) accessories_name_list_array[i] = new_name; });
			active_accessories=new_name;
			} else {
			accessories_hash[active_accessories][this.id] = new_name;
		}
	}
});
function show_menu_rows (menu_name) {
	if (menu_name != "") {
		let table = document.getElementById("parameter_table");
		for (var i = 0; i < table.rows.length; i++) {
			table.rows[i].style.display = "none";
			let row_menu_name = table.rows[i].getAttribute("menu_name");
			if (row_menu_name == menu_name) { table.rows[i].style.display = "block"; }
		}
	}
}
$(document).on( "click", ".param_menu", function() {
	$(".param_menu").each(function () { $(this).removeClass("active"); });
	$(this).addClass("active");
	let menu_name = $(this).text();
	show_menu_rows (menu_name);
});
$(document).on( "focus", "input", function() {
	if (this.id.indexOf("path") != -1) {
		this.blur();
		$(".param_menu").each(function () { if ($(this).text() == "Общие") { $(this).addClass("active"); show_menu_rows ("Общие"); }});
		sketchup.get_data("change_path"+this.id+"=>"+this.parentNode.parentNode.cells[0].innerText+"=>"+this.value);
		} else if (this.id.indexOf("file") != -1) {
		this.blur();
		$(".param_menu").each(function () { if ($(this).text() == "Общие") { $(this).addClass("active"); show_menu_rows ("Общие"); }});
		sketchup.get_data("change_file"+this.id+"=>"+this.parentNode.parentNode.cells[0].innerText+"=>"+this.value);
	    } else if (this.id.indexOf("third_fastener") != -1) {
		this.blur();
		$(".param_menu").each(function () { if ($(this).text() == "Шаблон") { $(this).addClass("active"); show_menu_rows ("Шаблон"); }});
		sketchup.get_data("edit_additional_fastener"+this.id+"=>"+this.parentNode.parentNode.cells[0].innerText+"=>"+this.value);
	}
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
});
$(document).on( "focus", "textarea", function() {
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
});
function save_additional_fastener(additional_fastener) {
	document.getElementById('third_fastener').value = additional_fastener;
}
$(document).on( "change", "select", function() {
	if (this.id.indexOf("param_profile") != -1) {
		if (this.value.indexOf("New") != -1) {
			sketchup.get_data("new_profile");
			} else {
			sketchup.get_data("change_profile=>"+this.value);
		}
	}
	document.getElementById('apply').disabled = false;
	document.getElementById('apply').value = "Сохранить изменения";
});
function add_new_profile(new_profile) {
	var select = document.getElementById('param_profile');
	var opt = document.createElement('option');
    opt.value = new_profile;
    opt.innerHTML = new_profile;
	opt.setAttribute('selected', true);
    select.appendChild(opt);
}
function save_changes(read="true") {
	var table = document.getElementById("parameter_table");
	var rows = table.rows;
	var str = "save_changes";
	for (var i = 0; i < rows.length; i++) {
		if (rows[i].cells[1]) {
			var tagName = rows[i].cells[1].childNodes[0].tagName;
			var label = rows[i].cells[0].innerText;
			var tr_td_id = rows[i].cells[1].childNodes[0].id;
			var value = rows[i].cells[1].childNodes[0].value;
			let class_name = rows[i].cells[1].childNodes[0].className;
			if ((tr_td_id.indexOf("waste") != -1) || (tr_td_id.indexOf("install_cost") != -1) || (tr_td_id.indexOf("prepayment") != -1)) {
				if (value.slice(-1) != "%") { value = value + "%" }
			}
			if (class_name=="menu_row") {
				let number_menu = rows[i].cells[1].childNodes[0].getAttribute("number_menu");
				str += "|"+label+"="+class_name+"="+number_menu;
				} else if (tr_td_id.indexOf("edge_header") != -1) {
				str += "|"+label+"="+tr_td_id+"="+rows[i].cells[1].innerText+"="+rows[i].cells[2].innerText+"="+rows[i].cells[3].innerText;
				} else if (tr_td_id.indexOf("edge_trim") != -1) {
				let rgb = "no";
				let color_value = rows[i].cells[0].childNodes[2];
				if (color_value) {
					let bigint = parseInt(color_value.value.split('#')[1], 16);
					let r = (bigint >> 16) & 255;
					let g = (bigint >> 8) & 255;
					let b = bigint & 255;
					rgb = r+","+g+","+b;
				} 
				str += "|"+label+" "+rows[i].cells[0].childNodes[1].value+"="+tr_td_id+"="+rows[i].cells[1].childNodes[0].value+"="+rows[i].cells[2].childNodes[0].value+"="+rgb+"="+rows[i].cells[3].childNodes[0].value;
				} else if (tr_td_id.indexOf("edge_vendor_header") != -1) {
				str += "|"+label+"="+tr_td_id+"="+rows[i].cells[1].innerText+"="+rows[i].cells[2].innerText+"="+rows[i].cells[3].innerText+"="+rows[i].cells[4].innerText;
				} else if (tr_td_id.indexOf("edge_width_header") != -1) {
				str += "|"+label+"="+tr_td_id+"="+rows[i].cells[1].innerText;
				} else if (tr_td_id.indexOf("edge_width") != -1) {
				str += "|"+rows[i].cells[0].childNodes[1].value+"="+tr_td_id+"="+rows[i].cells[0].childNodes[3].value+"="+rows[i].cells[1].childNodes[0].value;
				} else if (tr_td_id.indexOf("edge_vendor") != -1) {
				str += "|"+label+"="+tr_td_id+"="+rows[i].cells[1].childNodes[0].value+"="+(rows[i].cells[2].childNodes[0].value=="0"?"1":rows[i].cells[2].childNodes[0].value)+"="+(rows[i].cells[3].childNodes[0].value=="0"?"1":rows[i].cells[3].childNodes[0].value)+"="+(rows[i].cells[4].childNodes[0].value=="0"?"1":rows[i].cells[4].childNodes[0].value);
				} else if (tr_td_id.indexOf("fastener_position") != -1) {
				str += "|"+label+"="+tr_td_id+"="+value+"="+tagName;
				} else if ((tr_td_id.indexOf("fastener_table") == -1) && (tr_td_id.indexOf("hinge_producer_table") == -1) && (tr_td_id.indexOf("drawer_table") == -1) && (tr_td_id.indexOf("accessories_table") == -1) && (tr_td_id.indexOf("groove_table") == -1) && (rows[i].className!="template_row")) {
				str += "|"+label+"="+tr_td_id+"="+value+"="+tagName;
			}
			if ((tagName=="SELECT") && (rows[i].className!="template_row")) {
				str += "=";
				var options = rows[i].cells[1].childNodes[0].childNodes;
				for (var j = 0; j < options.length; j++) {
					var opt_value = options[j].value;
					var opt_text = options[j].innerText;
					str += "&"+opt_value+"^"+opt_text;
				}
			}
			if (tr_td_id.indexOf("fastener_position") != -1) {
				str += "|Установка размеров:=fastener_dimension="+rows[i].cells[3].childNodes[0].value+"=SELECT";
				str += "=";
				var options = rows[i].cells[3].childNodes[0].childNodes;
				for (var j = 0; j < options.length; j++) {
					var opt_value = options[j].value;
					var opt_text = options[j].innerText;
					str += "&"+opt_value+"^"+opt_text;
				}
				str += "|База для размеров:=dimension_base="+rows[i].cells[5].childNodes[0].value+"=SELECT";
				str += "=";
				var options = rows[i].cells[5].childNodes[0].childNodes;
				for (var j = 0; j < options.length; j++) {
					var opt_value = options[j].value;
					var opt_text = options[j].innerText;
					str += "&"+opt_value+"^"+opt_text;
				}
				str += "|Тип в названии отверстия:=type_hole="+rows[i].cells[7].childNodes[0].value+"=SELECT";
				str += "=";
				var options = rows[i].cells[7].childNodes[0].childNodes;
				for (var j = 0; j < options.length; j++) {
					var opt_value = options[j].value;
					var opt_text = options[j].innerText;
					str += "&"+opt_value+"^"+opt_text;
				}
			}
			if (tr_td_id.indexOf("groove_material") != -1) {
				str += "|Расширение паза, если он проходит через торец:=groove_offset="+rows[i].cells[3].childNodes[0].value+"=SELECT";
				str += "=";
				var options = rows[i].cells[3].childNodes[0].childNodes;
				for (var j = 0; j < options.length; j++) {
					var opt_value = options[j].value;
					var opt_text = options[j].innerText;
					str += "&"+opt_value+"^"+opt_text;
				}
			}
		}
	}
	
	let fastener_array = "";
	for (let fastener_name of fastener_name_list_array) {
		fastener_param_array = "&";
		fastener_param = fastener_hash[fastener_name];
		for (let key in fastener_param) {
			fastener_param_array += key.replace(/,/g,".")+"=>"+fastener_param[key].replace(/,/g,".")+",";
		}
		fastener_param_array = fastener_param_array.slice(0,-1);
		fastener_array += fastener_param_array;
	}
	let template_array = "";
	let template_rows = document.getElementsByClassName("template_row");
	for (let row of template_rows) {
		let tr_id = "="+row.cells[1].childNodes[0].id;
		let cols = row.querySelectorAll('td');
		for (var j = 0; j < cols.length; j++) {
			let elem = cols[j].childNodes[0];
			if (elem.tagName.indexOf("LABEL") != -1) { template_array += (elem.getAttribute('template_name')?elem.getAttribute('template_name'):elem.textContent)+(j==0?tr_id:"")+(j<cols.length-1?"=":""); }
			else if (elem.tagName.indexOf("SELECT") != -1) { template_array += elem.value+(j<cols.length-1?"=":"")+(elem.getAttribute('options')?"=SELECT="+elem.getAttribute('options'):""); }
			else if (elem.getAttribute('template_position')) { template_array += elem.value+(j<cols.length-1?"=":""); }
		    else if (elem.tagName.indexOf("DIV") != -1) { template_array += (elem.children[0].checked ? "1" : (elem.children[1].checked ? "2" : "0"))+(j<cols.length-1?"=":""); }
			else { template_array += elem.value+(j==0?tr_id:"")+(j<cols.length-1?"=":"=INPUT"); }
		}
		template_array += "/n";
	}
	let hinge_array = "";
	for (let key1 in hinge_hash) {
		hinge_array += key1.replace(", ","=");
		hinge_param_array = "<=>";
		for (let key2 in hinge_hash[key1]) {
			hinge_param_array += key2.replace(/,/g,".");
			for (let key3 in hinge_hash[key1][key2]) {
				hinge_param_array += "="+hinge_hash[key1][key2][key3]["name"].replace(/,/g,"|")+"=";
				if(!("axis1" in hinge_hash[key1][key2][key3])) { hinge_param_array += "&"; }
				if (key1.indexOf("планки")==-1) {
					if ((hinge_hash[key1][key2][key3]["diam2"]=="")||(hinge_hash[key1][key2][key3]["depth2"]=="")||(hinge_hash[key1][key2][key3]["multiple_dist2"]=="")) {
						for (let key4 in hinge_hash[key1][key2][key3]) {
							if  (key4.indexOf("2") != -1) { delete hinge_hash[key1][key2][key3][key4] }
						}
					}
				}
				hinge_param_array = param_array(hinge_param_array,hinge_hash[key1][key2][key3],false);
				hinge_param_array = hinge_param_array.slice(0,-1);
			}
			hinge_param_array += "<=>";
		}
		hinge_param_array = hinge_param_array.slice(0,-3);
		hinge_array += hinge_param_array;
		hinge_array += "/n";
	}
	new_hash = {};
	for (let drawer_name_of_list of drawer_name_list_array) {
		new_hash[drawer_name_of_list] = drawer_hash[drawer_name_of_list];
	}
	drawer_hash = new_hash;
	let drawer_array = "";
	for (let key1 in drawer_hash) {
		drawer_array += "drawer_name=>"+key1.replace(/,/g,".");
		for (let key2 in drawer_hash[key1]) {
			if ((key2 == "depth_list") || (key2 == "symmetrical_holes")) { drawer_array += ","+key2.replace(/,/g,".")+"=>"+drawer_hash[key1][key2].replace(/,/g,"."); }
		}
		for (let key2 in drawer_hash[key1]) {
			if ((key2 != "depth_list") && (key2 != "symmetrical_holes")) {
				drawer_array += ","+key2.replace(/,/g,".")+"=>";
				drawer_array = param_array(drawer_array,drawer_hash[key1][key2],true);
			}
		}
		drawer_array += "/n";
	}
	new_hash = {};
	for (let accessories_name_of_list of accessories_name_list_array) {
		new_hash[accessories_name_of_list] = accessories_hash[accessories_name_of_list];
	}
	accessories_hash = new_hash;
	let accessories_array = "";
	for (let key1 in accessories_hash) {
		if (accessories_hash[key1]) {
			accessories_array += key1.replace(/,/g,".")+"=>";
			accessories_array = param_array(accessories_array,accessories_hash[key1],true);
			accessories_array += "/n";
		}
	}
	
	new_hash = {};
	for (let groove_name_of_list of groove_name_list_array) {
	    if (groove_hash[groove_name_of_list]) {
		    new_hash[groove_name_of_list] = groove_hash[groove_name_of_list];
		}
	}
	groove_hash = new_hash;
	let groove_array = "";
	for (let key1 in groove_hash) {
		groove_array += key1.replace(/,/g,".")+"=>";
		for (var i = 0; i <= 7; i++) {
			if (groove_hash[key1]["x"+i]) {
				groove_array += (groove_hash[key1]["x"+i]?groove_hash[key1]["x"+i].replace(/,/g,"."):"")+";";
				groove_array += (groove_hash[key1]["y"+i]?groove_hash[key1]["y"+i].replace(/,/g,"."):"")+"&";
			}
		}
		groove_array += "/n";
	}
	let lists_param_array = "";
	for (var i = 0; i < lists_array.length; i++) {
		lists_param_array += lists_array[i].join("=")
		lists_param_array += "/n";
	}
	let texts_param_array = "";
	let texts_rows = document.getElementsByClassName("texts");
	for (var i = 0; i < texts_rows.length; i++) {
	    texts_param_array += texts_rows[i].cells[2].childNodes[0].value+"=text"+i+"="+texts_rows[i].cells[3].childNodes[0].value+"/n";
	}
	let worktop_param_array = "";
	let worktop_rows = document.getElementsByClassName("worktop");
	for (let row of worktop_rows) {
	    worktop_param_array += row.cells[2].childNodes[0].value+"=>"+row.cells[3].childNodes[0].value+"/n";
	}
	let fartuk_param_array = "";
	let fartuk_rows = document.getElementsByClassName("fartuk");
	for (let row of fartuk_rows) {
	    fartuk_param_array += row.cells[2].childNodes[0].value+"=>"+row.cells[3].childNodes[0].value+"/n";
	}
	let frontal_param_array = "";
	let frontal_rows = document.getElementsByClassName("frontal");
	for (let row of frontal_rows) {
	    frontal_param_array += row.cells[2].childNodes[0].value+"=>"+row.cells[3].childNodes[0].value+"/n";
	}
	let freza_param_array = "";
	let freza_rows = document.getElementsByClassName("freza");
	for (let row of freza_rows) {
	    freza_param_array += row.cells[2].childNodes[0].value+"="+row.cells[3].childNodes[0].value+"/n";
	}
	let component_param_array = "";
	let component_rows = document.getElementsByClassName("component");
	for (let row of component_rows) {
	    component_param_array += row.cells[2].childNodes[0].value+"="+row.cells[3].childNodes[0].value+"/n";
	}
	let material_param_array = "";
	let material_rows = document.getElementsByClassName("material");
	for (let row of material_rows) {
	    material_param_array += row.cells[2].childNodes[0].value+"="+row.cells[3].childNodes[0].value+"="+row.cells[4].childNodes[0].value+"="+row.cells[5].childNodes[0].value+"="+row.cells[6].childNodes[0].value+"/n";
	}
	sketchup.get_data(str);
	sketchup.get_data("save_fasteners"+fastener_array);
	sketchup.get_data("save_template"+template_array);
	sketchup.get_data("save_hinge"+hinge_array);
	sketchup.get_data("save_drawer"+drawer_array);
	sketchup.get_data("save_accessories"+accessories_array);
	sketchup.get_data("save_groove"+groove_array);
	sketchup.get_data("save_lists"+lists_param_array);
	sketchup.get_data("save_texts"+texts_param_array);
	sketchup.get_data("save_worktop"+worktop_param_array);
	sketchup.get_data("save_fartuk"+fartuk_param_array);
	sketchup.get_data("save_frontal"+frontal_param_array);
	sketchup.get_data("save_freza"+freza_param_array);
	sketchup.get_data("save_component"+component_param_array);
	sketchup.get_data("save_material"+material_param_array);
	
	if (read=="true") { $('#parameter_table').empty(); sketchup.get_data("read_param"); }
	document.getElementById('apply').disabled = true;
	document.getElementById('apply').value = "Изменения сохранены";
	document.getElementById('apply').style.backgroundColor = "buttonface";
}
function param_array(array,value,repl) {
	for (var i = 1; i <= 7; i++) {
		if (value["axis"+i]) {
			array += (value["axis"+i]?(repl?value["axis"+i].replace(/,/g,"."):value["axis"+i]):"")+";";
			array += (value["diam"+i]?(repl?value["diam"+i].replace(/,/g,"."):value["diam"+i]):"")+";";
			array += (value["depth"+i]?(repl?value["depth"+i].replace(/,/g,"."):value["depth"+i]):"")+";";
			array += (value["x"+i]?(repl?value["x"+i].replace(/,/g,"."):value["x"+i]):"")+";";
			array += (value["y"+i]?(repl?value["y"+i].replace(/,/g,"."):value["y"+i]):"")+";";
			array += (value["z"+i]?(repl?value["z"+i].replace(/,/g,"."):value["z"+i]):"")+";";
			array += (value["multiple"+i]?(repl?value["multiple"+i].replace(/,/g,"."):value["multiple"+i]):"")+";";
			array += (value["multiple_dist"+i]?(repl?value["multiple_dist"+i].replace(/,/g,"."):value["multiple_dist"+i]):"")+";";
			array += (value["list_name"+i]?(repl?value["list_name"+i].replace(/,/g,"."):value["list_name"+i]):"")+";";
			array += (value["color"+i]?(repl?value["color"+i].replace(/,/g,"."):value["color"+i]):"")+"&";
		}
	}
	return array;
}
$(document).on( "click", "#export_parameters", function() {
	save_changes("false");
	sketchup.get_data('export_parameters');
});
$(document).on( "click", "#import_parameters", function() {
	sketchup.get_data('import_parameters');
});
$(document).on( "click", "#reset_parameters", function() {
	sketchup.get_data("reset_parameters");
});
$(document).on( "click", "#export_library", function() {
	sketchup.get_data('export_library');
});

