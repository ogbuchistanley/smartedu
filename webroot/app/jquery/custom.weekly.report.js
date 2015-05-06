$('document').ready(function(){

    //var domain_name = '/smartschool';

//////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////// Teacher Subjects  //////////////////////////////////////////////////////////////////////////
    //When the Search button is clicked for managing students subjects assigned to a staff
    $(document.body).on('submit', '#search_subject_assign_form', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        $.ajax({
            type: "POST",
            url: domain_name+'/subjects/search_assigned2Staff',
            data: $(this).serialize(),
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var output = '<caption><strong>Results Output From The Search</strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Academic Term</th>\
                                        <th>Subjects</th>\
                                        <th>Classlevels</th>\
                                        <th>Class Rooms</th>\
                                        <th>Weekly Report</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SubjectClasslevel, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.academic_term+'</td>\n\
                                <td>'+value.subject_name+'</td>\n\
                                <td>'+value.classlevel+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td><a target="__blank" href="'+domain_name+'/weekly_reports/report/'+value.encrypt_sub_cls_id+'" class="btn btn-primary btn-xs"><i class="fa fa-tasks"></i> Reports</a></td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#subject_assigned_table').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="9">No Assigned Subject Found</th></tr>';
                        $('#subject_assigned_table').html(output);
                    }
                } catch (exception) {
                    $('#subject_assigned_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#subject_assigned_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#subject_assigned_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            }
        });
        return false;
    });

    //Validate The Weekly Weight Point
    $(document.body).on('blur', '.weekly_ca', function(){
        var weekly_ca = parseInt($(this).val());
        var WP = $('#hidden_weight_point').val();
        if(weekly_ca > parseInt(WP) || weekly_ca < 0){
            $(this).parent().children(':nth-child(2)').html('<span class="label label-danger">>= 0 and <='+WP+'</span>');
            $(this).focus();
        }else{
            $(this).parent().children(':nth-child(2)').html('');
        }
    });

    //Validate The Weekly Report Form Before Submission
    $(document.body).on('click', '#weekly_report_form_btn', function(){
        var validate = '';
        $('.weekly_ca').each(function(key){
            var span = $(this).next('span').html();
            validate += span;
            //alert(key + ' = ' + $(this).val());
        });
        if(validate.trim() == '')
            return true;
        else
            return false;
    });



});