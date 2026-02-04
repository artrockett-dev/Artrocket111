// ===== materials.js (перерисовываем только один уровень ниже: HtmlDialog callback 'redraw_children') =====
var currSelection = {
  section: [],
  frontal_section: [],
  frontal_vendor: "",
  vendor: void 0,
  material: void 0
};
var frontal_color_type = "";
var material_vendor = {};
var patina_name = translate("No");
var patina_arr = [translate("No"),translate("Gold"),translate("Silver"),translate("Brown"),translate("Black")];
var arr_comp = [];
var edge_mat = false;
var delete_mat = false;
var standard_mat = false;

// безопасный мост к SketchUp
window.sketchup = window.sketchup || {};
if (typeof window.sketchup.get_data !== 'function') {
  window.sketchup.get_data = function(){ try{ console.warn('[materials] sketchup.get_data missing'); }catch(e){} };
}

function logB(msg){ try{ console.log('[materials] '+msg); }catch(e){} }

// Перерисовка: просим Ruby вызвать HtmlDialog callback 'redraw_children' (один уровень ниже)
function callRedrawChildren(delayMs){
  var ms = typeof delayMs === 'number' ? delayMs : 80;
  setTimeout(function(){
    try{
      if (typeof sketchup.redraw_children === 'function'){
        logB('calling sketchup.redraw_children()');
        sketchup.redraw_children();                 // целевой колбэк из AR_attr_redraw.rb
      } else if (typeof sketchup.force_redraw === 'function'){
        logB('sketchup.redraw_children() not found → fallback sketchup.force_redraw()');
        sketchup.force_redraw();                    // общий «полный» редроу (на всякий случай)
      } else {
        logB('no HtmlDialog callbacks found → last fallback get_data("redraw_children")');
        if (typeof sketchup.get_data === 'function') sketchup.get_data('redraw_children');
      }
    }catch(e){ try{ console.warn('[materials] redraw call error:', e); }catch(_e){} }
  }, ms);
}

function reloadJs(src) {
  src = $('script[src$="' + src + '"]').attr("src");
  $('script[src$="' + src + '"]').remove();
  $('<script/>').attr('src', src).appendTo('head');
}

function materials_activate(s){
  window.scrollTo(0, 0);
  $('#main').empty();
  sketchup.get_data('mat');
  reloadJs("cont/material_list.js");
  loadSections();
  document.body.style.backgroundColor = "#383838";
  document.getElementById("footer").style.display='none';
  document.getElementById('add_accessories').style.display='none';
  document.getElementById('add_attribute').style.display='none';
  document.getElementById('set_position_att').style.display='none';
  document.getElementById('auto_refresh').style.display='none';
  document.getElementById('panel_size').style.display='none';
  if (s){
    $(document.getElementById(s[0])).click();
    if (s[0] == "Frontal") { $(document.getElementById(s[2])).click(); $(document.getElementById(s[3])).click(); }
    else { $('#'+s[1]).click(); }
  }
}

function change_edge_mat(new_edge_mat) { edge_mat = (new_edge_mat=="true"); }

function loadSections() {
  var sections = [];
  $.each(material_content.sections, function(key, value){
    sections.push('<button class="tablinks" id="'+value.name+'" data-name="'+value.name+'">'+value.alias+'</button>');
  });
  $('#sections').remove();
  $("<div/>", { "id":"sections", html: sections.join("") }).appendTo("#main");
}

function frontal_sections_name(value) {
  const namesMap = {
    "MDF": "PVC",
    "PLASTIC": "Plastic",
    "LDSP": "Chipboard",
    "LMDF": "MDF",
    "COLOR": "Enamel",
    "SHPON": "Veneer",
    "MASSIV": "Wood"
  };
  return namesMap[value] ? translate(namesMap[value]) : value;
}

function loadFrontalSections(filterVendor) {
  var frontal_sections = [];
  $.each(filterVendor, function(key, value){
    var section_name = frontal_sections_name(value);
    frontal_sections.push('<button class="frontal_tablinks" id="'+value+'" data-name="'+value+'">'+section_name+'</button>');
  });
  $('#frontal_sections').remove();
  $('#filter-wrap').remove();
  $("<div/>", { "id":"frontal_sections", html: frontal_sections.join("") }).appendTo("#main");
  $('#vendors-wrap').remove();
  updateFrontalSectionsPosition();
}

