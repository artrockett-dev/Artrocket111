var currSelection = {
    CompSection: [],
    acc_vendor: void 0,
    component: void 0
}
var vendor;
var ctrlKey = false;

function showcomponents(vendor) { 
    $('#components-wrap').remove();
    if (!vendor) { vendor = component_content.CompVendors[currSelection.CompSection]; }
    if (vendor.length == 1) { 
        curr_vendor = document.getElementById(vendor[0]);
        $(curr_vendor).addClass("active");
        currSelection.acc_vendor = curr_vendor;
    }
    var components = component_content.components[vendor];
    var images = [];
    $.each( components, function( key, value ) {
        var name = value.substr(0, value.lastIndexOf('.'));
        images.push('<div class="components" oncontextmenu="return menu(event,'+"'"+name+"'"+');" data-name="'+value+'"><img class="components_image" src="'+component_content.full_path_comp+'/'+vendor+'/'+value+'" title="'+name+'">'+name+'<div id="'+name+'" class="right-menu"><button class="delete_component" id="delete_comp_'+vendor+'/'+name+'" >Удалить</button></div></div>' );
    })
    $( "<div/>", {
        "id": "components-wrap",
        html: images.join( "" )
    }).appendTo( "#main" )
}
document.addEventListener('keydown', function(event) {
        if (event.ctrlKey || event.metaKey) { ctrlKey = true; }
    });
function sendComp(index_vendor) {
    document.addEventListener('keydown', function(event) {
        if (event.ctrlKey || event.metaKey) { ctrlKey = true; }
    });
    alert(ctrlKey)
    if (index_vendor < 0 ) {
        CompSection = currSelection.CompSection.join(', ');
        if (currSelection.CompSection[0].indexOf("Element") != -1) { vendor = $(currSelection.acc_vendor).prop('id').replace("/","^"); } 
        else { vendor = component_content.CompVendors[currSelection.CompSection][0]; }
        } else {
        if (currSelection.CompSection[0].indexOf("Element") != -1) { CompSection = currSelection.CompSection.join(', '); } 
        else {
            if (ctrlKey == true) { CompSection = "Element"; }
            else { CompSection = component_content.CompVendors[currSelection.CompSection][index_vendor].split("/")[1]; }
        }
        vendor = component_content.CompVendors[currSelection.CompSection][index_vendor].replace("/","^");
    }
    var str = 'sendComp/' + CompSection + '/' + vendor + '/' + currSelection.component;
    sketchup.get_data(str);
    ctrlKey = false;
}

$(document).on( "click", ".components_image", function() {
    $('.right-menu').hide();
    let this_component = this.parentNode;
    $(".components").each(function () {
        $(this).removeClass("active");
    });
    $(this_component).addClass("active");
    currSelection.component = $(this_component).attr('data-name');
    index_vendor = component_content.CompVendors[currSelection.CompSection].indexOf(currSelection.acc_vendor);
    sendComp(index_vendor);
});
function menu(event,id_comp) {
	event = event || window.event;
	event.cancelBubble = true;
    $('.right-menu').hide();
    document.getElementById(id_comp).style.display = 'block';
	return false;
}
$(document).on('contextmenu', function(){
	$('.right-menu').hide();
});
$(document).on('click', function(){
	$('.right-menu').hide();
});
$(document).on('click', '.delete_component', function(){
	let ids = $(this).attr('id');
    sketchup.get_data(ids);
    let path = ids.slice(12).split("/");
    setTimeout(
        () => {
            components_activate();
            document.getElementById(path[0]).click();
            if (path.length > 2) { document.getElementById(path[0]+"/"+path[1]).click(); }
        }, 200 );  
});

