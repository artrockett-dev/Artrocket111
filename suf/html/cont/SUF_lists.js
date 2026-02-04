// ====== TRANSLATION LAYER ===================================================
const translateDB = window.translateFromDB;
const SHOW_SPEC = true;
function tr(txt){
  const fromDB = translateDB?.(txt);
  if (fromDB !== undefined && fromDB !== null && fromDB !== '') return fromDB;
  return window.translate ? window.translate(txt) : txt;
}

// ====== SAFETY/ENV FALLBACKS ===============================================
// Заглушки, чтобы ar_specification.html грузилась даже без моста/DOM-элементов
window.translationDB = window.translationDB || {};
window.sketchup = window.sketchup || {
  getFxSettings: function(){},
  get_data: function(){ /* no-op */ }
};
// если где-то в HTML есть onclick="add_comp(...)" — устраняем ReferenceError
window.add_comp = window.add_comp || function(){};

// Утилиты безопасной работы с DOM
function el(id){ try{ return document.getElementById(id) || null; }catch(_){ return null; } }
function withEl(id, fn){ const node = el(id); if (node) try{ fn(node); }catch(_){} }

// ====== STATE ===============================================================
var currSelection = { ListSection: [], }
var currency_name = "р.";
var currency_rate = [];
var mat_currency = "";
var profil_name_cost_arr = [];
var pipe_name_cost_arr = [];
var markup = 1;
var markup_from_param = 1;
var access_level = 1;
var sep = ",";
var digit_capacity = "0";
var model_name = "";
var panel_sizes = "Пильные без кромки";
var all_mat_array = [];
var visible_rows = [];
var selected_panel_arr = [];
var acc_group_hash = {};

// ====== FX: CURRENCY CONVERSION LAYER ======================================
const FX_CURRS = ['MDL','EUR','USD','RON'];
const FX_SYMBOL = { MDL:'MDL', EUR:'EUR', USD:'USD', RON:'RON' };
const fx = {
  base: 'MDL',
  show: 'EUR',
  rates: { MDL:1, EUR:18.9, USD:17.3, RON:4.7 },
};
function fxSetRates({base, rates}){ if(base) fx.base = base; if(rates) fx.rates = {...fx.rates, ...rates}; }
function fxConvert(value, from, to){
  from = from || fx.base; to = to || fx.show;
  const rFrom = fx.rates[from]; const rTo = fx.rates[to];
  if(!rFrom || !rTo) return value;
  const inMDL = (from==='MDL') ? value : (value * rFrom);
  return (to==='MDL') ? inMDL : (inMDL / rTo);
}
function fxSymbol(curr){ return FX_SYMBOL[curr] || curr; }
function fxRenderAll(){
  const nodes = document.getElementsByClassName('elem_cost');
  for(let i=0;i<nodes.length;i++){
    const el = nodes[i];
    const native = +el.getAttribute('data-native') || 0;
    const ncur   = el.getAttribute('data-native-curr') || fx.base;
    const digit  = el.getAttribute('data-digit') || digit_capacity;
    const disp   = fxConvert(native, ncur, fx.show);
    el.setAttribute('data-disp', String(disp));
    el.innerHTML = priceSet(disp, digit);
  }
  rerenderTotals(); // безопасный no-op ниже
}
// — предпочтительный способ обновления курсов из Ruby/моста
function fx_update(payload){ try{ fxSetRates(payload); fxRenderAll(); }catch(e){} }

// — получаем валюту/курсы из parameters через Startup Bridge
window.__applyFxSettings = function(payload){
  try{
    if (payload && payload.rates) fxSetRates({ rates: payload.rates, base: payload.base || 'MDL' });
    if (payload && payload.show)  fx.show = String(payload.show);
    fxRenderAll();
  }catch(e){}
};

// — совместимость со старым форматом массива: ["EUR=19.05=€", ...]
function cbr_xml_daily(str) {
  currency_rate = str;
  try{
    const rates = {};
    for(const item of str){
      const [cur, rate, symbol] = item.split('=');
      if(symbol && FX_SYMBOL[cur]===undefined) FX_SYMBOL[cur] = symbol;
      rates[cur] = parseFloat(rate);
      if(cur==='MDL' && !rates.MDL) rates.MDL = 1;
    }
    fxSetRates({ base: rates['MDL']? 'MDL' : 'MDL', rates });
    currency_name = str[0].split("=")[2];
    fxRenderAll();
  }catch(e){}
}

// ====== HELPERS =============================================================
function applyFilter(text) {
  for (let key in window.translationDB) {
    let escKey = key.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    text = text.replace(new RegExp(escKey, 'g'), window.translationDB[key]);
  }
  return text;
}
function rerenderTotals(){} // чтобы fxRenderAll() не падал, если тоталов нет