function loadFrontalVendors(filterVendor) {
  $('#vendors-wrap').remove();
  $('#filter-wrap').remove();
  var vendors = [];
  var filterVendor0 = filterVendor[0] || "";
  var curr_section = currSelection.section;
  if (standard_mat == true) {
    var standard_path = material_content.standard[curr_section][0];
    $(".vendors").each(function(){ $(this).removeClass("active"); });
    currSelection.vendor = standard_path;
    var fv = [standard_path];
    $.each(material_content.materials, function(key){
      for (let i=0;i<fv.length;i++){
        if (key.toLowerCase().indexOf(fv[i].toLowerCase())>=0){
          if (key == standard_path) vendors.push('<button id="'+key+'" title="'+subarr(key)+'" class="vendors active">'+subarr(key)+'</button>');
          else vendors.push('<button id="'+key+'" title="'+subarr(key)+'" class="vendors">'+subarr(key)+'</button>');
        }
      }
    });
  } else {
    selected_comp("check_select");
    var select_comp_name = selected_comp("comp");
    select_comp_name = "false";
    var fv = (select_comp_name!="false") ? select_comp_name : filterVendor0;
    $.each(material_content.materials, function(key){
      if (fv == "COLOR") {
        if (key.toLowerCase().indexOf(fv.toLowerCase())>=0){
          vendors.push('<button id="'+translate("G_")+key+'" title="'+subarr(key)+' '+translate("gloss")+'" class="vendors">'+translate("G_")+subarr(key)+'</button>');
          vendors.push('<button id="'+translate("M_")+key+'" title="'+subarr(key)+' '+translate("matte")+'" class="vendors">'+translate("M_")+subarr(key)+'</button>');
        }
      } else {
        if (key.indexOf('^')==-1 && key.toLowerCase().indexOf(fv.toLowerCase())>=0){
          vendors.push('<button id="'+key+'" title="'+subarr(key)+'" class="vendors">'+subarr(key)+'</button>');
        }
      }
    });
  }
  $("<div/>", { "id":"vendors-wrap", "html": vendors.join("") }).appendTo("#main");
  updateVendorsWrapPosition();
  $('#filter').attr('placeholder', 'Поиск по материалам…');
}

function subarr(string) {
  var array = ["_LDSP","_LMDF","_MDF","_COLOR","_WORKTOP","_PLASTIC","_STONE","_SHPON",".jpg",".jpeg",".png"];
  for (let i=0;i<array.length;i++){
    var search = new RegExp('('+array[i]+')','gi');
    string = string.replace(search,'');
  }
  return string;
}

function loadVendors(filterVendor) {
  $('#vendors-wrap').remove();
  $('#filter-wrap').remove();
  var vendors = [];
  var fv = filterVendor || "";
  var curr_section = currSelection.section;
  if (standard_mat) {
    var standard_path = material_content.standard[curr_section][0];
    $(".vendors").each(function(){ $(this).removeClass("active"); });
    currSelection.vendor = standard_path;
    var fva = [standard_path];
    $.each(material_content.materials, function(key){
      for (let i=0;i<fva.length;i++){
        if (key.toLowerCase().indexOf(fva[i].toLowerCase())>=0){
          if (key==standard_path) vendors.push('<button id="'+key+'" title="'+subarr(key)+'" class="vendors active">'+subarr(key)+'</button>');
          else vendors.push('<button id="'+key+'" class="vendors">'+subarr(key)+'</button>');
        }
      }
    });
  } else {
    selected_comp("check_select");
    var select_comp_name = selected_comp("comp");
    select_comp_name = "false";
    var fva = (select_comp_name!="false") ? select_comp_name : fv;
    $.each(material_content.materials, function(key){
      for (let i=0;i<fva.length;i++){
        if (key.indexOf('^')==-1 && key.toLowerCase().indexOf(fva[i].toLowerCase())>=0){
          vendors.push('<button id="'+key+'" title="'+subarr(key)+'" class="vendors">'+subarr(key)+'</button>');
        }
      }
    });
  }
  $("<div/>", { "id":"vendors-wrap", "html": vendors.join("") }).appendTo("#main");
  updateVendorsWrapPosition();
}

function selected_comp(selection) {
  if (selection == "check_select") { str='selection'; sketchup.get_data(str); }
  else if (selection == "false") { arr_comp = []; arr_comp = "false"; return arr_comp; }
  else if (selection == "comp") { return arr_comp; }
  else { arr_comp = []; arr_comp = arr_comp.concat(selection); }
}

