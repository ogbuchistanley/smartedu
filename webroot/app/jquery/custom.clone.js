$('document').ready(function(){
    
    //var domain_name = '/smartschool';

    setTabActive('[href="'+domain_name+'/clones/index"]', 1);
    $('[href="'+domain_name+'/clones/index"]').attr('data-toggle', 'tab');

    $('[href="'+domain_name+'/clones/index"]').click(function(){
        $('#myTab a[href="'+domain_name+'/clones/index"]').tab('show');
        setTabActive('[href="'+domain_name+'/clones/index"]', 1);
    });
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    // OnChange of Academic Year Get Academic Term
    var url = "\/academic_terms\/ajax_get_terms\/CloneClass\/%23academic_year_from_id";
    getDependentListBox($("#academic_year_from_id"), $("#academic_term_from_id"), url);

    var url5 = "\/academic_terms\/ajax_get_terms\/CloneClass\/%23academic_year_to_id";
    getDependentListBox($("#academic_year_to_id"), $("#academic_term_to_id"), url5);
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    // When setup exam button is clicked validate

    $(document.body).on('submit', '#clone_class_form', function(){
        ajax_loading_image($('#msg_box1'), ' Cloning...');
        var from = $('#academic_term_from_id').text();
        var to = $('#academic_term_to_id').text();
        var values = $('#clone_class_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/clones/validateClone',
            data: values,
            success: function(data){
                try{
                    if(data === '3'){
                        var output = 'Sorry You Can Not Clone Subjects Assigned To Class Room And Teachers <em>From '+ from +
                            'To '+ to +'</em> Kindly Navigate To Subjects Module For Modifications';
                        set_msg_box($('#msg_box1'), output, 2);
                    }else if(data === '2'){
                        var output = 'Subjects Has Been Assigned To Class Room And Teachers Already for <em>'+ to +
                            '</em> Kindly Navigate To Subjects Module For Modifications';
                        set_msg_box($('#msg_box1'), output, 2);
                    }else if(data === '1'){
                        ajax_remove_loading_image($('#msg_box1'));
                        $('#clone_class_output').html('Clone Subjects Assigned To Class Room And Teachers From <em>' + from + ' To ' + to +'</em>');
                        $('#from_term_id').val($('#academic_term_from_id').val());
                        $('#to_term_id').val($('#academic_term_to_id').val());
                        $('#clone_class_modal').modal('show');
                    }
                } catch (exception) {
                    $('#msg_box1').html(data);
                }
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#msg_box1').html(errorThrown);
            }
        });
        return false;
    });

});