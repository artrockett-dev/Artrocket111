
document.addEventListener('DOMContentLoaded', function() {
    sketchup.get_data("read_param");
}, false);
function parameters(s){
    var content='';
    document.getElementById('apply').innerHTML = translate("Save");
    var table = document.getElementById("section_parameter_table");
    var rows = table.rows;
    var rowCount = table.rows.length;
    for (var i = 0; i < s.length; i += 1) {
        row = table.insertRow(i);
        cell=row.insertCell(0);
        cell.innerHTML='<td >' + s[i].split("=")[0] + '</td>';
        if ( s[i].split("=")[1] ) {
            cell=row.insertCell(1);
            if (s[i].split("=")[3].toLowerCase().indexOf("input") != -1) {
                content='<td ><input id="' + s[i].split("=")[1] + '" type="text" value="' + s[i].split("=")[2] + '"></td>';
                cell.innerHTML=content;
                } else if (s[i].split("=")[3].toLowerCase().indexOf("select") != -1 ) {
                content='<td ><select id="' + s[i].split("=")[1] + '" type="text" ></td>';
                var option_array = s[i].split("=")[4].split("&");
                for (var j = 1; j < option_array.length; j += 1) {
                    content=content.concat('<option value="'+option_array[j].split("^")[0]+'">'+option_array[j].split("^")[1]+'</option>');
                }
                content=content.concat('</select>');
                cell.innerHTML=content;
                document.getElementById(s[i].split("=")[1]).value = s[i].split("=")[2];
            }
        }
    }
}
$(document).on( "focus", "input", function() {
    document.getElementById('apply').disabled = false;
});
$(document).on( "focus", "select", function() {
    document.getElementById('apply').disabled = false;
});
function save_changes() {
    var table = document.getElementById("section_parameter_table");
    var rows = table.rows;
    var str = "save_changes";
    for (var i = 0; i < rows.length; i += 1) {
        var label = rows[i].cells[0].innerText;
        if ( rows[i].cells[1] ) {
            var tr_td_id = rows[i].cells[1].childNodes[0].id;
            var value = rows[i].cells[1].childNodes[0].value;
            if ( tr_td_id.indexOf("waste") != -1 ) {
                if (value.slice(-1) != "%") { value = value + "%" }
            }
            var tagName = rows[i].cells[1].childNodes[0].tagName;
            str += "|"+label+"="+tr_td_id+"="+value+"="+tagName;
            if (tagName=="SELECT") { 
                str += "=";
                var options = rows[i].cells[1].childNodes[0].childNodes;
                for (var j = 0; j < options.length; j += 1) {
                    var opt_value = options[j].value;
                    var opt_text = options[j].innerText;
                    str += "&"+opt_value+"^"+opt_text;
                }
            }
        } else {
            str += "|"+label
        }
    }
    sketchup.get_data(str);
    $('#section_parameter_table').empty();
    sketchup.get_data("read_param");
    document.getElementById('apply').disabled = true;
}