function appendFilter(patina=false) {
  $('#filter-wrap').remove();
  var input = '<input id="filter" size="9" placeholder="'+translate("...")+'" />'
    + '<img id="select_pick" class="select_pick" src="Cont/style/pipette.png" data-name="pick" title="'+translate("Choose a material")+'" />'
    + '<input type="checkbox" id="standard_mat" title="'+translate("Standard materials")+'" class="standard_mat" />'
    + '<span id="standard_text">'+translate("Standard")+' </span>'
    + '<input type="checkbox" id="edge_mat" title="'+translate("Change the edge according to the parameters")+'" class="edge_mat"'
    + (edge_mat ? ' checked' : '') + '/>'
    + '<span id="edge_mat_text">'+translate("Edge")+' </span>';
  if (patina != false) {
    input += '<span id="patina_text"> <br>'+translate("Patina")+': </span><select id="patina_select">';
    for (let i=0;i<patina_arr.length;i++){ input += '<option value="'+patina_arr[i]+'">'+patina_arr[i]+'</option>'; }
    input += '</select>';
  }
  $("<div />", { "id": "filter-wrap", "html": input }).appendTo("#main");
  $('#patina_select option:contains("'+patina_name+'")').prop('selected', true);
  $('.standard_mat').prop('checked', standard_mat);
  updateFilterWrapPosition();
}

