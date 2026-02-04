
document.addEventListener('DOMContentLoaded', function() {
    sketchup.get_data("read_param");
}, false);
var param = [];
var bb_width = 0;
var bb_height = 0;
function parameters(s){
	all_param = s;
	bb_width = s[0];
	bb_height = s[1];
	param = s.slice(2);
    var hinge_option_array = ["1^Накладные","2^Полунакладные","3^Вкладные"];
    $('#frontal_parameter_table').empty();
    $('#frontal_parameters_table').empty();
    var frontal_parameter_table = document.getElementById("frontal_parameter_table");
    row = frontal_parameter_table.insertRow(0);
    cell=row.insertCell(0);
    cell.innerHTML='<td><p class="vertical_td">Количество по вертикали</p></td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td><table id="frontal_parameter"></table></td>';
    var table = document.getElementById("frontal_parameter");
    var table_row = table.insertRow(0);
    table_row.innerHTML='<tr><td colspan="9" >Количество по горизонтали</td></tr>';
	let width = bb_width;
	let height = bb_height;
	let width_count = 0;
	let height_count = 0;
	for (var i = 0; i <= 3; i++) {
        var frontal_param = param[i].split("<=>");
		if (i==0) {
			for (var j = 1; j <= 9; j++) {
				if (frontal_param[j] && frontal_param[j] != "") {
					if (frontal_param[j].split(";")[0] != "auto") {
						width -= +frontal_param[j].split(";")[0];
						} else {
						width_count += 1;
					}
				}
			}
		}
		if (frontal_param[1] && frontal_param[1] != "") {
			if (frontal_param[0] != "auto") {
				height -= +frontal_param[0];
				} else {
				height_count += 1;
			}
		}
	}
	if (width_count > 0) { width /= width_count; }
	if (height_count > 0) { height /= height_count; }
    for (var i = 0; i <= 3; i++) {
        var frontal_param = param[i].split("<=>");
        if (frontal_param[1]) {
            var table_row = table.insertRow(i+1);
            for (var j = 1; j <= 9; j++) {
                if (frontal_param[j]) {
                    cell=table_row.insertCell(j-1);
                    cell.innerHTML='<td><table id="frontal_rect_table_'+i+j+'" class="frontal_rect_table"></table></td>';
                    var frontal_rect_table = document.getElementById('frontal_rect_table_'+i+j);
                    if (j==1) {
                        row = frontal_rect_table.insertRow(0);
                        if (i==0) {
                            // количество по горизонтали
                            row.innerHTML='<tr><td></td><td></td><td><button>'+j+'</button></td></tr>';
                            row = frontal_rect_table.insertRow(1);
							row.innerHTML='<tr><td></td><td></td><td><input class="width_hor" id="width_hor_'+(j)+'" title="Ширина (пусто или 0 - auto)" style="width: 80px; height: 15px;" value="'+frontal_param[j].split(";")[0]+(frontal_param[j].split(";")[0]=="auto" ? " ("+width.toFixed(1)+")" : "")+'" ></td></tr>';
							row = frontal_rect_table.insertRow(2);
						}
                        cell=row.insertCell(0);
                        // количество по вертикали
                        cell.innerHTML='<td><button'+(i==0 ? '' : ' id="del_ver_'+(i)+'" class="del_ver" title="Удалить фасад '+(i+1)+((i!=3 && param[i+1].split("<=>")[1]) ? ' и следующие"' : '"'))+'>'+(i+1)+(i==0 ? '' : '<br>- ')+'</button></td>'
                        cell=row.insertCell(1);
                        cell.innerHTML='<td><div style="width: 22px; height: 22px; transform: rotate(-90deg); display: inline-block;"><input class="height_ver" id="height_ver_'+(i)+'" style="width: 80px; height: 15px; position: relative; left: -32px; line-height: 30px;" title="Высота (пусто или 0 - auto)" value="'+frontal_param[0]+(frontal_param[0]=="auto" ? " ("+height.toFixed(1)+")" : "")+'" ><div></td>'
                        cell=row.insertCell(2);
                        cell.innerHTML='<td><table id="frontal_rect_'+i+j+'" class="frontal_rect"></table></td>';
                        } else {
                        row = frontal_rect_table.insertRow(0);
                        if (i==0) {
                            // количество по горизонтали
                            row.innerHTML='<tr><td><button id="del_hor_'+(j)+'" class="del_hor" title="Удалить фасад '+j+((j!=9 && frontal_param[j+1]) ? ' и следующие"' : '"')+'>'+j+' - </button></td></tr>';
                            row = frontal_rect_table.insertRow(1);
						    row.innerHTML='<tr><td><input class="width_hor" id="width_hor_'+(j)+'" title="Ширина (пусто или 0 - auto)" style="width: 80px; height: 15px;" value="'+frontal_param[j].split(";")[0]+(frontal_param[j].split(";")[0]=="auto" ? " ("+width.toFixed(1)+")" : "")+'" ></td></tr>';
                            row = frontal_rect_table.insertRow(2);
						}
                        cell=row.insertCell(0);
                        cell.innerHTML='<td><table id="frontal_rect_'+i+j+'" class="frontal_rect"></table></td>';
					}
                    // квадрат фасада
                    var frontal_rect = document.getElementById('frontal_rect_'+i+j);
                    row = frontal_rect.insertRow(0);
                    row.innerHTML='<tr><td></td><td><input class="trim" id="trim_up'+i+j+'" title="Отступ сверху" value="'+(frontal_param[j] ? frontal_param[j].split(";")[2] : "3") +'" ></td><td></td></tr>';
                    row = frontal_rect.insertRow(1);
                    let frontal_open = (j%2==0 ? "►" : "◄")
					switch(frontal_param[j].split(";")[1]) {
						case '0': frontal_open = "◄";
						break;
						case '1': frontal_open = "►";
						break;
						case '2': frontal_open = "▼";
						break;
						case '3': frontal_open = "▲";
						break;
					}
                    row.innerHTML='<tr><td><input class="trim" id="trim_lf'+i+j+'" title="Отступ слева" value="'+frontal_param[j].split(";")[4] +'" ></td><td><button id="open_'+i+j+'" class="open" title="Открывание '+(frontal_param[j] ? (frontal_param[j].split(";")[1]=="0" ? "налево" : (frontal_param[j].split(";")[1]=="1" ? "направо" : (frontal_param[j].split(";")[1]=="3" ? "наверх" : "вниз"))) : (j%2==0 ? "направо" : "налево"))+'">'+frontal_open +'</button></td><td><input class="trim" id="trim_rt'+i+j+'" title="Отступ справа" value="'+frontal_param[j].split(";")[5]+'" ></td></tr>';
                    row = frontal_rect.insertRow(2);
                    row.innerHTML='<tr><td></td><td><input class="trim" id="trim_dn'+i+j+'" title="Отступ снизу" value="'+frontal_param[j].split(";")[3]+'" ></td><td></td></tr>';
                    row = frontal_rect_table.insertRow((i>0 ? 1 : 3));
                    content = '<tr>';
                    if (i!=3 && j==1) { // кнопка добавления фасада по высоте
                        if (!param[i+1].split("<=>")[1]) { content += '<td style="height: 21px;"><button id="add_ver_'+i+'" class="add_ver" title="Добавить фасад по высоте" >+</button></td><td></td><td style="height: 21px;"><select class="hinge_select" style="width: 102px;" id="hinge_'+i+j+'" type="text" >'; }
                        else { content += '<td></td><td></td><td style="height: 21px;"><select class="hinge_select" style="width: 102px;" id="hinge_'+i+j+'" type="text" >'; }
                        } else { // выбор типа петель
                        content += '<td style="height: 21px;"><select class="hinge_select" style="width: 102px;" id="hinge_'+i+j+'" type="text" >';
					}
                    for (var k = 0; k < hinge_option_array.length; k++ ) {
                        content += '<option value="'+hinge_option_array[k].split("^")[0]+'">'+hinge_option_array[k].split("^")[1]+'</option>';
					}
                    content += '</select></td></tr>';
                    row.innerHTML=content;
                    document.getElementById('hinge_'+i+j).value = frontal_param[j].split(";")[6];
                    // кнопка добавления фасада по ширине
                    if (i==0 && j!=9 && !frontal_param[j+1]) {
                        cell=table_row.insertCell(j);
                        cell.innerHTML='<td><table id="frontal_rect_table_'+i+(j+1)+'" class="frontal_rect_table"></table></td>';
                        frontal_rect_table = document.getElementById('frontal_rect_table_'+i+(j+1));
                        row = frontal_rect_table.insertRow(0);
                        row.innerHTML='<tr><td><button id="add_hor_'+(j+1)+'" class="add_hor" title="Добавить фасад по ширине" >+</button></td></tr>';
                        row = frontal_rect_table.insertRow(1);
                        row.innerHTML='<tr><td style="height: 145px;"></td></tr>';
                        //row.innerHTML='<tr><td style="height: '+(!param[i+1].split("<=>")[1] ? 145 : 120)+'px;"></td></tr>';
					}
				}
			}
		}
	}
    var frontal_parameters_table = document.getElementById("frontal_parameters_table");
    row = frontal_parameters_table.insertRow(frontal_parameters_table.rows.length);
    cell=row.insertCell(0);
    cell.innerHTML='<td><table id="frontal_parameters"></table></td>';
    var table = document.getElementById("frontal_parameters");
    var content='';
    for (var i = 4; i < param.length; i++ ) {
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td >' + param[i].split("=")[0] + '</td>';
        if ( param[i].split("=")[1] ) {
            cell=row.insertCell(1);
            if (param[i].split("=")[3].toLowerCase().indexOf("input") != -1) {
                content='<td ><input class="input_select" id="' + param[i].split("=")[1] + '" type="text" value="' + param[i].split("=")[2] + '"></td>';
                cell.innerHTML=content;
                } else if (param[i].split("=")[3].toLowerCase().indexOf("select") != -1 ) {
                content='<td ><select class="input_select" id="' + param[i].split("=")[1] + '" type="text" ></td>';
                var option_array = param[i].split("=")[4].split("&");
                for (var j = 1; j < option_array.length; j += 1) {
                    content=content.concat('<option value="'+option_array[j].split("^")[0]+'">'+option_array[j].split("^")[1]+'</option>');
				}
                content=content.concat('</select>');
                cell.innerHTML=content;
                document.getElementById(param[i].split("=")[1]).value = param[i].split("=")[2];
			}
		}
        if ((param[i].split("=")[1].indexOf("_input")!=-1 && param[i-1].split("=")[2]!="3") || (param[i].split("=")[1].indexOf("_position")!=-1 && param[i-2].split("=")[2]!="3")){
            row.style.display = 'none';
		}
	}
}
$(document).on( "click", ".del_ver", function(){
    let index = this.id.substr(8);
    let auto_array = [];
    for (var i = 0; i <= 3; i++) {
        if (index <= i) { param[i] = "auto<=>"; }
        if (param[i].split("<=>")[1]){ auto_array = auto_array.concat(param[i].split("<=>")[0]); }
	}
    if (!auto_array.includes("auto")) {alert("Хотя бы одно значение должно быть auto");return;}
    if (index == 1){ param[0] = "auto<=>"+param[0].split("<=>").slice(1).join("<=>"); }
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "click", ".del_hor", function(){
    let index = this.id.substr(8);
    for (var i = 0; i <= 3; i++) {
        let param_arr = param[i].split("<=>");
        let new_arr = param_arr.slice(0, index);
        param[i] = new_arr.join("<=>");
	}
    let auto_array = [];
    let param_arr = param[0].split("<=>");
    for (var i = 1; i <= param_arr.length-1; i++) {
        auto_array = auto_array.concat(param_arr[i].split(";")[0]);
	}
    console.log(auto_array)
    if (!auto_array.includes("auto")) {alert("Хотя бы одно значение должно быть auto");return;}
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "click", ".add_ver", function(){
    let index = this.id.substr(8);
    param[+index+1] = param[index];
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "click", ".add_hor", function(){
    let index = this.id.substr(8);
    for (var i = 0; i <= 3; i++) {
        if (param[i].split("<=>")[1]){
            let last_param = param[i].split("<=>")[param[i].split("<=>").length - 1];
            let last_param_arr = last_param.split(";");
            if (index%2==0 && last_param_arr[1]=="◄") { last_param_arr[1]="►"; }
            else if (index%2!=0 && last_param_arr[1]=="►") { last_param_arr[1]="◄"; }
            param[i] = param[i]+"<=>"+last_param_arr.join(";");
		}
	}
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "change", ".width_hor", function(){
    let index = this.id.substr(10);
    let value = this.value.replace(",",".").replace(/[^\d\.]/g,"");
	console.log(value)
    if ((value.trim()=="")||(value.trim()=="0")||(value.indexOf("auto")!=-1)) {value="auto";}
    for (var i = 0; i <= 3; i++) {
        if (param[i].split("<=>")[1]){
            let param_arr = param[i].split("<=>");
            let this_param_arr = param_arr[index].split(";");
            this_param_arr[0] = value;
            param_arr[index] = this_param_arr.join(";");
            param[i] = param_arr.join("<=>");
		}
	}
    let auto_array = [];
    let param_arr = param[0].split("<=>");
    for (var i = 1; i <= param_arr.length-1; i++) {
        auto_array = auto_array.concat(param_arr[i].split(";")[0]);
	}
    console.log(auto_array)
    if (!auto_array.includes("auto")) {
        alert("Хотя бы одно значение должно быть auto");
        this.value="auto";
        return;
	}
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "change", ".height_ver", function(){
    let index = this.id.substr(11);
    let value = this.value.replace(",",".").replace(/[^\d\.]/g,"");
    if ((value.trim()=="")||(value.trim()=="0")) {value="auto";}
    let param_arr = param[index].split("<=>");
    param_arr[0] = value;
    param[index] = param_arr.join("<=>");
    let auto_array = [];
    for (var i = 0; i <= 3; i++) {
        if (param[i].split("<=>")[1]){ auto_array = auto_array.concat(param[i].split("<=>")[0]); }
	}
    console.log(auto_array)
    if (!auto_array.includes("auto")) {alert("Хотя бы одно значение должно быть auto");return;}
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "change", ".trim", function(){
    let index = this.id.substr(7);
    let value = this.value.replace(",",".").replace(/[^\d\.\-]/g,"");
    let trim_index=1;
    if (this.id.substr(5,2)=="up") {trim_index=2;if(value.trim()==""){value="3";}}
    else if (this.id.substr(5,2)=="dn") {trim_index=3;if(value.trim()==""){value="0";}}
    else if (this.id.substr(5,2)=="lf") {trim_index=4;if(value.trim()==""){value="1.5";}}
    else if (this.id.substr(5,2)=="rt") {trim_index=5;if(value.trim()==""){value="1.5";}}
    if (trim_index!=1){
        let param_arr = param[index.substr(0,1)].split("<=>");
        let this_param_arr = param_arr[index.substr(1,1)].split(";");
        this_param_arr[trim_index] = value;
        param_arr[index.substr(1,1)] = this_param_arr.join(";");
        param[index.substr(0,1)] = param_arr.join("<=>");
        sketchup.get_data("save_changes|"+param.join("|"));
        parameters([bb_width,bb_height].concat(param));
        document.getElementById('apply').disabled = false;
	}
});
$(document).on( "click", ".open", function(){
    let index = this.id.substr(5);
    let value = this.innerHTML;
    let param_arr = param[index.substr(0,1)].split("<=>");
    let this_param_arr = param_arr[index.substr(1,1)].split(";");
    if (value=="◄") { value = "▲"; this_param_arr[1] = "3";} 
    else if (value=="▲") { value = "►"; this_param_arr[1] = "1";}
    else if (value=="►") { value = "▼"; this_param_arr[1] = "2";}
    else if (value=="▼") { value = "◄"; this_param_arr[1] = "0";}
    this.innerHTML = value;
    param_arr[index.substr(1,1)] = this_param_arr.join(";");
    param[index.substr(0,1)] = param_arr.join("<=>");
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "change", ".hinge_select", function(){
    let index = this.id.substr(6);
    let value = this.value;
    for (var i = 0; i <= 3; i++) {
        if (param[i].split("<=>")[1] && index.substr(0,1)==i){
            let param_arr = param[i].split("<=>");
            let this_param_arr = param_arr[index.substr(1,1)].split(";");
            this_param_arr[6] = value;
            param_arr[index.substr(1,1)] = this_param_arr.join(";");
            param[i] = param_arr.join("<=>");
		}
	}
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "change", ".input_select", function(){
    for (var i = 4; i <= param.length-1; i++) {
        let param_arr = param[i].split("=");
        if (this.id==param_arr[1]) {
            param_arr[2] = this.value.replace(",",".").replace(/[^\d\.]/g,"");
            param[i] = param_arr.join("=");
		}
	}
    console.log(this.id);
    console.log(this.value);
    console.log(param);
    sketchup.get_data("save_changes|"+param.join("|"));
    parameters([bb_width,bb_height].concat(param));
    document.getElementById('apply').disabled = false;
});
$(document).on( "focus", ".width_hor", function() {
    $(this).select();
});
$(document).on( "focus", ".height_ver", function() {
    $(this).select();
});
$(document).on( "focus", ".trim", function() {
    $(this).select();
});
function place_frontal(){
    sketchup.get_data("place_frontal|"+param.join("|"));
}

