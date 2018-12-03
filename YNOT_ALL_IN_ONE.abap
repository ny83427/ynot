*&---------------------------------------------------------------------*
*& Report YNOT_ALL_IN_ONE built as all-in-one program at 20130620 143241
*& Author: Joker @ SAP Labs China FGI
*&---------------------------------------------------------------------*
*& Function Description:
*& This report will collect objects data from several released transport
*&  request and generate a documentation for note pre-implementation.
*& Those objects cannot be shipped via note automatically need to be
*&  maintained by customer according to instruction step by step, and this
*&  tool aims to reduce the effort of writing instruction documentation.
*&---------------------------------------------------------------------*
*& Supported Object Types(Total: 33):
*& -  DEVC : Package
*& -  DEVP : Package: Usage
*& -  PINF : Package: Interface
*& -  FUGR/FUGT : Function Group (Texts)
*& -  DOMA/DOMD : Domain (Definition)
*& -  DTEL/DTED : Data Element (Definition)
*& -  TABL/TABD/TABT/INDX : Table (Definition/Technical Setting/Index)
*& -  VIEW/VIED/VIET : View (Definition / Technical Attributes)
*& -  VCLS : View cluster
*& -  TOBJ : Definition of a Maintenance and Transport Object
*& -  SHLP/SHLD : Search Help (Definition)
*& -  ENQU/ENQD : Lock Object (Definition)
*& -  TTYP/TTYD : Table Type (Definition)
*& -  NROB : Number Range Objects
*& -  DOCU : Documentation(TODO: DOCT/DOCV)
*& -  MSAD/MSAG : Message Class (Definition and All Short Texts)
*& -  MESS : Single Message
*& -  TRAN : Transaction
*& -  CDAT : View Cluster Maintenance Data
*& -  VDAT : View Maintenance Data
*& -  TABU : Table Contents
*&---------------------------------------------------------------------*
*& Limitations(including but not limited to):
*&  1.Generated File is html which is word compatible, but the auto list
*&    item adjustment(and maybe some other features also) is missing
*&  2.Only English and German are available
*&  3.Cannot detect delta change mode for all objects, however we can add
*&    objects into excluded list as a workaround.
*&---------------------------------------------------------------------*
*& Report Message:
*&  This tool as a infant is not robust and might result in new troubules,
*&    any feedback is of great help to let it grows up and becomes strong.
*&  So if you find any issue when you use this tool, please kindly write
*&    email to joker.yang@sap.corp, I will try to fix them ASAP.
*&---------------------------------------------------------------------*
*& Inspiration From & Thanks To:
*&  1.Z_METH_ABAP_TECH_DOCU,  Author: SAP Custom Development
*&  2.ZSAPLINK, http://saplink.org
*&---------------------------------------------------------------------*
REPORT YNOT_ALL_IN_ONE.
*&----------------Types/Constants/Global Data Declarations-------------*
*&---------------------Types Definition: utility types-----------------*
TYPE-POOLS: icon, trwbo.
TYPES: BEGIN OF s_objtype_order,
       object          TYPE trobjtype,
       sort_no         TYPE i,
       show_basic_attr TYPE abap_bool,
       END OF s_objtype_order.
TYPES: ht_objtype_order TYPE HASHED TABLE OF s_objtype_order WITH UNIQUE KEY object.

TYPES: BEGIN OF s_object_instruction,
       object      TYPE trobjtype,
       instruction TYPE string,
       END OF s_object_instruction.
TYPES: ht_object_instruction TYPE HASHED TABLE OF s_object_instruction WITH UNIQUE KEY object.

TYPES: BEGIN OF s_lintype,
       line(1024) TYPE x,
       END OF s_lintype.
TYPES: t_linetype TYPE STANDARD TABLE OF s_lintype WITH DEFAULT KEY.
TYPES: t_string TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

TYPES: BEGIN OF s_obj_header,
       pgmid          TYPE  pgmid,
       object         TYPE trobjtype,
       obj_name	      TYPE sobj_name,
       primary_sort   TYPE i,
       secondary_sort TYPE numc2,
       devclass       TYPE devclass,
       short_text     TYPE ddtext,
       screenshots    TYPE int1,
       activity       TYPE char6,
       END OF s_obj_header.

TYPES: BEGIN OF s_value_desc,
       fieldname   TYPE fieldname,
       ddfixvalues TYPE ddfixvalues,
       END OF s_value_desc.

TYPES: BEGIN OF s_common_msg,
       msgty TYPE sy-msgty,
       msg TYPE string,
       END OF s_common_msg.

TYPES: BEGIN OF s_obj_gen_msg.
        INCLUDE TYPE s_obj_header.
        INCLUDE TYPE s_common_msg.
TYPES: END OF s_obj_gen_msg.
*&--Types for supported kinds of objects, Naming Convention: s_{objtype}--*
TYPES: t_package_interface TYPE TABLE OF vintf WITH DEFAULT KEY.
TYPES: BEGIN OF s_devc.
        INCLUDE TYPE s_obj_header.
TYPES: parentcl               TYPE parentcl.
TYPES: pdevclass              TYPE devlayer.
TYPES: component              TYPE uffctr.
TYPES: dlvunit                TYPE dlvunit.
TYPES: applicat               TYPE trdevcappl.
TYPES: ufps_posid             TYPE ufps_posid.
TYPES: mainpack               TYPE mainpack.
TYPES: korrflag               TYPE korrflag.
TYPES: project_id             TYPE pak_project_id.
TYPES: translation_relevance  TYPE c LENGTH 60.
TYPES: use_accesses           TYPE permis_tab.
TYPES: interfaces             TYPE t_package_interface.
TYPES: END OF s_devc.

TYPES: BEGIN OF s_devp.
        INCLUDE TYPE s_devc.
TYPES: END OF s_devp.

TYPES: BEGIN OF s_pinf.
        INCLUDE TYPE s_obj_header.
        INCLUDE STRUCTURE vintf.
TYPES: END OF s_pinf.

TYPES: BEGIN OF s_fugr.
        INCLUDE TYPE s_obj_header.
TYPES: END OF s_fugr.

TYPES: BEGIN OF s_fugt.
        INCLUDE TYPE s_fugr.
TYPES: END OF s_fugt.

TYPES: t_dd07v TYPE STANDARD TABLE OF dd07v WITH DEFAULT KEY.
TYPES: BEGIN OF s_doma.
        INCLUDE TYPE s_obj_header.
TYPES: datatype    TYPE datatype_d.
TYPES: leng        TYPE ddleng.
TYPES: outputlen   TYPE outputlen.
TYPES: decimals    TYPE decimals.
TYPES: lowercase   TYPE lowercase.
TYPES: signflag    TYPE signflag.
TYPES: valexi      TYPE valexi.
TYPES: entitytab   TYPE entitytab.
TYPES: value_range TYPE t_dd07v.
TYPES: END OF s_doma.

TYPES: BEGIN OF s_domd.
        INCLUDE TYPE s_doma.
TYPES: END OF s_domd.

TYPES: BEGIN OF s_dtel.
        INCLUDE TYPE s_obj_header.
TYPES: domname   TYPE domname.
TYPES: headlen   TYPE headlen.
TYPES: scrlen1   TYPE scrlen_s.
TYPES: scrlen2   TYPE scrlen_m.
TYPES: scrlen3   TYPE scrlen_l.
TYPES: reptext   TYPE reptext.
TYPES: scrtext_s TYPE scrtext_s.
TYPES: scrtext_m TYPE scrtext_m.
TYPES: scrtext_l TYPE scrtext_l.
TYPES: datatype  TYPE datatype_d.
TYPES: leng      TYPE ddleng.
TYPES: END OF s_dtel.

TYPES: BEGIN OF s_dted.
        INCLUDE TYPE s_dtel.
TYPES: END OF s_dted.

TYPES: BEGIN OF s_tabl_fk_def,
        fieldname   TYPE  forfield,
        fortable    TYPE  fortable,
        forkey      TYPE  forkey,
        checktable  TYPE  checktable,
        checkfield  TYPE  fieldname,
        generic     TYPE  c,
        constant    TYPE  c LENGTH 30,
       END OF s_tabl_fk_def.
TYPES: t_tabl_fk_def TYPE TABLE OF s_tabl_fk_def WITH DEFAULT KEY.

TYPES: BEGIN OF s_tabl_field,
       fieldname    TYPE fieldname,
       keyflag      TYPE keyflag,
       rollname     TYPE rollname,
       checktable   TYPE checktable,
       shlpname     TYPE shlpname,
       typing_method TYPE string,
       END OF s_tabl_field.
TYPES: t_tabl_field TYPE STANDARD TABLE OF s_tabl_field WITH DEFAULT KEY.

TYPES: BEGIN OF s_tabl_index,
       indexname TYPE indexid,
       isextind  TYPE ddisextind,
       ddtext    TYPE ddtext,
       uniqueflag TYPE uniqueflag,
       dbindex    TYPE dbindex_d,
       dbstate    TYPE ddixdbstat,
       dbinclexcl TYPE ddixincex,
       index_fields TYPE string,
       END OF s_tabl_index.
TYPES: t_tabl_index TYPE STANDARD TABLE OF s_tabl_index WITH DEFAULT KEY.

TYPES: BEGIN OF s_tabl.
        INCLUDE TYPE s_obj_header.
TYPES:  tabclass  TYPE  tabclass.
TYPES:  contflag  TYPE  contflag.
TYPES:  mainflag  TYPE  maintflag.
TYPES:  fields    TYPE  t_tabl_field.
TYPES:  tech_setting  TYPE  dd09v.
TYPES:  namespace     TYPE  db6tresc_tab.
TYPES:  foreign_key_header  TYPE  dd08vttyp.
TYPES:  foreign_keys  TYPE  t_tabl_fk_def.
TYPES:  assignments   TYPE  dd35vttyp.
TYPES:  index         TYPE  t_tabl_index.
TYPES: END OF s_tabl.

TYPES: BEGIN OF s_tabd.
        INCLUDE TYPE s_tabl.
TYPES: END OF s_tabd.

TYPES: t_table_join          TYPE STANDARD TABLE OF dd26v WITH DEFAULT KEY.
TYPES: t_view_fields         TYPE STANDARD TABLE OF dd27p WITH DEFAULT KEY.
TYPES: t_join_condition      TYPE STANDARD TABLE OF dd28j WITH DEFAULT KEY.
TYPES: t_selection_condition TYPE STANDARD TABLE OF dd28v WITH DEFAULT KEY.

TYPES: BEGIN OF s_view.
        INCLUDE TYPE s_obj_header.
TYPES:  viewclass   TYPE  viewclass.
TYPES:  customauth  TYPE  contflag.
TYPES:  viewgrant   TYPE  viewgrant.
TYPES:  globalflag  TYPE  maintflag.
TYPES:  table_join  TYPE  t_table_join.
TYPES:  fields      TYPE  t_view_fields.
TYPES:  join_condition       TYPE  t_join_condition.
TYPES:  selection_condition  TYPE  t_selection_condition.
TYPES:  tech_setting         TYPE  dd09v.
TYPES: END OF s_view.

TYPES: BEGIN OF s_vied.
        INCLUDE TYPE s_view.
TYPES: END OF s_vied.

TYPES: t_vclstruc TYPE STANDARD TABLE OF v_vclstruc WITH DEFAULT KEY.
TYPES: t_vclstdep TYPE STANDARD TABLE OF  v_vclstdep WITH DEFAULT KEY.
TYPES: t_maintenance_events TYPE STANDARD TABLE OF tvimf WITH DEFAULT KEY.
TYPES: t_viewcluster_events TYPE STANDARD TABLE OF v_vclmf WITH DEFAULT KEY.

TYPES: BEGIN OF s_vcls.
        INCLUDE TYPE s_obj_header.
TYPES:  hieropsoff  TYPE  sychar01.
TYPES:  readkind    TYPE  sychar01.
TYPES:  basevcl     TYPE  vcl_name.
TYPES:  exitprog    TYPE  programm.
TYPES:  object_stru TYPE  t_vclstruc.
TYPES:  field_dep   TYPE  t_vclstdep.
TYPES:  events      TYPE  t_viewcluster_events.
TYPES: END OF s_vcls.

TYPES: BEGIN OF s_tobj.
        INCLUDE TYPE s_obj_header.
TYPES:  tabname TYPE  vim_name.
TYPES:  area    TYPE  funct_pool.
TYPES:  maint_type    TYPE  maint_type.
TYPES:  liste   TYPE  list_scr.
TYPES:  detail  TYPE  single_scr.
TYPES:  mclass  TYPE  ddmclass.
TYPES:  cclass  TYPE  dicbercls.
TYPES:  events  TYPE  t_maintenance_events.
TYPES: END OF s_tobj.

TYPES: BEGIN OF s_shlp.
        INCLUDE TYPE s_obj_header.
TYPES:  issimple   TYPE  ddshsimple.
TYPES:  selmethod  TYPE  selmethod.
TYPES:  selmtype   TYPE  selmtype.
TYPES:  selmexit   TYPE  ddshselext.
TYPES:  hotkey     TYPE  ddshhotkey.
TYPES:  dialogtype TYPE  ddshdiatyp.
TYPES:  params     TYPE  rsdg_t_dd32p.
TYPES: END OF s_shlp.

TYPES: BEGIN OF s_shld.
        INCLUDE TYPE s_shlp.
TYPES: END OF s_shld.

TYPES: t_base_table TYPE STANDARD TABLE OF dd26e WITH DEFAULT KEY.
TYPES: t_lock_param TYPE STANDARD TABLE OF ddena WITH DEFAULT KEY.
TYPES: BEGIN OF s_enqu.
        INCLUDE TYPE s_obj_header.
TYPES:  rfcenable    TYPE  rfcenable.
TYPES:  base_tables  TYPE  t_base_table.
TYPES:  lock_params  TYPE  t_lock_param.
TYPES: END OF s_enqu.

TYPES: BEGIN OF s_enqd.
        INCLUDE TYPE s_enqu.
TYPES: END OF s_enqd.

TYPES: t_dd42v TYPE STANDARD TABLE OF dd42v WITH DEFAULT KEY.
TYPES: t_dd43v TYPE STANDARD TABLE OF dd43v WITH DEFAULT KEY.
TYPES: BEGIN OF s_ttyp.
        INCLUDE TYPE s_obj_header.
TYPES:  rowtype     TYPE  ttrowtype.
TYPES:  accessmode  TYPE  accessmode.
TYPES:  keydef   TYPE  ttypkeydef.
TYPES:  keykind  TYPE  keykind.
TYPES:  keyfdcount  TYPE  keyfdcnt.
TYPES:  generic     TYPE  typgeneric.
TYPES:  typelen     TYPE  ddleng.
TYPES:  ttypkind    TYPE  ttypkind.
TYPES:  range_ctyp  TYPE  range_ctyp.
TYPES:  reftype     TYPE  ddreftype.
TYPES:  occurs      TYPE  ddoccurs.
TYPES:  primary_key    TYPE  t_dd42v.
TYPES:  secondary_key  TYPE  t_dd43v.
TYPES: END OF s_ttyp.

TYPES: BEGIN OF s_ttyd.
        INCLUDE TYPE s_ttyp.
TYPES: END OF s_ttyd.

TYPES: BEGIN OF s_nrob.
        INCLUDE TYPE s_obj_header.
TYPES:  txt  TYPE  nrobjtxt.
TYPES:  dtelsobj    TYPE  nrsobjnam.
TYPES:  domlen      TYPE  nrlendom.
TYPES:  percentage  TYPE  nrperc.
TYPES:  code        TYPE  nrcode.
TYPES:  buffer      TYPE  nrbuffer.
TYPES:  noivbuffer  TYPE  nrivbuffer.
TYPES:  nonrswap    TYPE  nrswap.
TYPES:  yearind     TYPE  nryearind.
TYPES: END OF s_nrob.

TYPES: BEGIN OF s_msg_txt.
        INCLUDE TYPE t100.
TYPES: self_explanatory TYPE c.
TYPES: END  OF s_msg_txt.
TYPES: t_message_txt TYPE STANDARD TABLE OF s_msg_txt WITH DEFAULT KEY.

TYPES: t_tline TYPE STANDARD TABLE OF tline WITH DEFAULT KEY.
TYPES: BEGIN OF s_long_text.
        INCLUDE TYPE t100.
TYPES: long_text TYPE t_tline.
TYPES: END OF  s_long_text.
TYPES: t_long_text TYPE STANDARD TABLE OF s_long_text WITH DEFAULT KEY.

TYPES: BEGIN OF s_msad.
        INCLUDE TYPE s_obj_header.
TYPES:  message_texts  TYPE t_message_txt.
TYPES:  long_texts     TYPE t_long_text.
TYPES: END OF s_msad.

TYPES: BEGIN OF s_msag.
        INCLUDE TYPE s_msad.
TYPES: END OF s_msag.

TYPES: BEGIN OF s_mess.
        INCLUDE TYPE s_obj_header.
        INCLUDE TYPE s_msg_txt.
TYPES: long_text TYPE t_tline.
TYPES: END OF s_mess.

TYPES: BEGIN OF s_docu.
        INCLUDE TYPE s_obj_header.
TYPES: long_text TYPE t_tline.
TYPES: END OF s_docu.

TYPES: t_primary_key TYPE STANDARD TABLE OF e071k  WITH DEFAULT KEY.
TYPES: t_field_info  TYPE STANDARD TABLE OF e071kf WITH DEFAULT KEY.
TYPES: BEGIN OF s_vdat.
        INCLUDE TYPE s_obj_header.
TYPES: primary_keys TYPE t_primary_key.
TYPES: field_info   TYPE t_field_info.
TYPES: END OF s_vdat.
TYPES: t_vdat TYPE STANDARD TABLE OF s_vdat WITH DEFAULT KEY.

TYPES: BEGIN OF s_cdat.
        INCLUDE TYPE s_vdat.
TYPES:  object_stru TYPE t_vclstruc.
TYPES: END OF s_cdat.

TYPES: BEGIN OF s_vdat_ignore,
        vcls_name TYPE sobj_name,
        obj_name TYPE sobj_name,
       END OF s_vdat_ignore.

TYPES: BEGIN OF s_tabu.
        INCLUDE TYPE s_vdat.
TYPES: END OF s_tabu.

TYPES: t_tcode_authority TYPE STANDARD TABLE OF tstca WITH DEFAULT KEY.
TYPES: BEGIN OF s_tran_default_value,
       screen_field TYPE eu_para_fn,
       value        TYPE eu_para_vl,
       END OF s_tran_default_value.
TYPES: t_tran_default_value TYPE STANDARD TABLE OF s_tran_default_value WITH DEFAULT KEY.
TYPES: BEGIN OF s_tran.
        INCLUDE TYPE s_obj_header.
TYPES: transaction_type TYPE  c.
TYPES: authority        TYPE  t_tcode_authority.
TYPES: basic_info       TYPE  tstcv.
TYPES: gui_attributes   TYPE  tstcc.
TYPES: uiclass          TYPE  tstcclass.
TYPES: param            TYPE  tcdparam.
TYPES: param_values     TYPE  t_tran_default_value.
TYPES: transaction      TYPE  tcode.
TYPES: END OF s_tran.
*&-------------------------Constants/Global Data Definition-------------------------*
CONSTANTS: gcv_act_update TYPE char6 VALUE 'Update',
           gcv_act_create TYPE char6 VALUE 'Create',
* Html template definition, place holder like $XXX will be replaced by content
           gcv_header_html TYPE string VALUE '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                             '<b><span style="font-size:20.0pt;line-height:115%">$HEADER_NO.$OBJECT_DESC</span></b>' &
                                             '</p>',
           gcv_title_html  TYPE string VALUE
                                   '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                   '<span style="font-size:16.0pt;line-height:115%">$TITLE_NO $ACTIVITY $OBJECT_DESC $OBJ_NAME</span>' &
                                   '</p>',
           gcv_small_title_html  TYPE string VALUE
                                   '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                   '<span style="font-size:14.0pt;line-height:115%">$TITLE</span>' &
                                   '</p>',
           gcv_paragraph_html  TYPE string VALUE
                                    '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                    '$PARAGRAPH' &
                                    '</p>',
           gcv_td_label  TYPE string VALUE
                                '<td valign="top" style="border:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt">' &
                                  '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                    '<b>$LABEL</b>' &
                                  '</p>' &
                                '</td>',
           gcv_td_content TYPE string VALUE
                                '<td valign="top" style="border:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt">' &
                                  '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal">' &
                                    '$VALUE' &
                                  '</p>' &
                                '</td>',
           gcv_td_inner_table TYPE string VALUE '<td>$VALUE</td>',
           gcv_img_content TYPE string VALUE '<p><img width=600 height=450 src="$IMAGE.jpg"></p>',  "#EC NEEDED
           gcv_table_begin TYPE string VALUE '<table class="MsoTableGrid" border="1" cellspacing="0" cellpadding="0" width="100%" style="100.0%;border-collapse:collapse;border:none">',
           gcv_table_end   TYPE string VALUE '</table>'.

CONSTANTS: BEGIN OF c_trans_type,
            dialog TYPE c VALUE '1',
            report TYPE c VALUE '2',
            oo     TYPE c VALUE '3',
            trans_with_variant TYPE c VALUE '4',
            trans_with_param   TYPE c VALUE '5',
           END OF c_trans_type.
DATA: gt_ko100         TYPE HASHED TABLE OF ko100 WITH UNIQUE KEY object,
      gt_objtype_desc  TYPE HASHED TABLE OF ko100 WITH UNIQUE KEY object,
      gt_objtype_order TYPE ht_objtype_order,
      gt_value_desc    TYPE HASHED TABLE OF s_value_desc WITH UNIQUE KEY fieldname,
      gv_trans_dir     TYPE string,
      " global internal data table for each kind of object, name convention: gt_{objtype}
      gt_devc TYPE TABLE OF s_devc,                         "#EC NEEDED
      gt_devp TYPE TABLE OF s_devp,                         "#EC NEEDED
      gt_pinf TYPE TABLE OF s_pinf,                         "#EC NEEDED
      gt_fugr TYPE TABLE OF s_fugr,                         "#EC NEEDED
      gt_fugt TYPE TABLE OF s_fugt,                         "#EC NEEDED
      gt_doma TYPE TABLE OF s_doma,                         "#EC NEEDED
      gt_domd TYPE TABLE OF s_domd,                         "#EC NEEDED
      gt_dtel TYPE TABLE OF s_dtel,                         "#EC NEEDED
      gt_dted TYPE TABLE OF s_dted,                         "#EC NEEDED
      gt_tabl TYPE TABLE OF s_tabl,                         "#EC NEEDED
      gt_tabd TYPE TABLE OF s_tabd,                         "#EC NEEDED
      gt_view TYPE TABLE OF s_view,                         "#EC NEEDED
      gt_vied TYPE TABLE OF s_vied,                         "#EC NEEDED
      gt_vcls TYPE TABLE OF s_vcls,                         "#EC NEEDED
      gt_tobj TYPE TABLE OF s_tobj,                         "#EC NEEDED
      gt_shlp TYPE TABLE OF s_shlp,                         "#EC NEEDED
      gt_shld TYPE TABLE OF s_shld,                         "#EC NEEDED
      gt_enqu TYPE TABLE OF s_enqu,                         "#EC NEEDED
      gt_enqd TYPE TABLE OF s_enqd,                         "#EC NEEDED
      gt_ttyp TYPE TABLE OF s_ttyp,                         "#EC NEEDED
      gt_ttyd TYPE TABLE OF s_ttyd,                         "#EC NEEDED
      gt_nrob TYPE TABLE OF s_nrob,                         "#EC NEEDED
      gt_msad TYPE TABLE OF s_msad,                         "#EC NEEDED
      gt_msag TYPE TABLE OF s_msag,                         "#EC NEEDED
      gt_mess TYPE TABLE OF s_mess,                         "#EC NEEDED
      gt_docu TYPE TABLE OF s_docu,                         "#EC NEEDED
      gt_tran TYPE TABLE OF s_tran,                         "#EC NEEDED
      gt_cdat TYPE TABLE OF s_cdat,                         "#EC NEEDED
      gt_vdat TYPE t_vdat,                                  "#EC NEEDED
      gt_tabu TYPE t_vdat,                                  "#EC NEEDED

      gt_vdat_ignore   TYPE HASHED TABLE OF s_vdat_ignore WITH UNIQUE KEY obj_name,
      gv_tr_date       TYPE as4date,
      gv_header_no     TYPE numc2,
      " screen shot folder, however currently this feature is not available
      gv_img_folder    TYPE string,                         "#EC NEEDED
      gt_object_instruction TYPE ht_object_instruction,
      gt_html          TYPE TABLE OF string,
      gt_html_all      TYPE TABLE OF string,
      " template code: a helper when add support for new object types
      gt_code_template TYPE TABLE OF char255,
      gt_objtype2codes TYPE TABLE OF trobjtype,
      gt_obj_gen_msg   TYPE TABLE OF s_obj_gen_msg,
      gt_sys_msg       TYPE TABLE OF s_common_msg,
      gv_username      TYPE string,
      go_zip           TYPE REF TO cl_abap_zip,
      gv_slash         TYPE c.

DATA: gcv_text_unexpected_error TYPE string,
      BEGIN OF text_common,
        label_col_attr  TYPE string,
        label_col_value TYPE string,
        title_tobj      TYPE string,
        txt_notice      TYPE string,
        title_html      TYPE string,
        msg_success     TYPE string,
        msg_ignore      TYPE string,
        msg_error       TYPE string,
        msg_error_msg   TYPE string,
        rep_none        TYPE string,
        rep_docu        TYPE string,
        action_en       TYPE string,
        action2_en      TYPE string,
        action_de       TYPE string,
        thanks          TYPE string,
        time_cost       TYPE string,
      END OF text_common,
      BEGIN OF text_devc,
        label_tp_layer    TYPE string,
        txt_tp_note       TYPE string,
        title_access      TYPE string,
        title_interface   TYPE string,
        inst_devc         TYPE string,
        inst_devp         TYPE string,
        inst_devp_sub     TYPE string,
        inst_pinf         TYPE string,
        inst_pinf_sub     TYPE string,
      END OF text_devc,
      BEGIN OF text_fugr,
        inst_fugr TYPE string,
        inst_fugt TYPE string,
      END OF text_fugr,
      BEGIN OF text_doma,
        label_value_range TYPE string,
        inst_doma         TYPE string,
        inst_domd         TYPE string,
      END OF text_doma,
      BEGIN OF text_dtel,
        label_domain     TYPE string,
        label_data_type  TYPE string,
        label_predf_type TYPE string,
        label_fld_lab    TYPE string,
        label_length     TYPE string,
        label_short      TYPE string,
        label_medium     TYPE string,
        label_long       TYPE string,
        label_heading    TYPE string,
        txt_mt_docu_title TYPE string,
        txt_mt_docu_para  TYPE string,
        inst_dtel         TYPE string,
        inst_dted         TYPE string,
      END OF text_dtel,
      BEGIN OF text_tabl,
        title_tech  TYPE string,
        title_flds  TYPE string,
        title_comps TYPE string,
        title_fks   TYPE string,
        title_namespace TYPE string,
        title_index     TYPE string,
        note_flds  TYPE string,
        note_comps TYPE string,
        note_fks   TYPE string,
        inst_tabl  TYPE string,
        inst_tabd  TYPE string,
        inst_tabt  TYPE string,
        inst_indx  TYPE string,
        label_fk_flds  TYPE string,
        label_check_rq TYPE string,
        label_msg_no   TYPE string,
        label_aarea    TYPE string,
        label_screen_check TYPE string,
        label_card     TYPE string,
        label_fk_type  TYPE string,
        label_fk_semantic  TYPE string,
      END OF text_tabl,
      BEGIN OF text_view,
        inst_view TYPE string,
        inst_vied TYPE string,
        inst_viet TYPE string,
        title_tables TYPE string,
        title_fields TYPE string,
        title_join_conds TYPE string,
        title_sel_conds  TYPE string,
        note_join_cond   TYPE string,
        note_sel_cond    TYPE string,
      END OF text_view,
      BEGIN OF text_shlp,
        txt_type_ele  TYPE string,
        txt_type_col  TYPE string,
        txt_type      TYPE string,
        inst_shlp     TYPE string,
        inst_shld     TYPE string,
      END OF text_shlp,
      BEGIN OF text_enqu,
        label_allow_rfc TYPE string,
        label_tables    TYPE string,
        label_params    TYPE string,
        inst_enqu       TYPE string,
        inst_enqd       TYPE string,
      END OF text_enqu,
      BEGIN OF text_nrob,
        inst_nrob TYPE string,
      END OF text_nrob,
      BEGIN OF text_docu,
        inst_docu TYPE string,
        inst_doct TYPE string,
        inst_docv TYPE string,
      END OF text_docu,
      BEGIN OF text_mess,
        txt_title       TYPE string,
        txt_mt_longtext TYPE string,
        inst_mess       TYPE string,
      END OF text_mess,
      BEGIN OF text_msag,
        label_messages  TYPE string,
        inst_msag       TYPE string,
        inst_msad       TYPE string,
        inst_mess       TYPE string,
      END OF text_msag,
      BEGIN OF text_tobj,
        msg_obj_invalid TYPE string,
        label_events    TYPE string,
        inst_tobj       TYPE string,
        txt_mt_event   TYPE string,
      END OF text_tobj,
      BEGIN OF text_vcls,
        title_obj_stru TYPE string,
        title_fld_dep  TYPE string,
        title_events   TYPE string,
        label_hier     TYPE string,
        label_type     TYPE string,
        txt_type_comp  TYPE string,
        txt_type_sub   TYPE string,
        txt_mt_event   TYPE string,
      END OF text_vcls,
      BEGIN OF text_ttyp,
        label_row_type  TYPE string,
        inst_ttyp       TYPE string,
        inst_ttyd       TYPE string,
      END OF text_ttyp,
      BEGIN OF text_tran,
        inst_tran            TYPE string,
        label_type           TYPE string,
        label_default_values TYPE string,
        label_classification TYPE string,
        label_inherit_gui    TYPE string,
        label_prof_user      TYPE string,
        label_easy_web       TYPE string,
        label_service        TYPE string,
        label_pervasive      TYPE string,
        label_auth_values    TYPE string,
        label_oo_mode        TYPE string,
        label_oo_clas        TYPE string,
        label_oo_meth        TYPE string,
        label_oo_local_prog  TYPE string,
        label_oo_update_mode TYPE string,
        label_transaction    TYPE string,
        label_transaction_variant TYPE string,
        label_skip_init_screen    TYPE string,
      END OF text_tran,
      BEGIN OF text_tabu,
        inst_cdat  TYPE string,
        inst_vdat  TYPE string,
        inst_tabu  TYPE string,
        txt_maint_node TYPE string,
      END OF text_tabu.
