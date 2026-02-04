var currency = "RUB";
var currency_name = "р";
var currency_arr = ["RUB","AUD","GBP","MDL","BYN","BGN","USD","EUR","KZT","CAD","KGS","CNY","TJS","UZS","UAH","KF"];
var digit_arr = ["0","0.0","0.00"]
var digit_capacity = "0";
var digit_capacity_found = false;
document.addEventListener('DOMContentLoaded', function() {
    sketchup.get_price_data('price_activate');
}, false);
function price(s){
	console.log(s)
    window.scrollTo(0, 0);
	$('#p_prldr').delay(500).fadeOut('slow');
    $('#table_mess').empty();
    $('#table_mess').append('<td id="des_name"></td>');
    $('#main').empty();
    $('#main').append('<div id="prices_table" ></div>');
	$('#prices_table').append('<table class="search_table" id="search_table" ></table>');
	$('#search_table').append('<th>Поиск по наименованию </th><th><input class="search_in_prices" placeholder="Минимум 2 символа"></input></th>')
    document.body.style.backgroundColor = "#FFFFFF";
    let price_arr = JSON.parse(s[0]);
    let param_list = s[1];
    currency = s[2].split("=")[0];
    currency_name = s[2].split("=")[2];
	digit_capacity = Object.values(price_arr)[0][0][13];
	Object.keys(price_arr).forEach(key => {
	  if (key != "Акции") { load_file(key,price_arr[key],param_list); }
	});
    load_discount_file("Акции",price_arr["Акции"],param_list);
	$('#prices_table').append('<p >');
    $('#prices_table').append('<table class="add_table" id="add_table" ></table>');
    let	table = document.getElementById('add_table');
    let rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<td ><new_table title="Добавить таблицу"><b>+</b></new_table></td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td ></td>';
    cell=row.insertCell(2);
    cell.innerHTML='<td >Разряд. | Валюта | Сокр.назв.вал.</td>';
    cell=row.insertCell(3);
	str = '<td ><select id="digit_select" >';
    for (let i = 0; i < digit_arr.length; i++) {
        str = str.concat('<option value='+digit_arr[i]+'>'+digit_arr[i]+'</option>');
	}
    str = str.concat('</select></td>');
    cell.innerHTML=str;
    $("#digit_select option[value='"+digit_capacity.replace(",",".")+"']").attr("selected", "selected");
    cell=row.insertCell(4);
    str = '<td ><select id="currency_select" >';
    for (let i = 0; i < currency_arr.length; i++) {
        str = str.concat('<option value='+currency_arr[i]+'>'+currency_arr[i]+'</option>');
	}
    str = str.concat('</select></td>');
    cell.innerHTML=str;
    $("#currency_select option[value='"+currency+"']").attr("selected", "selected");
    cell=row.insertCell(5);
    cell.innerHTML='<td ><currency_name_label>' + currency_name + '</currency_name_label></td>';
    
    document.getElementById('footer').style.display='block';
    document.getElementById('save_button').disabled = true;
    document.getElementById('save_button').style.backgroundColor = "buttonface";
    document.getElementById('save_button').value = "Сохранить изменения";
}
$(document).on( "click", ".add_path", function() {
    let add_path_id = $(this).attr('id');
    sketchup.get_price_data('add_path=>'+add_path_id.slice(9,add_path_id.length));
});
function add_materials_row(arr) {
    let price_name = arr[0];
    let prefix = arr[1];
	let suffix = arr[2];
	if ((suffix != "") && (suffix != " ")) { suffix = " "+suffix; }
    let provider = arr[3];
    let article = arr[4];
    let unit = arr[5];
    let cost = arr[6];
    let currency_price = arr[7];
    let coef = +arr[8].replace(",",".");
    let cost_price = +cost.replace(",",".")*coef;
    let work = arr[9];
    let category = arr[10];
	let code = arr[11];
	let weight = arr[12];
	let link = arr[13];
    let mat_names = arr.slice(14,arr.length);
    mat_names.sort();
    let price_table = document.getElementById(price_name);
    for (let i = 0; i < mat_names.length; i++) {
        let rowCount = price_table.rows.length;
        let coincidence = false;
        for (let j = 0; j < rowCount; j++) {
            if (prefix+" "+mat_names[i]+suffix == price_table.rows[j].cells[3].innerText) { coincidence = true; }
		}
        if (coincidence == false) {
            row = price_table.insertRow(rowCount);
            row.style.backgroundColor = "#F0FFFF";
            cell=row.insertCell(0);
            cell.innerHTML='<td><number_label>'+rowCount+'</number_label> </td>';
            cell=row.insertCell(1);
            cell.innerHTML='<td><copy_row title="Скопировать строку"><b>+</b></copy_row></td>';
            cell=row.insertCell(2);
            cell.innerHTML='<td><del_row title="Удалить строку"><b>–</b></del_row></td>';
            cell=row.insertCell(3);
            cell.innerHTML='<td><label>' + provider + '</label></td>';
            cell=row.insertCell(4);
            cell.innerHTML='<td><label>' + article + '</label></td>';
            cell=row.insertCell(5);
            cell.innerHTML='<td><name_label>' + prefix + " " + mat_names[i] + suffix + '</name_label></td>';
            cell=row.insertCell(6);
            cell.innerHTML='<td><label>' + unit + '</label></td>';
            cell=row.insertCell(7);
            cell.innerHTML='<td><label>' + (Math.ceil(+cost.replace(",",".")*100)/100).toString().replace(".",",") + '</label></td>';
            cell=row.insertCell(8);
            cell.innerHTML='<td><currency_label>' + currency_price + '</currency_label></td>';
            cell=row.insertCell(9);
            cell.innerHTML='<td><label>' + coef.toString().replace(".",",") + '</label></td>';
            cell=row.insertCell(10);
            cell.innerHTML='<td><cost_label>' + (Math.ceil(cost_price*100)/100).toString().replace(".",",") + '</cost_label></td>';
            cell=row.insertCell(11);
            cell.innerHTML='<td><label>' + work + '</label></td>';
            cell=row.insertCell(12);
            cell.innerHTML='<td><label>' + category + '</label></td>';
			cell=row.insertCell(13);
            cell.innerHTML='<td><label>' + code + '</label></td>';
			cell=row.insertCell(14);
            cell.innerHTML='<td><label>' + weight + '</label></td>';
			cell=row.insertCell(15);
            cell.innerHTML='<td><label>' + link + '</label></td>';
		}
	}
    document.getElementById('save_button').disabled = false;
    document.getElementById('save_button').style.backgroundColor = "red";
}
$(document).on( "change paste keyup", ".search_in_prices", function() {
	let filterText = $(this).val();
	let tables = document.querySelectorAll('.price_table');
	Array.from(tables).forEach((table, index) => {
		table.style.display='none';
		let rows = table.rows;
		for (let j = 1; j < rows.length; j++) { rows[j].style.display='table-row'; }
		if (filterText.length > 1) {
			for (let j = 1; j < rows.length; j++) {
				if (rows[j].style.display!='none') {
					let name_price = rows[j].cells[5].textContent.toLowerCase();
					if (name_price.indexOf(filterText.toLowerCase()) != -1) {
						table.style.display='block';
						rows[j].style.display='table-row';
						} else {
						rows[j].style.display='none';
					}
				}
			}
			number = 0;
			for (let j = 1; j < rows.length; j++) {
				if (rows[j].style.display!='none') {
					number += 1;
					rows[j].cells[0].innerHTML='<td><number_label>'+number+'</number_label></td>';
				}
			}
		}
	});
});
$(document).on( "change paste keyup", ".search_row", function() {
    let this_table_id = $(this).attr('table_id');
    let table = document.getElementById(this_table_id);
    let rows = table.rows;
    for (let i = 1; i < rows.length; i++) { rows[i].style.display='table-row'; }
    const elements = document.querySelectorAll('.search_row');
    Array.from(elements).forEach((element, index) => {
        let filterText = element.value;
		if (filterText.length > 1) {
			let cell_number = element.parentNode.cellIndex;
			let table_id = element.getAttribute('table_id');
			if (this_table_id == table_id) {
				for (let i = 1; i < rows.length; i++) {
					if (rows[i].style.display!='none') {
						let name_price = rows[i].cells[cell_number].textContent.toLowerCase();
						if ((cell_number==12) && (filterText!="")) {
						if (name_price != filterText.toLowerCase()) { rows[i].style.display='none'; } }
						else { if (name_price.indexOf(filterText.toLowerCase()) == -1) { rows[i].style.display='none'; }
						else { rows[i].style.display='table-row'; } }
					}
				}
			}
		}
	});
    number = 0;
    for (let i = 1; i < rows.length; i++) {
        if (rows[i].style.display!='none') {
            number += 1;
            rows[i].cells[0].innerHTML='<td><number_label>'+number+'</number_label></td>';
		}
	}
});
function load_file(price_file,price_array,param_list) {
    $('#prices_table').append('<table class="category_table" id="category_'+price_file.replace(/ /g,"_")+'" ></table>');
    let	table = document.getElementById("category_"+price_file.replace(/ /g,"_"));
    let rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<div attr-table="'+price_file.replace(/ /g,"_")+'" class="delete_category" title="Удалить таблицу"><b> x </b></div>';
	cell=row.insertCell(1);
    cell.innerHTML='<div attr-table="'+price_file.replace(/ /g,"_")+'" class="category" title="Скрыть/показать таблицу"><b> ► </b></div>';
    cell=row.insertCell(2);
    cell.innerHTML='<cut_label class="category_name" id="cat_'+price_file.replace(/ /g,"_")+'"><b>'+price_file.replace(/ /g,"_")+'</b></cut_label>';
    cell=row.insertCell(3);
    cell.innerHTML='<img src="cont/style/from_folder.png" class="add_path" title="Добавить названия файлов из папки" id="add_path_'+price_file.replace(/ /g,"_")+'"></img>';
    $('#prices_table').append('<table attr-old="'+price_file+'" class="price_table" id="'+price_file.replace(/ /g,"_")+'" ></table>');
    table = document.getElementById(price_file.replace(/ /g,"_"));
    table.innerHTML = '<th>№</th><th></th><th></th><th><header_label title="Применить значение первой строки ко всем остальным">Поставщик</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Артикул</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Наименование</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Ед.</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Цена</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Вал</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Коэф</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Итог. Цена</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Работа</header_label></th><th><header_label title="Применить значение первой строки ко всем остальным">Категория</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Код</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Вес</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th><th><header_label title="Применить значение первой строки ко всем остальным">Ссылка</header_label>\n<input class="search_row" placeholder="фильтр" table_id="'+price_file.replace(/ /g,"_")+'"></input></th>';
    
    for (let i = 0; i < price_array.length; i++) {
	    let mat_price = price_array[i];
        
        let provider = "-----";
        if ((mat_price[0]) && (mat_price[0] != "")) {
            provider = mat_price[0];
		}
        let article = "-----";
        if ((mat_price[1]) && (mat_price[1] != "")) {
            article = mat_price[1];
		}
		let name_price = mat_price[2];
        let unit_price = mat_price[3];
        let cost = mat_price[4];
        let currency_price = mat_price[5];
        let coef = mat_price[6];
        let cost_price = mat_price[7];
        let work = "0";
        if ((mat_price[8]) && (mat_price[8] != "")) {
            work = mat_price[8];
		}
        let category = "0";
        if ((mat_price[9]) && (mat_price[9] != "")) {
            category = mat_price[9];
		}
		let code = "-----";
        if ((mat_price[10]) && (mat_price[10] != "")) {
            code = mat_price[10];
		}
		let weight = "-----";
        if ((mat_price[11]) && (mat_price[11] != "")) {
            weight = mat_price[11];
		}
		let link = "-----";
        if ((mat_price[12]) && (mat_price[12] != "")) {
            link = mat_price[12];
		}
        let rowCount = table.rows.length;
        row = table.insertRow(rowCount);
        if (i % 2 === 0) {row.style.backgroundColor = "#f0f0f0"; }
        cell=row.insertCell(0);
        cell.innerHTML='<td><number_label>'+rowCount+'</number_label> </td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td><copy_row title="Скопировать строку"><b>+</b></copy_row></td>';
        cell=row.insertCell(2);
        cell.innerHTML='<td><del_row title="Удалить строку"><b>–</b></del_row></td>';
        cell=row.insertCell(3);
        cell.innerHTML='<td><label>' + provider + '</label></td>';
        cell=row.insertCell(4);
        cell.innerHTML='<td><label>' + article + '</label></td>';
        cell=row.insertCell(5);
        cell.innerHTML='<td><name_label>' + name_price + '</name_label></td>';
        cell=row.insertCell(6);
        cell.innerHTML='<td><label>' + unit_price + '</label></td>';
        cell=row.insertCell(7);
        cell.innerHTML='<td><label>' + (Math.ceil(+cost.replace(",",".")*100)/100).toString().replace(".",",") + '</label></td>';
        cell=row.insertCell(8);
        cell.innerHTML='<td><currency_label>' + currency_price + '</currency_label></td>';
        cell=row.insertCell(9);
        cell.innerHTML='<td><label>' + coef + '</label></td>';
        cell=row.insertCell(10);
        cell.innerHTML='<td><cost_label>' + (Math.ceil(+cost_price.replace(",",".")*100)/100).toString().replace(".",",") + '</cost_label></td>';
        cell=row.insertCell(11);
        cell.innerHTML='<td><label>' + work + '</label></td>';
        cell=row.insertCell(12);
        cell.innerHTML='<td><label>' + category + '</label></td>';
		cell=row.insertCell(13);
		cell.innerHTML='<td><label>' + code + '</label></td>';
		cell=row.insertCell(14);
		cell.innerHTML='<td><label>' + weight + '</label></td>';
		cell=row.insertCell(15);
		cell.innerHTML='<td><label>' + link + '</label></td>';
	}
    if (param_list != []) { 
        for (let param of param_list) {
            if (param.split("=>")[0] == price_file.replace(/ /g,"_")) { 
                if (param.split("=>")[1] == "0") { 
                    table.style.display='none';
                    document.getElementById('add_path_'+price_file.replace(/ /g,"_")).style.display='none';
				}
			}
		}
	}
}
function load_discount_file(price_file,price_array,param_list) {
    $('#prices_table').append('<table class="category_table" id="category_'+price_file.replace(/ /g,"_")+'" ></table>');
    let	table = document.getElementById("category_"+price_file.replace(/ /g,"_"));
    let rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<div attr-table="'+price_file.replace(/ /g,"_")+'" class="category" title="Скрыть/показать таблицу"><b> ► </b></div>';
    cell=row.insertCell(1);
    cell.innerHTML='<cut_label class="category_name" id="cat_'+price_file.replace(/ /g,"_")+'"><b> '+price_file.replace(/ /g,"_")+'</b></cut_label>';
    $('#prices_table').append('<table attr-old="'+price_file+'" class="price_table" id="'+price_file.replace(/ /g,"_")+'" ></table>');
    table = document.getElementById(price_file.replace(/ /g,"_"));
    table.innerHTML = '<th>№</th><th></th><th></th><th></th><th></th><th title="Применить значение первой строки ко всем остальным">Наименование</th><th title="Применить значение первой строки ко всем остальным">Значение</th>';
    for (let i = 0; i < price_array.length; i++) {
        let mat_price = price_array[i]
        let name_price = mat_price[2];
        let value = mat_price[14];
        
        let rowCount = table.rows.length;
        row = table.insertRow(rowCount);
        if (i % 2 === 0) {row.style.backgroundColor = "#f0f0f0"; }
        cell=row.insertCell(0);
        cell.innerHTML='<td><number_label>'+rowCount+'</number_label> </td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td ><copy_discount_row title="Скопировать строку"><b>+</b></copy_discount_row></td>';
        cell=row.insertCell(2);
        cell.innerHTML='<td ><del_row title="Удалить строку"><b>–</b></del_row></td>';
        cell=row.insertCell(3);
        cell.innerHTML='<td ></td>';
        cell=row.insertCell(4);
        cell.innerHTML='<td ></td>';
        cell=row.insertCell(5);
        cell.innerHTML='<td ><name_label>' + name_price + '</name_label></td>';
        cell=row.insertCell(6);
        cell.innerHTML='<td ><name_label>' + value + '</name_label></td>';
	}
    if (param_list != []) { 
        for (let param of param_list) {
            if (param.split("=>")[0] == price_file.replace(/ /g,"_")) { 
                if (param.split("=>")[1] == "0") { 
                    table.style.display='none';
				}
			}
		}
	}
}
$(document).on( "click", ".delete_category", function(e) {
    category = e.target.parentNode.getAttribute("attr-table");
	prices_table = document.getElementById('prices_table');
	prices_table.removeChild(document.getElementById(category));
	prices_table.removeChild(document.getElementById('category_'+category));
    sketchup.get_price_data('cat_delete=>'+category);
});
$(document).on( "click", ".category", function(e) {
    category = e.target.parentNode.getAttribute("attr-table");
    let	table = document.getElementById(category);
    let add_path = document.getElementById('add_path_'+category);
    if ($(table).is(":visible")) {
        table.style.display='none';
        if (add_path) { add_path.style.display='none'; }
	}
    else { 
        table.style.display='block';
        if (add_path) { add_path.style.display='block'; }
	}
    let hidden_tables = [];
    let	tables = document.getElementsByClassName("price_table");
    for (let table_category of tables) {
        if ($(table_category).is(":visible")) { hidden_tables.push(table_category.getAttribute("id") + "=>1") }
        else { hidden_tables.push(table_category.getAttribute("id") + "=>0") }
	}
    sketchup.get_price_data('cat_hidden=>'+hidden_tables);
});
$(document).on( "click", "copy_row", function(e) {
    let	table = e.target.parentNode.parentNode.parentNode.parentNode;
    let e_row = e.target.parentNode.parentNode.parentNode;
    let row_index = e_row.rowIndex+1
    let provider = e_row.cells[3].textContent;
    let article = e_row.cells[4].textContent;
    let name_price = e_row.cells[5].textContent;
    let unit_price = e_row.cells[6].textContent;
    let cost = e_row.cells[7].textContent;
    let currency_price = e_row.cells[8].textContent;
    let coef = e_row.cells[9].textContent;
    let cost_price = e_row.cells[10].textContent;
    let work = e_row.cells[11].textContent;
    let category = e_row.cells[12].textContent;
	let code = e_row.cells[13].textContent;
	let weight = e_row.cells[14].textContent;
	let link = e_row.cells[15].textContent;
    row = table.insertRow(row_index);
    cell=row.insertCell(0);
    cell.innerHTML='<td><number_label></number_label> </td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td ><copy_row title="Скопировать строку"><b>+</b></copy_row></td>';
    cell=row.insertCell(2);
    cell.innerHTML='<td ><del_row title="Удалить строку"><b>–</b></del_row></td>';
    cell=row.insertCell(3);
    cell.innerHTML='<td ><label>' + provider + '</label></td>';
    cell=row.insertCell(4);
    cell.innerHTML='<td ><label>' + article + '</label></td>';
    cell=row.insertCell(5);
    cell.innerHTML='<td ><name_label>' + name_price + '</name_label></td>';
    cell=row.insertCell(6);
    cell.innerHTML='<td ><label>' + unit_price + '</label></td>';
    cell=row.insertCell(7);
    cell.innerHTML='<td ><label>' + cost + '</label></td>';
    cell=row.insertCell(8);
    cell.innerHTML='<td ><currency_label>' + currency_price + '</currency_label></td>';
    cell=row.insertCell(9);
    cell.innerHTML='<td ><label>' + coef + '</label></td>';
    cell=row.insertCell(10);
    cell.innerHTML='<td ><cost_label>' + cost_price + '</cost_label></td>';
    cell=row.insertCell(11);
    cell.innerHTML='<td ><label>' + work + '</label></td>';
    cell=row.insertCell(12);
    cell.innerHTML='<td ><label>' + category + '</label></td>';
	cell=row.insertCell(13);
	cell.innerHTML='<td><label>' + code + '</label></td>';
	cell=row.insertCell(14);
	cell.innerHTML='<td><label>' + weight + '</label></td>';
	cell=row.insertCell(15);
	cell.innerHTML='<td><label>' + link + '</label></td>';
    $('tr:not(:first)').each(function(j, tr) {
        $tr = $(tr);
        let name_price = $.trim($tr.find('td:nth-child(5)').text());
        let unit_price = $.trim($tr.find('td:nth-child(6)').text());
        let cost_price = $.trim($tr.find('td:nth-child(10)').text());
        if ((name_price == "Наименование") || (unit_price == "Ед.") || (cost_price == "Цена")) {
            table.deleteRow(j + 1);
		}
	});
});
$(document).on( "click", "copy_discount_row", function(e) {
    let	table = e.target.parentNode.parentNode.parentNode.parentNode;
    let e_row = e.target.parentNode.parentNode.parentNode;
    let row_index = e_row.rowIndex+1
    let name_price = e_row.cells[5].textContent;
    let value = e_row.cells[6].textContent;
    row = table.insertRow(row_index);
    cell=row.insertCell(0);
    cell.innerHTML='<td><number_label></number_label> </td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td ><copy_discount_row title="Скопировать строку"><b>+</b></copy_discount_row></td>';
    cell=row.insertCell(2);
    cell.innerHTML='<td ><del_row title="Удалить строку"><b>–</b></del_row></td>';
    cell=row.insertCell(3);
    cell.innerHTML='<td ></td>';
    cell=row.insertCell(4);
    cell.innerHTML='<td ></td>';
    cell=row.insertCell(5);
    cell.innerHTML='<td ><name_label>' + name_price + '</name_label></td>';
    cell=row.insertCell(6);
    cell.innerHTML='<td ><name_label>' + value + '</name_label></td>';
});
$(document).on( "click", "del_row", function(e) {
    let delBlock = e.target.parentNode.parentNode.parentNode.parentNode;
    delBlock.removeChild(e.target.parentNode.parentNode.parentNode);
    document.getElementById('save_button').disabled = false;
    document.getElementById('save_button').style.backgroundColor = "red";
});
$(document).on( "click", "new_table", function(e) {
    let delBlock = e.target.parentNode.parentNode.parentNode.parentNode.parentNode;
    delBlock.parentNode.removeChild(delBlock);
    let number_cut = 1;
    for (let i = 1; i < 100; i++) {
        let new_table_id = document.getElementById("_Новая_категория_" + i);
        if (new_table_id == null) { number_cut = i; break; }
	}
	price_file = '_Новая_категория_' + number_cut;
	$('#prices_table').append('<table class="category_table" id="category_'+price_file.replace(/ /g,"_")+'" ></table>');
    let	table = document.getElementById("category_"+price_file.replace(/ /g,"_"));
    let rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<div attr-table="'+price_file.replace(/ /g,"_")+'" class="delete_category" title="Удалить таблицу"><b> x </b></div>';
	cell=row.insertCell(1);
    cell.innerHTML='<div attr-table="'+price_file.replace(/ /g,"_")+'" class="category" title="Скрыть/показать таблицу"><b> ► </b></div>';
    cell=row.insertCell(2);
    cell.innerHTML='<cut_label class="category_name" id="cat_'+price_file.replace(/ /g,"_")+'"><b>'+price_file.replace(/ /g,"_")+'</b></cut_label>';
    cell=row.insertCell(3);
    cell.innerHTML='<img src="cont/style/from_folder.png" class="add_path" title="Добавить названия файлов из папки" id="add_path_'+price_file.replace(/ /g,"_")+'"></img>';
    $('#prices_table').append('<table attr-old="'+price_file+'" class="price_table" id="'+price_file.replace(/ /g,"_")+'" ></table>');
    table = document.getElementById(price_file.replace(/ /g,"_"));
    table.innerHTML = '<th>№</th><th></th><th></th><th title="Применить значение первой строки ко всем остальным">Поставщик</th><th title="Применить значение первой строки ко всем остальным">Артикул</th><th title="Применить значение первой строки ко всем остальным">Наименование</th><th title="Применить значение первой строки ко всем остальным">Ед.</th><th title="Применить значение первой строки ко всем остальным">Цена</th><th title="Применить значение первой строки ко всем остальным">Вал</th><th title="Применить значение первой строки ко всем остальным">Коэф</th><th title="Применить значение первой строки ко всем остальным">Итог. Цена</th><th title="Применить значение первой строки ко всем остальным">Работа</th><th title="Применить значение первой строки ко всем остальным">Категория</th><th title="Применить значение первой строки ко всем остальным">Код</th><th title="Применить значение первой строки ко всем остальным">Вес</th><th title="Применить значение первой строки ко всем остальным">Ссылка</th>';
    rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<td><number_label>'+rowCount+'</number_label> </td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td ><copy_row title="Скопировать строку"><b>+</b></copy_row></td>';
    cell=row.insertCell(2);
    cell.innerHTML='<td ><del_row title="Удалить строку"><b>–</b></del_row></td>';
    cell=row.insertCell(3);
    cell.innerHTML='<td ><label>-----</label></td>';
    cell=row.insertCell(4);
    cell.innerHTML='<td ><label>-----</label></td>';
    cell=row.insertCell(5);
    cell.innerHTML='<td ><name_label>Новая строка</name_label></td>';
    cell=row.insertCell(6);
    cell.innerHTML='<td ><label>шт</label></td>';
    cell=row.insertCell(7);
    cell.innerHTML='<td ><label>100</label></td>';
    cell=row.insertCell(8);
    cell.innerHTML='<td ><currency_label>RUB</currency_label></td>';
    cell=row.insertCell(9);
    cell.innerHTML='<td ><label>2</label></td>';
    cell=row.insertCell(10);
    cell.innerHTML='<td ><label>200</label></td>';
    cell=row.insertCell(11);
    cell.innerHTML='<td ><label>0</label></td>';
    cell=row.insertCell(12);
    cell.innerHTML='<td ><label>1</label></td>';
	cell=row.insertCell(13);
    cell.innerHTML='<td ><label>-----</label></td>';
	cell=row.insertCell(14);
    cell.innerHTML='<td ><label>-----</label></td>';
	cell=row.insertCell(15);
    cell.innerHTML='<td ><label>-----</label></td>';
    $('#prices_table').append('<p >');
    $('#prices_table').append('<table class="add_table" id="add_table" ></table>');
    table = document.getElementById('add_table');
    rowCount = table.rows.length;
    row = table.insertRow(rowCount);
    cell=row.insertCell(0);
    cell.innerHTML='<td ><new_table title="Добавить таблицу"><b>+</b></new_table></td>';
    cell=row.insertCell(1);
    cell.innerHTML='<td ></td>';
    cell=row.insertCell(2);
    cell.innerHTML='<td >Разряд. | Валюта | Сокр.назв.вал.</td>';
    cell=row.insertCell(3);
    str = '<td ><select id="digit_select" >';
    for (let i = 0; i < digit_arr.length; i++) {
        str = str.concat('<option value='+digit_arr[i]+'>'+digit_arr[i]+'</option>');
	}
    str = str.concat('</select></td>');
    cell.innerHTML=str;
    $("#digit_select option[value='"+digit_capacity.replace(",",".")+"']").attr("selected", "selected");
    cell=row.insertCell(4);
    str = '<td ><select id="currency_select" >';
    for (let i = 0; i < currency_arr.length; i++) {
        str = str.concat('<option value='+currency_arr[i]+'>'+currency_arr[i]+'</option>');
	}
    str = str.concat('</select></td>');
    cell.innerHTML=str;
    $("#currency_select option[value='"+currency+"']").attr("selected", "selected");
    cell=row.insertCell(5);
    cell.innerHTML='<td ><currency_name_label>' + currency_name + '</currency_name_label></td>';
    save();
	sketchup.get_price_data('new_category');
});
$(document).on( "click", "name_label", function(e) {
    let t = e.target || e.srcElement;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'textarea')	{return false;}
    let val = $(this).html();
    $(this).empty().append('<textarea type="text" id="edit" >' + val + '</textarea>');
    $('#edit').focus();
    $('#edit').select();
    $('#edit').blur(function()	{
        let val = $(this).val();
        $(this).parent().empty().html(val);
        document.getElementById('save_button').disabled = false;
        document.getElementById('save_button').style.backgroundColor = "red";
	});
});
$(document).on( "click", "cut_label", function(e) {
    let t = e.target || e.srcElement;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'textarea')	{return false;}
    let val = $(this).text();
    $(this).empty().append('<textarea type="text" id="edit" >' + val + '</textarea>');
    $('#edit').focus();
    $('#edit').select();
    $('#edit').blur(function()	{
        let val = $(this).val();
        $(this).parent().empty().html('<b>'+val+'</b>');
        document.getElementById('save_button').disabled = false;
        document.getElementById('save_button').style.backgroundColor = "red";
	});
});
$(document).on( "click", "label", function(e) {
    let rng, sel;
    let t = e.target || e.srcElement;
    let row = t.parentNode.parentNode;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'input')	{return false;}
    let val = $(this).html();
    $(this).empty().append('<input type="text" id="edit" value="'+val+'" />');
    $('#edit').focus();
    $('#edit').select();
    $('#edit').blur(function()	{
        let val = $(this).val();
        $(this).parent().empty().html(val);
        let cost_price = (+row.cells[7].innerText.replace(",","."))*(+row.cells[9].innerText.replace(",","."));
        row.cells[10].innerHTML = '<cost_label>' + (Math.ceil(cost_price*100)/100).toString().replace(".",",") + '</cost_label>';
        document.getElementById('save_button').disabled = false;
        document.getElementById('save_button').style.backgroundColor = "red";
	});
});
$(document).on( "click", "currency_name_label", function(e) {
    let rng, sel;
    let t = e.target || e.srcElement;
    let row = t.parentNode.parentNode;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'input')	{return false;}
    let val = $(this).html();
    $(this).empty().append('<input type="text" id="edit" value="'+val+'" />');
    $('#edit').focus();
    $('#edit').select();
    $('#edit').blur(function()	{
        let val = $(this).val();
        $(this).parent().empty().html(val);
        document.getElementById('save_button').disabled = false;
        document.getElementById('save_button').style.backgroundColor = "red";
	});
});
$(document).on( "click", "currency_label", function(e) {
    let rng, sel;
    let t = e.target || e.srcElement;
    let row = t.parentNode.parentNode;
    let elm_name = t.tagName.toLowerCase();
    if (elm_name == 'select')	{return false;}
    let val = $(this).html();
    let str = '<select id="edit" >';
    for (let i = 0; i < currency_arr.length; i++) {
        str = str.concat('<option value='+currency_arr[i]+'>'+currency_arr[i]+'</option>');
	}
    str = str.concat('</select>');
    $(this).empty().append(str);
    $('#edit option:contains('+val+')').prop('selected', true);
    $('#edit').focus();
    $('#edit').select();
    $('#edit').blur(function()	{
        let val = $(this).val();
        $(this).parent().empty().html(val);
        document.getElementById('save_button').disabled = false;
        document.getElementById('save_button').style.backgroundColor = "red";
	});
});
$(document).on( "click", "#digit_select", function(e) {
    document.getElementById('save_button').disabled = false;
    document.getElementById('save_button').style.backgroundColor = "red";
});
$(document).on( "click", "#currency_select", function(e) {
    document.getElementById('save_button').disabled = false;
    document.getElementById('save_button').style.backgroundColor = "red";
});
$(document).on( "click", "header_label", function(e) {
    let t = e.target || e.srcElement;
    t = t.parentNode;
    let table = t.parentNode.parentNode.parentNode;
    let col_number = t.cellIndex;
    let rows = table.rows;
    let visible_rows = [];
    for (let i = 1; i < rows.length; i++) {
        if (rows[i].style.display != "none") {visible_rows.push(rows[i]);}
	}
    console.log(visible_rows)
    let content = visible_rows[0].cells[col_number].innerText;
    for (let i = 1; i < visible_rows.length; i++) {
        visible_rows[i].cells[col_number].innerHTML = content;
        visible_rows[i].cells[10].innerHTML = (+visible_rows[i].cells[7].innerText.replace(",","."))*(+visible_rows[i].cells[9].innerText.replace(",","."));
	}
    document.getElementById('save_button').disabled = false;
    document.getElementById('save_button').style.backgroundColor = "red";
});
$(window).keydown(function(event){
	if(event.keyCode == 13) {
		$('#edit').blur();
	}
});
$(document).on( "click", "#save_button", function() {
    save();
});
function save() {
	let	price_tables = document.getElementsByClassName('price_table');
    let	add_table = document.getElementById('add_table');
	
	digit_select = add_table.rows[add_table.rows.length-1].cells[3].childNodes[0];
    digit_capacity = digit_select.options[digit_select.options.selectedIndex].value.replace(".",",");
	
    currency_select = add_table.rows[add_table.rows.length-1].cells[4].childNodes[0];
    currency = currency_select.options[currency_select.options.selectedIndex].value;
    
    currency_name = add_table.rows[add_table.rows.length-1].cells[5].textContent;
    sketchup.get_price_data('save_currency=>'+currency+'=>'+currency_name);
    for (let table of price_tables) {
        if (table.id == "Акции") {
            let	file_name = document.getElementById('cat_'+table.id).innerText;
            let old_price_file = table.getAttribute("attr-old");
            save_discount_xml(table,old_price_file,file_name.trim(),digit_capacity);
            } else {
            let	file_name = document.getElementById('cat_'+table.id).innerText;
            let old_price_file = table.getAttribute("attr-old");
            save_xml(table,old_price_file,file_name.trim(),digit_capacity);
		}
	}
    document.getElementById('save_button').disabled = true;
    document.getElementById('save_button').style.backgroundColor = "buttonface";
}
$(document).on( "click", "#export_price", function() {
    let	price_tables = document.getElementsByClassName('price_table');
    let	add_table = document.getElementById('add_table');
	
    digit_select = add_table.rows[add_table.rows.length-1].cells[3].childNodes[0];
    digit_capacity = digit_select.options[digit_select.options.selectedIndex].value.replace(".",",");
    
    currency_select = add_table.rows[add_table.rows.length-1].cells[4].childNodes[0];
    currency = currency_select.options[currency_select.options.selectedIndex].value;
    
    currency_name = add_table.rows[add_table.rows.length-1].cells[5].textContent;
    sketchup.get_price_data('export_price>'+currency+'=>'+currency_name);
    for (let table of price_tables) {
        if (table.id == "Акции") {
            let	file_name = document.getElementById('cat_'+table.id).innerText;
            let old_price_file = table.getAttribute("attr-old");
            save_discount_xml(table,old_price_file,file_name.trim(),digit_capacity,true);
            } else {
            let	file_name = document.getElementById('cat_'+table.id).innerText;
            let old_price_file = table.getAttribute("attr-old");
            save_xml(table,old_price_file,file_name.trim(),digit_capacity,true);
		}
	}
});
function save_xml(table,old_price_file,file_name,digit_capacity,export_price=false){
    let xml = "";
    xml+= '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml+= '<Database>\n';
    xml+= '\t<Materials>\n'
    for (let i = 1, tr; tr = table.rows[i]; i++) {
        $tr = $(tr);
        xml += '\t\t<Material>\n';
        
        let provider = $.trim($tr.find('td:nth-child(4)').text());
        xml += '\t\t\t<Provider>'+provider+'</Provider>\n';
        
        let article = $.trim($tr.find('td:nth-child(5)').text());
        xml += '\t\t\t<Article>'+article+'</Article>\n';
        
        let name_price = $.trim($tr.find('td:nth-child(6)').text());
        xml += '\t\t\t<Name>'+name_price+'</Name>\n';
        
        let unit_price = $.trim($tr.find('td:nth-child(7)').text());
        xml += '\t\t\t<Unit_Measure>'+unit_price+'</Unit_Measure>\n';
        
        let cost = $.trim($tr.find('td:nth-child(8)').text());
        xml += '\t\t\t<Cost>'+cost.replace(".",",")+'</Cost>\n';
        
        let currency = $.trim($tr.find('td:nth-child(9)').text());
        xml += '\t\t\t<Currency>'+currency+'</Currency>\n';
        
        let coef = $.trim($tr.find('td:nth-child(10)').text());
        xml += '\t\t\t<Coef>'+coef.replace(".",",")+'</Coef>\n';
        
        let cost_price = $.trim($tr.find('td:nth-child(11)').text());
        xml += '\t\t\t<Price>'+cost_price.replace(".",",")+'</Price>\n';
        
        let work = $.trim($tr.find('td:nth-child(12)').text());
        xml += '\t\t\t<Work>'+work.replace(".",",")+'</Work>\n';
        
        let category = $.trim($tr.find('td:nth-child(13)').text());
        xml += '\t\t\t<Category>'+category+'</Category>\n';
		
		let code = $.trim($tr.find('td:nth-child(14)').text());
        xml += '\t\t\t<Code>'+code+'</Code>\n';
		
		let weight = $.trim($tr.find('td:nth-child(15)').text());
        xml += '\t\t\t<Weight>'+weight+'</Weight>\n';
		
		let link = $.trim($tr.find('td:nth-child(16)').text());
        xml += '\t\t\t<Link>'+link+'</Link>\n';
        
        xml+= '\t\t\t<Digit_capacity>'+digit_capacity+'</Digit_capacity>\n';
        
        xml += '\t\t</Material>\n';
	}
    if (digit_capacity.indexOf("0") == -1) { digit_capacity = "0" }
    
    xml+= '\t</Materials>\n';
    xml+= '</Database>\n';
    if (export_price==true) { sketchup.get_price_data('export_xml=>'+file_name+'=>'+xml); }
    else { sketchup.get_price_data('delete_xml=>'+old_price_file);
        if (file_name != "") { sketchup.get_price_data('save_xml=>'+file_name+'=>'+xml); }
	}
}
function save_discount_xml(table,old_price_file,file_name,digit_capacity,export_price=false){
    let xml = "";
    xml+= '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml+= '<Database>\n';
    xml+= '\t<Materials>\n'
    for (let i = 1, tr; tr = table.rows[i]; i++) {
        $tr = $(tr);
        xml += '\t\t<Material>\n';
        
        let name_price = $.trim($tr.find('td:nth-child(6)').text());
        xml += '\t\t\t<Name>'+name_price+'</Name>\n';
        
        let value = $.trim($tr.find('td:nth-child(7)').text());
        xml += '\t\t\t<Value>'+value+'</Value>\n';
        
        xml += '\t\t</Material>\n';
	}
    
    xml+= '\t</Materials>\n';
    xml+= '</Database>\n';
    if (export_price==true) { sketchup.get_price_data('export_xml=>'+file_name+'=>'+xml); }
    else { sketchup.get_price_data('delete_xml=>'+old_price_file);
        if (file_name != "") { sketchup.get_price_data('save_xml=>'+file_name+'=>'+xml); }
	}
}
$(document).on( "click", "#import_price", function() {
    sketchup.get_price_data('import_price');
});

