// SUF_attribute.js (merged: new base + old extras, no JS-side redraw, selection-fix)

// ===== Translation DB fallback (coexists with global translate()) =====
window.translationDB = window.translationDB || {};
function translateFromDB(text){ const t = window.translationDB[(text||'').trim()]; return t!==undefined ? t : text; }

// ===== Safe bridge & debounce =====
window.sketchup = window.sketchup || {};
if (typeof window.sketchup.get_data !== 'function') window.sketchup.get_data = function(){ console.warn('[SUF_attribute] sketchup.get_data missing'); };
const __debounce = (fn, ms)=>{ let t; return (...a)=>{ clearTimeout(t); t=setTimeout(()=>fn(...a), ms); }; };

// ===== Selection change handling (called from Ruby) =====
window.__SUF__selSig = null;
function __makeSelSig(idsOrSig){ if (Array.isArray(idsOrSig)) return idsOrSig.join(','); if (idsOrSig == null) return ''; return String(idsOrSig); }
window.onSketchupSelectionChanged = __debounce(function(idsOrSig){
  const sig = __makeSelSig(idsOrSig);
  if (sig !== window.__SUF__selSig){
    window.__SUF__selSig = sig;
    add_comp();
  }
}, 80);
// для совместимости с вызовом sketchup.selection_changed(...)
window.sketchup.selection_changed = window.onSketchupSelectionChanged;

// ===== Auto-translate visible interface text =====
function autoTranslateInterface(){
  document.querySelectorAll('att_label, select option, legend, #des_name, #description, input[type=button], input[type=submit], td')
    .forEach(el=>{
      if(!el.dataset.translated && el.innerText && el.innerText.trim()){
        const orig = el.innerText; const tr = translateFromDB(orig); if(tr!==orig) el.innerText = tr; el.dataset.translated = 'true';
      }
    });
}

// ===== Restore collapsed/expanded state of nested rows =====
function restoreAttributeStates(){
  const rows = document.getElementById('attribute_table')?.rows; if(!rows) return;
  for(let i=0;i<rows.length;i++){
    const btn = rows[i].cells[1]?.querySelector('input.view'); if(!btn) continue;
    const state = localStorage.getItem('att_state_'+btn.id); if(!state) continue;
    if(state==='▶' && btn.value==='▼'){ btn.value='▶'; hide(rows[i].parentNode, i, 'none'); }
    else if(state==='▼' && btn.value==='▶'){ btn.value='▼'; hide(rows[i].parentNode, i, 'table-row'); }
  }
}

// Run translate on load
if(document.readyState==='loading'){ document.addEventListener('DOMContentLoaded', autoTranslateInterface); } else { autoTranslateInterface(); }

// Observe DOM mutations → re-translate + restore row states
const observer = new MutationObserver(()=>{ autoTranslateInterface(); restoreAttributeStates(); });
observer.observe(document.documentElement, { childList:true, subtree:true });

// ===== Globals =====
var arr_val=[], att_array=[], unit_array=[], att_to_show=[], scrollPos;
var submit_att=false, copied_att=false, activeInput=null, awaitingAttInsertion=false;

// ===== UI =====
function attributes_activate(){
  window.__SUF__selSig = null; // сброс сигнатуры выделения при активации вкладки
  arr_val=[]; att_array=[]; unit_array=[]; window.scrollTo(0,0);
  $('#main').empty()
    .append('<table id="table_mess"></table>')
    .append('<legend id="description"></legend>')
    .append('<div id="att_table"><table id="attribute_table"></table></div>');

  $('#table_mess')
    .append('<td id="Logo"><img id="image" src=""></td>')
    .append('<td id="des_name">'+(typeof translate==='function'?translate('No Components Selected'):translateFromDB('No Components Selected'))+'</td>');
  $('#description').text((typeof translate==='function'?translate('Select one or more components and view their parameters.'):translateFromDB('Select one or more components and view their parameters.')));

  document.body.style.backgroundColor = '#FFFFFF';
  const footer = document.getElementById('footer'); if(footer) footer.style.display='block';

  // Hide/Show controls
  ['copy_button','add_accessories','auto_refresh','panel_size'].forEach(id=>{ const el=document.getElementById(id); if(el) el.style.display='none'; });

  // Ensure submit button exists
  if(!document.getElementById('submit_button')){
    const btn=document.createElement('input'); btn.type='submit'; btn.id='submit_button'; btn.value=(typeof translate==='function'?translate('Apply'):translateFromDB('Apply')); btn.disabled=true; footer && footer.appendChild(btn);
  }
  $('#submit_button').show().prop('disabled',true).css('display','block').val((typeof translate==='function'?translate('Apply'):translateFromDB('Apply'))).css('background', '');

  const addAttr=document.getElementById('add_attribute'); if(addAttr){ addAttr.title='Записать скопированный атрибут\nв выбранный компонент'; addAttr.style.display='none'; }
  const setPos=document.getElementById('set_position_att'); if(setPos){ setPos.style.display='block'; }
  const attTableWrap=document.getElementById('att_table'); if(attTableWrap){ attTableWrap.style.display='block'; }

  sketchup.get_data('att');
  setTimeout(()=>{ autoTranslateInterface(); restoreAttributeStates(); },100);
}