*&---------------------Selection Screen Components---------------------*
DATA: lt_trans TYPE e070-trkorr,
      lt_exclu TYPE e071-obj_name,
      lt_objtype TYPE trobjtype.
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE gc_case.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(35) gc_exp FOR FIELD export.
PARAMETERS export TYPE c RADIOBUTTON GROUP a DEFAULT 'X' USER-COMMAND updown.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(35) gc_imp FOR FIELD import.
PARAMETERS import TYPE c RADIOBUTTON GROUP a.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(35) gc_code FOR FIELD code.
PARAMETERS code TYPE c RADIOBUTTON GROUP a.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE gc_opt.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_trans FOR FIELD so_trans MODIF ID exp.
SELECT-OPTIONS: so_trans FOR lt_trans NO INTERVALS MODIF ID exp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_exclu FOR FIELD so_exclu MODIF ID exp.
SELECT-OPTIONS: so_exclu FOR lt_exclu NO INTERVALS MODIF ID exp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_dir FOR FIELD p_dir MODIF ID exp.
PARAMETERS: p_dir TYPE string  MODIF ID exp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_doc FOR FIELD p_doc MODIF ID exp.
PARAMETERS: p_doc TYPE string LOWER CASE DEFAULT 'Correction_Pre' MODIF ID exp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_open FOR FIELD p_open MODIF ID exp.
PARAMETERS: p_open TYPE abap_bool AS CHECKBOX MODIF ID exp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_bin FOR FIELD p_bin MODIF ID exp.
PARAMETERS: p_bin TYPE c AS CHECKBOX DEFAULT abap_true MODIF ID exp.
PARAMETERS: p_test TYPE abap_bool NO-DISPLAY.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_file FOR FIELD p_file MODIF ID imp.
PARAMETERS: p_file TYPE string MODIF ID imp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) gc_objt FOR FIELD so_objt MODIF ID cod.
SELECT-OPTIONS: so_objt FOR lt_objtype NO INTERVALS MODIF ID cod.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_trans-low.
  PERFORM f4_request.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_exclu-low.
  PERFORM f4_exclude_objects.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dir.
  PERFORM select_download_dir CHANGING p_dir.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM select_transport_file CHANGING p_file.

INITIALIZATION.
  PERFORM init_texts USING sy-langu.
  PERFORM initialize_buffer.

AT SELECTION-SCREEN OUTPUT.
  PERFORM scenario_switch.

START-OF-SELECTION.
  PERFORM response.
*&--------------------------Text Elements: English and German available--------------------------*
***************** i18n Begin *****************
FORM init_texts USING iv_langu TYPE sy-langu.
*  TODO
*  IF iv_langu EQ 'D'.
*    PERFORM init_german_texts.
*  ELSE.
*    PERFORM init_english_texts.
*  ENDIF.
  PERFORM init_english_texts.
  PERFORM init_object_instructions.
ENDFORM.

FORM init_english_texts.
* selection screen texts
  gc_case   = 'Scenario Selection'.
  gc_exp    = 'Generate Note Pre-Impl Documentation'.
  gc_imp    = 'Upload Transport Files'.
  gc_code   = 'Code Helper For New Object Type'.
  gc_opt    = 'Options'.
  gc_trans  = 'Transport Request'.
  gc_exclu  = 'Excluded Objects'.
  gc_dir    = 'Export Folder'.
  gc_doc    = 'Document Title'.
  gc_open   = 'Open Document In MS Word'.
  gc_bin    = 'Download Transport Files'.
  gc_file   = 'Upload Transport File(Zip)'.
  gc_objt   = 'New Object Types'.
* documentation/message texts
  gcv_text_unexpected_error = 'An unexpected error occurred.'.
  text_common-label_col_attr = 'Attribute'.
  text_common-label_col_value = 'Value'.
  text_common-title_tobj = 'Maintenance Object'.
  text_common-title_html = 'Note Pre-Impl Documentation'.
  text_common-txt_notice = 'Dear customer, please maintain objects in the below refer to this documentation and your own system settings.' &
                           'In case some of the objects exist already and are exactly same as described in the documentation, you may simply igore them.'.
  text_common-msg_success = 'Success'.
  text_common-msg_ignore = 'Ignored.Nothing needs to be done on this object'.
  text_common-msg_error = 'Failed'.
  text_common-msg_error_msg = 'Error Message'.
  text_common-rep_none = 'Dear $USERNAME, it seems there is no need to prepare documentation for the not.'.
  text_common-rep_docu = 'Dear $USERNAME, here is documentation generation report : '.
  text_common-action_en = 'Please open the generated html file using MS Office Word, save as DOCX'.
  text_common-action2_en = 'Then review and make necessary modifications for your usage.'.
  text_common-action_de = 'Please open the generated html file using IE , copy all the content to Word and save.'.
  text_common-thanks = 'Thank you for using this tool, have a nice day ^_^'.
  text_common-time_cost = 'Job finished in $TIME seconds.'.

  text_devc-label_tp_layer = 'Transport Layer'.
  text_devc-txt_tp_note = '<i style=mso-bidi-font-style:normal><span style=color:red>' &
                          'Please fill in according to your own system landscape settings' &
                          '</span></i>'.
  text_devc-title_access = 'Use Accesses'.
  text_devc-title_interface = 'Package Interfaces'.

  text_doma-label_value_range = 'Value Range'.

  text_dtel-label_domain = 'Domain'.
  text_dtel-label_data_type = 'Data Type '.
  text_dtel-label_predf_type = 'Predefined type'.
  text_dtel-label_fld_lab = 'Field Label'.
  text_dtel-label_length = 'Length'.
  text_dtel-label_short = 'Short'.
  text_dtel-label_medium = 'Medium'.
  text_dtel-label_long = 'Long'.
  text_dtel-label_heading = 'Heading'.
  text_dtel-txt_mt_docu_title = 'Maintain documentation for this data element:'.
  text_dtel-txt_mt_docu_para = 'Please add documentation according to the format and content listed in the below.<br>'.

  text_tabl-title_tech = 'Technical Settings:'.
  text_tabl-label_fk_flds = 'Foreign Key Fields'.
  text_tabl-title_flds = 'Fields: '.
  text_tabl-title_comps = 'Components: '.

  DATA lcv_note_fc TYPE string.
  lcv_note_fc = 'Please notice that those $ELE marked as italic are contained in included structure/table and you <b>DON''T</b> need to add them.'.
  text_tabl-note_flds = lcv_note_fc.
  REPLACE FIRST OCCURRENCE OF '$ELE' IN text_tabl-note_flds WITH 'fields'.
  text_tabl-note_comps = lcv_note_fc.
  REPLACE FIRST OCCURRENCE OF '$ELE' IN text_tabl-note_comps WITH 'components'.

  text_tabl-title_fks = 'Foreign Keys:'.
  text_tabl-note_fks = 'Maintain foreign key relationship for field: '.
  text_tabl-title_namespace = 'Maintain Customer Namespace: '.
  text_tabl-title_index = 'Indexes:'.
  text_tabl-label_check_rq = 'Check required: '.
  text_tabl-label_msg_no = 'MsgNo: '.
  text_tabl-label_aarea = 'AArea: '.
  text_tabl-label_screen_check = 'Screen check'.
  text_tabl-label_card = 'Cardinality: '.
  text_tabl-label_fk_type = 'Foreign key field type: '.
  text_tabl-label_fk_semantic = 'Semantic attributes'.

  text_view-title_tables = 'Tables: '.
  text_view-title_join_conds = 'Join Conditions: '.
  text_view-title_sel_conds = 'Selection conditions: '.
  text_view-title_fields = 'View Flds:'.
  text_view-note_join_cond = '<i>No additional join condition needs to be maintained here.</i>'.
  text_view-note_sel_cond = '<i>No additional selection condition needs to be maintained here.</i>'.

  text_enqu-label_allow_rfc = 'Allow RFC'.
  text_enqu-label_tables = 'Tables'.
  text_enqu-label_params = 'Parameters'.

  text_shlp-txt_type_ele = 'Elementary'.
  text_shlp-txt_type_col = 'Collective'.
  text_shlp-txt_type = 'Type'.

  text_ttyp-label_row_type = 'Line Type'.

  text_msag-label_messages = 'Messages'.

  text_mess-txt_title = 'Maintain messages with short text under message class as listed in the below<br>'.
  text_mess-txt_mt_longtext = 'Maintain long text for message: '.

  text_tobj-msg_obj_invalid = 'Maintenance Object does not exist any more, it might be deleted by someone else.'.
  text_tobj-label_events = 'Events'.
  text_tobj-txt_mt_event = 'In the maintenance object screen, click menu Enviroment->Modification->Events, ' &
                           'click ''New Entries'' button, input event type and FORM routine name, then save.' &
                           'The code of the routines will be imported in the process of implementing note'.

  text_vcls-title_obj_stru = 'Object Structure'.
  text_vcls-title_fld_dep = 'Field Dependence'.
  text_vcls-title_events = text_tobj-label_events.
  text_vcls-label_hier = 'Hierarchical Maintenance Operation Handling'.
  text_vcls-label_type = 'Read Type'.
  text_vcls-txt_type_comp = 'Complete'.
  text_vcls-txt_type_sub = 'Subtree'.
  text_vcls-txt_mt_event = 'In the maintenance screen of view cluster, double click node ''Events'', ' &
                           'input main program name, event type, form routine and save.'.

  text_tran-label_type           = 'Transaction Type'.
  text_tran-label_default_values = 'Default Values'.
  text_tran-label_classification = 'Classfication'.
  text_tran-label_inherit_gui    = 'Inherit GUI Attributes'.
  text_tran-label_prof_user      = 'Professional User Transaction'.
  text_tran-label_easy_web       = 'Easy Web Transaction'.
  text_tran-label_service        = 'Service'.
  text_tran-label_pervasive      = 'Pervasive enabled'.
  text_tran-label_auth_values    = 'Values'.
  text_tran-label_oo_mode        = 'OO Transaction Mode'.
  text_tran-label_oo_clas        = 'Class Name'.
  text_tran-label_oo_meth        = 'Method'.
  text_tran-label_oo_local_prog  = 'Local In Program'.
  text_tran-label_oo_update_mode = 'Update mode'.
  text_tran-label_transaction    = 'Transaction'.
  text_tran-label_transaction_variant = 'Transaction Variant'.
  text_tran-label_skip_init_screen    = 'Skip initial screen'.

  text_tabu-txt_maint_node = 'Maintain entries for node : '.
* instructions of supported object types
  text_devc-inst_devc = 'Run TCODE SE80 and enter in Repository Browser, select ''Package'' from dropdown list, ' &
            'input package name and press enter, click ''Yes'' in the pop up dialog box to create package, ' &
            'input necessary attribute values according to the documentation and save.'.
  text_devc-inst_devp = 'Run TCODE SE21, input package name listed in the below, click ''Change'' button,' &
            ' click ''Use Accesses'' tab, click ''Create'' button, ' &&
            'input package interface name and error severity according to the documentation and save.'.
  text_devc-inst_pinf = 'Run TCODE SE21, input package name listed in the below, click ''Change'' button, ' &
            'click ''Package Interfaces'' tab, click ''Add'' button, ' &
            'input package interface name and short description according to documentation and save.'.
  text_devc-inst_devp_sub = 'Click ''Use Accesses'' tab, click ''Create'' button, ' &
            'input package interface name and error severity according to the documentation and save.'.
  text_devc-inst_pinf_sub = 'Click ''Package Interfaces'' tab, click ''Add'' button, ' &
            'input package interface name and short description according to documentation and save.'.
  text_fugr-inst_fugr = 'Select package where function group will be created, right click->Create->Function Group, ' &
                        'input attribute values and save.'.
  text_fugr-inst_fugt = 'Select function group and right click->Change, input attribute values and save.'.
  text_doma-inst_doma = 'Run TCODE SE11, select radio box ''Domain'', input domain name, click ''Create'' button, ' &
                        'input attribute values, save and activate.'.
  text_dtel-inst_dtel = 'Run TCODE SE11, select radio box ''Data type'', input data element name, click ''Create'' button, ' &
                        'select radio box ''Data element'', input attribute values, then save and activate.'.
  text_tabl-inst_tabl = 'Run TCODE SE11, for database table, select radio box ''Database table'', input table name, click ''Create'' button, ' &
                        'maintain the attributes, fields, technical settings, indexes and etc.' &
                        'For structure, select radio box ''Data type'', input structure name, ' &&
                        'click ''Create'' button, select radio box ''Structure'', input attribute values, then save and activate.'.
  text_tabl-inst_tabd = 'Run TCODE SE11, select radio box ''Database table'', input table/structure name, click ''Change'' button, ' &
                        'maintain the attributes, then save and activate.'.
  text_view-inst_view = 'Run TCODE SE11, select radio box ''View'', input view name, click ''Create'' button, select the view type,' &
                        ' maintain attributes, table/join conditions, ' &
                        'View fields, Selection Conditions, Maint Status and etc, then save and activate.'.
  text_view-inst_vied = 'Run TCODE SE11, select radio box ''View'', input view name, click ''Change'' button, maintain attributes, ' &
                        'table/join conditions, View fields, Selection Conditions, Maint Status and etc, then save and activate.'.
  text_shlp-inst_shlp = 'Run TCODE SE11, select radio box ''Search help'', input search help name, click ''Create'' button, ' &
                        'select the search help type, maintain attributes, search help parameters and etc, then save and activate.'.
  text_enqu-inst_enqu = 'Run TCODE SE11, select radio box ''Lock Object'', input lock object name, click ''Create'' button, ' &
                        'maintain attributes, tables, lock parameters and etc, then save and activate.'.
  text_ttyp-inst_ttyp = 'Run TCODE SE11, select radio box ''Data type'', input table type name, click ''Create'' button, ' &
                        'select radio box ''Table Type'', input attribute values, then save and activate.'.
  text_tobj-inst_tobj = 'Run TCODE SE54, input maintenance view name, select radio box ''Generated Objects'', click ''Create/Change'' button, ' &&
                        'select ''Yes'' in the popup confirmation dialog box, input attribute values and click the create button above, ' &
                        'choose package according to documentation and save.'.
  text_nrob-inst_nrob = 'Run TCODE SNRO, input number range object name, click ''Create'' button, input attribute values and save, ' &
                        'choose package according to documentation.'.
  text_msag-inst_msad = 'Run TCODE SE91, input message class name and click ''Create'' button, input attribute values, messages and save,' &
                        ' choose package according to documentation.'.
  text_msag-inst_msag =  text_msag-inst_msad.
  text_msag-inst_mess = 'Run TCODE SE91, input message class name and click ''Change'' button, maintain message short texts, ' &
                        'for message with long text, uncheck the checkbox ' &
                        '''Self-explanatory'', then click menu ''Long text'', maintain the long text according to documentation.'.
  text_docu-inst_docu = 'For data element, run TCODE SE11, select radio box ''Data type'', input data element name and click ''Change'' button, ' &
                        ' click menu ''Documentation'' and maintain the documentation as described in the below.<br>' &&
                        'For long text of message short text, run TCODE SE91, input message class name and click ''Change'' button, ' &
                        'select the message, uncheck the checkbox ''Self-explanatory'', then click menu ''Long text'', ' &
                        'maintain the long text as described in the below.'.
  text_tran-inst_tran = 'Run TCODE SE93, input transaction code, click ''Create'' button, if ' &
                        'input short text and select Start object, if it already exists, simply ignore it, if not, ' &
                        'maintain the attribute values and choose package according to documentation, then save your work.'.
  text_doma-inst_domd = 'Run TCODE SE11, select radio box ''Domain'', input domain name, click ''Change'' button, ' &
                        'input attribute values, save and activate.'.
  text_dtel-inst_dted = 'Run TCODE SE11, select radio box ''Data type'', input data element name, click ''Change'' button, ' &
                        'select radio box ''Data element'', input attribute values, then save and activate.'.
  text_tabl-inst_tabt = 'Run TCODE SE11, select radio box ''Database table'', input table name, click ''Change'' button, ' &
                        'click menu ''Technical Settings'', maintain attribute values according documentation and save.'.
  text_tabl-inst_indx = 'Run TCODE SE11, select radio box ''Database table'', input table name, click ''Change'' button, ' &
                        'click menu ''Indexes'', maintain attribute values according documentation and save.'.
  text_ttyp-inst_ttyd = 'Run TCODE SE11, select radio box ''Data type'', input table type name, click ''Change'' button, ' &
                        'select radio box ''Table Type'', input attribute values, then save and activate.'.
  text_shlp-inst_shld = 'Run TCODE SE11, select radio box ''Search help'', input search help name, click ''Change'' button, ' &
                        'select the search help type, maintain attributes, search help parameters and etc, then save and activate.'.
  text_enqu-inst_enqd = 'Run TCODE SE11, select radio box ''Lock Object'', input lock object name, click ''Change'' button, ' &
                        'maintain attributes, tables, lock parameters and etc, then save and activate.'.
  text_view-inst_viet = 'Run TCODE SE11, select radio box ''View'', input view name, click ''Change'' button,  ' &
                        'click menu ''Goto''->''Technical Settings'', maintain attribute values, then save and activate.'.
  text_docu-inst_doct = ''.
  text_docu-inst_docv = ''.

  DATA: lcv_inst_dat TYPE string.
  lcv_inst_dat = 'Run TCODE $CODE, input $DATYPE name, click button ''Maintain'',' &
          ' if warning message''Caution: The table is cross-client'' popup, ' & 'simply confirm it, then add entries in the below.<br>' &&
          'Notice that these entries might be dependent on other repository ojects, if you cannot go further, ' &
          'try to add the dependent objects first or do it again after implementing the note.' &&
          'Meanwhile, only those fields have a valid value need to maintain are listed, ' &
          'which means you don''t need to care about other fields.'.
  text_tabu-inst_cdat = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_cdat WITH 'SM34'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_cdat WITH 'view cluster'.

  text_tabu-inst_vdat = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_vdat WITH 'SM30'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_vdat WITH 'maintenance view'.

  text_tabu-inst_tabu = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_tabu WITH 'SM30'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_tabu WITH 'table'.
ENDFORM.

FORM init_german_texts.
* I'm sorry, but most of these German texts are actually translated by google and babylon...
* Auswahl Bildschirm Texte
  gc_case = 'Szenario Auswahl'.
  gc_exp = 'erzeugen Anmerkung Vor-einf#hren Dokumentation'.
  gc_imp = 'Antriebskraft-Transport-Dateien'.
  gc_code = 'Kodieren Sie Helfer f#r neuen Objekt-Typ'.
  gc_opt = 'Optionen'.
  gc_trans = 'Transport-Antrag'.
  gc_exclu = 'Ausgeschlossene Objekte'.
  gc_dir = 'Export-Ordner'.
  gc_doc = 'Dokument Title'.
  gc_open = 'Offenes Dokument im Wort'.
  gc_bin = 'Herunterladen Transport Files'.
  gc_file = 'Hochladen Transport-Datei (zip)'.
  gc_objt = 'Neue Objekt-Typen der'.
* Dokumentation / Meldetexte
  gcv_text_unexpected_error = 'Ein unerwarteter Fehler ist aufgetreten.'.
  text_common-label_col_attr = 'Attribut'.
  text_common-label_col_value = 'Value'.
  text_common-title_tobj = 'Wartung Object'.
  text_common-title_html = 'Hinweis Pre-Impl Dokumentation'.
  text_common-txt_notice = 'Sehr geehrter Kunde, bitte halten Objekte in der unten an dieser Dokumentation und Ihr eigenes System Einstellungen beziehen.' &&
                           'Bei einigen der Objekte bereits vorhanden sind und genau das gleiche wie in der Dokumentation beschrieben, k#nnen Sie einfach igore ihnen.'.
  text_common-msg_success = 'Erfolg'.
  text_common-msg_ignore = 'Ignored.Nothing muss auf diesem Gegenstand getan werden'.
  text_common-msg_error = 'Ausfallen'.
  text_common-msg_error_msg = 'Fehlermeldung'.
  text_common-rep_none = 'Lieber $USERNAME, scheint es, dass es keinen Bedarf gibt, Dokumentation f#r die Anmerkung vorzubereiten.'.
  text_common-rep_docu = 'Lieber $USERNAME, ist hier Dokumentationsgenerationsbericht : '.
  text_common-action_en = '#ffnen Sie bitte die erzeugte HTML-Datei unter Verwendung Mitgliedstaates Office Word, Abwehr als DOCX'.
  text_common-action2_en = 'Dann wiederholen Sie und machen Sie notwendige #nderungen f#r Ihre Verwendung.'.
  text_common-action_de = '#ffnen Sie bitte die erzeugte HTML-Datei unter Verwendung IE, kopieren Sie den ganzen Inhalt, um abzufassen und zu speichern.'.
  text_common-thanks = 'Danke f#r die Anwendung dieses Werkzeugs, haben Sie ein sch#ner Tag-^_^'.
  text_common-time_cost = 'Job beendet in $TIME Sekunden.'.

  text_devc-label_tp_layer = 'Transport Layer'.
  text_devc-txt_tp_note = '<i style=mso-bidi-font-style:normal><span style=color:red>' &
                          'Bitte in Bezug auf Ihre eigene Systemlandschaft Einstellungen f#llen' &
                          '</span></i>'.
  text_devc-title_access = 'Use Greift'.
  text_devc-title_interface = 'Paket Interfaces'.

  text_doma-label_value_range = 'Wert-Strecke'.

  text_dtel-label_domain = 'Domain'.
  text_dtel-label_data_type = 'Datentyp'.
  text_dtel-label_predf_type = 'Vordefinierte Typ'.
  text_dtel-label_fld_lab = 'Das Feld Label:'.
  text_dtel-label_length = 'L#nge'.
  text_dtel-label_short = 'Kurzes'.
  text_dtel-label_medium = 'mittleres'.
  text_dtel-label_long = 'langes'.
  text_dtel-label_heading = '#berschrift'.
  text_dtel-txt_mt_docu_title = 'Pflege der Dokumentation f#r dieses Datenelement:'.
  text_dtel-txt_mt_docu_para = 'Bitte f#gen Dokumentation nach Form und Inhalt in der unten. <br> aufgef#hrt.'.

  text_tabl-title_tech = 'Technische Einstellungen:'.
  text_tabl-label_fk_flds = 'Foreign Key Fields'.
  text_tabl-title_flds = 'Fields:'.
  text_tabl-title_comps = 'Komponenten:'.

  DATA lcv_note_fc TYPE String.
  lcv_note_fc = 'Bitte beachten Sie, dass die $ELE als kursiv markiert inkludierten Struktur / Tabelle enthalten sind und Sie <b> DON''T </b> brauchen, um sie hinzuzuf#gen.'.
  text_tabl-note_flds = lcv_note_fc.
  REPLACE FIRST OCCURRENCE OF '$ELE' IN text_tabl-note_flds WITH 'fields'.
  text_tabl-note_comps = lcv_note_fc.
  REPLACE FIRST OCCURRENCE OF '$ELE' IN text_tabl-note_flds WITH 'Komponenten'.

  text_tabl-title_fks = 'Foreign Keys:'.
  text_tabl-note_fks = 'Pflegen Fremdschl#sselbeziehung f#r field:'.
  text_tabl-title_namespace = 'Pflegen Kunde Namensraum:'.
  text_tabl-title_index = 'Indexes:'.
  text_tabl-label_check_rq = 'Check-in erforderlich:'.
  text_tabl-label_msg_no = 'MsgNr:'.
  text_tabl-label_aarea = 'AAREA:'.
  text_tabl-label_screen_check = 'Bildschirm #berpr#fen'.
  text_tabl-label_card = 'Kardinalit#t:'.
  text_tabl-label_fk_type = 'Fremdschl#sselfeld Typ:'.
  text_tabl-label_fk_semantic = 'Semantic Attribute'.

  text_view-title_tables = 'Tabellen:'.
  text_view-title_join_conds = 'Join-Bedingungen:'.
  text_view-title_sel_conds = 'Selection Bedingungen:'.
  text_view-title_fields = 'View Flds:'.
  text_view-note_join_cond = '<i> Keine zus#tzliche Join-Bedingung muss hier gehalten werden. </i>'.
  text_view-note_sel_cond = '<i> keine zus#tzliche Auswahl Bedingung muss hier gehalten werden. </i>'.

  text_enqu-label_allow_rfc = 'Erlaube RFC'.
  text_enqu-label_tables = 'Tabellen'.
  text_enqu-label_params = 'Parameter'.

  text_shlp-txt_type_ele = 'Elementary'.
  text_shlp-txt_type_col = 'Collective'.
  text_shlp-txt_type = 'Type'.

  text_ttyp-label_row_type = 'Line Type'.

  text_msag-label_messages = 'Nachrichten'.

  text_mess-txt_title = 'Nachrichten pflegen mit kurzen Text unter Nachricht Klasse wie in der unten aufgef#hrten <br>'.
  text_mess-txt_mt_longtext = 'Pflegen Langtext Nachricht:'.

  text_tobj-msg_obj_invalid = 'Wartung Objekt nicht mehr existiert, k#nnte es von jemand anderem gel#scht werden.'.
  text_tobj-label_events = 'Events'.
  text_tobj-txt_mt_event = 'Im Instandhaltungsobjekt Bildschirm, klicken Sie auf Men# Enviroment-> Modification-> Veranstaltungen, ' &&
                           'Klick ''New Entries'' Knopf, Eingang Event-Typ und FORM-Routine Namen, dann speichern. ' &
                           'Der Code der Routinen werden in den Prozess der Umsetzung beachten importiert werden.'.

  text_vcls-title_obj_stru = 'Objekt-Struktur'.
  text_vcls-title_fld_dep = 'Das Feld Dependence'.
  text_vcls-title_events = text_tobj-label_events.
  text_vcls-label_hier = 'Hierarchische Instandhaltung Betrieb Handhabung'.
  text_vcls-label_type = 'Read Type'.
  text_vcls-txt_type_comp = 'Beenden'.
  text_vcls-txt_type_sub = 'Subtree'.
  text_vcls-txt_mt_event = 'In der Pflege von Viewclusters, doppelklicken Sie auf Knoten ''Events'', Eingang Attributwerte und sparen.'.

  text_tran-label_type           = 'Transaction Type'.
  text_tran-label_default_values = 'Vorschlagswerte'.
  text_tran-label_classification = 'Klassifikation'.
  text_tran-label_inherit_gui    = 'GUI-Eigenschaften erben'.
  text_tran-label_prof_user      = 'Professional User Transaction'.
  text_tran-label_easy_web       = 'Easy Web Transaction'.
  text_tran-label_service        = 'Service'.
  text_tran-label_pervasive      = 'Pervasive enabled'.
  text_tran-label_auth_values    = 'Werte'.
  text_tran-label_oo_mode        = 'OO-Transaktionsmodell'.
  text_tran-label_oo_clas        = 'Klassenname'.
  text_tran-label_oo_meth        = 'Methode'.
  text_tran-label_oo_local_prog  = 'lokal_in_Programm'.
  text_tran-label_oo_update_mode = 'Verbuchungsmodus'.
  text_tran-label_transaction    = 'Transaktion'.
  text_tran-label_transaction_variant = 'Transaktionsvariante'.
  text_tran-label_skip_init_screen    = 'Einstiegsbild #berspringen'.

  text_tabu-txt_maint_node = 'Pflegen Sie die Eintr#ge f#r den Knoten:'.
* Anweisungen der unterst#tzten Objekttypen
  text_devc-inst_devc = 'Run TCODE SE80 und geben in Repository Browser, w#hlen Sie'' Paket'' von Dropdown-Liste' &
            'Input Paket Namen, klicken Sie auf'' Ja'' in der Pop-up-Dialogfeld Input notwendiges Attribut-Werte entsprechend der Dokumentation und sparen.'.
  text_devc-inst_devp = 'Run TCODE SE21, Eingang Package-Namen in der unten aufgef#hrt ist, klicken'' #ndern'' Knopf, klicken Sie auf ''Use Zugriffe Registerkarte auf'' Erstellen'' Knopf,' &&
            'Input Paketschnittstelle Namen und Fehlerschwere entsprechend der Dokumentation und sparen.'.
  text_devc-inst_pinf = 'Run TCODE SE21, Eingang Package-Namen in der unten aufgef#hrt ist, klicken'' #ndern'' Knopf, klicken Sie auf ''Paketschnittstellen Registerkarte, klicken Sie auf'' Add'' Knopf,' &&
            'Input Paketschnittstelle Namen und eine kurze Beschreibung nach Dokumentation und sparen.'.
  text_devc-inst_devp_sub = 'Klicken Sie auf ''Use Zugriffe Registerkarte auf'' Erstellen'' Knopf,' &&
            'Input Paketschnittstelle Namen und Fehlerschwere entsprechend der Dokumentation und sparen.'.
  text_devc-inst_pinf_sub = 'Klicken Sie auf ''''Paketschnittstellen Registerkarte, klicken Sie auf'' Add'' Knopf,' &
            'Input Paketschnittstelle Namen und eine kurze Beschreibung nach Dokumentation und sparen.'.
  text_fugr-inst_fugr = 'Select-Paket, wo Funktion Gruppe erstellt werden soll, rechte Maustaste> Create-> Funktion Group, Eingang Attributwerte und sparen.'.
  text_fugr-inst_fugt = 'Select Funktion Gruppe und klicken Sie rechts-> #ndern Eingang Attributwerte und sparen.'.
  text_doma-inst_doma = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Domain'', Eingang Domain-Namen, klicken Sie auf'' Erstellen'' Knopf, Eingang Attributwerte, dann speichern und zu aktivieren.'.
  text_dtel-inst_dtel = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Datentyp'', Eingabedaten Element Name, auf'' Erstellen'' Knopf,' &
                        'W#hlen Radiokasten'' Datenelement'', Eingang Attributwerte, dann speichern und zu aktivieren.'.
  text_tabl-inst_tabl = 'Run TCODE SE11, f#r Datenbank-Tabelle, w#hlen Sie Radio-Box ''Database Tabelle'', Eingabe-Tabelle ein, klicken Sie ''erstellen'' Knopf,' &&
                        'Halten die Attribute, Felder, technischen Einstellungen, Indizes und etc.' &
                        'F#r Struktur, w#hlen Sie Radio-Box ''Datentyp'', Input-Struktur name, ' &&
                        'Klick '''' erstellen, w#hlen Sie Radio-Box'' Struktur'', Eingang Attributwerte, dann speichern und zu aktivieren. '.
  text_tabl-inst_tabd = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Datenbank'' Tisch, Eingang Tabelle / Struktur Namen, auf'' #ndern'' Knopf, pflegen Sie die Attribute, dann speichern und zu aktivieren.'.
  text_view-inst_view = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Ansicht'', Eingang Ansicht Name, klicken Sie auf'' Erstellen'' Knopf, ' &&
                        'w#hlen Sie die Ansicht Typ, pflegen Attribute, Tisch / Join-Bedingungen,' &
                        'View Felder, Selection AGB, Status-und Wa. etc, dann speichern und zu aktivieren.'.
  text_view-inst_vied = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Ansicht'', Eingang Ansicht Name, klicken Sie auf'' #ndern'' Knopf, pflegen Attribute, Tisch / Join-Bedingungen,' &
                        'View Felder, Selection AGB, Status-und Wa. etc, dann speichern und zu aktivieren.'.

  text_shlp-inst_shlp = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Suchhilfe'', Eingang Suchhilfe Namen, auf'' Erstellen'' Taste, w#hlen Sie die Suchhilfe Art pflegen Attribute' &
                        'Suchhilfeparameter und etc, dann speichern und zu aktivieren.'.
  text_enqu-inst_enqu = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Sperrobjektname'', Eingang Sperrobjektname auf'' Erstellen'' Knopf, pflegen Attribute' &
                        'Tische, Sperrparameter und etc, dann speichern und zu aktivieren. '.
  text_ttyp-inst_ttyp = 'Run TCODE SE11, w#hlen Sie Radio-Box'' Datentyp'', Eing#nge Typnamen auf'' Erstellen'' Knopf,' &
                        'W#hlen Radiokasten'' Table Type'', Eingang Attributwerte, dann speichern und zu aktivieren.'.
  text_tobj-inst_tobj = 'Run TCODE SE54, Eingang Pflege-View ein, w#hlen Sie Radio-Box'' generierte Objekte'' auf'' erstellen / #ndern'' Knopf,' &&
                        'W#hlen Sie'' Ja'' in den Popup-Dialogfeld zur Best#tigung, Eingang Attributwerte und klicken Sie auf die Schaltfl#che Erstellen oben, w#hlen Sie Paket nach Dokumentation und sparen.'.
  text_nrob-inst_nrob = 'Run TCODE SNRO, Eingang Nummernkreisobjekts Namen, auf'' Erstellen'' Knopf, Eingang Attributwerte und speichern, w#hlen Sie Paket nach Dokumentation.'.
  text_msag-inst_msad = 'Run TCODE SE91, Input-Message-Klasse, und klicken Sie'' erstellen'' Knopf, Eingang Attribut, Meldungen und speichern, w#hlen Sie Paket nach Dokumentation.'.
  text_msag-inst_msag = text_msag-inst_msad.
  text_msag-inst_mess = 'Run TCODE SE91, Input-Message-Klasse, und klicken Sie'' #ndern'' Knopf, pflegen Nachricht kurze Texte, ' &&
                        'f#r die Nachrichten#bertragung mit langen Text, deaktivieren Sie das Kontrollk#stchen ' &
                        '''Selbsterkl#rende'', klicken Sie dann auf Men#'' Langtext'', halten die lange Text nach der Dokumentation.'.
  text_docu-inst_docu = 'F#r Daten-Element, TCODE SE11 ausf#hren, w#hlen Sie Radio-Box ''Datentyp'', Eingabedaten Element und klicken Sie auf ''#ndern'' Knopf,' &&
                        'Klicken im Men# ''Documentation'' und pflegen die Dokumentation, wie in der unten beschrieben. <br>' &&
                        'F#r Langtext Nachricht Kurztext, TCODE SE91, Input-Message-Klasse, und klicken Sie ''#ndern'' Knopf, w#hlen Sie die Nachricht ausf#hren, deaktivieren Sie die Checkbox' &&
                        ' ''Selbsterkl#rende'', klicken Sie dann auf Men# ''Langtext'', halten die lange Text wie im Folgenden beschrieben.'.
  text_tran-inst_tran = 'Run TCODE SE93, Eingang Transaktionscode auf'' Erstellen'' Knopf, wenn' &&
                        'Input Kurztext und w#hlen Sie Start-Objekt, wenn es bereits vorhanden ist, einfach ignorieren, wenn nicht,' &
                        'Halten die Werte der Attribute und w#hlen Sie Paket nach der Dokumentation, dann speichern Sie Ihre Arbeit.'.

  DATA: lcv_inst_dat TYPE String.
  lcv_inst_dat = 'Run TCODE $CODE, Eingang $DATYPE Namen klicken'' pflegen'',' &&
          'Wenn Warnmeldung'' Achtung: Der Tisch ist Cross-client'' Pop-up,' & 'einfach best#tigen, dann f#gen Sie Eintr#ge in der Event ausw#hlen.' &&
          'Beachten Sie, dass diese Eintr#ge k#nnten abh#ngig von anderen Repository ojekte, wenn Sie nicht weiter gehen kann, versuchen,' &&
          'F#gen Sie die abh#ngigen Objekte ersten oder es wieder tun nach der Umsetzung der note.Meanwhile, haben nur die Felder einen g#ltigen Wert muss ' &&
          'Aufgef#hrt zu erhalten, das hei#t, Sie don'' t m#ssen #ber andere Felder zu k#mmern.'.
  text_tabu-inst_cdat = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_cdat WITH 'SM34'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_cdat WITH 'Viewclusters'.

  text_tabu-inst_vdat = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_vdat WITH 'SM30'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_vdat WITH 'Pflege-View'.

  text_tabu-inst_tabu = lcv_inst_dat.
  REPLACE FIRST OCCURRENCE OF '$CODE' IN text_tabu-inst_tabu WITH 'SM30'.
  REPLACE FIRST OCCURRENCE OF '$DATYPE' IN text_tabu-inst_tabu WITH 'table'.
