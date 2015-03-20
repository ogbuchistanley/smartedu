$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    var val = '';
    var old_btn;
    var employeeNames = $('#employee_names').clone();
    $('#employee_names').addClass('hide');    
    
     //Set The Active Tab
     setTabActive('[href="'+domain_name+'/subjects/add2class#assign2class"]', 1);
     $('[href="'+domain_name+'/subjects/add2class#assign2class"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/subjects/add2class#assign2teachers"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]').attr('data-toggle', 'tab');
//    var hash = window.location.hash;		
//    if(hash === "#assign2teachers" || hash === ''){
//        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2teachers"]').tab('show');
//        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2teachers"]', 1);
//    } else if(hash === "#assign2class") {
//        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2class"]').tab('show');
//        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2class"]', 1);
//    } else if(hash === "#adjust_subjects_assign") {
//        $('#myTab a[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]').tab('show'); 
//        setTabActive('[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]', 1);
//    }
    $('[href="'+domain_name+'/subjects/add2class#assign2class"]').click(function(){
        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2class"]').tab('show');
        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2class"]', 1);
    });
    
    $('[href="'+domain_name+'/subjects/add2class#assign2teachers"]').click(function(){
        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2teachers"]').tab('show');
        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2teachers"]', 1);
    });
    
    $('[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]').click(function(){
        $('#myTab a[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]').tab('show');
        setTabActive('[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]', 1);
    });
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange Of Subject Groups Get Subjects
    var url11 = "\/subjects\/ajax_get_subjects\/SubjectClasslevel\/%23subject_group_id";
    getDependentListBox($("#subject_group_id"), $("#subject_id"), url11);
    var url12 = "\/subjects\/ajax_get_subjects\/ModifySubjectClasslevel\/%23subject_group_modify_id";
    getDependentListBox($("#subject_group_modify_id"), $("#subject_modify_id"), url12);
    var url_sub = "\/subjects\/ajax_get_subjects\/SubjectStudentView\/%23subject_view_group_id";
    getDependentListBox($("#subject_view_group_id"), $("#subject_view_id"), url_sub);

    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    var url2 = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id_all";
    getDependentListBox($("#academic_year_id_all"), $("#academic_term_id_all"), url2);
    var url21 = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_search_id";
    getDependentListBox($("#academic_year_search_id"), $("#academic_term_search_id"), url21);
    var url22 = "\/academic_terms\/ajax_get_terms\/ModifySubjectClasslevel\/%23academic_year_modify_id";
    getDependentListBox($("#academic_year_modify_id"), $("#academic_term_modify_id"), url22);
    var url_acad = "\/academic_terms\/ajax_get_terms\/SubjectStudentView\/%23academic_view_year_id";
    getDependentListBox($("#academic_view_year_id"), $("#academic_view_term_id"), url_acad);
    
    // OnChange Of Classlevel Get Class Room
    var url3 = "\/classrooms\/ajax_get_classes\/SubjectClasslevel\/%23classlevel_id";
    getDependentListBox($("#classlevel_id"), $("#class_id"), url3);
    var url31 = "\/classrooms\/ajax_get_classes\/SubjectClasslevel\/%23classlevel_id_all";
    getDependentListBox($("#classlevel_id_all"), $("#class_id_all"), url31);
    var url32 = "\/classrooms\/ajax_get_classes\/ModifySubjectClasslevel\/%23classlevel_modify_id";
    getDependentListBox($("#classlevel_modify_id"), $("#class_modify_id"), url32);
    var url_cla = "\/classrooms\/ajax_get_classes\/SubjectStudentView\/%23classlevel_view_id";
    getDependentListBox($("#classlevel_view_id"), $("#class_view_id"), url_cla);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    //When The Form assign_subject_form is submitted
    $(document.body).on('submit', '#assign_subject_form', function(){
        ajax_loading_image($('#msg_box2'), ' Loading');
        val = $('#assign_subject_form').serialize();
        $.post(domain_name+'/subjects/validateIfExist', val, function(data){
            if(data === '1'){
                set_msg_box($('#msg_box2'), ' Sorry This Subject Has Been Assigned Already... You Can Only Modify', 2)
            }else{
                ajax_remove_loading_image($('#msg_box2'));
                var output = '<ol>';
                $.each($('#assign_subject_form :selected'), function(key, value) {
                    if(key === 1 && $(value).val() !== '')
                        output += ' <li><b>Subject Name</b> : ' + $(value).html() + '</li>';
                    else if(key === 2 && $(value).val() !== '')
                        output += ' <li><b>Class Level</b> : ' + $(value).html() + '</li>';
                    else if(key === 3 && $(value).val() !== '')
                        output += ' <li><b>Class Room</b> : ' + $(value).html() + '</li>';
                    else if(key === 5 && $(value).val() !== '')
                        output += ' <li><b>Academic Term</b> : ' + $(value).html() + '</li>';
                });
                output += '</ol>';
                $('#confirm_output').html(output);
                $('#confirm_subject_modal').modal('show');
            }
        });
        return false; 
    });
    
    //When the confirm form is submitted
    $(document.body).on('submit', '#confirm_subject_form', function(){
        ajax_loading_image($('#msg_box_modal'), ' Assigning Subject');
        $.post(domain_name+'/subjects/assign', val, function(data){
            val = '';
            if(data === '0'){
                $('#msg_box_modal').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
                $('#msg_box2').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
            }else{
                $('#assign_subject_form')[0].reset();
                $('#confirm_subject_modal').modal('hide');
                ajax_remove_loading_image($('#msg_box_modal'));            
            }
        });
        return false; 
    });
    
    //Search Form For displaying Subjects Assigned to a Class
    $(document.body).on('submit', '#search_subject_form', function() {
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        var values = $('#search_subject_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/subjects/search_all',
            data: values,
            success: function(data){
                //$.post(domain_name+'/subjects/search_all', values, function(data){
                try{
                    var obj = $.parseJSON(data);
                    var pre = '0';
                    var output = '<caption><strong>Results Output From The Search</strong></caption>\
                                    <thead><tr>\
                                        <th>Subjects</th>\
                                        <th>Classlevels</th>\
                                        <th>#</th>\
                                        <th>Class Rooms</th>\
                                        <th>Exam Status</th>\
                                        <th>Teacher</th>\
                                        <th></th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SubjectClasslevel, function(key, value) {
                            var cur = value.subject_id;
                            if(cur !== pre){
                                output += '<tr>\
                                    <th>'+value.subject_name+'</th>\n\
                                    <th>'+value.classlevel+'</th><th></th><th></th><th></th><th></th><th></th>\\n\
                                </tr>';
                            }
                            pre = cur;
                            output += '<tr>\
                                <td></td><td></td>\n\\n\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\
                                <td style="font-size:medium">'+value.exam_status+'</td>\
                                <td style="font-size:medium">\
                                    <button value="'+value.teachers_subjects_id+'" title="'+value.employee_id+'" class="btn btn-link subject_teacher_edit">\n\
                                    <i class="fa fa-edit"></i> '+value.employee_name+'</button></td>\
                                <td>\
                                    <input type="hidden" class="input-small" value="'+value.class_id+'">\
                                    <input type="hidden" class="input-small" value="'+value.subject_classlevel_id+'">\
                                </td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#subjects_table_div_all').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="7">No Subject Found</th></tr>';
                        $('#subjects_table_div_all').html(output);
                    }
                } catch (exception) {
                    $('#subjects_table_div_all').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#subjects_table_div_all'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#subjects_table_div_all').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            }
        });
        return false;
   });
   
   //When the edit button is clicked show Employees Drop Down
   $(document.body).on('click', '.subject_teacher_edit', function(){
        var employees = employeeNames.clone();
        var buttonTD = $(this).parent();
        var teachers_subjects_id = $(this).val();
        old_btn = $(this).clone();
        buttonTD.html(employees);
        employees.val($(this).attr('title'));
        employees.prop('id', '');
        employees.attr('title', teachers_subjects_id);
        employees.addClass('teacher_subj_select');
        buttonTD.children('select').focus();        
   });
   
   //When No Changes is made to the Teachers Listbox //On Blur 
    $(document.body).on('blur', '.teacher_subj_select', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
   //On Change of the employees name assign to the class
   $(document.body).on('change', '.teacher_subj_select', function(){
        var teac_sub_id = $(this).attr('title');
        var class_id = $(this).parent().next().children(':nth-child(1)').val();
        var sub_class_id = $(this).parent().next().children(':nth-child(2)').val();
        var buttonTD = $(this).parent();
        var emp_id = $(this).val();
        var emp_name = $(this).children('option:selected').text();
        td_loading_image(buttonTD);
        $.post(domain_name+'/subjects/assign_tutor', 
            {teac_sub_id:teac_sub_id, emp_id:emp_id, class_id:class_id, sub_class_id:sub_class_id}, 
            function(data){
                if(data > 0){
                    buttonTD.html('<button value="'+data+'" title="'+emp_id+'" class="btn btn-link subject_teacher_edit">\n\
                    <i class="fa fa-edit"></i> '+emp_name+'</button></td>');
                }else{
                    alert('Error... Please Try Again');
                }
        });
    });
   
   
   
    //When the Search button is clicked for modifying subjects assigned to a classlevel or classroom
    $(document.body).on('submit', '#modify_subject_search_form', function(){
        ajax_loading_image($('#msg_box3'), ' Loading Contents');
        $.ajax({
            type: "POST",
            url: domain_name+'/subjects/search_assigned',
            data: $(this).serialize(),
            success: function(data){
                //$.post(domain_name+'/subjects/search_assigned', $(this).serialize(), function(data){
                try{
                    var obj = $.parseJSON(data);
                    var output = '<caption><strong>Results Output From The Search</strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Academic Term</th>\
                                        <th>Subjects</th>\
                                        <th>Classlevels</th>\
                                        <th>Class Rooms</th>\
                                        <th>Exam Status</th>\
                                        <th>Modify</th>\
                                        <th>Manage</th>\
                                        <th>Delete</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SubjectClasslevel, function(key, value) {
                            var ids = value.academic_term_id+'_'+value.subject_id+'_'+value.classlevel_id+'_'+value.class_id;
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.academic_term+'</td>\n\
                                <td>'+value.subject_name+'</td>\n\
                                <td>'+value.classlevel+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td style="font-size:medium">'+value.exam_status+'</td>\n\
                                <td>\
                                    <button type="submit" value="'+value.subject_classlevel_id+'" class="btn btn-warning btn-xs modify_subject_assign">\n\
                                    <i class="fa fa-edit"></i> Modify</button><input type="hidden" class="input-small" value="'+ids+'">\</td>\
                                <td>\
                                    <button type="submit" value="'+value.subject_classlevel_id+'" class="btn btn-success btn-xs manage_student_subject">\n\
                                    <i class="fa fa-ticket"></i> Students</button></td>\
                                <td>\
                                    <button type="submit" value="'+value.subject_classlevel_id+'" class="btn btn-danger btn-xs delete_subject_classlevel">\n\
                                    <i class="fa fa-thrash"></i> Delete</button></td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#modify_subjects_table_div').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="9">No Assigned Subject Found</th></tr>';
                        $('#modify_subjects_table_div').html(output);
                    }
                } catch (exception) {
                    $('#modify_subjects_table_div').html(data);
                }
                ajax_remove_loading_image($('#msg_box3'));
                //Scroll To Div
                scroll2Div($('#modify_subjects_table_div'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#modify_subjects_table_div').html(errorThrown);
                ajax_remove_loading_image($('#msg_box3'));
            }   
        });
        return false;
    });
    
    //When the Modify button is clicked show the modal for modifications
    $(document.body).on('click', '.modify_subject_assign', function(){
        var ids = $(this).next().val();
        var id = ids.split('_');
        var tr = $(this).parent().parent();
        $('#subject_classlevel_modify_id').val($(this).val());
        $('#academic_term_modify_id').html('<option value="'+id[0]+'">'+tr.children(':nth-child(2)').text()+'</option>');
        $('#subject_modify_id').html('<option value="'+id[1]+'">'+tr.children(':nth-child(3)').text()+'</option>');
        $('#classlevel_modify_id').val(id[2]);
        $('#class_modify_id').html('<option value="'+id[3]+'">'+tr.children(':nth-child(5)').text()+'</option>');
        $('#modify_subject_assign_modal').modal('show');
   });

   //When the Delete button is clicked show the modal for confirmation
    $(document.body).on('click', '.delete_subject_classlevel', function(){
        var id = $(this).val();
        $('#delete_subject_button').val(id);
        var tr = $(this).parent().parent('tr');
        var last = (tr.children(':nth-child(5)').text() === 'nill') ? '' : '<li>' + tr.children(':nth-child(5)').text() + '</li>';
        var out = '<li>' + tr.children(':nth-child(2)').text() + '</li><li>' + tr.children(':nth-child(3)').text() + '</li>';
        out = out + '<li>' + tr.children(':nth-child(4)').text() + '</li>' + last;
        $('#delete_output').html('<ul>' + out + '</ul>');
        $('#delete_subject_modal').modal('show');
   });


    //Deleting the subject assigned to classlevel form
    $(document.body).on('submit', '#delete_subject_form', function(){
        var id = $('#delete_subject_button').val();
        ajax_loading_image($('#msg_box_modal4'), ' Deleting Subject Assigned');
        $.post(domain_name+'/subjects/delete_assign', {subject_classlevel_id:id}, function(data){
            $('#modify_subjects_table_div').html('');
            ajax_remove_loading_image($('#msg_box_modal4'));
            $('#delete_subject_modal').modal('hide');
            //if(data == '0')
            //    $('#msg_box_modal4').html('<i class="fa fa-warning fa-2x"></i> Error...Try Again '+data);
        });
        return false;
    });

    //Subject Assignment Form...Assign to teachers
    $(document.body).on('submit', '#modify_subject_form', function(){
        ajax_loading_image($('#msg_box2_modal'), ' Modifying Subject Assigned');
        $.post(domain_name+'/subjects/modify_assign', $(this).serialize(), function(data){
            $('#modify_subjects_table_div').html('');
            ajax_remove_loading_image($('#msg_box2_modal'));            
            $('#modify_subject_assign_modal').modal('hide');
            if(data === '0')
                $('#msg_box2_modal').html('<i class="fa fa-warning fa-1x"></i> Error...Try Again '+data);
        });
        return false; 
    });    
    
    //When the Manage Student button is clicked show the modal for modifications
    $(document.body).on('click', '.manage_student_subject', function(){
        var id = $(this).val();        
        var tr = $(this).parent().parent();
        $.post(domain_name+'/subjects/search_students', {subject_classlevel_id:id}, function(data){
            try{
                var obj = $.parseJSON(data);
                var assign = ''; var avaliable = '';
                if(obj.Flag === 1){
                    $.each(obj.SubjectClasslevel, function(key, value) {
                        //ids += value.student_id+',';
                        assign += '<option value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</option>';
                    });
                    //ids = ids.substr(0, ids.length - 1);
                }
                if(obj.Flag2 === 1){
                    $.each(obj.SubjectNoClasslevel, function(key, value) {
                        avaliable += '<option value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</option>';
                    });
                }
                var cls = (tr.children(':nth-child(5)').text() === 'nill') ? tr.children(':nth-child(4)').text() : tr.children(':nth-child(5)').text();
                $('#msg_box3_modal').html('Managing <b>'+tr.children(':nth-child(3)').html()+'</b> Subject Offered by Students in <b>'+cls+'</b>');
                $('#LinkedLB').html(assign);
                $('#AvailableLB').html(avaliable);
                $('#manage_student_btn').val(id);
                $('#manage_students_modal').modal('show');
            } catch (exception) {
                $('#msg_box3_modal').html(data);
            }
        });
        return false; 
    });
    
    //OnClick Of The Update Student Button	//Insert or Update The Records
    $(document.body).on('click', '#manage_student_btn', function(){
        getNewValues($("#LinkedLB"), $("#manage_student_hidden"));
        $('#msg_box3_modal').html('<i class="fa fa-refresh"></i> Updating Record... <img src="'+domain_name+'/img/ajax-loader.gif" alt="Loading Image"/>');
        var sub_cls_id = $(this).val();
        var stud_ids = $("#manage_student_hidden").val();
        $.post(domain_name+'/subjects/updateStudentsSubjects', {sub_cls_id:sub_cls_id, stud_ids:stud_ids}, function(data){            
            if(data === '0')
                $('#msg_box3_modal').html('<i class="fa fa-warning fa-1x"></i> Error...Updating Record '+data);
            else{
                ajax_remove_loading_image($('#msg_box3_modal'));            
                $('#manage_students_modal').modal('hide');
            }
        });
    });


    /////////////////////////////////////////////////////////////////////////// Subject View Analysis //////////////////////////////////////////
    //When the Search button is clicked for viewing students subject scores in a classroom
    $(document.body).on('submit', '#search_subject_view_form', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        $.ajax({
            type: "POST",
            url: domain_name+'/subjects/search_subject',
            data: $(this).serialize(),
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var term = $('#academic_view_term_id').children('option:selected').text();
                    var subject_name = $('#subject_view_id').children('option:selected').text();
                    var class_name = $('#class_view_id').children('option:selected').text();
                    var output = '<caption><strong>'+term+' Results Output For '+class_name+ ' ('+subject_name+')</strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Full Name</th>\
                                        <th>1st C.A ('+obj.WA1+')</th>\
                                        <th>2nd C.A ('+obj.WA2+')</th>\
                                        <th>Exam ('+obj.WAExam+')</th>\
                                        <th>Total ('+obj.WATotal+')</th>\
                                        <th>Total (100%)</th>\
                                        <th>Details</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.StudentScores, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_fullname+'</td>\n\
                                <td>'+value.ca1+'</td>\n\
                                <td>'+value.ca2+'</td>\n\
                                <td>'+value.exam+'</td>\n\
                                <td>'+value.sum_total+'</td>\n\
                                <td>'+ ((value.sum_total * 100) / obj.WATotal).toFixed(2)+'</td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/subjects/view/'+value.std_sub_cla_term_id+'/'+(key+1)+'" class="btn btn-primary btn-xs">\n\
                                    <i class="fa fa-eye-slash"></i> View </a>\
                                </td>\n\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#subjects_view_table').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="8">No Record Found</th></tr>';
                        $('#subjects_view_table').html(output);
                    }
                } catch (exception) {
                    $('#subjects_view_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#subjects_view_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#subjects_view_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            }
        });
        return false;
    });






    //Functions Triggers
    //Moves Each Selected Option From Left 2 Right
    $(document.body).on('dblclick', '#AvailableLB', function(){
        moveSelection($("#available_span"), $("#AvailableLB"), $("#assign_span"), $("#LinkedLB"));
    });
    $(document.body).on('click', '#student_RightButton', function(){
        moveSelection($("#available_span"), $("#AvailableLB"), $("#assign_span"), $("#LinkedLB"));
    });
    //Moves Each Selected Option From Right 2 Left
    $(document.body).on('dblclick', '#LinkedLB', function(){
        moveSelection($("#assign_span"), $("#LinkedLB"), $("#available_span"), $("#AvailableLB"));
    });
    $(document.body).on('click', '#student_LeftButton', function(){
        moveSelection($("#assign_span"), $("#LinkedLB"), $("#available_span"), $("#AvailableLB"));
    });
    //Moves All Selected Option From Left 2 Right
    $(document.body).on('click', '#student_RightAllButton', function(){
        moveAll($("#available_span"), $("#AvailableLB"), $("#assign_span"), $("#LinkedLB"));
    });
    //Moves All Selected Option From Right 2 Left
    $(document.body).on('click', '#student_LeftAllButton', function(){
        moveAll($("#assign_span"), $("#LinkedLB"), $("#available_span"), $("#AvailableLB"));
    });
   
   // Auto Complete of Employee Name
//   $(document.body).on('keydown.autocomplete', '#employee_name', function(){
//        $(this).autocomplete({
//            source: domain_name+'/employees/autoComplete',
//            minLength: 0
//        });
//        $(this).autocomplete("option", "appendTo", "#display_autoComplete");
//        $(this).autocomplete({
//            select: function(event, ui) {
//                selected_id = ui.item.id;
//                $("#employee_id").val(selected_id);
//                $('#employee_nameerrorDiv').remove();
//            }
//        });
//        $(this).autocomplete({
//            open: function(event, ui) {
//                $("#employee_id").val(-1);
//            }
//        });
//    });
   
   
});