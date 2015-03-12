$('document').ready(function(){
    
    //var domain_name = '/smartschool';


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    var url = "\/academic_terms\/ajax_get_terms\/SearchStudent\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
     //Search Form For displaying Subjects assigned to sponsor
     $('#search_student_sponsor_form').on('submit', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        var values = $('#search_student_sponsor_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/home/search_student',
            data: values,
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var term = $('#academic_term_id').children('option:selected').text();
                    var output = '<caption><strong>Results For <u>::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>ID Code</th>\
                                        <th>Student Name</th>\
                                        <th>Class Name</th>\
                                        <th>Terminal Scores</th>\
                                        <th>Annual Scores</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SearchStudent, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_no+'</td>\
                                <td>'+value.student_name+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/home/term_scorestd/'+value.std_cls_term_id+'" class="btn btn-info btn-xs">\n\
                                    <i class="fa fa-eye-slash"></i> View Scores</a>\
                                </td>\n\
                                <td>\n\
                                    <a target="__blank" href="'+domain_name+'/home/annual_scorestd/'+value.std_cls_yr_id+'" class="btn btn-warning btn-xs">\n\
                                    <i class="fa fa-eye"></i> Proceed</a>\
                                </td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#search_students_table').html(output);
                    }else if(obj.Flag === 0){
                        $('#search_students_table').html('<tr><th colspan="6">No Record Found</th></tr>');
                    }
                } catch (exception) {
                    $('#search_students_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#search_students_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            } 
        });
        return false;
    });
    
});