$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    var domian_url = domain_name+'/sponsors/';
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    var url = "\/local_govts\/ajax_get_local_govt\/Sponsor\/%23state_id";
    getDependentListBox($("#state_id"), $("#local_govt_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    //Set Nigeria as the defualt country
    $('#country_id').val('140');
    $('#country_id').bind('change', function(){
        var val = $(this).val();
        if(val === '140'){
            $('#state_lga_div').removeClass('hide');
        }else{ 
            $('#state_id').val('');            
            $('#state_lga_div').addClass('hide');
            $('#local_govt_id').html('<option value="">  (Select Sponsor\'s L.G.A)  </option>');
        }
    });
    
    //On Click of the register button
    $(document.body).on('submit', '#sponsor_form', function(){
        if($('#country_id').val() === '140' && $('#local_govt_id').val() === ''){
            $('#local_govt_id').focus();
            return false;
        }
        if($('#salutation_id').val() !== '' && $('#first_name').val() !== '' && $('#mobile_number1').val() !== '' 
            && $('#contact_address').val() !== '' && $('#country_id').val() !== '' && $('#occupation').val() !== '') {
            //Hide The Submit Button
            $('#register_sponsor_btn').addClass('hide');
        }
        $("[type='submit']").addClass('hide');
        return true;
    });
    
    //on click of the delete button
    $(document.body).on('click', '.delete_sponsor', function(){
        $('#hidden_sponsor_id').val($(this).val());
    });
    
   // Deleting the sponsor record via modal
   $(document.body).on('submit', '#sponsor_delete_form', function(){
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/sponsors/delete/' + $('#hidden_sponsor_id').val(), 
            success: function(data,textStatus,xhr){
                $('#sponsor_delete_modal').modal('hide');
                window.location.replace(domian_url);
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + xhr); 
            } 
        });	 
        return false; 
    });
    
    
    /////// Validations  : begin/////////////////////////////////////
    // Ajax Auto Validation : Salutation
    autoValidateDropDown($('#salutation_id'), domian_url+'validate_form');
    // Ajax Auto Validation : First Name
    autoValidateField($('#first_name'), domian_url+'validate_form');
    // Ajax Auto Validation : Other Names
    autoValidateField($('#other_name'), domian_url+'validate_form');
    // Ajax Auto Validation : Email
    //autoValidateField($('#email'), domian_url+'validate_form');
    // Ajax Auto Validation : Mobile Number One
    autoValidateField($('#mobile_number1'), domian_url+'validate_form');
    // Ajax Auto Validation : Contact Address
    autoValidateField($('#contact_address'), domian_url+'validate_form');
    // Ajax Auto Validation : Nationality
    autoValidateDropDown($('#country_id'), domian_url+'validate_form');
    // Ajax Auto Validation : Occupation
    autoValidateField($('#occupation'), domian_url+'validate_form');
    // Ajax Auto Validation : Passport
    validateImageFile($("#image_url"));
    /////// Validations  : ends/////////////////////////////////////      
});