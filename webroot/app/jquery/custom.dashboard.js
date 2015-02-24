$('document').ready(function(){
    
    //var domain_name = '/smartschool';
    
////////////////////////////// Dashboard Pie Chat Begin/////////////////////////////////////////////////////////////
   // Pie chart on Dashboard // Displaying Students Gender
   td_loading_image($('#students_gender'));
   $.post(domain_name+'/dashboard/studentGender', function(data){
        var result = $.parseJSON(data)
        Morris.Donut({
            element: "students_gender",
            data: result.Gender,
            labelColor: "#54728c",
            colors: [ "#54728c", "#54b5df"],
            formatter: function(e) {
                return e.toFixed(2) + "%";
            }
        }).on("click", function(e, t) {
            //console.log(e, t);
            var sex_count = (t.label === "Male") ? result.Male : result.Female;
            var active_count = (t.label === "Male") ? result.ActiveMale : result.ActiveFemale;
            var sex = (t.label === "Male") ? 'Male' : 'Female';
            $.gritter.add({
                // (string | mandatory) the heading of the notification
                title: sex_count+' '+sex+' Students out of Which '+active_count+' are Active',
                // (string | mandatory) the text inside the notification
                text: 'The Total Number Of Students are '+result.Count+' Both Past and Present',
                // (string | optional) the image to display on the left
                image: false,
                // (bool | optional) if you want it to fade out on its own or just sit there
                sticky: false,
                // (int | optional) the time you want it to be alive for before fading out
                time: 5000
            });
        });
    });
    
    // Pie chart on Dashboard // Displaying Students Status
    td_loading_image($('#students_status'));
    $.post(domain_name+'/dashboard/studentStauts', function(data){
        var result = $.parseJSON(data)
        //alert(data);
        Morris.Donut({
            element: "students_status",
            data: result.Status,
            labelColor: "#54728c",
            colors: [ "#90c657", "#54728c", "#54b5df", "#f9a94a", "#e45857" ],
            formatter: function(e) {
                return e.toFixed(2) + "%";
            }
        }).on("click", function(e, t) {
            var status_count;
            var status;
            $.each(result.CountEach, function(key, value) {
                if(t.label === value.label){
                    status_count = value.count;
                    status = value.label;
                }
            });
            $.gritter.add({
                // (string | mandatory) the heading of the notification
                title: status_count+' Students on '+status+' Status!!!',
                // (string | mandatory) the text inside the notification
                text: 'The Total Number Of Students are '+result.Count+' Both Past and Present',
                // (string | optional) the image to display on the left
                image: false,
                // (bool | optional) if you want it to fade out on its own or just sit there
                sticky: false,
                // (int | optional) the time you want it to be alive for before fading out
                time: 5000
            });
        });
    });
    
    // Pie chart on Dashboard // Displaying Payment Status
    td_loading_image($('#payment_status'));
    $.post(domain_name+'/dashboard/studentPaymentStatus', function(data){
        var result = $.parseJSON(data)
        //alert(data);
        Morris.Donut({
            element: "payment_status",
            data: result.Status,
            labelColor: "#54728c",
            colors: [ "#90c657", "#e45857" ],
            formatter: function(e) {
                return e.toFixed(0) +' Students';
            }
        }).on("click", function(e, t) {
            var status_count = t.value;
            var status = t.label;
                        
            $.gritter.add({
                // (string | mandatory) the heading of the notification
                title: status_count+' Students have '+status+' for ' + result.CurrentTerm + '!!!',
                // (string | mandatory) the text inside the notification
                text: 'The Total Number Of Students are '+result.CountAll+' for '+result.CurrentTerm,
                // (string | optional) the image to display on the left
                image: false,
                // (bool | optional) if you want it to fade out on its own or just sit there
                sticky: false,
                // (int | optional) the time you want it to be alive for before fading out
                time: 5000
            });
        });
    });
////////////////////////////// Dashboard Pie Chat Ends/////////////////////////////////////////////////////////////
    
    
////////////////////////////// Dashboard Bar Chat Begin/////////////////////////////////////////////////////////////
// Discrete Bar chart on Dashboard // Displaying Students Class Level
    //td_loading_image($('#chart1'));
    
    //$.post(domain_name+'/dashboard/studentClasslevel', function(data){
    $.ajax({
        type: "POST",
        url: domain_name+'/dashboard/studentClasslevel',
        success: function(data){
            try{
                var result = $.parseJSON(data)
                var historicalBarChart = [ 
                    {
                        key: "Cumulative Return",
                        values: result.Classlevel
                    }
                ];
                $('.current_year_span').text(result.CurrentYear);
                nv.addGraph(function() { 
                    var chart = nv.models.discreteBarChart()
                        .x(function(d) { return d.label })
                        .y(function(d) { return d.value })
                        .staggerLabels(true)
                        //.staggerLabels(historicalBarChart[0].values.length > 8)
                        //.tooltips(false)
                        .showValues(true)
                        .transitionDuration(350)
                        .margin({bottom:60})
                        ;
                    var xTicks = d3.select('.nv-x.nv-axis > g').selectAll('g');
                        xTicks
                            .selectAll('text')
                            .style("text-anchor", "end")
                            .attr("transform", function(d) {
                                return "rotate(-45)" 
                            });
                    chart.yAxis.tickFormat(d3.format(',f'));
                    chart.xAxis.axisLabel('Classlevel');
                    chart.valueFormat(d3.format('d'));
                    d3.select('#chart1 svg')
                        .datum(historicalBarChart)
                        .transition().duration(700)
                        .call(chart);

                    nv.utils.windowResize(chart.update);

                    return chart;
                });
            } catch (exception) {
                $('#chart1').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>'+data+'</h4></div></div>');
                $('#chart1').next('p').html('');
            }
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
           $('#chart1').html(errorThrown);
        }    
    });
    
    // Discrete Bar chart on Dashboard // Displaying Head Tutor Subject For The Current Term
    $.ajax({
        type: "POST",
        url: domain_name+'/dashboard/subjectHeadTutor',
        success: function(data){
            try{
                var result = $.parseJSON(data)
                var historicalBarChart = [ 
                    {
                    key: "Cumulative Return",
                    values: result.Subject
                    }
                ];
                $('.current_term_span').text(result.CurrentTerm);
                nv.addGraph(function() { 
                    //var days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
                    var chart = nv.models.discreteBarChart()
                        .x(function(d) { return d.label })
                        .y(function(d) { return d.value })
                        .staggerLabels(true)
                        //.staggerLabels(historicalBarChart[0].values.length > 8)
                        //.tooltips(false)
                        .showValues(false)
                        .transitionDuration(350)
                        .margin({bottom:60, left: 140})
                        ;
                    var xTicks = d3.select('.nv-x.nv-axis > g').selectAll('g');
                        xTicks
                            .selectAll('text')
                            .style("text-anchor", "end")
                            .attr("transform", function(d) {
                                return "rotate(-45)" 
                            });
                            
                    chart.yAxis.tickValues(result.Count)
                    .tickFormat(function(d){
                        return result.Subj[(d / 5) - 1];
                    });
                    //chart.forceY([0, 40]);
                    chart.valueFormat(d3.format('d'));
                    d3.select('#chart01 svg')
                        .datum(historicalBarChart)
                        .transition().duration(700)
                        .call(chart);

                    nv.utils.windowResize(chart.update);

                    return chart;
                });
            } catch (exception) {
                $('#chart01').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>'+data+'</h4></div></div>');
                $('#chart01').next('p').html('');
            }
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
           $('#chart01').html(errorThrown);
        }            
    });
    
    // Discrete Bar chart on Dashboard // Displaying Head Tutor Class Rooms 
    $.ajax({
        type: "POST",
        url: domain_name+'/dashboard/classHeadTutor',
        success: function(data){
            try{
                var result = $.parseJSON(data)
                var historicalBarChart = [ 
                    {
                    key: "Cumulative Return",
                    values: result.Classroom
                    }
                ];
                $('.current_year_span').text(result.CurrentYear);
                nv.addGraph(function() { 
                    
                    var chart = nv.models.discreteBarChart()
                        .x(function(d) { return d.label })
                        .y(function(d) { return d.value })
                        .staggerLabels(true)
                        //.staggerLabels(historicalBarChart[0].values.length > 8)
                        //.tooltips(false)
                        .showValues(true)
                        .transitionDuration(350)
                        .margin({bottom:60})
                        ;
                    var xTicks = d3.select('.nv-x.nv-axis > g').selectAll('g');
                        xTicks.selectAll('text')
                            .style("text-anchor", "end")
                            .attr("transform", function(d) {
                                return "rotate(-45)" 
                            });
                    chart.yAxis.tickFormat(d3.format(',f'));
                    chart.valueFormat(d3.format('d'));
                    
                    d3.select('#chart0 svg')
                        .datum(historicalBarChart)
                        .transition().duration(700)
                        .call(chart);
                    
                    nv.utils.windowResize(chart.update);
                    return chart;
                });
            } catch (exception) {
                $('#chart0').html('<div class="info-box  bg-info-dark  text-white"><div class="info-details"><h4>'+data+'</h4></div></div>');
                $('#chart0').next('p').html('');
            }
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
           $('#chart0').html(errorThrown);
        }            
    });
////////////////////////////// Dashboard Bar Chat Ends/////////////////////////////////////////////////////////////
});

//svg.append("g")
//                        .attr("class", "x axis")
//                        .attr("transform", "translate(0," + height + ")")
//                        .call(xAxis)
//                        .selectAll("text")  
//                        .style("text-anchor", "end")
//                        .attr("dx", "-.8em")
//                        .attr("dy", ".15em")
//                        .attr("transform", function(d) {
//                            return "rotate(-65)" 
//                        });