$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    var itemFormData = '';
    var old_btn;
    
    //Set The Active Tab
     if($('#myTab a[href="'+domain_name+'/items/index#process_fees"]').text() === ''){
        setTabActive('[href="'+domain_name+'/items/index#bill_student"]', 1);
        $('#myTab a[href="'+domain_name+'/items/index#bill_student"]').parent('li').addClass('active');
        $('#bill_student').addClass('active');
        $('#myTab a[href="'+domain_name+'/items/index#bill_student"]').tab('show');
     } else {
        setTabActive('[href="'+domain_name+'/items/index#process_fees"]', 1);
        $('#myTab a[href="'+domain_name+'/items/index#process_fees"]').parent('li').addClass('active');
        $('#process_fees').addClass('active');
        $('#myTab a[href="'+domain_name+'/items/index#process_fees"]').tab('show');
     }
     $('[href="'+domain_name+'/items/index#process_fees"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/items/index#bill_student"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/items/index#search"]').attr('data-toggle', 'tab');
     
    $('[href="'+domain_name+'/items/index#process_fees"]').click(function(){
        $('#myTab a[href="'+domain_name+'/items/index#process_fees"]').tab('show');
        setTabActive('[href="'+domain_name+'/items/index#process_fees"]', 1);
    });
        
    $('[href="'+domain_name+'/items/index#bill_student"]').click(function(){
        $('#myTab a[href="'+domain_name+'/items/index#bill_student"]').tab('show');
        setTabActive('[href="'+domain_name+'/items/index#bill_student"]', 1);
    });
    
    $('[href="'+domain_name+'/items/index#search"]').click(function(){
        $('#myTab a[href="'+domain_name+'/items/index#search"]').tab('show');
        setTabActive('[href="'+domain_name+'/items/index#search"]', 1);
    });

    // Process Fees Date... DataPicker
    $('#process_date').datepicker({
        maxDate: 0,
        changeMonth: true,
        changeYear: true,
        yearRange: "-10:+0"
    });
    
    
    /////////////////////////////////////////////////// Fees Summary //////////////////////////////////////////////////////////
 
    // Discrete Bar chart on Payment Status // Displaying Students Class Level / Class Room Payment Status
    //$(document.body).on('submit', '#search_payment_status', function(){
        $.post(domain_name+'/items/payment_status', function(data){
             var result = $.parseJSON(data);
             var count = 1;
             $.each(result.ClasslevelName, function(key, value) {
                 //alert(result['Reception']);
                 Morris.Bar({
                   element: 'payment_status'+count,
                   data: result[value],
                   xkey: 'classrooms',
                   ykeys: ['paid', 'not_paid'],
                   labels: ['Paid', 'Not Paid'],
                   xLabelAngle: 40,
                   barColors: [ "#90c657", "#e45857" ],
                   resize: true,
                 });
                 $('#total_paid'+count).html(result[value][0][0]);
                 $('#total_Npaid'+count).html(result[value][0][1]);
                 $('#total_students'+count).html(result[value][0][0] + result[value][0][1]);
                 count++;
             });
         });
     //});
    /////////////////////////////////////////////////// \\Fees Summary //////////////////////////////////////////////////////////
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    var url = "\/academic_terms\/ajax_get_terms\/ProcessItem\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#academic_term_id"), url);
    
    var url3 = "\/academic_terms\/ajax_get_terms\/SearchExamTAScores\/%23academic_year_examTAScores_id";
    getDependentListBox($("#academic_year_examTAScores_id"), $("#academic_term_examTAScores_id"), url3);

    var url5 = "\/classrooms\/ajax_get_classes\/SearchExamTAScores\/%23classlevel_examTAScores_id";
    getDependentListBox($("#classlevel_examTAScores_id"), $("#class_examTAScores_id"), url5);
    
    var url7 = "\/academic_terms\/ajax_get_terms\/SearchPayment\/%23search_academic_year_id";
    getDependentListBox($("#search_academic_year_id"), $("#search_academic_term_id"), url7);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //When The Form process_item_form is submitted
    $(document.body).on('submit', '#process_item_form', function(){
        ajax_loading_image($('#msg_box'), ' Processing');
        itemFormData = $('#process_item_form').serialize();
        $.post(domain_name+'/items/validateIfExist', itemFormData, function(data){
            if(data === '1'){
               set_msg_box($('#msg_box'), 'The Fees Has Been Processed For The Academic Term Already', 2)
            }else{
                ajax_remove_loading_image($('#msg_box'));
                var term = $('#academic_term_id').children('option:selected').text();
                var output = '<ol>\n\
                                <li><b>Academic Term</b> : ' + term + '</li>\n\
                                <li><b>Process Date</b> : ' + $('#process_date').val() + '</li>\n\
                            </ol>';
                $('#confirm_output').html(output);
                $('#confirm_process_fees_modal').modal('show');
            }
        });
        return false;
    });
    
    //When the confirm modal form is submitted
    $(document.body).on('submit', '#confirm_process_fees_form', function(){
        ajax_loading_image($('#msg_box_modal'), ' Processing Fees');
        $.post(domain_name+'/items/process_fees', itemFormData, function(data){
            itemFormData = '';
            if(data === '0'){
                $('#msg_box_modal').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
                $('#msg_box').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
            }else{
                $('#process_item_form')[0].reset();
                $('#confirm_process_fees_modal').modal('hide');
                ajax_remove_loading_image($('#msg_box_modal')); 
            }
        });
        return false; 
    })
    
    //Search Form For displaying List of Students in a class room or list of class rooms in a class level
    $(document.body).on('submit', '#search_student_class_form', function(){
        ajax_loading_image($('#msg_box2'), ' Loading Contents');
        var billFeesFormData = $('#search_student_class_form').serialize();
        $.post(domain_name+'/exams/search_student_classlevel', billFeesFormData, function(data){
            try{
                var obj = $.parseJSON(data);
                var cls = $('#class_examTAScores_id').children('option:selected').text();
                var cls_lvl = $('#classlevel_examTAScores_id').children('option:selected').text();
                var term = $('#academic_term_examTAScores_id').children('option:selected').text();
                var term_id = $('#academic_term_examTAScores_id').val();
                var output = '<caption><strong>Results For Students in <u>'+cls+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                <thead><tr>\
                                    <th>#</th>\
                                    <th>ID Code</th>\
                                    <th>Student Name</th>\
                                    <th>Bill Student</th>\
                                    <th>View Stauts</th>\
                                </tr></thead>';
                var output2 = '<caption><strong>Results For Class rooms in <u>Classlevel '+cls_lvl+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                <thead><tr>\
                                    <th>#</th>\
                                    <th>Class Name</th>\
                                    <th>Class Capacity</th>\
                                    <th>Bill Class</th>\
                                    <th>View Status</th>\
                                </tr></thead>';
                if(obj.Flag === 1){
                    output += '<tbody>';
                    $.each(obj.SearchExamTAScores, function(key, value) {
                        output += '<tr>\
                            <td>'+(key + 1)+'</td>\n\
                            <td>'+value.student_no+'</td>\
                            <td>'+value.student_name+'</td>\n\
                            <td>\
                                <button value="'+value.student_id+','+term_id+'" class="btn btn-danger btn-xs bill_student_btn">\n\
                                <i class="fa fa-money"></i> Bill Student</button>\
                            </td>\n\
                            <td>\n\
                                <a target="__blank" href="'+domain_name+'/items/view_stdfees/'+value.std_term_id+'" class="btn btn-info btn-xs">\n\
                                <i class="fa fa-eye-slash"></i> View Status</a>\
                            </td>\
                        </tr>';
                    });
                    output += '</tbody>';
                    $('#bill_student_table_div').html(output);
                }else if(obj.Flag === 2){
                    output2 += '<tbody>';
                    $.each(obj.SearchExamTAScores, function(key, value) {
                        output2 += '<tr>\
                            <td>'+(key + 1)+'</td>\n\
                            <td>'+value.class_name+'</td>\
                            <td>'+value.class_size+'</td>\
                            <td>\
                                <button value="'+value.class_id+','+term_id+'" class="btn btn-danger btn-xs bill_class_btn">\n\
                                <i class="fa fa-money"></i> Bill Class</button>\
                            </td>\n\
                            <td>\n\
                                <a target="__blank" href="'+domain_name+'/items/view_clsfees/'+value.cls_term_id+'" class="btn btn-warning btn-xs">\n\
                                <i class="fa fa-eye-slash"></i> View Status</a>\
                            </td>\
                        </tr>';
                    });
                    output2 += '</tbody>';
                    $('#bill_student_table_div').html(output2);
                }else if(obj.Flag === 0){
                    $('#bill_student_table_div').html('<tr><th colspan="5">No Record Found</th></tr>');
                }
            } catch (exception) {
                $('#bill_student_table_div').html(data);
            }
            ajax_remove_loading_image($('#msg_box2'));
            //Scroll To Div
            scroll2Div($('#bill_student_table_div'));
        });
        return false;
    });
    
    //Triggers the modal for billing student
    $(document.body).on('click', '.bill_student_btn', function(){
        var ids = $(this).val().split(',');
        $('#confirm_bill_student_form')[0].reset();
        $('#studentIV_id').val(ids[0]);
        $('#academic_termIV_id').val(ids[1]);
        $('#confirm_bill_student_modal').modal('show');
    });
    
    //Triggers the modal for billing student
    $(document.body).on('click', '.bill_class_btn', function(){
        var ids = $(this).val().split(',');
        $('#confirm_bill_student_form')[0].reset();
        $('#classIV_id').val(ids[0]);
        $('#academic_termIV_id').val(ids[1]);
        $('#confirm_bill_student_modal').modal('show');
    });
    
    //When the confirm modal form is submitted
    $(document.body).on('submit', '#confirm_bill_student_form', function(){
        ajax_loading_image($('#msg_box2_modal'), ' Billing Students');
        var billData = $('#confirm_bill_student_form').serialize();
        $.post(domain_name+'/items/bill_students', billData, function(data){
            if(data === '0'){
                $('#msg_box2_modal').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
                $('#msg_box').html('<i class="fa fa-warning fa-1x"></i> Error... Please Try Again '+data);
            }else{
                $('#confirm_bill_student_form')[0].reset();
                $('#confirm_bill_student_modal').modal('hide');
                ajax_remove_loading_image($('#msg_box2_modal')); 
            }
        });
        return false; 
    });
    
    //Inline edit of the Payment status //on Click of the button enable it the select drop down
    $(document.body).on('click', '.order_status_edit', function(){
        old_btn = $(this).clone();
        var order_id = $(this).val();
        var td = $(this).parent();
        var status_id = $(this).attr('title');
        var options;
        if(status_id === '1')
            options = '<option selected value="1">Paid</option><option value="2">NotPaid</option>';
        else if(status_id === '2')
            options = '<option value="1">Paid</option><option selected value="2">Not Paid</option>';
        td.html('<select title="'+order_id+'" class="form-control order_status_id input-sm">'+options+'</select>');
        td.children('select').focus(); 
    });
    
    //When No Changes is made to the status //On Blur 
    $(document.body).on('blur', '.order_status_id', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
    //On Change of the status //Update the the record with the selected value
    $(document.body).on('change', '.order_status_id', function(){
        var td = $(this).parent();
        var select = $(this).val();
        var order_id = $(this).attr('title');
        td_loading_image(td);
        $.post(domain_name+'/items/statusUpdate', {order_id:order_id, status_id:select}, function(data){
            if(select === '1'){
                td.html('<button title="'+select+'" value="'+order_id+'" class="btn btn-success btn-xs order_status_edit">\n\
                    <i class="fa fa-check-square-o fa-1x"><span class="label label-success"> Paid</span></button>');
            }else{
                td.html('<button title="'+select+'" value="'+order_id+'" class="btn btn-danger btn-xs order_status_edit">\n\
                    <i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> Not Paid</span></button>');
            }
        });
    });
    
});