function add_comp(){
  const table=document.getElementById('attribute_table'); if(!table) return;
  activeInput=null; arr_val=[]; att_array=[]; unit_array=[]; table.innerHTML='';
  $('#submit_button').show().prop('disabled',true); $('#att_table').show();
  if(copied_att) $('#add_attribute').show();
  const wrap=document.getElementById('att_table'); if(wrap) wrap.style.display='block';
  sketchup.get_data('att');
  setTimeout(()=>{ autoTranslateInterface(); restoreAttributeStates(); },100);
  if(submit_att){ $('html,body').animate({scrollTop:scrollPos},500); submit_att=false; }
}

function set_copied_att(v){ copied_att=v; }

function clear_selection(){
  const table=document.getElementById('attribute_table'); if(!table) return;
  arr_val=[]; att_array=[]; unit_array=[]; table.innerHTML='';
  $('#des_name').text(translateFromDB('No Components Selected'));
  $('#description').text(translateFromDB('Select one or more components and view their parameters.'));
  $('#image').attr('src','');
  $('#add_accessories').hide();
  $('#submit_button,#att_table').hide();
}

function no_attributes(des_name){
  arr_val=[]; $('#des_name').html(des_name);
  $('#description').text(translateFromDB('The selected components do not have parameters that can be edited at all.'));
  $('#image').attr('src',''); $('#submit_button,#att_table').hide();
}

function no_attributes_one(s){
  arr_val=[]; $('#des_name').html(s[0]+"<br/>", s[1]);
  $('#description').text(translateFromDB('The component has no parameters that can be edited'));
  $('#image').attr('src', s[2]); $('#submit_button,#att_table').hide();
}

// ===== Submit (single source of truth; no JS redraw) =====
function submit_changes(){
  awaitingAttInsertion=false; scrollPos=$(window).scrollTop(); submit_att=true;
  let message=['submit'];
  if(typeof activeInput!=='undefined' && activeInput){ message.push('fals'+activeInput.id+'=>' + activeInput.value); }
  message = message.concat(arr_values()||[]);
  if(message.length>1){ sketchup.get_data(message); arr_val=[]; activeInput=null; }
}

// Bind submit button
$(document).off('click','#submit_button').on('click','#submit_button', submit_changes);

// ===== Buffer API =====
function arr_values(str){ if(str){ arr_val.push(str); } else { return arr_val; } }

// ===== Inputs =====
function set_default(att, def){ if(def) document.getElementById(att).value = def; }
function key_down(att){ $('#'+att).css('backgroundColor','#B0E2FF'); $('#submit_button').prop('disabled',false); }
function key_up(e, att, deep_change){
  e=e||window.event; const input=document.getElementById(att);
  if(e.keyCode===13){ $('#submit_button').prop('disabled',false).click(); awaitingAttInsertion=false; return false; }
  if(!awaitingAttInsertion && input.value.includes('=')){ awaitingAttInsertion=true; activeInput=input; }
  return true;
}
function insertAttributeId(attrId){
  if(!awaitingAttInsertion || !activeInput) return; const input=activeInput; const cursorPos=input.selectionStart; const val=input.value;
  if(input.id.indexOf('_section_')!=-1){ attrId='LOOKUP("'+attrId+'")'; }
  const newVal = val.slice(0,cursorPos)+attrId+val.slice(cursorPos); input.value=newVal; const newCursorPos=cursorPos+attrId.length; input.setSelectionRange(newCursorPos,newCursorPos); input.focus();
}
function on_change_input(att, dc){ if(awaitingAttInsertion) return; store_values(att, dc, false); }
function on_change_check(att, dc){ const el=document.getElementById(att); el.blur(); $('#submit_button').prop('disabled',false).focus(); const val=el.checked; sketchup.get_data('change_checkbox/'+att+'=>'+val); arr_values('chck'+att+'=>'+val); }
function on_change_select(att, dc){ const el=document.getElementById(att); if(!el) return; el.blur(); $('#submit_button').prop('disabled',false).focus(); $(el).css('backgroundColor','#B0E2FF'); store_values(att, dc, true); check_visible_attribute(att); }
function check_visible_attribute(att){ const v=document.getElementById(att).value; sketchup.get_data('check_visible_attribute/'+att+'='+encodeURIComponent(v)); }

