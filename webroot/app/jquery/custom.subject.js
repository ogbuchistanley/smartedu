$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    var val = '';
    var old_btn;
    var employeeNames = $('#employee_names').clone();
    $('#employee_names').addClass('hide');    
    
     //Set The Active Tab
     setTabActive('[href="'+domain_name+'/subjects/add2class#assign2class"]', 1);
     $('[href="'+domain_name+'/subjects/add2class#assign2class"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/subjects/add2class#assign2classlevel"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/subjects/add2class#assign2teachers"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/subjects/add2class#adjust_subjects_assign"]').attr('data-toggle', 'tab');

    $('[href="'+domain_name+'/subjects/add2class#assign2class"]').click(function(){
        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2class"]').tab('show');
        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2class"]', 1);
    });

    $('[href="'+domain_name+'/subjects/add2class#assign2classlevel"]').click(function(){
        $('#myTab a[href="'+domain_name+'/subjects/add2class#assign2classlevel"]').tab('show');
        setTabActive('[href="'+domain_name+'/subjects/add2class#assign2classlevel"]', 1);
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
    //var url11 = "\/subjects\/ajax_get_subjects\/SubjectClasslevel\/%23subject_group_id";
    //getDependentListBox($("#subject_group_id"), $("#subject_id"), url11);
    var url_sub = "\/subjects\/ajax_get_subjects\/SubjectStudentView\/%23subject_view_group_id";
    getDependentListBox($("#subject_view_group_id"), $("#subject_view_id"), url_sub);

    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    var url2 = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id_all";
    getDependentListBox($("#academic_year_id_all"), $("#academic_term_id_all"), url2);
    var url21 = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_search_id";
    getDependentListBox($("#academic_year_search_id"), $("#academic_term_search_id"), url21);
    var url22 = "\/academic_terms\/ajax_get_terms\/SubjectAssignLevel\/%23academic_year_id_level";
    getDependentListBox($("#academic_year_id_level"), $("#academic_term_id_level"), url22);
    var url_acad = "\/academic_terms\/ajax_get_terms\/SubjectStudentView\/%23academic_view_year_id";
    getDependentListBox($("#academic_view_year_id"), $("#academic_view_term_id"), url_acad);
    
    // OnChange Of Classlevel Get Class Room
    var url3 = "\/classrooms\/ajax_get_classes\/SubjectClasslevel\/%23classlevel_id";
    getDependentListBox($("#classlevel_id"), $("#class_id"), url3);
    var url31 = "\/classrooms\/ajax_get_classes\/SubjectClasslevel\/%23classlevel_id_all";
    getDependentListBox($("#classlevel_id_all"), $("#class_id_all"), url31);
    var url_cla = "\/classrooms\/ajax_get_classes\/SubjectStudentView\/%23classlevel_view_id";
    getDependentListBox($("#classlevel_view_id"), $("#class_view_id"), url_cla);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    //When The Form assign_subject_form is submitted
     $(document.body).on('submit', '#assign_subject_form', function(){
        ajax_loading_image($('#msg_box_1'), ' Loading Contents');
        var values = $('#assign_subject_form').serialize();
        $.post(domain_name+'/subjects/search_assign', values, function(data){
            try{
                var obj = $.parseJSON(data);
                var assign = ''; var avaliable = '';
                var assign_count = 0; var avaliable_count = 0;
                if(obj.Flag === 1){
                    $.each(obj.SubjectClasslevel, function(key, value) {
                        //ids += value.student_id+',';
                        assign += '<option value="'+value.subject_id+'">'+value.subject_name+'</option>';
                        assign_count++;
                    });
                    //ids = ids.substr(0, ids.length - 1);
                }
                if(obj.Flag2 === 1){
                    $.each(obj.SubjectNoClasslevel, function(key, value) {
                        avaliable += '<option value="'+value.subject_id+'">'+value.subject_name+'</option>';
                        avaliable_count++;
                    });
                }
                var cls = ($('#class_id').text() === 'nill') ? $('#classlevel_id').children('option:selected').text() : $('#class_id').children('option:selected').text();
                $('#msg_box_modal_1').html('<b>Assign Subjects Offered by Students in '+cls+'</b>');
                $('#class_id_1').val($('#class_id').val());
                $('#classlevel_id_1').val($('#classlevel_id').val());
                $('#academic_term_id_1').val($('#academic_term_id').val());

                $('#LinkedLB_1').html(assign);
                $('#AvailableLB_1').html(avaliable);
                $("#available_span_1").html(avaliable_count);
                $("#assign_span_1").html(assign_count);
                $('#assign_subject_modal_1').modal('show');
            } catch (exception) {
                $('#msg_box_modal_1').html(data);
            }
            ajax_remove_loading_image($('#msg_box_1'));
        });
        return false;
    });

    //OnClick Of The Assign Subjects Button	//Insert or Update The Records
    $(document.body).on('click', '#assign_subject_btn', function(){
        getNewValues($("#LinkedLB_1"), $("#subject_ids_1"));
        $('#msg_box_modal_1').html('<i class="fa fa-refresh"></i> Updating Record... <img src="'+domain_name+'/img/ajax-loader.gif" alt="Loading Image"/>');
        $("#confirm_subject_form").submit();
    });


    //When The Form assign_subjectlevel_form is submitted
    $(document.body).on('submit', '#assign_subjectlevel_form', function(){
        ajax_loading_image($('#msg_box_2'), ' Loading Contents');
        var values = $('#assign_subjectlevel_form').serialize();
        $.post(domain_name+'/subjects/search_assignlevel', values, function(data){
            try{
                var obj = $.parseJSON(data);
                var assign = ''; var avaliable = '';
                var assign_count = 0; var avaliable_count = 0;
                if(obj.Flag === 1){
                    $.each(obj.SubjectClasslevel, function(key, value) {
                        assign += '<option value="'+value.subject_id+'">'+value.subject_name+'</option>';
                        assign_count++;
                    });
                }
                if(obj.Flag2 === 1){
                    $.each(obj.SubjectNoClasslevel, function(key, value) {
                        avaliable += '<option value="'+value.subject_id+'">'+value.subject_name+'</option>';
                        avaliable_count++;
                    });
                }
                $('#msg_box_modal_2').html('<b>Assign Subjects Offered by Students in '+$('#classlevel_id_level').children('option:selected').text()+'</b>');
                $('#classlevel_id_2').val($('#classlevel_id_level').val());
                $('#academic_term_id_2').val($('#academic_term_id_level').val());

                $('#LinkedLB_2').html(assign);
                $('#AvailableLB_2').html(avaliable);
                $("#available_span_2").html(avaliable_count);
                $("#assign_span_2").html(assign_count);
                $('#assign_subject_modal_2').modal('show');
            } catch (exception) {
                $('#msg_box_modal_2').html(data);
            }
            ajax_remove_loading_image($('#msg_box_2'));
        });
        return false;
    });

    //OnClick Of The Assign Subjects Button	//Insert or Update The Records
    $(document.body).on('click', '#assign_levelsubject_btn', function(){
        getNewValues($("#LinkedLB_2"), $("#subject_ids_2"));
        $('#msg_box_modal_2').html('<i class="fa fa-refresh"></i> Updating Record... <img src="'+domain_name+'/img/ajax-loader.gif" alt="Loading Image"/>');
        $("#subjectclasslevel_form").submit();
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
                        output += '<tr><th colspan="8">No Assigned Subject Found</th></tr>';
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

    //When the Manage Student button is clicked show the modal for modifications
    $(document.body).on('click', '.manage_student_subject', function(){
        ajax_loading_image($('#msg_box3'), ' Loading Contents');
        var id = $(this).val();        
        var tr = $(this).parent().parent();
        $.post(domain_name+'/subjects/search_students', {subject_classlevel_id:id}, function(data){
            try{
                var obj = $.parseJSON(data);
                var assign = ''; var avaliable = '';
                var assign_count = 0; var avaliable_count = 0;
                if(obj.Flag === 1){
                    $.each(obj.SubjectClasslevel, function(key, value) {
                        //ids += value.student_id+',';
                        assign += '<option value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</option>';
                        assign_count++;
                    });
                    //ids = ids.substr(0, ids.length - 1);
                }
                if(obj.Flag2 === 1){
                    $.each(obj.SubjectNoClasslevel, function(key, value) {
                        avaliable += '<option value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</option>';
                        avaliable_count++;
                    });
                }
                var cls = (tr.children(':nth-child(5)').text() === 'nill') ? tr.children(':nth-child(4)').text() : tr.children(':nth-child(5)').text();
                $('#msg_box3_modal').html('Managing <b>'+tr.children(':nth-child(3)').html()+'</b> Subject Offered by Students in <b>'+cls+'</b>');
                $('#LinkedLB').html(assign);
                $('#AvailableLB').html(avaliable);
                $("#available_span").html(avaliable_count);
                $("#assign_span").html(assign_count);
                $('#manage_student_btn').val(id);
                $('#manage_students_modal').modal('show');
            } catch (exception) {
                $('#msg_box3_modal').html(data);
            }
            ajax_remove_loading_image($('#msg_box3'));
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
                                        <th>C. A ('+obj.WA+')</th>\
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
                                <td>'+value.ca+'</td>\n\
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
                        output += '<tr><th colspan="7">No Record Found</th></tr>';
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


///////////////////////////////////////////// Teacher Subjects  //////////////////////////////////////////////////////////////////////////
    //When the Search button is clicked for managing students subjects assigned to a staff
    $(document.body).on('submit', '#manage_student_subject_form', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        $.ajax({
            type: "POST",
            url: domain_name+'/subjects/search_assigned2Staff',
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
                                        <th>Manage</th>\
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
                                <td style="font-size:medium">'+value.exam_status+'</td>\n\
                                <td>\
                                    <button type="submit" value="'+value.subject_classlevel_id+'" rel="'+value.class_id+'" class="btn btn-success btn-xs manage_student_subject_btn">\n\
                                    <i class="fa fa-ticket"></i> Students</button></td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#manage_student_subject_table').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="9">No Assigned Subject Found</th></tr>';
                        $('#manage_student_subject_table').html(output);
                    }
                } catch (exception) {
                    $('#manage_student_subject_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#manage_student_subject_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#manage_student_subject_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            }
        });
        return false;
    });

    //When the Manage Student button is clicked show the modal for modifications for only subjects assigned to the login staff
    $(document.body).on('click', '.manage_student_subject_btn', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        var sub_id = $(this).val();
        var class_id = $(this).attr('rel');
        var tr = $(this).parent().parent();
        $.post(domain_name+'/subjects/search_students_subjects', {subject_classlevel_id:sub_id, class_id:class_id}, function(data){
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
                $('#msg_box_modal').html('Managing <b>'+tr.children(':nth-child(3)').html()+'</b> Subject Offered by Students in <b>'+cls+'</b>');
                $('#LinkedLB').html(assign);
                $('#AvailableLB').html(avaliable);
                $('#manage_student_sub_btn').val(sub_id);
                $('#manage_class_sub_hidden').val(class_id);
                $('#manage_students_modal').modal('show');
            } catch (exception) {
                $('#msg_box_modal').html(data);
            }
            ajax_remove_loading_image($('#msg_box'));
        });
        return false;
    });


    //OnClick Of The Update Student Button	//Insert or Update The Records
    $(document.body).on('click', '#manage_student_sub_btn', function(){
        getNewValues($("#LinkedLB"), $("#manage_student_sub_hidden"));
        $('#msg_box_modal').html('<i class="fa fa-refresh"></i> Updating Record... <img src="'+domain_name+'/img/ajax-loader.gif" alt="Loading Image"/>');
        var sub_cls_id = $(this).val();
        var stud_ids = $("#manage_student_sub_hidden").val();
        var class_id = $("#manage_class_sub_hidden").val();
        $.post(domain_name+'/subjects/updateStudentsStaffSubjects', {sub_cls_id:sub_cls_id, stud_ids:stud_ids, class_id:class_id}, function(data){
            if(data === '0')
                $('#msg_box_modal').html('<i class="fa fa-warning fa-1x"></i> Error...Updating Record ' + data);
            else
                ajax_remove_loading_image($('#msg_box_modal'));
            $('#manage_students_modal').modal('hide');
        });
    });
    

    //Functions Triggers
    //Moves Each Selected Option From Left 2 Right
    $(document.body).on('dblclick', '#AvailableLB_1', function(){
        moveSelection($("#available_span_1"), $("#AvailableLB_1"), $("#assign_span_1"), $("#LinkedLB_1"));
    });
    $(document.body).on('click', '#student_RightButton_1', function(){
        moveSelection($("#available_span_1"), $("#AvailableLB_1"), $("#assign_span_1"), $("#LinkedLB_1"));
    });
    //Moves Each Selected Option From Right 2 Left
    $(document.body).on('dblclick', '#LinkedLB_1', function(){
        moveSelection($("#assign_span_1"), $("#LinkedLB_1"), $("#available_span_1"), $("#AvailableLB_1"));
    });
    $(document.body).on('click', '#student_LeftButton_1', function(){
        moveSelection($("#assign_span_1"), $("#LinkedLB_1"), $("#available_span_1"), $("#AvailableLB_1"));
    });
    //Moves All Selected Option From Left 2 Right
    $(document.body).on('click', '#student_RightAllButton_1', function(){
        moveAll($("#available_span_1"), $("#AvailableLB_1"), $("#assign_span_1"), $("#LinkedLB_1"));
    });
    //Moves All Selected Option From Right 2 Left
    $(document.body).on('click', '#student_LeftAllButton_1', function(){
        moveAll($("#assign_span_1"), $("#LinkedLB_1"), $("#available_span_1"), $("#AvailableLB_1"));
    });


    //Moves Each Selected Option From Left 2 Right
    $(document.body).on('dblclick', '#AvailableLB_2', function(){
        moveSelection($("#available_span_2"), $("#AvailableLB_2"), $("#assign_span_2"), $("#LinkedLB_2"));
    });
    $(document.body).on('click', '#student_RightButton_2', function(){
        moveSelection($("#available_span_2"), $("#AvailableLB_2"), $("#assign_span_2"), $("#LinkedLB_2"));
    });
    //Moves Each Selected Option From Right 2 Left
    $(document.body).on('dblclick', '#LinkedLB_2', function(){
        moveSelection($("#assign_span_2"), $("#LinkedLB_2"), $("#available_span_2"), $("#AvailableLB_2"));
    });
    $(document.body).on('click', '#student_LeftButton_2', function(){
        moveSelection($("#assign_span_2"), $("#LinkedLB_2"), $("#available_span_2"), $("#AvailableLB_2"));
    });
    //Moves All Selected Option From Left 2 Right
    $(document.body).on('click', '#student_RightAllButton_2', function(){
        moveAll($("#available_span_2"), $("#AvailableLB_2"), $("#assign_span_2"), $("#LinkedLB_2"));
    });
    //Moves All Selected Option From Right 2 Left
    $(document.body).on('click', '#student_LeftAllButton_2', function(){
        moveAll($("#assign_span_2"), $("#LinkedLB_2"), $("#available_span_2"), $("#AvailableLB_2"));
    });


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

   
});