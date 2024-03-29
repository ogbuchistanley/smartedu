$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
    setTabActive('[href="'+domain_name+'/exams/index#setupExam"]', 1);
     $('[href="'+domain_name+'/exams/index#setupExam"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/exams/index#subjectScores"]').attr('data-toggle', 'tab');
     $('[href="'+domain_name+'/exams/index#viewTAScores"]').attr('data-toggle', 'tab');
     
    $('[href="'+domain_name+'/exams/index#setupExam"]').click(function(){
        $('#myTab a[href="'+domain_name+'/exams/index#setupExam"]').tab('show');
        setTabActive('[href="'+domain_name+'/exams/index#setupExam"]', 1);
    });
    $('[href="'+domain_name+'/exams/index#subjectScores"]').click(function(){
        $('#myTab a[href="'+domain_name+'/exams/index#subjectScores"]').tab('show');
        setTabActive('[href="'+domain_name+'/exams/index#subjectScores"]', 1);
    });
    $('[href="'+domain_name+'/exams/index#viewTAScores"]').click(function(){
        $('#myTab a[href="'+domain_name+'/exams/index#viewTAScores"]').tab('show');
        setTabActive('[href="'+domain_name+'/exams/index#viewTAScores"]', 1);
    });
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////           Dependent ListBox
    //var url = "\/academic_terms\/ajax_get_terms\/SubjectClasslevel\/%23academic_year_id_all";
    //getDependentListBox($("#academic_year_id_all"), $("#academic_term_id_all"), url);
    var url = "\/academic_terms\/ajax_get_terms\/Exam\/%23academic_year_id_all";
    getDependentListBox($("#academic_year_id_all"), $("#academic_term_id_all"), url);
    
    var url2 = "\/academic_terms\/ajax_get_terms\/SearchExamSetup\/%23academic_year_examSetup_id";
    getDependentListBox($("#academic_year_examSetup_id"), $("#academic_term_examSetup_id"), url2);
    
    var url3 = "\/academic_terms\/ajax_get_terms\/SearchExamTAScores\/%23academic_year_examTAScores_id";
    getDependentListBox($("#academic_year_examTAScores_id"), $("#academic_term_examTAScores_id"), url3);
    
    var url4 = "\/classrooms\/ajax_get_classes\/SubjectClasslevel\/%23classlevel_id_all";
    getDependentListBox($("#classlevel_id_all"), $("#class_id_all"), url4);
    
    var url5 = "\/classrooms\/ajax_get_classes\/SearchExamTAScores\/%23classlevel_examTAScores_id";
    getDependentListBox($("#classlevel_examTAScores_id"), $("#class_examTAScores_id"), url5);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // When setup exam button is clicked validate
    $(document.body).on('submit', '#setup_exam', function(){
        ajax_loading_image($('#msg_box'), ' SettingUp Exam...');
        var values = $('#setup_exam').serialize();
        $.ajax({
             type: "POST",
             url: domain_name+'/exams/setup_validate',
             data: values,
             success: function(data){
                 if(data === '2'){
                     ajax_remove_loading_image($('#msg_box1_modal'));
                 }else{
                     set_msg_box($('#msg_box1_modal'), data, 3);
                 }
                 $('#hidden_term_id').val($('#academic_term_id_all').val());
                 ajax_remove_loading_image($('#msg_box'));
                 $('#setup_exam_modal').modal('show');
             },
             error: function(XMLHttpRequest, textStatus, errorThrown) {
                $('#msg_box').html(errorThrown);
             }
        });
        return false;
    });

    //When the modal form is submitted... setup the exam
    $(document.body).on('submit', '#exam_setup_modal_form', function(){
         ajax_loading_image($('#msg_box1_modal'), ' SettingUp Exam...');
        ajax_loading_image($('#msg_box'), ' SettingUp Exam...');
    });

    //Search Form For displaying Subjects Assigned to a Class
    //$(document.body).on('submit', '#search_subject_assigned_form', function() {
    //    ajax_loading_image($('#msg_box'), ' Loading Contents');
    //    var values = $('#search_subject_assigned_form').serialize();
    //    $.ajax({
    //        type: "POST",
    //        url: domain_name+'/exams/search_subjects_assigned',
    //        data: values,
    //        success: function(data){
    //            try{
    //                var obj = $.parseJSON(data);
    //                var pre = '0';
    //                var term = $('#academic_term_search_id').children('option:selected').text();
    //                var output = '<caption><strong>Results Output From The Search ::: <u>'+term+' Academic Year</u></strong></caption>\
    //                                <thead><tr>\
    //                                    <th>Subjects</th>\
    //                                    <th>Classlevels</th>\
    //                                    <th>#</th>\
    //                                    <th>Class Rooms</th>\
    //                                    <th>Teacher</th>\
    //                                    <th>Exam Status</th>\
    //                                    <th>Action</th>\
    //                                    <th></th>\
    //                                </tr></thead>';
    //                if(obj.Flag === 1){
    //                    output += '<tbody>';
    //                    $.each(obj.SubjectClasslevel, function(key, value) {
    //                        var cur = value.subject_id;
    //                        if(cur !== pre){
    //                            output += '<tr>\
    //                                <th>'+value.subject_name+'</th>\n\
    //                                <th>'+value.classlevel+'</th><th></th><th></th><th></th><th></th><th></th><th></th>\\n\
    //                            </tr>';
    //                        }
    //                        pre = cur;
    //                        output += '<tr>\
    //                            <td></td><td></td>\n\\n\
    //                            <td>'+(key + 1)+'</td>\n\
    //                            <td>'+value.class_name+'</td>\n\
    //                            <td style="font-size:medium">'+value.employee_name+'</td>\
    //                            <td style="font-size:medium">'+value.exam_status+'</td>';
    //                            if(value.exam_id === '-1'){
    //                                output += '<td>\
    //                                    <button type="button" value="'+value.subject_classlevel_id+'" title="'+value.class_id+'"  class="btn btn-warning btn-xs setup_exam_btn">\n\
    //                                    <i class="fa fa-gear"></i> Setup Exam</button></td>';
    //                            }else if(value.exam_id > 0){
    //                                output += '<td>\
    //                                    <button type="button" value="'+value.exam_id+'" class="btn btn-success btn-xs edit_setup_exam_btn">\n\
    //                                    <i class="fa fa-edit"></i> Edit Exam</button></td>';
    //                            }
    //                        output += '<td></td></tr>';
    //                    });
    //                    output += '</tbody>';
    //                    $('#search_subjects_assigned_table').html(output);
    //                }else if(obj.Flag === 0){
    //                    output += '<tr><th colspan="7">No Subject Found</th></tr>';
    //                    $('#search_subjects_assigned_table').html(output);
    //                }
    //            } catch (exception) {
    //                $('#search_subjects_assigned_table').html(data);
    //            }
    //            ajax_remove_loading_image($('#msg_box'));
    //            //Scroll To Div
    //            scroll2Div($('#search_subjects_assigned_table'));
    //        },
    //        error: function(XMLHttpRequest, textStatus, errorThrown) {
    //           $('#search_subjects_assigned_table').html(errorThrown);
    //            ajax_remove_loading_image($('#msg_box'));
    //        }
    //    });
    //    return false;
    //});
   
   //When the setup exam button is clicked show the form
   //$(document.body).on('click', '.setup_exam_btn', function(){
   //     $('#exam_setup_modal_form')[0].reset();
   //     ajax_loading_image($('#msg_box'), ' Loading Contents');
   //     //var subject = $(this).parent().parent().children(':nth-child(2)').html();
   //     $('#setup_exam_modal').modal('show');
   //     $('#edit_exam_id').val(-1);
   //     $('#class_id').val($(this).attr('title'));
   //     $('#subject_classlevel_id').val($(this).val());
   //     ajax_remove_loading_image($('#msg_box'));
   //});
   
   //When the Edit setup exam button is clicked show the form with the existing values
   //$(document.body).on('click', '.edit_setup_exam_btn', function(){
   //     ajax_loading_image($('#msg_box'), ' Loading Contents');
   //     var exam_id = $(this).val();
   //     $.ajax({
   //         type: "POST",
   //         url: domain_name+'/exams/get_exam_setup',
   //         data: {exam_id:exam_id},
   //         success: function(data){
   //         //$.post(domain_name+'/exams/get_exam_setup', {exam_id:exam_id}, function(data){
   //             try {
   //                 var obj = $.parseJSON(data);
   //                 $('#edit_exam_id').val(exam_id);
   //                 $('#class_id').val(obj.class_id);
   //                 $('#weightageCA1').val(obj.weightageCA1);
   //                 $('#weightageCA2').val(obj.weightageCA2);
   //                 $('#weightageExam').val(obj.weightageExam);
   //                 $('#exam_desc').val(obj.exam_desc);
   //                 $('#subject_classlevel_id').val(obj.subject_classlevel_id);
   //                 $('#setup_exam_modal').modal('show');
   //                 ajax_remove_loading_image($('#msg_box'));
   //             } catch (exception) {
   //                 $('#search_subjects_assigned_table').html(data);
   //             }
   //             ajax_remove_loading_image($('#msg_box'));
   //         },
   //         error: function(XMLHttpRequest, textStatus, errorThrown) {
   //            $('#search_subjects_assigned_table').html(errorThrown);
   //             ajax_remove_loading_image($('#msg_box'));
   //         }
   //     });
   //});
   
   
   //When the modal form is submitted... setup the exam
   // $(document.body).on('submit', '#exam_setup_modal_form', function(){
   //     ajax_loading_image($('#msg_box1_modal'), ' SettingUp...');
   //     var values = $('#exam_setup_modal_form').serialize();
   //     $.ajax({
   //         type: "POST",
   //         url: domain_name+'/exams/setup_exam',
   //         data: values,
   //         success: function(data){
   //         //$.post(domain_name+'/exams/setup_exam', $(this).serialize(), function(data){
   //             if(data !== '0'){
   //                 ajax_remove_loading_image($('#msg_box1_modal'));
   //                 $('#search_subjects_assigned_table').html('');
   //                 $('#exam_setup_modal_form')[0].reset();
   //                 $('#setup_exam_modal').modal('hide');
   //             }
   //         },
   //         error: function(XMLHttpRequest, textStatus, errorThrown) {
   //            $('#search_subjects_assigned_table').html(errorThrown);
   //             ajax_remove_loading_image($('#msg_box1_modal'));
   //         }
   //     });
   //     return false;
   // });
    
    //Search Form For displaying Subjects Exams Has Been Setup for editing
    $(document.body).on('submit', '#search_examSetup_form', function(){
        ajax_loading_image($('#msg_box2'), ' Loading Contents');
        var values = $('#search_examSetup_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/exams/search_subjects_examSetup',
            data: values,
            success: function(data){
            //$.post(domain_name+'/exams/search_subjects_examSetup', values, function(data){
                try{
                    var obj = $.parseJSON(data);
                    var term = $('#academic_term_examSetup_id').children('option:selected').text();
                    var output = '<caption><strong>Results Output From The Search ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th colspan="4"></th>\
                                        <th colspan="2" style="text-align: center">Weight Point</th>\
                                        <th colspan="3"></th>\
                                    </tr></thead>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Subjects</th>\
                                        <th>Classlevels</th>\
                                        <th>Class Rooms</th>\
                                        <th>C.A</th>\
                                        <th>Exam</th>\
                                        <th>Exam Status</th>\
                                        <th colspan="2" style="text-align: center">Action</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SearchExamSetup, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.subject_name+'</td>\n\
                                <td>'+value.classlevel+'</td>\
                                <td>'+value.class_name+'</td>\n\
                                <td>'+value.ca_weight_point+'</td>\n\
                                <td>'+value.exam_weight_point+'</td>\n\
                                <td  style="font-size: medium">'+value.exammarked_status+'</td>';
                                if(value.exammarked_status_id === '2'){
                                    output += '<td>\n\
                                        <a target="__blank" href="'+domain_name+'/exams/enter_scores/'+value.exam_id+'" class="btn btn-warning btn-xs">\n\
                                        <i class="fa fa-foursquare"></i> Input Scores</a>\
                                    </td><td><span class="label label-danger">nill</span></td>';
                                }else {
                                    output += '<td>\n\
                                        <a target="__blank" href="'+domain_name+'/exams/enter_scores/'+value.exam_id+'" class="btn btn-info btn-xs">\n\
                                        <i class="fa fa-edit"></i> Edit Scores</a>\
                                    </td>\n\
                                    <td>\n\
                                        <a target="__blank" href="'+domain_name+'/exams/view_scores/'+value.exam_id+'" class="btn btn-primary btn-xs">\n\
                                        <i class="fa fa-eye"></i> View Scores</a>\
                                    </td>';
                                }
                            output += '</tr>';
                        });
                        output += '</tbody>';
                        $('#search_subjects_scores_table').html(output);
                    }else if(obj.Flag === 0){
                        output += '<tr><th colspan="9">No Subject Assigned To You In The Class Level</th></tr>';
                        $('#search_subjects_scores_table').html(output);
                    }
                } catch (exception) {
                    $('#search_subjects_scores_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box2'));
                //Scroll To Div
                scroll2Div($('#search_subjects_scores_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#search_subjects_scores_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box2'));
            } 
        });
        return false;
    });
    
    
    //Validate The C.A Weight Point
    $(document.body).on('blur', '.ca_value, .exam_value', function(){
        var ca = parseInt($(this).val());
        var WA = $('#hidden_WA_value').val().split('-');
        var classes = $(this).attr('class').split(' ');
        var value = '';
        if(classes[2] === 'ca_value'){
            value = WA[0];
        }else if(classes[2] === 'exam_value'){
            value = WA[1];
        }
        if(ca > parseInt(value) || ca < 0){
            $(this).parent().children(':nth-child(2)').html('<span class="label label-danger">>= 0 and <= '+value+'</span>');
            $(this).focus();
        }else{
            $(this).parent().children(':nth-child(2)').html('');
        }
    });

    //Validate The Weekly Report Form Before Submission
    $(document.body).on('click', '#exam_form_btn', function(){
        var validate = '';
        $('.ca_value').each(function(){
            var span = $(this).next('span').html();
            validate += span;
        });
        $('.exam_value').each(function(){
            var span = $(this).next('span').html();
            validate += span;
        });
        if(validate.trim() == '')
            return true;
        else
            return false;
    });
    
    //Search Form For displaying Subjects Exams Has Been Setup for editing
    $(document.body).on('submit', '#search_examTAScores_form', function(){
        ajax_loading_image($('#msg_box3'), ' Loading Contents');
        var values = $('#search_examTAScores_form').serialize();
        $.ajax({
            type: "POST",
            url: domain_name+'/exams/search_student_classlevel',
            data: values,
            success: function(data){
            //$.post(domain_name+'/exams/search_student_classlevel', values, function(data){
                try{
                    var obj = $.parseJSON(data);
                    var cls = $('#class_examTAScores_id').children('option:selected').text();
                    var cls_lvl = $('#classlevel_examTAScores_id').children('option:selected').text();
                    var term = $('#academic_term_examTAScores_id').children('option:selected').text();
                    var output = '<caption><strong>Results For <u>'+cls+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>ID Code</th>\
                                        <th>Student Name</th>\
                                        <th>Print</th>\
                                        <th>Chart Analysis</th>\
                                        <th>Terminal Scores</th>\
                                        <th>Annual Scores</th>\
                                    </tr></thead>';
                    var output2 = '<caption><strong>Results For <u>Classlevel '+cls_lvl+' ::: <u>'+term+' Academic Year</u></strong></caption>\
                                    <thead><tr>\
                                        <th>#</th>\
                                        <th>Class Name</th>\
                                        <th>Class Capacity</th>\
                                        <th>Terminal Scores</th>\
                                        <th>Annual Scores</th>\
                                    </tr></thead>';
                    if(obj.Flag === 1){
                        output += '<tbody>';
                        $.each(obj.SearchExamTAScores, function(key, value) {
                            output += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.student_no+'</td>\
                                <td>'+value.student_name+'</td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/exams/print_result/'+value.std_cls_term_id+'" class="btn btn-success btn-xs">\n\
                                    <i class="fa fa-print"></i> Print</a>\
                                </td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/exams/chart/'+value.std_cls_term_id+'" class="btn btn-primary btn-xs">\n\
                                    <i class="fa fa-bar-chart-o"></i> View Chart</a>\
                                </td>\n\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/exams/term_scorestd/'+value.std_cls_term_id+'" class="btn btn-info btn-xs">\n\
                                    <i class="fa fa-eye-slash"></i> View Scores</a>\
                                </td>\n\
                                <td>\n\
                                    <a target="__blank" href="'+domain_name+'/exams/annual_scorestd/'+value.std_cls_yr_id+'" class="btn btn-warning btn-xs">\n\
                                    <i class="fa fa-eye"></i> Proceed</a>\
                                </td>\
                            </tr>';
                        });
                        output += '</tbody>';
                        $('#view_TA_scores_table').html(output);
                    }else if(obj.Flag === 2){
                        output2 += '<tbody>';
                        $.each(obj.SearchExamTAScores, function(key, value) {
                            output2 += '<tr>\
                                <td>'+(key + 1)+'</td>\n\
                                <td>'+value.class_name+'</td>\
                                <td>'+value.class_size+'</td>\
                                <td>\
                                    <a target="__blank" href="'+domain_name+'/exams/term_scorecls/'+value.cls_term_id+'" class="btn btn-info btn-xs">\n\
                                    <i class="fa fa-eye-slash"></i> View Scores</a>\
                                </td>\n\
                                <td>\n\
                                    <a target="__blank" href="'+domain_name+'/exams/annual_scorecls/'+value.cls_yr_id+'" class="btn btn-warning btn-xs">\n\
                                    <i class="fa fa-eye"></i> Proceed</a>\
                                </td>\
                            </tr>';
                        });
                        output2 += '</tbody>';
                        $('#view_TA_scores_table').html(output2);
                    }else if(obj.Flag === 0){
                        $('#view_TA_scores_table').html('<tr><th colspan="5">No Record Found</th></tr>');
                    }
                } catch (exception) {
                    $('#view_TA_scores_table').html(data);
                }
                ajax_remove_loading_image($('#msg_box3'));
                //Scroll To Div
                scroll2Div($('#view_TA_scores_table'));
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
               $('#view_TA_scores_table').html(errorThrown);
                ajax_remove_loading_image($('#msg_box3'));
            } 
        });
        return false;
    });
    
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



   ////////////////////////////////////////////// Exam Chart  //////////////////////////////////////////////////////////////////////
    // Discrete Bar chart on Dashboard // Displaying Students Exams Result
    $.ajax({
        type: "POST",
        url: domain_name+'/exams/chart_analysis/'+$('#encrypt_id').val(),
        success: function(data){
            try{
                var result = $.parseJSON(data)
                if(result.Flag > 0) {
                    Morris.Bar ({
                        element: 'visitors',
                        data: result.Subject,
                        xkey: 'subject_name',
                        ykeys: ['ca', 'exam', 'total'],
                        labels: ['C.A', 'Exams', 'Total(100%)'],
                        //barSizeRatio:0.4, //I think you meant barSizeRatio, not barSize
                        xLabelAngle: 35,
                        hideHover: 'auto'
                    });
                }else{
                    $('#visitors').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>No Record Found</h4></div></div>');
                }
            } catch (exception) {
                $('#visitors').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>'+data+'</h4></div></div>');
                $('#visitors').next('p').html('');
            }
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            $('#visitors').html(errorThrown);
        }
    });


    // Discrete Bar chart on Dashboard // Displaying Students Exams Result
    //$.ajax({
    //    type: "POST",
    //    url: domain_name+'/exams/chart_anal/'+$('#encrypt_id').val(),
    //    success: function(data){
    //        try{
    //            var result = $.parseJSON(data)
    //            console.log(result.Subject);
    //            nv.addGraph(function() {
    //                var chart = nv.models.multiBarChart()
    //                        .transitionDuration(350)
    //                        .reduceXTicks(true)   //If 'false', every single x-axis tick label will be rendered.
    //                        //.rotateLabels(-30)      //Angle to rotate x-axis labels.
    //                        .showControls(true)   //Allow user to switch between 'Grouped' and 'Stacked' mode.
    //                        .groupSpacing(0.1)    //Distance between each group of bars.
    //                        .showLegend(true)
    //                        .staggerLabels(true)
    //                    ;
    //
    //                chart.yAxis
    //                    .tickFormat(d3.format(',.1f'));
    //
    //                chart.tooltip(function(key, x, y, e, graph) {
    //                    return '<h4>' + key + '</h4>' +
    //                        '<p>Score: ' +  y + ' on ' + x + '</p>';
    //                });
    //
    //                d3.select('#chart1 svg')
    //                    .datum(result.Subject)
    //                    .call(chart);
    //
    //                nv.utils.windowResize(chart.update);
    //
    //                return chart;
    //            });
    //        } catch (exception) {
    //            $('#chart1').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>'+data+'</h4></div></div>');
    //            $('#chart1').next('p').html('');
    //        }
    //    },
    //    error: function(XMLHttpRequest, textStatus, errorThrown) {
    //        $('#chart1').html(errorThrown);
    //    }
    //});
////////////////////////////// Exam Bar Chat Ends/////////////////////////////////////////////////////////////

});