// ===== Show/Hide =====
function show_hide_att(cmds){
  const rows=document.getElementById('attribute_table').rows;
  for(let i=0;i<rows.length;i++){
    const id = rows[i].cells[1]?.firstElementChild?.id || rows[i].cells[1]?.childNodes?.[0]?.id;
    cmds.forEach(cmd=>{
      if(cmd[1]===id){
        if(cmd[0]==='SETACCESS'){
          rows[i].style.display = cmd[2]==='NONE' ? 'none' : 'table-row';
          const inputEl=document.getElementById(id); if(inputEl) inputEl.disabled = (cmd[2]==='VIEW');
        } else if(cmd[0]==='SETLABEL'){
          rows[i].cells[0].firstElementChild.innerHTML = cmd[2];
        }
      }
    });
  }
}

function store_values(att, dc, select_tag=false){
  var arr = arr_values()||[]; if(arr.length){ arr.forEach((e,idx)=>{ if(e.startsWith(dc+att)) arr_val.splice(idx,1); }); }
  var str='', sep='=>', s=document.getElementById(att).value; if(s!==''){
    var formula=false; if(s[0]==='='){ formula=true; s=s.substring(1); }
    var number_in_string = s[0]?.replace(/[^\d\.]/g,'');
    if(!select_tag && number_in_string!=='' && Number.isInteger(+number_in_string)){
      if(s.indexOf('+')!=-1){ let s_arr=s.split('+'); let result=Number(s_arr[0].replace(',','.').replace(/[^\d\.\-]/g,'')); for(let i=1;i<s_arr.length;i++){ result += Number(s_arr[i].replace(',','.').replace(/[^\d\.\-]/g,'')); } s=result; }
      else if(s.indexOf('-')!=-1){ let s_arr=s.split('-'); let result=Number(s_arr[0].replace(',','.').replace(/[^\d\.]/g,'')); for(let i=1;i<s_arr.length;i++){ result -= Number(s_arr[i].replace(',','.').replace(/[^\d\.]/g,'')); } s=result; }
      else if(s.indexOf('/')!=-1){ let s_arr=s.split('/'); let result=Number(s_arr[0].replace(',','.').replace(/[^\d\.\-]/g,'')); for(let i=1;i<s_arr.length;i++){ result /= Number(s_arr[i].replace(',','.').replace(/[^\d\.\-]/g,'')); } s=result; }
      else if(s.indexOf('*')!=-1){ let s_arr=s.split('*'); let result=Number(s_arr[0].replace(',','.').replace(/[^\d\.\-]/g,'')); for(let i=1;i<s_arr.length;i++){ result *= Number(s_arr[i].replace(',','.').replace(/[^\d\.\-]/g,'')); } s=result; }
    } else if(!select_tag){
      if(s.indexOf('/')!=-1){ alert("Нельзя использовать символ ' / '"); return; }
      else if(s.indexOf('*')!=-1){ alert("Нельзя использовать символ ' * '"); return; }
      else if(s.indexOf('+')!=-1){ alert("Нельзя использовать символ ' + '"); return; }
      else if(s.indexOf('(')!=-1){ alert("Нельзя использовать символ ' ( '\nВместо него используйте ' [ '"); return; }
      else if(s.indexOf(')')!=-1){ alert("Нельзя использовать символ ' ) '\nВместо него используйте ' ] '"); return; }
    }
    if(formula){ att='_'+att+'_formula'; }
  }
  str = (dc+att)+sep+s; arr_values(str);
  var unit_of_att = att_array.indexOf(dc+att); var att_value=document.getElementById(att)?.value;
  if((typeof formula!=='undefined' && !formula) && number_in_string!=='' && Number.isInteger(+number_in_string) && unit_of_att!=-1 && att_value.indexOf(unit_array[unit_of_att])==-1){ document.getElementById(att).value = s + unit_array[unit_of_att]; }
}