ENDFORM.

FORM init_object_instructions.
  PERFORM append_instruction USING 'DEVC' text_devc-inst_devc.
  PERFORM append_instruction USING 'DEVP' text_devc-inst_devp.
  PERFORM append_instruction USING 'PINF' text_devc-inst_pinf.
  PERFORM append_instruction USING 'FUGR' text_fugr-inst_fugr.
  PERFORM append_instruction USING 'FUGR' text_fugr-inst_fugt.
  PERFORM append_instruction USING 'DOMA' text_doma-inst_doma.
  PERFORM append_instruction USING 'DTEL' text_dtel-inst_dtel.
  PERFORM append_instruction USING 'TABL' text_tabl-inst_tabl.
  PERFORM append_instruction USING 'TABD' text_tabl-inst_tabd.
  PERFORM append_instruction USING 'VIEW' text_view-inst_view.
  PERFORM append_instruction USING 'VIED' text_view-inst_vied.
  PERFORM append_instruction USING 'SHLP' text_shlp-inst_shlp.
  PERFORM append_instruction USING 'ENQU' text_enqu-inst_enqu.
  PERFORM append_instruction USING 'TTYP' text_ttyp-inst_ttyp.
  PERFORM append_instruction USING 'TOBJ' text_tobj-inst_tobj.
  PERFORM append_instruction USING 'VCLS' text_tabl-inst_tabd.
  PERFORM append_instruction USING 'NROB' text_nrob-inst_nrob.
  PERFORM append_instruction USING 'DOCU' text_docu-inst_docu.
  PERFORM append_instruction USING 'MSAD' text_msag-inst_msad.
  PERFORM append_instruction USING 'MSAG' text_msag-inst_msag.
  PERFORM append_instruction USING 'MESS' text_msag-inst_mess.
  PERFORM append_instruction USING 'TRAN' text_tran-inst_tran.
  PERFORM append_instruction USING 'CDAT' text_tabu-inst_cdat.
  PERFORM append_instruction USING 'VDAT' text_tabu-inst_vdat.
  PERFORM append_instruction USING 'TABU' text_tabu-inst_tabu.
ENDFORM.

FORM append_instruction USING iv_object TYPE trobjtype iv_txt TYPE string.
  DATA: ls_inst TYPE s_object_instruction.

  ls_inst-object = iv_object.
  ls_inst-instruction = iv_txt.

  READ TABLE gt_object_instruction WITH TABLE KEY object = iv_object TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  INSERT ls_inst INTO TABLE gt_object_instruction.
ENDFORM.
***************** i18n End *****************
*&---------------Common Routines & UI Logic & HTML Ultility & Upload & Code Helper---------------*
FORM f4_request.
  DATA: ls_selected_request TYPE trwbo_request_header,
        lv_organizer_type   TYPE trwbo_calling_organizer VALUE 'W',
        ls_selection        TYPE trwbo_selection.

  ls_selection-reqstatus = 'R'.
  CALL FUNCTION 'TR_PRESENT_REQUESTS_SEL_POPUP'
    EXPORTING
      iv_organizer_type   = lv_organizer_type
      is_selection        = ls_selection
    IMPORTING
      es_selected_request = ls_selected_request.

  so_trans-low = ls_selected_request-trkorr.
ENDFORM.

FORM f4_exclude_objects.
  DATA: lt_objects TYPE TABLE OF s_obj_header,
        lt_ddsh    TYPE TABLE OF ddshretval.

  PERFORM collect_objects_header_in_tr CHANGING lt_objects.
  CHECK lt_objects IS NOT INITIAL.
  SORT lt_objects BY object obj_name ASCENDING.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'OBJ_NAME'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'SO_EXCLU'
      value_org       = 'S'
      display         = 'F'
    TABLES
      value_tab       = lt_objects
      return_tab      = lt_ddsh
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.

FORM select_download_dir CHANGING cv_dir TYPE string.
  cl_gui_frontend_services=>directory_browse(
    CHANGING
      selected_folder      =     cv_dir
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4
      ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.

FORM select_transport_file CHANGING cv_file TYPE string.
  DATA: lv_desktop_path TYPE string,
        lt_filetable    TYPE filetable,
        lv_user_action  TYPE i,
        lv_msg          TYPE string,
        lv_rc           TYPE i.

  cl_gui_frontend_services=>get_desktop_directory(
    CHANGING
      desktop_directory = lv_desktop_path
    ).

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      default_extension       = '*.zip'                     "#EC NOTEXT
      initial_directory       = lv_desktop_path
      file_filter             = cl_gui_frontend_services=>filetype_all
      multiselection          = abap_false
    CHANGING
      file_table              = lt_filetable
      user_action             = lv_user_action
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5
    ).

  IF sy-subrc EQ 0.
    READ TABLE lt_filetable INDEX 1 INTO cv_file.
  ELSE.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_msg.
    MESSAGE e208(00) WITH lv_msg.
  ENDIF.
ENDFORM.

FORM scenario_switch.
  DATA: lv_hide_id1 TYPE c LENGTH 3,
        lv_hide_id2 TYPE c LENGTH 3.

  IF export EQ abap_true.
    lv_hide_id1 = 'IMP'.
    lv_hide_id2 = 'COD'.
  ELSEIF import EQ abap_true.
    lv_hide_id1 = 'EXP'.
    lv_hide_id2 = 'COD'.
  ELSEIF code EQ abap_true.
    lv_hide_id1 = 'EXP'.
    lv_hide_id2 = 'IMP'.
  ENDIF.

  LOOP AT SCREEN.
    IF screen-group1 EQ lv_hide_id1 OR screen-group1 EQ lv_hide_id2.
      screen-active = '0'.
      screen-invisible = '1'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM validate_params CHANGING cv_msg TYPE string.
  CLEAR cv_msg.

  IF export EQ abap_true.
    IF so_trans IS INITIAL.
      cv_msg = 'Please select transport request'.
      RETURN.
    ELSE.
      DATA: lt_e070 TYPE TABLE OF e070,
            ls_e070 TYPE e070.

      SELECT * FROM e070 INTO TABLE lt_e070 WHERE trkorr IN so_trans AND trstatus EQ 'R' ORDER BY as4date ASCENDING.
      LOOP AT so_trans.
        READ TABLE lt_e070 WITH KEY trkorr = so_trans-low TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0.
          CONCATENATE 'Request ' so_trans-low ' does not exist or is not released yet.' INTO cv_msg RESPECTING BLANKS.
          RETURN.
        ENDIF.
      ENDLOOP.

      READ TABLE lt_e070 INTO ls_e070 INDEX 1.
      gv_tr_date = ls_e070-as4date.
    ENDIF.

    IF p_dir IS INITIAL.
      cv_msg = 'Please select export folder'.
      RETURN.
    ENDIF.

    IF p_doc IS INITIAL.
      cv_msg = 'Please input document title'.
      RETURN.
    ENDIF.
  ENDIF.

  IF import EQ abap_true.
    IF p_file IS INITIAL.
      cv_msg = 'Please upload a transport zip file'.
      RETURN.
    ELSE.
      PERFORM check_transport_zip CHANGING cv_msg.
      IF cv_msg IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.

  IF code EQ abap_true.
    DATA: lv_confirm_msg TYPE string,
          lv_answer      TYPE c.

    CLEAR gt_objtype2codes.

    LOOP AT so_objt.
      READ TABLE gt_ko100 WITH TABLE KEY object = so_objt-low TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        CONCATENATE so_objt-low ' is a invalid object type, please check it.' INTO cv_msg RESPECTING BLANKS.
        RETURN.
      ENDIF.

      READ TABLE gt_objtype_desc WITH TABLE KEY object = so_objt-low TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CONCATENATE 'Object Type ' so_objt-low ' has been supported already, do you still want to print code template?'
          INTO lv_confirm_msg RESPECTING BLANKS.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            text_question = lv_confirm_msg
          IMPORTING
            answer        = lv_answer.

        IF lv_answer EQ '1'.
          APPEND so_objt-low TO gt_objtype2codes.
        ENDIF.
        CLEAR lv_confirm_msg.
      ELSE.
        APPEND so_objt-low TO gt_objtype2codes.
      ENDIF.
    ENDLOOP.

    IF gt_objtype2codes IS INITIAL.
      cv_msg = 'Please select at least one valid object type'.
      RETURN.
    ENDIF.
  ENDIF.
ENDFORM.

FORM response.
  DATA: lv_msg   TYPE string,
        lv_start TYPE i,
        lv_end   TYPE i,
        lv_str   TYPE string,
        lv_cost  TYPE p DECIMALS 2,
        lv_file  TYPE string.

  PERFORM validate_params CHANGING lv_msg.
  IF lv_msg IS NOT INITIAL.
    MESSAGE s208(00) WITH lv_msg.
    RETURN.
  ENDIF.

  GET RUN TIME FIELD lv_start.
  IF export EQ abap_true.
    PERFORM prepare_html_head.
    PERFORM prepare_html_body.
    IF gt_html IS NOT INITIAL.
      APPEND LINES OF gt_html TO gt_html_all.
      PERFORM prepare_html_tail.
      PERFORM export_docu CHANGING lv_file.
    ENDIF.
    IF p_bin EQ abap_true.
      PERFORM export_transport_files.
    ENDIF.

    CHECK p_test NE abap_true.
    PERFORM display_result.
    PERFORM open_html_in_msword USING lv_file.
  ENDIF.

  IF import EQ abap_true.
    PERFORM upload_transport_files.
  ENDIF.

  IF code EQ abap_true.
    PERFORM initialize_code_template.
    PERFORM print_template_codes.
  ENDIF.

  CHECK p_test NE abap_true.

  GET RUN TIME FIELD lv_end.
  lv_cost = ( lv_end - lv_start ) / 1000000.
  lv_str = lv_cost.
  lv_msg = text_common-time_cost.
  REPLACE FIRST OCCURRENCE OF '$TIME' IN lv_msg WITH lv_str.
  WRITE: / icon_time AS ICON, lv_msg.
ENDFORM.
FORM export_transport_files.
  DATA: lv_zip TYPE xstring,
        lt_str TYPE solix_tab,
        lv_msg TYPE string,
        lv_err_cnt     TYPE i,
        lv_zipfilename TYPE string.

  IF go_zip IS NOT BOUND.
    CREATE OBJECT go_zip.
  ENDIF.

  LOOP AT so_trans.
    PERFORM add_single_transport USING so_trans-low CHANGING lv_msg.
    IF lv_msg IS NOT INITIAL.
      PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
      ADD 1 TO lv_err_cnt.
    ENDIF.
    CONCATENATE lv_zipfilename '_' so_trans-low INTO lv_zipfilename.
  ENDLOOP.

  IF lv_err_cnt GT 0.
    RETURN.
  ENDIF.
  SHIFT lv_zipfilename.
  CONCATENATE p_dir gv_slash lv_zipfilename '.zip' INTO lv_zipfilename RESPECTING BLANKS.

  lv_zip = go_zip->save( ).
  lt_str = cl_bcs_convert=>xstring_to_solix( iv_xstring  = lv_zip ).
  PERFORM download_file USING 'BIN' lv_zipfilename CHANGING lv_msg lt_str.
  IF lv_msg IS NOT INITIAL.
    PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
  ENDIF.
ENDFORM.

FORM add_single_transport USING iv_tr TYPE e070-trkorr CHANGING cv_msg TYPE string.
  DATA: server_file_k TYPE rlgrap-filename,
        server_file_r TYPE rlgrap-filename,
        lv_tr_no      TYPE e070-trkorr,
        lv_filename   TYPE string,
        lv_slah       TYPE c.

  CLEAR cv_msg.
  lv_slah = gv_trans_dir(1).
  lv_tr_no = iv_tr.
  SHIFT lv_tr_no BY 4 PLACES LEFT.

  " SI3K017810-> K017810.SI3 & R017810.SI3
  CONCATENATE 'K' lv_tr_no '.' so_trans-low(3) INTO lv_filename.
  CONCATENATE gv_trans_dir lv_slah 'cofiles' lv_slah  lv_filename INTO server_file_k. "#EC NOTEXT
  PERFORM add2zip USING lv_filename server_file_k CHANGING cv_msg.
  CLEAR lv_filename.
  IF cv_msg IS NOT INITIAL.
    EXIT.
  ENDIF.

  CONCATENATE 'R' lv_tr_no '.' so_trans-low(3) INTO lv_filename.
  CONCATENATE gv_trans_dir lv_slah 'data' lv_slah lv_filename INTO server_file_r. "#EC NOTEXT
  PERFORM add2zip USING lv_filename server_file_r CHANGING cv_msg.
  IF cv_msg IS NOT INITIAL.
    RETURN.
  ENDIF.
ENDFORM.

FORM add2zip USING iv_filename TYPE string iv_server_file TYPE rlgrap-filename CHANGING cv_msg TYPE string.
  DATA: l_data     TYPE STANDARD TABLE OF tbl1024,
        l_size     TYPE i,
        lv_xstr    TYPE xstring.

  CALL FUNCTION 'SCMS_UPLOAD'
    EXPORTING
      filename = iv_server_file
      binary   = 'X'
      frontend = ' '
    IMPORTING
      filesize = l_size
    TABLES
      data     = l_data
    EXCEPTIONS
      error    = 1
      OTHERS   = 2.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO cv_msg.
    PERFORM append_common_msg USING 'E' cv_msg CHANGING gt_sys_msg.
    RETURN.
  ENDIF.

  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = l_size
    IMPORTING
      buffer       = lv_xstr
    TABLES
      binary_tab   = l_data
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  go_zip->add( name = iv_filename content = lv_xstr ).
ENDFORM.
FORM prepare_html_body.
  DATA: lt_object_header TYPE TABLE OF s_obj_header,
        ls_tadir         TYPE tadir,
        lv_subroutine    TYPE string.

  FIELD-SYMBOLS: <fs_object_header> TYPE s_obj_header,
                 <fs_objtype_order> TYPE s_objtype_order.

  PERFORM collect_objects_header_in_tr CHANGING lt_object_header.
  LOOP AT lt_object_header ASSIGNING <fs_object_header>.
    READ TABLE so_exclu WITH KEY low = <fs_object_header>-obj_name TRANSPORTING NO FIELDS.
    IF sy-subrc EQ 0.
      DELETE lt_object_header.
      CONTINUE.
    ENDIF.

    READ TABLE gt_objtype_order WITH TABLE KEY object = <fs_object_header>-object ASSIGNING <fs_objtype_order>.
    <fs_object_header>-primary_sort = <fs_objtype_order>-sort_no.
  ENDLOOP.
  CHECK lt_object_header IS NOT INITIAL.

  SORT lt_object_header BY primary_sort obj_name.

  LOOP AT lt_object_header ASSIGNING <fs_object_header>.
    SELECT SINGLE * FROM tadir INTO ls_tadir WHERE pgmid = <fs_object_header>-pgmid
      AND object = <fs_object_header>-object AND obj_name = <fs_object_header>-obj_name.
    IF sy-subrc EQ 0.
      <fs_object_header>-devclass = ls_tadir-devclass.
    ENDIF.
    " set activity 'Create' as default value, change mode will be detected in routine GETDATA_{objtype} if possible
    <fs_object_header>-activity = gcv_act_create.
    CONCATENATE 'GETDATA_' <fs_object_header>-object INTO lv_subroutine. "#EC NOTEXT
    PERFORM (lv_subroutine) IN PROGRAM (sy-repid) USING <fs_object_header> IF FOUND.
    CLEAR lv_subroutine.

    AT END OF object.
      " usually abstract routine can cover 80% of the case, however 20% are special and need to handle separately
      " so we will try to call subroutine of special case first and then fall back to common mode
      TRY.
          CONCATENATE 'CONVERT_' <fs_object_header>-object INTO lv_subroutine. "#EC NOTEXT
          PERFORM (lv_subroutine) IN PROGRAM (sy-repid).
        CATCH cx_sy_dyn_call_illegal_form.
          PERFORM convert_obj_abstract USING <fs_object_header>-object.
      ENDTRY.
    ENDAT.
  ENDLOOP.
ENDFORM.

* abstract subroutine for all kinds of objects
* for a collection of objects with same kind, the rendering html should be build in the steps below:
* 1.get header html
* 2.render each object in same format
FORM convert_obj_abstract USING iv_objtype TYPE trobjtype.
  DATA: lv_cnt  TYPE i,
        lv_tab  TYPE string,
        lt_html TYPE TABLE OF string.
  FIELD-SYMBOLS: <fs_t_obj>       TYPE STANDARD TABLE,
                 <fs_obj>         TYPE any,
                 <fs_sec_sort>    TYPE any.

  CONCATENATE '(' sy-repid ')GT_' iv_objtype INTO lv_tab.
  ASSIGN (lv_tab) TO <fs_t_obj>.
  CHECK <fs_t_obj> IS ASSIGNED AND <fs_t_obj> IS NOT INITIAL.

  ADD 1 TO gv_header_no.
  lv_cnt  = lines( <fs_t_obj> ).
  PERFORM add_header_html USING iv_objtype CHANGING lt_html.
  PERFORM add_object_instruction_html USING iv_objtype CHANGING lt_html.

  LOOP AT <fs_t_obj> ASSIGNING <fs_obj>.
    ASSIGN COMPONENT 'SECONDARY_SORT' OF STRUCTURE <fs_obj> TO <fs_sec_sort>.
    IF <fs_sec_sort> IS ASSIGNED.
      <fs_sec_sort> = sy-tabix.
    ENDIF.
    PERFORM get_single_obj_html_abstract USING <fs_obj> lv_cnt CHANGING lt_html.

    UNASSIGN <fs_sec_sort>.
  ENDLOOP.
  UNASSIGN <fs_obj>.
  APPEND LINES OF lt_html TO gt_html.
ENDFORM.

FORM add_object_instruction_html USING iv_object TYPE trobjtype CHANGING ct_html TYPE t_string.
  FIELD-SYMBOLS <fs_instruction> TYPE s_object_instruction.

  READ TABLE gt_object_instruction ASSIGNING <fs_instruction> WITH TABLE KEY object = iv_object.
  IF <fs_instruction> IS ASSIGNED AND <fs_instruction>-instruction IS NOT INITIAL.
    PERFORM get_paragraph_html USING <fs_instruction>-instruction CHANGING ct_html.
    APPEND '<br>' TO ct_html.
  ENDIF.
ENDFORM.

* abstract subroutine as a template pattern for all kinds of objects to implement
* for a single object, the rendering html should be built in the steps below:
* 1.get title html
* 2.get basic attributes and always are obj_name, devclass, short_text
* 3.get additional attributes, for example, for package, its application component, software component and etc
* 4.get special attributes, for example, for table, its fields, technical settings, foreign key settings and etc
* To keep things simple, name convention should be followed like this:
* GET_ADDITIONAL_HTML_{objtype}
* GET_SPECIAL_HTML_{objtype}
FORM get_single_obj_html_abstract USING is_obj TYPE any iv_cnt TYPE i CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_form_addi  TYPE string,
        lv_form_spec  TYPE string,
        ls_obj_header TYPE s_obj_header.
  FIELD-SYMBOLS <fs_objtype_order> TYPE s_objtype_order.

  MOVE-CORRESPONDING is_obj TO ls_obj_header.
  CONCATENATE 'GET_ADDITIONAL_HTML_' ls_obj_header-object INTO lv_form_addi.
  CONCATENATE 'GET_SPECIAL_HTML_' ls_obj_header-object INTO lv_form_spec.

  PERFORM add_title_html USING is_obj iv_cnt CHANGING ct_html.
  READ TABLE gt_objtype_order WITH TABLE KEY object = ls_obj_header-object ASSIGNING <fs_objtype_order>.
  IF <fs_objtype_order>-show_basic_attr EQ abap_true.
    APPEND gcv_table_begin TO ct_html.
    PERFORM get_basic_attr_html USING ls_obj_header CHANGING ct_html.
    PERFORM (lv_form_addi) IN PROGRAM (sy-repid) USING is_obj CHANGING ct_html IF FOUND.
    APPEND gcv_table_end TO ct_html.
    APPEND '<br>' TO ct_html.
  ENDIF.

  PERFORM (lv_form_spec) IN PROGRAM (sy-repid) USING is_obj CHANGING ct_html IF FOUND.
  PERFORM add_obj_gen_msg USING ls_obj_header 'S' ''.
ENDFORM.

FORM get_basic_attr_html USING is_obj_header TYPE s_obj_header CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM get_default2column_html CHANGING ct_html.
  " basic attributes of maintenance object is of little value
  CHECK is_obj_header-object NE 'TOBJ'.
  DATA lv_fields TYPE string VALUE 'OBJ_NAME|SHORT_TEXT'.
  IF is_obj_header-object NE 'DEVC' AND is_obj_header-object NE 'FUGT'.
    CONCATENATE lv_fields '|' 'DEVCLASS' INTO lv_fields.
  ENDIF.
  PERFORM data2rows USING is_obj_header 'S_OBJ_HEADER' lv_fields CHANGING ct_html.
ENDFORM.

FORM get_objtype_desc USING iv_objtype TYPE trobjtype CHANGING cv_str TYPE ko100-text.
  DATA: ls_ko100 TYPE ko100.
  READ TABLE gt_objtype_desc INTO ls_ko100 WITH TABLE KEY object = iv_objtype.
  CLEAR cv_str.
  " TOBJ: Definition of a Maintenance and Transport Object -> might be confusing to customer
  IF iv_objtype EQ 'TOBJ'.
    cv_str = text_common-title_tobj.
  ELSE.
    cv_str = ls_ko100-text.
  ENDIF.
ENDFORM.

FORM add_header_html USING iv_objtype TYPE trobjtype CHANGING ct_html TYPE t_string.
  DATA: lv_html   TYPE string,
        lv_desc   TYPE ddtext,
        lv_no_str TYPE string.

  lv_html = gcv_header_html.
  PERFORM format_numc USING gv_header_no CHANGING lv_no_str.
  REPLACE FIRST OCCURRENCE OF '$HEADER_NO' IN lv_html WITH lv_no_str.
  PERFORM get_objtype_desc USING iv_objtype CHANGING lv_desc.
  REPLACE FIRST OCCURRENCE OF '$OBJECT_DESC' IN lv_html WITH lv_desc.

  APPEND lv_html TO ct_html.
ENDFORM.

FORM add_title_html USING is_obj TYPE any iv_cnt TYPE i CHANGING ct_html TYPE t_string.
  DATA: lv_no1 TYPE string,
        lv_no2 TYPE string,
        lv_desc TYPE ddtext,
        ls_obj_header TYPE s_obj_header,
        lv_title_no TYPE string,
        lv_html TYPE string VALUE gcv_title_html.

  MOVE-CORRESPONDING is_obj TO ls_obj_header.
  IF iv_cnt EQ 1.
    REPLACE FIRST OCCURRENCE OF '$TITLE_NO' IN lv_html WITH ''.
  ELSE.
    PERFORM format_numc USING gv_header_no CHANGING lv_no1.
    PERFORM format_numc USING ls_obj_header-secondary_sort CHANGING lv_no2.
    CONCATENATE lv_no1 '.' lv_no2 ' ' INTO lv_title_no RESPECTING BLANKS.
    REPLACE FIRST OCCURRENCE OF '$TITLE_NO' IN lv_html WITH lv_title_no.
  ENDIF.

  PERFORM get_title_objtype_desc USING ls_obj_header-object is_obj CHANGING lv_desc.
  REPLACE FIRST OCCURRENCE OF '$ACTIVITY' IN lv_html WITH ls_obj_header-activity.
  REPLACE FIRST OCCURRENCE OF '$OBJECT_DESC' IN lv_html WITH lv_desc.
  REPLACE FIRST OCCURRENCE OF '$OBJ_NAME' IN lv_html WITH ls_obj_header-obj_name.
  APPEND lv_html TO ct_html.
ENDFORM.

* some object type has sub category and we need to get that
FORM get_objtype_desc_deep USING is_obj_header TYPE s_obj_header CHANGING cv_desc TYPE string.
  DATA: lv_desc TYPE ddtext,
        lv_len  TYPE i.

  CASE is_obj_header-object.
    WHEN 'TABL'.
      DATA ls_tabl TYPE s_tabl.
      READ TABLE gt_tabl INTO ls_tabl WITH KEY obj_name = is_obj_header-obj_name BINARY SEARCH.
      PERFORM get_title_objtype_desc USING is_obj_header-object ls_tabl CHANGING lv_desc.
    WHEN 'VIEW'.
      DATA ls_view TYPE s_view.
      READ TABLE gt_view INTO ls_view WITH KEY obj_name = is_obj_header-obj_name BINARY SEARCH.
      PERFORM get_title_objtype_desc USING is_obj_header-object ls_view CHANGING lv_desc.
    WHEN OTHERS.
      PERFORM get_objtype_desc USING is_obj_header-object CHANGING lv_desc.
  ENDCASE.

  CLEAR cv_desc.
  CHECK lv_desc IS NOT INITIAL.
  lv_len = strlen( lv_desc ).
  cv_desc = lv_desc(lv_len).
ENDFORM.

FORM get_title_objtype_desc USING iv_objtype TYPE trobjtype is_obj TYPE any CHANGING cv_desc TYPE ddtext.
  DATA: lv_low TYPE ddfixvalue-low.
  FIELD-SYMBOLS <fs_value> TYPE any.

  CLEAR cv_desc.
  IF iv_objtype EQ 'TABL'.
    ASSIGN COMPONENT 'TABCLASS' OF STRUCTURE is_obj TO <fs_value>.
    IF <fs_value> IS ASSIGNED.
      lv_low = <fs_value>.
      PERFORM get_value_desc USING 'TABCLASS' lv_low CHANGING cv_desc.
    ENDIF.
  ELSEIF iv_objtype EQ 'VIEW'.
    ASSIGN COMPONENT 'VIEWCLASS' OF STRUCTURE is_obj TO <fs_value>.
    IF <fs_value> IS ASSIGNED.
      lv_low = <fs_value>.
      PERFORM get_value_desc USING 'VIEWCLASS' lv_low CHANGING cv_desc.
    ENDIF.
  ELSE.
    PERFORM get_objtype_desc USING iv_objtype CHANGING cv_desc.
  ENDIF.
ENDFORM.

FORM get_small_title_html USING iv_small_title TYPE string CHANGING ct_html TYPE t_string.
  DATA lv_html TYPE string VALUE gcv_small_title_html.
  REPLACE FIRST OCCURRENCE OF '$TITLE' IN lv_html WITH iv_small_title.
  APPEND lv_html TO ct_html.
ENDFORM.

