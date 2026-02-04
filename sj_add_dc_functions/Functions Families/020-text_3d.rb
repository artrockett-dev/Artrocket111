require 'sj_add_dc_functions/functions_family'
require 'sj_add_dc_functions/function'
require 'sj_add_dc_functions/functions_families'
require 'sketchup'
require 'su_dynamiccomponents'

# DOCUMENTATION DE CETTE FAMILLE DE FONCTIONS.

# Espace de noms de l'auteur.
module SimJoubert
  # Espace de noms du plugin.
  module AddDCFunctions
    functions_family = FunctionsFamily.new('020-text_3d')
    functions_family.title = '3D text functions'
    functions_family.author = 'Simon Joubert'

    function = Function.new('Create3dText', functions_family)
    function.add_parameter('newComponentName', 'Name of the text subcomponent that will be created.')
    function.add_parameter('text', 'The text that will be modeled.')
    function.description = 'Create an editable 3D text sub-component, and the attributes to configure its editing. <br> , text, line break character, font, alignment, italics, bold, fill, extrusion height, offset ... <br> , and a calculation attribute to recreate the geometry. <br> , <strong> The function must be called by an attribute named txt_ini </strong>'
    functions_family.add_function(function)

    function = Function.new('Edit3dText', functions_family)
    function.add_parameter('text', 'The text that will be modeled.')
    function.add_parameter('lineBreak', 'Replacement character for line breaks.')
    function.add_parameter('align', 'left = 0, center = 1, right = 2')
    function.add_parameter('font', 'Writing font')
    function.add_parameter('bold', 'yes = 1, no = 0')
    function.add_parameter('italic', 'yes = 1, no = 0')
    function.add_parameter('height', 'Character height.')
    function.add_parameter('tolerance', 'Curve rounding tolerance 0.1 mm')
    function.add_parameter('zOffset', 'Offset the text on its Z axis.')
    function.add_parameter('filled', 'Outline only (no extrusion) = 0, Fill with outline = 1, Fill without outline = 2')
    function.add_parameter('extrusion', 'Text extrusion height in centimeters, only if filled > 0')
    function.add_parameter('actualize', 'Edit the text if update = 1, otherwise return unedited text')
    function.add_parameter('xOffset', 'Offset the text on its X axis.')
    function.add_parameter('yOffset', 'Offset the text on its Y axis.')
    function.description = 'Function to edit 3D text.'
    functions_family.add_function(function)

    # TODO: Aliaser CreateFond3dText en Create3dTextBackground ?
    function = Function.new('CreateFond3dText', functions_family)
    function.description = 'Create a background sub component for the 3d text created with Create3dText. <br>Create additional attributes to manage the margins and visibility of the background and its thickness.'
    functions_family.add_function(function)

    FunctionsFamilies.add_family(functions_family)
  end
end

# IMPLEMENTATION DE CETTE FAMILLE DE FONCTIONS.