function resolveSpecUrl(){
  window.sketchup.get_data("size_attributes");
  const base = document.location.href.replace(/[#?].*$/, "").replace(/[^/]+$/, "");
  return base + "ar_specification.html";
}

// ====== UI BOOT =============================================================
function lists_activate(){
  window.scrollTo(0, 0);

  withEl('main', function(main){
    $(main).empty();
    $(main).append('<table id="table_mess"></table>');
    let tableObj = [];
    tableObj.push ('<td id="Logo"> <img id="image" src="" ></td>');
    tableObj.push ('<td id="des_name">'+tr("Model")+'</td>');
    $('#table_mess').append(tableObj);

    // (панель выбора валют скрыта, но настройки валюты подтягиваем мостом)
    try{ if (window.sketchup && window.sketchup.getFxSettings) window.sketchup.getFxSettings(); }catch(e){}

    $(main).append('<legend id="description"></legend>');
    $(main).append('<div id="ListSections" ></div>');
  });

  // стандартные вкладки
  $('#ListSections').append('<button id="Accessories" class="Listtablinks" data-name="Accessories" title="'+tr("Accessories/Fasteners")+'">'+tr("Acc/Fast")+'</button>');
  $('#ListSections').append('<button id="Sheet" class="Listtablinks" data-name="Sheet" title="'+tr("Sheets")+'">'+tr("Sheets")+'</button>');
  $('#ListSections').append('<button id="Linear" class="Listtablinks" data-name="Linear" title="'+tr("Linear")+'">'+tr("Linear")+'</button>');
  $('#ListSections').append('<button id="Operations" class="Listtablinks" data-name="Operations" title="'+tr("Operations")+'">'+tr("Operations")+'</button>');
  $('#ListSections').append('<button id="Cost" class="Listtablinks" data-name="Cost" title="'+tr("Cost")+'">'+tr("Cost")+'</button>');

  // PRICE — икон-кнопка, остаётся вкладкой
  $('#ListSections').append(
    '<button id="Price" class="Listtablinks ls-iconbtn icon-price" data-name="Price" title="'+tr("Price list")+'">' +
      '<img src="cont/style/menu.png" alt="Price">' +
    '</button>'
  );

  // SPEC — отдельная икон-кнопка того же стиля (не вкладка)
  if (SHOW_SPEC && !document.getElementById('ARSpecBtn')) {
    $('#ListSections').append(
      '<button id="ARSpecBtn" class="ls-iconbtn icon-spec" title="AR Specification">'+
        '<img src="cont/style/specification.png" alt="Spec" onerror="this.style.display=\'none\'; this.parentNode.textContent=\''+tr("Specification")+'\';">'+
      '</button>'
    );
    withEl('ARSpecBtn', function(btn){
      btn.addEventListener('click', function(){
        location.href = resolveSpecUrl();
      });
    });
  }

  withEl('main', function(main){
    $(main).append('<div id="lists_table"></div>');
  });

  // Всё ниже — только если соответствующие узлы есть на странице
  withEl('footer', (n)=> n.style.display='block');
  withEl('add_accessories', (n)=> n.title="Добавить в модель");
  withEl('panel_size', (n)=> n.title="Размеры панелей: \n"+panel_sizes);
  withEl('submit_button', (n)=> n.style.display='none');

  withEl('copy_button', function(n){
    n.style.display='block';
    n.style.backgroundColor = "buttonface";
    n.disabled = true;
    n.value = tr("Copy the list");
  });
  withEl('transfer_button', function(n){
    n.style.display='none';
    n.style.backgroundColor = "buttonface";
    n.disabled = true;
    n.value = tr("Transfer the list");
  });
}

function cost_table(){
  if (!document.getElementById('lists_table')) return;

  $('#lists_table').empty();
  profil_name_cost_arr = [];
  pipe_name_cost_arr = [];

  try{
    if (typeof discount_content !== 'undefined' && discount_content?.discounts){
      $.each(discount_content.discounts, function(key, val){
        if (val.name == "Total markup") { markup_from_param = parseFloat(String(val.value).replace(",",".")); }
      });
    }
  }catch(e){}

  let table_name = '<table class="acc_table" id="acc_table" ></table>';
  $('#lists_table').append(table_name);
  let table = document.getElementById('acc_table');
  let tableAccHeader = '<th id="acc_number_header" >№</th><th >'+tr("provider")+'</th><th >'+tr("name")+'</th><th >'+tr("count")+'</th><th >'+tr("unit")+'</th><th >'+tr("price")+'</th>';
  table.innerHTML = tableAccHeader;

  withEl('footer', (n)=> n.style.display='block');
  withEl('copy_button', function(n){
    n.style.display='block';
    n.style.backgroundColor = "buttonface";
    n.disabled = false;
  });
  withEl('panel_size', (n)=> n.style.display='none');
  withEl('transfer_button', function(n){
    n.style.display='block';
    n.style.backgroundColor = "buttonface";
    n.disabled = false;
  });
}

// ====== COST ROWS W/ FX =====================================================
function cost_rows(s) {
  let name = applyFilter(s[0]);
  let count = s[1];
  let unit = s[2];
  let cost = s[3];
  let net_cost = s[4];
  let work = s[5];
  let provider = s[6];
  let article = s[7];
  let mat_currency = s[8];
  let code = s[9];
  let weight = s[10];
  let link = s[11];
  digit_capacity = s[12];
  let spec = s[13];

  if (spec == true) {
    let elem_cost_native = count * (cost + work);
    const elem_cost_disp  = fxConvert(elem_cost_native, (mat_currency||fx.base), fx.show);

    let table = document.getElementById('acc_table');
    if (table) {
      let rowCount = table.rows.length;
      let row = table.insertRow(rowCount);

      let cell=row.insertCell(0);
      cell.innerHTML='<td class="acc_number" id="acc_number" ><cost_number>'+rowCount+'</cost_number></td>';

      cell=row.insertCell(1);
      cell.innerHTML='<td class="acc_provider" id="acc_provider" ><label>'+provider+'</label></td>';

      cell=row.insertCell(2);
      cell.innerHTML='<td class="acc_name" id="acc_name" ><label>'+name+'</label></td>';

      cell=row.insertCell(3);
      cell.innerHTML='<td><cost_label class="acc_count" id="acc_count">'+count.toString().replace(".",sep)+' </cost_label></td>';
      if (count == 0) { cell.style.backgroundColor = "red";}

      cell=row.insertCell(4);
      cell.innerHTML='<td><cost_label>'+unit+'</cost_label></td>';

      cell=row.insertCell(5);
      cell.innerHTML='<td><cost_label title="Unit price: '+priceSet(cost,digit_capacity)+'\nWork: '+priceSet(work,digit_capacity)+'" class="elem_cost" data-native="'+(elem_cost_native)+'" data-native-curr="'+(mat_currency||fx.base)+'" data-digit="'+digit_capacity+'" data-disp="'+elem_cost_disp+'">'+priceSet(elem_cost_disp,digit_capacity)+'</cost_label></td>';
      if (elem_cost_native == 0) { cell.style.backgroundColor = "red"; }
    }
  }
  return [cost,net_cost,work,provider,article,code,weight,link];
}

// ====== PRICE FORMAT ========================================================
function priceSet(data,zero=0){
  if (data != 0) {
    data = rounding(data,digit_capacity);
    let price = data.toString();
    if (zero != 0) {
      for (let i = zero; i > 0; i--) {
        price = price.slice(0,-i)+price.substr(-i).replace(/\d/,"0");
      }
    }
    data = price.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1");
  }
  return data;
}
function roundSet(data){ if (data != 0) { data = rounding(data,digit_capacity); } return data; }
function rounding(cost,digit_capacity) {
  if (digit_capacity == "0,00") { cost = Math.ceil(cost*100)/100 }
  else if (digit_capacity == "0,0") { cost = Math.ceil(cost*10)/10 }
  else { cost = Math.ceil(cost) }
  return cost;
}

// ====== TOTAL (FX) ==========================================================
function total_cost(s){
  let volume = s[0];
  let table = document.getElementById('acc_table');
  if(!table) return;

  let rows = table.rows;
  let row = table.insertRow(rows.length);
  row.insertCell(0);
  row.insertCell(1).innerHTML='<td class="acc_name" id="acc_name" ><cost_label><b>'+tr("Total")+'</b></cost_label></td>';
  row.insertCell(2);
  row.insertCell(3);
  row.insertCell(4);
  const last = row.insertCell(5);

  let total = 0;
  const elems = document.getElementsByClassName('elem_cost');
  for (let i = 0; i < elems.length; i++) {
    total += +(elems[i].getAttribute('data-disp') || 0);
  }
  last.innerHTML = '<td><cost_total_label><b>'+priceSet(total,digit_capacity)+'&nbsp;'+fxSymbol(fx.show)+'</b></cost_total_label></td>';

  if (volume != "") {
    $('#lists_table').append('<p id="p_'+volume+'" style="margin-left: 20px;" ><b>'+tr("The volume of modules")+' '+volume+' '+tr("cub.m.")+'</b>');
  }
}

// ====== LISTS / ACC TABLES ==================================================
function check_listtablinks() {
  $('#lists_table').empty();
  let active = $('button.Listtablinks.active').attr('data-name');
  if (!active) return;
  let str='list@'+active;
  sketchup.get_data(str);
}
function clear_selection_list(show_list=true){
  selected_panel_arr = [];
  $('#lists_table').empty();
  let active = $('button.Listtablinks.active').attr('data-name');
  let str='list@'+active;
  if (show_list) { sketchup.get_data(str); }
  withEl('des_name', (n)=> n.innerHTML = tr("Model"));
  withEl('description', (n)=> n.innerHTML = "");
  withEl('image', (n)=> n.src = "");
}
function acc_table(s){
  sep = s[1];
  if (s[0]=="new_table") { $('#lists_table').empty(); }
  let table_name, table_id;
  if (s[2]) {
    $('#lists_table').append('<table class="title_table acc_table" id="'+s[3]+'_title_table" style="margin-top: 5px;"></table>');
    $(document.getElementById(s[3]+'_title_table')).append('<th id="p_'+s[3]+'" class="table_title_p" style="margin-top: 3px; margin-bottom: 3px;" ><b>'+s[2]+'</b></th>');
    table_name = '<table class="acc_table" id="'+s[3]+'_acc_table" style="margin-top: -1px;"></table>';
    table_id=s[3]+'_acc_table';
  }
  else {table_name = '<table class="acc_table" id="acc_table" style="margin-top: 5px;"></table>'; table_id='acc_table';}
  $('#lists_table').append(table_name);
  let table = document.getElementById(table_id);
  table.innerHTML = '<th id="acc_number_header">№</th><th>'+tr("name")+'</th><th>'+tr("count")+'</th><th>'+tr("unit")+'</th>';
  withEl('footer', (n)=> n.style.display='block');
  withEl('copy_button', function(n){
    n.style.display='block';
    n.style.backgroundColor = "buttonface";
    n.disabled = false;
  });
  withEl('panel_size', (n)=> n.style.display='none');
  withEl('add_accessories', function(n){
    n.style.display='block';
    n.disabled = false;
  });
}
function acc_rows(s) { //0-name, 1-count, 2-unit
  let name = applyFilter(s[0].trim());
  name = name.replace("~","=");
  name = name.replace(/\|/g,",");
  name = name.replace(/плюс/g,"+");
  name = name.replace("[","(");
  name = name.replace("]",")");
  let count = s[1];
  let unit = s[2];
  let label = "name_label";
  let table_id='acc_table';
  let title = "";
  if (currSelection.ListSection!="Operations") { title=tr("Select accessories"); }
  if (s[3]) {
    if (s[3].constructor === Array) {
      if (s[3].length!=0) {
        let group_arr = s[3];
        label = "group_label";
        title = "";
        acc_group_hash[name] = group_arr;
        for (let i = 0; i < group_arr.length; i++) { title += group_arr[i][0]+" - "+group_arr[i][1]+" "+group_arr[i][2]+"\n"; }
      }
    } else {
      if (s[3]=="hole") { title=tr("Сhange properties"); }
      table_id=s[3]+'_acc_table';
    }
  }
  let table = document.getElementById(table_id);
  let rowCount = table.rows.length;
  let row = table.insertRow(rowCount);
  let cell=row.insertCell(0);
  if (!s[4]) { cell.innerHTML='<td class="acc_number" id="acc_number" ><acc_label>'+rowCount+'</acc_label> </td>';}
  cell=row.insertCell(1);
  cell.innerHTML='<td class="acc_name" id="acc_name" ><'+label+' onkeyup="return searchKeyPress(event)" title="'+title+'">'+name+'</'+label+'> </td>';
  cell=row.insertCell(2);
  cell.innerHTML='<td ><acc_label class="acc_count" id="acc_count">'+count.toString().replace(".",sep)+'</acc_label> </td>';
  cell=row.insertCell(3);
  cell.innerHTML='<td ><acc_label>'+unit+'</acc_label> </td>';
}
function acc2_table(s){
  $('#lists_table').append('<p id="p_'+s[0]+'" style="margin-bottom: 3px;" ><b>'+s[0]+'</b>');
  let table_name = '<table class="acc2_table" id="acc2_table" ></table>';
  $('#lists_table').append(table_name);
  let table = document.getElementById('acc2_table');
  let tableAccHeader = '<th id="acc_number_header" >№</th><th >'+tr("name")+'</th><th >'+tr("length")+'</th><th >'+tr("width")+'</th><th >'+tr("count")+'</th>';
  table.innerHTML = tableAccHeader;
  withEl('footer', (n)=> n.style.display='block');
  withEl('copy_button', (n)=> { n.style.display='block'; n.disabled=false; });
  withEl('panel_size', (n)=> n.style.display='none');
  withEl('add_accessories', (n)=> { n.style.display='block'; n.disabled=false; });
}
function acc2_rows(s){ //0-name, 1-width, 2-height,3-count,4-unit
  let name = s[0];
  name = name.replace("~","=");
  name = name.replace(/\|/g,",");
  name = name.replace(/плюс/g,"+");
  let width = s[1];
  let height = s[2];
  let count = s[3];
  let table = document.getElementById('acc2_table');
  let rowCount = table.rows.length;
  let row = table.insertRow(rowCount);
  let cell=row.insertCell(0);
  cell.innerHTML='<td class="acc_number" id="acc_number"><acc_label>'+rowCount+'</acc_label></td>';
  cell=row.insertCell(1);
  cell.innerHTML='<td class="acc_name" id="acc_name"><label>'+name+'</label></td>';
  cell=row.insertCell(2);
  cell.innerHTML='<td ><acc_label class="acc_count" id="acc_count">'+width+'</acc_label></td>';
  cell=row.insertCell(3);
  cell.innerHTML='<td ><acc_label class="acc_count" id="acc_count">'+height+'</acc_label></td>';
  cell=row.insertCell(4);
  cell.innerHTML='<td ><acc_label class="acc_count" id="acc_count">'+count+tr("pc")+'</acc_label></td>';
}

// ====== LISTS LIST ==========================================================
function lists_list(s){
  let table_new = s[0];
  if (table_new == "new") {
    all_mat_array = [];
    $('#lists_table').empty();
    panel_sizes = s[1];

    withEl('panel_size_input', (n)=> { n.checked = (panel_sizes == "Готовые с кромкой"); });
    withEl('footer', (n)=> n.style.display='block');
    withEl('copy_button', function(n){
      n.style.display='block';
      n.style.backgroundColor = "buttonface";
      n.disabled = false;
    });
    withEl('add_accessories', (n)=> n.style.display='none');
    withEl('panel_size', function(n){
      n.style.display='block';
      n.disabled = false;
    });
  } else if (table_new == "new_table") {
    all_mat_array.push(s);
    let type = s[1];
    let material_name = applyFilter(s[2]);
    let mat = s[3];
    let back_mat = s[4];
    let material_thickness = s[5];
    let material_unit = s[6];
    let material_src = s[7];
    let material_area = s[8];
    let edge = s[9];
    let sheet_size = s[10];
    let sheet_count = s[11];
    let type_material = s[13];
    let max_width_of_count = s[14];
    $('#lists_table').append('<p id="p_'+mat+"/"+back_mat+"/"+material_thickness+'/'+material_unit+'/'+type_material+"/"+max_width_of_count+'" > ' );
    $('#lists_table').append('<table class="list_table" id="'+type+"="+mat+"="+back_mat+"="+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count+'" ></table>');
    let tableListHeader = '<th align="left" colspan="6" <span><img class="texture_image" align="left" id="texture_image_'+ type+"="+mat+"="+back_mat+'='+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count+'" title="'+tr("Collapse/expand the list")+'" src="'+material_src+'"></span> <span><text title="'+tr("Select all the details")+'" id="material_name">'+material_name+", "+material_thickness+' '+tr("mm")+' <br>'+material_area+' '+material_unit;
    if (sheet_size != "") { tableListHeader = tableListHeader.concat (' ('+sheet_size+' - '+sheet_count+' '+tr("pc")+')');}
    let strips = '';
    if (edge[0]) {
      let edge_type = edge[0][2];
      let edge_count = Math.ceil(edge[0][3]);
      if (edge[0][5]) {
        if (edge[0][5].slice(-1) == "1") { strips = ' ('+edge[0][5]+' '+tr("strip")+')';}
        else if ((edge[0][5].slice(-1) == "2") || (edge[0][5].slice(-1) == "3") || (edge[0][5].slice(-1) == "4")) { strips = ' ('+edge[0][5]+' '+tr("stripes")+')';}
        else { strips = ' ('+edge[0][5]+' '+tr("strips")+')';}
      }
      if (edge_type[0] == "_") { tableListHeader = tableListHeader.concat ('<font color="red"><br>'+tr("Edge")+'_'+edge_type.slice(1,edge_type.length)+" - "+edge_count+' '+tr("m")+'</font>'); }
      else { tableListHeader = tableListHeader.concat ('<br>'+tr("Edge")+'_'+edge_type+" - "+edge_count+' м'+strips); }
    }
    if (edge[1]) {
      let edge_type = edge[1][2];
      let edge_count = Math.ceil(edge[1][3]);
      if (edge[1][5]) {
        if (edge[1][5].slice(-1) == "1") { strips = ' ('+edge[1][5]+' '+tr("strip")+')';}
        else if ((edge[1][5].slice(-1) == "2") || (edge[1][5].slice(-1) == "3") || (edge[1][5].slice(-1) == "4")) { strips = ' ('+edge[1][5]+' '+tr("stripes")+')';}
        else { strips = ' ('+edge[1][5]+' '+tr("strips")+')';}
      }
      if (edge_type[0] == "_") { tableListHeader = tableListHeader.concat ('<font color="red"><br>'+tr("Edge")+'_'+edge_type.slice(1,edge_type.length)+" - "+edge_count+' '+tr("m")+'</font>'); }
      else { tableListHeader = tableListHeader.concat ('<br>'+tr("Edge")+'_'+edge_type+" - "+edge_count+' м'+strips); }
    }
    if (edge[2]) {
      let edge_type = edge[2][2];
      let edge_count = Math.ceil(edge[2][3]);
      if (edge[2][5]) {
        if (edge[2][5].slice(-1) == "1") { strips = ' ('+edge[2][5]+' '+tr("strip")+')';}
        else if ((edge[2][5].slice(-1) == "2") || (edge[2][5].slice(-1) == "3") || (edge[2][5].slice(-1) == "4")) { strips = ' ('+edge[2][5]+' '+tr("stripes")+')';}
        else { strips = ' ('+edge[2][5]+' '+tr("strips")+')';}
      }
      if (edge_type[0] == "_") { tableListHeader = tableListHeader.concat ('<font color="red"><br>'+tr("Edge")+'_'+edge_type.slice(1,edge_type.length)+" - "+edge_count+' '+tr("m")+'</font>'); }
      else { tableListHeader = tableListHeader.concat ('<br>'+tr("Edge")+'_'+edge_type+" - "+edge_count+' м'+strips); }
    }
    if (edge[3]) {
      let edge_type = edge[3][2];
      let edge_count = Math.ceil(edge[3][3]);
      if (edge[3][5]) {
        if (edge[3][5].slice(-1) == "1") { strips = ' ('+edge[3][5]+' '+tr("strip")+')';}
        else if ((edge[3][5].slice(-1) == "2") || (edge[3][5].slice(-1) == "3") || (edge[3][5].slice(-1) == "4")) { strips = ' ('+edge[3][5]+' '+tr("stripes")+')';}
        else { strips = ' ('+edge[3][5]+' '+tr("strips")+')';}
      }
      if (edge_type[0] == "_") { tableListHeader = tableListHeader.concat ('<font color="red"><br>'+tr("Edge")+'_'+edge_type.slice(1,edge_type.length)+" - "+edge_count+' '+tr("m")+'</font>'); }
      else { tableListHeader = tableListHeader.concat ('<br>'+tr("Edge")+'_'+edge_type+" - "+edge_count+' м'+strips); }
    }
    tableListHeader = tableListHeader.concat ('</span></th><th width="28" >');
    tableListHeader = tableListHeader.concat ('<img align="right" class="ocl_image" id="ocl_image_'+type+"="+mat+"="+back_mat+'='+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count+'" src="cont/style/ocl.png" title="'+tr("Cutting details")+'" onclick="open_cut_list(this);">');
    tableListHeader = tableListHeader.concat ('<img align="right" class="copy_image" id="copy_image_'+type+"="+mat+"="+back_mat+'='+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count+'" src="cont/style/report.png" title="'+tr("Exporting a list")+'" onclick="export_list(this);">');
    tableListHeader = tableListHeader.concat ('</th>');
    let list_table = document.getElementById(type+"="+mat+"="+back_mat+"="+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count);
    list_table.innerHTML = tableListHeader;
  } else if (table_new == "panel_count") {
    all_mat_array.push(s);
    let type = s[1];
    let mat = s[3];
    let back_mat = s[4];
    let material_thickness = s[5];
    let material_unit = s[6];
    let panel_count = s[11];
    let grain = s[12];
    let type_material = s[13];
    let max_width_of_count = s[14];
    let list_table = document.getElementById(type+"="+mat+"="+back_mat+"="+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count);
    let rowCount = list_table.rows.length;
    let row = list_table.insertRow(rowCount);
    let grain_title, grain_img;
    if (grain == "false") { grain_title = tr("Texture without direction"); grain_img = "░░"; }
    else { grain_title = tr("Directional texture"); grain_img = "↕↕"; }
    row.innerHTML='<td><list_first grain='+grain+' class="grain" title="'+grain_title+'"><b>'+grain_img+'</b></list_first></td><td><list_label><b>'+tr("Number of parts")+'</b></list_label></td><td></td><td></td><td></td><td></td><td><list_label><b>'+panel_count+tr("pc")+'</b></list_label></td>';
  } else if (table_new == "total_panel_count") {
    all_mat_array.push(s);
    $('#lists_table').append('<p id="p_total_panel_count" >' );
    $('#lists_table').append('<table class="list_table" id="total_panel_count" ></table>');
    let list_table = document.getElementById("total_panel_count");
    list_table.innerHTML = '<tr><td></td><td><list_label><b>'+tr("Total number of parts")+': </b></list_label></td><td><list_label><b>'+s[1]+tr("pc")+'</b></list_label></td></tr>';
  } else if (table_new == "total_hole_count") {
    all_mat_array.push(s);
    $('#lists_table').append('<p id="p_total_hole_count" >' );
    $('#lists_table').append('<table class="list_table" id="total_hole_count" ></table>');
    let list_table = document.getElementById("total_hole_count");
    let content = '<tr id="total_hole_row" title="'+tr("List of holes")+'"><td>▼</td><td><hole_count_label><b>'+tr("Hole")+' </b></hole_count_label></td><td><hole_count_label><b>'+s[1]+tr("pc")+'</b></hole_count_label></td></tr>';
    for (let i = 0; i < s[2].length; i++) {
      content += '<tr id="hole_count"><td></td><td><hole_label><b>'+s[2][i][0]+'</b></hole_label></td><td><hole_label><b>'+s[2][i][1]+tr("pc")+'</b></hole_label></td></tr>';
    }
    list_table.innerHTML = content;
  } else {
    all_mat_array.push(s);
    let number = s[0];
    let type = s[1]
    let material_name = s[2];
    let mat = s[3];
    let back_mat = s[4];
    let material_thickness = s[5];
    let material_unit = s[6];
    let name = s[7];
    let item_code = s[8];
    let width_panel = s[9];
    let width_comp = s[10];
    let height_panel = s[11];
    let height_comp = s[12];
    let count_comp = s[13];
    let z1 = s[14];
    let z1_texture = s[15];
    let z2 = s[16];
    let z2_texture = s[17];
    let y1 = s[18];
    let y1_texture = s[19];
    let y2 = s[20];
    let y2_texture = s[21];
    let sel = s[22];
    let rotate = s[23];
    let type_material = s[24];
    let max_width_of_count = s[25];
    let list_table = document.getElementById(type+"="+mat+"="+back_mat+"="+material_thickness+'='+material_unit+'='+type_material+"="+max_width_of_count);
    let rowCount = list_table.rows.length;
    add_list_row(rowCount,type,mat,back_mat,material_thickness,material_unit,type_material,max_width_of_count,name,item_code,width_panel,width_comp,height_panel,height_comp,count_comp,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,number,sel,rotate);
  }
}
function add_list_row(k, type, mat, back_mat, material_thickness, material_unit, type_material, max_width_of_count, name, item_code, width_panel, width_comp, height_panel, height_comp, count_comp, z1, z1_texture, z2, z2_texture, y1, y1_texture, y2, y2_texture, number, sel, rotate) {
  let table = document.getElementById(type + "=" + mat + "=" + back_mat + "=" + material_thickness + '=' + material_unit + '=' + type_material + "=" + max_width_of_count);
  let filtered_name = applyFilter(name);
  let row = table.insertRow(k);
  let cell = row.insertCell(0);
  cell.innerHTML = `<td><number_label title="${tr("Turning in the cutting")}" id="number=${number}=${type}=${mat}=${back_mat}=${material_thickness}=${material_unit}=${type_material}=${max_width_of_count}"> ${number} </number_label></td>`;
  if (rotate == "1") { document.getElementById(`number=${number}=${type}=${mat}=${back_mat}=${material_thickness}=${material_unit}=${type_material}=${max_width_of_count}`).style.color = "red"; }
  cell = row.insertCell(1);
  let content = `<td colspan="2" id="name_comp"><name_label onkeyup="return searchKeyPress(event)" title="${tr("Change the part name")}" item_code="${item_code}" id="number=${number}=${type}=${mat}=${back_mat}=${material_thickness}=${filtered_name}">${filtered_name}</name_label></td>`;
  cell.innerHTML = content;
  cell = row.insertCell(2);
  cell.innerHTML = `<td align="right"><list_label title="${tr("Select a part")}" size1="${width_comp}" size2="${height_comp}" id="${number}${filtered_name}${item_code}${width_comp}${height_comp}"> ${(panel_sizes == "Пильные без кромки" ? width_comp : width_panel)} </list_label></td>`;
  let td_width_comp = document.getElementById(`${number}${filtered_name}${item_code}${width_comp}${height_comp}`);
  if ((z1 > 0) && (z1 < 0.8)) { td_width_comp.style.borderTop='1px green solid'; }
  if ((z1 >= 0.8) && (z1 < 1.3)) { td_width_comp.style.borderTop='2px yellow solid'; }
  if (z1 >= 1.3) { td_width_comp.style.borderTop='1px red solid'; }
  if ((z2 > 0) && (z2 < 0.8)) { td_width_comp.style.borderBottom='1px green solid'; }
  if ((z2 >= 0.8) && (z2 < 1.3)) { td_width_comp.style.borderBottom='2px yellow solid'; }
  if (z2 >= 1.3) { td_width_comp.style.borderBottom='1px red solid'; }
  if (((z1 != 0) && (mat.indexOf(z1_texture) == -1)) || ((z2 != 0) && (mat.indexOf(z2_texture) == -1))) { td_width_comp.style.color="red"; }
  cell=row.insertCell(3);
  cell.innerHTML='<td ><list_label title="'+tr("Select a part")+'" id="comp"> x </list_label> </td>';
  cell=row.insertCell(4);
  content='<td ><list_label title="'+tr("Select a part")+'" id="'+number+name+item_code+height_comp+width_comp+'"> ';
  if ((y2 > 0) && (y2 < 0.8)) { content=content.concat("<font color=green><b>|</b></font>"); }
  if ((y2 >= 0.8) && (y2 < 1.3)) { content=content.concat("<font color=yellow><b>|</b></font>"); }
  if (y2 >= 1.3) { content=content.concat("<font color=red><b>|</b></font>"); }
  content=content.concat((panel_sizes=="Пильные без кромки" ? height_comp : height_panel))
  if ((y1 > 0) && (y1 < 0.8)) { content=content.concat("<font color=green><b>|</b></font>"); }
  if ((y1 >= 0.8) && (y1 < 1.3)) { content=content.concat("<font color=yellow><b>|</b></font>"); }
  if (y1 >= 1.3) { content=content.concat("<font color=red><b>|</b></font>"); }
  content=content.concat(" </list_label> </td>");
  cell.innerHTML=content;
  let td_height_comp = document.getElementById(number+name+item_code+height_comp+width_comp);
  if (((y1 != 0) && (mat.indexOf(y1_texture) == -1)) || ((y2 != 0) && (mat.indexOf(y2_texture) == -1))) { td_height_comp.style.color="red"; }
  cell=row.insertCell(5);
  cell.innerHTML='<td ><list_label title="'+tr("Select a part")+'" id="comp"> </list_label> </td>';
  cell=row.insertCell(6);
  cell.innerHTML='<td ><list_label title="'+tr("Select a part")+'" id="count_comp">'+count_comp+tr("pc")+' </list_label></td>';
  if (sel == 0) { $(row).hide(); }
}

// ====== HANDLERS ============================================================
function searchKeyPress(e){
  e = e || window.event;
  if (e.keyCode == 13) { $('#edit').blur(); return false; }
  return true;
}
$(document).on( "click", "number_label", function() {
  let rotate;
  if (this.style.color=="red" ) { this.style.color="black"; rotate = 0; } 
  else { this.style.color="red"; rotate = 1; }
  sketchup.get_data("rotate/"+rotate+"/"+this.id);
});
$(document).on( "click", "name_label", function(e) {
  let t = e.target || e.srcElement;
  let row = t.parentNode.parentNode;
  let elm_name = t.tagName.toLowerCase();
  if(elm_name == 'input')	{return false;}
  let current_val = $(this).text();
  let old_val = current_val;
  if (currSelection.ListSection=="Accessories") {
    sketchup.get_data("select_accessories/"+old_val);
  } else if (currSelection.ListSection=="Operations") {
    sketchup.get_data("select_holes/"+old_val);
  } else {
    let item_code = $(this).attr('item_code');
    let prefix = "";
    let suffix = "";
    if (old_val.indexOf(item_code+" - ") != -1) { prefix += item_code+" - "; old_val = old_val.split(" - ")[1]; }
    if ((old_val.indexOf("<") != -1) && (old_val.indexOf(">") != -1)) { prefix += old_val.split(">")[0]+">"; old_val = old_val.split(">")[1]; }
    if (old_val.indexOf(" - "+item_code) != -1) { old_val = old_val.split(" - ")[0]; suffix = " - "+item_code;}
    let id = $(this).attr('id');
    $(this).empty().append('<input type="text" id="edit" value="'+old_val+'" />');
    $('#edit').focus(); $('#edit').select();
    $('#edit').blur(function(){
      let val = $(this).val();
      if (old_val != val) {
        $(this).parent().empty().html(prefix+val+suffix);
        if(currSelection.ListSection=="Sheet"){
          let new_id = id.split("=")[0]+"="+id.split("=")[1]+"="+id.split("=")[2]+"="+id.split("=")[3]+"="+id.split("=")[4]+"="+id.split("=")[5]+"="+val;
          $(this).attr('id',new_id);
          sketchup.get_data("new_name/"+val+"/"+id);
        }
      } else { $(this).parent().empty().html(current_val); }
    })
  }
});
$(document).on( "click", "list_label", function(e) {
  let t = e.target || e.srcElement;
  let row = t.parentNode.parentNode;
  let table = row.parentNode.parentNode;
  let rows = table.rows;
  let	tables = document.getElementsByClassName('list_table');
  for (let i = 0; i < tables.length; i++) {
    if (tables[i] != table) {
      for (let j = 0; j < tables[i].rows.length; j++) {
        tables[i].rows[j].classList.remove('selected_panel');
      }
    }
  }
  if (row.classList.contains('selected_panel')){ row.classList.remove('selected_panel'); }
  else { row.classList.add('selected_panel'); }
  let panel_arr = [];
  for (let i = 1; i < rows.length; i++) {
    if (rows[i].classList.contains('selected_panel')) {
      panel_arr = panel_arr.concat(rows[i].cells[1].childNodes[0].id+"="+rows[i].cells[2].childNodes[0].getAttribute("size1")+"="+rows[i].cells[2].childNodes[0].getAttribute("size2"));
    }
  }
  if (panel_arr.length) { sketchup.get_data("select_panel/"+panel_arr.join()); }
});
$(document).on( "click", "#material_name", function(e) {
  let t = e.target || e.srcElement;
  let row = t.parentNode.parentNode.parentNode;
  let table = row.parentNode.parentNode;
  let rows = table.rows;
  if (!event.ctrlKey) {
    selected_panel_arr = [];
    let	tables = document.getElementsByClassName('list_table');
    for (let i = 0; i < tables.length; i++) {
      if (tables[i] != table) {
        for (let j = 1; j < tables[i].rows.length; j++) {
          tables[i].rows[j].classList.remove('selected_panel');
        }
      }
    }
  }
  for (let i = 1; i < rows.length-1; i++) {
    if (rows[i].classList.contains('selected_panel')) {
      rows[i].classList.remove('selected_panel');
      let index = selected_panel_arr.indexOf(rows[i].cells[1].childNodes[0].id+"="+rows[i].cells[2].childNodes[0].getAttribute("size1")+"="+rows[i].cells[2].childNodes[0].getAttribute("size2"));
      if (index !== -1) { selected_panel_arr.splice(index, 1); }
    } else {
      rows[i].classList.add('selected_panel');
      selected_panel_arr = selected_panel_arr.concat(rows[i].cells[1].childNodes[0].id+"="+rows[i].cells[2].childNodes[0].getAttribute("size1")+"="+rows[i].cells[2].childNodes[0].getAttribute("size2"));
    }
  }
  if (selected_panel_arr.length) { sketchup.get_data("select_panel/"+selected_panel_arr.join()); }
});
$(document).on( "click", ".grain", function(e) {
  let t = e.target || e.srcElement;
  let row = t.parentNode.parentNode.parentNode;
  let table = row.parentNode.parentNode;
  let grain = t.parentNode.getAttribute("grain");
  let grain_title, grain_img;
  if (grain == "false") { grain_title = tr("Directional texture"); grain_img = "↕↕"; grain = true; }
  else { grain_title = tr("Texture without direction"); grain_img = "░░"; grain = false; }
  row.cells[0].innerHTML = '<list_first grain='+grain+' class="grain" title="'+grain_title+'"><b>'+grain_img+'</b></list_first>';
  sketchup.get_data("grain/"+grain+"/"+table.id);
});
$(document).on( "click", "#total_hole_row", function() {
  let table = document.getElementById('total_hole_count');
  if (!table) return;
  let rows = table.rows;
  for (let i = 1; i < rows.length; i++) { 
    if ($(rows[i]).is(':visible')) { $(rows[i]).hide(); }
    else { $(rows[i]).show(); }
  }
});
$(document).on( "click", "label", function(e) {
  if ($(this).attr('id')!="panel_size") {
    let t = e.target || e.srcElement;
    let row = t.parentNode.parentNode;
    let elm_name = t.tagName.toLowerCase();
    if(elm_name == 'input')	{return false;}
    let val = $(this).html();
    $(this).empty().append('<input type="text" id="edit" value="'+val+'" />');
    $('#edit').focus(); $('#edit').select();
    $('#edit').blur(function(){
      let val = $(this).val();
      $(this).parent().empty().html(val);
      if (row && row.cells && row.cells[6] && row.cells[8] && row.cells[9]) {
        let cost_price = (+row.cells[6].innerText.replace(",","."))*(+row.cells[8].innerText.replace(",","."));      
        row.cells[9].innerHTML = '<cost_label>' + (Math.ceil(cost_price*100)/100).toString().replace(".",",") + '</cost_label>';
      }
      withEl('save_button', function(n){ n.disabled=false; n.style.backgroundColor="red"; });
    });
  }
});
$(document).on( "change", "label", function(e) {
  if ($(this).attr('id')=="panel_size") {
    let panel_size_input = el('panel_size_input');
    if (panel_size_input && panel_size_input.checked) { panel_sizes = "Готовые с кромкой"; }
    else { panel_sizes = "Пильные без кромки"; }
    withEl('panel_size', (n)=> n.title="Размеры панелей: \n"+panel_sizes);
    sketchup.get_data("change_panel_size/"+panel_sizes);
    let new_all_mat_array = all_mat_array.slice();
    all_mat_array = [];
    lists_list(["new",panel_sizes]);
    for (let i = 0; i < new_all_mat_array.length; i++) { 
      lists_list(new_all_mat_array[i]);
    }
    for (let i = 0; i < visible_rows.length; i++) { 
      let table_id = visible_rows[i];
      let table = document.getElementById(table_id.slice(14,table_id.length));
      if (!table) continue;
      let rows = table.rows;
      for (let j = 1; j < rows.length-1; j++) { $(rows[j]).show(); }
    }
  }
});
$(document).on( "click", "#add_accessories", function(e) { sketchup.get_data("add_accessories"); });
$(document).on( "click", ".texture_image", function() {
  let table_id = $(this).attr('id');
  let table = document.getElementById(table_id.slice(14,table_id.length));
  if (!table) return;
  let rows = table.rows;
  if ($(rows[1]).is(':visible')) {visible_rows.splice(visible_rows.indexOf(table_id), 1);}
  else { visible_rows.push(table_id); }
  for (let i = 1; i < rows.length-1; i++) { if ($(rows[i]).is(':visible')) { $(rows[i]).hide(); } else { $(rows[i]).show(); } }
});
$(document).on( "click", ".Listtablinks", function() {
  window.scrollTo(0, 0);
  let name = $(this).attr('data-name');
  if (name == "Price") {
    sketchup.get_data("activate_price");
  } else {
    $(".Listtablinks").each(function () { $(this).removeClass("active"); });
    if ($(this).hasClass("active")) {
      $(this).removeClass("active");
      currSelection.ListSection = currSelection.ListSection.filter(function (item) { return item !== name; });
    } else {
      $(this).addClass("active");
      currSelection.ListSection = [];
      currSelection.ListSection.push(name);
      check_listtablinks();
      sketchup.get_data("model_name");
    }
    withEl('copy_button', (n)=> n.value = tr("Copy the list"));
    withEl('transfer_button', (n)=> n.style.display='none');
  }
});
function get_model_name(name) { model_name=name; }
function open_cut_list(e) { let material = e.id; sketchup.get_data('cut_list<=>'+material.replace("ocl_image_","")); }
function export_list(e){ let material = e.id; copyToClipboard(material.replace("copy_image_","")) }
function copyToClipboard(material,prog=null) {
  let focus_elem = document.activeElement;
  let str;
  if (prog == "Excel") {
    let mat_a = material[0];
    for (let mat = 1; mat < material.length; mat++) { mat_a = mat_a+"=>"+material[mat] }
    str='copyToClipboard<=>'+mat_a+"<=>"+prog;
  }
  else { str='copyToClipboard<=>'+material; }
  sketchup.get_data(str);
  let elems = document.getElementsByClassName('copy_image');
  for (let i = 0; i < elems.length; i++) { elems[i].src="cont/style/report.png";}
}
function copy_board(s) {
  let all_array = s[0];
  let prog = s[1];
  if (prog != "Bazis") {
    let mat = all_array[0][0];
    let text_value = all_array[0][1].join('\r\n');
    for (let mat = 1; mat < all_array.length; mat++){ 
      let mat_array = all_array[mat][1];
      mat_array.shift();
      text_value += "\n\t\n"+mat_array.join('\r\n'); 
    }
    let copytext = document.createElement('textarea');
    copytext.value = text_value;
    document.body.appendChild(copytext);
    copytext.select();
    document.execCommand('copy');
    document.body.removeChild(copytext);
    if (prog != "Excel") {
      let copy_image = el('copy_image_'+mat);
      if (copy_image){ copy_image.src = "cont/style/report_done.png"; }
      if (document.activeElement && document.activeElement.blur) { document.activeElement.blur(); }
    }
    $('#report_done_message').html(tr("The list is copied to the clipboard"));
    $('#report_done_message').show();
    $('#report_done_message').css('opacity', '100');
    setTimeout(function(){
      $('#report_done_message').animate({opacity: 0}, 490, function(){ $(this).css('display', 'none'); });
    }, 2000);
  }
}
$(document).on( "click", "#copy_button", function() {
  let active = $('button.Listtablinks.active').attr('data-name');
  if (active){
    if ((active == "Sheet") || (active == "Linear")) {
      sketchup.get_data('export_list<=>'+active);
    } else {
      export_excel(active);
    }
    setTimeout(function(){ 
      withEl('copy_button', function(n){
        n.value = tr("Copy the list");
        n.disabled = false;
      });
    }, 5000);
  }
});
function export_excel(s) {
  if ((s == "Accessories") || (s == "Cost")) {
    let	table = document.getElementById('acc_table');
    let	table2 = document.getElementById('acc2_table');
    if (!table) return;
    let rows = table.rows;
    let content = ["\t"+model_name+"\n"];
    let mat_array = [];
    let all_array = [];
    let number = 0;
    for (let i = 0; i < rows.length; i += 1) {
      let value = "";
      if (acc_group_hash[rows[i].cells[1].innerText]) {
        let arr = acc_group_hash[rows[i].cells[1].innerText];
        for (let k = 0; k < arr.length; k += 1) {
          value += number+"\t"+arr[k][0]+"\t"+arr[k][1]+"\t"+arr[k][2];
          if (k!=arr[k].length-1) { value += "\n"; }
          number += 1;
        }
      } else {
        for (let j = 0; j < rows[i].cells.length; j += 1) {
          if ((i==0)&&(j==0)) { value += rows[i].cells[j].innerText+"\t"; }
          else if (j==0) { value += number+"\t"; }
          else { value += rows[i].cells[j].innerText+"\t"; }
        }
        number += 1;
      }
      content.push(value);
    }
    if (table2) {
      content.push("\n\t"+tr("Frame facades"));
      let rows2 = table2.rows;
      for (let i = 0; i < rows2.length; i += 1) {
        let value = rows2[i].cells[0].innerText;
        for (let j = 1; j < rows2[i].cells.length; j += 1) {
          value += "\t"+rows2[i].cells[j].innerText;
        }
        content.push(value);
      }
    }
    mat_array.push([]);
    mat_array.push(content);
    all_array.push([mat_array]);
    all_array.push("Excel");
    copy_board(all_array);
  } else if (s == "Operations") {
    let	tables = document.getElementsByClassName('acc_table');
    let content = ["\t"+model_name];
    for (let i = 0; i < tables.length; i += 1) {
      let table = tables[i];
      let rows = table.rows;
      if (table.classList.contains("title_table")) {
        content.push("\n\t"+table.innerText);
      } else {
        for (let j = 0; j < rows.length; j += 1) {
          let row = rows[j];
          let value = row.cells[0].innerText;
          for (let k = 1; k < row.cells.length; k += 1) { value += "\t"+row.cells[k].innerText; }
          content.push(value);
        }
      }
    }
    let mat_array = [];
    let all_array = [];
    mat_array.push([]);
    mat_array.push(content);
    all_array.push([mat_array]);
    all_array.push("Excel");
    copy_board(all_array);
  } else if ((s == "Sheet") || (s == "Linear")) {
    let list_tables = document.getElementsByClassName('list_table');
    let mat = [];
    for (let list_table of list_tables) { if (list_table.id!="total_panel_count") { mat.push(list_table.id); }}
    copyToClipboard(mat,"Excel")
  }
  withEl('copy_button', (n)=> { n.value = tr("The list is copied"); n.disabled = true; });
}

$(document).on( "click", "#transfer_button", function() { // нижняя кнопка
  let active = $('button.Listtablinks.active').attr('data-name');
  if (active){
    export_json(active);
    setTimeout(function(){ 
      withEl('transfer_button', (n)=> { n.value = tr("Transfer the list"); n.disabled = false; });
    }, 5000);
  }
});
function export_json(s) {
  if ((s == "Cost")) {
    let	table = document.getElementById('acc_table');
    let	table2 = document.getElementById('acc2_table');
    if (!table) return;
    let rows = table.rows;
    let content = ["\t"+model_name+"\n"];
    let mat_array = [];
    let all_array = [];
    let number = 0;
    for (let i = 0; i < rows.length; i += 1) {
      let value = "";
      if (acc_group_hash[rows[i].cells[1].innerText]) {
        let arr = acc_group_hash[rows[i].cells[1].innerText];
        for (let k = 0; k < arr.length; k += 1) {
          value += number+"\t"+arr[k][0]+"\t"+arr[k][1]+"\t"+arr[k][2];
          if (k!=arr[k].length-1) { value += "\n"; }
          number += 1;
        }
      } else {
        for (let j = 0; j < rows[i].cells.length; j += 1) {
          if ((i==0)&&(j==0)) { value += rows[i].cells[j].innerText+"\t"; }
          else if (j==0) { value += number+"\t"; }
          else { value += rows[i].cells[j].innerText+"\t"; }
        }
        number += 1;
      }
      content.push(value);
    }
    if (table2) {
      content.push("\n\t"+tr("Frame facades"));
      let rows2 = table2.rows;
      for (let i = 0; i < rows2.length; i += 1) {
        let value = rows2[i].cells[0].innerText;
        for (let j = 1; j < rows2[i].cells.length; j += 1) {
          value += "\t"+rows2[i].cells[j].innerText;
        }
        content.push(value);
      }
    }
    mat_array.push([]);
    mat_array.push(content);
    all_array.push([mat_array]);
    all_array.push("JSON");
    TransferJson(all_array);
  } else if (s == "Operations") {
    let	tables = document.getElementsByClassName('acc_table');
    let content = ["\t"+model_name];
    for (let i = 0; i < tables.length; i += 1) {
      let table = tables[i];
      let rows = table.rows;
      if (table.classList.contains("title_table")) {
        content.push("\n\t"+table.innerText);
      } else {
        for (let j = 0; j < rows.length; j += 1) {
          let row = rows[j];
          let value = row.cells[0].innerText;
          for (let k = 1; k < row.cells.length; k += 1) {
            value += "\t"+row.cells[k].innerText;
          }
          content.push(value);
        }
      }
    }
    let mat_array = [];
    let all_array = [];
    mat_array.push([]);
    mat_array.push(content);
    all_array.push([mat_array]);
    all_array.push("Excel");
    copy_board(all_array);
  } else if ((s == "Sheet") || (s == "Linear")) {
    let list_tables = document.getElementsByClassName('list_table');
    let mat = [];
    for (let list_table of list_tables) { if (list_table.id!="total_panel_count") { mat.push(list_table.id); }}
  }
  withEl('transfer_button', (n)=> { n.value = tr("The list is transfered"); n.disabled = true; });
}

function generateUUIDv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

async function TransferJson(s) {
  try {
    const response = await fetch("https://artrocket.ro/wp-json/ar/v1/projects", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization" : "Bearer OkifXtHTUjRKyVe5F09T6nSXsJqeBeEtNToApqtE" },
      body: JSON.stringify({ "registration_code": (el('registration_code')||{value:''}).value,
                             "project_id":  generateUUIDv4(),
                             "title": (el('project_id')||{value:''}).value,
                             "data": s
      })
    });

    if (response.ok) {
      alert("Your project data has been transfered to your online account");
    } else {
      alert("Your project data has failed transfer to your online account");
    }
  } catch (err) {
    console.error("Network error:", err);
    alert("⚠️ Could not reach activation server.");
  }	
}