FORM get_paragraph_html  USING iv_para TYPE string CHANGING ct_html TYPE t_string.
  DATA lv_html TYPE string VALUE gcv_paragraph_html.
  REPLACE FIRST OCCURRENCE OF '$PARAGRAPH' IN lv_html WITH iv_para.
  APPEND lv_html TO ct_html.
ENDFORM.

FORM get_column_label_html USING iv_label TYPE any CHANGING cv_td TYPE string.
  CLEAR cv_td.
  cv_td = gcv_td_label.
  REPLACE FIRST OCCURRENCE OF '$LABEL' IN cv_td WITH iv_label.
ENDFORM.

FORM get_tr_label_html USING iv_labels TYPE string CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_td TYPE string,
        lv_tr TYPE string,
        lt_labels TYPE TABLE OF string.
  FIELD-SYMBOLS: <fs_label> TYPE string.

  SPLIT iv_labels AT '|' INTO TABLE lt_labels.

  lv_tr = '<tr>'.
  LOOP AT lt_labels ASSIGNING <fs_label>.
    CHECK <fs_label> IS NOT INITIAL.
    CONDENSE <fs_label>.
    PERFORM get_column_label_html USING <fs_label> CHANGING lv_td.
    CONCATENATE lv_tr lv_td INTO lv_tr RESPECTING BLANKS.
  ENDLOOP.
  CONCATENATE lv_tr '</tr>' INTO lv_tr RESPECTING BLANKS.
  APPEND lv_tr TO ct_html.
ENDFORM.

FORM get_column_value_html USING iv_value TYPE any CHANGING cv_td TYPE string.
  DATA: lv_str   TYPE string,
        lo_descr TYPE REF TO cl_abap_datadescr.

  lo_descr ?= cl_abap_typedescr=>describe_by_data( iv_value ).
  IF lo_descr IS BOUND AND lo_descr->type_kind EQ 'N'.
    PERFORM format_numc USING iv_value CHANGING lv_str.
  ELSE.
    lv_str = iv_value.
  ENDIF.

  CLEAR cv_td.
  cv_td = gcv_td_content.
  REPLACE FIRST OCCURRENCE OF '$VALUE' IN cv_td WITH lv_str.
ENDFORM.

FORM get_column_innertable_html USING iv_value TYPE any CHANGING cv_td TYPE string.
  DATA lv_str TYPE string.
  lv_str = iv_value.

  CLEAR cv_td.
  cv_td = gcv_td_inner_table.
  REPLACE FIRST OCCURRENCE OF '$VALUE' IN cv_td WITH lv_str.
ENDFORM.

FORM get_default2column_html CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM get_2column_label_html USING text_common-label_col_attr text_common-label_col_value CHANGING ct_html.
ENDFORM.

FORM get_2column_label_html USING iv_label1 TYPE string iv_label2 TYPE string CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_td1 TYPE string,
        lv_td2 TYPE string.

  PERFORM get_column_label_html USING iv_label1 CHANGING lv_td1.
  PERFORM get_column_label_html USING iv_label2 CHANGING lv_td2.
  PERFORM combine2td USING lv_td1 lv_td2 CHANGING ct_html.
ENDFORM.

FORM get_2column_right_table_html USING iv_label1 TYPE string iv_inner_table_html TYPE string CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_td1 TYPE string,
        lv_td2 TYPE string.

  PERFORM get_column_value_html USING iv_label1 CHANGING lv_td1.
  PERFORM get_column_innertable_html USING iv_inner_table_html CHANGING lv_td2.
  PERFORM combine2td USING lv_td1 lv_td2 CHANGING ct_html.
ENDFORM.

FORM get_2column_value_html USING iv_label TYPE any iv_value TYPE any CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_td1 TYPE string,
        lv_td2 TYPE string.

  PERFORM get_column_value_html USING iv_label CHANGING lv_td1.
  PERFORM get_column_value_html USING iv_value CHANGING lv_td2.
  PERFORM combine2td USING lv_td1 lv_td2 CHANGING ct_html.
ENDFORM.

FORM combine2td USING iv_td1 TYPE string iv_td2 TYPE string  CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_tr TYPE string.
  CONCATENATE '<tr>' iv_td1 iv_td2  '</tr>' INTO lv_tr RESPECTING BLANKS.
  APPEND lv_tr TO ct_html.
  CLEAR lv_tr.
ENDFORM.

FORM combine3td USING iv_td1 TYPE string iv_td2 TYPE string iv_td3 TYPE string  CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_tr TYPE string.
  CONCATENATE '<tr>' iv_td1 iv_td2 iv_td3  '</tr>' INTO lv_tr RESPECTING BLANKS.
  APPEND lv_tr TO ct_html.
  CLEAR lv_tr.
ENDFORM.

FORM join_str USING it_tab TYPE t_string CHANGING cv_str TYPE string.
  CLEAR cv_str.

  FIELD-SYMBOLS: <fs_str> TYPE string.
  LOOP AT it_tab ASSIGNING <fs_str>.
    CONCATENATE cv_str <fs_str> INTO cv_str RESPECTING BLANKS.
  ENDLOOP.
ENDFORM.

FORM table2tr USING iv_label TYPE string it_tab TYPE STANDARD TABLE iv_stru TYPE any iv_fldnames TYPE string CHANGING ct_html TYPE t_string.
  DATA: lv_td1 TYPE string,
        lv_td2 TYPE string,
        lv_tmp TYPE string,
        lt_tab TYPE TABLE OF string.

  PERFORM get_column_value_html USING iv_label CHANGING lv_td1.
  PERFORM convert_table_html USING '' it_tab iv_stru iv_fldnames abap_false '' abap_true CHANGING lt_tab.
  PERFORM join_str USING lt_tab CHANGING lv_tmp.
  PERFORM get_column_innertable_html USING lv_tmp CHANGING lv_td2.

  PERFORM combine2td USING lv_td1 lv_td2 CHANGING ct_html.
ENDFORM.

FORM convert_table_html USING iv_title TYPE string it_tab TYPE STANDARD TABLE iv_stru TYPE any
                              iv_fldnames TYPE string iv_remove TYPE abap_bool iv_remove_flds TYPE string
                              iv_innertable  TYPE abap_bool
                        CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lt_used_ddic TYPE ddfields,
        lv_tr        TYPE string,
        lv_td        TYPE string,
        lv_txt       TYPE ddtext.
  FIELD-SYMBOLS: <fs_ddic>  TYPE dfies,
                 <fs_row>   TYPE any,
                 <fs_value> TYPE any.

  CHECK it_tab IS NOT INITIAL.
  PERFORM get_used_ddfields USING iv_stru iv_fldnames CHANGING lt_used_ddic.
  CHECK sy-subrc EQ 0.

  IF iv_remove EQ abap_true.
    PERFORM remove_no_need_fields USING it_tab iv_remove_flds CHANGING lt_used_ddic.
  ENDIF.

  IF iv_title IS NOT INITIAL.
    PERFORM get_small_title_html USING iv_title CHANGING ct_html.
  ENDIF.

  APPEND gcv_table_begin TO ct_html.
  PERFORM get_table_head_html USING lt_used_ddic CHANGING lv_tr.
  APPEND lv_tr TO ct_html.

  LOOP AT it_tab ASSIGNING <fs_row>.
    lv_tr = '<tr>'.

    LOOP AT lt_used_ddic ASSIGNING <fs_ddic>.
      ASSIGN COMPONENT <fs_ddic>-fieldname OF STRUCTURE <fs_row> TO <fs_value>.
      CHECK <fs_value> IS ASSIGNED.

      PERFORM get_value_desc USING <fs_ddic>-fieldname <fs_value> CHANGING lv_txt.
      IF lv_txt IS NOT INITIAL.
        lv_txt = escape( val = lv_txt format = cl_abap_format=>e_html_text ).
        PERFORM get_column_value_html USING lv_txt CHANGING lv_td.
      ELSE.
        PERFORM get_column_value_html USING <fs_value> CHANGING lv_td.
      ENDIF.
      CONCATENATE lv_tr lv_td INTO lv_tr RESPECTING BLANKS.

      CLEAR: lv_txt.
      UNASSIGN <fs_value>.
    ENDLOOP.

    CONCATENATE lv_tr '</tr>' INTO lv_tr RESPECTING BLANKS.
    APPEND lv_tr TO ct_html.
  ENDLOOP.
  APPEND gcv_table_end TO ct_html.

  IF iv_innertable EQ abap_false.
    APPEND '<br>' TO ct_html.
  ENDIF.
ENDFORM.

FORM remove_no_need_fields USING it_tab TYPE STANDARD TABLE iv_remove_flds TYPE string CHANGING ct_ddfields TYPE ddfields.
  TYPES: BEGIN OF s_field_remain,
         fieldname TYPE fieldname,
         remain    TYPE abap_bool,
         END OF s_field_remain.
  TYPES: BEGIN OF s_field_to_check,
         fieldname TYPE fieldname,
         END OF s_field_to_check.

  DATA: lt_fld_remain TYPE HASHED TABLE OF s_field_remain WITH UNIQUE KEY fieldname,
        ls_fld_remain TYPE s_field_remain,
        lt_fldnames   TYPE TABLE OF s_field_to_check,
        lt_fld2check  TYPE HASHED TABLE OF s_field_to_check WITH UNIQUE KEY fieldname.
  FIELD-SYMBOLS: <fs_ddic>  TYPE dfies,
                 <fs_fld>   TYPE s_field_to_check,
                 <fs_row>   TYPE any,
                 <fs_value> TYPE any.

  IF iv_remove_flds IS NOT INITIAL.
    SPLIT iv_remove_flds AT '|' INTO TABLE lt_fldnames.
  ELSE.
    LOOP AT ct_ddfields ASSIGNING <fs_ddic>.
      APPEND <fs_ddic>-fieldname TO lt_fldnames.
    ENDLOOP.
  ENDIF.
  MOVE lt_fldnames TO lt_fld2check.

  LOOP AT it_tab ASSIGNING <fs_row>.
    LOOP AT lt_fldnames ASSIGNING <fs_fld>.
      ASSIGN COMPONENT <fs_fld>-fieldname OF STRUCTURE <fs_row> TO <fs_value>.
      IF <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.
        READ TABLE lt_fld_remain WITH TABLE KEY fieldname = <fs_fld>-fieldname TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.

        ls_fld_remain-fieldname = <fs_fld>-fieldname.
        ls_fld_remain-remain = abap_true.
        INSERT ls_fld_remain INTO TABLE lt_fld_remain.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

  LOOP AT ct_ddfields ASSIGNING <fs_ddic>.
    READ TABLE lt_fld2check WITH KEY fieldname = <fs_ddic>-fieldname TRANSPORTING NO FIELDS.
    CHECK sy-subrc EQ 0.

    READ TABLE lt_fld_remain WITH TABLE KEY fieldname = <fs_ddic>-fieldname TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.
    DELETE ct_ddfields.
  ENDLOOP.
ENDFORM.

FORM table2html USING iv_title TYPE string
                      it_tab   TYPE STANDARD TABLE
                      iv_stru  TYPE any
                      iv_fldnames    TYPE string
                      iv_remove      TYPE abap_bool
                      iv_remove_flds TYPE string
                CHANGING ct_html     TYPE STANDARD TABLE.
  PERFORM convert_table_html USING iv_title it_tab iv_stru iv_fldnames iv_remove iv_remove_flds abap_false CHANGING ct_html.
ENDFORM.

FORM data2rows_common USING iv_data TYPE any  iv_stru TYPE any iv_fldnames TYPE any iv_filter TYPE abap_bool CHANGING ct_html TYPE t_string.
  DATA: lt_ddfields TYPE ddfields,
        lv_label    TYPE string,
        lv_txt      TYPE ddtext.
  FIELD-SYMBOLS: <fs_dfies> TYPE dfies,
                 <fs_value> TYPE any.

  PERFORM get_used_ddfields USING iv_stru iv_fldnames CHANGING lt_ddfields.
  LOOP AT lt_ddfields ASSIGNING <fs_dfies>.
    ASSIGN COMPONENT <fs_dfies>-fieldname OF STRUCTURE iv_data TO <fs_value>.
    CHECK <fs_value> IS ASSIGNED.

    PERFORM get_value_desc USING <fs_dfies>-fieldname <fs_value> CHANGING lv_txt.
    IF iv_filter EQ abap_true.
      CHECK <fs_value> IS NOT INITIAL OR lv_txt IS NOT INITIAL.
    ENDIF.

    PERFORM get_field_label USING <fs_dfies> CHANGING lv_label.
    IF lv_txt IS NOT INITIAL.
      lv_txt = escape( val = lv_txt format = cl_abap_format=>e_html_text ).
      PERFORM get_2column_value_html USING lv_label lv_txt CHANGING ct_html.
    ELSE.
      PERFORM get_2column_value_html USING lv_label <fs_value> CHANGING ct_html.
    ENDIF.

    UNASSIGN <fs_value>.
    CLEAR: lv_txt.
  ENDLOOP.
ENDFORM.

FORM data2rows USING iv_data TYPE any  iv_stru TYPE any iv_fldnames TYPE any CHANGING ct_html TYPE t_string.
  PERFORM data2rows_common USING iv_data iv_stru iv_fldnames abap_true CHANGING ct_html.
ENDFORM.

FORM get_used_ddfields USING iv_stru TYPE any iv_fldnames TYPE string CHANGING ct_ddfields TYPE ddfields.
  DATA: lo_stru      TYPE REF TO cl_abap_structdescr,
        lo_type      TYPE REF TO cl_abap_typedescr,
        lt_ddic      TYPE ddfields,
        lt_hash_ddic TYPE HASHED TABLE OF dfies WITH UNIQUE KEY fieldname,
        lt_used_ddic TYPE ddfields,
        lt_fldnames  TYPE TABLE OF fieldname,
        ls_ddic      TYPE dfies,
        lt_components TYPE abap_component_tab,
        lo_ele_descr  TYPE REF TO cl_abap_elemdescr,
        lv_msg       TYPE string.

  FIELD-SYMBOLS: <fs_ddic>  TYPE dfies,
                 <fs_fld>   TYPE fieldname,
                 <fs_comp>  TYPE abap_componentdescr.

  CHECK iv_stru IS NOT INITIAL.
  CALL METHOD cl_abap_typedescr=>describe_by_name
    EXPORTING
      p_name         = iv_stru
    RECEIVING
      p_descr_ref    = lo_type
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  IF sy-subrc EQ 0.
    lo_stru ?= lo_type.
    IF lo_stru->is_ddic_type( ) EQ abap_true.
      lt_ddic = lo_stru->get_ddic_field_list( ).
    ELSE.
      lt_components = lo_stru->get_components( ).

      LOOP AT lt_components ASSIGNING <fs_comp> WHERE as_include EQ abap_false.
        " include/table/structure is out of scope, only fields will be fetched
        CHECK <fs_comp>-type->type_kind NE cl_abap_typedescr=>typekind_table AND
              <fs_comp>-type->type_kind NE cl_abap_typedescr=>typekind_struct1 AND
              <fs_comp>-type->type_kind NE cl_abap_typedescr=>typekind_struct2.

        lo_ele_descr ?= <fs_comp>-type.
        IF lo_ele_descr->is_ddic_type( ) EQ abap_true.
          ls_ddic = lo_ele_descr->get_ddic_field( ).
          ls_ddic-fieldname = <fs_comp>-name.
        ELSE.
          " if component is not ddic type, then fall back to its field name
          ls_ddic-fieldname = <fs_comp>-name.
        ENDIF.
        APPEND ls_ddic TO lt_ddic.
        CLEAR ls_ddic.
      ENDLOOP.
    ENDIF.
  ELSE.
    CONCATENATE 'Type ' iv_stru ' not found.' INTO lv_msg RESPECTING BLANKS.
    PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
    RETURN.
  ENDIF.

  IF iv_fldnames IS NOT INITIAL.
    MOVE lt_ddic TO lt_hash_ddic.

    SPLIT iv_fldnames AT '|' INTO TABLE lt_fldnames.
    LOOP AT lt_fldnames ASSIGNING <fs_fld>.
      CONDENSE <fs_fld> NO-GAPS.
      CHECK <fs_fld> IS NOT INITIAL.

      READ TABLE lt_hash_ddic WITH TABLE KEY fieldname = <fs_fld> ASSIGNING <fs_ddic>.
      IF <fs_ddic> IS ASSIGNED.
        APPEND <fs_ddic> TO lt_used_ddic.
        UNASSIGN <fs_ddic>.
      ELSE.
        ls_ddic-fieldname = <fs_fld>.
        APPEND ls_ddic TO lt_used_ddic.
      ENDIF.
    ENDLOOP.
  ELSE.
    lt_used_ddic = lt_ddic.
  ENDIF.

  CLEAR ct_ddfields.
  ct_ddfields = lt_used_ddic.
ENDFORM.

TYPES: BEGIN OF s_label,
       len TYPE headlen,
       txt TYPE string,
       END OF s_label.
TYPES: t_label TYPE STANDARD TABLE OF s_label.

FORM append_fld_label USING iv_txt TYPE c CHANGING ct_label TYPE t_label.
  DATA ls_label TYPE s_label.

  ls_label-len = strlen( iv_txt ).
  ls_label-txt = iv_txt.
  APPEND ls_label TO ct_label.
ENDFORM.

FORM get_field_label USING iv_dfies TYPE dfies CHANGING cv_label TYPE string.
  CHECK iv_dfies IS NOT INITIAL.
  CLEAR cv_label.

  DATA lt_table TYPE t_label.
  FIELD-SYMBOLS <fs_label> TYPE s_label.

  PERFORM append_fld_label USING iv_dfies-scrtext_s CHANGING lt_table.
  PERFORM append_fld_label USING iv_dfies-scrtext_m CHANGING lt_table.
  PERFORM append_fld_label USING iv_dfies-scrtext_l CHANGING lt_table.
  PERFORM append_fld_label USING iv_dfies-reptext   CHANGING lt_table.

  SORT lt_table BY len DESCENDING.
  READ TABLE lt_table ASSIGNING <fs_label> INDEX 1.
  IF <fs_label>-txt IS INITIAL.
    PERFORM format_fldname USING iv_dfies-fieldname CHANGING cv_label.
  ELSE.
    cv_label = <fs_label>-txt.
  ENDIF.
ENDFORM.

FORM format_fldname USING iv_fldname TYPE fieldname CHANGING cv_label TYPE string.
  DATA: lt_word TYPE TABLE OF fieldname,
        lv_char TYPE c.
  FIELD-SYMBOLS <fs_word> TYPE fieldname.
  SPLIT iv_fldname AT '_' INTO TABLE lt_word.
  LOOP AT lt_word ASSIGNING <fs_word>.
    lv_char = <fs_word>(1).
    TRANSLATE <fs_word> TO LOWER CASE.
    <fs_word>(1) = lv_char.
  ENDLOOP.

  CONCATENATE LINES OF lt_word INTO cv_label SEPARATED BY space.
ENDFORM.

FORM get_table_head_html USING it_dfies TYPE ddfields CHANGING cv_tr TYPE string.
  DATA: lv_tr    TYPE string VALUE '<tr>',
        lv_td    TYPE string,
        lv_label TYPE string.

  FIELD-SYMBOLS: <fs_ddic> TYPE dfies.

  LOOP AT it_dfies ASSIGNING <fs_ddic>.
    PERFORM get_field_label USING <fs_ddic> CHANGING lv_label.
    PERFORM get_column_label_html USING lv_label CHANGING lv_td.
    CONCATENATE lv_tr lv_td INTO lv_tr RESPECTING BLANKS.

    CLEAR: lv_label, lv_td.
  ENDLOOP.
  CONCATENATE lv_tr '</tr>' INTO lv_tr RESPECTING BLANKS.

  CLEAR cv_tr.
  cv_tr = lv_tr.
ENDFORM.

FORM prepare_html_head.
  APPEND '<html>' TO gt_html_all.
  APPEND '<head>' TO gt_html_all.
  APPEND '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">' TO gt_html_all.
  APPEND '<meta name="Generator" content="Microsoft Word 14 (filtered)">' TO gt_html_all.
  APPEND '<style type="text/css">' TO gt_html_all.
  APPEND '<!--' TO gt_html_all.
  APPEND '/* Font Definitions */' TO gt_html_all.
  APPEND '@font-face' TO gt_html_all.
  APPEND '{font-family:Calibri;' TO gt_html_all.
  APPEND 'panose-1:2 15 5 2 2 2 4 3 2 4;}' TO gt_html_all.
  APPEND '@font-face' TO gt_html_all.
  APPEND '{font-family:Tahoma;' TO gt_html_all.
  APPEND 'panose-1:2 11 6 4 3 5 4 4 2 4;}' TO gt_html_all.
  APPEND '/* Style Definitions */' TO gt_html_all.
  APPEND 'p.MsoNormal, li.MsoNormal, div.MsoNormal' TO gt_html_all.
  APPEND '{margin-top:0in;' TO gt_html_all.
  APPEND 'margin-right:0in;' TO gt_html_all.
  APPEND 'margin-bottom:10.0pt;' TO gt_html_all.
  APPEND 'margin-left:0in;' TO gt_html_all.
  APPEND 'line-height:115%;' TO gt_html_all.
  APPEND 'font-size:11.0pt;' TO gt_html_all.
  APPEND 'font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND 'p.MsoAcetate, li.MsoAcetate, div.MsoAcetate' TO gt_html_all.
  APPEND 'p.MsoListParagraph, li.MsoListParagraph, div.MsoListParagraph' TO gt_html_all.
  APPEND '{margin-top:0in;' TO gt_html_all.
  APPEND 'margin-right:0in;' TO gt_html_all.
  APPEND 'margin-bottom:10.0pt;' TO gt_html_all.
  APPEND 'margin-left:.5in;' TO gt_html_all.
  APPEND 'line-height:115%;' TO gt_html_all.
  APPEND 'font-size:11.0pt;' TO gt_html_all.
  APPEND 'font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND 'p.MsoListParagraphCxSpFirst, li.MsoListParagraphCxSpFirst, div.MsoListParagraphCxSpFirst' TO gt_html_all.
  APPEND '{margin-top:0in;' TO gt_html_all.
  APPEND 'margin-right:0in;' TO gt_html_all.
  APPEND 'margin-bottom:0in;' TO gt_html_all.
  APPEND 'margin-left:.5in;' TO gt_html_all.
  APPEND 'margin-bottom:.0001pt;' TO gt_html_all.
  APPEND 'line-height:115%;' TO gt_html_all.
  APPEND 'font-size:11.0pt;' TO gt_html_all.
  APPEND 'font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND 'p.MsoListParagraphCxSpMiddle, li.MsoListParagraphCxSpMiddle, div.MsoListParagraphCxSpMiddle' TO gt_html_all.
  APPEND '{margin-top:0in;' TO gt_html_all.
  APPEND 'margin-right:0in;' TO gt_html_all.
  APPEND 'margin-bottom:0in;' TO gt_html_all.
  APPEND 'margin-left:.5in;' TO gt_html_all.
  APPEND 'margin-bottom:.0001pt;' TO gt_html_all.
  APPEND 'line-height:115%;' TO gt_html_all.
  APPEND 'font-size:11.0pt;' TO gt_html_all.
  APPEND 'font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND 'p.MsoListParagraphCxSpLast, li.MsoListParagraphCxSpLast, div.MsoListParagraphCxSpLast' TO gt_html_all.
  APPEND '{margin-top:0in;' TO gt_html_all.
  APPEND 'margin-right:0in;' TO gt_html_all.
  APPEND 'margin-bottom:10.0pt;' TO gt_html_all.
  APPEND 'margin-left:.5in;' TO gt_html_all.
  APPEND 'line-height:115%;' TO gt_html_all.
  APPEND 'font-size:11.0pt;' TO gt_html_all.
  APPEND 'font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND '.MsoChpDefault' TO gt_html_all.
  APPEND '{font-family:"Calibri","sans-serif";}' TO gt_html_all.
  APPEND '.MsoPapDefault' TO gt_html_all.
  APPEND '{margin-bottom:10.0pt;' TO gt_html_all.
  APPEND 'line-height:115%;}' TO gt_html_all.
  APPEND '/* Page Definitions */' TO gt_html_all.
  APPEND '@page WordSection1' TO gt_html_all.
  APPEND '{size:8.5in 11.0in;' TO gt_html_all.
  APPEND 'margin:1.0in 1.0in 1.0in 1.0in;}' TO gt_html_all.
  APPEND 'div.WordSection1' TO gt_html_all.
  APPEND '{page:WordSection1;}' TO gt_html_all.
  APPEND '/* List Definitions */' TO gt_html_all.
  APPEND 'ol' TO gt_html_all.
  APPEND '{margin-bottom:0in;}' TO gt_html_all.
  APPEND 'ul' TO gt_html_all.
  APPEND '{margin-bottom:0in;}' TO gt_html_all.
  APPEND '-->' TO gt_html_all.
  APPEND '</style>' TO gt_html_all.
  APPEND '<title>' TO gt_html_all.
  APPEND text_common-title_html TO gt_html_all.
  APPEND '</title>' TO gt_html_all.
  APPEND '</head>' TO gt_html_all.
  APPEND '<body lang="EN-US">' TO gt_html_all.
  APPEND '<div class="WordSection1">' TO gt_html_all.
  APPEND '<p class="MsoNormal" style="margin-bottom:0in;margin-bottom:.0001pt;line-height: normal"><span syle="font-size:14.0pt;line-height:115%">' TO gt_html_all.
  APPEND text_common-txt_notice TO gt_html_all.
  APPEND '</span></p><br>' TO gt_html_all.
ENDFORM.

FORM prepare_html_tail.
  APPEND '</div>'  TO gt_html_all.
  APPEND '</body>' TO gt_html_all.
  APPEND '</html>' TO gt_html_all.
ENDFORM.

FORM export_docu CHANGING cv_file_name TYPE string.
  DATA: lv_html_file TYPE string,
        lv_msg       TYPE string,
        lv_len       TYPE i,
        lv_codepage  TYPE cpcodepage,
        lv_cp_dl     TYPE abap_encod.

  lv_len = strlen( p_doc ).
  CONCATENATE p_dir gv_slash p_doc(lv_len) '.html' INTO  lv_html_file RESPECTING BLANKS.
  cv_file_name = lv_html_file.

  PERFORM download_file USING 'ASC' lv_html_file CHANGING lv_msg gt_html_all.
  RETURN.

  IF sy-langu EQ 'E'.
    PERFORM download_file USING 'ASC' lv_html_file CHANGING lv_msg gt_html_all.
  ELSE.
    CALL FUNCTION 'SCP_CODEPAGE_BY_EXTERNAL_NAME'
      EXPORTING
        external_name = 'UTF-16LE'
        kind          = 'H'
      IMPORTING
        sap_codepage  = lv_codepage
      EXCEPTIONS
        not_found     = 1
        OTHERS        = 2.
    IF sy-subrc NE 0.
      lv_codepage = '4013'.
    ENDIF.
    lv_cp_dl = lv_codepage.

    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename                = lv_html_file
        confirm_overwrite       = boolc( p_test NE abap_true )
        codepage                = lv_cp_dl
      CHANGING
        data_tab                = gt_html_all
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
ENDFORM.

FORM open_html_in_msword USING iv_filename TYPE string.
* German should be open by IE browser directly, MS WORD won't work
  CHECK sy-langu EQ 'E' AND p_open EQ abap_true.

  DATA: lt_paths      TYPE TABLE OF string,
        lv_path_used  TYPE string,
        lv_params     TYPE string,
        lv_result     TYPE abap_bool.
  FIELD-SYMBOLS <fs_path> TYPE string.

  APPEND 'C:\Program Files (x86)\Microsoft Office\Office12\WINWORD.exe' TO lt_paths.
  APPEND 'C:\Program Files (x86)\Microsoft Office\Office14\winword.exe' TO lt_paths.

  LOOP AT lt_paths ASSIGNING <fs_path>.
    CALL METHOD cl_gui_frontend_services=>file_exist
      EXPORTING
        file                 = <fs_path>
      RECEIVING
        result               = lv_result
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        wrong_parameter      = 3
        not_supported_by_gui = 4
        OTHERS               = 5.

    IF sy-subrc EQ 0 AND lv_result EQ abap_true.
      lv_path_used = <fs_path>.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF lv_path_used IS INITIAL.
    "TODO read registry to get the installation path of MS Word
  ENDIF.
  CHECK lv_path_used IS NOT INITIAL.

  CONCATENATE '/f ' iv_filename INTO lv_params RESPECTING BLANKS.
  CALL METHOD cl_gui_frontend_services=>execute
    EXPORTING
      application            = lv_path_used
      parameter              = lv_params
      maximized              = 'X'
    EXCEPTIONS
      cntl_error             = 1
      error_no_gui           = 2
      bad_parameter          = 3
      file_not_found         = 4
      path_not_found         = 5
      file_extension_unknown = 6
      error_execute_failed   = 7
      synchronous_failed     = 8
      not_supported_by_gui   = 9
      OTHERS                 = 10.
ENDFORM.
FORM upload_transport_files.
  DATA: lv_slah       TYPE c,
        lv_filename   TYPE c LENGTH 1024,
        lv_answer     TYPE c,
        lv_len        TYPE i,
        lv_contents   TYPE xstring,
        lt_data       TYPE t_linetype,
        lt_msg        TYPE TABLE OF s_common_msg,
        lv_msg        TYPE string,
        lv_stms       TYPE abap_bool VALUE abap_true.

  FIELD-SYMBOLS: <fs_file> TYPE cl_abap_zip=>t_file,
                 <fs_msg>  TYPE s_common_msg.

  lv_slah = gv_trans_dir(1).
  LOOP AT go_zip->files ASSIGNING <fs_file>.
    CLEAR: lv_filename, lv_contents, lt_data, lv_msg, lv_len, lv_answer.

    IF <fs_file>-name(1) EQ 'K'.
      CONCATENATE gv_trans_dir lv_slah 'cofiles' lv_slah <fs_file>-name INTO lv_filename RESPECTING BLANKS.
    ELSEIF <fs_file>-name(1) EQ 'R'.
      CONCATENATE gv_trans_dir lv_slah 'data' lv_slah <fs_file>-name INTO lv_filename RESPECTING BLANKS.
    ENDIF.
    lv_len = strlen( lv_filename ).

    go_zip->get(
      EXPORTING
        name                    = <fs_file>-name
      IMPORTING
        content                 = lv_contents
      EXCEPTIONS
        zip_index_error         = 1
        zip_decompression_error = 2
        OTHERS                  = 3
      ).

    IF sy-subrc NE 0.
      PERFORM get_sys_error_msg CHANGING lv_msg.
      CONCATENATE 'Unable to get ' <fs_file>-name ' in zip file ' p_file '.Reason: ' lv_msg INTO lv_msg RESPECTING BLANKS.
      PERFORM append_common_msg USING 'E' lv_msg CHANGING lt_msg.
    ELSE.
      CONCATENATE 'Unzip file ' p_file ' and get ' <fs_file>-name ' successfully.' INTO lv_msg RESPECTING BLANKS.
      PERFORM append_common_msg USING 'S' lv_msg CHANGING lt_msg.
    ENDIF.

    CLEAR lv_msg.
    PERFORM convert_zip2tbl1024 USING lv_contents CHANGING lt_data.
    PERFORM upload_overwrite_confirm USING lv_filename CHANGING lv_answer.
    IF lv_answer NE '1'.
      CONCATENATE lv_filename(lv_len) ' exists in server already and you choose to ignore.' INTO lv_msg RESPECTING BLANKS.
      PERFORM append_common_msg USING 'W' lv_msg CHANGING lt_msg.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'SCMS_DOWNLOAD'
      EXPORTING
        filename = lv_filename
        filesize = <fs_file>-size
        binary   = 'X'
        frontend = ' '
      TABLES
        data     = lt_data
      EXCEPTIONS
        error    = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
      PERFORM get_sys_error_msg CHANGING lv_msg.
      CONCATENATE 'Failed to upload ' p_file ' to server: ' lv_filename(lv_len) '.Reason: ' lv_msg INTO lv_msg RESPECTING BLANKS.
      PERFORM append_common_msg USING 'E' lv_msg CHANGING lt_msg.
    ELSE.
      CONCATENATE 'Upload ' p_file ' to server address ' lv_filename(lv_len) ' successfully.' INTO lv_msg RESPECTING BLANKS.
      PERFORM append_common_msg USING 'S' lv_msg CHANGING lt_msg.
    ENDIF.
  ENDLOOP.

  WRITE: / icon_icon_list AS ICON, 'Dear', gv_username, ', here is transport file upload report:'.
  SKIP.
  LOOP AT lt_msg ASSIGNING <fs_msg>.
    PERFORM print_msg USING <fs_msg>-msgty <fs_msg>-msg.
    IF <fs_msg>-msgty NE 'S'.
      lv_stms = abap_false.
    ENDIF.
  ENDLOOP.
  SKIP.
  WRITE: / icon_tools AS ICON, text_common-thanks.

  CHECK lv_stms EQ abap_true.
  MESSAGE 'Now you can import the transport request.' TYPE 'I'.
  CALL TRANSACTION 'STMS_IMPORT' AND SKIP FIRST SCREEN.
