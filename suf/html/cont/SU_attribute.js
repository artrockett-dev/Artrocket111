var arr_val = [];
var att_array = [];
var unit_array = [];
var att_to_show = [];
var scrollPos;
var submit_att = false;
var copied_att = false;
var activeInput = null;
var awaitingAttInsertion = false;
document.addEventListener('DOMContentLoaded', function() {
    attributes_activate();
}, false);
function attributes_activate(){
    arr_val = [];
    att_array = [];
    unit_array = [];
    window.scrollTo(0, 0);
    $('#main').empty();
    $('#main').append('<table id="table_mess"></table>');
    var tableObj = [];
    tableObj.push ('<td id="Logo"> <img id="image" src="" ></td>');
    tableObj.push ('<td id="des_name">'+translate("No Components Selected")+'</td>');
    $('#table_mess').append(tableObj);
    $('#main').append('<legend id="description">'+translate("Select one or more components and view their parameters.")+'</legend>');
    $('#main').append('<div id="att_table" ></div>');
    $('#att_table').append('<table id="attribute_table" ></table>');
    document.body.style.backgroundColor = "#FFFFFF";
    document.getElementById('footer').style.display='block';
    document.getElementById('submit_button').style.display='block';
    document.getElementById('submit_button').disabled = true;
    document.getElementById('submit_button').value = translate("Apply");
    document.getElementById('submit_button').style.background = null;
    document.getElementById("att_table").style.display='block';
	document.getElementById('add_attribute').title="Записать скопированный атрибут\nв выбранный компонент";
	document.getElementById('set_position_att').style.display='block';
    sketchup.get_att_data('att');
}
function add_comp(){
    let attribute_table = document.getElementById('attribute_table');
    if (attribute_table) {
	    activeInput = null;
        arr_val = [];
        att_array = [];
        unit_array = [];
        attribute_table.innerHTML = "";
        document.getElementById('submit_button').style.display='block';
        document.getElementById('submit_button').disabled = true;
        document.getElementById('att_table').style.display='block';
		if (copied_att) {
			document.getElementById('add_attribute').style.display='block';
		}
        sketchup.get_att_data('att');
	}
    if (submit_att){
        $('html, body').animate({
            scrollTop: scrollPos
		}, 500);
        submit_att = false;
	}
}
function set_copied_att(copied){
    copied_att = copied;
}
function clear_selection(){
    let attribute_table = document.getElementById('attribute_table');
    if (attribute_table) {
        arr_val = [];
        att_array = [];
        unit_array = [];
        attribute_table.innerHTML = "";
        document.getElementById('des_name').innerHTML = translate("No Components Selected");
        document.getElementById('description').innerHTML = translate("Select one or more components and view their parameters.");
        document.getElementById('image').src = "";
        document.getElementById('submit_button').style.display='none';
        document.getElementById('att_table').style.display='none';
	}
}
function no_attributes(des_name){
    arr_val = [];
    document.getElementById('des_name').innerHTML = des_name;
    document.getElementById('description').innerHTML = translate("The selected components do not have parameters that can be edited at all.");
    document.getElementById('image').src = "";
    document.getElementById('submit_button').style.display='none';
    document.getElementById('att_table').style.display='none';
}
function no_attributes_one(s){
    arr_val = [];
    var des_name = s[0];
    var item_code = s[1];
    var thumbnail = s[2];
    document.getElementById('des_name').innerHTML = des_name + "<br />" + item_code;
    document.getElementById('description').innerHTML = translate("The component has no parameters that can be edited");
    document.getElementById('image').src = thumbnail;
    document.getElementById('submit_button').style.display='none';
    document.getElementById('att_table').style.display='none';
}
$(document).on( "click", "#submit_button", function() {
	awaitingAttInsertion = false;
    change_store();
});
function change_store(){
    scrollPos = $(window).scrollTop();
    submit_att = true;
	var message = ['submit'];
	if (typeof activeInput !== 'undefined' && activeInput) {
        message.push("fals"+activeInput.id+"=>"+activeInput.value);
	}
	message = message.concat(arr_values());
    if (message.length > 1) {
		sketchup.get_att_data(message);
		arr_val = [];
		activeInput = null;
	}
}
function arr_values(str){
    if (str) { arr_val.push(str);} 
    else { return arr_val;}
}
function set_default(att,default_value){
	if (default_value != "") {
		document.getElementById(att).value = default_value;
	}
}
function key_down(att){
    document.getElementById(att).style.backgroundColor = '#B0E2FF';
    document.getElementById('submit_button').disabled = false;
}
function key_up(e, att, deep_change) {
    e = e || window.event;
    const input = document.getElementById(att);
    if (e.keyCode === 13) {
        document.getElementById('submit_button').disabled = false;
        document.getElementById('submit_button').click();
        awaitingAttInsertion = false;
        return false;
	}
    if (!awaitingAttInsertion && input.value.includes('=')) {
        awaitingAttInsertion = true;
		activeInput = input;
	}
    return true;
}
function insertAttributeId(attrId) {
    if (!awaitingAttInsertion || !activeInput) return;
    const input = activeInput;
    const cursorPos = input.selectionStart;
    const val = input.value;
	if (input.id.indexOf("_section_") != -1) { attrId = 'LOOKUP("'+attrId+'")'; }
    const newVal = val.slice(0, cursorPos) + attrId + val.slice(cursorPos);
    input.value = newVal;
    const newCursorPos = cursorPos + attrId.length;
    input.setSelectionRange(newCursorPos, newCursorPos);
    input.focus();
}
function on_change_input(att,deep_change){
	if (awaitingAttInsertion) return;
    store_values(att,deep_change,false);
}
function on_change_check(att,deep_change){
	document.getElementById(att).blur();
	document.getElementById('submit_button').disabled = false;
	document.getElementById('submit_button').focus();
	val=document.getElementById(att).checked;
	sketchup.get_att_data("change_checkbox/"+att+"=>"+val);
	arr_values("chck"+att+"=>"+val);
}
function on_change_select(att,deep_change){
    document.getElementById(att).blur();
    document.getElementById('submit_button').disabled = false;
    document.getElementById('submit_button').focus();
    document.getElementById(att).style.backgroundColor = '#B0E2FF';
    store_values(att,deep_change,true);
    check_visible_attribute(att);
}
function check_visible_attribute(att){
    val=document.getElementById(att).value;
    sketchup.get_att_data("check_visible_attribute/"+att+"="+val); 
}
function show_hide_att(s) {
    var	table = document.getElementById('attribute_table');
    var rows = table.rows;
    for (let i = 0; i < rows.length; i++) {
        var id = rows[i].cells[1].childNodes[0].id;   
        for (let j = 0; j < s.length; j++) {
            if (id == s[j][1]) {
                if (s[j][0] == 'SETACCESS') {
                    if (s[j][2] == 'NONE') {
                        rows[i].classList.add('none');
                        rows[i].style.display = 'none';
                        } else {
                        rows[i].classList.add('table-row');
                        rows[i].style.display = 'table-row';
						if (s[j][2] == 'VIEW') {
							document.getElementById(id).disabled = true;
							} else {
							document.getElementById(id).disabled = false;
						}
					}
                    } else if (s[j][0] == 'SETLABEL') {
                    rows[i].cells[0].childNodes[0].innerHTML = s[j][2];
				}
			}
		}
	}
}
function store_values(att,deep_change,select_tag=false){
    var arr = arr_values();
    if (arr != "") {
        arr.forEach(function(entry) {
            index = entry.indexOf(deep_change+att);
			if (index != -1) { arr_val.splice(index, 1);}
		});
	}
	var str="", sep='=>', s;
	s=document.getElementById(att).value;
	if (s!="") {
	    var formula = false;
		if (s[0] == "=") { formula = true; s = s.substring(1); }
		var number_in_string = s[0].replace(/[^\d\.]/g,"");
		if (!select_tag && number_in_string!="" && Number.isInteger(+number_in_string)) {
			if (s.indexOf("+") != -1) {
				s_arr = s.split('+');
				var result = Number(s_arr[0].replace(",",".").replace(/[^\d\.\-]/g,""));
				for(let i = 1; i < s_arr.length; i++){result += Number(s_arr[i].replace(",",".").replace(/[^\d\.\-]/g,""));}
				s = result;
				} else if (s.indexOf("-") != -1) {
				s_arr = s.split('-');
				var result = Number(s_arr[0].replace(",",".").replace(/[^\d\.]/g,""));
				for(let i = 1; i < s_arr.length; i++){result -= Number(s_arr[i].replace(",",".").replace(/[^\d\.]/g,""));}
				s = result;
				} else if (s.indexOf("/") != -1) {
				s_arr = s.split('/');
				var result = Number(s_arr[0].replace(",",".").replace(/[^\d\.\-]/g,""));
				for(let i = 1; i < s_arr.length; i++){result /= Number(s_arr[i].replace(",",".").replace(/[^\d\.\-]/g,""));}
				s = result;
				} else if (s.indexOf("*") != -1) {
				s_arr = s.split('*');
				var result = Number(s_arr[0].replace(",",".").replace(/[^\d\.\-]/g,""));
				for(let i = 1; i < s_arr.length; i++){result *= Number(s_arr[i].replace(",",".").replace(/[^\d\.\-]/g,""));}
				s = result;
			}
			} else if (!select_tag) {
			if (s.indexOf("/") != -1) {
				alert("Нельзя использовать символ ' / '");
				return;
				} else if (s.indexOf("*") != -1) {
				alert("Нельзя использовать символ ' * '");
				return;
				} else if (s.indexOf("+") != -1) {
				alert("Нельзя использовать символ ' + '");
				return;
				} else if (s.indexOf("(") != -1) {
				alert("Нельзя использовать символ ' ( '\nВместо него используйте ' [ '");
				return;
				} else if (s.indexOf(")") != -1) {
				alert("Нельзя использовать символ ' ) '\nВместо него используйте ' ] '");
				return;
			}
		}
		if (formula) { att = "_"+att+"_formula"; }
	}
	str=str.concat(deep_change+att,sep);
	str=str.concat(s);
	arr_values(str);
	var unit_of_att = att_array.indexOf(deep_change+att);
	var att_value = document.getElementById(att).value;
	if ((!formula) && (number_in_string!="") && (Number.isInteger(+number_in_string)) && (unit_of_att != -1) && (att_value.indexOf(unit_array[unit_of_att]) == -1)) {
		document.getElementById(att).value=s+unit_array[unit_of_att];
	}
}
function name_list(s){ //0-des_name, 1-item_code, 2-summary, 3-description, 4-thumbnail
    var des_name = s[0];
    var item_code = s[1];
    var summary = s[2];
    var description = s[3];
    var thumbnail = s[4];
	if (item_code != "") { des_name = des_name + "<br />" + item_code; }
    document.getElementById('des_name').innerHTML = des_name;
    if ((summary != "nil") && (summary != "")) { description = "<b>" + summary + "</b>" + "<br />" + description; }
    document.getElementById('description').innerHTML = description;
    document.getElementById('image').src = thumbnail+'?anti_cache=' + Math.random();
}
function attribute_list(s){ //0-att, 1-access, 2-formlabel, 3-formulaunits, 4-value, 5-s_typ, 6-s_val
    var att = s[0];
    var access = s[1];
    var formlabel = s[2];
    var formulaunits = s[3];
    var val = s[4];
    var s_typ = unescape(s[5]);
    var s_val = unescape(s[6]);
    var att_hide = 'table-row';
	if (s[7]) { att_hide = 'none'; }
	var formula = s[8];
	var default_value = "";
	if (s[9]) { default_value = s[9]; }
	var deep_change = "fals";
	var rowCount = attribute_table.rows.length;
	var check = document.getElementById(att);
	if (!check) { add_row(rowCount,"attribute_table",access,formlabel,att,val,s_val,s_typ,deep_change,att_hide,formula,default_value);}
	if (access != "LIST") {
		var ind = val.toString().indexOf(" ");
		if (ind != -1) {
			var unit = val.toString().slice(ind, val.toString().length);
			att_array.push(deep_change+att);
			unit_array.push(unit);
		}
	}
}
function hidden_rows() {
    var	table = document.getElementById('attribute_table');
    var rows = table.rows;
    for (let i = 0; i < rows.length; i += 1) {
        var value = rows[i].cells[1].innerHTML;
        if (value.indexOf("▶") != -1) { hide (table, i, 'none'); } 
        else if (value.indexOf("▼") != -1) { hide (table, i, 'table-row'); }
	}
}
function hide(table, number, display) {
    var rows = table.rows;
    for (let i = number + 1; i < rows.length; i += 1) {
        var val_row_i = rows[i].cells[1].innerHTML;
        if (rows[i].className == 'none') continue;
        if ((val_row_i.indexOf("▼") != -1) || (val_row_i.indexOf("▶") != -1) || (val_row_i.indexOf("&#9660;") != -1) || (val_row_i.indexOf("&#9654;") != -1) || (val_row_i.indexOf("___") != -1)) { break;} 
        else { rows[i].style.display = display;}
	}
}
function add_row(i,id_tab,access,formlabel,id_i,val,s_val,s_typ,deep_change,att_hide,formula="",default_value=""){
	var i,access,formlabel,id_i,val,s_val,s_typ;
	var row,cell;
	var posi,posi_valu,res,valu,cur_val,opt,opt_valu;
	var	table = document.getElementById(id_tab);
	var t_select;
	row = table.insertRow(i);
	cell=row.insertCell(0);
    content = '<td><att_label onmouseover="ChangeOver('+"'"+id_i+"'"+')" onmouseout="ChangeOut('+"'"+id_i+"'"+')" title="" onclick="insertAttributeId('+"'"+id_i+"'"+')" ondblclick="onDoubleClick('+"'"+id_i+"'"+')">';
	if ((val.indexOf("&#9660;") != -1) || (val.indexOf("&#9654;") != -1)) {content=content.concat(((id_i.indexOf("_section_")!=-1) ? '<input type="button" title="Удалить секцию" class="delete_section" onclick="delete_section('+"'"+id_i+"'"+')" value="x">' : ""))}
	content=content.concat(formlabel + '</att_label></td>');
	cell.innerHTML=content;
	cell=row.insertCell(1);
	if (access=="VIEW") {
		content='<td ><input ';
        if ((val.indexOf("Редактировать") != -1) || (val.indexOf("Edit") != -1)) { content=content.concat('type="button" class="edit" '); }
        else if ((val.indexOf("&#9660;") != -1) || (val.indexOf("&#9654;") != -1)) { content=content.concat('type="button" class="view" table_id="'+id_tab+'"'); }
		else if ((val.indexOf("Показать") != -1) || (val.indexOf("Show") != -1)) { content=content.concat('type="button" class="axis_comp" '); }
		else if (id_i === "s9_comp_copy") { content=content.concat('type="button" class="copy_comp" '); }
        else { content=content.concat('disabled="true" onkeyup="return key_up(event, this.id, ' + "'" + deep_change + "'" + ')" onchange="on_change_input(this.id, ' + "'" + deep_change + "'" + ')"');}
        content=content.concat('id="' + id_i + '" number="' + i + '" value="' + val + '"></td>');
        cell.innerHTML=content;
	}
    else if (access=="TEXTBOX") {
	cell.innerHTML='<td id="cell" ><input onmouseover="ChangeOver('+"'"+id_i+"'"+')" onmouseout="ChangeOut('+"'"+id_i+"'"+')" type="text" id="' + id_i + '" onfocusin="set_default('+"'"+id_i+"','"+default_value+"'"+')" value="' + val + '" onkeydown="key_down(this.id)" onkeyup="return key_up(event, this.id, ' + "'" + deep_change + "'" + ')" title="'+(formula ? formula : (id_i.indexOf("c2_shelve")!=-1 ? translate("Clear - auto") : ""))+'" onchange="on_change_input(this.id, ' + "'" + deep_change + "'" + ')"></td>'; }
	
	else if (access=="CHECKBOX") {
		content = '<td style="text-align: left; vertical-align: middle;">';
		checkbox_array = val.split(',');
		for (let i = 0; i < checkbox_array.length; i += 1) {
			const [label, value] = checkbox_array[i].split('=>');
			content=content.concat('<label style="margin-left: 2px; vertical-align: middle; line-height: 16px;">'+label+'</label><input style="width: 14px; margin-left: 2px; margin-right: 8px; vertical-align: middle;" type="checkbox" id="' + id_i +'=>'+label+'"' +(value==='1'?'checked':'')+ ' onmouseover="ChangeOver('+"'"+id_i+"'"+')" onmouseout="ChangeOut('+"'"+id_i+"'"+')" onchange="on_change_check(this.id, ' + "'" + deep_change + "'" + ')"></td>');
		}
		content=content.concat('</td>');
		cell.innerHTML=content;
	}
	
    else if (access=="LIST") {
        posi= s_typ.indexOf(";");
        if (posi == -1) {
            cell.innerHTML='<td ><select onmouseover="ChangeOver('+"'"+id_i+"'"+')" onmouseout="ChangeOut('+"'"+id_i+"'"+')" id="' + id_i + '" title="'+formula+'" onchange="on_change_select(this.id, ' + "'" + deep_change + "'" + ')"><option value="' + s_val + '">' + s_typ + '</option> </select> </td>';
            } else {
            content='<td ><select onmouseover="ChangeOver('+"'"+id_i+"'"+')" onmouseout="ChangeOut('+"'"+id_i+"'"+')" id="' + id_i + '" title="'+formula+'" onchange="on_change_select(this.id, ' + "'" + deep_change + "'" + ')">';
            s_typ = s_typ.split(";");
            s_val = s_val.split(";");
            for (let i = 0; i < s_typ.length; i += 1) { content = content.concat('<option value="' + s_val[i] + '">' + s_typ[i] + '</option>'); }
            content = content.concat('</select> </td>');
            cell.innerHTML=content;
            cur_val= s_val.indexOf(val.toString());
            t_select = document.getElementById(id_i);
            if (cur_val == -1) {$(document.getElementById(id_i)).prepend('<option value=""></option>'); t_select.options[0].selected=true; }
            else { t_select.options[cur_val].selected=true;}
		}
	}
    row.classList.add(att_hide);
    row.style.display = att_hide;
}
function onDoubleClick(id) {
    sketchup.get_att_data("сlick_att/"+id);
}
$(document).on( "click", "#add_attribute", function(e) {
	sketchup.get_att_data("add_attribute");
});
$(document).on( "click", "#set_position_att", function(e) {
	sketchup.get_att_data("set_position_att");
});
function ChangeOver(row_id) {
    if(row_id.indexOf("_panel_section_") != -1){
        sketchup.get_att_data("draw_section/"+row_id);
        } else if(row_id.indexOf("_shelve_section_") != -1){
        sketchup.get_att_data("draw_section/"+row_id);
        } else if(row_id.indexOf("_drawer_section_") != -1){
        sketchup.get_att_data("draw_section/"+row_id);
		} else if(row_id.indexOf("_accessory_section_") != -1){
        sketchup.get_att_data("draw_section/"+row_id);
        } else if(row_id.indexOf("_frontal_section_") != -1){
        sketchup.get_att_data("draw_section/"+row_id);
	}
};

