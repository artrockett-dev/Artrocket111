// cont/SUF_component.js
// ***** Небольшая утилита-фильтр: переводит любые вхождения из глобального объекта translateFromDB
function applyFilter(str) {
    if (typeof str !== 'string' || !window.translateFromDB) return str;
    let out = str;
    for (let key in window.translateFromDB) {
      if (!window.translateFromDB.hasOwnProperty(key)) continue;
      const esc = key.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
      out = out.replace(new RegExp(esc, 'g'), window.translateFromDB[key]);
    }
    return out;
  }
  
var currSelection = {
    CompSection: [],
    frontal_vendor: void 0,
    comp_vendor: void 0,
    component: void 0
};

function reloadJs(src) {
    src = $('script[src$="' + src + '"]').attr("src");
    $('script[src$="' + src + '"]').remove();
    $('<script/>').attr('src', src).appendTo('head');
}

function components_activate() {
    window.scrollTo(0, 0);
    $('#main').empty();
    sketchup.get_data('comp');
    reloadJs("cont/component_list.js");
    loadCompSections();
    document.body.style.backgroundColor = "#383838";
    $("#footer, #add_accessories, #add_attribute, #set_position_att, #panel_size")
      .css("display", "none");
}

function loadCompSections() {
    $('#Compfilter-wrap').remove();
    var CompSections = [];
    $.each(component_content.CompSections, function(key, value) {
        // вот здесь оборачиваем текст кнопки в фильтр
        let display = applyFilter(value.alias);
        CompSections.push(
            '<button id="' + value.alias +
            '" class="Comptablinks" data-name="' + value.name +
            '">' + display + '</button>'
        );
    });
    $('#CompSections').remove();
    $("<div/>", {
        id: "CompSections",
        html: CompSections.join("")
    }).appendTo("#main");
}

function loadCompVendors() {
    var comp_vendors = [];
    var curr_section = currSelection.CompSection[0] || "";
    var CompVendors = component_content.CompVendors[curr_section] || [];

    for (let i = 1; i < CompVendors.length; i++) {
        let vendorName = applyFilter(CompVendors[i]);
        comp_vendors.push(
            '<button id="' + CompVendors[i] +
            '" class="comp_vendors">' +
            (vendorName.split("/")[1] || vendorName) +
            '</button>'
        );
    }

    $("#comp_vendors-wrap").remove();
    $("<div/>", {
        id: "comp_vendors-wrap",
        html: comp_vendors.join("")
    }).appendTo("#main");

    currSelection.comp_vendor = CompVendors[0];
    showcomponents(CompVendors[0]);
}

function showcomponents(vendor) {
    $('#components-wrap').remove();
    if (!vendor) {
        vendor = currSelection.CompSection[0] || "";
    }
    var components = component_content.components[vendor] || [];
    var images = [];

    $.each(components, function(key, value) {
        if (!value) return;
        let name = value.replace(/\.[^/.]+$/, "");
        name = applyFilter(name);

        images.push(
            '<div class="components" oncontextmenu="return menu(event,\'' + name + '\');" data-name="' + value + '">' +
                '<img class="components_image" src="' + component_content.full_path_comp + '/' + vendor + '/' + value + '" title="' + name + '">' +
                name +
                '<div id="' + name + '" class="right-menu">' +
                    '<button class="delete_component" id="delete_comp_' + vendor + '/' + name + '">Удалить</button>' +
                '</div>' +
            '</div>'
        );
    });

    $("<div/>", {
        id: "components-wrap",
        html: images.join("")
    }).appendTo("#main");
}

$(document).on("mouseover", ".components_image", function(e) {});

function sendComp(index_vendor) {
    var str = "";
    var CompSection;
    if (index_vendor < 0) {
        if (event.ctrlKey || event.metaKey) {
            CompSection = "Element";
        } else {
            CompSection = currSelection.CompSection.join(', ');
        }
        var vendorId = currSelection.CompSection[0].includes("Element")
          ? $(currSelection.comp_vendor).prop('id').replace("/", "^")
          : component_content.CompVendors[currSelection.CompSection[0]][0];
        str = 'sendComp/' + CompSection + '/' + vendorId + '/' + currSelection.component;
    } else {
        if (currSelection.CompSection[0].includes("Element")) {
            CompSection = currSelection.CompSection.join(', ');
        } else if (event.ctrlKey || event.metaKey) {
            CompSection = "Element";
        } else {
            CompSection = Object.keys(component_content.CompVendors)
                .find(key => component_content.CompVendors[key] === component_content.CompVendors[currSelection.CompSection[0]]);
        }
        var vendorId2 = component_content.CompVendors[currSelection.CompSection[0]][index_vendor].replace("/", "^");
        str = 'sendComp/' + CompSection + '/' + vendorId2 + '/' + currSelection.component;
    }
    if (event.ctrlKey || event.metaKey) str += '/replace';
  sketchup.get_data(str);      // заменили компонент
  sketchup.force_redraw();     // моментально перерисовали DC
}

$(document).on("click", ".Comptablinks", function() {
    window.scrollTo(0, 0);
    $(".Comptablinks").removeClass("active");
    var name = $(this).attr('data-name');
    if ($(this).hasClass("active")) {
        $(this).removeClass("active");
        currSelection.CompSection = currSelection.CompSection.filter(item => item !== name);
    } else {
        $(this).addClass("active");
        currSelection.CompSection = [name];
        currSelection.component = void 0;
        $('#comp_vendors-wrap').remove();
        if (component_content.CompVendors[name].length === 1) {
            currSelection.comp_vendor = void 0;
            showcomponents();
        } else {
            loadCompVendors();
        }
    }
    sketchup.get_data('comp|' + component_content.full_path_comp);
});

$(document).on("click", ".comp_vendors", function() {
    window.scrollTo(0, 0);
    $(".comp_vendors").removeClass("active");
    $(this).addClass("active").blur();
    currSelection.comp_vendor = $(this).prop('id');
    currSelection.component = void 0;
    showcomponents(currSelection.comp_vendor);
});

$(document).on("click", ".components", function() {
    $('.right-menu').hide();
    $(".components").removeClass("active");
    $(this).addClass("active");
    currSelection.component = $(this).attr('data-name');
    var idx = component_content.CompVendors[currSelection.CompSection[0]].indexOf(currSelection.comp_vendor);
    sendComp(idx);
});

function menu(event, id_comp) {
    event = event || window.event;
    event.cancelBubble = true;
    $('.right-menu').hide();
    document.getElementById(id_comp).style.display = 'block';
    return false;
}

$(document).on('contextmenu click', function() {
    $('.right-menu').hide();
});

$(document).on('click', '.delete_component', function() {
    let ids = $(this).attr('id');
    sketchup.get_data(ids);
    let path = ids.slice(12).split("/");
    setTimeout(() => {
        components_activate();
        document.getElementById(path[0]).click();
        if (path.length > 2) {
            document.getElementById(path[0] + "/" + path[1]).click();
        }
    }, 200);
});

function delete_ok_image() {
    $(".components, .materials").removeClass("active");
}

  



