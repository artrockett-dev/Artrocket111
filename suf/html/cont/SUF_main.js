document.addEventListener('DOMContentLoaded', function() {
	translate_name_item();
    sketchup.get_data("read_param");
}, false);
function translate_name_item() {
    $(".menu_item").each(function (index) {
    $(this).html(translate($(this).html()));
    })
}
$(document).on( "click", ".menu_item", function() {
    $(".menu_item").each(function () {
        $(this).removeClass("active")
    })
    var name = $(this).attr('data-name');
    if ($(this).hasClass("active")) {
        $(this).removeClass("active");
        currSelection.main_menu = currSelection.main_menu.filter(function (item) {
            return item !== name;
        })
        } else {
        $(this).addClass("active");
        currSelection.main_menu = [];
        currSelection.main_menu.push(name);
    }
});
function activate_item(item_name) {
    $(".menu_item").each(function () {
        if ($(this).attr('data-name') == item_name) {
            $(this).click();
            $(this).addClass("active"); 
            }
        currSelection.main_menu = [];
        currSelection.main_menu.push(name);
    });
}
function have_updates(new_version_text) {
    $('#main').append("<div class='center'><div class='new_version_text'><br> "+new_version_text.split("@")[0]+" → "+new_version_text.split("@")[1]+"</div><br><button class='update' onclick='update_dialog();'>"+new_version_text.split("@")[2]+"</button><div class='new_version_text'><br> ("+new_version_text.split("@")[3]+")</div></div>");
}
function update_dialog() {
    sketchup.get_data("update_dialog");
    $('#main').empty();
}