function ChangeOut(row_id) {
    if((row_id.indexOf("_panel_section_") != -1)||(row_id.indexOf("_shelve_section_") != -1)||(row_id.indexOf("_drawer_section_") != -1)||(row_id.indexOf("_accessory_section_") != -1)||(row_id.indexOf("_frontal_section_") != -1)||(row_id.indexOf("s5") != -1)){
        sketchup.get_att_data("select_tool");
	}
}
function delete_section(row_id) {
    sketchup.get_att_data("delete_section/"+row_id);
	attributes_activate();
}
$(document).on( "click", ".edit", function(e) {
    if ($(this).attr('id') == "name_list") { sketchup.get_att_data("edit_name_list"); }
	else { sketchup.get_att_data("edit_additional"); }
});
$(document).on( "click", ".axis_comp", function(e) {
	sketchup.get_att_data("axis_comp");
});
$(document).on( "click", ".copy_comp", function(e) {
	sketchup.get_att_data("copy_comp");
});
$(document).on( "click", ".view", function(e) {
    let table_id = $(this).attr('table_id');
    var	table = document.getElementById(table_id);
    var id = $(this).attr('id');
    number = +($(this).attr('number'));
    var value = $(this).attr('value')
    if (value == "▼") { 
        $(this).val("▶"); 
        hide (table, number, 'none'); 
        if (table_id == "attribute_table") { sketchup.get_att_data("hidden_att/" + id + "/#9654;"); }
        } else if (value == "▶") {
        $(this).val("▼"); 
        hide (table, number, 'table-row'); 
        if (table_id == "attribute_table") { sketchup.get_att_data("hidden_att/" + id + "/#9660;"); }
	}
});