if defined?($dc_observers)
    # Open SketchUp's Dynamic Component Functions (V1) class.
    # BUT only if DC extension is active...
    class DCFunctionsV1
        protected
        
        #_____________________________________________________________________________________________________________________________
        ##### FONCTIONS TEXTE 3D####
        #_____________________________________________________________________________________________________________________________
        
        #--------------------------------------------
        # FONCTION CREATE3DTEXT
        #--------------------------------------------
            # Creation d'un sous composant texte 3d depuis le composant  
            # # DC Function Usage: =create3dText(nom du composant,texte)
            if not DCFunctionsV1.method_defined?(:create3dtext)
                def create3dtext(a)
                    # Récupérations des paramètres
                    nom_def = a[0].to_s
                    text = a[1].to_s.gsub(/%20/," ")
                    
        
                    # Initialisation des valeurs par défault
                    align = 1
                    font = "Arial"
                    bold = false
                    italic = false
                    height = 10.cm
                    height_s = (10/2.54)
                    tol = 0.1.mm
                    tol_s = (0.01/2.54)
                    z = 0.cm                
                    z_s = 0
                    filled = true
                    extrusion = 2.cm
                    extrusion_s = (2/2.54)
                    
                    model = Sketchup.active_model
                    model.start_operation("creation Texte DC", true,false,false)
                    dcdict = "dynamic_attributes"
        
                    #Definition d'une methode qui creer un attribut en luis tranmetant un hash ,l'objet et le dictionnaire
                    def definir_attribut(atr,obj,dictionary)
                        name = atr["name"]
                        value = atr["value"]
                        meta = atr["meta"]
                    
                        if name == ""
                            return
                        end
                        obj.set_attribute(dictionary,name,value)
                        unless meta == {}
                            meta_keys =meta.keys
                            meta_keys.each do |k|
                                if atr[k] != ""
                                    obj.set_attribute( dictionary , "_" + name + "_" + k , meta[k] )
                                end
                            end
                        end
                    
                    end
        
                    source_def = @source_entity.definition
                    source_def.name = nom_def
                    #Attribut _name qui sert pour les liaisons de calcul
                    source_def.set_attribute(dcdict,"_name","Control_3dTxtDC")
                    @source_entity.set_attribute(dcdict,"_name","Control_3dTxtDC")
                    source_def.description = SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Editable Dynamic 3D Text component. Please note this component uses calculation functions not native to Sketchup! It requires the installation of the sj_AddDCFunctions plugin!")
        
                    source_ents = source_def.entities
        
                    # # Création du sous composant vide
                    group_text = source_ents.add_group
                    inst_text = group_text.to_component
                    compo_text = inst_text.definition
                    compo_text.name = nom_def+"_Text_3dTxtDC"
                    compo_text.description = "DC3dtext"
                    compo_text.set_attribute(dcdict,"_lengthunits","CENTIMETERS")
        
                    # # Création du texte 3d dans un groupe
                    compo_ents = compo_text.entities
        
                    group_text_new = compo_ents.add_group()
                    group_text_new_ents = group_text_new.entities
                    group_text_new_ents.add_3d_text(text,align,font,bold,italic,height,tol,z,filled,extrusion)
        
        
        
                    # On place le texte à l'origine du sous composant Texte
                    pt=Geom::Point3d.new(0,0,0)
                    t=Geom::Transformation.new(pt)         
                    group_text_new.move!(t)
        
                    # On explose le groupe texte
                    group_text_new.explode
        
                    # On reset l'échelle du Souc composant pour éviter les déformations
                    def reset_scale_a(obj)
                        tr_matrix = obj.transformation.to_a
                        xscale = tr_matrix[0]
                        yscale = tr_matrix[5]
                        zscale = tr_matrix[10]
                        tr_reset_scale = Geom::Transformation.scaling(1.0/xscale, 1.0/yscale, 1.0/zscale)
                        obj.transform!(tr_reset_scale)
                    end
        
                    reset_scale_a(inst_text)
        
                    # On recupère la largeur et la longueur de la boundingbox du texte
                    txt_bounds = inst_text.bounds
                    txt_lenx = txt_bounds.width
                    txt_leny = txt_bounds.height
        
                                  
        
                    #Le reset scale du composant est inactif car il est réalisé depuis l'intérieur du composant
                    reset_scale_a(@source_entity)
        
                                   
                    ###############################################################
                    # CREATION DES ATTRIBUTS POUR LE COMPOSANT
                    ###############################################################
                    # Ajout d'une description
                    atr = {
                        "name" => "description",
                        "value" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("<p><b>Dynamic 3D Text Component</b><br>Set text formatting options. Apply!<br>If Refresh = NO, settings changes will not be applied.<br>You can make multiline text by inserting in the text the character selected in the line break character option.</p><p><b><i><font color=\"red\">Warning this component uses functions non-native calculation tools of Sketchup!!!<br>It requires the installation of the plugin sj_AddDCFunctions!</font></i></b></p>"),
                        "meta" => {}
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    # Creation de l'attribut font
                    #liste des polices vous pouvez ajoutez ou supprimer
                    font_array = ["Arial","Arial Black","Arial Narrow","Bookman Old Style","Bradley Hand ITC","Century","Century Gothic","CityBlueprint","Corbel","Comic Sans MS","Courier New","Eurostile","Garamond","Georgia","Impact","Lucida Console","Monotxt","Monotype Corsiva","Papyrus","Rockwell","RomanT","Romantic","SansSerif","Simplex","Stylus BT","Symbol","Tahoma","Technic","Times New Roman","Trebuchet MS","Verdana","Vineta BT","Vrinda","Webdings","Wingdings","Wingdings 2","Wingdings 3"]
                    
                    font_option = "&"+font_array.map {|val| val+"="+val}.join("&")+"&"
                    atr = {
                        "name" => "txt_01_font",
                        "value" => "Arial",
                        "meta" => {
                            "label" => "txt_01_font",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Font"),
                            "access" => "LIST",
                            "options" => font_option
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut alignement
                    atr = {
                        "name" => "txt_02_align",
                        "value" => 0,
                        "meta" => {
                            "label" => "txt_02_align",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Alignment"),
                            "access" => "LIST",
                            "options" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("&Left=0&Center=1&Right=2&")
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut italic
                    atr = {
                        "name" => "txt_03_italic",
                        "value" => 0,
                        "meta" => {
                            "label" => "txt_03_italic",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Italic"),
                            "access" => "LIST",
                            "options" => "&Non=0&Oui=1&"
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut bold
                    atr = {
                        "name" => "txt_04_bold",
                        "value" => 0,
                        "meta" => {
                            "label" => "txt_04_bold",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Bold"),
                            "access" => "LIST",
                            "options" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("&Non=0&Oui=1&")
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut color
                    atr = {
                        "name" => "txt_05_color",
                        "value" => "default",
                        "meta" => {
                            "label" => "txt_05_color",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Text Color"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut height
                    atr = {
                        "name" => "txt_06_height",
                        "value" => height_s,
                        "meta" => {
                            "label" => "txt_06_height",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Character height"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut filled
                    atr = {
                        "name" => "txt_07_filled",
                        "value" => 1,
                        "meta" => {
                            "label" => "txt_07_filled",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Text fill"),
                            "access" => "LIST",
                            "options" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("&Outline only (no extrusion)=0&Fill with outline=1&Fill without outline=2&")
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut extrusion
                    atr = {
                        "name" => "txt_08_extrusion",
                        "value" => extrusion_s,
                        "meta" => {
                            "label" => "txt_08_extrusion",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Extrude height"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut decallage en z
                    atr = {
                        "name" => "txt_09_zoffset",
                        "value" => z_s,
                        "meta" => {
                            "label" => "txt_09_zoffset",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Z-axis offset"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut tolerance arrondi 0.1mm
                    atr = {
                        "name" => "txt_10_tol",
                        "value" => tol_s,
                        "meta" => {
                            "label" => "txt_10_tol",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "MILLIMETERS",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Rounding tolerance"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut fondmarge
                    atr = {
                            "name" => "txt_13_fondmarged",
                            "value" => 0,
                            "meta" => {
                                "label" => "txt_13_fondmarged",
                                "formulaunits" => "CENTIMETERS",
                                "units" => "CENTIMETERS",
                                "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Right margin"),
                                "access" => "TEXTBOX",
                            }
                        }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut fondmarge
                    atr = {
                            "name" => "txt_13_fondmargeh",
                            "value" => 0,
                            "meta" => {
                                "label" => "txt_13_fondmargeh",
                                "formulaunits" => "CENTIMETERS",
                                "units" => "CENTIMETERS",
                                "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Top Margin"),
                                "access" => "TEXTBOX",
                            }
                        }
                    definir_attribut(atr,source_def,dcdict)
                    #Creation de l'attribut fondmarge
                    atr = {
                            "name" => "txt_13_fondmargeb",
                            "value" => 0,
                            "meta" => {
                                "label" => "txt_13_fondmargeb",
                                "formulaunits" => "CENTIMETERS",
                                "units" => "CENTIMETERS",
                                "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Bottom margin"),
                                "access" => "TEXTBOX",
                            }
                        }
                    definir_attribut(atr,source_def,dcdict)
                    #Creation de l'attribut fondmarge
                    atr = {
                            "name" => "txt_13_fondmargeg",
                            "value" => 0,
                            "meta" => {
                                "label" => "txt_13_fondmargeg",
                                "formulaunits" => "CENTIMETERS",
                                "units" => "CENTIMETERS",
                                "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Left margin"),
                                "access" => "TEXTBOX",
                            }
                        }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut texte de remplacement saut de ligne
                    atr = {
                        "name" => "txt_14_linebreak",
                        "value" => "$",
                        "meta" => {
                            "label" => "txt_14_linebreak",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Line break character(s)"),
                            "access" => "LIST",
                            "options" => "&$=$&£=£&µ=µ&"
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut texte
                    atr = {
                        "name" => "txt_15_texte",
                        "value" => text,
                        "meta" => {
                            "label" => "txt_15_texte",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Text"),
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut actualiser
                    atr = {
                        "name" => "txt_16_actualiser",
                        "value" => 0,
                        "meta" => {
                            "label" => "txt_16_actualiser",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Actualiser"),
                            "access" => "LIST",
                            "options" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("&No=0&Yes=1&")
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut edition
                    atr = {
                        "name" => "txt_17_edit",
                        "value" => "Texte non edité",
                        "meta" => {
                            "label" => "txt_17_edit",
                            "formula" => "EDIT3DTEXT( txt_15_texte , txt_14_linebreak , txt_02_align , txt_01_font , txt_04_bold , txt_03_italic , txt_06_height , txt_10_tol , txt_09_zoffset , txt_07_filled , txt_08_extrusion , txt_16_actualiser , txt_13_fondmargeg,txt_13_fondmargeb)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Editing"),
                            "access" => "VIEW",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut defname
                    atr = {
                        "name" => "txt_18_defname",
                        "value" => nom_def,
                        "meta" => {
                            "label" => "txt_18_defname",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Definition Name"),
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut setdef
                    atr = {
                        "name" => "txt_19_setdef",
                        "value" => nom_def,
                        "meta" => {
                            "label" => "txt_19_setdef",
                            "formula" => "setnamedefinition(txt_18_defname)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Nom définition (Calcul)",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut defnametxt nom de définition du sous composant texte
                    atr = {
                        "name" => "txt_20_deftxt",
                        "value" => nom_def +"_3dTxtDC",
                        "meta" => {
                            "label" => "txt_20_deftxt",
                            "formula" => "txt_18_defname&\"_Text_3dTxtDC\"",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Nom définition du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
        
        
                    ###############################################################
                    # CREATION DES ATTRIBUTS POUR LE SOUS COMPOSANT TEXTE
                    ###############################################################
                    
                    text_def = inst_text.definition
                    
                    #Attribut _name qui sert pour les liaisons de calcul
                    text_def.set_attribute(dcdict,"_name","Text_3dTxtDC")
                    atr = {
                        "name" => "defname",
                        "value" => nom_def +"_3dTxtDC",
                        "meta" => {
                            "label" => "defname",
                            "formula" => "setnamedefinition(parent!txt_20_deftxt)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Nom de la deffinition",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,text_def,dcdict)
        
                    #Creation de l'attribut longueur du texte
                    atr = {
                        "name" => "lenx",
                        "value" => txt_lenx,
                        "meta" => {
                            "label" => "LenX",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Longueur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,text_def,dcdict)
        
                    #Creation de l'attribut largeur du texte
                    atr = {
                        "name" => "leny",
                        "value" => txt_leny,
                        "meta" => {
                            "label" => "LenY",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Largeur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,text_def,dcdict)
        
                    #Création de l'attribut color appolique la couleur dur les faces et non sur l'envelloppe du composant
                    atr = {
                        "name" => "color",
                        "value" => "Default",
                        "meta" => {
                            "label" => "color",
                            "formula" => "SetMaterialFrontFaces(parent!txt_05_color)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "couleur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,text_def,dcdict)
        
                    # status = model.commit_operation
                    # if status == true
                        #On supprime la formule rentrée dans txt_ini qui a appellé la création des attributs
                        @source_entity.definition.delete_attribute(dcdict,"_txt_ini_formula")
                        @source_entity.delete_attribute(dcdict,"_txt_ini_formula")
                        result = SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Text attributes created")
                        #dc = $dc_observers.get_latest_class
                        #dc.redraw_with_undo(@source_entity)
                    # else
                    #    result = "Erreur dans la cration du sous composant texte"
                    # end
                    message_dialogue1 = "Le composant a été renommé en #{nom_def}\nUn sous composant #{nom_def +"_3dTxtDC"} a été créer.\n\nParamétrez le texte et son style avec le panneau d'option du composant.\nPour appliquer les modififications => Actualiser = Oui.\n\nLa formule de création du texte a été supprimée.\nVous pouvez ajouttez un fond dynamique\navec la fonction CreateFond3dText()"
                    dialogue1 = UI.messagebox(message_dialogue1, MB_OK,MB_MULTILINE)
                    return result
                    
                end
            end
        
        #--------------------------------------------
        # FONCTION CREATEFOND3DTEXT
        #--------------------------------------------
            # Création d'un fond pour un composant texte 3d  
            # # DC Function Usage: =createfond3dText()    
            if not DCFunctionsV1.method_defined?(:createfond3dtext)
                def createfond3dtext(a)
        
                    ###############################################################
                    ### INITIALISATION DES VARIABLES
                    ###############################################################
                    model = Sketchup.active_model
                    model.start_operation("creation Fond Texte DC", true,false,false)
        
                    dcdict = "dynamic_attributes"
        
                    source_def = @source_entity.definition
                    nom_def = source_def.name
                    source_ents = source_def.entities
                    epaisseur = 1.cm
                    epaisseur_txt = epaisseur.to_f*2.54
        
                    
        
        
                    ###############################################################
                    ### MODELISATION DU FOND
                    ###############################################################
                    # On recupère l'instance du texte
                    text = source_ents.find {|e| e.typename == "ComponentInstance" && e.description == "DC3dtext"}
                    text_def = text.definition
                    
                    # On recupère la largeur et la longueur de la boundingbox du texte
                    txt_bounds = text.bounds
                    txt_lenx = txt_bounds.width
                    txt_leny = txt_bounds.height
        
                    # On récupère la valeur de l'attribut marge
                    marge_d = source_def.get_attribute( dcdict, "txt_13_fondmarged",0).to_l
                    marge_g = source_def.get_attribute( dcdict, "txt_13_fondmargeg",0).to_l
                    marge_h = source_def.get_attribute( dcdict, "txt_13_fondmargeh",0).to_l
                    marge_b = source_def.get_attribute( dcdict, "txt_13_fondmargeb",0).to_l
        
                    fond_lenx = txt_lenx + marge_d + marge_g
                    fond_leny = txt_leny + marge_h + marge_b
                    
                    # On créer un array de points 3d angles du fond
                    pts = []
                    pts[0] = Geom::Point3d.new(0,0,0)
                    pts[1] = Geom::Point3d.new(fond_lenx,0,0)
                    pts[2] = Geom::Point3d.new(fond_lenx,fond_leny,0)
                    pts[3] = Geom::Point3d.new(0,fond_leny,0)
        
                    # on créer le sous composant fond vide
                    fond = source_ents.add_group
                    fond = fond.to_component
                    fond.definition.name = nom_def + "_Fond_3dTxtDC"
                    fond.definition.set_attribute(dcdict,"_lengthunits","CENTIMETERS")
        
                    # On créer la face puis un pushpull
                    fond_ents = fond.definition.entities
                    face = fond_ents.add_face(pts)
                    status = face.reverse!
                    status = face.pushpull(epaisseur, true)
        
                    # On place le fond à l'origine du sous composant Texte
        
                    pt=Geom::Point3d.new(0,0,0)
                    t=Geom::Transformation.new(pt)        
                    fond.move!(t)
                
                    
                    ###############################################################
                    ### DEFINITION METHODE DEFINIR ATTRIBUT DEPUIS HASH ATR
                    ###############################################################
                    def definir_attribut(atr,obj,dictionary)
                        name = atr["name"]
                        value = atr["value"]
                        meta = atr["meta"]
                    
                        if name == ""
                            return
                        end
                        obj.set_attribute(dictionary,name,value)
                      
                        meta_keys =meta.keys
                        meta_keys.each do |k|
                            if atr[k] != ""
                                obj.set_attribute( dictionary , "_" + name + "_" + k , meta[k] )
                            end
                        end
                    
                    end
                    ###############################################################
                    ### AJOUT ATTRIBUTS AU COMPOSANT
                    ###############################################################
        
                    # Creation de l'attribut fond
                    atr = {
                        "name" => "txt_11_fond",
                        "value" => 2,
                        "meta" => {
                            "label" => "txt_11_fond",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "affichage du fond",
                            "access" => "LIST",
                            "options" => "&Sans fond(masqué)=1&Fond et contour=2&fond sans contour=3&Contour sans fond=4&"
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    # Creation de l'attribut fondcolor
                    atr = {
                        "name" => "txt_12_fondcolor",
                        "value" => "default",
                        "meta" => {
                            "label" => "txt_12_fondcolor",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Couleur du fond",
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    # Creation de l'attribut fondepaisseur
                    atr = {
                        "name" => "txt_12_fondepaisseur",
                        "value" => epaisseur_txt,
                        "meta" => {
                            "label" => "txt_12_fondepaisseur",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Epaisseur du fond",
                            "access" => "TEXTBOX",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut deffond nom de définition du sous composant fond
                    atr = {
                        "name" => "txt_21_deffond",
                        "value" => nom_def +"_Fond3dTxtDC",
                        "meta" => {
                            "label" => "txt_21_deffond",
                            "formula" => "txt_18_defname&\"_Fond_3dTxtDC\"",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Nom définition du fond",
                            "access" => "NONE",
                            "options" => ""
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut longueur du texte
                    atr = {
                        "name" => "txt_22_txtlenx",
                        "value" => txt_lenx,
                        "meta" => {
                            "label" => "txt_22_txtlenx",
                            "formula" => "Text_3dTxtDC!LenX",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Longueur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
        
                    #Creation de l'attribut largeur du texte
                    atr = {
                        "name" => "txt_23_txtleny",
                        "value" => txt_leny,
                        "meta" => {
                            "label" => "txt_23_txtleny",
                            "formula" => "Text_3dTxtDC!LenY",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Largeur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,source_def,dcdict)
                    
        
                    ###############################################################
                    ### ATTRIBUTS POUR LE SOUS COMPOSANT FOND
                    ###############################################################
                   
        
                    fond_def = fond.definition
                    
                    #Attribut _name qui sert pour les liaisons de calcul
                    fond_def.set_attribute(dcdict,"_name","Fond_3dTxtDC")
        
                    atr = {
                        "name" => "defname",
                        "value" => nom_def +"_3dTxtDC",
                        "meta" => {
                            "label" => "defname",
                            "formula" => "setnamedefinition(parent!txt_21_deffond)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Nom de la deffinition",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Creation de l'attribut longueur fond
                    atr = {
                        "name" => "lenx",
                        "value" => txt_lenx,
                        "meta" => {
                            "label" => "LenX",
                            "formula" => "parent!txt_13_fondmarged+parent!txt_13_fondmargeg+Text_3dTxtDC!LenX",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Longueur du fond",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Creation de l'attribut largeur fond
                    atr = {
                        "name" => "leny",
                        "value" => txt_leny,
                        "meta" => {
                            "label" => "LenY",
                            "formula" => "parent!txt_13_fondmargeh+parent!txt_13_fondmargeb+Text_3dTxtDC!LenY",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Largeur du fond",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Creation de l'attribut epaisseur fond
                    atr = {
                        "name" => "lenz",
                        "value" => epaisseur_txt,
                        "meta" => {
                            "label" => "LenZ",
                            "formula" => "Control_3dTxtDC!txt_12_fondepaisseur",
                            "formulaunits" => "CENTIMETERS",
                            "units" => "CENTIMETERS",
                            "formlabel" => "Epaisseur du fond",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Création de l'attribut color appolique la couleur sur les faces et non sur l'envelloppe du composant
                    atr = {
                        "name" => "color",
                        "value" => "Default",
                        "meta" => {
                            "label" => "color",
                            "formula" => "SetMaterialFaces(parent!txt_12_fondcolor,parent!txt_12_fondcolor)",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "couleur du texte",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Creation de l'attribut hidden arrêttes
                    atr = {
                        "name" => "edges_hidden",
                        "value" => 0,
                        "meta" => {
                            "label" => "edges_hidden",
                            "formula" => "sethiddenedgess(CHOOSE(parent!txt_11_fond,1,0,1,0))",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Contour visible",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #Creation de l'attribut hidden arrêttes
                    atr = {
                        "name" => "faces_hidden",
                        "value" => 0,
                        "meta" => {
                            "label" => "faces_hidden",
                            "formula" => "sethiddenfaces(CHOOSE(parent!txt_11_fond,1,0,0,1))",
                            "formulaunits" => "STRING",
                            "units" => "STRING",
                            "formlabel" => "Faces visibles",
                            "access" => "NONE",
                        }
                    }
                    definir_attribut(atr,fond_def,dcdict)
        
                    #On supprime la formule rentrée dans txt_ini qui a appellé la création des attributs
                    source_def.delete_attribute(dcdict,"_txt_ini_formula")
                    @source_entity.delete_attribute(dcdict,"_txt_ini_formula")
        
                    #dc = $dc_observers.get_latest_class
                    #dc.redraw_with_undo(@source_entity)
     
     
                    return SimJoubert::AddDCFunctions::FunctionsFamilies.family('020-text_3d').translate("Background attributes created")
                        
                    
        
                end
            end
            
        
        
        #--------------------------------------------
        # FONCTION EDIT3DTEXT
        #--------------------------------------------
            # Modification d'un composant texte 3d    
            # # DC Function Usage: =edit3dText("actualiser")        
            if not DCFunctionsV1.method_defined?(:edit3dtext)
                def edit3dtext(a)
                    # Récupérations des paramètres
                    text_s = a[0].to_s
                    linebreak = a[1].to_s
                    align = a[2].to_i
                    font = a[3].to_s
                    bold = a[4].to_i
                    italic = a[5].to_i
                    height = a[6].to_f.cm
                    tol = a[7].to_f.cm
                    z = a[8].to_f.cm
                    filled = a[9].to_i
                    extrusion = a[10].to_f.cm
                    actualiser = a[11].to_i
                    marge_g = a[12].to_f.cm
                    marge_b = a[13].to_f.cm
                    
                    filled_edge = true
        
                    if actualiser == 0
                        return " Texte non édité"
                    end
                    
        
                    # Initialisation des valeurs et gestion des erreurs
                    dcdict = "dynamic_attributes"
                    source_def = @source_entity.definition
                    model = Sketchup.active_model
                    model.start_operation("Modification Texte DC", true,false,false)
        
                    if text_s == ""
                        return "Aucun texte saisie"
                    end
        
                    if linebreak == ""
                        return "Manque caractères simulant les sauts de ligne"
                    end
        
                    
                    
        
                    if font == ""
                        return "Aucune police définie"
                    end
        
                    if bold == 1
                        bold = true
                    else
                        bold = false
                    end
        
                    if italic == 1
                        italic = true
                    else
                        italic = false
                    end
        
                    if filled == 0
                        filled = false
                        extrusion = 0.cm
                    elsif filled == 1
                        filled = true
                    elsif filled == 2
                        filled = true
                        filled_edge = false
                    end
                    
        
                    # Remplacement ds sauts de ligne
                    text = text_s.strip+"                                      "#64 espaces
                    text = text.strip.gsub(linebreak,"\n")### removes trailing/leading spaces
                    
                    source_transformation = @source_entity.transformation
                    source_origine = source_transformation.origin
        
                    source_ents = source_def.entities
        
                    
                    #On recherche le sous composant Texte
                    compo_text = source_ents.find {|e| e.typename == "ComponentInstance" && e.description == "DC3dtext"}
                    
                    model = Sketchup.active_model
                    model.start_operation("Edition du texte",true,false,false)
                    #On efface les entités à l'interieur
                    compo_ents = compo_text.definition.entities
                    xents = compo_ents.to_a 
                    xents.each{|e|e.erase! if e.valid?}
        
                    # Création du texte 3d
     
                    group_text_new = compo_ents.add_group()
                    group_text_new_ents = group_text_new.entities
                    group_text_new_ents.add_3d_text(text,align,font,bold,italic,height,tol,z,filled,extrusion)
        
                    if filled_edge == false
                        edges = group_text_new_ents.grep(Sketchup::Edge)
                        edges.each do |edge|
                            if edge.valid?
                                edge.hidden = true
                            end
                        end
                    end
        
     
                    #on place le nouveau groupe texte à l'origine du sous composant texte
                    compo_text_transformation = compo_text.transformation
                    compo_text_origine = compo_text_transformation.origin
        
                    pt=Geom::Point3d.new( marge_g , marge_b , 0 )            
                    t=Geom::Transformation.new(pt)
                    
                    group_text_new.move!(t)
                  
                    #On explose le groupe texte
                    group_text_new.explode
        
                    #On reset l'echelle du sous composant texte
                    def reset_scale_a(obj)
                        tr_matrix = obj.transformation.to_a
                        xscale = tr_matrix[0]
                        yscale = tr_matrix[5]
                        zscale = tr_matrix[10]
                        tr_reset_scale = Geom::Transformation.scaling(1.0/xscale, 1.0/yscale, 1.0/zscale)
                        obj.transform!(tr_reset_scale)
                    end
                    reset_scale_a(compo_text)
        
                    #On reset l'echelle du composant mais ne fonctionne pas car on est dans le composant et non à l'exterieur
                    reset_scale_a(@source_entity)
        
                    return text_s
                    
        
                end
            end
        
    end # class
end # if
