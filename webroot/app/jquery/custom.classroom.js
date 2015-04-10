$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    var old_btn;
    var employeeNames = $('#employee_names').clone();
    $('#employee_names').addClass('hide');    
    
    //Set The Active Tab
     setTabActive('[href="'+domain_name+'/classrooms/index#assign_students"]', 1);
     $('[href="'+domain_name+'/classrooms/index#assign_students"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/classrooms/index#search_students"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/classrooms/index#assign_head_tutor"]').attr('data-toggle', 'tab');
//    var hash =  window.location.hash;		
//    if(hash === "#assign_students"){
//        $('#myTab a[href="'+domain_name+'/students/add2class#assign_students"]').tab('show');
//        setTabActive('[href="'+domain_name+'/students/add2class#assign_students"]', 1);
//    }else if(hash === "#search_students"){
//        $('#myTab a[href="'+domain_name+'/students/add2class#search_students"]').tab('show');
//        setTabActive('[href="'+domain_name+'/students/add2class#search_students"]', 1);
//    }
    
    //on click of Assign Students to a class link... activate the link
    $('[href="'+domain_name+'/classrooms/index#assign_students"]').click(function(){
        $('#myTab a[href="'+domain_name+'/classrooms/index#assign_students"]').tab('show');
        setTabActive('[href="'+domain_name+'/classrooms/index#assign_students"]', 1);
    });
    //on click of Search for Students in a class link... activate the link
    $('[href="'+domain_name+'/classrooms/index#search_students"]').click(function(){
        $('#myTab a[href="'+domain_name+'/classrooms/index#search_students"]').tab('show');
        setTabActive('[href="'+domain_name+'/classrooms/index#search_students"]', 1);
    });
    //on click of Search for Students in a class link... activate the link
    $('[href="'+domain_name+'/classrooms/index#assign_head_tutor"]').click(function(){
        $('#myTab a[href="'+domain_name+'/classrooms/index#assign_head_tutor"]').tab('show');
        setTabActive('[href="'+domain_name+'/classrooms/index#assign_head_tutor"]', 1);
    });
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Dependent ListBox
    var url = "\/classrooms\/ajax_get_classes\/StudentsClass\/%23classlevel_id";
    var url2 = "\/classrooms\/ajax_get_classes\/StudentsClassAll\/%23classlevel_id_all";
    getDependentListBox($("#classlevel_id"), $("#class_id"), url);
    getDependentListBox($("#classlevel_id_all"), $("#class_id_all"), url2);
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    //Search Form For assigning students to class
   $('#search_form').bind('submit', function(){
       $('#hidden_class_id').val($('#class_id').val());
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        var val = $('#search_form').serialize();
        $.ajax({ 
            type: 'POST', 
            url: ''+domain_name+'/students_classes/search', 
            data: val,
            success: function(data){  
                try {
                    var obj = $.parseJSON(data);
                    var available = '<caption><strong>List Of Available Students</strong></caption>\
                                    <tr id="available_student_tr">\
                                        <th >Student No.</th>\
                                        <th >Full Name</th>\
                                        <th ><i class="fa fa-check-square"></i> </th>\
                                    </tr>';
                    var assign = '<caption><strong>List Of Assigned Students</strong></caption>\
                                    <tr id="assign_student_tr">\
                                        <th >Student No.</th>\
                                        <th >Full Name</th>\
                                        <th ><i class="fa fa-times"></i> </th>\
                                    </tr>';
                    if(obj.Flag2 === 1){
                        $.each(obj.StudentsNoClass, function(key, value) {
                            available += '<tr>\
                                <td>'+value.student_no+'</td>\n\
                                <td>'+value.first_name+' '+value.surname+' '+value.other_name+'</td>\n\
                                <td><input type="checkbox" class="assign_student" title="-1" value="'+value.student_id+'"/> </td></tr>\n\
                            ';                        
                        });
                        $('#available_students').html(available);
                    }else if(obj.Flag2 === 0){
                        available += '<tr><th colspan="3">No Student Available</th></tr>';
                        $('#available_students').html(available);
                    }
                    if(obj.Flag === 1){
                        $.each(obj.StudentsClass, function(key, value) {
                            assign += '<tr>\
                                <td>'+value.student_no+'</td>\n\
                                <td>'+value.first_name+' '+value.surname+' '+value.other_name+'</td>\n\
                                <td><input type="checkbox" class="assign_student" title="'+value.student_class_id+'" checked="checked" value="'+value.student_id+'"/> </td></tr>\n\
                            ';                        
                        });
                        $('#assigned_students').html(assign);
                    }else if(obj.Flag === 0){
                        assign += '<tr><th colspan="3">No Student Has Been Assigned</th></tr>';
                        $('#assigned_students').html(assign);
                    }
                } catch (exception) {
                    $('#assigned_students').html(data);
                }
                $('#students_table_div').removeClass('hide');
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#students_table_div'));
            }
        });
        return false;
    });
    
    //When The Checkbox is Checked To Assign A Student to Class
   $(document.body).on('click', '.assign_student', function(){
        ajax_loading_image($('#msg_box'), ' Processing...');
        var class_id = $('#hidden_class_id').val();
        var student_id = $(this).val();
        var student_class_id = $(this).prop('title');
        var parent_tr = $(this).parent().parent();
        //Assign A Students
        if($(this).prop('checked') === true){
            $(this).attr("checked", "checked");
            $.post(''+domain_name+'/students_classes/assign', {student_class_id:student_class_id, student_id:student_id, class_id:class_id}, function(data){
                if(data !== '0'){
                    var title = parent_tr.children().next().next();
                    title.children().attr("title", data);
                    if($("#assign_student_tr").next().children().html() === "No Student Has Been Assigned"){
                        $("#assign_student_tr").next().remove();
                    }
                    $("#assign_student_tr").after("<tr><td>"+parent_tr.children().html()+"</td><td>"+parent_tr.children().next().html()+"</td><td>"+title.html()+"</td></tr>");
                    parent_tr.remove();
                    ajax_remove_loading_image($('#msg_box'));
                }
            });	
        //Remove An Assigned Examiner
        } else if($(this).prop('checked') === false){
            $(this).removeAttr("checked");
            $.post(''+domain_name+'/students_classes/assign', {student_class_id:student_class_id, student_id:student_id}, function(data){
                if(data !== '0'){
                    var title = parent_tr.children().next().next();
                    title.children().attr("title", '-1');
                    if($("#available_student_tr").next().children().html() === "No Student Available"){
                        $("#available_student_tr").next().remove();
                    }
                    $("#available_student_tr").after("<tr><td>"+parent_tr.children().html()+"</td><td>"+parent_tr.children().next().html()+"</td><td>"+title.html()+"</td></tr>");
                    parent_tr.remove();
                    ajax_remove_loading_image($('#msg_box'));
                }
            });	
        }
        //return false;
    });
    
    //Search Form For displaying students to class
    $('#search_form_all').bind('submit', function(){
        ajax_loading_image($('#msg_box2'), ' Loading Contents');
        var val = $('#search_form_all').serialize();
        $.ajax({ 
            type: 'POST', 
            url: ''+domain_name+'/students_classes/search_all', 
            data: val,
            success: function(data){ 
                try {
                    //json = JSON.parse(jsonString);
                    var obj = $.parseJSON(data);
                    var output = '<caption><strong>Results Output From The Search</strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>No.</th>\
                                        <th>Full Name</th>\
                                        <th>Gender</th>\
                                        <th>Birth Date</th>\
                                        <th>Class</th>\
                                        <th>View</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.StudentsClass, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_no+'</td>\n\
                                <td>'+value.first_name+' '+value.surname+' '+value.other_name+'</td>\n\
                                <td>'+value.gender+'</td>\n\
                                <td>'+value.birth_date+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td><a target="__blank" href="'+domain_name+'/students/view/'+value.hashed_id+'" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>\n\
                            </tr>';                        
                        });
                        output += '</tbody>';
                        $('#students_table_div_all').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="7">No Student Found</th></tr>';
                        $('#students_table_div_all').html(output);
                    }
                } catch (exception) {
                    $('#students_table_div_all').html(data);
                }
                ajax_remove_loading_image($('#msg_box2'));
                //Scroll To Div
                scroll2Div($('#students_table_div_all'));
            }
        });
        return false;
   });
   
   
   //Search Form For displaying classrooms and thier class teacher
    $('#search_classes_form').bind('submit', function(){
        ajax_loading_image($('#msg_box3'), ' Loading Contents');
        var val = $('#search_classes_form').serialize();
        $.ajax({ 
            type: 'POST', 
            url: ''+domain_name+'/classrooms/search_classes', 
            data: val,
            success: function(data){ 
                try {
                    //json = JSON.parse(jsonString);
                    var obj = $.parseJSON(data);
                    var output = '<caption><strong>Results Output From The Search</strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Room</th>\
                                        <th>No. of Students</th>\
                                        <th>Class Teacher</th>\
                                        <th></th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.Classroom, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td>'+value.student_count+'</td>\n\
                                <td >\
                                    <button value="'+value.teacher_class_id+'" title="'+value.employee_id+'" \n\
                                        style="font-size:medium" class="btn btn-link head_tutor_edit">\n\
                                    <i class="fa fa-edit"></i> '+value.employee_name+'</button>\n\
                                </td>\\n\
                                <td>\
                                    <input type="hidden" class="input-small" value="'+value.class_id+'">\
                                    <input type="hidden" class="input-small" value="'+value.academic_year_id+'">\
                                </td>\
                            </tr>';                        
                        });
                        output += '</tbody>';
                        $('#head_tutor_class_table').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="5">No Record Found</th></tr>';
                        $('#head_tutor_class_table').html(output);
                    }
                } catch (exception) {
                    $('#head_tutor_class_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box3'));
                //Scroll To Div
                scroll2Div($('#head_tutor_class_table'));
            }
        });
        return false;
   });
   
   //When the edit button is clicked show Staffs Drop Down
   $(document.body).on('click', '.head_tutor_edit', function(){
        var employees = employeeNames.clone();
        var buttonTD = $(this).parent();
        var teacher_class_id = $(this).val();
        old_btn = $(this).clone();
        buttonTD.html(employees);
        employees.val($(this).attr('title'));
        employees.prop('id', '');
        employees.attr('title', teacher_class_id);
        employees.addClass('head_tutor_select');
        buttonTD.children('select').focus();        
   });
   
   
   //When No Changes is made to the Class Teacher Listbox //On Blur
    $(document.body).on('blur', '.head_tutor_select', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
   //On Change of the Staffs name assign to the class
   $(document.body).on('change', '.head_tutor_select', function(){
        var teac_class_id = $(this).attr('title');
        var class_id = $(this).parent().next().children(':nth-child(1)').val();
        var acad_year_id = $(this).parent().next().children(':nth-child(2)').val();
        var buttonTD = $(this).parent();
        var emp_id = $(this).val();
        var emp_name = $(this).children('option:selected').text();
        td_loading_image(buttonTD);
        $.ajax({
            type: "POST",
            url: ''+domain_name+'/classrooms/assign_head_tutor',
            data: {teac_class_id:teac_class_id, emp_id:emp_id, class_id:class_id, acad_year_id:acad_year_id},
            success: function(data){                
                if(data > 0){
                    buttonTD.html('<button value="'+data+'" title="'+emp_id+'" class="btn btn-link head_tutor_edit">\n\
                    <i class="fa fa-edit"></i> '+emp_name+'</button></td>');
                    ajax_remove_loading_image($('#msg_box3'));
                }else{
                    set_msg_box($('#msg_box3'), ' Error... Please Try Again', 2);
                    $('#head_tutor_class_table').html('');
                }
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#head_tutor_class_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box3'));
            }    
        });    
    });    
});