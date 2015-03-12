$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    var old_btn;

    //When a key is typed check if the new password and confirm new password field matches
    confirmPassword($('#msg_box3'), '#new_pass2', '#new_pass', $('#pass_change_btn'));
    
    //On blur of the old password //check if the existing password did match with the type password
//    $(document.body).on('blur', '#old_pass', function(){
//        var val = $(this).val();
//        $.post(domain_name+'/users/change', {old_pass:val}, function(data){
//            if(data === '0'){
//                set_msg_box($('#msg_box3'), ' Your Existing Password did not match', 2);
//                $('#pass_change_btn').attr("disabled", "disabled");
//            }else{
//                set_msg_box($('#msg_box3'), ' Make sure that your <i>New and Confirm Password</i> did match.', 0);				
//                $('#pass_change_btn').removeAttr("disabled");
//            }
//        });
//        return false;
//    });
    
    //On submit of the password change form //try updating the password
    $(document.body).on('submit', '#change_pass_form', function(){
//        var group_alias = $('#group_alias').val();
        ajax_loading_image($('#msg_box3'), ' Processing...');
        $.post(domain_name+'/users/change', $('#change_pass_form').serialize(), function(data){
            if(data == 1){
                set_msg_box($('#msg_box3'), ' Your Password was Successfully Updated', 1);
                $('#change_pass_form')[0].reset();
            }else if(data == 0){
                set_msg_box($('#msg_box3'), ' Error Updating Your Password... Try Again', 2);
            }else if(data == -1){
                $('#new_pass2').focus();
                set_msg_box($('#msg_box3'), ' Your <i>New and Confirm Passwords</i> did not match', 2);
            }else if(data == -2){
                $('#old_pass').focus();
                set_msg_box($('#msg_box3'), ' Your <i>Old (Existing) Password</i> did not match', 2);
            }  
        });
        return false;
    });
    
    
    //Inline edit of the user status //on Click of the button enable it the select drop down
    $(document.body).on('click', '.user_status_edit', function(){
        old_btn = $(this).clone();
        var user_id = $(this).val();
        var td = $(this).parent();
        var status_id = $(this).attr('title');
        var options;
        if(status_id === '1')
            options = '<option selected value="1">Active</option><option value="2">Inactive</option>';
        else if(status_id === '2')
            options = '<option value="1">Active</option><option selected value="2">Inactive</option>';
        td.html('<select title="'+user_id+'" class="form-control user_status_id input-sm">'+options+'</select>');
        td.children('select').focus();
        
    });
    
    //When No Changes is made to the status //On Blur 
    $(document.body).on('blur', '.user_status_id', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
    
    //On Change of the status //Update the the record with the selected value
    $(document.body).on('change', '.user_status_id', function(){
        var td = $(this).parent();
        var select = $(this).val();
        var user_id = $(this).attr('title');
        //alert($(this).attr('title'));
        td_loading_image(td);
        $.post(domain_name+'/users/statusUpdate', {user_id:user_id, status_id:select}, function(data){
            if(select === '1'){
                td.html('<button title="'+select+'" value="'+user_id+'" class="btn btn-success btn-xs user_status_edit">\n\
                    <i class="fa fa-check-square-o fa-1x"><span class="label label-success">Active</span></button>');
            }else{
                td.html('<button title="'+select+'" value="'+user_id+'" class="btn btn-danger btn-xs user_status_edit">\n\
                    <i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> Inactive</span></button>');
            }
        });
    });
    

    //Forget Password
    $(document.body).on('submit', '#forget_password_form', function() {
        td_loading_image($('#msg_box'));
        $.ajax({
            type: "POST",
            url: domain_name+'/users/forget_password',
            data: $('#forget_password_form').serialize(),
            success: function(data){
                $('#msg_box').html(data);
                window.location.replace(domain_name+'/users/login');
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#msg_box').html(errorThrown);
                //ajax_remove_loading_image($('#msg_box'));
            }
        });
        return false;
    });
});