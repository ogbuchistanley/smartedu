$('document').ready(function(){
    
    var domian_url = domain_name+'/messages/';
    
    $('[href="'+domain_name+'/messages/index#sponsors"]').attr('data-toggle', 'tab');
    $('[href="'+domain_name+'/messages/index#employees"]').attr('data-toggle', 'tab');
     
    $('[href="'+domain_name+'/messages/index#sponsors"]').click(function(){
        $('#myTab a[href="'+domain_name+'/messages/index#sponsors"]').tab('show');
        setTabActive('[href="'+domain_name+'/messages/index#sponsors"]', 1);
    });
    
    $('[href="'+domain_name+'/messages/index#employees"]').click(function(){
        $('#myTab a[href="'+domain_name+'/messages/index#employees"]').tab('show');
        setTabActive('[href="'+domain_name+'/messages/index#employees"]', 1);
    });
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    var url = "\/classrooms\/ajax_get_classes\/SearchForm\/%23classlevel_id";
    getDependentListBox($("#classlevel_id"), $("#class_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Mark All Function
    function mark_all(btn, checkbox){
        $(document.body).on('click', btn, function(){
            $('.err').html('');
            if($(btn + ':first').text() === 'Mark All'){
                $(btn).text('UnMark All');
                $(btn).removeClass('btn-success');
                $(btn).addClass('btn-danger');
                $(checkbox).prop("checked", true);
            }else if($(this).text() === 'UnMark All'){
                $(btn).text('Mark All');
                $(btn).removeClass('btn-danger');
                $(btn).addClass('btn-success');
                $(checkbox).prop("checked", false);
            }
        });
    }
    
    //Function To Redirect To Send Message Page
    function redirectToSend(btn, checkbox){
        $(document.body).on('click', btn, function(){
            var ids = '';
            $(checkbox).each(function(index, element) {
                if($(element).prop("checked") === true) {
                    ids = ids + $(element).val() + ',';
                }
            });
            if(ids === ''){
                $('.err').html('You Must Check at least One Receipient');
            }else{
                ids = ids.substring(0, ids.length - 1);
                $('.err').html('');
                $.post(domain_name+'/messages/encrypt/' + ids + '/' + $(btn + ':first').val(), function(data){            
                    try{
                        //Type emp = employees while spn = sponsors
                        window.location.replace(domain_name+'/messages/send/'+data);
                    } catch (exception) {
                        $('.err').html(data);
                    }
                });
            }
        });
    }
    
    
    ///////////////////////////////////    Employee Message   //////////////////////////////////////////////////////////////////
    
    //Mark or UnMark All Employees
    mark_all('.mark_btn_emp', '.message_check_emp');
    
    //Encrypt The Marked ID's and Process to Send Page For The Marked Employees
    redirectToSend('.msg_all_mark_emp', '.message_check_emp');
    
    
    ///////////////////////////////////    Recipient Message   //////////////////////////////////////////////////////////////////
    
    //Mark or UnMark All Recipients
    mark_all('.mark_btn_rcp', '.message_check_rcp');
    
    //Encrypt The Marked ID's and Process to Send Page For The Marked Recipients
    redirectToSend('.msg_all_mark_rcp', '.message_check_rcp');
    
    
    ///////////////////////////////////    Sponsor Message   //////////////////////////////////////////////////////////////////
    
    //Mark or UnMark All Sponsors
    mark_all('.mark_btn_spn', '.message_check_spn');
    
    //Encrypt The Marked ID's and Process to Send Page For The Marked Employees
    redirectToSend('.msg_all_mark_spn', '.message_check_spn');
    
    //Search Form For displaying List of Students in a class room or list of class rooms in a class level
    $(document.body).on('submit', '#search_sponsor_form', function(){
        ajax_loading_image($('#msg_box'), ' Loading Contents');
        var values = $('#search_sponsor_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/messages/search_student_classlevel',
            data: values,
            success: function(data){
                try{
                    var obj = $.parseJSON(data);
                    var div = '<div class="form-group">\
                            <div class="col-sm-offset-2 col-sm-8"><br><br><br>\
                                <button type="button" class="mark_btn_spn btn btn-success">Mark All</button>\
                                <button type="button" class="msg_all_mark_spn btn btn-primary" value="spn">Message Marked Sponsors</button>\
                                <span style="font-size: medium" class="label label-danger err"></span>\
                            </div>\
                        </div>';
                    var div2 = '<div class="form-group">\
                            <div class="col-sm-offset-2 col-sm-8"><br><br><br>\
                                <button type="button" class="mark_btn_spn btn btn-success">Mark All</button>\
                                <button type="button" class="msg_all_mark_spn btn btn-primary" value="spn_class">Message Marked Classes</button>\
                                <span style="font-size: medium" class="label label-danger err"></span>\
                            </div>\
                        </div>';
                    var cls = $('#class_id').children('option:selected').text();
                    var cls_lvl = $('#classlevel_id').children('option:selected').text();
                    var year = $('#academic_year_id').children('option:selected').text();
                    var output = '<caption><strong>Results For Students in <u>'+cls+' ::: <u>'+year+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Student No.</th>\
                                        <th>Student Name</th>\
                                        <th>Sponsor Name</th>\
                                        <th>Send</th>\
                                        <th>Mark</th>\
                                    </tr></thead>';
                    var output2 = '<caption><strong>Results For Class rooms in <u>Classlevel '+cls_lvl+' ::: <u>'+year+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Name</th>\
                                        <th>No. of Students</th>\
                                        <th>Send</th>\
                                        <th>Mark</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SearchResult, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_no+'</td>\
                                <td>'+value.student_name+'</td>\n\
                                <td>'+value.sponsor_name+'</td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/messages/send/'+value.spn_typ_id+'" class="btn btn-warning btn-xs"><i class="fa fa-envelope"></i> Send</a>\
                                </td>\
                                <td><input type="checkbox" value="'+value.sponsor_id+'" class="message_check_spn"></td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#search_sponsors_table').html(output);
                        $('#search_sponsors_table').next().html(div);
                    }else if(obj.Flag === 2){
                        output2 += '<tbody>';
                        $.each(obj.SearchResult, function(key, value) {
                            output2 += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\
                                <td>'+value.student_count+'</td>\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/messages/send/'+value.cls_typ_id+'" class="btn btn-warning btn-xs"><i class="fa fa-envelope"></i> Send</a>\
                                </td>\
                                <td><input type="checkbox" value="'+value.class_id+'" class="message_check_spn"></td>\
                            </tr>';
                        });
                        output2 += '</tbody>';
                        $('#search_sponsors_table').html(output2);
                        $('#search_sponsors_table').next().html(div2);
                    }else if(obj.Flag === 0){
                        $('#search_sponsors_table').html('<tr><th>No Record Found</th></tr>');
                    }
                } catch (exception) {
                    $('#search_sponsors_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box'));
                //Scroll To Div
                scroll2Div($('#search_sponsors_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#search_sponsors_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box'));
            } 
        });
        return false;
    });
    
    //on click of the delete button
    $(document.body).on('click', '.delete_recipient', function(){
        $('#hidden_recipient_id').val($(this).val());
    });
    
    // Deleting the sponsor record via modal
   $(document.body).on('submit', '#recipient_delete_form', function(){
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/messages/delete_recipient/' + $('#hidden_recipient_id').val(), 
            success: function(data,textStatus,xhr){
                $('#recipient_delete_modal').modal('hide');
                window.location.replace(domian_url + 'recipient');
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + xhr); 
            } 
        });	 
        return false; 
    });
    
    //on click of the send button recipient
    $(document.body).on('click', '.send_message_recipient', function(){
        $('#hidden_id').val($(this).val());
    });
    
   // Sending Message To Recipients via modal
   $(document.body).on('submit', '#recipient_message_form', function(){
       var values = $('#recipient_message_form').serialize();
       ajax_loading_image($('#msg_box'), ' Sending Message');
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/messages/sendOne', 
            data: values,
            success: function(data,textStatus,xhr){
                $('#recipient_message_modal').modal('hide');
                ajax_remove_loading_image($('#msg_box'));
                window.location.replace(domian_url + 'recipient');
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + xhr); 
            } 
        });	 
        return false; 
    });
    
    
    //on click of the send button employee
    $(document.body).on('click', '.send_message_employee', function(){
        $('#hidden_id').val($(this).val());
        $('#type').val('emp');
    });
    
    // Sending Message To Employee or Sponsor via modal
   $(document.body).on('submit', '#message_form', function(){
       var values = $('#message_form').serialize();
       ajax_loading_image($('#msg_box4'), ' Sending Message');
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/messages/sendOne', 
            data: values,
            success: function(data,textStatus,xhr){
                $('#message_modal').modal('hide');
                ajax_remove_loading_image($('#msg_box4'));
                window.location.replace(domian_url + 'index');
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + xhr); 
            } 
        });	 
        return false; 
    });
    
    
    // jQuery Validation : Message Body
    validateField($('#message'), 'Message Body is required');
    // jQuery Validation : Message Body
    validateField($('#message'), 'Message Body is required');
    // jQuery Validation : Message Body
    validateField($('#mobile_number'), 'Recipient Mobile Number is required');
    // jQuery Validation : Message Subject
    validateField($('#recipient_name'), 'Recipient Name Subject is required');
    
    
    //Textarea Counter
    var options1 = {  
        'maxCharacterSize': 320,  
        'originalStyle': 'originalDisplayInfo',  
        'warningStyle': 'warningDisplayInfo',  
        'warningNumber': 40,  
        'displayFormat': '#input Characters | #left Characters Left | #words Words'  
        };  
    $('#message').textareaCount(options1);  
    
});