$('document').ready(function(){

    //var domain_name = '/smartschool';

    setTabActive('[href="'+domain_name+'/weekly_reports/index#report"]', 1);
    $('[href="'+domain_name+'/weekly_reports/index#report"]').attr('data-toggle', 'tab');
    $('[href="'+domain_name+'/weekly_reports/index#midterm"]').attr('data-toggle', 'tab');

    $('[href="'+domain_name+'/weekly_reports/index#report"]').click(function(){
        $('#myTab a[href="'+domain_name+'/weekly_reports/index#report"]').tab('show');
        setTabActive('[href="'+domain_name+'/weekly_reports/index#report"]', 1);
    });
    $('[href="'+domain_name+'/weekly_reports/index#midterm"]').click(function(){
        $('#myTab a[href="'+domain_name+'/weekly_reports/index#midterm"]').tab('show');
        setTabActive('[href="'+domain_name+'/weekly_reports/index#midterm"]', 1);
    });
//////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);

    var url3 = "\/academic_terms\/ajax_get_terms\/SearchExamTAScores\/%23academic_year_examTAScores_id";
    getDependentListBox($("#academic_year_examTAScores_id"), $("#academic_term_examTAScores_id"), url3);

    var url5 = "\/classrooms\/ajax_get_classes\/SearchExamTAScores\/%23classlevel_examTAScores_id";
    getDependentListBox($("#classlevel_examTAScores_id"), $("#class_examTAScores_id"), url5);
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
    

    //Search Form For displaying Subjects Exams Has Been Setup for editing
    $(document.body).on('submit', '#search_examTAScores_form', function(){
        ajax_loading_image($('#msg_box2'), ' Loading Contents');
        var values = $('#search_examTAScores_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/exams/search_student_classlevel',
            data: values,
            success: function(data){
                //$.post(domain_name+'/exams/search_student_classlevel', values, function(data){
                try{
                    var obj = $.parseJSON(data);
                    var cls = $('#class_stud_id').children('option:selected').text();
                    var cls_lvl = $('#classlevel_stud_id').children('option:selected').text();
                    var term = $('#academic_term_stud_id').children('option:selected').text();
                    var output = '<caption><strong>Results For <u>'+cls+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>ID Code</th>\
                                        <th>Student Name</th>\
                                        <th>Print</th>\
                                    </tr></thead>';
                    var output2 = '<caption><strong>Results For <u>Classlevel '+cls_lvl+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Name</th>\
                                        <th>Class Capacity</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SearchExamTAScores, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_no+'</td>\
                                <td>'+value.student_name+'</td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/weekly_reports/print_report/'+value.std_cls_term_id+'" class="btn btn-success btn-xs">\n\
                                    <i class="fa fa-print"></i> Print</a>\
                                </td>\n\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#view_stud_table').html(output);
                    }else if(obj.Flag === 2){
                        output2 += '<tbody>';
                        $.each(obj.SearchExamTAScores, function(key, value) {
                            output2 += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\
                                <td>'+value.class_size+'</td>\
                            </tr>';
                        });
                        output2 += '</tbody>';
                        $('#view_stud_table').html(output2);
                    }else if(obj.Flag === 0){
                        $('#view_stud_table').html('<tr><th colspan="5">No Record Found</th></tr>');
                    }
                } catch (exception) {
                    $('#view_stud_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box2'));
                //Scroll To Div
                scroll2Div($('#view_stud_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#view_stud_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box2'));
            }
        });
        return false;
    });


});