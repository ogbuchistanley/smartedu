$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    var domian_url = domain_name+'/employees/';
    var old_btn;
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Dependent ListBox
    var url = "\/local_govts\/ajax_get_local_govt\/Employee\/%23state_id";
    getDependentListBox($("#state_id"), $("#local_govt_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    //Set Nigeria as the defualt country
    $("#country_id").val("140");
    $(document.body).on('change', '#country_id', function(){
        var val = $(this).val();
        if(val === '140'){
            $('#state_lga_div').removeClass('hide');
        }else{ 
            $('#state_id').val('');            
            $('#state_lga_div').addClass('hide');
            $('#local_govt_id').html('<option value="">  (Select Employee\'s L.G.A)  </option>');
        }
    });
    if($("#country_id").val() === '140'){
        $('#state_lga_div').removeClass('hide')
    }
    if($("#marital_status").val() === 'Married'){
        $('#marital_status_div').removeClass('hide')
    }
    
    //Change of Marital Status
    $(document.body).on('change', '#marital_status', function(){
        if($(this).val() === 'Married'){
            $('#marital_status_div').removeClass('hide');
        }else{ 
            $('#marital_status_div').addClass('hide');
            $('#spouse_name').val('');            
            $('#spouse_employer').val('');            
            $('#spouse_phone_no').val('');            
        }
    });
    
    //qualification Section
    //Add a new row for inputting new qualification
    $(document.body).on('click', '.add_new_row_btn', function(){
        var new_tr = $('#qualification_table tbody').children(':last-child').clone();
        $('#qualification_table tbody').append(new_tr);
        new_tr.children(':nth-child(1)').html( parseInt(new_tr.children(':nth-child(1)').html()) + 1 );
        new_tr.children(':nth-child(2)').children('textarea').val('');
        new_tr.children(':nth-child(2)').children('input').val('');
        new_tr.children(':nth-child(3)').children('input').val('');
        new_tr.children(':nth-child(4)').children('input').val('');
        new_tr.children(':nth-child(5)').children('textarea').val('');
        new_tr.children(':nth-child(6)').children('input').val('');
        new_tr.children(':last-child').html('<td><button type="button" class="btn btn-xs btn-danger remove_tr_btn">Remove</button></td>');
        //Assign Date Pickers
        new_tr.children(':nth-child(3)').children('input').datepicker();
        new_tr.children(':nth-child(4)').children('input').datepicker();
        new_tr.children(':nth-child(6)').children('input').datepicker();
    });
    
    //Remove the row added
    $(document.body).on('click', '.remove_tr_btn', function(){
       var parentTR = $(this).parent().parent().parent();
       parentTR.remove();
    });
    
    //on click of the delete button
    $(document.body).on('click', '.delete_employee', function(){
        //alert($(this).val());
        $('#hidden_employee_id').val($(this).val());
    });
    
   // Deleting the employee record via modal
   $(document.body).on('submit', '#employee_delete_form', function(){
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/employees/delete/' + $('#hidden_employee_id').val(), 
            success: function(data,textStatus,xhr){
                $('#employee_delete_modal').modal('hide');
                window.location.replace(domian_url);
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + xhr); 
            } 
        });	 
        return false; 
    });
    
    
    // Date of birth DataPicker
    $('#birth_date').datepicker({
        changeMonth: true,
        changeYear: true,
        yearRange: "-80:-10"
    });
    //I.D Expiry Date
    $('#identity_expiry_date').datepicker({
        changeMonth: true,
        changeYear: true,
        yearRange: "-15:+10"
    });
    //Date Qualification
    $('.date_picker').datepicker({
        changeMonth: true,
        changeYear: true,
        yearRange: "-40:+10"
    });
    
    //On Click of the register button
    $(document.body).on('submit', '#employee_form', function(){
        //Hide The Finish Button When its Clicked once to avoid duplicates record submission
//        if($('#salutation_id').val() !== '' && $('#first_name').val() !== '' && $('#other_name').val() !== '' 
//            && $('#email').val() !== '' && $('#mobile_number1').val() !== '' && $('#contact_address').val() !== ''
//            && $('#country_id').val() !== '' && $('#gender').val() !== '' && $('#birth_date').val() !== '') {
//            //Hide The Submit Button
//            //$('#register_emp_btn').addClass('hide');
//        }
        $("[type='submit']").addClass('hide');
        return true;
    });
    
    
    //Inline edit of the Employee status //on Click of the button enable it the select drop down
    $(document.body).on('click', '.employee_status_edit', function(){
        old_btn = $(this).clone();
        var employee_id = $(this).val();
        var td = $(this).parent();
        var status_id = $(this).attr('title');
        var options;
        if(status_id === '1')
            options = '<option selected value="1">Active</option><option value="2">Inactive</option>';
        else if(status_id === '2')
            options = '<option value="1">Active</option><option selected value="2">Inactive</option>';
        td.html('<select title="'+employee_id+'" class="form-control employee_status_id input-sm">'+options+'</select>');
        td.children('select').focus();        
    });
    
    //When No Changes is made to the status //On Blur 
    $(document.body).on('blur', '.employee_status_id', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
    //On Change of the status //Update the the record with the selected value
    $(document.body).on('change', '.employee_status_id', function(){
        var td = $(this).parent();
        var select = $(this).val();
        var employee_id = $(this).attr('title');
        td_loading_image(td);
        $.post(domain_name+'/employees/statusUpdate', {employee_id:employee_id, status_id:select}, function(data){
            if(select === '1'){
                td.html('<button title="'+select+'" value="'+employee_id+'" class="btn btn-success btn-xs employee_status_edit">\n\
                    <i class="fa fa-check-square-o fa-1x"><span class="label label-success"> Active</span></button>');
            }else{
                td.html('<button title="'+select+'" value="'+employee_id+'" class="btn btn-danger btn-xs employee_status_edit">\n\
                    <i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> Inactive</span></button>');
            }
        });
    });
    
    
    
    
    /////// Validations  : begin/////////////////////////////////////
    // Ajax Auto Validation : Salutation
    autoValidateDropDown($('#salutation_id'), domian_url+'validate_form');
    // Ajax Auto Validation : First Name
    autoValidateField($('#first_name'), domian_url+'validate_form');
    // Ajax Auto Validation : Other Names
    autoValidateField($('#other_name'), domian_url+'validate_form');
    // Ajax Auto Validation : Email
    autoValidateField($('#email'), domian_url+'validate_form');
    // Ajax Auto Validation : Mobile Number One
    autoValidateField($('#mobile_number1'), domian_url+'validate_form');
    // Ajax Auto Validation : Contact Address
    autoValidateField($('#contact_address'), domian_url+'validate_form');
    // Ajax Auto Validation : Nationality
    autoValidateDropDown($('#country_id'), domian_url+'validate_form');
    // Ajax Auto Validation : Gender
    autoValidateDropDown($('#gender'), domian_url+'validate_form');
    // Ajax Auto Validation : Birth Date
    autoValidateField($('#birth_date'), domian_url+'validate_form');
    // Ajax Auto Validation : Marital Status
    autoValidateDropDown($('#marital_status'), domian_url+'validate_form');
    // Ajax Auto Validation : Sponsorship Type
    //autoValidateDropDown($('#employee_type_id'), domian_url+'validate_form');
    // Ajax Auto Validation : Next of Kin Name
    autoValidateField($('#next_ofkin_name'), domian_url+'validate_form');
    // Ajax Auto Validation : Next of Kin Number
    autoValidateField($('#next_ofkin_number'), domian_url+'validate_form');
    // Ajax Auto Validation : Next of Kin Relationship
    autoValidateField($('#next_ofkin_relate'), domian_url+'validate_form');
    // Ajax Auto Validation : Passport
    validateImageFile($("#image_url"));
    /////// Validations  : ends/////////////////////////////////////      
});