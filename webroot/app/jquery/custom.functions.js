    
domain_name = '/smartedu';

$('document').ready(function(){
    //Students
    submenuCount($('#student_count'));
    //Sponsors
    submenuCount($('#sponsor_count'));
    //Employees
    submenuCount($('#employee_count'));
    //Subjects
    submenuCount($('#subject_count'));
    //Attendance
    submenuCount($('#attend_count'));
    //Class Rooms
    submenuCount($('#class_count'));
    //Exams
    submenuCount($('#exams_count'));
    //Fees
    submenuCount($('#fees_count'));
    //Master Records
    submenuCount($('#record_count'));
    //Message Records
    submenuCount($('#message_count'));

});


//Display the number of sub-menu count in a menu item
function submenuCount(span){
    var ul = span.parent().parent().next();
    //alert(ul.html() + ' ' + ul.children().length);
    span.html(ul.children().length);
}

//time function
function showTime() {
    var today = new Date();
    var hours = today.getHours();
    var min = today.getMinutes();
    var sec = today.getSeconds();
    var time ="";
	
    //time definition
    if(hours == 0) {
        time = "12";
    }
    
    if(hours < 10) {
        time += "0" + hours;
    }else if(hours <= 12) {
        time += hours;
    }
    
    if(hours > 12) {
        time += hours - 12;
    }
    
    if(min < 10) {
        time += ":0" + min;
    }else {	
        time += ":" + min;
    }
    
    if(sec < 10) {
        time += ":0" + sec;
    } else {
        time += ":" + sec;
    }
    
    if(hours >= 12) {
        time += " PM";
    } else{	
        time +=" AM";
    }
    $("#timer").html(time);
    setTimeout("showTime()", 1000)
}

function readURL(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function (e) 
            {
              $('#img_prev')
              .attr('src', e.target.result)
              .width(150)
              .height(150);
            };
        reader.readAsDataURL(input.files[0]);
    }
}

//Scrolling To a div
function scroll2Div(div){
    $('html, body').animate({
        scrollTop: div.offset().top
      }, 2000);
}

//Dependent List Box
function getDependentListBox(parent, child, url){
    parent.bind("change", function (event) {
        $.ajax({
            type:"post", 
            async:true, 
            data:parent.serialize(), 
            url:domain_name+url,
            dataType:"html", 
            success:function (data, textStatus) {
                child.html(data);
            }
        });
        return false;
    });
}

// set a loading image
function ajax_loading_image(div, text) {
    div.html('<div class="alert alert-info"><h4><i class="fa fa-refresh fa-1x"></i> '+text+'... <img src="'+domain_name+'/img/ajax-loader.gif" alt="Loading Image"/></h4></div>');
}

// set a loading image
function td_loading_image(div) {
    div.html('<img src="'+domain_name+'/img/ajax-loader2.gif" style="width:30px; height:30px"/>');
}

//Set Warning 3, Error 2, Info 0 or success 1 messages
function set_msg_box(div, text, type) {
    if(type === 1)
        div.html('<div class="alert alert-success"><h4><i class="fa fa-thumbs-up fa-1x"></i> '+text+'</h4></div>');
    else if(type === 2)
        div.html('<div class="alert alert-danger"><h4><i class="fa fa-thumbs-down fa-1x"></i> '+text+'</h4></div>');
    else if(type === 3)
        div.html('<div class="alert alert-warning"><h4><i class="fa fa-warning fa-1x"></i> '+text+'</h4></div>');
    else
        div.html('<div class="alert alert-info"><h4><i class="fa fa-info fa-1x"></i> '+text+'</h4></div>');
}

//Append Div Below the element with an error message
function set_error_div(id, msg){
    if($('#'+id+'errorDiv').text() === ''){
        $('#'+id).after('<div id="'+id+'errorDiv" class="alert alert-danger" style="margin:0; padding:0;">' + msg + '</div>')
    }
}

// remove loading image
function ajax_remove_loading_image(div) {
   div.html('');
}

//Activing Tab And Links With the class set to active
function setTabActive(link, type){
    $('#nav_menu li.active, #nav_menu li ul li.active').each(function(){
        $(this).removeClass('active');
    });
    var submenu = $(link).parent();
    var mainmenu = $(link).parent().parent().parent();
    if(type === 1)
        submenu.addClass('active');
    mainmenu.addClass('active');
}
// Auto Complete Function
function autoCompleteField(name, id, source){
    name.autocomplete({
        source: source,
        minLength: 0
    });
    name.autocomplete({
        select: function(event, ui) {
            selected_id = ui.item.id;
            id.val(selected_id);
            //alert(selected_id);
        }
    });
    name.autocomplete({
        open: function(event, ui) {
            id.val(-1);
        }
    });
}