ENDFORM.

FORM append_common_msg USING iv_msgty TYPE sy-msgty iv_msg TYPE string CHANGING ct_msg TYPE STANDARD TABLE.
  DATA ls_common_msg TYPE s_common_msg.
  ls_common_msg-msgty = iv_msgty.
  ls_common_msg-msg = iv_msg.
  APPEND ls_common_msg TO ct_msg.
ENDFORM.

FORM upload_overwrite_confirm USING iv_server_file TYPE c CHANGING cv_answer TYPE c.
  CLEAR cv_answer.

  OPEN DATASET iv_server_file FOR INPUT IN BINARY MODE.
  IF sy-subrc EQ 0.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question = 'This file exists on server already, do you really want to overwrite?'
      IMPORTING
        answer        = cv_answer.
  ELSE.
    cv_answer = '1'.
  ENDIF.
  CLOSE DATASET iv_server_file.
ENDFORM.

FORM convert_zip2tbl1024 USING iv_xstr TYPE xstring CHANGING ct_tabl TYPE t_linetype.
  CONSTANTS: c_length_segment   TYPE i VALUE 1024.
  DATA: lv_line(1024) TYPE x,
        ls_line       TYPE s_lintype,
        len_src       TYPE i,
        len_wa        TYPE i,
        offset        TYPE i.

  offset = 0.
  len_src = xstrlen( iv_xstr ).

  WHILE offset < len_src.
    len_wa = len_src - offset.
    IF len_wa > c_length_segment.
      lv_line = iv_xstr+offset(c_length_segment).
      ls_line-line = lv_line.
      APPEND ls_line TO ct_tabl.
      offset = offset + c_length_segment.
    ELSE.
      lv_line = iv_xstr+offset(len_wa).
      ls_line-line = lv_line.
      APPEND ls_line TO ct_tabl.
      offset = offset + len_wa.
    ENDIF.
  ENDWHILE.
ENDFORM.

FORM check_transport_zip CHANGING cv_msg TYPE string.
  DATA: lv_str TYPE xstring,
        lt_tab TYPE solix_tab.

  CALL METHOD cl_gui_frontend_services=>file_exist
    EXPORTING
      file                 = p_file
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      wrong_parameter      = 3
      not_supported_by_gui = 4
      OTHERS               = 5.
  IF sy-subrc <> 0.
    PERFORM get_sys_error_msg CHANGING cv_msg.
    RETURN.
  ENDIF.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      text = 'Upload transport zip file...'.

  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename                = p_file
      filetype                = 'BIN'
    CHANGING
      data_tab                = lt_tab
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      not_supported_by_gui    = 17
      error_no_gui            = 18
      OTHERS                  = 19.
  IF sy-subrc <> 0.
    PERFORM get_sys_error_msg CHANGING cv_msg.
    RETURN.
  ELSE.
    lv_str = cl_bcs_convert=>solix_to_xstring( it_solix  = lt_tab ).
  ENDIF.

  IF go_zip IS NOT BOUND.
    CREATE OBJECT go_zip.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = 2
        text       = 'Load and parse transport zip file...'.

    go_zip->load(
      EXPORTING
        zip = lv_str
      EXCEPTIONS
        zip_parse_error = 1
        OTHERS          = 2
      ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO cv_msg.
    ENDIF.

    " if validity check passed but count of files mod 2 ne 0, give a warning message
    IF lines( go_zip->files ) MOD 2 NE 0.
      cv_msg = 'There should a K/R file missing for a certain transport request, please check your zip file'.
    ENDIF.

    FIELD-SYMBOLS: <fs_file> TYPE cl_abap_zip=>t_file.
    LOOP AT go_zip->files ASSIGNING <fs_file>.
      "TODO: replace by regex match
      IF <fs_file>-name(1) NE 'K' AND <fs_file>-name(1) NE 'R' AND strlen( <fs_file>-name ) NE 11.
        CONCATENATE 'Invalid file name in zip: ' <fs_file>-name INTO cv_msg RESPECTING BLANKS.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.
***** Generate Code Template For New Object Type Begin ****
FORM initialize_code_template.
  APPEND 'TYPES: BEGIN OF s_$OBJECT.' TO gt_code_template. "#EC NOTEXT
  APPEND 'INCLUDE TYPE s_obj_header.' TO gt_code_template. "#EC NOTEXT
  APPEND 'TYPES: END OF s_$OBJECT.' TO gt_code_template. "#EC NOTEXT
  APPEND 'DATA gt_$OBJECT TYPE TABLE OF s_$OBJECT.  "#EC NEEDED' TO gt_code_template. "#EC NOTEXT
  APPEND '' TO gt_code_template. "#EC NOTEXT
  APPEND '***************** $DESC Begin *****************' TO gt_code_template. "#EC NOTEXT
  APPEND 'FORM getdata_$OBJECT USING is_obj_header TYPE s_obj_header.     "#EC CALLED' TO gt_code_template. "#EC NOTEXT
  APPEND '  DATA: ls_$OBJECT TYPE s_$OBJECT.' TO gt_code_template. "#EC NOTEXT
  APPEND '  MOVE-CORRESPONDING is_obj_header TO ls_$OBJECT.' TO gt_code_template. "#EC NOTEXT
  APPEND '  " add data retrive logic here' TO gt_code_template. "#EC NOTEXT
  APPEND '  APPEND ls_$OBJECT TO gt_$OBJECT.' TO gt_code_template. "#EC NOTEXT
  APPEND 'ENDFORM.' TO gt_code_template. "#EC NOTEXT
  APPEND '' TO gt_code_template. "#EC NOTEXT

  APPEND 'FORM get_additional_html_$OBJECT USING is_$OBJECT TYPE s_$OBJECT CHANGING ct_html TYPE t_string.     "#EC CALLED' TO gt_code_template. "#EC NOTEXT
  APPEND '  PERFORM data2rows USING is_$OBJECT ''S_$OBJECT'' ''${Field names separated by |}'' CHANGING ct_html.' TO gt_code_template. "#EC NOTEXT
  APPEND 'ENDFORM.' TO gt_code_template. "#EC NOTEXT
  APPEND '' TO gt_code_template. "#EC NOTEXT

  APPEND 'FORM get_special_html_$OBJECT USING is_$OBJECT TYPE s_$OBJECT CHANGING ct_html TYPE t_string.     "#EC CALLED' TO gt_code_template. "#EC NOTEXT
  APPEND '  PERFORM table2html USING ''${TITLE}'' is_$OBJECT-{$TABLE} ''${STRUC}'' ''${Field names separated by |}'' abap_false '''' CHANGING ct_html.' TO gt_code_template. "#EC NOTEXT
  APPEND 'ENDFORM.' TO gt_code_template. "#EC NOTEXT
  APPEND '' TO gt_code_template. "#EC NOTEXT

  APPEND 'FORM convert_$OBJECT.     "#EC CALLED' TO gt_code_template. "#EC NOTEXT
  APPEND '  CHECK gt_$OBJECT IS NOT INITIAL.' TO gt_code_template. "#EC NOTEXT
  APPEND '  ADD 1 TO gv_header_no.' TO gt_code_template. "#EC NOTEXT
  APPEND '  PERFORM add_header_html USING ''$OBJECT'' CHANGING gt_html.' TO gt_code_template. "#EC NOTEXT
  APPEND '  PERFORM add_object_instruction_html USING ''$OBJECT'' CHANGING gt_html.' TO gt_code_template. "#EC NOTEXT
  APPEND '  PERFORM table2html USING ''${TITLE}'' gt_$OBJECT ''S_$OBJECT'' ''${Field names separated by |}'' abap_false '''' CHANGING gt_html.' TO gt_code_template. "#EC NOTEXT
  APPEND 'ENDFORM.' TO gt_code_template. "#EC NOTEXT
  APPEND '***************** $DESC Close *****************' TO gt_code_template. "#EC NOTEXT
  APPEND '' TO gt_code_template. "#EC NOTEXT
ENDFORM.

FORM print_template_codes.
  DATA: lv_objtype  TYPE trobjtype,
        lv_tmp      TYPE char255,
        lv_rc       TYPE i,
        lt_code_tab TYPE TABLE OF char255.

  FIELD-SYMBOLS: <fs_ko100> TYPE ko100,
                 <fs_code>  TYPE char255.

  LOOP AT so_objt.
    READ TABLE gt_ko100 WITH KEY object = so_objt-low ASSIGNING <fs_ko100>.
    IF <fs_ko100> IS ASSIGNED.
      lv_objtype = so_objt-low.
      LOOP AT gt_code_template INTO lv_tmp.
        REPLACE ALL OCCURRENCES OF '$OBJECT' IN lv_tmp WITH lv_objtype.
        REPLACE ALL OCCURRENCES OF '$DESC' IN lv_tmp WITH <fs_ko100>-text.
        APPEND lv_tmp TO lt_code_tab.
      ENDLOOP.
    ENDIF.
    UNASSIGN <fs_ko100>.
  ENDLOOP.

  LOOP AT lt_code_tab ASSIGNING <fs_code>.
    IF <fs_code> IS INITIAL.
      SKIP.
    ENDIF.
    WRITE: / <fs_code>.
  ENDLOOP.

  CALL METHOD cl_gui_frontend_services=>clipboard_export
    IMPORTING
      data                 = lt_code_tab
    CHANGING
      rc                   = lv_rc
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.

  IF sy-subrc EQ 0 AND lv_rc NE -1.
    MESSAGE s208(00) WITH 'Generated Codes exported to clip board also.'.
  ENDIF.
ENDFORM.
***** Generate Code Template For New Object Type Close ****
FORM collect_objects_header_in_tr CHANGING ct_objheaders TYPE STANDARD TABLE.
  CHECK so_trans IS NOT INITIAL.
  CLEAR ct_objheaders.

* since tadir is buffered by primary key, join e071 and tadir to get devclass is not necessary
  SELECT DISTINCT pgmid object obj_name FROM e071              ##too_many_itab_fields
    INTO CORRESPONDING FIELDS OF TABLE ct_objheaders FOR ALL ENTRIES IN gt_objtype_order
* object function marked as deletion is out of scope
    WHERE trkorr IN so_trans AND objfunc NE 'D' AND object = gt_objtype_order-object.
ENDFORM.

FORM initialize_buffer.
  PERFORM init_objectype_config.
  PERFORM init_objectype_desc.
  PERFORM init_trans_dir.
  PERFORM init_texts_of_value.
  PERFORM get_user_info.
  CALL METHOD cl_gui_frontend_services=>get_file_separator
    CHANGING
      file_separator       = gv_slash
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
    gv_slash = '\'.
  ENDIF.
ENDFORM.

FORM add_objectype_config_entry USING iv_object TYPE trobjtype iv_sort_no TYPE i iv_show_basic_attr TYPE abap_bool
                                CHANGING ct_object_config TYPE ht_objtype_order.
  DATA ls_object_config TYPE s_objtype_order.

  ls_object_config-object = iv_object.
  CONDENSE ls_object_config-object NO-GAPS.

  ls_object_config-sort_no = iv_sort_no.
  ls_object_config-show_basic_attr = iv_show_basic_attr.

  READ TABLE gt_objtype_order WITH TABLE KEY object = iv_object TRANSPORTING NO FIELDS.
  IF sy-subrc NE 0.
    INSERT ls_object_config INTO TABLE ct_object_config.
  ENDIF.
ENDFORM.

FORM init_objectype_config.
  PERFORM add_objectype_config_entry USING :  'DEVC' 0010 abap_true  CHANGING gt_objtype_order,
                                              'DEVP' 0020 abap_false CHANGING gt_objtype_order,
                                              'PINF' 0021 abap_false CHANGING gt_objtype_order,
                                              'FUGR' 0030 abap_true  CHANGING gt_objtype_order,
                                              'FUGT' 0040 abap_true  CHANGING gt_objtype_order,
                                              'DOMA' 0050 abap_true  CHANGING gt_objtype_order,
                                              'DOMD' 0051 abap_true  CHANGING gt_objtype_order,
                                              'DTEL' 0060 abap_true  CHANGING gt_objtype_order,
                                              'DTED' 0061 abap_true  CHANGING gt_objtype_order,
                                              'TABL' 0070 abap_true  CHANGING gt_objtype_order,
                                              'TABD' 0080 abap_false CHANGING gt_objtype_order,
                                              'TABT' 0081 abap_false CHANGING gt_objtype_order,
                                              'INDX' 0082 abap_false CHANGING gt_objtype_order,
                                              'VIEW' 0090 abap_true  CHANGING gt_objtype_order,
                                              'VIED' 0091 abap_false CHANGING gt_objtype_order,
                                              'VIET' 0092 abap_false CHANGING gt_objtype_order,
                                              'SHLP' 0100 abap_true  CHANGING gt_objtype_order,
                                              'SHLD' 0101 abap_true  CHANGING gt_objtype_order,
                                              'ENQU' 0110 abap_true  CHANGING gt_objtype_order,
                                              'ENQD' 0111 abap_true  CHANGING gt_objtype_order,
                                              'TTYP' 0120 abap_true  CHANGING gt_objtype_order,
                                              'TTYD' 0121 abap_true  CHANGING gt_objtype_order,
                                              'TOBJ' 0130 abap_true  CHANGING gt_objtype_order,
                                              'VCLS' 0140 abap_true  CHANGING gt_objtype_order,
                                              'NROB' 0150 abap_true  CHANGING gt_objtype_order,
                                              'DOCU' 0160 abap_true  CHANGING gt_objtype_order,
                                              'DOCT' 0161 abap_true  CHANGING gt_objtype_order,
                                              'DOCV' 0162 abap_true  CHANGING gt_objtype_order,
                                              'MSAD' 0170 abap_true  CHANGING gt_objtype_order,
                                              'MSAG' 0180 abap_true  CHANGING gt_objtype_order,
                                              'MESS' 0190 abap_true  CHANGING gt_objtype_order,
                                              'TRAN' 0200 abap_true  CHANGING gt_objtype_order,
                                              'CDAT' 0201 abap_false CHANGING gt_objtype_order,
                                              'VDAT' 0210 abap_false CHANGING gt_objtype_order,
                                              'TABU' 0220 abap_false CHANGING gt_objtype_order.
ENDFORM.

FORM init_objectype_desc.
  DATA: lt_ko100 TYPE TABLE OF ko100.
  FIELD-SYMBOLS <fs_ko100> TYPE ko100.

  CALL FUNCTION 'TR_OBJECT_TABLE'
    TABLES
      wt_object_text = lt_ko100.
  MOVE lt_ko100 TO gt_ko100.

  LOOP AT gt_ko100 ASSIGNING <fs_ko100>.
    READ TABLE gt_objtype_order WITH TABLE KEY object = <fs_ko100>-object TRANSPORTING NO FIELDS.
    IF sy-subrc EQ 0.
      INSERT <fs_ko100> INTO TABLE gt_objtype_desc.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM init_trans_dir.
  DATA: lv_trans_dir     TYPE trtppvalue,
        lv_len           TYPE i.

  CALL 'C_SAPGPARAM' ID 'NAME' FIELD 'DIR_TRANS' ID 'VALUE' FIELD lv_trans_dir.
  lv_len = strlen( lv_trans_dir ).
  gv_trans_dir = lv_trans_dir(lv_len).
ENDFORM.

FORM init_texts_of_value.
  PERFORM add_value_desc USING 'DD02L'   'TABCLASS'   'TABCLASS'.
  PERFORM add_value_desc USING 'DD02L'   'MAINFLAG'   'MAINFLAG'.
  PERFORM add_value_desc USING 'DD25L'   'GLOBALFLAG' 'GLOBALFLAG'.
  PERFORM add_value_desc USING 'DD25L'   'VIEWCLASS'  'VIEWCLASS'.
  PERFORM add_value_desc USING 'DD25L'   'VIEWGRANT'  'VIEWGRANT'.
  PERFORM add_value_desc USING 'DD09L'   'BUFALLOW'   'BUFALLOW'.
  PERFORM add_value_desc USING 'DD03P_D' 'F_REFTYPE'  'F_REFTYPE'.
  PERFORM manual_add_value_desc.
ENDFORM.

FORM add_value_desc USING iv_tabname TYPE ddobjname iv_fieldname TYPE fieldname iv_lfield_name TYPE dfies-lfieldname.
  DATA: ls_value_desc  TYPE s_value_desc.

  ls_value_desc-fieldname = iv_fieldname.
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname      = iv_tabname
      fieldname    = iv_fieldname
      lfieldname   = iv_lfield_name
      langu        = sy-langu
    TABLES
      fixed_values = ls_value_desc-ddfixvalues.

  READ TABLE gt_value_desc WITH TABLE KEY fieldname = iv_fieldname TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  INSERT ls_value_desc INTO TABLE gt_value_desc.
ENDFORM.

FORM manual_add_value_desc.
  DATA: ls_vd TYPE s_value_desc.

  ls_vd-fieldname = 'PUFFERUNG'.
  PERFORM add_ddfixvalue USING: 'P'  'Single records buff.'  CHANGING ls_vd-ddfixvalues,
                                'G'  'Generic Area Buffered' CHANGING ls_vd-ddfixvalues,
                                'X'  'Fully Buffered'        CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.

  CLEAR ls_vd.
  ls_vd-fieldname = 'FRKART'.
  PERFORM add_ddfixvalue USING: ''      'Not Specified'              CHANGING ls_vd-ddfixvalues,
                                'OPT'   'Optional foreign key'       CHANGING ls_vd-ddfixvalues,
                                'OBL'   'Mandatory foreign key'      CHANGING ls_vd-ddfixvalues,
                                'ID'    'Identifying foreign key'    CHANGING ls_vd-ddfixvalues,
                                'TEXT'  'Key fields of a text table' CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.

  CLEAR ls_vd.
  ls_vd-fieldname = 'TRANSACTION_TYPE'.
  PERFORM add_ddfixvalue USING: c_trans_type-dialog 'Program and screen (dialog transaction)'           CHANGING ls_vd-ddfixvalues,
                                c_trans_type-report 'Program and selection screen (report transaction)' CHANGING ls_vd-ddfixvalues,
                                c_trans_type-oo 'Method of a class (OO transaction) ' CHANGING ls_vd-ddfixvalues,
                                c_trans_type-trans_with_variant 'Transaction with variant (variant transaction)'    CHANGING ls_vd-ddfixvalues,
                                c_trans_type-trans_with_param 'Transaction with parameters (parameter transaction)' CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.

  CLEAR ls_vd.
  ls_vd-fieldname = 'UPDATE_MODE'.
  PERFORM add_ddfixvalue USING: 'U' 'Asynchronous Update' CHANGING ls_vd-ddfixvalues,
                                'S' 'Synchronous Update'  CHANGING ls_vd-ddfixvalues,
                                'L' 'LocalUpdate'         CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.

  CLEAR ls_vd.
  ls_vd-fieldname = 'VCLS_HIERARCHY'.
  PERFORM add_ddfixvalue USING: ''  'Use in Hierarchy (Popup) '      CHANGING ls_vd-ddfixvalues,
                                'A' 'Use in Hierarchy (Mandatory) '  CHANGING ls_vd-ddfixvalues,
                                'X' 'Limit to One Step'              CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.

  CLEAR ls_vd.
  ls_vd-fieldname = 'MAINT_TYPE'.
  PERFORM add_ddfixvalue USING: '1'  'One Step'  CHANGING ls_vd-ddfixvalues,
                                '2'  'Two Step'  CHANGING ls_vd-ddfixvalues.
  INSERT ls_vd INTO TABLE gt_value_desc.
ENDFORM.

FORM add_ddfixvalue USING iv_value TYPE c iv_text TYPE ddtext CHANGING ct_ddfixvalue TYPE ddfixvalues.
  DATA ls_ddfixvalue TYPE ddfixvalue.
  ls_ddfixvalue-low = iv_value.
  ls_ddfixvalue-ddtext = iv_text.

  APPEND ls_ddfixvalue TO ct_ddfixvalue.
ENDFORM.

FORM get_value_desc USING iv_fieldname TYPE fieldname iv_value TYPE any CHANGING cv_desc TYPE ddtext.
  DATA: ls_value_desc  TYPE s_value_desc,
        lv_low  TYPE ddfixvalue-low.
  FIELD-SYMBOLS: <fs_ddfixvalue> TYPE ddfixvalue.

  CLEAR cv_desc.
  READ TABLE gt_value_desc INTO ls_value_desc WITH TABLE KEY fieldname = iv_fieldname.
  CHECK sy-subrc EQ 0.

  lv_low = iv_value.
  READ TABLE ls_value_desc-ddfixvalues ASSIGNING <fs_ddfixvalue> WITH KEY low = iv_value.
  IF sy-subrc EQ 0 AND <fs_ddfixvalue> IS ASSIGNED.
    cv_desc = <fs_ddfixvalue>-ddtext.
  ENDIF.
ENDFORM.

FORM get_user_info.
  DATA: ls_user_addr  TYPE bapiaddr3,
        lv_len        TYPE i,
        lv_title      TYPE string,
        lt_return_tab TYPE TABLE OF bapiret2.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username      = sy-uname
      cache_results = 'X'
    IMPORTING
      address       = ls_user_addr
    TABLES
      return        = lt_return_tab.

  IF ls_user_addr-title_p IS NOT INITIAL.
    lv_title = ls_user_addr-title_p.
    CONDENSE lv_title NO-GAPS.
  ENDIF.

  lv_len = strlen( ls_user_addr-fullname ).
  CONCATENATE lv_title ' ' ls_user_addr-fullname(lv_len) INTO gv_username RESPECTING BLANKS.
ENDFORM.

FORM download_file USING iv_filetype TYPE char10 iv_filename TYPE string CHANGING cv_msg TYPE string ct_tab TYPE STANDARD TABLE .
  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filetype                  = iv_filetype
      filename                  = iv_filename
      confirm_overwrite         = boolc( p_test NE abap_true )
    CHANGING
      data_tab                  = ct_tab
    EXCEPTIONS
      file_write_error          = 1
      no_batch                  = 2
      gui_refuse_filetransfer   = 3
      invalid_type              = 4
      no_authority              = 5
      unknown_error             = 6
      header_not_allowed        = 7
      separator_not_allowed     = 8
      filesize_not_allowed      = 9
      header_too_long           = 10
      dp_error_create           = 11
      dp_error_send             = 12
      dp_error_write            = 13
      unknown_dp_error          = 14
      access_denied             = 15
      dp_out_of_memory          = 16
      disk_full                 = 17
      dp_timeout                = 18
      file_not_found            = 19
      dataprovider_exception    = 20
      control_flush_error       = 21
      not_supported_by_gui      = 22
      error_no_gui              = 23
      OTHERS                    = 24
    ).

  IF sy-subrc NE 0.
    PERFORM get_sys_error_msg CHANGING cv_msg.
    PERFORM append_common_msg USING 'E' cv_msg CHANGING gt_sys_msg.
  ENDIF.
ENDFORM.

FORM get_sys_error_msg CHANGING cv_msg TYPE string.
  CLEAR cv_msg.
  IF sy-msgid IS NOT INITIAL AND sy-msgty IS NOT INITIAL AND sy-msgno IS NOT INITIAL.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO cv_msg.
  ELSE.
    cv_msg = gcv_text_unexpected_error.                     "#EC NOTEXT
  ENDIF.
ENDFORM.

FORM handle_rc USING is_obj_header TYPE s_obj_header.
  DATA lv_rc TYPE sy-subrc.
  IF sy-subrc NE 0.
    DATA: lv_msgty TYPE sy-msgty,
          lv_msg   TYPE string.

    lv_rc = sy-subrc.
    IF sy-msgid IS NOT INITIAL AND sy-msgty IS NOT INITIAL AND sy-msgno IS NOT INITIAL.
      lv_msgty = sy-msgty.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_msg.
    ELSE.
      lv_msgty = 'E'.
      lv_msg = gcv_text_unexpected_error.
    ENDIF.
    PERFORM add_obj_gen_msg USING is_obj_header lv_msgty lv_msg.

    sy-subrc = lv_rc.
  ENDIF.
ENDFORM.

FORM add_obj_gen_msg USING is_obj_header TYPE s_obj_header iv_msgty TYPE sy-msgty iv_msg TYPE string.
  DATA: ls_gen_msg TYPE s_obj_gen_msg,
        lv_desc TYPE string,
        lv_len TYPE i.

  MOVE-CORRESPONDING is_obj_header TO ls_gen_msg.
  ls_gen_msg-msgty = iv_msgty.

  lv_len = strlen( ls_gen_msg-obj_name ).
  PERFORM get_objtype_desc_deep USING is_obj_header CHANGING lv_desc.
  IF iv_msgty EQ 'S'.
    CONCATENATE lv_desc ' ' ls_gen_msg-obj_name(lv_len) ' : ' text_common-msg_success
      INTO ls_gen_msg-msg RESPECTING BLANKS.
    APPEND ls_gen_msg TO gt_obj_gen_msg.
  ELSEIF iv_msgty EQ 'W'.
    CONCATENATE lv_desc ' ' ls_gen_msg-obj_name(lv_len) ' : ' text_common-msg_ignore
      INTO ls_gen_msg-msg RESPECTING BLANKS.
    APPEND ls_gen_msg TO gt_obj_gen_msg.
  ELSEIF iv_msgty EQ 'E'.
    CONCATENATE lv_desc ' ' ls_gen_msg-obj_name(lv_len) ' : ' text_common-msg_error
      INTO ls_gen_msg-msg RESPECTING BLANKS.
    APPEND ls_gen_msg TO gt_obj_gen_msg.

    CLEAR ls_gen_msg-msg.
    CONCATENATE '  ' text_common-msg_error_msg ': ' iv_msg INTO ls_gen_msg-msg RESPECTING BLANKS.
    APPEND ls_gen_msg TO gt_obj_gen_msg.
  ENDIF.
ENDFORM.

FORM display_result.
  DATA: lv_msg TYPE string.
  FIELD-SYMBOLS: <fs_gen_msg> TYPE s_obj_gen_msg,
                 <fs_sys_msg> TYPE s_common_msg.

  IF gt_obj_gen_msg IS INITIAL AND gt_sys_msg IS INITIAL.
    lv_msg = text_common-rep_none.
    REPLACE FIRST OCCURRENCE OF '$USERNAME' IN lv_msg WITH gv_username.
    WRITE: / icon_led_green AS ICON, lv_msg.
  ELSE.
    lv_msg = text_common-rep_docu.
    REPLACE FIRST OCCURRENCE OF '$USERNAME' IN lv_msg WITH gv_username.
    WRITE: / icon_led_green AS ICON, lv_msg.

    LOOP AT gt_obj_gen_msg ASSIGNING <fs_gen_msg>.
      PERFORM print_msg USING <fs_gen_msg>-msgty <fs_gen_msg>-msg.
    ENDLOOP.

    LOOP AT gt_sys_msg ASSIGNING <fs_sys_msg>.
      PERFORM print_msg USING <fs_sys_msg>-msgty <fs_sys_msg>-msg.
    ENDLOOP.

    SKIP.
    WRITE: / icon_information AS ICON, text_common-action_en.
    WRITE: / icon_information AS ICON, text_common-action2_en.
  ENDIF.
  WRITE: / icon_tools AS ICON, text_common-thanks.
ENDFORM.

FORM print_msg USING iv_msgty TYPE sy-msgty iv_msg TYPE string.
  CASE iv_msgty.
    WHEN 'E' OR 'A' OR 'X'.
      WRITE / icon_led_red AS ICON.
    WHEN 'W'.
      WRITE / icon_led_yellow AS ICON.
    WHEN OTHERS.
      WRITE / icon_led_green AS ICON.
  ENDCASE.

  WRITE iv_msg.
ENDFORM.

FORM get_activity USING iv_obj_create_date TYPE as4date CHANGING cv_activity TYPE s_obj_header-activity.
  "TODO: it seems not reliable via compare object create/last change date with request create date
  RETURN.

  IF iv_obj_create_date LT gv_tr_date.
    cv_activity = gcv_act_update.
  ELSE.
    cv_activity = gcv_act_create.
  ENDIF.
ENDFORM.

FORM format_numc USING iv_num TYPE n CHANGING cv_oput TYPE string.
  CLEAR cv_oput.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = iv_num
    IMPORTING
      output = cv_oput.
ENDFORM.

FORM collect_tab_fld USING it_tab TYPE STANDARD TABLE iv_fld TYPE fieldname iv_sep TYPE string CHANGING cv_result TYPE string.
  CHECK it_tab IS NOT INITIAL AND iv_fld IS NOT INITIAL.
  CLEAR cv_result.

  FIELD-SYMBOLS: <fs_row> TYPE any,
                 <fs_value> TYPE any.
  LOOP AT it_tab ASSIGNING <fs_row>.
    ASSIGN COMPONENT iv_fld OF STRUCTURE <fs_row> TO <fs_value>.
    CHECK <fs_value> IS ASSIGNED.
    CONCATENATE cv_result iv_sep <fs_value> INTO cv_result RESPECTING BLANKS.
  ENDLOOP.

  IF iv_sep IS NOT INITIAL.
    DATA lv_len TYPE i.
    lv_len = strlen( iv_sep ).
    SHIFT cv_result BY lv_len PLACES.
  ENDIF.
