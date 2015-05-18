$('document').ready(function(){
    
    
     //Set The Active Tab
     //setTabActive('[href="'+domain_name+'/records/index"]', 1);
//     $('[href="'+domain_name+'/records/index#terms"]').attr('data-toggle', 'tab');
//     $('[href="'+domain_name+'/records/index#years"]').attr('data-toggle', 'tab');
//     
//    $('[href="'+domain_name+'/records/index#terms"]').click(function(){
//        $('#myTab a[href="'+domain_name+'/records/index#terms"]').tab('show');
//        setTabActive('[href="'+domain_name+'/records/index#terms"]', 1);
//    });
//    $('[href="'+domain_name+'/records/index#years"]').click(function(){
//        $('#myTab a[href="'+domain_name+'/records/index#years"]').tab('show');
//        //setTabActive('[href="'+domain_name+'/records/index#terms"]', 1);
//    });


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/SearchWeeklyReport\/%23academic_year_search_id";
    getDependentListBox($("#academic_year_search_id"), $("#academic_term_search_id"), url);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //// Get all the id's of the records to be deleted and set it into the "deleted_term" input textbox
    function setDeleteIDs(){
        var ids = "";
        $(".delete_ids").each(function(index, element) {
            if($(element).prop('checked') === true) {
                ids = ids + $(element).val() + ",";		
            }
        });
        $("#deleted_term").val(ids.substr(0, (ids.length-1)));
    }

    //Submission Date
    $('.date_picker').datepicker({
        minDate: 0,
        changeMonth: true,
        changeYear: true,
        yearRange: "-0:+10"
    });


    
    //Add a new row for inputting new record
    $(document.body).on('click', '.add_new_record_btn', function(){
        var new_tr = $('.custom_tables tbody').children(':last-child').clone();
        $('.custom_tables tbody').append(new_tr);
        new_tr.children(':nth-child(1)').html( parseInt(new_tr.children(':nth-child(1)').html()) + 1 );
        new_tr.children(':nth-child(2)').children('input').val('');
        new_tr.children(':nth-child(2)').children('select').val('');
        new_tr.children(':nth-child(3)').children('input').val('');
        new_tr.children(':nth-child(3)').children('select').val('');
        new_tr.children(':nth-child(4)').children('input').val('');
        new_tr.children(':nth-child(4)').children('textarea').val('');
        new_tr.children(':nth-child(4)').children('select').val('');
        new_tr.children(':nth-child(5)').children('input').val('');
        new_tr.children(':nth-child(5)').children('select').val('');
        new_tr.children(':nth-child(6)').children('input').val('');
        new_tr.children(':last-child').html('<td><button type="button" class="btn btn-xs btn-danger remove_tr_btn">Remove</button></td>');
    });
    
    //Remove the row added
    $(document.body).on('click', '.remove_tr_btn', function(){
       var parentTR = $(this).parent().parent().parent();
       parentTR.remove();
    });

    //Remove the row added for weekly reports setup
    $(document.body).on('click', '.remove_report_btn', function(){
       var parentTR = $(this).parent().parent();
        //alert(parentTR.html());
       parentTR.remove();
    });
    
    ////////////////////    Academic Year   ////////////////////////////////////////////////////////////////////////////
    // Validate to make sure its only one academic year that is set to active
    $(document.body).on('click', '#save_year_btn', function(){
        setDeleteIDs();
        var count = 0;
        $(".year_status_id").each(function(index, element) {
            if($(element).val() === '1') {
                count++;
            }            
        });
        if(count !== 1){
            $(this).next().html('<h4><span class="label label-danger">Note: Only One Academic Year Status Can Be Set To Active</h4>')
            return false;
        }else{
            $(this).next().html('')
        }
    });
    
    ////////////////////    Academic Term   ////////////////////////////////////////////////////////////////////////////
    // Validate to make sure its only one academic Term that is set to active
    $(document.body).on('click', '#save_term_btn', function(){
        setDeleteIDs();
        var count = 0;
        $(".term_status_id").each(function(index, element) {
            if($(element).val() === '1') {
                count++;
            }            
        });
        if(count !== 1){
            $(this).next().html('<h4><span class="label label-danger">Note: Only One Academic Term Status Can Be Set To Active</h4>')
            return false;
        }else{
            $(this).next().html('')
        }
    });
    
    ////////////////////    Class Group   ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_classgroup_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Class Levels   ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_classlevel_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Class Room   ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_classroom_btn', function(){
        setDeleteIDs();
    });

    ////////////////////    Weekly Reports   ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_weekly_report_btn', function(){
        setDeleteIDs();
    });

    ////////////////////    Weekly Report Details  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_weekly_detail_btn', function(){
        //Validate The C.A Percentage
        var no = $(this).val().split('_');
        var cg1_percent = 0;
        var cg2_percent = 0;
        $(".ca_percent").each(function(index, element) {
            //alert(index+'--'+$(element).val());
            if(index < no[0])
                cg1_percent += parseInt($(element).val());
            if(index >= no[0] && index < (no[0] + no[1]))
                cg2_percent += parseInt($(element).val());
        });
        if(cg1_percent !== 100) {
            $(this).next().html('<h4><span class="label label-danger">The Sum Total of the percentages For The <strong style="text-decoration: underline">First Class Group is '+cg1_percent+'%.</strong> It Must Sum Up To 100%</span></h4>')
            return false;
        }else if(cg2_percent !== 100) {
            $(this).next().html('<h4><span class="label label-danger">The Sum Total of the percentages For The <strong style="text-decoration: underline">Second Class Group is '+cg2_percent+'%.</strong> It Must Sum Up To 100%</span></h4>')
            return false;
        }else{
            setDeleteIDs();
            $(this).next().html('')
            return true;
        }
    });
    
    ////////////////////    Grade Grouping  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_grade_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Subject Groups  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_subject_group_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Subject  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_subject_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Items  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_item_btn', function(){
        setDeleteIDs();
    });
    
    ////////////////////    Item Bills  ////////////////////////////////////////////////////////////////////////////
    $(document.body).on('click', '#save_item_bill_btn', function(){
        setDeleteIDs();
    });
    
});