function name_list(s){ // [dn, code, sum, desc, thumb]
  let [dn, code, sum, desc, thumb]=s; if(code) dn += '<br/>'+code; $('#des_name').html(dn);
  if(sum && sum!=='nil') desc = '<b>'+sum+'</b><br/>'+desc; $('#description').html(desc);
  $('#image').attr('src', (thumb||'')+'?anti_cache='+Math.random());
}

// ===== attribute_list & add_row =====
function attribute_list(s){
  const att=s[0], access=s[1], label=s[2], units=s[3], val=s[4];
  const s_typ = s[5] ? unescape(s[5]) : ''; const s_val = s[6] ? unescape(s[6]) : '';
  const hideCls = s[7] ? 'none' : 'table-row'; const formula=s[8]; const def=s[9]||'';
  const dc='fals'; const table=document.getElementById('attribute_table'); if(!table) return;
  if(!document.getElementById(att)){
    add_row(table.rows.length, 'attribute_table', access, label, att, val, s_val, s_typ, dc, hideCls, formula||'', def||'');
    autoTranslateInterface(); restoreAttributeStates();
  }
  if(access!=='LIST' && (val+'').includes(' ')){
    att_array.push(dc+att); unit_array.push((val+'').slice((val+'').indexOf(' ')));
  }
}

function hidden_rows(){ const rows=document.getElementById('attribute_table').rows; for(let i=0;i<rows.length;i++){ const btn=rows[i].cells[1]?.querySelector('input.view'); if(!btn) continue; hide(rows[i].parentNode, i, btn.value==='▶'?'none':'table-row'); } }