ENDFORM.
*&---------------------Supported Object Types Data Retrieve & HTML Conversion--------------------*
***************** Package Begin *****************
FORM getdata_devc USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_devc_reuse USING is_obj_header.
ENDFORM.

FORM getdata_devc_reuse USING is_obj_header TYPE s_obj_header.
  DATA: lv_devclass     TYPE devclass,
        lo_package      TYPE REF TO if_package,
        lt_permission   TYPE tpak_permission_to_use_list,
        lo_permission   TYPE REF TO if_package_permission_to_use,
        ls_use_access   TYPE permission,
        lt_interface    TYPE tpak_package_interface_list,
        lo_interface    TYPE REF TO if_package_interface,
        ls_interface    TYPE vintf,
        ls_devc         TYPE s_devc.

  IF is_obj_header-object EQ 'DEVP'.
    READ TABLE gt_devc WITH KEY obj_name = ls_devc-obj_name TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.
  ENDIF.

  lv_devclass = is_obj_header-obj_name.
  cl_package_factory=>load_package(
    EXPORTING
      i_package_name             = lv_devclass
    IMPORTING
      e_package                  = lo_package
    EXCEPTIONS
      object_not_existing        = 1
      unexpected_error           = 2
      intern_err                 = 3
      no_access                  = 4
      object_locked_and_modified = 5
      OTHERS                     = 6
    ).
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND lo_package IS BOUND.
  MOVE-CORRESPONDING is_obj_header TO ls_devc.
* basic attributes
  ls_devc-devclass = lo_package->package_name.
  ls_devc-short_text = lo_package->short_text.
  ls_devc-parentcl = lo_package->super_package_name.
  ls_devc-dlvunit = lo_package->software_component.
  ls_devc-applicat = lo_package->application_component_abbrev.
  ls_devc-ufps_posid = lo_package->application_component_abbrev.
  ls_devc-project_id = lo_package->project_id.
  ls_devc-translation_relevance = lo_package->translation_depth_text.
  ls_devc-mainpack =  lo_package->main_package.
  ls_devc-korrflag = lo_package->wbo_korr_flag.
  ls_devc-pdevclass = lo_package->transport_layer.
  PERFORM get_activity USING lo_package->created_on CHANGING ls_devc-activity.
* use accesses
  lo_package->get_permissions_to_use(
    IMPORTING
      e_permissions    = lt_permission
    EXCEPTIONS
      object_invalid   = 1
      unexpected_error = 2
      OTHERS           = 3
    ).
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0.

  LOOP AT lt_permission INTO lo_permission.
    ls_use_access-intf_name = lo_permission->package_interface_name.
    ls_use_access-client_pak = lo_permission->publisher_package_name.
    ls_use_access-err_sever = lo_permission->error_severity.
    APPEND ls_use_access TO ls_devc-use_accesses.
  ENDLOOP.
* interfaces published
  IF is_obj_header-object EQ 'DEVC'.
    lo_package->get_interfaces(
      IMPORTING
        e_package_interfaces = lt_interface
      EXCEPTIONS
        object_invalid       = 1
        unexpected_error     = 2
        intern_err           = 3
        OTHERS               = 4
    ).
    PERFORM handle_rc USING is_obj_header.
    CHECK sy-subrc EQ 0.

    LOOP AT lt_interface INTO lo_interface.
      ls_interface-intf_name = lo_interface->interface_name.
      ls_interface-descript = lo_interface->short_text.
      ls_interface-pack_name = lo_interface->publisher_package_name.
      APPEND ls_interface TO ls_devc-interfaces.
    ENDLOOP.
  ENDIF.

  IF ls_devc-object EQ 'DEVC'.
    APPEND ls_devc TO gt_devc.
  ELSEIF ls_devc-object EQ 'DEVP'.
    ls_devc-activity = gcv_act_update.
    APPEND ls_devc TO gt_devp.
  ENDIF.
ENDFORM.

FORM get_additional_html_devc USING ls_devc TYPE s_devc CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM data2rows USING ls_devc 'S_DEVC' 'APPLICAT|UFPS_POSID|TRANSLATION_RELEVANCE|PARENTCL|DLVUNIT|KORRFLAG' CHANGING ct_html.
  PERFORM get_2column_value_html USING text_devc-label_tp_layer text_devc-txt_tp_note CHANGING ct_html.
ENDFORM.

FORM get_special_html_devc USING ls_devc TYPE s_devc CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  IF ls_devc-use_accesses IS NOT INITIAL.
    PERFORM get_small_title_html USING text_devc-title_access CHANGING ct_html.
    PERFORM get_paragraph_html USING text_devc-inst_devp_sub CHANGING ct_html.
    PERFORM table2html USING '' ls_devc-use_accesses 'PERMISSION' 'INTF_NAME|CLIENT_PAK|ERR_SEVER' abap_false '' CHANGING ct_html.
  ENDIF.

  IF ls_devc-interfaces IS NOT INITIAL.
    PERFORM get_small_title_html USING text_devc-title_interface CHANGING ct_html.
    PERFORM get_paragraph_html USING text_devc-inst_pinf_sub CHANGING ct_html.
    PERFORM table2html USING '' ls_devc-interfaces 'VINTF' 'INTF_NAME|DESCRIPT' abap_false '' CHANGING ct_html.
  ENDIF.
ENDFORM.
***************** Package Close *****************

***************** Package: Usage Begin *****************
FORM getdata_devp USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_devc_reuse USING is_obj_header.
ENDFORM.

FORM get_special_html_devp USING is_devp TYPE s_devp CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_small_title_html USING text_devc-title_access CHANGING ct_html.
  PERFORM get_paragraph_html USING text_devc-inst_devp CHANGING ct_html.
  PERFORM table2html USING '' is_devp-use_accesses 'PERMISSION' 'INTF_NAME|CLIENT_PAK|ERR_SEVER' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Package: Usage Close *****************

***************** Package: Interface Begin *****************
FORM getdata_pinf USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_pinf TYPE s_pinf.
  MOVE-CORRESPONDING is_obj_header TO ls_pinf.
  SELECT SINGLE * FROM vintf INTO CORRESPONDING FIELDS OF ls_pinf WHERE intf_name = ls_pinf-obj_name AND langu = sy-langu.
* check whether package interface is valid
  CHECK ls_pinf IS NOT INITIAL AND ls_pinf-pack_name IS NOT INITIAL.

  READ TABLE gt_devc WITH KEY obj_name = ls_pinf-pack_name TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  APPEND ls_pinf TO gt_pinf.
ENDFORM.

FORM convert_pinf.                                          "#EC CALLED
  CHECK gt_pinf IS NOT INITIAL.
  SORT gt_pinf BY pack_name ASCENDING.
  ADD 1 TO gv_header_no.
  PERFORM add_header_html USING 'PINF' CHANGING gt_html.
  PERFORM add_object_instruction_html USING 'PINF' CHANGING gt_html.
  PERFORM table2html USING '' gt_pinf 'VINTF' 'PACK_NAME|INTF_NAME|DESCRIPT' abap_false '' CHANGING gt_html.
ENDFORM.
***************** Package: Interface Close *****************
***************** Function Group Begin *****************
FORM getdata_fugr USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_fugr TYPE s_fugr.

  MOVE-CORRESPONDING is_obj_header TO ls_fugr.
  SELECT SINGLE areat FROM tlibt INTO ls_fugr-short_text WHERE spras = sy-langu AND area = ls_fugr-obj_name.
*  CHECK sy-subrc EQ 0.
  APPEND ls_fugr TO gt_fugr.
ENDFORM.
***************** Function Group Close *****************

***************** Function Group(Texts) Begin *****************
FORM getdata_fugt USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_fugt TYPE s_fugt.

  MOVE-CORRESPONDING is_obj_header TO ls_fugt.
  SELECT SINGLE areat FROM tlibt INTO ls_fugt-short_text WHERE spras = sy-langu AND area = ls_fugt-obj_name.
*  CHECK sy-subrc EQ 0.
  ls_fugt-activity = gcv_act_update.
  APPEND ls_fugt TO gt_fugt.
ENDFORM.
***************** Function Group(Texts) Close *****************
***************** Domain Begin *****************
FORM getdata_doma USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_doma_reuse USING is_obj_header.
ENDFORM.

FORM getdata_doma_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_doma        TYPE s_doma,
        lv_dm_name     TYPE ddobjname,
        ls_dd01v       TYPE dd01v.
  lv_dm_name = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_DOMA_GET'
    EXPORTING
      name          = lv_dm_name
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd01v_wa      = ls_dd01v
    TABLES
      dd07v_tab     = ls_doma-value_range
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd01v IS NOT INITIAL.

  MOVE-CORRESPONDING is_obj_header TO ls_doma.
  MOVE-CORRESPONDING ls_dd01v TO ls_doma.
  PERFORM get_activity USING ls_dd01v-as4date CHANGING ls_doma-activity.
  ls_doma-short_text = ls_dd01v-ddtext.

  IF ls_doma-object EQ 'DOMA'.
    APPEND ls_doma TO gt_doma.
  ELSEIF ls_doma-object EQ 'DOMD'.
    ls_doma-activity = gcv_act_update.
    APPEND ls_doma TO gt_doma.
  ENDIF.
ENDFORM.

FORM get_additional_html_doma USING is_doma TYPE s_doma CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM data2rows USING is_doma 'S_DOMA' 'DATATYPE|LENG|OUTPUTLEN|DECIMALS|LOWERCASE|SIGNFLAG|ENTITYTAB' CHANGING ct_html.
  IF is_doma-valexi EQ abap_true.
    PERFORM table2tr USING text_doma-label_value_range is_doma-value_range 'DD07V' 'DOMVALUE_L|DDTEXT' CHANGING ct_html.
  ENDIF.
ENDFORM.
***************** Domain Close *****************

***************** Domain Definition: Begin *****************
FORM getdata_domd USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_doma_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_domd USING is_domd TYPE s_domd CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM data2rows USING is_domd 'S_DOMA' 'DATATYPE|LENG|OUTPUTLEN|DECIMALS|LOWERCASE|SIGNFLAG|ENTITYTAB' CHANGING ct_html.
  IF is_domd-valexi EQ abap_true.
    PERFORM table2tr USING text_doma-label_value_range is_domd-value_range 'DD07V' 'DOMVALUE_L|DDTEXT' CHANGING ct_html.
  ENDIF.
ENDFORM.
***************** Domain Definition: Close *****************
***************** Data Element Begin *****************
FORM getdata_dtel USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_dtel_reuse USING is_obj_header.
ENDFORM.

FORM getdata_dtel_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_dtel    TYPE s_dtel,
        lv_de_name TYPE ddobjname,
        ls_dd04v   TYPE dd04v.

  lv_de_name = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_DTEL_GET'
    EXPORTING
      name          = lv_de_name
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd04v_wa      = ls_dd04v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd04v IS NOT INITIAL.

  MOVE-CORRESPONDING is_obj_header TO ls_dtel.
  MOVE-CORRESPONDING ls_dd04v TO ls_dtel.
  PERFORM get_activity USING ls_dd04v-as4date CHANGING ls_dtel-activity.
  ls_dtel-short_text = ls_dd04v-ddtext.

  IF ls_dtel-object EQ 'DTEL'.
    APPEND ls_dtel TO gt_dtel.
  ELSE.
    ls_dtel-activity = gcv_act_update.
    APPEND ls_dtel TO gt_dted.
  ENDIF.
ENDFORM.

FORM get_additional_html_dtel USING ls_dtel TYPE s_dtel CHANGING ct_html TYPE t_string. "#EC CALLED
  DATA: lv_tr   TYPE string,
        lv_td1  TYPE string,
        lv_td2  TYPE string,
        lv_td3  TYPE string,
        lv_tmp  TYPE string,
        lv_numc TYPE string,
        lt_tab  TYPE TABLE OF string,
        lv_labels  TYPE string.

  IF ls_dtel-domname IS NOT INITIAL.
    PERFORM get_2column_value_html USING text_dtel-label_domain ls_dtel-domname  CHANGING ct_html.
  ELSE.
    PERFORM format_numc USING ls_dtel-leng CHANGING lv_numc.
    CONCATENATE text_dtel-label_domain ': ' ls_dtel-datatype '<br>' text_dtel-label_length ': ' lv_numc INTO lv_tmp RESPECTING BLANKS.
    PERFORM get_2column_value_html USING text_dtel-label_predf_type lv_tmp CHANGING ct_html.
  ENDIF.
  PERFORM get_column_value_html USING text_dtel-label_fld_lab CHANGING lv_td1.
  CONCATENATE '<tr>' lv_td1 '<td>' INTO lv_tr RESPECTING BLANKS.

  APPEND gcv_table_begin TO lt_tab.
  CONCATENATE ' |' text_dtel-label_length '|' text_dtel-label_fld_lab INTO lv_labels RESPECTING BLANKS.
  PERFORM get_tr_label_html USING lv_labels CHANGING lt_tab.

  PERFORM get_column_value_html USING text_dtel-label_short CHANGING lv_td1.
  PERFORM get_column_value_html USING ls_dtel-scrlen1 CHANGING lv_td2.
  PERFORM get_column_value_html USING ls_dtel-scrtext_s CHANGING lv_td3.
  PERFORM combine3td USING lv_td1 lv_td2 lv_td3 CHANGING lt_tab.

  PERFORM get_column_value_html USING text_dtel-label_medium CHANGING lv_td1.
  PERFORM get_column_value_html USING ls_dtel-scrlen2 CHANGING lv_td2.
  PERFORM get_column_value_html USING ls_dtel-scrtext_m CHANGING lv_td3.
  PERFORM combine3td USING lv_td1 lv_td2 lv_td3 CHANGING lt_tab.

  PERFORM get_column_value_html USING text_dtel-label_long CHANGING lv_td1.
  PERFORM get_column_value_html USING ls_dtel-scrlen3 CHANGING lv_td2.
  PERFORM get_column_value_html USING ls_dtel-scrtext_l CHANGING lv_td3.
  PERFORM combine3td USING lv_td1 lv_td2 lv_td3 CHANGING lt_tab.

  PERFORM get_column_value_html USING text_dtel-label_heading CHANGING lv_td1.
  PERFORM get_column_value_html USING ls_dtel-headlen CHANGING lv_td2.
  PERFORM get_column_value_html USING ls_dtel-reptext CHANGING lv_td3.
  PERFORM combine3td USING lv_td1 lv_td2 lv_td3 CHANGING lt_tab.

  APPEND gcv_table_end TO lt_tab.
  PERFORM join_str USING lt_tab CHANGING lv_tmp.
  CONCATENATE lv_tr lv_tmp '</td></tr>' INTO lv_tr RESPECTING BLANKS.
  APPEND lv_tr TO ct_html.
ENDFORM.

FORM get_special_html_dtel USING ls_dtel TYPE s_dtel CHANGING ct_html TYPE t_string. "#EC CALLED
  DATA: ls_dokil TYPE dokil,
        lt_lines TYPE t_tline.

  SELECT SINGLE * FROM dokil INTO ls_dokil WHERE id = 'DE'
    AND object = ls_dtel-obj_name AND langu = sy-langu AND typ = 'E'.
  PERFORM read_docu_by_dokil USING ls_dokil CHANGING lt_lines.
  CHECK lt_lines IS NOT INITIAL.

  PERFORM get_small_title_html USING text_dtel-txt_mt_docu_title CHANGING ct_html.
  PERFORM get_paragraph_html USING text_dtel-txt_mt_docu_para CHANGING ct_html.
  PERFORM append_docu_html USING lt_lines CHANGING ct_html.
ENDFORM.

FORM read_docu_by_dokil USING is_dokil TYPE dokil CHANGING ct_lines TYPE t_tline.
  CHECK is_dokil IS NOT INITIAL.

  CALL FUNCTION 'DOCU_READ'
    EXPORTING
      id      = is_dokil-id
      langu   = is_dokil-langu
      object  = is_dokil-object
      typ     = is_dokil-typ
      version = is_dokil-version
    TABLES
      line    = ct_lines.
ENDFORM.

FORM append_docu_html USING it_lines TYPE t_tline CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM table2html USING '' it_lines 'TLINE' 'TDFORMAT|TDLINE' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Data Element Close *****************

***************** Data Element Definition Begin *****************
FORM getdata_dted USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_dtel_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_dted USING is_dted TYPE s_dted CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_additional_html_dtel USING is_dted CHANGING ct_html.
ENDFORM.

FORM get_special_html_dted USING is_dted TYPE s_dted CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_special_html_dtel USING is_dted CHANGING ct_html.
ENDFORM.
***************** Data Element Definition Close *****************
***************** Table Begin *****************
FORM getdata_tabl USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_tabl_reuse USING is_obj_header.
ENDFORM.

FORM getdata_tabl_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_tabl    TYPE s_tabl,
        lv_tabname TYPE ddobjname,
        ls_dd02v   TYPE dd02v,
        lt_dd36m   TYPE dd36mttyp,
        lt_dd05m   TYPE dd05mttyp,
        lt_dd03p   TYPE dd03ttyp,
        lt_dd12v   TYPE dd12vtab,
        lt_dd17v   TYPE dd17vtab,
        ls_fk_def     TYPE s_tabl_fk_def,
        ls_tabl_fld   TYPE s_tabl_field,
        ls_tabl_index TYPE s_tabl_index.
  FIELD-SYMBOLS: <fs_dd05m> TYPE dd05m,
                 <fs_dd03p> TYPE dd03p,
                 <fs_dd12v> TYPE dd12v,
                 <fs_dd17v> TYPE dd17v.

  lv_tabname = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_TABL_GET'
    EXPORTING
      name          = lv_tabname
      langu         = sy-langu
    IMPORTING
      dd02v_wa      = ls_dd02v                      " table header information
      dd09l_wa      = ls_tabl-tech_setting          " technical setting
    TABLES
      dd03p_tab     = lt_dd03p                      " fields
      dd05m_tab     = lt_dd05m                      " foreign key
      dd08v_tab     = ls_tabl-foreign_key_header    " foreign key headers and texts
      dd12v_tab     = lt_dd12v                      " indexes with text
      dd17v_tab     = lt_dd17v                      " secondary indexes
      dd35v_tab     = ls_tabl-assignments           " assignment of structure fields and search helps
      dd36m_tab     = lt_dd36m                      " interface structure for field assignments table-search help
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd02v IS NOT INITIAL AND lt_dd03p IS NOT INITIAL.

  MOVE-CORRESPONDING is_obj_header TO ls_tabl.
  MOVE-CORRESPONDING ls_dd02v TO ls_tabl.
  ls_tabl-short_text = ls_dd02v-ddtext.
* convert table/structure fields
  LOOP AT lt_dd03p ASSIGNING <fs_dd03p>.
    MOVE-CORRESPONDING <fs_dd03p> TO ls_tabl_fld.
    IF <fs_dd03p>-fieldname EQ '.INCLUDE'.
      ls_tabl_fld-rollname = <fs_dd03p>-precfield.
    ENDIF.

    IF <fs_dd03p>-adminfield NE 0.
      CLEAR ls_tabl_fld-fieldname.
      CONCATENATE '<i>' <fs_dd03p>-fieldname '</i>' INTO ls_tabl_fld-fieldname RESPECTING BLANKS.
    ENDIF.

    IF ls_tabl-tabclass EQ 'INTTAB'.
      PERFORM get_tabl_comp_typing_method USING <fs_dd03p> CHANGING ls_tabl_fld-typing_method.
    ENDIF.
    APPEND ls_tabl_fld TO ls_tabl-fields.
    CLEAR ls_tabl_fld.
  ENDLOOP.
* convert foreign key definition
  LOOP AT lt_dd05m ASSIGNING <fs_dd05m>.
    MOVE-CORRESPONDING <fs_dd05m> TO ls_fk_def.
    IF <fs_dd05m>-forkey IS INITIAL.
      ls_fk_def-fortable = abap_false.
    ENDIF.

    IF <fs_dd05m>-fortable EQ '*'.
      ls_fk_def-generic = abap_true.
    ENDIF.

    IF <fs_dd05m>-forkey IS INITIAL AND <fs_dd05m>-fortable NE '*'.
      ls_fk_def-constant = <fs_dd05m>-fortable.
    ENDIF.
    APPEND ls_fk_def TO ls_tabl-foreign_keys.
    CLEAR ls_fk_def.
  ENDLOOP.
* convert table index
  LOOP AT lt_dd12v ASSIGNING <fs_dd12v>.
    MOVE-CORRESPONDING <fs_dd12v> TO ls_tabl_index.
    LOOP AT lt_dd17v ASSIGNING <fs_dd17v> WHERE indexname EQ <fs_dd12v>-indexname.
      CONCATENATE ls_tabl_index-index_fields '<br>' <fs_dd17v>-fieldname INTO ls_tabl_index-index_fields.
    ENDLOOP.

    SHIFT ls_tabl_index-index_fields BY 4 PLACES.
    APPEND ls_tabl_index TO ls_tabl-index.
    CLEAR ls_tabl_index.
  ENDLOOP.
* namespace reservation
  SELECT * FROM tresc INTO TABLE ls_tabl-namespace WHERE tabname = ls_tabl-obj_name.
  PERFORM get_activity USING ls_dd02v-as4date CHANGING ls_tabl-activity.

  IF ls_tabl-object EQ 'TABL'.
    APPEND ls_tabl TO gt_tabl.
  ELSEIF ls_tabl-object EQ 'TABL'.
    ls_tabl-activity = gcv_act_update.
    APPEND ls_tabl TO gt_tabd.
  ENDIF.
ENDFORM.

FORM get_additional_html_tabl USING ls_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  IF ls_tabl-tabclass EQ 'TRANSP'.
    PERFORM data2rows USING ls_tabl 'S_TABL' 'CONTFLAG|MAINFLAG' CHANGING ct_html.
  ENDIF.
ENDFORM.

FORM get_special_html_tabl USING is_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_tabl_fields_html USING is_tabl CHANGING ct_html.
  PERFORM get_tabl_fk_setting_html USING is_tabl CHANGING ct_html.
  PERFORM get_tabl_techsetting_html USING is_tabl CHANGING ct_html.
  PERFORM get_tabl_namespace_html USING is_tabl CHANGING ct_html.
  PERFORM get_tabl_index_html USING is_tabl CHANGING ct_html.
ENDFORM.

FORM get_tabl_fields_html USING is_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE.
  DATA lv_show_note_flds TYPE abap_bool.
  FIELD-SYMBOLS <fs_fld> TYPE s_tabl_field.

  LOOP AT is_tabl-fields ASSIGNING <fs_fld> WHERE fieldname EQ '.INCLUDE'.
    lv_show_note_flds = abap_true.
  ENDLOOP.
  " we will handle transparent table and structure currently
  IF is_tabl-tabclass EQ 'TRANSP'.
    PERFORM get_small_title_html USING text_tabl-title_flds CHANGING ct_html.
    IF lv_show_note_flds EQ abap_true.
      PERFORM get_paragraph_html USING text_tabl-note_flds CHANGING ct_html.
    ENDIF.
    PERFORM table2html USING '' is_tabl-fields 'S_TABL_FIELD' 'FIELDNAME|KEYFLAG|ROLLNAME|CHECKTABLE|SHLPNAME' abap_true 'CHECKTABLE|SHLPNAME' CHANGING ct_html.
  ELSEIF is_tabl-tabclass EQ 'INTTAB'.
    PERFORM get_small_title_html USING text_tabl-title_comps CHANGING ct_html.
    IF lv_show_note_flds EQ abap_true.
      PERFORM get_paragraph_html USING text_tabl-note_comps CHANGING ct_html.
    ENDIF.
    PERFORM table2html USING '' is_tabl-fields 'S_TABL_FIELD' 'FIELDNAME|TYPING_METHOD|ROLLNAME' abap_false '' CHANGING ct_html.
  ENDIF.
ENDFORM.

FORM get_tabl_comp_typing_method USING is_fld TYPE dd03p CHANGING cv_typing_method TYPE string.
  CONSTANTS: c_t_ref       VALUE 'R',
             c_t_boxed     VALUE 'J',
             c_type        TYPE f_reftype VALUE '1',     " type
             c_type_ref_to TYPE f_reftype VALUE '3',     " type ref to
             c_type_boxed  TYPE f_reftype VALUE '5'.     " type ... boxed
  DATA: lv_txt TYPE ddtext,
        lv_low TYPE ddfixvalue-low,
        lv_f_reftype TYPE f_reftype.

  CLEAR cv_typing_method.

  IF is_fld-comptype EQ c_t_ref.
    IF is_fld-reftype = c_t_boxed.
      lv_f_reftype = c_type_boxed.
    ELSE.
      lv_f_reftype = c_type_ref_to.
    ENDIF.
  ELSE.
    lv_f_reftype = c_type.
  ENDIF.

  lv_low = lv_f_reftype.
  PERFORM get_value_desc USING 'F_REFTYPE' lv_low CHANGING lv_txt.
  CONCATENATE lv_f_reftype ' ' lv_txt INTO cv_typing_method RESPECTING BLANKS.
ENDFORM.

FORM get_tabl_techsetting_html USING is_tabl TYPE s_tabl CHANGING ct_html TYPE t_string.
  CHECK is_tabl-tabclass EQ 'TRANSP'.
  PERFORM get_techsetting_html USING is_tabl-tech_setting CHANGING ct_html.
ENDFORM.

FORM get_techsetting_html USING is_dd09v TYPE dd09v CHANGING ct_html TYPE t_string.
  DATA lt_dd09v TYPE TABLE OF dd09v.
  APPEND is_dd09v TO lt_dd09v.
  PERFORM table2html USING text_tabl-title_tech lt_dd09v 'DD09V' 'TABART|TABKAT|BUFALLOW|PUFFERUNG|PROTOKOLL|JAVAONLY' abap_false '' CHANGING ct_html.
ENDFORM.

FORM get_tabl_fk_setting_html USING is_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_tmp  TYPE string,
        lv_card TYPE string,
        lv_fkt  TYPE ddtext,
        lv_low  TYPE ddfixvalue-low,
        lv_screen_check TYPE c.
  FIELD-SYMBOLS: <fs_header> LIKE LINE OF is_tabl-foreign_key_header.

  CHECK is_tabl-tabclass EQ 'TRANSP' AND is_tabl-foreign_key_header IS NOT INITIAL AND is_tabl-foreign_keys IS NOT INITIAL.

  PERFORM get_small_title_html USING text_tabl-title_fks CHANGING ct_html.
  LOOP AT is_tabl-foreign_key_header ASSIGNING <fs_header>.
    CLEAR: lv_screen_check, lv_card.
    CONCATENATE text_tabl-note_fks '<b>' <fs_header>-fieldname '</b>' INTO lv_tmp RESPECTING BLANKS.
    PERFORM get_paragraph_html USING lv_tmp CHANGING ct_html.

    APPEND gcv_table_begin TO ct_html.
    PERFORM get_default2column_html CHANGING ct_html.
    PERFORM data2rows USING <fs_header> 'S_TABL_FK_DEF' 'FIELDNAME|CHECKTABLE|DDTEXT' CHANGING ct_html.
    " foreign key definitions
    PERFORM get_fk_fld_definition_html USING is_tabl-foreign_keys <fs_header>-fieldname CHANGING lv_tmp.
    PERFORM get_2column_right_table_html USING text_tabl-label_fk_flds lv_tmp CHANGING ct_html.
    " screen check attributes: screen check flag differs from checkflag
    lv_screen_check = boolc( <fs_header>-checkflag EQ abap_false ).
    IF lv_screen_check IS NOT INITIAL OR <fs_header>-msgnr IS NOT INITIAL OR <fs_header>-arbgb IS NOT INITIAL.
      CONCATENATE text_tabl-label_check_rq lv_screen_check '&nbsp;&nbsp; ' text_tabl-label_msg_no <fs_header>-msgnr '&nbsp;&nbsp; ' text_tabl-label_aarea <fs_header>-arbgb
        INTO lv_tmp RESPECTING BLANKS.
      PERFORM get_2column_value_html USING text_tabl-label_screen_check lv_tmp CHANGING ct_html.
      CLEAR lv_tmp.
    ENDIF.
    " semantic attributes
    lv_low = <fs_header>-frkart.
    PERFORM get_value_desc USING 'FRKART' lv_low CHANGING lv_fkt.
    IF <fs_header>-cardleft IS NOT INITIAL OR <fs_header>-card IS NOT INITIAL.
      CONCATENATE '<br>' text_tabl-label_card '[' <fs_header>-cardleft '&nbsp;&nbsp;:&nbsp;&nbsp;' <fs_header>-card ']' INTO lv_card RESPECTING BLANKS.
    ENDIF.
    CONCATENATE text_tabl-label_fk_type lv_fkt lv_card INTO lv_tmp RESPECTING BLANKS.
    PERFORM get_2column_value_html USING text_tabl-label_fk_semantic lv_tmp CHANGING ct_html.
    CLEAR lv_tmp.

    APPEND gcv_table_end TO ct_html.
    APPEND '<br>' TO ct_html.
  ENDLOOP.
ENDFORM.

FORM get_fk_fld_definition_html USING it_fk_def TYPE t_tabl_fk_def iv_fieldname TYPE fieldname CHANGING cv_html TYPE string.
  DATA: lt_html   TYPE t_string,
        lt_fk_def TYPE t_tabl_fk_def.
  PERFORM get_fk_fld_def_by_name USING it_fk_def iv_fieldname CHANGING lt_fk_def.
  PERFORM convert_table_html USING '' lt_fk_def 'S_TABL_FK_DEF'
        'CHECKTABLE|CHECKFIELD|FORTABLE|FORKEY|GENERIC|CONSTANT' abap_true 'GENERIC|CONSTANT' abap_true CHANGING lt_html.
  PERFORM join_str USING lt_html CHANGING cv_html.
ENDFORM.

FORM get_fk_fld_def_by_name USING it_fk_def TYPE t_tabl_fk_def iv_fieldname TYPE fieldname CHANGING ct_fld_def TYPE t_tabl_fk_def.
  FIELD-SYMBOLS: <fs_fk_def> TYPE s_tabl_fk_def.
  LOOP AT it_fk_def ASSIGNING <fs_fk_def> WHERE fieldname EQ iv_fieldname.
    APPEND <fs_fk_def> TO ct_fld_def.
  ENDLOOP.
ENDFORM.

FORM get_tabl_namespace_html USING is_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE.
* only transparent table with delivery class E need to display namespace maintainance settings
  CHECK is_tabl-tabclass EQ 'TRANSP' AND is_tabl-contflag EQ 'E' AND is_tabl-namespace IS NOT INITIAL.
  PERFORM table2html USING text_tabl-title_namespace is_tabl-namespace 'TRESC' 'FIELDNAME|KEYLOW' abap_false '' CHANGING ct_html.
ENDFORM.

FORM get_tabl_index_html USING is_tabl TYPE s_tabl CHANGING ct_html TYPE STANDARD TABLE.
  CHECK is_tabl-tabclass EQ 'TRANSP' AND is_tabl-index IS NOT INITIAL.
  PERFORM table2html USING text_tabl-title_index is_tabl-index 'S_TABL_INDEX' '' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Table Close *****************

