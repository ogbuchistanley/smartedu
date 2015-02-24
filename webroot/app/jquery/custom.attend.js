$('document').ready(function(){
    //
    //Set The Active Tab
     setTabActive('[href="'+domain_name+'/attends/index#take_attend"]', 1);
     $('[href="'+domain_name+'/attends/index#take_attend"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/attends/index#edit_attend"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/attends/index#summary"]').attr('data-toggle', 'tab');
    
    //on click of Assign Students to a class link... activate the link
    $('[href="'+domain_name+'/attends/index#take_attend"]').click(function(){
        $('#myTab a[href="'+domain_name+'/attends/index#take_attend"]').tab('show');
        setTabActive('[href="'+domain_name+'/attends/index#take_attend"]', 1);
    });
    //on click of Search for Students in a class link... activate the link
    $('[href="'+domain_name+'/attends/index#edit_attend"]').click(function(){
        $('#myTab a[href="'+domain_name+'/attends/index#edit_attend"]').tab('show');
        setTabActive('[href="'+domain_name+'/attends/index#edit_attend"]', 1);
    });
    //on click of Search for Students in a class link... activate the link
    $('[href="'+domain_name+'/attends/index#summary"]').click(function(){
        $('#myTab a[href="'+domain_name+'/attends/index#summary"]').tab('show');
        setTabActive('[href="'+domain_name+'/attends/index#summary"]', 1);
    });
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Dependent ListBox
    var url = "\/academic_terms\/ajax_get_terms\/SearchAttend\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    var url2 = "\/academic_terms\/ajax_get_terms\/SummaryAttend\/%23academic_year_id_all";
    getDependentListBox($("#academic_year_id_all"), $("#academic_term_id_all"), url2);
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Count the number of students that are checked for attendance
    function countCheckedboxes(){
        var mark = 0;
        var count = 0;
        $($('.check_student')).each(function(index, element) {
            count++;
            if($(element).prop('checked') === true){
                mark++;
            }
        });
        $("#mark_span").html(mark);
        $("#unmark_span").html(count - mark);
    }
    
    
    // Attendance DataPicker
    $('#attend_date').datepicker({
        maxDate: 0
    });
    //.$('#search_date').datepicker();
    $('#date_to').datepicker({
        maxDate: 0,
        showWeek: true,
        firstDay: 1,
        changeMonth: true,
        changeYear: true,
        yearRange: "-20:+0"
    });
    $('#date_from').datepicker({
        maxDate: 0,
        showWeek: true,
        firstDay: 1,
        changeMonth: true,
        changeYear: true,
        yearRange: "-20:+0"
    });
    $( "#search_date" ).datepicker({
        maxDate: 0,
        changeMonth: true,
        changeYear: true,
        yearRange: "-20:+0"
    });
    
    //When The Form assign_subject_form is submitted
    $(document.body).on('click', '.mark_attend_btn', function(){
        ajax_loading_image($('#msg_box'), ' Loading...');
        var cls_yr_id = $(this).val();
        var tr = $(this).parent().parent();
        var class_name = tr.children(':nth-child(2)').html();
        $.post(domain_name+'/attends/search_students', {cls_yr_id:cls_yr_id}, function(data){
            try{
                var obj = $.parseJSON(data);
                var avaliable = ''; 
                var linked = ''; 
                if(obj.Flag === 1){
                    $.each(obj.Students, function(key, value) {
                        //avaliable += '<option value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</option>';
                        if(key % 2 === 0){
                            avaliable += '<div class="checkbox"><label><input class="check_student" type="checkbox" value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</label></div>';
                        }else if(key % 2 === 1){
                            linked += '<div class="checkbox"><label><input type="checkbox" class="check_student" value="'+value.student_id+'">'+value.student_no.toUpperCase()+': '+value.student_name+'</label></div>';
                        }
                    });
                }
                $('#AvailableLB').html(avaliable);
                $('#LinkedLB').html(linked);
                $('#class_id').val(obj.ClassID);
                $('#caption_span').html(class_name);
            } catch (exception) {
                $('#attend_table_div').html(data);
            }
            $('#attend_table_div').removeClass('hide');
            ajax_remove_loading_image($('#msg_box'));
            //Scroll To Div
            scroll2Div($('#attend_table_div'));
        });
        return false; 
    });
    
    
    //Count The Checkboxes when checked
    $(document.body).on('click', '.check_student', function(){
        countCheckedboxes();
    });
    
    //Count The Checkboxes when checked
    $(document.body).on('click', '#check_all', function(){
        $('.check_student').prop("checked", $(this).prop("checked"));
        countCheckedboxes();
    });
    
    
    //OnSubmit Of The Attendance Form	//Insert The Records
    $(document.body).on('submit', '#attendance_form', function(){
        $("#student_ids").val('');
        var ids = '';
        $($('.check_student')).each(function(index, element) {
            if($(element).prop('checked') === true){
                ids = ids + $(element).val() + ',';
            }
            $("#student_ids").val(ids);
        });	
        //getNewValues($("#LinkedLB"), $("#student_ids"));
        ajax_loading_image($('#msg_box'), ' Saving Record...');
        ajax_loading_image($('#msg_box_1'), ' Saving Record...');
        var values = $('#attendance_form').serialize();
        $.post(domain_name+'/attends/validateIfExist', values, function(data){
            if(data === '1'){
                set_msg_box($('#msg_box'), ' Attendance For The Date Has Been Taken Already... You Can Only Edit', 2)
                set_msg_box($('#msg_box_1'), ' Attendance For The Date Has Been Taken Already... You Can Only Edit', 2)
            }else{
                $.post(domain_name+'/attends/take_attend', values, function(data1){            
                    try{
                        if(data1 > 0){ 
                            window.location.replace(domain_name+'/attends');
                        }
                    } catch (exception) {
                        $('#attend_table_div').html(data1);
                    }
                });
            }
        });
        return false;
    });	
    
    //Search Form
    $(document.body).on('submit', '#search_attend_form', function() {
        ajax_loading_image($('#msg_box2'), ' Searching ...');
        var values = $('#search_attend_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/attends/search_attend',
            data: values,
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var term = $('#academic_term_id').children('option:selected').text();
                    var output = '<caption><strong>Results Output From The Search ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Rooms</th>\
                                        <th>Academic Term</th>\
                                        <th>Head Tutor</th>\
                                        <th>Attendance Date</th>\
                                        <th colspan="2">Attendance</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.Attend, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td>'+value.academic_term+'</td>\n\
                                <td>'+value.head_tutor+'</td>\
                                <td>'+value.attend_date+'</td>\n\
                                <td  style="font-size: medium">\n\
                                    <a target="__blank" href="'+domain_name+'/attends/view/'+value.attend_id+'" class="btn btn-primary btn-xs">\n\
                                    <i class="fa fa-eye"></i> View</a>\
                                </td>\
                                <td  style="font-size: medium">\n\
                                    <a target="__blank" href="'+domain_name+'/attends/edit/'+value.attend_id+'" class="btn btn-warning btn-xs">\n\
                                    <i class="fa fa-edit"></i> Edit</a>\
                                </td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#attend_search_table_div').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="7">No Attendance Found</th></tr>';
                        $('#attend_search_table_div').html(output);
                    }
                } catch (exception) {
                    $('#attend_search_table_div').html(data);
                }
                ajax_remove_loading_image($('#msg_box2'));
                //Scroll To Div
                scroll2Div($('#attend_search_table_div'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#attend_search_table_div').html(errorThrown);
                ajax_remove_loading_image($('#msg_box2'));
            }            
        });
        return false;
    });
    
    
    //OnSubmit Of The Attendance Edit Form	//Update The Records
    $(document.body).on('submit', '#attendance_edit_form', function(){
        $("#student_ids").val('');
        var ids = '';
        $($('.check_student')).each(function(index, element) {
            if($(element).prop('checked') === true){
                ids = ids + $(element).val() + ',';
            }
            $("#student_ids").val(ids);
        });
        return true;
    });	
    
    
    //Search Form for attendance summary
    $(document.body).on('submit', '#search_summary_form', function() {
        ajax_loading_image($('#msg_box3'), ' Searching ...');
        var values = $('#search_summary_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/attends/search_summary',
            data: values,
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var term = $('#academic_term_id_all').children('option:selected').text();
                    var output = '<caption><strong>Results Output From The Search ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Rooms</th>\
                                        <th>Academic Term</th>\
                                        <th>Head Tutor</th>\
                                        <th>Attendance</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.Summary, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\n\
                                <td>'+value.academic_term+'</td>\n\
                                <td>'+value.head_tutor+'</td>\
                                <td  style="font-size: medium">\n\
                                    <a target="__blank" href="'+domain_name+'/attends/summary/'+value.cls_term_id+'" class="btn btn-primary btn-xs">\n\
                                    <i class="fa fa-eye"></i> View</a>\
                                </td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#summary_table_div').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="5">No Subject Found</th></tr>';
                        $('#summary_table_div').html(output);
                    }
                } catch (exception) {
                    $('#summary_table_div').html(data);
                }
                ajax_remove_loading_image($('#msg_box3'));
                //Scroll To Div
                scroll2Div($('#summary_table_div'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#summary_table_div').html(errorThrown);
                ajax_remove_loading_image($('#msg_box3'));
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
});