
document.addEventListener('DOMContentLoaded', function() {
    sketchup.get_data("read_param");
}, false);
function parameters(s){
    let hide_new_objects = s[0];
    let table = document.getElementById("pages_properties_table");
    let row = table.insertRow(table.rows.length);
    cell=row.insertCell(0);
    cell.innerHTML='<td >Скрыть объект в других сценах</td>';
    cell=row.insertCell(1);
    if (hide_new_objects == "true") { cell.innerHTML='<td ><input id="hide_new_objects" type="checkbox" class=hide_new_objects checked></td>'; }
    else { cell.innerHTML='<td ><input id="hide_new_objects" type="checkbox" class=hide_new_objects</td>'; }
}
$(document).on( "change", "#hide_new_objects", function() {
    sketchup.get_data('hide_new_objects=>'+document.getElementById("hide_new_objects").checked);
});