***************** Table Definition Begin *****************
FORM getdata_tabd USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_tabl_reuse USING is_obj_header.
ENDFORM.

FORM get_special_html_tabd USING is_tabd TYPE s_tabd CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_special_html_tabl USING is_tabd CHANGING ct_html.
ENDFORM.
***************** Table Definition Close *****************
***************** Technical Attributes of a Table Begin *****************
TYPES: BEGIN OF s_tabt.
        INCLUDE TYPE s_obj_header.
TYPES: tech_setting TYPE dd09v.
TYPES: END OF s_tabt.
DATA gt_tabt TYPE TABLE OF s_tabt.                          "#EC NEEDED

FORM getdata_tabt USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_tabt  TYPE s_tabt,
        lv_ddobj TYPE ddobjname.

  MOVE-CORRESPONDING is_obj_header TO ls_tabt.
  lv_ddobj = ls_tabt-obj_name.
  CALL FUNCTION 'DDIF_TABT_GET'
    EXPORTING
      name          = lv_ddobj
      state         = 'A'
    IMPORTING
      dd09l_wa      = ls_tabt-tech_setting
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_tabt-tech_setting IS NOT INITIAL.

  APPEND ls_tabt TO gt_tabt.
ENDFORM.

FORM get_special_html_tabt USING is_tabt TYPE s_tabt CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_techsetting_html USING is_tabt-tech_setting CHANGING ct_html.
ENDFORM.
***************** Technical Attributes of a Table Close *****************

***************** Table Index Begin *****************
TYPES: t_dd17v TYPE STANDARD TABLE OF dd17v WITH DEFAULT KEY.
TYPES: BEGIN OF s_indx.
        INCLUDE TYPE s_obj_header.
TYPES: header TYPE dd12v.
TYPES: fields TYPE string.
TYPES: END OF s_indx.
DATA gt_indx TYPE TABLE OF s_indx.                          "#EC NEEDED

FORM getdata_indx USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_indx     TYPE s_indx,
        lv_table    TYPE ddobjname,
        lt_dd17v    TYPE TABLE OF dd17v,
        lv_index_id TYPE ddobjectid.
  MOVE-CORRESPONDING is_obj_header TO ls_indx.
  CALL FUNCTION 'DDIF_INDX_GET'
    EXPORTING
      name          = lv_table
      id            = lv_index_id
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd12v_wa      = ls_indx-header
    TABLES
      dd17v_tab     = lt_dd17v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_indx-header IS NOT INITIAL AND ls_indx-fields IS NOT INITIAL.
  PERFORM collect_tab_fld USING lt_dd17v 'FIELDNAME' `, ` CHANGING ls_indx-fields.
  APPEND ls_indx TO gt_indx.
ENDFORM.

FORM get_additional_html_indx USING is_indx TYPE s_indx CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM data2rows_common USING is_indx-header 'DD12V' 'SQLTAB|INDEXNAME|UNIQUEFLAG|DBINDEX|DBSTATE|FIELDS' abap_false CHANGING ct_html.
  IF is_indx-header-dbstate EQ 'D'.
    PERFORM data2rows USING is_indx-header 'DD12V' 'DBINCLEXCL|DBSYSSEL1|DBSYSSEL2|DBSYSSEL3|DBSYSSEL4' CHANGING ct_html.
  ENDIF.
ENDFORM.
***************** Table Index Close *****************
***************** View Begin *****************
FORM getdata_view USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_view_reuse USING is_obj_header.
ENDFORM.

FORM getdata_view_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_view  TYPE s_view,
        lv_view_name TYPE ddobjname,
        ls_dd25v TYPE dd25v.

  MOVE-CORRESPONDING is_obj_header TO ls_view.
  lv_view_name = ls_view-obj_name.
  CALL FUNCTION 'DDIF_VIEW_GET'
    EXPORTING
      name          = lv_view_name
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd25v_wa      = ls_dd25v
      dd09l_wa      = ls_view-tech_setting
    TABLES
      dd26v_tab     = ls_view-table_join
      dd27p_tab     = ls_view-fields
      dd28j_tab     = ls_view-join_condition
      dd28v_tab     = ls_view-selection_condition
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd25v IS NOT INITIAL.

  MOVE-CORRESPONDING ls_dd25v TO ls_view.
  PERFORM get_activity USING ls_dd25v-as4date CHANGING ls_view-activity.
  ls_view-short_text = ls_dd25v-ddtext.

  IF ls_view-object EQ 'VIEW'.
    APPEND ls_view TO gt_view.
  ELSEIF ls_view-object EQ 'VIED'.
    ls_view-activity = gcv_act_update.
    APPEND ls_view TO gt_vied.
  ENDIF.
ENDFORM.

FORM get_additional_html_view USING ls_view TYPE s_view CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM data2rows USING ls_view 'S_VIEW' 'VIEWGRANT|CUSTOMAUTH|GLOBALFLAG' CHANGING ct_html.
ENDFORM.

FORM get_special_html_view USING is_view TYPE s_view CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_jointable_html USING is_view CHANGING ct_html.
  PERFORM get_view_fields_html USING is_view CHANGING ct_html.
  PERFORM get_selcondition_html USING is_view CHANGING ct_html.

  DATA lt_dd09v TYPE TABLE OF dd09v.
  CHECK is_view-tech_setting IS NOT INITIAL.
  APPEND is_view-tech_setting TO lt_dd09v.
  PERFORM table2html USING text_tabl-title_tech lt_dd09v 'DD09V' 'BUFALLOW|PUFFERUNG' abap_false '' CHANGING ct_html.
ENDFORM.

FORM get_jointable_html USING is_view TYPE s_view CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_tmp  TYPE string.
  FIELD-SYMBOLS: <fs_tb> TYPE dd26v.

  LOOP AT is_view-table_join ASSIGNING <fs_tb>.
    CONCATENATE lv_tmp ', ' <fs_tb>-tabname INTO lv_tmp RESPECTING BLANKS.
  ENDLOOP.
  SHIFT lv_tmp BY 2 PLACES.
  CONCATENATE text_view-title_tables lv_tmp INTO lv_tmp RESPECTING BLANKS.
  PERFORM get_paragraph_html USING lv_tmp CHANGING ct_html.

  IF is_view-join_condition IS INITIAL.
    PERFORM get_paragraph_html USING text_view-note_join_cond CHANGING ct_html.
    APPEND '<br>' TO ct_html.
  ELSE.
    PERFORM table2html USING text_view-title_join_conds is_view-join_condition 'DD28J' 'LTAB|LFIELD|OPERATOR|RTAB|RFIELD' abap_false '' CHANGING ct_html.
  ENDIF.
ENDFORM.

FORM get_view_fields_html USING is_view TYPE s_view CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM table2html USING text_view-title_fields is_view-fields 'DD27P'
          'VIEWFIELD|TABNAME|FIELDNAME|RDONLY|KEYFLAG|ROLLCHANGE' abap_true 'RDONLY|ROLLCHANGE' CHANGING ct_html.
ENDFORM.

FORM get_selcondition_html USING is_view TYPE s_view CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM get_small_title_html USING text_view-title_sel_conds CHANGING ct_html.
  IF is_view-selection_condition IS INITIAL.
    PERFORM get_paragraph_html USING text_view-note_sel_cond CHANGING ct_html.
    APPEND '<br>' TO ct_html.
  ELSE.
    PERFORM table2html USING '' is_view-selection_condition 'DD28V' 'TABNAME|FIELDNAME|OPERATOR|CONSTANTS|AND_OR' abap_false '' CHANGING ct_html.
  ENDIF.
ENDFORM.
***************** View Close *****************

***************** View Definition Begin *****************
FORM getdata_vied USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  READ TABLE gt_view WITH KEY obj_name = is_obj_header-obj_name TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  PERFORM getdata_view_reuse USING is_obj_header.
ENDFORM.

FORM get_special_html_vied USING is_vied TYPE s_vied CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_special_html_view USING is_vied CHANGING ct_html.
ENDFORM.
***************** View Definition Close *****************

TYPES: BEGIN OF s_viet.
        INCLUDE TYPE s_obj_header.
TYPES: tech_setting TYPE dd09v.
TYPES: END OF s_viet.
DATA gt_viet TYPE TABLE OF s_viet.                          "#EC NEEDED

***************** Technical Attributes of a View Begin *****************
FORM getdata_viet USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_viet  TYPE s_viet,
        lv_ddobj TYPE ddobjname.

  READ TABLE gt_view WITH KEY obj_name = is_obj_header-obj_name TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  READ TABLE gt_vied WITH KEY obj_name = is_obj_header-obj_name TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.

  MOVE-CORRESPONDING is_obj_header TO ls_viet.
  lv_ddobj = ls_viet-obj_name.
  CALL FUNCTION 'DDIF_VIET_GET'
    EXPORTING
      name          = lv_ddobj
    IMPORTING
      dd09l_wa      = ls_viet-tech_setting
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_viet-tech_setting IS NOT INITIAL.
  ls_viet-activity = gcv_act_update.
  APPEND ls_viet TO gt_viet.
ENDFORM.

FORM get_special_html_viet USING is_viet TYPE s_viet CHANGING ct_html TYPE t_string. "#EC CALLED
  DATA lt_dd09v TYPE TABLE OF dd09v.
  APPEND is_viet-tech_setting TO lt_dd09v.
  PERFORM table2html USING '' lt_dd09v 'DD09V' 'TABNAME|BUFALLOW|PUFFERUNG' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Technical Attributes of a View Close *****************
***************** Search Help Begin *****************
FORM getdata_shlp USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_shlp_reuse USING is_obj_header.
ENDFORM.

FORM getdata_shlp_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_shlp TYPE s_shlp,
        lv_shlp_name TYPE ddobjname,
        ls_dd30v TYPE dd30v,
        lt_dd31v TYPE TABLE OF dd31v,
        lt_dd33v TYPE TABLE OF dd33v.

  lv_shlp_name = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_SHLP_GET'
    EXPORTING
      name          = lv_shlp_name
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd30v_wa      = ls_dd30v
    TABLES
      dd31v_tab     = lt_dd31v
      dd32p_tab     = ls_shlp-params
      dd33v_tab     = lt_dd33v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd30v IS NOT INITIAL.

  MOVE-CORRESPONDING is_obj_header TO ls_shlp.
  MOVE-CORRESPONDING ls_dd30v TO ls_shlp.
  PERFORM get_activity USING ls_dd30v-as4date CHANGING ls_shlp-activity.
  ls_shlp-short_text = ls_dd30v-ddtext.

  IF ls_shlp-object EQ 'SHLP'.
    APPEND ls_shlp TO gt_shlp.
  ELSEIF ls_shlp-object EQ 'SHLD'.
    ls_shlp-activity = gcv_act_update.
    APPEND ls_shlp TO gt_shld.
  ENDIF.
ENDFORM.

FORM get_additional_html_shlp USING ls_shlp TYPE s_shlp CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  DATA: lv_type TYPE string.
  IF ls_shlp-issimple EQ abap_true.
    lv_type = text_shlp-txt_type_ele.
  ELSE.
    lv_type = text_shlp-txt_type_col.
  ENDIF.
  PERFORM get_2column_value_html USING text_shlp-txt_type lv_type CHANGING ct_html.
  PERFORM data2rows USING ls_shlp 'DD30V' 'SELMETHOD|DIALOGTYPE|HOTKEY|SELMEXIT' CHANGING ct_html.
ENDFORM.

FORM get_special_html_shlp USING is_shlp TYPE s_shlp CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM table2html USING text_enqu-label_params is_shlp-params 'DD32P'
          'FIELDNAME|SHLPINPUT|SHLPOUTPUT|SHLPSELPOS|SHLPLISPOS|SHLPSELDIS|ROLLNAME|ROLLCHANGE|DEFAULTVAL' abap_true 'DEFAULTVAL' CHANGING ct_html.
ENDFORM.
***************** Search Help Close *****************

***************** Search Help Definition Begin *****************
FORM getdata_shld USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_shlp_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_shld USING is_shld TYPE s_shld CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_additional_html_shlp USING is_shld CHANGING ct_html.
ENDFORM.

FORM get_special_html_shld USING is_shld TYPE s_shld CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_special_html_shlp USING is_shld CHANGING ct_html.
ENDFORM.
***************** Search Help Definition Close *****************
***************** Lock Object Begin *****************
FORM getdata_enqu USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_enqu_reuse USING is_obj_header.
ENDFORM.

FORM getdata_enqu_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_enqu TYPE s_enqu,
        ls_dd25v     TYPE dd25v,
        lt_dd27p     TYPE TABLE OF dd27p,
        lv_lock_name TYPE ddobjname.

  lv_lock_name = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_ENQU_GET'
    EXPORTING
      name          = lv_lock_name
      state         = 'A'
      langu         = sy-langu
    IMPORTING
      dd25v_wa      = ls_dd25v            "lock object attributes(similar as that of view)
    TABLES
      dd26e_tab     = ls_enqu-base_tables "base tables
      dd27p_tab     = lt_dd27p            "view fields
      ddena_tab     = ls_enqu-lock_params "lock argument fields
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd25v IS NOT INITIAL.
  MOVE-CORRESPONDING is_obj_header TO ls_enqu.
  ls_enqu-short_text = ls_dd25v-ddtext.
  PERFORM get_activity USING ls_dd25v-as4date CHANGING ls_enqu-activity.

  IF ls_enqu-object EQ 'ENQU'.
    APPEND ls_enqu TO gt_enqu.
  ELSEIF ls_enqu-object EQ 'ENQD'.
    ls_enqu-activity = gcv_act_update.
    APPEND ls_enqu TO gt_enqd.
  ENDIF.
ENDFORM.

FORM get_additional_html_enqu USING ls_enqu TYPE s_enqu CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_2column_value_html USING text_enqu-label_allow_rfc ls_enqu-rfcenable CHANGING ct_html.
ENDFORM.

FORM get_special_html_enqu USING is_enqu TYPE s_enqu CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM table2html USING text_enqu-label_tables is_enqu-base_tables 'DD26E' 'TABPOS|TABNAME|ENQMODE' abap_false '' CHANGING ct_html.
  PERFORM table2html USING text_enqu-label_params is_enqu-lock_params 'DDENA' 'VIEWFIELD|TABNAME|FIELDNAME' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Lock Object Close *****************

***************** Lock Object Definition Begin *****************
FORM getdata_enqd USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_enqu_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_enqd USING is_enqd TYPE s_enqd CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_additional_html_enqu USING is_enqd CHANGING ct_html.
ENDFORM.

FORM get_special_html_enqd USING is_enqd TYPE s_enqd CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_special_html_enqu USING is_enqd CHANGING ct_html.
ENDFORM.
***************** Lock Object Definition Close *****************
***************** Table Type Begin *****************
FORM getdata_ttyp USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_ttyp_reuse USING is_obj_header.
ENDFORM.

FORM getdata_ttyp_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_ttyp TYPE s_ttyp,
        lv_ttype_name TYPE ddobjname,
        ls_dd40v      TYPE dd40v.

  lv_ttype_name = is_obj_header-obj_name.
  CALL FUNCTION 'DDIF_TTYP_GET'
    EXPORTING
      name          = lv_ttype_name
      langu         = sy-langu
    IMPORTING
      dd40v_wa      = ls_dd40v
    TABLES
      dd42v_tab     = ls_ttyp-primary_key
      dd43v_tab     = ls_ttyp-secondary_key
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.                                    "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_dd40v IS NOT INITIAL.
  MOVE-CORRESPONDING is_obj_header TO ls_ttyp.

  MOVE-CORRESPONDING ls_dd40v TO ls_ttyp.
  PERFORM get_activity USING ls_dd40v-as4date CHANGING ls_ttyp-activity.
  ls_ttyp-short_text = ls_dd40v-ddtext.

  IF ls_ttyp-object EQ 'TTYP'.
    APPEND ls_ttyp TO gt_ttyp.
  ELSEIF ls_ttyp-object EQ 'TTYD'.
    ls_ttyp-activity = gcv_act_update.
    APPEND ls_ttyp TO gt_ttyd.
  ENDIF.
ENDFORM.

FORM get_additional_html_ttyp USING is_ttyp TYPE s_ttyp CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_2column_value_html USING text_ttyp-label_row_type is_ttyp-rowtype CHANGING ct_html.
ENDFORM.
***************** Table Type Close *****************

***************** Table Type Definition Begin *****************
FORM getdata_ttyd USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_ttyp_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_ttyd USING is_ttyd TYPE s_ttyd CHANGING ct_html TYPE t_string. "#EC CALLED
  PERFORM get_additional_html_ttyp USING is_ttyd CHANGING ct_html.
ENDFORM.
***************** Table Type Definition Close *****************
***************** Definition of a Maintenance and Transport Object Begin *****************
FORM getdata_tobj USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_tobj TYPE s_tobj,
        ls_tvdir TYPE tvdir,
        lv_len   TYPE i,
        ls_tddat TYPE tddat.

  MOVE-CORRESPONDING is_obj_header TO ls_tobj.
  lv_len = strlen( ls_tobj-obj_name ) - 1.
  SELECT SINGLE * FROM tvdir INTO ls_tvdir WHERE tabname = ls_tobj-obj_name(lv_len).
  IF sy-subrc NE 0.
    IF ls_tobj-obj_name+lv_len(1) EQ 'C'.
      " maintenance object also exists for view cluster and will be ignored
      PERFORM add_obj_gen_msg USING is_obj_header 'W' ''.
    ELSE.
      PERFORM add_obj_gen_msg USING is_obj_header 'E' text_tobj-msg_obj_invalid.
    ENDIF.
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING ls_tvdir TO ls_tobj.
  ls_tobj-maint_type = ls_tvdir-type.
  ls_tobj-devclass = ls_tvdir-devclass.
  SELECT SINGLE * FROM tddat INTO ls_tddat WHERE tabname = ls_tvdir-tabname.
  MOVE-CORRESPONDING ls_tddat TO ls_tobj.
  SELECT * FROM tvimf INTO CORRESPONDING FIELDS OF TABLE ls_tobj-events WHERE tabname = ls_tobj-tabname.

  APPEND ls_tobj TO gt_tobj.
ENDFORM.

FORM get_additional_html_tobj USING ls_tobj TYPE s_tobj CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM data2rows USING ls_tobj 'S_TOBJ' 'TABNAME|CCLASS|AREA|DEVCLASS|MAINT_TYPE|LISTE|DETAIL' CHANGING ct_html.
ENDFORM.

FORM get_special_html_tobj USING ls_tobj TYPE s_tobj CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  CHECK ls_tobj-events IS NOT INITIAL.
  PERFORM get_small_title_html USING text_tobj-label_events CHANGING ct_html.
  PERFORM get_paragraph_html USING text_tobj-txt_mt_event CHANGING ct_html.
  PERFORM table2html USING '' ls_tobj-events 'TVIMF' 'EVENT|FORMNAME' abap_false '' CHANGING ct_html.
ENDFORM.
***************** Definition of a Maintenance and Transport Object Close *****************
***************** View cluster Begin *****************
FORM getdata_vcls USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_vcls         TYPE s_vcls.

  PERFORM get_vcls_reuse USING is_obj_header CHANGING ls_vcls.
  CHECK sy-subrc EQ 0.
  APPEND ls_vcls TO gt_vcls.
ENDFORM.

FORM get_vcls_reuse USING is_obj_header TYPE s_obj_header CHANGING cs_vcls TYPE s_vcls.
  DATA: lv_vcls_name TYPE vcl_name,
        ls_vcldir    TYPE v_vcldir.

  CLEAR cs_vcls.
  READ TABLE gt_vcls INTO cs_vcls WITH KEY object = 'VCLS' obj_name = is_obj_header-obj_name.
  CHECK sy-subrc NE 0.

  lv_vcls_name = is_obj_header-obj_name.
  CALL FUNCTION 'VIEWCLUSTER_GET_DEFINITION'
    EXPORTING
      vclname                = lv_vcls_name
    IMPORTING
      vcldir_entry           = ls_vcldir
    TABLES
      vclstruc_tab           = cs_vcls-object_stru
      vclstrudep_tab         = cs_vcls-field_dep
      vclmf_tab              = cs_vcls-events
    EXCEPTIONS
      viewcluster_not_found  = 1
      incomplete_viewcluster = 2
      OTHERS                 = 3.                           "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.

  CHECK is_obj_header-object EQ 'VCLS'.
  MOVE-CORRESPONDING is_obj_header TO cs_vcls.
  PERFORM get_activity USING ls_vcldir-changedate CHANGING cs_vcls-activity.
  cs_vcls-short_text = ls_vcldir-text.
ENDFORM.

FORM get_additional_html_vcls USING ls_vcls TYPE s_vcls CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  DATA: lv_low       TYPE ddfixvalue-low,
        lv_hierarchy TYPE ddtext,
        lv_readtype  TYPE string.

  lv_low = ls_vcls-hieropsoff.
  PERFORM get_value_desc USING 'VCLS_HIERARCHY' lv_low CHANGING lv_hierarchy.
  PERFORM get_2column_value_html USING text_vcls-label_hier lv_hierarchy CHANGING ct_html.
  IF ls_vcls-readkind EQ 'T'.
    lv_readtype = text_vcls-txt_type_sub.
  ELSE.
    lv_readtype = text_vcls-txt_type_comp.
  ENDIF.
  PERFORM get_2column_value_html USING text_vcls-label_type lv_readtype CHANGING ct_html.
  PERFORM data2rows USING ls_vcls 'VCLDIR' 'EXITPROG' CHANGING ct_html.
ENDFORM.

FORM get_special_html_vcls USING is_vcls TYPE s_vcls CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM table2html USING text_vcls-title_obj_stru is_vcls-object_stru 'V_VCLSTRUC'
        'OBJECT|OBJECTTEXT|PREDOBJECT|DEPENDENCY|OBJPOS|STARTOBJ|SUPPRESS|CARDINAL|SWITCH_ID' abap_true 'SUPPRESS|CARDINAL|SWITCH_ID' CHANGING ct_html.

  PERFORM table2html USING text_vcls-title_fld_dep is_vcls-field_dep 'V_VCLSTDEP'
        'OBJECT|OBJFIELD|PREDOBJECT|PREDFIELD|NOKEYFIELD' abap_true 'NOKEYFIELD' CHANGING ct_html.

  CHECK is_vcls-events IS NOT INITIAL.
  PERFORM get_small_title_html USING text_vcls-title_events CHANGING ct_html.
  PERFORM get_paragraph_html USING text_vcls-txt_mt_event CHANGING ct_html.
  PERFORM table2html USING '' is_vcls-events 'V_VCLMF' 'EVENT|FORMNAME' abap_false '' CHANGING ct_html.
ENDFORM.
***************** View cluster Close *****************
***************** Number Range Objects Begin *****************
FORM getdata_nrob USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_nrob TYPE s_nrob,
        lv_object TYPE tnro-object,
        ls_tnro   TYPE tnro,
        ls_tnrot  TYPE tnrot.

  lv_object = is_obj_header-obj_name.
  CALL FUNCTION 'NUMBER_RANGE_OBJECT_READ'
    EXPORTING
      object            = lv_object
    IMPORTING
      object_attributes = ls_tnro
      object_text       = ls_tnrot
    EXCEPTIONS
      object_not_found  = 1
      OTHERS            = 2.                                "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0 AND ls_tnro IS NOT INITIAL.

  MOVE-CORRESPONDING is_obj_header TO ls_nrob.
  MOVE-CORRESPONDING ls_tnro TO ls_nrob.
  MOVE-CORRESPONDING ls_tnrot TO ls_nrob.
  ls_nrob-short_text = ls_tnrot-txtshort.
  ls_nrob-object = is_obj_header-object.
  APPEND ls_nrob TO gt_nrob.
ENDFORM.

FORM get_additional_html_nrob USING ls_nrob TYPE s_nrob CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM data2rows USING ls_nrob 'S_NROB' 'TXT|DTELSOBJ|DOMLEN|PERCENTAGE|YEARIND|NONRSWAP|CODE|BUFFER|NOIVBUFFER' CHANGING ct_html.
ENDFORM.
***************** Number Range Objects Close *****************
***************** Documentation Begin *****************
FORM getdata_docu USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_docu TYPE s_docu,
        lv_docu_name TYPE sobj_name,
        ls_mess_header TYPE s_obj_header,
        ls_dokil TYPE dokil.
  FIELD-SYMBOLS: <fs_objtype_order> TYPE s_objtype_order.

  MOVE-CORRESPONDING is_obj_header TO ls_docu.
  lv_docu_name = ls_docu-obj_name.
  SHIFT lv_docu_name BY 2 PLACES.
  " single message documentation will be transferred to MESS for reusage
  IF ls_docu-obj_name(2) EQ 'NA'.
    READ TABLE gt_mess WITH KEY obj_name = lv_docu_name TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

    ls_mess_header-pgmid = 'LIMU'.
    ls_mess_header-object = 'MESS'.
    ls_mess_header-obj_name = lv_docu_name.
    ls_mess_header-activity = gcv_act_create.
    READ TABLE gt_objtype_order ASSIGNING <fs_objtype_order> WITH TABLE KEY object = 'MESS'.
    ls_mess_header-primary_sort = <fs_objtype_order>-sort_no.
    PERFORM getdata_mess USING ls_mess_header.
  ELSEIF ls_docu-obj_name(2) EQ 'DE'.
    READ TABLE gt_dtel WITH KEY obj_name = lv_docu_name TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

    ls_docu-obj_name = lv_docu_name.
    SELECT SINGLE * FROM dokil INTO ls_dokil WHERE id = 'DE'
      AND object = ls_docu-obj_name AND langu = sy-langu AND typ = 'E'.
    PERFORM read_docu_by_dokil USING ls_dokil CHANGING ls_docu-long_text.
    CHECK ls_docu-long_text IS NOT INITIAL.
    APPEND ls_docu TO gt_docu.
  ENDIF.
ENDFORM.

FORM convert_docu.                                          "#EC CALLED
  DATA: ls_obj_header TYPE s_obj_header,
        lv_cnt TYPE i.
  FIELD-SYMBOLS: <fs_docu> TYPE s_docu.

  CHECK gt_docu IS NOT INITIAL.

  ADD 1 TO gv_header_no.
  lv_cnt = lines( gt_docu ).
  PERFORM add_header_html USING 'DOCU' CHANGING gt_html.
  " only data element documentation will be handled
  LOOP AT gt_docu ASSIGNING <fs_docu>.
    <fs_docu>-secondary_sort = sy-tabix.
    PERFORM add_title_html USING <fs_docu> lv_cnt CHANGING gt_html.
    PERFORM append_docu_html USING <fs_docu>-long_text CHANGING gt_html.

    MOVE-CORRESPONDING <fs_docu> TO ls_obj_header.
    PERFORM add_obj_gen_msg USING ls_obj_header 'S' ''.
  ENDLOOP.
ENDFORM.
***************** Documentation Close *****************
***************** Message Class: Definition and All Short Texts Begin *****************
FORM getdata_msad USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_msad_reuse USING is_obj_header.
ENDFORM.

FORM getdata_msad_reuse USING is_obj_header TYPE s_obj_header.
  DATA: ls_msg   TYPE s_msad,
        ls_t100a TYPE t100a.

  SELECT SINGLE stext FROM t100t INTO ls_msg-short_text
    WHERE sprsl = sy-langu AND arbgb = is_obj_header-obj_name.
*  CHECK sy-subrc EQ 0.
  SELECT * FROM t100 INTO CORRESPONDING FIELDS OF TABLE ls_msg-message_texts ##too_many_itab_fields
    WHERE sprsl = sy-langu AND arbgb = is_obj_header-obj_name ORDER BY msgnr ASCENDING.
  MOVE-CORRESPONDING is_obj_header TO ls_msg.

  DATA: ls_long_txt TYPE s_long_text.
  FIELD-SYMBOLS <fs_msg_txt> TYPE s_msg_txt.
  LOOP AT ls_msg-message_texts ASSIGNING <fs_msg_txt>.
    MOVE-CORRESPONDING <fs_msg_txt> TO ls_long_txt.
    PERFORM read_msg_docu USING <fs_msg_txt> CHANGING <fs_msg_txt>-self_explanatory ls_long_txt-long_text.
    IF <fs_msg_txt>-self_explanatory EQ abap_false.
      APPEND ls_long_txt TO ls_msg-long_texts.
    ENDIF.
  ENDLOOP.

  SELECT SINGLE * FROM t100a INTO ls_t100a WHERE arbgb = ls_msg-obj_name.
  PERFORM get_activity USING ls_t100a-ldate CHANGING ls_msg-activity.

  IF ls_msg-object EQ 'MSAG'.
    APPEND ls_msg TO gt_msag.
  ELSEIF ls_msg-object EQ 'MSAD'.
    APPEND ls_msg TO gt_msag.
  ENDIF.
ENDFORM.

FORM get_additional_html_msad USING ls_msad TYPE s_msad CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM table2tr USING text_msag-label_messages ls_msad-message_texts 'T100' 'MSGNR|TEXT|SELF_EXPLANATORY' CHANGING ct_html.
ENDFORM.

FORM get_special_html_msad USING is_obj TYPE any CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  DATA: ls_msad TYPE s_msad,
        lv_tmp  TYPE string.
  FIELD-SYMBOLS: <fs_long_txt> TYPE s_long_text.

  MOVE-CORRESPONDING is_obj TO ls_msad.
  LOOP AT ls_msad-long_texts ASSIGNING <fs_long_txt>.
    CONCATENATE text_mess-txt_mt_longtext <fs_long_txt>-arbgb ' ' <fs_long_txt>-msgnr INTO lv_tmp RESPECTING BLANKS.
    PERFORM get_small_title_html USING lv_tmp CHANGING ct_html.
    PERFORM append_docu_html USING <fs_long_txt>-long_text CHANGING ct_html.
  ENDLOOP.
ENDFORM.
***************** Message Class: Definition and All Short Texts Close *****************

***************** Message Class Begin *****************
FORM getdata_msag USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  PERFORM getdata_msad_reuse USING is_obj_header.
ENDFORM.

FORM get_additional_html_msag USING is_obj TYPE any CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_additional_html_msad USING is_obj CHANGING ct_html.
ENDFORM.

FORM get_special_html_msag USING is_obj TYPE any CHANGING ct_html TYPE STANDARD TABLE. "#EC CALLED
  PERFORM get_special_html_msad USING is_obj CHANGING ct_html.
ENDFORM.
***************** Message Class Close *****************
***************** Single Message Begin *****************
FORM getdata_mess USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_mess     TYPE s_mess,
        ls_msg_txt  TYPE s_msg_txt,
        lv_len      TYPE i.
  lv_len = strlen( is_obj_header-obj_name ) - 3.
  ls_mess-arbgb = is_obj_header-obj_name(lv_len).
  ls_mess-msgnr = is_obj_header-obj_name+lv_len(3).

  MOVE-CORRESPONDING is_obj_header TO ls_mess.
  SELECT SINGLE text FROM t100 INTO ls_mess-text WHERE sprsl = sy-langu AND arbgb = ls_mess-arbgb AND msgnr = ls_mess-msgnr.
  CHECK sy-subrc EQ 0.

  MOVE-CORRESPONDING ls_mess TO ls_msg_txt.
  PERFORM read_msg_docu USING ls_msg_txt CHANGING ls_mess-self_explanatory ls_mess-long_text.
  APPEND ls_mess TO gt_mess.
