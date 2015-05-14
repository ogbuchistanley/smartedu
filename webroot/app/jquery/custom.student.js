$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    var domian_url = domain_name+'/students/';
    var old_btn;
    var students_status = $('#students_status').clone();
    $('#students_status').addClass('hide');    
    
    //Hide The Finish Button When its Clicked once to avoid duplicates record submission
//    $('.buttonFinish').bind('click', function(){
//        $(this).addClass('buttonDisabled');
//        alert($(this).text());
//    });
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/Student\/%23academic_year_id";
    getDependentListBox($("#academic_year_id"), $("#admission_term_id"), url);
    // OnChange Of States Get Local Govt
    var url3 = "\/local_govts\/ajax_get_local_govt\/Student\/%23state_id";
    getDependentListBox($("#state_id"), $("#local_govt_id"), url3);
    // OnChange Of Classlevel Get Class Room
    var url5 = "\/classrooms\/ajax_get_classes\/Student\/%23classlevel_id";
    getDependentListBox($("#classlevel_id"), $("#class_id"), url5);
    var url7 = "\/classrooms\/ajax_get_classes\/StudentNew\/%23classlevel_id_new";
    getDependentListBox($("#classlevel_id_new"), $("#class_id_new"), url7);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    //Set Nigeria as the defualt country
    $('#country_id').val('140');
    $('#country_id').bind('change', function(){
        var val = $(this).val();
        if(val === '140'){
            $('#state_lga_div').removeClass('hide');
        }else{
            $('#state_lga_div').addClass('hide');
        }
    });
    
    //On Click of the register button
    $(document.body).on('submit', '#student_form', function(){
        if($('#sponsor_name').val() == '' || $('#first_name').val() == '' || $('#relationtype_id').val() == '' || $('#surname').val() == '' || $('#gender').val() == '') {
            //Validate The Form
            $('#display_message').removeClass('hide');
            $('#display_message').addClass('alert-danger');
            $('#display_message').html('<b><i class="fa fa-thumbs-down fa-2x"></i> All Fields With * Needs To Be Filled Properly</b>');
            return false;
        }
        //Hide The Finish Button When its Clicked once to avoid duplicates record submission
        $("[type='submit']").addClass('hide');
        return true;
    });
    
    //On Click of the delete button 
    $(document.body).on('click', '.delete_student', function(){
        //alert($(this).val());
        $('#hidden_student_id').val($(this).val());
    });
    
    // Deleting the student record via modal
    $(document.body).on('submit', '#student_delete_form', function(){
        $.ajax({ 
            type: 'POST', 
            url: domain_name+'/students/delete/' + $('#hidden_student_id').val(), 
            success: function(data,textStatus,xhr){
                $('#student_delete_modal').modal('hide');
                window.location.replace(domian_url);
            }, 
            error: function(xhr,textStatus,error){ 
                alert(textStatus + ' ' + error); 
            } 
        });	 
        return false; 
    });    
   
   //Inline edit of the Student status //on Click of the button enable it the select drop down
    $(document.body).on('click', '.student_status_edit', function(){
        var students_stat = students_status.clone();
        var student_id = $(this).val();
        var td = $(this).parent();
        old_btn = $(this).clone();
        td.html(students_stat);
        students_stat.val($(this).attr('title'));
        students_stat.prop('id', '');
        students_stat.attr('title', student_id);
        students_stat.addClass('student_status_id');
        td.children('select').focus();
    });
    
    //When No Changes is made to the status //On Blur 
    $(document.body).on('blur', '.student_status_id', function(){
        var td = $(this).parent();
        td.html(old_btn);
    });
    
    //On Change of the status //Update the the Student record with the selected value
    $(document.body).on('change', '.student_status_id', function(){
        var td = $(this).parent();
        var select = $(this).val();
        var text = $(this).children('option:selected').text();
        var student_id = $(this).attr('title');
        td_loading_image(td);
        $.post(domain_name+'/students/statusUpdate', {student_id:student_id, status_id:select}, function(data){
            if(select === '1' || select === '2'){
                td.html('<button title="'+select+'" value="'+student_id+'" class="btn btn-success btn-xs student_status_edit">\n\
                    <i class="fa fa-check-square-o fa-1x"><span class="label label-success">'+text+'</span></button>');
            }else if(select === '3'){
                td.html('<button title="'+select+'" value="'+student_id+'" class="btn btn-warning btn-xs student_status_edit">\n\
                    <i class="fa fa-warning fa-1x"></i><span class="label label-warning">'+text+'</span></button>');
            }else {
                td.html('<button title="'+select+'" value="'+student_id+'" class="btn btn-danger btn-xs student_status_edit">\n\
                    <i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger">'+text+'</span></button>');
            }
        });
    });
    
    
        
    // Date of birth DataPicker
    $('#birth_date').datepicker({
        maxDate: 0,
        changeMonth: true,
        changeYear: true,
        yearRange: "-40:+0"
    });
    
    // Auto Complete of Sponsor Name
    autoCompleteField($("#sponsor_name"), $("#sponsor_id"), domain_name+"/sponsors/autoComplete");
    
    /////// Validations  : begin/////////////////////////////////////
    // Ajax Auto Validation : First Name
    autoValidateField($('#first_name'), domian_url+'validate_form');
    // jQuery Validation : Sponsor Name
    validateField($('#sponsor_name'), 'A Sponsor Name is required');
    // Ajax Auto Validation : Relationship Type
    autoValidateDropDown($('#relationtype_id'), domian_url+'validate_form');
    // Ajax Auto Validation : First Name
    autoValidateField($('#surname'), domian_url+'validate_form');
    // Ajax Auto Validation : Relationship Type
    autoValidateDropDown($('#gender'), domian_url+'validate_form');
    // Ajax Auto Validation : Date of Birth
    //autoValidateField($('#birth_date'), domian_url+'validate_form');
    // Ajax Auto Validation : Nationality
    autoValidateDropDown($('#country_id'), domian_url+'validate_form');
    // Ajax Auto Validation : Religion
    //autoValidateDropDown($('#religion'), domian_url+'validate_form');
    // Ajax Auto Validation : Passport
    validateImageFile($("#image_url"));
    /////// Validations  : ends/////////////////////////////////////      
});