//jQuery Validation
function validateFields(id, msg, type) {
    id.bind(type, function(){
        if($(this).val().length > 0){
            $('#'+$(this).attr('id')+'errorDiv').remove();
            id.parent().parent('div').removeClass('has-error');
            id.parent().parent('div').addClass('has-success');
            id.pulsate();
        }else{
            if($('#'+$(this).attr('id')+'errorDiv').length === 0){
                id.after('<div id="'+$(this).attr('id')+'errorDiv" class="alert alert-danger" style="margin:0; padding:0;">' + msg + '</div>')
                id.parent().parent('div').removeClass('has-success');
                id.parent().parent('div').addClass('has-error')
                id.pulsate({ color : '#B94A48' });
            }
        }
    });
}

//Image file type and file size vaildation
function validateImageFile(id){
    id.bind('change', function(){			    
        var size = this.files[0].size;
        var value = $(this).val().toLowerCase();
        var extension = value.substring(value.lastIndexOf('.'));
        if($.inArray(extension, ['.gif', '.png', '.jpg', '.jpeg']) === -1){
            $('#image_error').html('<div class="alert alert-danger" style="margin:0; padding:0;">\n\
            Invalid File Type. Require Only Image Files With Extensions Of .gif, .png, .jpg, .jpeg</div>')
        } else if(size >= 1048576){
            $('#image_error').html('<div class="alert alert-danger" style="margin:0; padding:0;">\n\
            File Size To Large. Requires Only Files Less Than '+(1048576/1024)+' KB</div>')
        }else{
            $('#image_error').html('');
        }
    });
}

// jQuery Validation : Drop Downs
function validateDropDown(id, msg) {
    validateFields(id, msg, 'change');
}

// jQuery Validation : Fields
function validateField(id, msg) {
    validateFields(id, msg, 'blur');
}

// Ajax Auto Validations
function autoValidate(id, source, type) {
    id.bind(type, function(){
        $.post(
            source,
            { field: id.attr('id'), value: id.val()},
            function(error){
                if(error.length > 0){
                    if($('#'+id.attr('id')+'errorDiv').length === 0){
                        id.after('<div id="'+id.attr('id')+'errorDiv" class="alert alert-danger" style="margin:0; padding:0;">' + error + '</div>')
                        id.parent().parent('div').removeClass('has-success');
                        id.parent().parent('div').addClass('has-error')
                        id.pulsate({ color : '#B94A48' });
                    }
                }else{
                    $('#'+id.attr('id')+'errorDiv').remove();
                    id.parent().parent('div').removeClass('has-error');
                    id.parent().parent('div').addClass('has-success')
                    id.pulsate();
                }
            }
        );
    });
}

// Ajax Auto Validation : Drop Downs
function autoValidateDropDown(id, source) {
    autoValidate(id, source, 'change');
}

// Ajax Auto Validation : Fields
function autoValidateField(id, source) {
    autoValidate(id, source, 'blur');
}

//Confirm that the password did match
function confirmPassword(div, new_pass, new_pass2, btn){
    $(document.body).on('keyup', new_pass, function(){
        if($(new_pass).val() !== $(new_pass2).val()){
            set_msg_box(div, ' Your <i>New and Confirm Passwords</i> did not match', 2);
            btn.attr("disabled", "disabled");
        }else {
            set_msg_box(div, ' Make sure that your <i>New and Confirm Password</i> did match.', 0);				
            btn.removeAttr("disabled");
        }
        return false;
    });
}


////////////////////////////////////  Side By Side  Begins ///////////////////////////
//Moves Each option from left to right or from right to left
function moveSelection(SpanAva, AvailableLB, SpanLin, LinkedLB)	 {
    for (i=0; i<AvailableLB.children().length; i++) {
        if (AvailableLB.children().eq(i).prop("selected") === true) {
            LinkedLB.append(new Option(AvailableLB.children().eq(i).text(), AvailableLB.children().eq(i).val()));
            AvailableLB.children().eq(i).remove();
        }
    }
    validateSize(SpanAva, AvailableLB, SpanLin, LinkedLB);
 }
 //Moves all the options from left to right or from right to left
 function moveAll(SpanAva, AvailableLB, SpanLin, LinkedLB) {
    var aval = AvailableLB.clone();
    LinkedLB.append(aval.html());
    AvailableLB.empty();
    validateSize(SpanAva, AvailableLB, SpanLin, LinkedLB);
 }
 //Count the total number of options in both the left and right multiple select
 function validateSize(objAva, AvailableLB, objLin, LinkedLB) {
    objAva.html(AvailableLB.children().length);
    objLin.html(LinkedLB.children().length);		
 }
 //Get all the id's in the right select list and set it in a hidden field
function getNewValues(LinkedLB, HiddenField) {
    HiddenField.val("");		 
    for (i=0; i<LinkedLB.children().length; i++) {
        if (HiddenField.val() !== "" ) {
            HiddenField.val(HiddenField.val()+",");
        }
        HiddenField.val(HiddenField.val()+LinkedLB.children().eq(i).val())
    }
}
////////////////////////////////////  Side By Side Ends ///////////////////////////
