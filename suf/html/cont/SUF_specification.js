var product = "Кухня";
var count_of_discount = 0;
var total = 0;
var total_cost = 0;
var total_cost_without_discount = 0;
var total_discount = 0;
var total_cost_with_discount = 0;
var discount1,discount2,discount3;
var discount_array = [];
var discount_cost_array = [];
var oversize_count = 0;
var install_appliances = 0;
var tech_list = [];
var path_price;
var total_net_cost = 0;
var total_instal_cost = 0;
var prepayment = 70;
var prepayment_cost = 0;
var contract_cost = 0;
var show_net = 0;
var production_time_table;
var excel_table_new = "";
var google_table = "";
var delivery_cost;
var lifting_furniture;
var sep = ",";
var contract = "false";
var mat_name = "";
var cost_coef = "";
var logo_file = "./cont/style/LOGO.jpeg";
var number,date,address,customer,customer_phone,e_mail,product,delivery_address,designer,designer_phone,client_service_phone,production_time,floor,lift,distance,markup_from_param,module_volume,module_count,worktop_count,install_cost,min_delivery_cost,delivery_distance,min_lifting_furniture,lifting_module,lifting_worktop,cp_checkbox;
var install_sink,connection_washing,install_mixer,connection_mixer,install_PMM,connection_PMM,install_hood,connection_hood,install_hob,connection_hob,install_DS,connection_DS,install_SVH,connection_SVH,install_fridge,connection_fridge,install_washer,connection_washer;
var last_zero = 0;
//$(window).on('load', function () { $('#p_prldr').delay(500).fadeOut('slow'); });
document.addEventListener('DOMContentLoaded', function() { sketchup.get_data("read_param"); }, false);
function formatDate() {
    let current_date=new Date();
    let dd = current_date.getDate();
    if (dd < 10) dd = '0' + dd;
    let mm = current_date.getMonth() + 1;
    if (mm < 10) mm = '0' + mm;
    let yy = current_date.getFullYear();
    return dd + '.' + mm + '.' + yy;
}
function specifications(s){
    //console.log(s)
    $('#p_prldr').delay(500).fadeOut('slow');
    let specification;
    $.each( discount_content.discounts, function( key, val ) { 
        if (val.name == "Общая наценка") { markup_from_param = parseFloat(val.value.replace(",",".")); }
	});
    for (let i = 0; i < s.length; i++) {
        if (s[i] == "sep") { sep=s[i+1]; }
        if (s[i] == "logo_file") { logo_file=s[i+1]; }
        if (s[i] == "number") { number=s[i+1]; }
        if (s[i] == "date") { date=s[i+1]; }
        if (s[i] == "discount1") { discount1=s[i+1]; }
        if (s[i] == "discount2") { discount2=s[i+1]; }
        if (s[i] == "discount3") { discount3=s[i+1]; }
        if (s[i] == "customer") { customer=s[i+1]; }
        if (s[i] == "customer_phone") { customer_phone=s[i+1]; }
        if (s[i] == "e_mail") { e_mail=s[i+1]}
        if (s[i] == "product") { product=s[i+1]}
        if (s[i] == "delivery_address") { delivery_address=s[i+1]; }
        if (s[i] == "floor") { floor=+s[i+1]; }
        if (s[i] == "lift") { lift=s[i+1]; }
        if (s[i] == "distance") { distance=+s[i+1]; }
        if (s[i] == "designer") { designer=s[i+1]; }
        if (s[i] == "designer_phone") { designer_phone=s[i+1]; }
        if (s[i] == "client_service_phone") { client_service_phone=s[i+1]; }
        if (s[i] == "production_time") { production_time=s[i+1]; }
        if (s[i] == "prepayment") { prepayment=+s[i+1].slice(0, -1); }
        if (s[i] == "install_cost") { install_cost=+s[i+1].slice(0, -1); }
        if (s[i] == "last_zero") { last_zero=+s[i+1]; }
        if (s[i] == "min_delivery_cost") { min_delivery_cost=+s[i+1]; }
        if (s[i] == "delivery_distance") { delivery_distance=+s[i+1]; }
        if (s[i] == "min_lifting_furniture") { min_lifting_furniture=+s[i+1]; }
        if (s[i] == "lifting_module") { lifting_module=+s[i+1]; }
        if (s[i] == "lifting_worktop") { lifting_worktop=+s[i+1]; }
        if (s[i] == "oversize_count") { oversize_count=+s[i+1]; }
        if (s[i] == "cp_checkbox") { cp_checkbox=s[i+1]; }
        if (s[i] == "specification") { specification=s[i+1]; }
        if (s[i] == "access_level") { access_level=s[i+1]; }
        if (s[i] == "install_sink") { install_sink=s[i+1]; }
        if (s[i] == "connection_sink") { connection_sink=s[i+1]; }
        if (s[i] == "install_mixer") { install_mixer=s[i+1]; }
        if (s[i] == "connection_mixer") { connection_mixer=s[i+1]; }
        if (s[i] == "install_PMM") { install_PMM=s[i+1]; }
        if (s[i] == "connection_PMM") { connection_PMM=s[i+1]; }
        if (s[i] == "install_hood") { install_hood=s[i+1]; }
        if (s[i] == "connection_hood") { connection_hood=s[i+1]; }
        if (s[i] == "install_hob") { install_hob=s[i+1]; }
        if (s[i] == "connection_hob") { connection_hob=s[i+1]; }
        if (s[i] == "install_DS") { install_DS=s[i+1]; }
        if (s[i] == "connection_DS") { connection_DS=s[i+1]; }
        if (s[i] == "install_SVH") { install_SVH=s[i+1]; }
        if (s[i] == "connection_SVH") { connection_SVH=s[i+1]; }
        if (s[i] == "install_fridge") { install_fridge=s[i+1]; }
        if (s[i] == "connection_fridge") { connection_fridge=s[i+1]; }
        if (s[i] == "install_washer") { install_washer=s[i+1]; }
        if (s[i] == "connection_washer") { connection_washer=s[i+1]; }
        if (s[i] == "contract") { contract=s[i+1]; }
        if (s[i] == "mat_name") { mat_name=s[i+1].split(','); }
		if (s[i] == "cost_coef") { cost_coef=s[i+1]; }
	}
    //console.log("specifications",specification)
    delivery_cost = min_delivery_cost;
    lifting_furniture = min_lifting_furniture;
    if (specification == "no") {
        let header_table = document.getElementById('header_table');
        if (header_table) {
            document.getElementById('header_table').rows[0].cells[0].innerHTML='Спецификация к договору <b>№'+number+'</b> от <b>'+date+'</b> / Адрес: <b>'+delivery_address+'</b>';
            document.getElementById('client_info_table').rows[0].cells[0].innerHTML='Покупатель: <b>'+customer+'</b>';
            document.getElementById('client_info_table').rows[1].cells[0].innerHTML='Тел. <b>'+customer_phone+'</b> , Изделие: <b>'+product+'</b>';
            document.getElementById('client_info_table').rows[2].cells[0].innerHTML='Адрес доставки: <b>'+delivery_address+'</b>';
            document.getElementById('client_info_table').rows[3].cells[0].innerHTML='Этаж: <b>'+floor+'</b>, Лифт: <b>'+lift+'</b>, Отдаленность: <b>'+distance+'</b> км';
            document.getElementById('client_info_table').rows[4].cells[0].innerHTML='Дизайнер: <b>'+designer+'</b> , Тел. <b>'+designer_phone+'</b>';
		}
        } else {
        $('#specifications_table').empty();
        $('#specifications_table').append('<table id="specification_table" ></table>');
        $('#specification_table').append('<table class="logo_table" id="logo_table" ></table>');
        let	table = document.getElementById('logo_table');
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        if (logo_file == "По умолчанию") { logo_file = "./cont/style/LOGO.png"; }
        cell.innerHTML='<td ><img src="'+logo_file+'" alt="LOGO" ></td>'; 
		
        $('#specification_table').append('<table class="header_table" id="header_table" ></table>');
        table = document.getElementById('header_table');
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        if (date.indexOf("___") != -1) { date = formatDate(); }
        cell.innerHTML='<td >Спецификация к договору <b>№'+number+'</b> от <b>'+date+'</b> / Адрес: <b>'+delivery_address+' </b></td>';
        cell.colSpan = 3
        row = table.insertRow(table.rows.length);
        $('#specification_table').append('<img title="Настройки" id="setup" data-html2canvas-ignore="true" class="setup" src="./cont/style/setup.png">');
        $('#specification_table').append('<img title="Обновить" id="update" data-html2canvas-ignore="true" class="update" src="./cont/style/update.png">');
        $('#specification_table').append('<img title="Экспорт в Google Sheets" id="google_sheets" data-html2canvas-ignore="true" class="google_sheets" src="./cont/style/google_sheets.png">');
        $('#specification_table').append('<img title="Экспорт в Excel" id="excel" data-html2canvas-ignore="true" class="excel" src="./cont/style/excel.png">');
        $('#specification_table').append('<img title="Сохранить спецификацию" id="export_spec" data-html2canvas-ignore="true" class="export_spec" src="./cont/style/export_spec.png">');
        let contract_src = "./cont/style/contract_unchecked.png";
        if (contract == "true") { contract_src = "./cont/style/contract_checked.png"; }
        $('#specification_table').append('<img title="Договор подписан" id="contract_checkbox" data-html2canvas-ignore="true" class="contract_checkbox" src='+contract_src+'>');
        if ((currency_rate[0].indexOf("USD") == -1) && (currency_rate[0].indexOf("EUR") == -1)) {
            $('#specification_table').append('<p id="dollar" data-html2canvas-ignore="true" class="dollar" >$&nbsp;'+currency_rate[1].split("=")[1]+'&nbsp;&nbsp;€&nbsp;'+currency_rate[2].split("=")[1]);
            if (currency_rate[1].split("=")[1] == '1') { document.getElementById('dollar').style.backgroundColor = "red";}
		}
        cell=row.insertCell(0);
        cell.innerHTML='<td ></td>';
        
        cell=row.insertCell(1);
        cell.innerHTML='<table class="discount_table" id="discount_table" ></table>';
        
        cell=row.insertCell(2);
        cell.innerHTML='<table class="total_with_discount_table" id="total_with_discount_table" ></table>';
        
        $('#specifications_table').append('<div class="vertical-line">&nbsp;</div>');
        
        $('#specification_table').append('<table class="spec_table" id="spec1_table" ></table>');
        
        table1 = document.getElementById('spec1_table');
        row = table1.insertRow(table1.rows.length);
        row.innerHTML='<th ><b>№</b></th><th ><b>Наименование</b></th><th ><b>Кол.</b></th><th ><b>Цена</b></th><th ><b>Итого</b></th>';
        cell=row.insertCell(5);
        cell.innerHTML='<th ><b>Себ.цена</b></th>';
        cell.style.display = 'none';
        cell=row.insertCell(6);
        cell.innerHTML='<th ><b>Себ.итого</b></th>';
        cell.style.display = 'none';
        cell=row.insertCell(7);
        cell.innerHTML='<th ><b>Работа</b></th>';
        cell.style.display = 'none';
        row = table1.insertRow(table1.rows.length);
        row.innerHTML='<th ></th><th ><b>Материалы</b></th><th ></th><th ></th><th ></th><th ></th><th ></th><th ></th>';
        $('#specification_table').append('<table class="spec_table" id="spec2_table" ></table>');
        table2 = document.getElementById('spec2_table');
        row = table2.insertRow(table2.rows.length);
        row.innerHTML='<th ><b>№</b></th><th ><b>Наименование</b></th><th ><b>Кол.</b></th><th ><b>Цена</b></th><th ><b>Итого</b></th>';
        cell=row.insertCell(5);
        cell.innerHTML='<th ><b>Себ.цена</b></th>';
        cell.style.display = 'none';
        cell=row.insertCell(6);
        cell.innerHTML='<th ><b>Себ.итого</b></th>';
        cell.style.display = 'none';
        cell=row.insertCell(7);
        cell.innerHTML='<th ><b>Работа</b></th>';
        cell.style.display = 'none';
        table = table1;
        if (specification.length > 32) { document.getElementById('spec1_table').style.fontSize = '8.5px'; document.getElementById('spec2_table').style.fontSize = '8.5px'; }
        if (specification.length > 37) { document.getElementById('spec1_table').style.fontSize = '8px'; document.getElementById('spec2_table').style.fontSize = '8px'; }
        if (specification.length > 42) { document.getElementById('spec1_table').style.fontSize = '7.5px'; document.getElementById('spec2_table').style.fontSize = '7.5px'; }
        let specification_number = 0;
        for (let i = 0; i < specification.length; i++ ) {
            let cost_of_this = 0;
            let net_cost = 0;
            let work = 0;
            let provider = '-------';
            let article = '-------';
			let code = '-----';
			let weight = '-----';
			let link = '-----';
            let specification_name = specification[i][0];
            let specification_count = specification[i][1];
            let specification_unit = specification[i][2];
            //console.info("name",specification_name)
            let mat_category = false;
            for (let i = 0; i < mat_name.length; i++ ) {
                if ((mat_category == false) && (typeof specification_name === 'string') && (specification_name.startsWith(mat_name[i]))) { mat_category = true; }
			}
            if ((specification_name.constructor === Array) || (mat_category == true)) {
                if (specification_name.indexOf("ЛДСП 30мм") != -1) { continue; }
                if (specification_name.constructor === Array) {
                    specification_name = specification_name.join('').trim().replace(/\|/g,",");
				}
                if (specification_name.toLowerCase().indexOf("кромка") != -1) { specification_count = Math.ceil(specification_count) }
                if ((specification_name.indexOf("камень") != -1) || (specification_name.indexOf("камня") != -1)) { specification_count = Math.ceil(specification_count/0.25)*0.25; }
				let cost_array = cost_rows(specification[i],false);
                cost_of_this = cost_array[0];
                net_cost = cost_array[1];
                work = cost_array[2];
                provider = ((cost_array[3]=="-------")?"":cost_array[3]);
                article = ((cost_array[4]=="-------")?"":cost_array[4]);
				code = ((cost_array[5]=="-----")?"":cost_array[5]);
				weight = ((cost_array[6]=="-----")?"":cost_array[6]);
				link = ((cost_array[7]=="-----")?"":cost_array[7]);
                cost_of_this += +work;
				specification_number += 1;
                row = table.insertRow(table.rows.length);
                cell=row.insertCell(0);
				let follow = (link.startsWith('http') ? ' class="cost_number" onclick="follow_the_link('+"'"+link+"'"+')" title="'+translate("Follow the link")+':\n'+link+'"' : '')
                cell.innerHTML='<td><label_number'+follow+'>'+specification_number+'</label_number></td>';
                cell=row.insertCell(1);
                cell.innerHTML='<td >'+specification_name+'</td>';
                cell=row.insertCell(2);
                cell.innerHTML='<td ><label_count count_value="'+specification_count+'" unit="'+specification_unit+'">'+specification_count.toString().replace(".",",")+'&nbsp;'+specification_unit+'</label_count></td>';
                
                cell=row.insertCell(3);
                cell.innerHTML='<td ><label name="'+specification_name+'" class="cost_of_this" value="'+(cost_of_this)+'">'+priceSet(cost_of_this)+'</label></td>';
                let elem_cost = specification_count*(cost_of_this);
                if ((cost_of_this == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(4);
                cell.innerHTML='<td ><label name="'+specification_name+'" class="elem_cost" value="'+(elem_cost)+'">'+priceSet(elem_cost)+'</td>';
                if ((cost_of_this == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(5);
                cell.innerHTML='<td ><label value="'+(net_cost)+'">'+priceSet(net_cost)+'</label></td>';
                cell.style.display = 'none';
                let elem_net_cost = specification_count*net_cost;
                total_net_cost += elem_net_cost;
                if ((net_cost == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(6);
                cell.innerHTML='<td ><label value="'+(elem_net_cost)+'">'+priceSet(elem_net_cost)+'</label></td>';
                cell.style.display = 'none';
                if ((net_cost == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(7);
                cell.innerHTML='<td ><label class="work_cost" provider="'+provider+'" article = "'+article+'" code = "'+code+'" weight = "'+weight+'" link = "'+link+'" net_value="'+(work)+'" value="'+(specification_count*work)+'">'+priceSet(specification_count*work)+'</label></td>';
                cell.style.display = 'none';
                
                if ((table == table1) && (table.offsetHeight > 366)) { table = table2; }
			}
		}
        row = table.insertRow(table.rows.length);
        row.innerHTML='<th ></th><th ><b>Фурнитура</b></th><th ></th><th ></th><th ></th><th ></th><th ></th><th ></th>';
        for (let i = 0; i < specification.length; i++ ) {
            let cost_of_this = 0;
            let net_cost = 0;
            let work = 0;
            let provider = '-------';
            let article = '-------';
			let code = '-----';
			let weight = '-----';
			let link = '-----';
            let specification_name = specification[i][0];
            let specification_count = specification[i][1];
            let specification_unit = specification[i][2];
            let mat_category = false;
            for (let i = 0; i < mat_name.length; i++ ) {
                if ((mat_category == false) && (typeof specification_name === 'string') && (specification_name.startsWith(mat_name[i]))) { mat_category = true; }
			}
            if ((typeof specification_name === 'string') && (mat_category == false)) {
                if (specification_name.toLowerCase().indexOf("паз") != -1) { specification_count = Math.ceil(specification_count) }
                specification_name = specification_name.trim().replace("~","=").replace(/\|/g,",").replace(/плюс/g,"+");
                specification_name = specification_name.replace("[","(").replace("]",")");
				let cost_array = cost_rows(specification[i],false);
                cost_of_this = cost_array[0];
                net_cost = cost_array[1];
                work = cost_array[2];
                provider = ((cost_array[3]=="-------")?"":cost_array[3]);
                article = ((cost_array[4]=="-------")?"":cost_array[4]);
				code = ((cost_array[5]=="-----")?"":cost_array[5]);
				weight = ((cost_array[6]=="-----")?"":cost_array[6]);
				link = ((cost_array[7]=="-----")?"":cost_array[7]);
                cost_of_this += +work;
                specification_number += 1;
                row = table.insertRow(table.rows.length);
                cell=row.insertCell(0);
				console.log(link)
                let follow = (link.startsWith('http') ? ' class="cost_number" onclick="follow_the_link('+"'"+link+"'"+')" title="'+translate("Follow the link")+':\n'+link+'"' : '')
                cell.innerHTML='<td><label_number'+follow+'>'+specification_number+'</label_number></td>';
                cell=row.insertCell(1);
                cell.innerHTML='<td >'+specification_name+'</td>';
                cell=row.insertCell(2);
                cell.innerHTML='<td ><label_count count_value="'+specification_count+'" unit="'+specification_unit+'">'+specification_count.toString().replace(".",",")+'&nbsp;'+specification_unit+'</label_count></td>';
                
                cell=row.insertCell(3);
                cell.innerHTML='<td ><label name="'+specification_name+'" class="cost_of_this" value="'+(cost_of_this)+'">'+priceSet(cost_of_this)+'</label></td>';
                let elem_cost = specification_count*(cost_of_this);
                if ((cost_of_this == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(4);
                cell.innerHTML='<td ><label name="'+specification_name+'" class="elem_cost" value="'+(elem_cost)+'">'+priceSet(elem_cost)+'</td>';
                if ((cost_of_this == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(5);
                cell.innerHTML='<td ><label value="'+(net_cost)+'">'+priceSet(net_cost)+'</label></td>';
                cell.style.display = 'none';
                let elem_net_cost = specification_count*net_cost;
                total_net_cost += elem_net_cost;
                if ((net_cost == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(6);
                cell.innerHTML='<td ><label value="'+(elem_net_cost)+'">'+priceSet(elem_net_cost)+'</label></td>';
                cell.style.display = 'none';
                if ((net_cost == 0) && (specification_name.indexOf("рамка") == -1)) { cell.style.backgroundColor = "red";}
                cell=row.insertCell(7);
                cell.innerHTML='<td ><label class="work_cost" provider="'+provider+'" article = "'+article+'" code = "'+code+'" weight = "'+weight+'" link = "'+link+'" net_value="'+(work)+'" value="'+(specification_count*work)+'">'+priceSet(specification_count*work)+'</label></td>';
                cell.style.display = 'none';
                if ((table == table1) && (table.offsetHeight > 366)) { table = table2; }
			}
		}
        $('#specifications_table').append('<table class="client_info_table" id="client_info_table" ></table>');
        let client_info_table = document.getElementById('client_info_table');
        
        let client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Покупатель: <b>'+customer+'</b></td>';
        
        client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Тел. <b>'+customer_phone+'</b> , Изделие: <b>'+product+'</b></td>';
        
        client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Адрес доставки: <b>'+delivery_address+'</b></td>';
        
        client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Этаж: <b>'+floor+'</b>, Лифт: <b>'+lift+'</b>, Отдаленность: <b>'+distance+'</b> км</td>';
        
        client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Дизайнер: <b>'+designer+'</b> , Тел. <b>'+designer_phone+'</b></td>';
        
        client_info_row = client_info_table.insertRow(client_info_table.rows.length);
        cell=client_info_row.insertCell(0);
        cell.innerHTML='<td >Клиентский отдел тел. <b>'+client_service_phone+'</b></td>';
        
        $('#specifications_table').append('<table class="production_time_table" id="production_time_table" ></table>');
        production_time_table = document.getElementById('production_time_table');
        let production_time_row = production_time_table.insertRow(production_time_table.rows.length);
        cell=production_time_row.insertCell(0);
        cell.innerHTML='<td ><b>Срок изготовления '+production_time+' рабочих дней</b></td>';
        
        $('#specifications_table').append('<table class="total_cost_table" id="total_cost_table" ></table>');
        let total_cost_table = document.getElementById('total_cost_table');
        let total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
        cell=total_cost_row.insertCell(0);
        cell.innerHTML='<td ><b>Общая стоимость</b></td>';
        cell=total_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
        cell=total_cost_row.insertCell(0);
        cell.innerHTML='<td ><b>Монтаж </b></td>';
        cell=total_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
        cell=total_cost_row.insertCell(0);
        cell.innerHTML='<td ><b>Доставка (0 '+currency_name+') + Подъем (0 '+currency_name+')</b></td>';
        cell=total_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
        cell=total_cost_row.insertCell(0);
        let tech_str = '<td ><b>Установка техники:';
        for (let i = 0; i < tech_list.length; i++) {
            if (i==0) { tech_str+=' '+tech_list[i][1]+tech_list[i][4] }
            else { tech_str+=', '+tech_list[i][1]+tech_list[i][4] }
            if ( tech_list[i][4] == " (уст.)" ) { install_appliances += +window["install_"+tech_list[i][0]]; }
            if ( tech_list[i][4] == " (уст. и подкл.)" ) {
                let count = 1;
                if (tech_list[i][5] != "0") { count = +tech_list[i][5]; }
                install_appliances += +window["install_"+tech_list[i][0]];
                install_appliances += +window["connection_"+tech_list[i][0]]*count;
			}
		}
        tech_str+='</b></td>';
        cell.innerHTML=tech_str;
        cell=total_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
        cell=total_cost_row.insertCell(0);
        cell.innerHTML='<td ><b>Итого</b></td>';
        cell=total_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        
        $('#specifications_table').append('<table class="total_net_cost_table" id="total_net_cost_table" ></table>');
        let total_net_cost_table = document.getElementById('total_net_cost_table');
        let total_net_cost_row = total_net_cost_table.insertRow(total_net_cost_table.rows.length);
        cell=total_net_cost_row.insertCell(0);
        cell.innerHTML='<td ><b>Общая себестоимость</b></td>';
        cell=total_net_cost_row.insertCell(1);
        cell.innerHTML='<td ><b>'+priceSet(total_net_cost)+' '+currency_name+'</b></td>';
        
        let discount_table = document.getElementById('discount_table');
        let discount_row = discount_table.insertRow(discount_table.rows.length);
        let discount_cell=discount_row.insertCell(0);
        discount_cell.innerHTML='<td ><b>Ваша выгода</b></td>';
        discount_row = discount_table.insertRow(discount_table.rows.length);
        discount_cell=discount_row.insertCell(0);
        discount_cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        
        let total_with_discount_table = document.getElementById('total_with_discount_table');
        let total_with_discount_row = total_with_discount_table.insertRow(total_with_discount_table.rows.length);
        let total_with_discount_cell=total_with_discount_row.insertCell(0);
        total_with_discount_cell.innerHTML='<td ><b>Итоговая цена</b></td>';
        total_with_discount_row = total_with_discount_table.insertRow(total_with_discount_table.rows.length);
        total_with_discount_cell=total_with_discount_row.insertCell(0);
        total_with_discount_cell.innerHTML='<td ><b>0 '+currency_name+'</b></td>';
        
        $('#popUp').empty();
        $('#popUp').append('<span id="close">x</span>');
        $('#popUp').append('<table id="setup_table" ></table>');
        table = document.getElementById('setup_table');
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>№ договора</td>';
        cell=row.insertCell(1);
        if (number.indexOf("___") != -1) {number = ""}
        cell.innerHTML='<td><input id="number" value="'+number+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Дата</td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td><input id="date" value="'+date+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Покупатель</td>';
        cell=row.insertCell(1);
        if (customer.indexOf("___") != -1) {customer = ""}
        cell.innerHTML='<td><input id="customer" value="'+customer+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Телефон</td>';
        cell=row.insertCell(1);
        if (customer_phone.indexOf("___") != -1) {customer_phone = ""}
        cell.innerHTML='<td><input id="customer_phone" value="'+customer_phone+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td >Изделие</td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td><input id="product" value="'+product+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Адрес доставки</td>';
        cell=row.insertCell(1);
        if (delivery_address.indexOf("___") != -1) {delivery_address = ""; address = ""}
        else {address = delivery_address}
        cell.innerHTML='<td><input id="delivery_address" value="'+delivery_address+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Этаж</td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td><input id="floor" value="'+floor+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td >Грузовой лифт</td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td><select id="lift" ><option value="Есть" >Есть</option><option value="Нет" >Нет</option></select></td>';
        $('#lift option:contains("'+lift+'")').prop('selected', true);
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Отдаленность</td>';
        cell=row.insertCell(1);
        cell.innerHTML='<td ><input id="distance" value="'+distance+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Дизайнер</td>';
        cell=row.insertCell(1);
        if (designer.indexOf("___") != -1) {designer = ""}
        cell.innerHTML='<td><input id="designer" value="'+designer+'"></input></td>';
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td>Телефон</td>';
        cell=row.insertCell(1);
        if (designer_phone.indexOf("___") != -1) {designer_phone = ""}
        cell.innerHTML='<td><input id="designer_phone" value="'+designer_phone+'"></input></td>';
        
        $('#popUp').append('<table id="CP_table" ></table>');
        table = document.getElementById('CP_table');
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        cell.innerHTML='<td><input type="checkbox" id="cp_checkbox" ></input></td>';
        if (cp_checkbox == "1") { document.getElementById('cp_checkbox').checked=true; }
        else { document.getElementById('cp_checkbox').checked=false; }
		cell=row.insertCell(1);
        cell.innerHTML='<td>Спецификация для КП</td>';
		cell=row.insertCell(2);
        cell.innerHTML='<td><label_coef id="cost_coef">'+cost_coef+'</label_coef></td>';
        hide_show_cells(cp_checkbox);
        
        $('#popUp').append('<input type="submit" id="save" value="Сохранить" disabled="disabled" onclick="save_changes();">');
        
        $('#popUp').append('<button id="discount" ></button>');
        $('#popUp').append('<button id="net_cost" ></button>');
        if (discount1) { count_of_discount += 1; discount_array.push(discount1); }
        if (discount2) { count_of_discount += 1; discount_array.push(discount2); }
        if (discount3) { count_of_discount += 1; discount_array.push(discount3); }
        let number_of_discount = 0;
        if (count_of_discount != 0) {
            $('#popUp').append('<table id="discounts_table" ></table>');
            table = document.getElementById('discounts_table');
            for (let i = 0; i < discount_array.length; i++) {
                let discount_name = discount_array[i].slice(0,discount_array[i].lastIndexOf("_"));
                let discount = discount_array[i].slice(discount_array[i].lastIndexOf("_")+1);
                number_of_discount = i+1;
                row = table.insertRow(table.rows.length);
                cell=row.insertCell(0);
                content = '<td ><select id="discount'+number_of_discount+'" class="discount_select" number="'+number_of_discount+'" onchange="change_discount(this,'+number_of_discount+');"><option></option>';
                $.each( discount_content.discounts, function( key, val ) { 
                    if (val.name == "Общая наценка") { return false; }
                    content=content.concat('<option value="'+val.value+'" >'+val.name+'</option>');
				});
                content=content.concat('</select></td>');
                cell.innerHTML=content;
                $('#discount'+number_of_discount+' option:contains("'+discount_name+'")').prop('selected', true);
                cell=row.insertCell(1);
                cell.innerHTML='<td ><input class="discount_input" attr-number='+number_of_discount+' value="'+discount+'"></input></td>';
                $('#popUp').animate({ "height": 360+30*count_of_discount }, 300 );
                let total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
                total_cost_row.id = 'row_'+number_of_discount;
                total_cost_row.className = 'discount_row';
                cell=total_cost_row.insertCell(0);
                cell.innerHTML='<td ></td>';
                cell=total_cost_row.insertCell(1);
                cell.innerHTML='<td ></td>'; 
			}
            let total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
            total_cost_row.id = 'row_last';
            cell=total_cost_row.insertCell(0);
            cell.innerHTML='<td ><b>Итого с учетом скидок</b></td>';
            cell=total_cost_row.insertCell(1);
            cell.innerHTML='<td ><b>0'+' '+currency_name+'</b></td>';
            total_cost_table.rows[0].cells[0].innerHTML = '<b>Общая стоимость без учета скидки</b>';
            document.getElementById('discount_table').style.display = 'block';
		}
        
        $('#tech_table').empty();
        $('#tech_table').append('<table class="header_table" id="tech_header_table" ></table>');
        
        table = document.getElementById('tech_header_table');
        row = table.insertRow(table.rows.length);
        cell=row.insertCell(0);
        if (date.indexOf("___") != -1) { date = formatDate(); }
        cell.innerHTML='<td ><b>Спецификация по технике к договору № '+number+' от '+date+' / Адрес: '+delivery_address+' </b></td>';
        $('#logo_table').clone().appendTo("#tech_table");
        $('#tech_table').append('<table class="tech_table" id="tech1_table" ></table>');
        
        table = document.getElementById('tech1_table');
        row = table.insertRow(table.rows.length);
        row.innerHTML='<th><b>№</b></th><th><b>Наименование</b></th><th><b>Кол.</b></th><th><b>Цена</b></th><th><b>Итого</b></th><th><b>Фото</b></th><th><b>Описание</b></th>';
        
        for (let i = 0; i < tech_list.length; i++) {
            row = table.insertRow(table.rows.length);
            cell=row.insertCell(0);
            cell.innerHTML='<td>'+(i+1)+'</td>';
            cell=row.insertCell(1);
            cell.innerHTML='<td>'+tech_list[i][1]+" "+tech_list[i][2]+'</td>';
            cell=row.insertCell(2);
            cell.innerHTML='<td>'+tech_list[i][5]+'</td>';
            cell=row.insertCell(3);
            cell.innerHTML='<td>'+priceSet(tech_list[i][6])+'</td>';
            cell=row.insertCell(4);
            cell.innerHTML='<td>'+priceSet(tech_list[i][6]*tech_list[i][5])+'</td>';
		}
        
        $('#client_info_table').clone().appendTo("#tech_table");
	}
    if ((specification) && (specification != []) && (specification != "")){
        compute_total();
        compute_discount();
        make_excel_table();
        if (cp_checkbox != "1") { show_net_cost(0); }
	}
    production_time_table.style.bottom = total_cost_table.offsetHeight+"px";
}
function compute_tech_list(s) {
    tech_list = s;
}
function show_tech(){
    document.getElementById('specifications_table').style.display = 'none';
    document.getElementById('tech_table').style.display = 'block';
    
    document.getElementById('show_tech_button').style.display = 'none';
    document.getElementById('show_spec_button').style.display = 'inline-block';
}
function show_spec(){
    document.getElementById('specifications_table').style.display = 'block';
    document.getElementById('tech_table').style.display = 'none';
    
    document.getElementById('show_tech_button').style.display = 'inline-block';
    document.getElementById('show_spec_button').style.display = 'none';
}
function compute_elements(s) {
    path_price = s[0];
    module_volume = s[1];
    module_count = s[2];
    worktop_count = s[3];
    oversize_count = s[4];
}
function make_excel_table() {
    let round_count = 2;
    //if (digit_capacity == "0,00") { round_count = 2; }
    //else if (digit_capacity == "0,0") { round_count = 1; }
    excel_table_new = 'Спецификация к договору № '+number+' от '+date+' / Адрес: '+delivery_address;
    excel_table_new += '\n№\tНаименование\tКол.\tЕд.\tЦена\tИтого\tСеб.цена\tСеб.итого\tРаб.цена\tРабота\tПоставщик\tАртикул\tКод\tВес\tСсылка';
    google_table = 'Спецификация к договору № '+number+' от '+date+' / Адрес: '+delivery_address;
    google_table += '\n№\tНаименование\tКол.\tЕд.\tЦена\tИтого\tСеб.цена\tСеб.итого\tРаб.цена\tРабота\tПоставщик\tАртикул\tКод\tВес\tСсылка';
    let table1 = document.getElementById('spec1_table');
    let table2 = document.getElementById('spec2_table');
    for (let i=0; i<table1.rows.length; i++) {
        if ((table1.rows[i].cells[0].innerText != "") && (table1.rows[i].cells[0].innerText != "№")) {
            let this_row = table1.rows[i];
            let this_provider = this_row.cells[7].childNodes[0].getAttribute("provider");
            let this_article = this_row.cells[7].childNodes[0].getAttribute("article");
			let this_code = this_row.cells[7].childNodes[0].getAttribute("code");
			let this_weight = this_row.cells[7].childNodes[0].getAttribute("weight");
			let this_link = this_row.cells[7].childNodes[0].getAttribute("link");
            excel_table_new += '\n'+this_row.cells[0].innerText+'\t'+this_row.cells[1].innerText+'\t'+this_row.cells[2].childNodes[0].getAttribute("count_value").toString().replace(".",sep)+'\t'+this_row.cells[2].childNodes[0].getAttribute("unit")+'\t'+(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")?(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")).toString().replace(".",sep):(this_row.cells[3].childNodes[0].getAttribute("value")).toString().replace(".",sep))+'\t=RC[-3]*RC[-1]\t'+(this_row.cells[5].childNodes[0].getAttribute("value")).toString().replace(".",sep)+'\t=RC[-5]*RC[-1]\t'+(this_row.cells[7].childNodes[0].getAttribute("net_value")).toString().replace(".",sep)+'\t=RC[-7]*RC[-1]\t'+((this_provider=="-------")?"":this_provider)+'\t'+((this_article=="-------")?"":this_article)+'\t'+((this_code=="-----")?"":this_code)+'\t'+((this_weight=="-----")?"":this_weight)+'\t'+((this_link=="-----")?"":this_link);
            
            google_table += '\n'+this_row.cells[0].innerText+'\t'+this_row.cells[1].innerText+'\t'+this_row.cells[2].childNodes[0].getAttribute("count_value").toString().replace(".",sep)+'\t'+this_row.cells[2].childNodes[0].getAttribute("unit")+'\t'+(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")?(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")).toString().replace(".",sep):(this_row.cells[3].childNodes[0].getAttribute("value")).toString().replace(".",sep))+'\t=ROUND(INDIRECT("RC[-3]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+(this_row.cells[5].childNodes[0].getAttribute("value")).toString().replace(".",sep)+'\t=ROUND(INDIRECT("RC[-5]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+(this_row.cells[7].childNodes[0].getAttribute("net_value")).toString().replace(".",sep)+'\t=ROUND(INDIRECT("RC[-7]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+((this_provider=="-------")?"":this_provider)+'\t'+((this_article=="-------")?"":this_article)+'\t'+((this_code=="-----")?"":this_code)+'\t'+((this_weight=="-----")?"":this_weight)+'\t'+((this_link=="-----")?"":this_link);
            
		}
	}
    for (let i=0; i<table2.rows.length; i++) {
        if ((table2.rows[i].cells[0].innerText != "") && (table2.rows[i].cells[0].innerText != "№")) {
            let this_row = table2.rows[i];
            let this_provider = this_row.cells[7].childNodes[0].getAttribute("provider");
            let this_article = this_row.cells[7].childNodes[0].getAttribute("article");
			let this_code = this_row.cells[7].childNodes[0].getAttribute("code");
			let this_weight = this_row.cells[7].childNodes[0].getAttribute("weight");
			let this_link = this_row.cells[7].childNodes[0].getAttribute("link");
            excel_table_new += '\n'+this_row.cells[0].innerText+'\t'+this_row.cells[1].innerText+'\t'+this_row.cells[2].childNodes[0].getAttribute("count_value").toString().replace(".",sep)+'\t'+this_row.cells[2].childNodes[0].getAttribute("unit")+'\t'+(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")?(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")).toString().replace(".",sep):(this_row.cells[3].childNodes[0].getAttribute("value")).toString().replace(".",sep))+'\t=RC[-3]*RC[-1]\t'+(this_row.cells[5].childNodes[0].getAttribute("value")).toString().replace(".",sep)+'\t=RC[-5]*RC[-1]\t'+(this_row.cells[7].childNodes[0].getAttribute("net_value")).toString().replace(".",sep)+'\t=RC[-7]*RC[-1]\t'+((this_provider=="-------")?"":this_provider)+'\t'+((this_article=="-------")?"":this_article)+'\t'+((this_code=="-----")?"":this_code)+'\t'+((this_weight=="-----")?"":this_weight)+'\t'+((this_link=="-----")?"":this_link);
            
            google_table += '\n'+this_row.cells[0].innerText+'\t'+this_row.cells[1].innerText+'\t'+this_row.cells[2].childNodes[0].getAttribute("count_value").toString().replace(".",sep)+'\t'+this_row.cells[2].childNodes[0].getAttribute("unit")+'\t'+(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")?(this_row.cells[3].childNodes[0].getAttribute("value_with_discount")).toString().replace(".",sep):(this_row.cells[3].childNodes[0].getAttribute("value")).toString().replace(".",sep))+'\t=ROUND(INDIRECT("RC[-3]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+(this_row.cells[5].childNodes[0].getAttribute("value")).toString().replace(".",sep)+'\t=ROUND(INDIRECT("RC[-5]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+(this_row.cells[7].childNodes[0].getAttribute("net_value")).toString().replace(".",sep)+'\t=ROUND(INDIRECT("RC[-7]";FALSE)*INDIRECT("RC[-1]";FALSE);'+round_count+')\t'+((this_provider=="-------")?"":this_provider)+'\t'+((this_article=="-------")?"":this_article)+'\t'+((this_code=="-----")?"":this_code)+'\t'+((this_weight=="-----")?"":this_weight)+'\t'+((this_link=="-----")?"":this_link);
		}
	}
    excel_table_new += '\n\t\t\t\t\t=СУММ(R3C:R[-1]C)\t\t=СУММ(R3C:R[-1]C)\t\t=СУММ(R3C:R[-1]C)\t\t\t\t=СУММ(R3C:R[-1]C)';
    excel_table_new += '\n\t\t\t\tМонтаж\t'+(Math.ceil((+total_instal_cost)*100)/100).toString().replace(".",sep);
    excel_table_new += '\n\t\t\t\tДост\t'+(delivery_cost+lifting_furniture).toString().replace(".",sep);
    excel_table_new += '\n\t\t\t\tТехника\t'+(install_appliances).toString().replace(".",sep);
    excel_table_new += '\n\t\t\t\tИтого\t=СУММ(R[-4]C:R[-1]C)';
    
    google_table += '\n\t\t\t\t\t=SUM(INDIRECT("R3C:R[-1]C";FALSE))\t\t=SUM(INDIRECT("R3C:R[-1]C";FALSE))\t\t=SUM(INDIRECT("R3C:R[-1]C";FALSE))\t\t\t\t=SUM(INDIRECT("R3C:R[-1]C";FALSE))';
    google_table += '\n\t\t\t\tМонтаж\t'+(Math.ceil((+total_instal_cost)*100)/100).toString().replace(".",sep);
    google_table += '\n\t\t\t\tДост\t'+(delivery_cost+lifting_furniture).toString().replace(".",sep);
    google_table += '\n\t\t\t\tТехника\t'+(install_appliances).toString().replace(".",sep);
    google_table += '\n\t\t\t\tИтого\t=SUM(INDIRECT("R[-4]C:R[-1]C";FALSE))';
}
function compute_total() {
    total = 0;
    total_work = 0;
    delivery_cost = min_delivery_cost;
    lifting_furniture = min_lifting_furniture;
    let lifting_floor = 2;
    
    let work_cost = document.getElementsByClassName('work_cost');
    for (let i = 0; i < work_cost.length; i++) { total_work += +work_cost[i].getAttribute('value'); }
    
    let elem_cost = document.getElementsByClassName('elem_cost');
    for (let i = 0; i < elem_cost.length; i++) { total += +elem_cost[i].getAttribute('value'); }
    
    let total_cost_table = document.getElementById('total_cost_table');
    total_cost_table.rows[0].cells[0].innerHTML='<td><b>Общая стоимость </b>(Работа '+priceSet(total_work)+'&nbsp;'+currency_name+')</td>';
    total_cost_table.rows[0].cells[1].innerHTML='<td><b>'+priceSet(total)+'&nbsp;'+currency_name+'</b></td>';
    total_instal_cost = total*install_cost/100;
    total_cost_table.rows[1].cells[1].innerHTML='<td><b>'+priceSet(total_instal_cost)+'&nbsp;'+currency_name+'</b></td>';
    if ((distance*2*delivery_distance) > delivery_cost) { delivery_cost = distance*2*delivery_distance + min_delivery_cost; }
    if (lift == "Нет") { lifting_floor = floor; }
    if ((module_count*lifting_module*lifting_floor+worktop_count*lifting_worktop*lifting_floor+oversize_count*lifting_worktop*lifting_floor) > lifting_furniture) {
        lifting_furniture = module_count*lifting_module*lifting_floor+worktop_count*lifting_worktop*lifting_floor+oversize_count*lifting_worktop*lifting_floor;
	}
    total_cost_table.rows[2].cells[0].innerHTML='<td><b>Доставка ('+priceSet(delivery_cost)+' '+currency_name+') + Подъем ('+priceSet(lifting_furniture)+' '+currency_name+')</b></td>';
    total_cost_table.rows[2].cells[1].innerHTML='<td><b>'+priceSet(+delivery_cost+lifting_furniture)+' '+currency_name+'</b></td>';
    total_cost_table.rows[3].cells[1].innerHTML='<td><b>'+priceSet(install_appliances)+'&nbsp;'+currency_name+'</b></td>';
    total_cost = total+total_instal_cost+delivery_cost+lifting_furniture+install_appliances;
    total_cost_table.rows[4].cells[0].innerHTML='<td><b>Итого</b></td>';
    let zero = 0;
    if (!discount1) {
        zero = last_zero;
        contract_cost = priceSet(total_cost-total_discount,last_zero);
        prepayment_cost = (total_cost-total_discount)*prepayment/100;
        total_cost_table.rows[4].cells[0].innerHTML='<td><b>Итого</b> (Предоплата: '+priceSet(prepayment_cost,last_zero+1)+' '+currency_name+')</td>';
	} 
    total_cost_table.rows[4].cells[1].innerHTML='<td><b>'+priceSet(total_cost,zero)+'&nbsp;'+currency_name+'</b></td>';
    let total_with_discount_table = document.getElementById('total_with_discount_table');
    total_with_discount_table.rows[1].cells[0].innerHTML='<td><b>'+priceSet(total_cost,zero)+' '+currency_name+'</b></td>';
}
function compute_discount() {
    discount_cost_array = [];
    discount_array = [];
    count_of_discount = 0;
    let cost_of_this = document.getElementsByClassName('cost_of_this');
    for (let i = 0; i < cost_of_this.length; i++) {
        let value = +cost_of_this[i].getAttribute('value');
        cost_of_this[i].innerHTML = priceSet(value);
	}
    let elem_cost = document.getElementsByClassName('elem_cost');
    for (let i = 0; i < elem_cost.length; i++) {
        let value = +elem_cost[i].getAttribute('value');
        elem_cost[i].innerHTML = priceSet(value);
	}
    if (discount1) { count_of_discount += 1; discount_array.push(discount1); }
    if (discount2) { count_of_discount += 1; discount_array.push(discount2); }
    if (discount3) { count_of_discount += 1; discount_array.push(discount3); }
    if (count_of_discount != 0) {
        for (let i = 0; i < discount_array.length; i++) {
            let this_discount = 0;
            let discount_name = discount_array[i].slice(0,discount_array[i].lastIndexOf("_"));
            let discount = discount_array[i].slice(discount_array[i].lastIndexOf("_")+1);
            let new_discount_name = discount_name;
            for (let i = 0; i < cost_of_this.length; i++) {
                let name = cost_of_this[i].getAttribute('name');
                if (discount_name.toLowerCase().indexOf("столеш") != -1) {
                    if ((name.toLowerCase().indexOf("столеш") != -1) && (name.toLowerCase().indexOf("камень") != -1)) {
                        let value = +cost_of_this[i].getAttribute('value');
                        let value_with_discount = value-value*discount/100;
                        cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                        cost_of_this[i].innerHTML = priceSet(value_with_discount);
                        let row = cost_of_this[i].parentNode.parentNode;
                        let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                        row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                        row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                        this_discount += count_value*value*discount/100;
					}
                    } else if (discount_name.toLowerCase().indexOf("blum") != -1) {
                    if (name.toLowerCase().indexOf("blum") != -1) {
                        let value = +cost_of_this[i].getAttribute('value');
                        let value_with_discount = value-value*discount/100;
                        cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                        cost_of_this[i].innerHTML = priceSet(value_with_discount);
                        let row = cost_of_this[i].parentNode.parentNode;
                        let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                        row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                        row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                        this_discount += count_value*value*discount/100;
					}
                    } else if (discount_name.toLowerCase().indexOf("лдсп") != -1) {
                    if (name.toLowerCase().indexOf("лдсп") != -1) {
                        let value = +cost_of_this[i].getAttribute('value');
                        let value_with_discount = value-value*discount/100;
                        cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                        cost_of_this[i].innerHTML = priceSet(value_with_discount);
                        let row = cost_of_this[i].parentNode.parentNode;
                        let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                        row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                        row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                        this_discount += count_value*value*discount/100;
					}
                    } else if (discount_name.toLowerCase().indexOf("led") != -1) {
                    if ((name.toLowerCase().indexOf("led") != -1) || (name.toLowerCase().indexOf("диод") != -1)) {
                        let value = +cost_of_this[i].getAttribute('value');
                        let value_with_discount = value-value*discount/100;
                        cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                        cost_of_this[i].innerHTML = priceSet(value_with_discount);
                        let row = cost_of_this[i].parentNode.parentNode;
                        let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                        row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                        row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                        this_discount += count_value*value*discount/100;
					}
                    } else {
                    if (discount_array.toString().toLowerCase().indexOf("столеш") != -1) {
                        if ((name.toLowerCase().indexOf("столеш") == -1) && (name.toLowerCase().indexOf("камень") == -1)) {
                            let value = +cost_of_this[i].getAttribute('value');
                            let value_with_discount = value-value*discount/100;
                            cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                            cost_of_this[i].innerHTML = priceSet(value_with_discount);
                            let row = cost_of_this[i].parentNode.parentNode;
                            let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                            row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                            row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                            this_discount += count_value*value*discount/100;
						}
                        } else if (discount_array.toString().toLowerCase().indexOf("blum") != -1) {
                        if (name.toLowerCase().indexOf("blum") == -1) {
                            let value = +cost_of_this[i].getAttribute('value');
                            let value_with_discount = value-value*discount/100;
                            cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                            cost_of_this[i].innerHTML = priceSet(value_with_discount);
                            let row = cost_of_this[i].parentNode.parentNode;
                            let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                            row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                            row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                            this_discount += count_value*value*discount/100;
						}
                        } else if (discount_array.toString().toLowerCase().indexOf("лдсп") != -1) {
                        if (name.toLowerCase().indexOf("лдсп") == -1) {
                            let value = +cost_of_this[i].getAttribute('value');
                            let value_with_discount = value-value*discount/100;
                            cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                            cost_of_this[i].innerHTML = priceSet(value_with_discount);
                            let row = cost_of_this[i].parentNode.parentNode;
                            let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                            row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                            row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                            this_discount += count_value*value*discount/100;
						}
                        } else if (discount_array.toString().toLowerCase().indexOf("led") != -1) {
                        if ((name.toLowerCase().indexOf("led") == -1) && (name.toLowerCase().indexOf("диод") == -1)) {
                            let value = +cost_of_this[i].getAttribute('value');
                            let value_with_discount = value-value*discount/100;
                            cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                            cost_of_this[i].innerHTML = priceSet(value_with_discount);
                            let row = cost_of_this[i].parentNode.parentNode;
                            let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                            row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                            row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                            this_discount += count_value*value*discount/100;
						}
                        } else {
                        let value = +cost_of_this[i].getAttribute('value');
                        let value_with_discount = value-value*discount/100;
                        cost_of_this[i].setAttribute('value_with_discount', value_with_discount);
                        cost_of_this[i].innerHTML = priceSet(value_with_discount);
                        let row = cost_of_this[i].parentNode.parentNode;
                        let count_value = +row.cells[2].childNodes[0].getAttribute('count_value');
                        row.cells[4].childNodes[0].setAttribute('value_with_discount', count_value*value_with_discount);
                        row.cells[4].childNodes[0].innerHTML = priceSet(count_value*value_with_discount);
                        this_discount += count_value*value*discount/100;
					}
                    
				}
			}
            discount_cost_array.push(new_discount_name+" "+discount+"%="+this_discount);
		}
        let total_cost_table = document.getElementById('total_cost_table');
        total_discount = 0;
        for (let i=0; i<discount_cost_array.length; i++) {
            total_cost_table.rows[i+5].cells[0].innerHTML='<td ><b>'+discount_cost_array[i].split("=")[0]+'</b></td>';
            total_cost_table.rows[i+5].cells[1].innerHTML='<td ><b>'+priceSet(discount_cost_array[i].split("=")[1])+' '+currency_name+'</b></td>';
            total_discount += +discount_cost_array[i].split("=")[1];
		}
        contract_cost = priceSet(total_cost-total_discount,last_zero);
        prepayment_cost = (total_cost-total_discount)*prepayment/100;
        console.log(discount_cost_array)
        total_cost_table.rows[discount_cost_array.length+5].cells[0].innerHTML='<td ><b>Итого с учетом скидок</b> (Предоплата: '+priceSet(prepayment_cost,last_zero+1)+' '+currency_name+')</td>';
        total_cost_table.rows[discount_cost_array.length+5].cells[1].innerHTML='<td ><b>'+priceSet(total_cost-total_discount,last_zero)+' '+currency_name+'</b></td>';
        let discount_table = document.getElementById('discount_table');
        discount_table.rows[1].cells[0].innerHTML='<td ><b>'+priceSet(total_discount)+' '+currency_name+'</b></td>';
        let total_with_discount_table = document.getElementById('total_with_discount_table');
        total_with_discount_table.rows[1].cells[0].innerHTML='<td ><b>'+priceSet(total_cost-total_discount,last_zero)+' '+currency_name+'</b></td>';
        let discount_rows = document.querySelectorAll('.discount_row');
        if (discount_array.toString().toLowerCase().indexOf("blum") != -1) {
            for (let i=0; i<discount_rows.length; i++) {
                let discount_name = discount_rows[i].cells[0].innerHTML;
                if (discount_name.toLowerCase().indexOf("blum") == -1) {
                    discount_rows[i].cells[0].innerHTML = discount_name + " (за искл. фурн. Blum)"
				}
			}
		}
        if (discount_array.toString().toLowerCase().indexOf("столеш") != -1) {
            for (let i=0; i<discount_rows.length; i++) {
                let discount_name = discount_rows[i].cells[0].innerHTML;
                if (discount_name.toLowerCase().indexOf("столеш") == -1) {
                    discount_rows[i].cells[0].innerHTML = discount_name + " (за искл. иск. камня)"
				}
			}
		}
        if (discount_array.toString().toLowerCase().indexOf("лдсп") != -1) {
            for (let i=0; i<discount_rows.length; i++) {
                let discount_name = discount_rows[i].cells[0].innerHTML;
                if (discount_name.toLowerCase().indexOf("лдсп") == -1) {
                    discount_rows[i].cells[0].innerHTML = discount_name + " (за искл. ЛДСП)"
				}
			}
		}
        if (discount_array.toString().toLowerCase().indexOf("led") != -1) {
            for (let i=0; i<discount_rows.length; i++) {
                let discount_name = discount_rows[i].cells[0].innerHTML;
                if (discount_name.toLowerCase().indexOf("led") == -1) {
                    discount_rows[i].cells[0].innerHTML = discount_name + " (за искл. подсветки LED)"
				}
			}
		}
	} 
}
$(document).on( "click", "#net_cost", function() {
    if (show_net == 0) { show_net = 1; show_net_cost(show_net); }
    else { show_net = 0; show_net_cost(show_net); }
});
function show_net_cost(show=0) {
    let table1 = document.getElementById('spec1_table');
    let table2 = document.getElementById('spec2_table');
    let total_cost_table = document.getElementById('total_cost_table');
    let total_net_cost_table = document.getElementById('total_net_cost_table');
    if (show == 1) {
        for (let i=0; i<table1.rows.length; i++) {
            table1.rows[i].cells[3].style.display='none';
            table1.rows[i].cells[4].style.display='none';
            table1.rows[i].cells[5].style.display='table-cell';
            table1.rows[i].cells[6].style.display='table-cell';
            table1.rows[i].cells[7].style.display='table-cell';
		}
        for (let i=0; i<table2.rows.length; i++) {
            table2.rows[i].cells[3].style.display='none';
            table2.rows[i].cells[4].style.display='none';
            table2.rows[i].cells[5].style.display='table-cell';
            table2.rows[i].cells[6].style.display='table-cell';
            table2.rows[i].cells[7].style.display='table-cell';
		}
        total_net_cost_table.style.display = 'block'; 
        total_cost_table.style.display = 'none';
        } else {
        for (let i=0; i<table1.rows.length; i++) {
            table1.rows[i].cells[3].style.display='table-cell';
            table1.rows[i].cells[4].style.display='table-cell';
            table1.rows[i].cells[5].style.display='none';
            table1.rows[i].cells[6].style.display='none';
            table1.rows[i].cells[7].style.display='none';
		}
        for (let i=0; i<table2.rows.length; i++) {
            table2.rows[i].cells[3].style.display='table-cell';
            table2.rows[i].cells[4].style.display='table-cell';
            table2.rows[i].cells[5].style.display='none';
            table2.rows[i].cells[6].style.display='none';
            table2.rows[i].cells[7].style.display='none';
		}
        total_net_cost_table.style.display = 'none'; 
        total_cost_table.style.display = 'block'; 
	}
}
function hide_show_cells(checkbox_checked) {
    cp_checkbox = checkbox_checked;
    if (checkbox_checked == "1") {
        table1 = document.getElementById('spec1_table');
        table2 = document.getElementById('spec2_table');
        for (let i=0; i<table1.rows.length; i++) {
            //table1.rows[i].cells[2].style.display='none';
            table1.rows[i].cells[3].style.display='none';
            table1.rows[i].cells[4].style.display='none';
		}
        for (let i=0; i<table2.rows.length; i++) {
            //table2.rows[i].cells[2].style.display='none';
            table2.rows[i].cells[3].style.display='none';
            table2.rows[i].cells[4].style.display='none';
		}
        } else {
        table1 = document.getElementById('spec1_table');
        table2 = document.getElementById('spec2_table');
        for (let i=0; i<table1.rows.length; i++) {
            //table1.rows[i].cells[2].style.display='table-cell';
            table1.rows[i].cells[3].style.display='table-cell';
            table1.rows[i].cells[4].style.display='table-cell';
		}
        for (let i=0; i<table2.rows.length; i++) {
            //table2.rows[i].cells[2].style.display='table-cell';
            table2.rows[i].cells[3].style.display='table-cell';
            table2.rows[i].cells[4].style.display='table-cell';
		}
	}
}
$(document).on( "change", "#cp_checkbox", function() {
    if (this.checked) { hide_show_cells("1"); }
    else { hide_show_cells("0"); }
});
$(document).on( "change", ".discount_input", function() {
    let number_of_discount = this.getAttribute('attr-number');
    let obj = document.getElementById('discount'+number_of_discount);
    let obj_name = obj.parentNode.parentNode.cells[0].firstChild;
    let name_of_discount = obj_name.options[obj_name.selectedIndex].text;
    change_discount(obj,number_of_discount,true);
    if (($(this).val() > 15) && (name_of_discount.indexOf("столеш") == -1)){ alert("Скидка больше 15% вычитается из вашей зарплаты!"); }
});
$(document).on( "focus", "input", function() {
    document.getElementById('save').disabled = false;
});
$(document).on( "focus", "select", function() {
    document.getElementById('save').disabled = false;
});
$(document).on( "click", "#discount", function() {
    if (count_of_discount < 3) {
        let number_of_discount = 1;
        let selects = document.querySelectorAll('.discount_select');
        for (let i = 0; i < selects.length; i++) { 
            let index = selects[i].selectedIndex;
            if (index == 0) { 
                count_of_discount -= 1;
                $('#popUp').animate({ "height": 360+30*count_of_discount }, 300 );
                selects[i].parentNode.parentNode.parentNode.removeChild(selects[i].parentNode.parentNode);
			} 
		}
        for (let i = 0; i < selects.length; i++) {
            if (selects[i].getAttribute("number").indexOf(number_of_discount.toString()) != -1) { number_of_discount += 1; }
		}
        count_of_discount += 1;
        table = document.getElementById('discounts_table');
        if (!table) { $('#popUp').append('<table id="discounts_table" ></table>'); }
        table = document.getElementById('discounts_table');
        rowCount = table.rows.length;
        row = table.insertRow(rowCount);
        cell=row.insertCell(0);
        content = '<td ><select id="discount'+number_of_discount+'" class="discount_select" number="'+number_of_discount+'" onchange="change_discount(this,'+number_of_discount+');"><option></option>';
        $.each( discount_content.discounts, function( key, val ) { 
            if (val.name == "Общая наценка") { return false; }
            content=content.concat('<option value="'+val.value+'" >'+val.name+'</option>');
		});
        content=content.concat('</select></td>');
        cell.innerHTML=content;
        cell=row.insertCell(1);
        cell.innerHTML='<td ></td>';
        $('#popUp').animate({ "height": 360+30*count_of_discount }, 300 );
	}
});
function change_discount(obj,number_of_discount,discount_change=false) {
    if (obj.selectedIndex) { // если выбор не 0
        let option_text = obj.options[obj.selectedIndex].text;
        let option_value = obj.options[obj.selectedIndex].value;
        let total_cost_table = document.getElementById('total_cost_table');
        if (count_of_discount == 1) { // если единственная скидка
            row = obj.parentNode.parentNode;
            if (discount_change == false) {
                discount = option_value;
                row.cells[1].innerHTML = '<input class="discount_input" attr-number='+number_of_discount+' value="'+discount+'"></input>';
                } else {
                discount = +row.cells[1].childNodes[0].value;
			}
            if (total_cost_table.rows.length > 5) {
                total_cost_table.deleteRow(total_cost_table.rows.length-1)
                total_cost_table.deleteRow(total_cost_table.rows.length-1)
			}
            total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
            total_cost_row.id = 'row_'+number_of_discount;
            total_cost_row.className = 'discount_row';
            cell=total_cost_row.insertCell(0);
            cell.innerHTML='<td ><b>'+option_text.slice(0,option_text.lastIndexOf(" ")+1)+option_value+'%</b></td>';
            cell=total_cost_row.insertCell(1);
            cell.innerHTML='<td ></td>';
            total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length);
            total_cost_row.id = 'row_last';
            cell=total_cost_row.insertCell(0);
            cell.innerHTML='<td ><b>Итого с учетом скидок</b></td>';
            cell=total_cost_row.insertCell(1);
            cell.innerHTML='<td ></td>';
            
            } else { // если скидок несколько
            row = obj.parentNode.parentNode;
            if (discount_change == false) {
                discount = option_value;
                row.cells[1].innerHTML = '<input class="discount_input" attr-number='+number_of_discount+' value="'+discount+'"></input>';
                } else {
                discount = +row.cells[1].childNodes[0].value;
			}
            let discount_row = document.getElementById('row_'+number_of_discount);
            if (!discount_row) { // если в таблице нет этой скидки
                total_cost_row = total_cost_table.insertRow(total_cost_table.rows.length-1);
                total_cost_row.id = 'row_'+number_of_discount;
                total_cost_row.className = 'discount_row';
                cell=total_cost_row.insertCell(0);
                cell.innerHTML='<td ></td>';
                cell=total_cost_row.insertCell(1);
                cell.innerHTML='<td ></td>';
			}
		}
        document.getElementById('discount_table').style.display = 'block';
        total_cost_table.rows[0].cells[0].innerHTML = '<b>Общая стоимость без учета скидки</b>';
        } else { // если выбор 0
        let discount_count = 0;
        let selects = document.querySelectorAll('.discount_select');
        for (let i = 0; i < selects.length; i++) { discount_count += selects[i].selectedIndex; }
        if (discount_count == 0) { // если все скидки 0
            table = document.getElementById('discounts_table');
            table.parentNode.removeChild(table);
            count_of_discount = 0;
            $('#popUp').animate({ "height": 360 }, 300 );
            let discount_rows = document.querySelectorAll('.discount_row');
            for (let i = 0; i < discount_rows.length; i++) { discount_rows[i].parentNode.removeChild(discount_rows[i]); }
            let row_last = document.getElementById('row_last');
            row_last.parentNode.removeChild(row_last);
            document.getElementById('discount_table').style.display = 'none';
            total_cost_table.rows[0].cells[0].innerHTML = '<b>Общая стоимость</b>';
            } else { // если текущая скидка 0
            let current_row = obj.parentElement.parentElement;
            current_row.parentNode.removeChild(current_row);
            count_of_discount -= 1;
            $('#popUp').animate({ "height": 360+30*count_of_discount }, 300 );
            let row_in_table = document.getElementById('row_'+number_of_discount);
            row_in_table.parentNode.removeChild(row_in_table);
		}
	}
    document.getElementById('save').disabled = false;
}
$(document).on( "click", "#cost_coef", function(e) {
	sketchup.get_data("cost_coef|"+cost_coef);
});
function save_changes() {
    $('#popUp')
    .animate({opacity: 0, top: '35%'}, 490, 
        function(){ 
            $(this).css('display', 'none'); 
            $('#overlay').fadeOut(220); 
		}
	);
    discount1 = null;
    discount2 = null;
    discount3 = null;
    let table = document.getElementById("setup_table");
    let rows = table.rows;
    let str = "save_changes";
    for (let i = 0; i < rows.length; i++) {
        let id = rows[i].cells[1].childNodes[0].getAttribute('id');
        let value = rows[i].cells[1].childNodes[0].value;
        if (value != "") { 
            str += id+"|"+value+"|";
            if (id == "delivery_address") { str += "address|"+value+"|"; }
		}
	}
    str += "currency_rate|"+currency_rate+"|"
    table = document.getElementById("discounts_table");
    if (table) {
        rows = table.rows;
        for (let i = 0; i < rows.length; i++) {
            let id = 'discount'+(i+1);
            let all_options = rows[i].cells[0].childNodes[0];
            let option_text = all_options.options[all_options.selectedIndex].text;
            let option_value = rows[i].cells[1].childNodes[0].value;
            str += id+"|"+option_text+"_"+option_value+"|";
            if (i == 0) { discount1 = option_text+"_"+option_value; }
            if (i == 1) { discount2 = option_text+"_"+option_value; }
            if (i == 2) { discount3 = option_text+"_"+option_value; }
		}
	}
    str += "cp_checkbox|"+cp_checkbox+"|";
    str += "contract|"+contract+"|";
    sketchup.get_data(str);
    compute_total();
    
}
function export_to_excel() {
    sketchup.get_data("send_to_excel"+excel_table_new);
}
function export_to_layout() {
    //if ((number == "") || (delivery_address == "")) {
    //alert("Введите номер договора и адрес!") }
    document.getElementById('specifications_table').style.display = 'block';
    document.getElementById('tech_table').style.display = 'none';
    html2canvas(document.getElementById("specifications_table"),{ scale: 2.2, }).then(function(canvas) {
        canvas.toBlob(function(blob) { 
            var reader = new window.FileReader();
            reader.readAsDataURL(blob);
            reader.onloadend = function () {
                base64data = reader.result;
                sketchup.get_data("1"+base64data);
			} });
	});
    document.getElementById('specifications_table').style.display = 'none';
    document.getElementById('tech_table').style.display = 'block';
    html2canvas(document.getElementById("tech_table"),{ scale: 2.2, }).then(function(canvas) {
        canvas.toBlob(function(blob) { 
            var reader = new window.FileReader();
            reader.readAsDataURL(blob);
            reader.onloadend = function () {
                base64data = reader.result;
                sketchup.get_data("2"+base64data);
			} });
	});
    document.getElementById('specifications_table').style.display = 'block';
    document.getElementById('tech_table').style.display = 'none';
    const func = () => { sketchup.get_data("send_to_layout"); };
    setTimeout(func, 1000);
}
$(document).on( "click", "label_count", function(e) {
    let rng, sel;
    let t = e.target || e.srcElement;
    let row = t.parentNode.parentNode;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'input')	{return false;}
    let val = t.getAttribute("count_value");
    let unit = t.getAttribute("unit");
    $(this).empty().append('<input type="text" id="count_edit" value="'+val+'" />');
    $('#count_edit').focus();
    $('#count_edit').select();
    $('#count_edit').blur(function(){
        $(this).parent().empty().html($(this).val()+'&nbsp;'+unit);
        t.setAttribute("count_value",$(this).val());
        t.classList.add('edited');
        let cost_value = "0";
        if (row.cells[3].childNodes[0].getAttribute("value_with_discount")) {
		    let value_with_discount = row.cells[3].childNodes[0].getAttribute("value_with_discount");
			let new_cost_with_discount = Math.ceil(value_with_discount*100)/100*$(this).val();
			let cost_value = row.cells[3].childNodes[0].getAttribute("value");
			let new_cost = Math.ceil(cost_value*100)/100*$(this).val();
			let name = row.cells[4].childNodes[0].getAttribute("name");
			row.cells[4].innerHTML='<td ><label name="'+name+'" class="elem_cost" value="'+roundSet(new_cost)+'" value_with_discount="'+roundSet(new_cost_with_discount)+'">'+priceSet(value_with_discount)+'</td>';
			} else {
			let cost_value = row.cells[3].childNodes[0].getAttribute("value");
			let new_cost = Math.ceil(cost_value*100)/100*$(this).val();
			let name = row.cells[4].childNodes[0].getAttribute("name");
			row.cells[4].innerHTML='<td ><label name="'+name+'" class="elem_cost" value="'+roundSet(new_cost)+'">'+priceSet(new_cost)+'</td>';
		}
        compute_total();
        compute_discount();
        make_excel_table();
	});
});
$(document).on( "click", ".setup", function(event){ 
    event.preventDefault(); 
    $('#overlay').fadeIn(250, 
	function(){ $('#popUp').css('display', 'block').animate({opacity: 1, top: '55%'}, 490); });
});
$(document).on( "click", ".update", function(event){
    sketchup.get_data("update_param");
});
$(document).on( "click", ".excel", function(event){
    copy_excel_table(excel_table_new);
    let copy_excel_image = document.getElementById('excel');
    copy_excel_image.src = "cont/style/excel_done.png";
});
$(document).on( "click", ".google_sheets", function(event){
    copy_excel_table(google_table);
    let copy_google_image = document.getElementById('google_sheets');
    copy_google_image.src = "cont/style/google_sheets.png";
});
$(document).on( "click", ".export_spec", function(event){
    document.getElementById('specifications_table').style.display = 'block';
    document.getElementById('tech_table').style.display = 'none';
    html2canvas(document.getElementById("specifications_table"),{ scale: 2.2, }).then(function(canvas) {
        canvas.toBlob(function(blob) { 
            var reader = new window.FileReader();
            reader.readAsDataURL(blob);
            reader.onloadend = function () {
                base64data = reader.result;
                sketchup.get_data("3"+base64data);
			} });
	});
    let export_spec_image = document.getElementById('export_spec');
    export_spec_image.src = "cont/style/export_spec_done.png";
});
$(document).on( "click", ".contract_checkbox", function(event){
    if (contract == "false") {
        console.log("|"+product+"|"+delivery_address+"|"+number+"|"+date+"|"+designer+"|"+production_time+"|"+contract_cost+"|"+priceSet(prepayment_cost,last_zero+1)+"|"+customer+"|"+customer_phone)
        if ((delivery_address == "") || (number == "") || (designer == "") || (customer == "") || (customer_phone == "")) { alert("Заполните все поля в настройках!")
            } else {
            let contract_checked_image = document.getElementById('contract_checkbox');
            contract_checked_image.src = "cont/style/contract_checked.png";
            contract = "true";
            save_changes();
            let str = "|"+product+"|"+delivery_address+"|"+customer+"|"+customer_phone+"|"+number+"|"+date+"|"+designer+"|"+production_time+"|"+contract_cost+"|"+priceSet(prepayment_cost,last_zero+1);
            console.log(tech_list)
            str += "|"
            for (let i = 0; i < tech_list.length; i++) { str+='^'+tech_list[i][1] }
            sketchup.get_data("google_sheet"+str+"|"+google_table);
		}
        } else {
        contract = "false";
        save_changes();
        let contract_checked_image = document.getElementById('contract_checkbox');
        contract_checked_image.src = "cont/style/contract_unchecked.png";
	}
});
function copy_excel_table(s) {
    console.log(s)
    let copytext = document.createElement('textarea');
    copytext.value = s;
    document.body.appendChild(copytext);
    copytext.select();
    document.execCommand('copy');
    document.body.removeChild(copytext);
}
$(document).on( "click", "#close, #overlay", function(){ 
    $('#popUp')
    .animate({opacity: 0, top: '35%'}, 490, 
        function(){ $(this).css('display', 'none'); $('#overlay').fadeOut(220); }
	);
});