function showMaterials(filterText) {
  $('#materials-wrap').remove();
  var materials = [];
  var filtered = [];
  var vendor = currSelection.vendor;
  if (standard_mat) {
    var curr_section = currSelection.section;
    var standard_materials = material_content.standard[curr_section];
    var standard_mat_length = standard_materials.length;
    if (standard_materials[1] == "") {
      materials = material_content.materials[vendor];
    } else {
      materials = [];
      for (let i=1;i<standard_mat_length;i++){ materials.push(standard_materials[i]); }
    }
  } else {
    materials = material_content.materials[vendor];
  }
  material_vendor = {};
  $.each(materials, function(key, value){ material_vendor[value] = vendor; });
  if (!filterText) {
    filtered = materials;
  } else {
    materials = [];
    Object.keys(material_content.materials).forEach(function(key){
      if (key.indexOf(vendor)!=-1){
        materials = materials.concat(material_content.materials[key]);
        $.each(material_content.materials[key], function(_, value){ material_vendor[value] = key; });
      }
    });
    filtered = materials.filter(function(item){ return item.toLowerCase().indexOf(filterText.toLowerCase()) >= 0; });
  }
  var images = [];
  images.push('<div class="add_material"><img onmouseover="filter_blur();" src="cont/style/add_material.png" title="'+translate("Add material")+'"></div>' );
  $.each(filtered, function(key, value){
    if (value!=""){
      if ([".jpg",".jpeg",".png",".bmp"].find(function(v){ return value.toLowerCase().includes(v); })) {
        var name = value.substr(0, value.lastIndexOf('.'));
var sImage = material_content.full_path_materials + '/' + material_vendor[value].replace("^", "/") + '/' + value;
sImage = sImage.replace(/\//g, "\\");

images.push('<div class="materials" oncontextmenu="return menu(event, \'' + name + '\');" data-name="' + value + '">'
            + '<img onmouseover="filter_blur();" src="' + sImage + '" title="' + subarr(value) + '" />'
            + name 
            + '<div id="' + name + '" class="right-menu">'
            + '<button class="delete_material" id="delete_mat_' + material_vendor[value].replace("^", "/") + '/' + value + '" >' 
            + translate("Delete") + '</button>'
            + '</div></div>');
      } else {
        images.push('<div class="material_vendors" id="'+vendor+'^'+value+'" data-name="'+vendor+'^'+value+'"><img onmouseover="filter_blur();" src="./cont/style/pictures.png" title="'+subarr(value)+'">'+value+'</div>' );
      }
    }
  });
  $("<div/>", { "id":"materials-wrap", html: images.join("") }).appendTo("#main");
}

function filter_blur() { document.getElementById("filter").blur(); }

function sendData() {
  var str;
  if (currSelection.frontal_section.length!=0){
    if ( (currSelection.frontal_section.indexOf("COLOR")!=-1) ||
         (currSelection.frontal_section.indexOf("SHPON")!=-1) ||
         (currSelection.frontal_section.indexOf("MDF")!=-1) ) {
      str = 'sendMat/'+currSelection.section+'/'+currSelection.frontal_vendor+'/'+currSelection.material+'/'+patina_name+'/'+patina_arr;
    } else {
      str = 'sendMat/'+currSelection.section+'/'+material_vendor[currSelection.material]+'/'+currSelection.material+'/'+patina_name+'/'+[translate("No")];
    }
  } else {
    str = 'sendMat/'+currSelection.section+'/'+material_vendor[currSelection.material]+'/'+currSelection.material+'/'+patina_name+'/'+[translate("No")];
  }
  var edge = document.getElementById("edge_mat").checked;
  sketchup.get_data(str+'/'+edge);

  // перерисовать только прямых детей (уровень ниже)
  callRedrawChildren(60);
}

function sendDataPick() {
  sketchup.get_data("pick");
  // перерисовать только прямых детей (уровень ниже)
  callRedrawChildren(60);
}

$(document).on("click", ".frontal_tablinks", function(){
  window.scrollTo(0, 0);
  $('#materials-wrap').remove();
  $(".frontal_tablinks").each(function(){ $(this).removeClass("active"); });
  var name = $(this).attr('data-name');
  if ($(this).hasClass("active")) {
    $(this).removeClass("active");
    currSelection.frontal_section = currSelection.frontal_section.filter(function (item) { return item !== name; });
  } else {
    $(this).addClass("active");
    currSelection.frontal_section = [];
    currSelection.frontal_section.push(name);
    var filterVendor = [name];
    $('#filter-wrap').remove();
    loadFrontalVendors(filterVendor);
    var patina = false;
    if ( (currSelection.frontal_section.indexOf("COLOR")!=-1) ||
         (currSelection.frontal_section.indexOf("SHPON")!=-1) ||
         (currSelection.frontal_section.indexOf("MDF")!=-1) ) { patina = true; }
    appendFilter(patina);
    if (standard_mat) { showMaterials(); }
  }
});

$(document).on("click", ".tablinks", function(){
  window.scrollTo(0, 0);
  $('#materials-wrap').remove();
  currSelection.frontal_section = [];
  $(".tablinks").each(function(){ $(this).removeClass("active"); });
  var name = $(this).attr('data-name');
  if ($(this).hasClass("active")) {
    $(this).removeClass("active");
    currSelection.section = currSelection.section.filter(function (item) { return item !== name; });
  } else {
    $(this).addClass("active");
    currSelection.section = [];
    currSelection.section.push(name);
    var filterVendor = material_content.vendors[name];
    if (name=="Frontal") { loadFrontalSections(filterVendor); }
    else { $('#frontal_sections').remove(); loadVendors(filterVendor); }
    appendFilter(false);
    if (standard_mat) { showMaterials(); }
  }
});

$(document).on("click", ".vendors", function(){
  window.scrollTo(0,0);
  $(".vendors").each(function(){ $(this).removeClass("active"); });
  $(this).addClass("active"); $(this).blur();
  if (($(this).text().startsWith(translate("G_"))) || ($(this).text().startsWith(translate("M_")))) {
    currSelection.vendor = $(this).attr('id').slice(2);
  } else {
    currSelection.vendor = $(this).attr('id');
  }
  currSelection.frontal_vendor = $(this).attr('id');
  currSelection.material = void 0;
  appendFilter(false);
  showMaterials();
  $('.right-menu').hide();
});

$(document).on("click", ".material_vendors", function(){
  window.scrollTo(0,0);
  $(".material_vendors").each(function(){ $(this).removeClass("active"); });
  $(this).addClass("active");
  currSelection.vendor = $(this).attr('data-name');
  currSelection.frontal_vendor = $(this).attr('data-name');
  currSelection.material = void 0;
  showMaterials();
  $('.right-menu').hide();
});

$(document).on("change paste keyup", "#filter", function(){
  var filterText = $('#filter').val();
  currSelection.material = void 0;
  if (filterText!=""){ $(".material_vendors").each(function(){ $(this).addClass("active"); }); }
  showMaterials(filterText);
  $('.right-menu').hide();
});

$(document).on("click", ".materials", function(){
  $('.right-menu').hide();
  $(".materials").each(function(){ $(this).removeClass("active"); });
  if (delete_mat) return;
  $(this).addClass("active");
  currSelection.material = $(this).attr('data-name');
  sendData();
});

$(document).on("click", ".add_material", function(){
  $(".materials").each(function(){ $(this).removeClass("active"); });
  var str = 'load_material/'+currSelection.section+'/'+currSelection.vendor+'/'+currSelection.frontal_section+'/'+currSelection.frontal_vendor;
  sketchup.get_data(str);
});

$(document).on("click", ".select_pick", function(){ sendDataPick(); });
$(document).on("change", "#edge_mat", function(){ edge_mat = !!document.getElementById("edge_mat").checked; });
$(document).on("change", "#patina_select", function(){ patina_name = $(this).val(); });

$(document).on("change", ".standard_mat", function(){
  standard_mat = $(this).prop('checked');
  var curr_section = currSelection.section;
  var filterVendor = material_content.vendors[curr_section];
  var frontal_section = currSelection.frontal_section;
  if (curr_section.indexOf("Frontal")!=-1) {
    loadFrontalSections(filterVendor);
    loadFrontalVendors(frontal_section);
  } else { loadVendors(filterVendor); }
  var patina = frontal_section.some(function(item){ return ["COLOR","SHPON","MDF"].includes(item); });
  appendFilter(patina);
  $('#materials-wrap').remove();
  if (standard_mat) { showMaterials(); }
  $('.right-menu').hide();
});

function pick_mat(values){
  var f = values;
  if (currSelection.section.indexOf("Frontal")!=-1) {
    frontal_color_type = f.substr(0, f.indexOf('_')+1);
  }
  var str = "search"+'/'+currSelection.section+'/'+f;
  if (currSelection.frontal_section) {
    if ( (currSelection.frontal_section.indexOf("COLOR")!=-1) ||
         (currSelection.frontal_section.indexOf("SHPON")!=-1) ||
         (currSelection.frontal_section.indexOf("MDF")!=-1) ) {
      str += '/'+patina_name+'/'+patina_arr;
    } else { str += '/'+patina_name+'/'+translate("No"); }
  } else { str += '/'+patina_name+'/'+translate("No"); }
  var edge = document.getElementById("edge_mat").checked;
  sketchup.get_data(str+'/'+edge);

  // перерисовать только прямых детей (уровень ниже)
  callRedrawChildren(60);
}

function onVend(values){
  var on_vend = values[0];
  var f = values[1].replace(/\.[^.]+$/, "");
  $(".vendors").each(function(){ $(this).removeClass("active"); });
  if ((on_vend) && (on_vend != 0)) {
    if (currSelection.section.indexOf("Frontal")!=-1) {
      var frontal_section = on_vend.substr(on_vend.lastIndexOf('_')+1);
      document.getElementById(frontal_section).click();
    }
    document.getElementById(frontal_color_type+on_vend).click();
    document.getElementById("filter").value = f;
    showMaterials(f);
    $('.right-menu').hide();
  }
  frontal_color_type = "";
}

function menu(event,id_comp){
  event = event || window.event;
  event.cancelBubble = true;
  $('.right-menu').hide();
  document.getElementById(id_comp).style.display = 'block';
  return false;
}

$(document).on('contextmenu', function(){ $('.right-menu').hide(); });
$(document).on('click', function(){ $('.right-menu').hide(); });

$(document).on('click', '.delete_material', function(){
  delete_mat = true;
  let ids = $(this).attr('id');
  sketchup.get_data(ids);
  let path = ids.slice(11).split("/");
  let curr_section = currSelection.section;
  setTimeout(function(){
    materials_activate();
    document.getElementById(curr_section).click();
    document.getElementById(path[0]).click();
    if (path.length > 2) { document.getElementById(path[0]+"^"+path[1]).click(); }
    delete_mat = false;
  }, 200);
});

function updateFrontalSectionsPosition(){
  const main_menu = document.getElementById('main_menu');
  const sections = document.getElementById('sections');
  const frontalSections = document.getElementById('frontal_sections');
  if (frontalSections) {
    let height = main_menu.offsetHeight;
    height += sections.offsetHeight;
    frontalSections.style.top = `${height}px`;
  }
}
function updateVendorsWrapPosition(){
  const main_menu = document.getElementById('main_menu');
  const sections = document.getElementById('sections');
  const frontalSections = document.getElementById('frontal_sections');
  const vendorsWrap = document.getElementById('vendors-wrap');
  if (vendorsWrap) {
    let height = main_menu.offsetHeight;
    height += sections.offsetHeight;
    if (frontalSections) { height += frontalSections.offsetHeight; }
    vendorsWrap.style.top = `${height}px`;
  }
}
function updateFilterWrapPosition(){
  const main_menu = document.getElementById('main_menu');
  const sections = document.getElementById('sections');
  const frontalSections = document.getElementById('frontal_sections');
  const vendorsWrap = document.getElementById('vendors-wrap');
  const filterWrap = document.getElementById('filter-wrap');
  if (filterWrap) {
    let height = main_menu.offsetHeight;
    height += sections.offsetHeight;
    if (frontalSections) { height += frontalSections.offsetHeight; }
    if (vendorsWrap) { height += vendorsWrap.offsetHeight; }
    filterWrap.style.top = `${height}px`;
  }
}
function updatePositions(){
  updateFrontalSectionsPosition();
  updateVendorsWrapPosition();
  updateFilterWrapPosition();
}
window.addEventListener('resize', updatePositions);