ENDFORM.

FORM read_msg_docu USING is_msg_text TYPE s_msg_txt CHANGING cv_self_expl TYPE c ct_lines TYPE t_tline.
  DATA: ls_dokil  TYPE dokil,
        lv_object TYPE dokil-object.

  CLEAR: cv_self_expl, ct_lines.
  cv_self_expl = abap_true.

  CONCATENATE is_msg_text-arbgb is_msg_text-msgnr INTO lv_object.
  SELECT SINGLE * FROM dokil INTO ls_dokil WHERE id = 'NA'
    AND object = lv_object AND langu = is_msg_text-sprsl AND typ = 'E' AND txtlines GT 0.

  CHECK sy-subrc EQ 0.
  cv_self_expl = abap_false.
  PERFORM read_docu_by_dokil USING ls_dokil CHANGING ct_lines.
ENDFORM.

FORM convert_mess.                                          "#EC CALLED
  DATA: lv_tmp  TYPE string,
        ls_objh TYPE s_obj_header,
        lt_mess TYPE TABLE OF s_mess.
  FIELD-SYMBOLS: <fs_mess> TYPE s_mess.

  CHECK gt_mess IS NOT INITIAL.
  " ignore single messages if they are already included in message class
  DELETE ADJACENT DUPLICATES FROM gt_mess.
  LOOP AT gt_mess ASSIGNING <fs_mess>.
    READ TABLE gt_msad WITH KEY obj_name = <fs_mess>-arbgb TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

    READ TABLE gt_msag WITH KEY obj_name = <fs_mess>-arbgb TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

    APPEND <fs_mess> TO lt_mess.
  ENDLOOP.

  CHECK lt_mess IS NOT INITIAL.
  ADD 1 TO gv_header_no.
  PERFORM add_header_html USING 'MESS' CHANGING gt_html.
  PERFORM add_object_instruction_html USING 'MESS' CHANGING gt_html.

  PERFORM table2html USING text_mess-txt_title lt_mess 'T100' 'ARBGB|MSGNR|TEXT|SELF_EXPLANATORY' abap_false '' CHANGING gt_html.
  LOOP AT lt_mess ASSIGNING <fs_mess>.
    MOVE-CORRESPONDING <fs_mess> TO ls_objh.
    PERFORM add_obj_gen_msg USING ls_objh 'S' ''.
  ENDLOOP.

  LOOP AT lt_mess ASSIGNING <fs_mess> WHERE self_explanatory IS INITIAL.
    CONCATENATE text_mess-txt_mt_longtext <fs_mess>-arbgb ' ' <fs_mess>-msgnr INTO lv_tmp RESPECTING BLANKS.
    PERFORM get_small_title_html USING lv_tmp CHANGING gt_html.
    PERFORM append_docu_html USING <fs_mess>-long_text CHANGING gt_html.
  ENDLOOP.
ENDFORM.
***************** Single Message Close *****************
***************** Transaction Begin *****************
FORM getdata_tran USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_tran     TYPE s_tran,
        lv_tcode    TYPE tcode,
        lt_gui_attr TYPE TABLE OF tstcc.

  MOVE-CORRESPONDING is_obj_header TO ls_tran.
  lv_tcode = ls_tran-obj_name.
* basic attributes, gui, param, authority, uiclass, short text
  SELECT SINGLE * FROM tstcv INTO ls_tran-basic_info WHERE tcode = lv_tcode AND sprsl = sy-langu.
* tstcc may not be retrieved from db directly, call RPY_TRANSACTION_READ
  CALL FUNCTION 'RPY_TRANSACTION_READ'
    EXPORTING
      transaction      = lv_tcode
    TABLES
      gui_attributes   = lt_gui_attr
    EXCEPTIONS
      permission_error = 1
      cancelled        = 2
      not_found        = 3
      object_not_found = 4
      OTHERS           = 5.                                 "#EC FB_RC
  PERFORM handle_rc USING is_obj_header.
  CHECK sy-subrc EQ 0.
  READ TABLE lt_gui_attr INTO ls_tran-gui_attributes INDEX 1.
  ls_tran-gui_attributes-s_webgui = boolc( ls_tran-gui_attributes-s_webgui EQ '1' ).

  SELECT SINGLE param FROM tstcp INTO ls_tran-param WHERE tcode = lv_tcode.
  SELECT * FROM tstca INTO TABLE ls_tran-authority WHERE tcode = lv_tcode.
  SELECT SINGLE * FROM tstcclass INTO ls_tran-uiclass WHERE tcode = lv_tcode.
  ls_tran-short_text = ls_tran-basic_info-ttext.
* determine transaction type
  IF ls_tran-basic_info-cinfo EQ '04'.
    ls_tran-transaction_type = c_trans_type-dialog.
  ELSEIF ls_tran-basic_info-cinfo EQ '80'.
    ls_tran-transaction_type = c_trans_type-report.
  ELSEIF ls_tran-basic_info-cinfo EQ '08'.
    ls_tran-transaction_type = c_trans_type-oo.
  ELSEIF ls_tran-basic_info-cinfo EQ '02' AND ls_tran-param IS NOT INITIAL.
    CALL FUNCTION 'RS_TRANSACTION_SINGLE_GET'
      EXPORTING
        parameter_tcode = lv_tcode
      IMPORTING
        tcode           = ls_tran-transaction.
    IF ls_tran-transaction IS NOT INITIAL.
      " OO transaction
      IF ls_tran-transaction EQ 'OS_APPLICATION'.
        ls_tran-transaction_type = c_trans_type-oo.
        " transaction with variant
      ELSEIF ls_tran-param(2) EQ '@@'.
        ls_tran-transaction_type = c_trans_type-trans_with_variant.
        " transaction with parameter
      ELSEIF ls_tran-param(2) EQ '/*' OR ls_tran-param(2) EQ '/N'.
        ls_tran-transaction_type = c_trans_type-trans_with_param.
      ENDIF.
    ELSEIF ls_tran-param(1) EQ '\'.
      ls_tran-transaction_type = c_trans_type-oo.
    ENDIF.

    PERFORM split_param2table USING ls_tran-param CHANGING ls_tran-param_values.
  ENDIF.

  APPEND ls_tran TO gt_tran.
ENDFORM.

FORM get_additional_html_tran USING ls_tran TYPE s_tran CHANGING ct_html TYPE t_string. "#EC CALLED
  DATA: lv_tp_txt      TYPE ddtext,
        lv_html         TYPE string.

  PERFORM get_value_desc USING 'TRANSACTION_TYPE' ls_tran-transaction_type CHANGING lv_tp_txt.
  PERFORM get_2column_value_html USING text_tran-label_type lv_tp_txt CHANGING ct_html.
  CASE ls_tran-transaction_type.
    WHEN c_trans_type-dialog.
      PERFORM get_dialog_value_html USING ls_tran CHANGING ct_html.
    WHEN c_trans_type-report.
      PERFORM get_report_value_html USING ls_tran CHANGING ct_html.
    WHEN c_trans_type-oo.
      PERFORM get_oo_value_html USING ls_tran-param ls_tran-param_values CHANGING ct_html.
    WHEN c_trans_type-trans_with_variant.
      PERFORM get_trans_variant_value_html USING ls_tran-param CHANGING ct_html.
    WHEN c_trans_type-trans_with_param.
      PERFORM get_2column_value_html USING text_tran-label_transaction ls_tran-transaction CHANGING ct_html.
      PERFORM get_2column_value_html USING text_tran-label_skip_init_screen 'X' CHANGING ct_html.
      PERFORM table2tr USING text_tran-label_default_values ls_tran-param_values 'S_TRAN_DEFAULT_VALUE' 'SCREEN_FIELD|VALUE' CHANGING ct_html.
  ENDCASE.

  PERFORM get_classfication_html USING ls_tran CHANGING lv_html.
  PERFORM get_2column_right_table_html USING text_tran-label_classification lv_html CHANGING ct_html.
ENDFORM.

FORM split_param2table USING iv_tcode_param TYPE s_tran-param CHANGING ct_param_values TYPE STANDARD TABLE.
  DATA: lv_dummy      TYPE string,
        lv_fld_values TYPE string,
        lt_dfvalue    TYPE TABLE OF string,
        ls_param      TYPE s_tran_default_value,
        lt_param      TYPE TABLE OF s_tran_default_value.
  FIELD-SYMBOLS: <fs_dfvalue> TYPE string.

  CHECK iv_tcode_param IS NOT INITIAL.
  SPLIT iv_tcode_param AT space INTO lv_dummy lv_fld_values.
  SPLIT lv_fld_values AT ';' INTO TABLE lt_dfvalue.
  CHECK lt_dfvalue IS NOT INITIAL.

  LOOP AT lt_dfvalue ASSIGNING <fs_dfvalue>.
    SPLIT <fs_dfvalue> AT '=' INTO ls_param-screen_field ls_param-value.
    APPEND ls_param TO lt_param.
    CLEAR ls_param.
  ENDLOOP.

  CLEAR ct_param_values.
  ct_param_values = lt_param.
ENDFORM.

FORM get_classfication_html USING is_tran TYPE s_tran CHANGING cv_html TYPE string.
  DATA: lt_html TYPE TABLE OF string.

  APPEND gcv_table_begin TO lt_html.
  " TODO: replace hardcoded values
  PERFORM get_2column_value_html USING text_tran-label_inherit_gui 'X' CHANGING lt_html.
  PERFORM get_2column_value_html USING text_tran-label_prof_user 'X' CHANGING lt_html.
  PERFORM get_2column_value_html USING text_tran-label_easy_web ''  CHANGING lt_html.
  PERFORM get_2column_value_html USING text_tran-label_service  is_tran-gui_attributes-s_service CHANGING lt_html.
  PERFORM get_2column_value_html USING text_tran-label_pervasive is_tran-gui_attributes-s_pervas CHANGING lt_html.
  PERFORM data2rows_common USING is_tran-gui_attributes 'TSTCC' 'S_WEBGUI|S_PLATIN|S_WIN32' abap_false CHANGING lt_html.
  APPEND gcv_table_end TO lt_html.

  PERFORM join_str USING lt_html CHANGING cv_html.
ENDFORM.

FORM get_dialog_value_html USING is_tran TYPE s_tran CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM get_value_html4dialog_report USING c_trans_type-dialog is_tran CHANGING ct_html.
ENDFORM.

FORM get_value_html4dialog_report USING iv_trans_type TYPE c is_tran TYPE s_tran CHANGING ct_html TYPE STANDARD TABLE.
  DATA: ls_tstca TYPE tstca.

  PERFORM data2rows USING is_tran-basic_info 'TSTC' 'PGMNA|DYPNO' CHANGING ct_html.
  IF is_tran-authority IS NOT INITIAL.
    READ TABLE is_tran-authority INTO ls_tstca INDEX 1.
    PERFORM data2rows USING ls_tstca 'TSTCA' 'OBJCT' CHANGING ct_html.
    PERFORM table2tr USING text_tran-label_auth_values is_tran-authority 'TSTCA' 'FIELD|VALUE' CHANGING ct_html.
  ENDIF.
ENDFORM.

FORM get_report_value_html USING is_tran TYPE s_tran CHANGING ct_html TYPE STANDARD TABLE.
  PERFORM get_value_html4dialog_report USING c_trans_type-report is_tran CHANGING ct_html.
ENDFORM.

FORM get_oo_value_html USING iv_param TYPE s_tran-param it_param_values TYPE t_tran_default_value CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lt_html    TYPE TABLE OF string,
        lv_oo_mode TYPE c,
        lv_text    TYPE ddtext.
  FIELD-SYMBOLS: <fs_pv> TYPE s_tran_default_value.

  APPEND gcv_table_begin TO lt_html.
  lv_oo_mode = boolc( iv_param(1) NE '\' ).
  PERFORM get_2column_value_html USING text_tran-label_oo_mode lv_oo_mode CHANGING lt_html.

  LOOP AT it_param_values ASSIGNING <fs_pv>.
    CASE <fs_pv>-screen_field.
      WHEN 'CLASS'.
        PERFORM get_2column_value_html USING text_tran-label_oo_clas <fs_pv>-value CHANGING lt_html.
      WHEN 'METHOD'.
        PERFORM get_2column_value_html USING text_tran-label_oo_meth <fs_pv>-value CHANGING lt_html.
      WHEN 'PROGRAM'.
        PERFORM get_2column_value_html USING text_tran-label_oo_local_prog <fs_pv>-value CHANGING lt_html.
      WHEN 'UPDATE_MODE'.
        PERFORM get_value_desc USING 'UPDATE_MODE' <fs_pv>-value CHANGING lv_text.
        PERFORM get_2column_value_html USING text_tran-label_oo_update_mode lv_text CHANGING lt_html.
    ENDCASE.
  ENDLOOP.
  APPEND gcv_table_end TO lt_html.
  APPEND LINES OF lt_html TO ct_html.
ENDFORM.

FORM get_trans_variant_value_html USING iv_param TYPE s_tran-param CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lv_tcode TYPE string,
        lv_vari  TYPE string.
  SPLIT iv_param AT space INTO lv_tcode lv_vari.
  SHIFT lv_tcode BY 2 PLACES.

  PERFORM get_2column_value_html USING text_tran-label_transaction lv_tcode CHANGING ct_html.
  PERFORM get_2column_value_html USING text_tran-label_transaction_variant lv_vari CHANGING ct_html.
ENDFORM.
***************** Transaction Close *****************
***************** View Cluster Maintenance: Data Begin *****************
FORM getdata_cdat USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_cdat TYPE s_cdat,
        ls_vcls TYPE s_vcls,
        ls_vdat TYPE s_vdat.

  MOVE-CORRESPONDING is_obj_header TO ls_cdat.
  PERFORM get_vcls_reuse USING is_obj_header CHANGING ls_vcls.
  CHECK sy-subrc EQ 0 AND ls_vcls IS NOT INITIAL.
  ls_cdat-object_stru = ls_vcls-object_stru.

  PERFORM getdata_tabu_reuse USING is_obj_header CHANGING ls_vdat.
  CHECK sy-subrc EQ 0 AND ls_vdat IS NOT INITIAL.
  ls_cdat-primary_keys = ls_vdat-primary_keys.
  ls_cdat-field_info = ls_vdat-field_info.

  APPEND ls_cdat TO gt_cdat.
ENDFORM.

FORM get_special_html_cdat USING is_cdat TYPE s_cdat CHANGING ct_html TYPE t_string. "#EC CALLED
  DATA: ls_vdat_ignore TYPE s_vdat_ignore,
        ls_vdat        TYPE s_vdat,
        ls_objheader   TYPE s_obj_header,
        lv_fields      TYPE string,
        lr_data        TYPE REF TO data,
        lv_msg         TYPE string.
  FIELD-SYMBOLS: <fs_obj_stru> TYPE v_vclstruc,
                 <fs_contents> TYPE STANDARD TABLE.

  LOOP AT is_cdat-object_stru ASSIGNING <fs_obj_stru>.
    CLEAR: lr_data, ls_vdat, ls_objheader, lv_fields, ls_vdat_ignore.
    UNASSIGN <fs_contents>.

    CHECK <fs_obj_stru>-object IS NOT INITIAL.
    TRY.
        CREATE DATA lr_data TYPE TABLE OF (<fs_obj_stru>-object).
        ASSIGN lr_data->* TO <fs_contents>.
      CATCH cx_sy_create_data_error.
        MESSAGE e208(00) WITH 'DDIC ' <fs_obj_stru>-object ' is invalid, please check it.' INTO lv_msg.
        PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
        RETURN.
    ENDTRY.

    PERFORM get_vdat_info_via_cdat USING <fs_obj_stru>-object is_cdat CHANGING ls_vdat.
    PERFORM get_complete_entries USING ls_vdat CHANGING <fs_contents>.
    CHECK <fs_contents> IS NOT INITIAL.

    MOVE-CORRESPONDING ls_vdat TO ls_objheader.
    PERFORM get_maintable_flds USING ls_objheader CHANGING lv_fields.
    CHECK lv_fields IS NOT INITIAL.

    PERFORM get_vcls_node_title USING <fs_obj_stru>-objecttext CHANGING ct_html.
    PERFORM table2html USING '' <fs_contents> ls_vdat-obj_name lv_fields abap_false '' CHANGING ct_html.

    READ TABLE gt_vdat_ignore WITH TABLE KEY obj_name = <fs_obj_stru>-object TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.
    ls_vdat_ignore-vcls_name = is_cdat-obj_name.
    ls_vdat_ignore-obj_name = <fs_obj_stru>-object.
    INSERT ls_vdat_ignore INTO TABLE gt_vdat_ignore.
  ENDLOOP.
ENDFORM.

FORM get_vcls_node_title USING iv_objtext TYPE v_vclstruc-objecttext CHANGING ct_html TYPE t_string.
  DATA: lv_txt  TYPE string.
  CONCATENATE text_tabu-txt_maint_node '<b>' iv_objtext '</b>' INTO lv_txt RESPECTING BLANKS.
  PERFORM get_paragraph_html USING lv_txt CHANGING ct_html.
ENDFORM.

FORM get_vdat_info_via_cdat USING iv_objname TYPE vim_name is_cdat TYPE s_cdat CHANGING cs_vdat TYPE s_vdat.
  CLEAR cs_vdat.
  TYPES: BEGIN OF s_e071kf_obj,
          objname TYPE tabname,
         END OF s_e071kf_obj.
  DATA: ls_object TYPE s_e071kf_obj,
        lt_object TYPE HASHED TABLE OF s_e071kf_obj WITH UNIQUE KEY objname.
  FIELD-SYMBOLS: <fs_e071k>  TYPE e071k,
                 <fs_e071kf> TYPE e071kf.

  cs_vdat-obj_name = iv_objname.
  LOOP AT is_cdat-primary_keys ASSIGNING <fs_e071k> WHERE objname EQ iv_objname OR viewname EQ iv_objname.
    APPEND <fs_e071k> TO cs_vdat-primary_keys.
    IF <fs_e071k>-viewname IS INITIAL.
      cs_vdat-object = 'TABU'.
    ELSE.
      cs_vdat-object = 'VDAT'.
    ENDIF.

    READ TABLE lt_object WITH TABLE KEY objname = <fs_e071k>-objname TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

    ls_object-objname = <fs_e071k>-objname.
    INSERT ls_object INTO TABLE lt_object.
  ENDLOOP.

  LOOP AT is_cdat-field_info ASSIGNING <fs_e071kf>.
    READ TABLE lt_object WITH TABLE KEY objname = <fs_e071kf>-objname TRANSPORTING NO FIELDS.
    CHECK sy-subrc EQ 0.
    APPEND <fs_e071kf> TO cs_vdat-field_info.
  ENDLOOP.
ENDFORM.
***************** View Cluster Maintenance: Data Close *****************

***************** View Maintenance: Data Begin *****************
FORM getdata_vdat USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_vdat TYPE s_vdat.
  PERFORM getdata_tabu_reuse USING is_obj_header CHANGING ls_vdat.
  CHECK ls_vdat IS NOT INITIAL.
  APPEND ls_vdat TO gt_vdat.
ENDFORM.

FORM getdata_tabu_reuse USING is_obj_header TYPE s_obj_header CHANGING cs_tabu TYPE s_vdat.
* if vdat/tabu has been included in cdat already, then ignore
  READ TABLE gt_vdat_ignore WITH TABLE KEY obj_name = is_obj_header-obj_name TRANSPORTING NO FIELDS.
  CHECK sy-subrc NE 0.
  DATA: lv_ddobj TYPE ddobjname,
        lv_rc    TYPE sy-subrc.
  lv_ddobj = is_obj_header-obj_name.

* filter system level data of view cluster/view maintenance/table contents
  IF is_obj_header-object EQ 'VDAT'.
    IF is_obj_header-obj_name EQ 'V_TVIMF' OR is_obj_header-obj_name EQ 'V_TVDIR'.
      PERFORM add_obj_gen_msg USING is_obj_header 'W' ''.
      RETURN.
    ENDIF.

    CALL FUNCTION 'DB_EXISTS_TABLE'
      EXPORTING
        tabname = lv_ddobj
      IMPORTING
        subrc   = lv_rc.
  ELSEIF is_obj_header-object EQ 'TABU'.
    IF is_obj_header-obj_name EQ 'TDDAT' OR is_obj_header-obj_name EQ 'TRESC' OR
          is_obj_header-obj_name EQ 'TVDIR' OR is_obj_header-obj_name EQ 'TVIMF'.
      PERFORM add_obj_gen_msg USING is_obj_header 'W' ''.
      RETURN.
    ENDIF.

    CALL FUNCTION 'DB_EXISTS_VIEW'
      EXPORTING
        viewname = lv_ddobj
      IMPORTING
        subrc    = lv_rc.
  ELSEIF is_obj_header-object EQ 'CDAT'.
    "TODO
  ENDIF.
* check validity of table/view
  sy-subrc = lv_rc.
  PERFORM handle_rc USING is_obj_header.
  CHECK lv_rc EQ 0.

  MOVE-CORRESPONDING is_obj_header TO cs_tabu.
  SELECT * FROM e071k INTO TABLE cs_tabu-primary_keys
    WHERE trkorr IN so_trans AND mastertype EQ cs_tabu-object AND mastername EQ cs_tabu-obj_name.
* only after change request was released key field info will be filled into table e071kf
  SELECT * FROM e071kf INTO TABLE cs_tabu-field_info
    FOR ALL ENTRIES IN cs_tabu-primary_keys
    WHERE trkorr IN so_trans AND objname EQ cs_tabu-primary_keys-objname.
ENDFORM.

FORM convert_vdat.                                          "#EC CALLED
  PERFORM convert_vdat_reuse USING 'VDAT' gt_vdat.
ENDFORM.

FORM convert_vdat_reuse USING iv_object TYPE trobjtype it_tab TYPE t_vdat.
  CHECK it_tab IS NOT INITIAL.
  ADD 1 TO gv_header_no.

  DATA: lv_cnt TYPE i.
  FIELD-SYMBOLS: <fs_vdat> TYPE s_vdat.

  lv_cnt = lines( it_tab ).
  PERFORM add_header_html USING iv_object CHANGING gt_html.
  PERFORM add_object_instruction_html USING iv_object CHANGING gt_html.

  LOOP AT it_tab ASSIGNING <fs_vdat>.
    <fs_vdat>-secondary_sort = sy-tabix.
    PERFORM convert_single_vdat2html USING <fs_vdat> lv_cnt CHANGING gt_html.
  ENDLOOP.
ENDFORM.

FORM convert_single_vdat2html USING is_vdat TYPE s_vdat iv_cnt TYPE i CHANGING ct_html TYPE STANDARD TABLE.
  DATA: lr_view_data  TYPE REF TO data,
        lv_fields     TYPE string,
        ls_obj_header TYPE s_obj_header,
        lv_msg        TYPE string.
  FIELD-SYMBOLS: <fs_view_contents> TYPE STANDARD TABLE.

  MOVE-CORRESPONDING is_vdat TO ls_obj_header.
  PERFORM get_maintable_flds USING ls_obj_header CHANGING lv_fields.
  CHECK lv_fields IS NOT INITIAL.

  TRY .
      CREATE DATA lr_view_data TYPE TABLE OF (is_vdat-obj_name).
      ASSIGN lr_view_data->* TO <fs_view_contents>.
    CATCH cx_sy_create_data_error.
      MESSAGE e208(00) WITH 'DDIC ' is_vdat-obj_name ' is invalid, please check it.' INTO lv_msg.
      PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
      RETURN.
  ENDTRY.

  PERFORM get_complete_entries USING is_vdat CHANGING <fs_view_contents>.
  PERFORM add_title_html USING is_vdat iv_cnt CHANGING ct_html.
  PERFORM table2html USING '' <fs_view_contents> is_vdat-obj_name lv_fields abap_true '' CHANGING ct_html.
  PERFORM add_obj_gen_msg USING ls_obj_header 'S' ''.
ENDFORM.

FORM get_complete_entries USING is_vdat TYPE s_vdat CHANGING ct_contents TYPE STANDARD TABLE.
  DATA: lr_view_data  TYPE REF TO data,
        lr_table_data TYPE REF TO data,
        lr_view_row   TYPE REF TO data,
        lt_where      TYPE TABLE OF string,
        lt_e071k      TYPE TABLE OF e071k,
        lv_where      TYPE string,
        lv_result     TYPE string,
        lv_msg        TYPE string,
        lv_index      TYPE i.
  FIELD-SYMBOLS: <fs_e071kf>      TYPE e071kf,
                 <fs_e071k>       TYPE e071k,
                 <fs_tab_conts>   TYPE STANDARD TABLE,
                 <fs_tab_cont>    TYPE any,
                 <fs_view_conts>  TYPE STANDARD TABLE,
                 <fs_view_cont>   TYPE any,
                 <fs_value>       TYPE any.

  TRY.
      CREATE DATA lr_view_data TYPE TABLE OF (is_vdat-obj_name).
      ASSIGN lr_view_data->* TO <fs_view_conts>.
    CATCH cx_sy_create_data_error.
      MESSAGE e208(00) WITH 'DDIC ' is_vdat-obj_name ' is invalid, please check it.' INTO lv_msg.
      PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
      RETURN.
  ENDTRY.

  lt_e071k = is_vdat-primary_keys.
  SORT lt_e071k BY objname ASCENDING.

  LOOP AT lt_e071k ASSIGNING <fs_e071k>.
    IF <fs_tab_conts> IS NOT ASSIGNED.
      TRY.
          CREATE DATA lr_table_data TYPE TABLE OF (<fs_e071k>-objname).
          ASSIGN lr_table_data->* TO <fs_tab_conts>.
        CATCH cx_sy_create_data_error.
          CLEAR lv_msg.
          MESSAGE e208(00) WITH 'DDIC ' <fs_e071k>-objname ' is invalid, please check it.' INTO lv_msg.
          PERFORM append_common_msg USING 'E' lv_msg CHANGING gt_sys_msg.
          RETURN.
      ENDTRY.
    ENDIF.

    " get table contents
    LOOP AT is_vdat-field_info ASSIGNING <fs_e071kf> WHERE objname EQ <fs_e071k>-objname.
      ASSIGN <fs_e071k>-tabkey+<fs_e071kf>-offset(<fs_e071kf>-dblength) TO <fs_value>.
      CHECK <fs_value> IS ASSIGNED AND <fs_value> IS NOT INITIAL.

      IF <fs_e071kf>-exid NE 'C'.
        DATA lo_datadescr TYPE REF TO cl_abap_datadescr.
        lo_datadescr ?= cl_abap_typedescr=>describe_by_data( <fs_value> ).
        CHECK lo_datadescr->type_kind EQ <fs_e071kf>-exid.
        CLEAR lo_datadescr.
      ENDIF.

      CONCATENATE <fs_e071kf>-fieldname ' = ''' <fs_value> ''' ' INTO lv_where RESPECTING BLANKS.
      APPEND lv_where TO lt_where.
      UNASSIGN <fs_value>.
    ENDLOOP.
    CONCATENATE LINES OF lt_where INTO lv_result SEPARATED BY ' AND ' RESPECTING BLANKS.

    SELECT * FROM (<fs_e071k>-objname) APPENDING TABLE <fs_tab_conts> WHERE (lv_result).
    CLEAR: lv_where, lt_where, lv_result.

    AT END OF objname.
      ADD 1 TO lv_index.
      " move table contents to view contents(similar as join)
      LOOP AT <fs_tab_conts> ASSIGNING <fs_tab_cont>.
        CREATE DATA lr_view_row TYPE (is_vdat-obj_name).
        ASSIGN lr_view_row->* TO <fs_view_cont>.

        MOVE-CORRESPONDING <fs_tab_cont> TO <fs_view_cont>.
        " if current table is primary table, then just insert
        IF lv_index LE 1.
          APPEND <fs_view_cont> TO <fs_view_conts>.
        " if primary table contents has been transferred to view contents, then other table contents should be appended as delta
        ELSE.
          MODIFY <fs_view_conts> FROM <fs_view_cont> INDEX sy-tabix.
        ENDIF.

        CLEAR lr_view_row.
        UNASSIGN <fs_view_cont>.
      ENDLOOP.

      CLEAR: lr_table_data.
      UNASSIGN: <fs_tab_conts>, <fs_tab_cont>.
    ENDAT.
  ENDLOOP.

  CLEAR ct_contents.
  ct_contents = <fs_view_conts>.
ENDFORM.

FORM get_maintable_flds USING is_objheader TYPE s_obj_header CHANGING cv_fldnames TYPE string.
  DATA: lv_ddobjname TYPE ddobjname,
        ls_obj_head  TYPE s_obj_header,
        lt_view_fld  TYPE t_view_fields,
        lt_tabl_fld  TYPE dd03ttyp.
  FIELD-SYMBOLS: <fs_view_fld> TYPE dd27p,
                 <fs_tabl_fld> TYPE dd03p.

  CLEAR cv_fldnames.
  lv_ddobjname = is_objheader-obj_name.

  IF is_objheader-object EQ 'VDAT'.
    CALL FUNCTION 'DDIF_VIEW_GET'
      EXPORTING
        name          = lv_ddobjname
        state         = 'A'
      TABLES
        dd27p_tab     = lt_view_fld
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.                                  "#EC FB_RC
    PERFORM handle_rc USING ls_obj_head.
    CHECK sy-subrc EQ 0 AND lt_view_fld IS NOT INITIAL.
    " only those available fields in maintenance view will be fetched
    LOOP AT lt_view_fld ASSIGNING <fs_view_fld> WHERE rdonly IS INITIAL.
      CONCATENATE cv_fldnames '|' <fs_view_fld>-fieldname INTO cv_fldnames.
    ENDLOOP.
    SHIFT cv_fldnames.
  ELSEIF is_objheader-object EQ 'TABU'.
    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = lv_ddobjname
        state         = 'A'
      TABLES
        dd03p_tab     = lt_tabl_fld
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.                                  "#EC FB_RC
    PERFORM handle_rc USING ls_obj_head.
    CHECK sy-subrc EQ 0 AND lt_tabl_fld IS NOT INITIAL.

    LOOP AT lt_tabl_fld ASSIGNING <fs_tabl_fld>.
      CONCATENATE cv_fldnames '|' <fs_tabl_fld>-fieldname INTO cv_fldnames.
    ENDLOOP.
    SHIFT cv_fldnames.
  ENDIF.
ENDFORM.
***************** View Maintenance: Data Close *****************

***************** Table Contents Begin *****************
FORM getdata_tabu USING is_obj_header TYPE s_obj_header.    "#EC CALLED
  DATA: ls_tabu TYPE s_tabu.
  PERFORM getdata_tabu_reuse USING is_obj_header CHANGING ls_tabu.
  CHECK ls_tabu IS NOT INITIAL.
  APPEND ls_tabu TO gt_tabu.
ENDFORM.

FORM convert_tabu.                                          "#EC CALLED
  PERFORM convert_vdat_reuse USING 'TABU' gt_tabu.
ENDFORM.
***************** Table Contents Close *****************