function hide(table, idx, disp){ const rows=table.rows; for(let i=idx+1;i<rows.length;i++){ if(rows[i].className==='none') continue; if(/[▼▶]/.test(rows[i].cells[1].innerHTML) || /&#9660;|&#9654;|___/.test(rows[i].cells[1].innerHTML)) break; rows[i].style.display=disp; } }

function add_row(i,id_tab,access,label,id_i,val,s_val,s_typ,dc,hideClass,formula='',def=''){
  var table=document.getElementById(id_tab), row=table.insertRow(i), c0=row.insertCell(0), c1=row.insertCell(1);
  let content = '<td><att_label onmouseover="ChangeOver(\''+id_i+'\')" onmouseout="ChangeOut(\''+id_i+'\')" title="" onclick="insertAttributeId(\''+id_i+'\')" ondblclick="onDoubleClick(\''+id_i+'\')">';
  if((val+'' ).indexOf('&#9660;')!=-1 || (val+'' ).indexOf('&#9654;')!=-1){ content += ((id_i.indexOf('_section_')!=-1)?'<input type="button" title="Удалить секцию" class="delete_section" onclick="delete_section(\''+id_i+'\')" value="x">':''); }
  content += label + '</att_label></td>'; c0.innerHTML = content;

  if(access==='VIEW'){
    let c = '<td><input '; if((val+'').indexOf('Редактировать')!=-1 || (val+'').indexOf('Edit')!=-1){ c+='type="button" class="edit" '; }
    else if((val+'').indexOf('&#9660;')!=-1 || (val+'').indexOf('&#9654;')!=-1){ c+='type="button" class="view" table_id="'+id_tab+'"'; }
    else if((val+'').indexOf('Показать')!=-1 || (val+'').indexOf('Show')!=-1){ c+='type="button" class="axis_comp" '; }
    else if(id_i==='s9_comp_copy'){ c+='type="button" class="copy_comp" '; }
    else { c+='disabled="true" onkeyup="return key_up(event, this.id, \''+dc+'\')" onchange="on_change_input(this.id, \''+dc+'\')"'; }
    c += ' id="'+id_i+'" number="'+i+'" value="'+val+'"></td>'; c1.innerHTML=c;
  }
  else if(access==='TEXTBOX'){
    c1.innerHTML = '<td id="cell"><input onmouseover="ChangeOver(\''+id_i+'\')" onmouseout="ChangeOut(\''+id_i+'\')" type="text" id="'+id_i+'" onfocusin="set_default(\''+id_i+'\',\''+def+'\')" value="'+val+'" onkeydown="key_down(this.id)" onkeyup="return key_up(event, this.id, \''+dc+'\')" title="'+(formula?formula:(id_i.indexOf('c2_shelve')!=-1?translateFromDB('Clear - auto'):''))+'" onchange="on_change_input(this.id, \''+dc+'\')"></td>';
  }
  else if(access==='CHECKBOX'){
    let c='<td style="text-align:left; vertical-align:middle;">'; const checkbox_array=(val+'').split(',');
    for(let i=0;i<checkbox_array.length;i++){ const parts=checkbox_array[i].split('=>'); const labelTxt=parts[0], value=parts[1]; c += '<label style="margin-left:2px; vertical-align:middle; line-height:16px;">'+labelTxt+'</label><input style="width:14px; margin-left:2px; margin-right:8px; vertical-align:middle;" type="checkbox" id="'+id_i+'=>'+labelTxt+'" '+(value==='1'?'checked':'')+' onmouseover="ChangeOver(\''+id_i+'\')" onmouseout="ChangeOut(\''+id_i+'\')" onchange="on_change_check(this.id, \''+dc+'\')">'; }
    c+='</td>'; c1.innerHTML=c;
  }
  else if(access==='LIST'){
    let content='<td><select onmouseover="ChangeOver(\''+id_i+'\')" onmouseout="ChangeOut(\''+id_i+'\')" id="'+id_i+'" title="'+(formula||'')+'" onchange="on_change_select(this.id, \''+dc+'\')">';
    if(s_typ.indexOf(';')===-1){ content += '<option value="'+s_val+'">'+s_typ+'</option>'; content+='</select></td>'; c1.innerHTML=content; }
    else { const labs=s_typ.split(';'), vals=s_val.split(';'); for(let i2=0;i2<labs.length;i2++){ content += '<option value="'+vals[i2]+'">'+labs[i2]+'</option>'; } content+='</select></td>'; c1.innerHTML=content; const sel=document.getElementById(id_i); const idx=vals.indexOf((val+'').toString()); if(idx===-1){ $(sel).prepend('<option value=""></option>'); sel.options[0].selected=true; } else { sel.options[idx].selected=true; } }
  }
  row.className = hideClass; row.style.display = hideClass;
}

function onDoubleClick(id){ sketchup.get_data('click_att/'+id); }

// ===== Buttons / actions =====
$(document).on('click','#add_attribute', ()=>{ sketchup.get_data('add_attribute'); });
$(document).on('click','#set_position_att', ()=>{ sketchup.get_data('set_position_att'); });
$(document).on('click','.edit', function(){ if($(this).attr('id')==='name_list'){ sketchup.get_data('edit_name_list'); } else { sketchup.get_data('edit_additional'); } });
$(document).on('click','.axis_comp', ()=>{ sketchup.get_data('axis_comp'); });
$(document).on('click','.copy_comp', ()=>{ sketchup.get_data('copy_comp'); });
$(document).on('click','.view', function(){
  let table_id=$(this).attr('table_id'); var table=document.getElementById(table_id); var id=$(this).attr('id'); var number=+($(this).attr('number')); var value=$(this).attr('value');
  if(value==='▼'){ $(this).val('▶'); hide(table, number, 'none'); if(table_id==='attribute_table'){ sketchup.get_data('hidden_att/'+id+'/#9654;'); } }
  else if(value==='▶'){ $(this).val('▼'); hide(table, number, 'table-row'); if(table_id==='attribute_table'){ sketchup.get_data('hidden_att/'+id+'/#9660;'); } }
  try{ localStorage.setItem('att_state_'+id, this.value); }catch(e){}
});

function ChangeOver(row_id){ if(row_id.indexOf('_panel_section_')!=-1 || row_id.indexOf('_shelve_section_')!=-1 || row_id.indexOf('_drawer_section_')!=-1 || row_id.indexOf('_accessory_section_')!=-1 || row_id.indexOf('_frontal_section_')!=-1){ sketchup.get_data('draw_section/'+row_id); } }
function ChangeOut(row_id){ if(row_id.indexOf('_panel_section_')!=-1 || row_id.indexOf('_shelve_section_')!=-1 || row_id.indexOf('_drawer_section_')!=-1 || row_id.indexOf('_accessory_section_')!=-1 || row_id.indexOf('_frontal_section_')!=-1 || row_id.indexOf('s5')!=-1){ sketchup.get_data('select_tool'); } }
function delete_section(row_id){ sketchup.get_data('delete_section/'+row_id); attributes_activate(); }
