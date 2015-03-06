$('document').ready(function(){


    setTabActive('[href="'+domain_name+'/assessments"]', 1);

    //////////////////////////////////////////////// iCheck Begins /////////////////////////////////////////////////////////////////////////////////////////////////

    $('.flat-input').iCheck({
        checkboxClass: 'icheckbox_flat-green',
        radioClass: 'iradio_flat-green'
    });

    $('.futurico-input').iCheck({
        checkboxClass: 'icheckbox_futurico',
        radioClass: 'iradio_futurico',
        increaseArea: '20%' // optional
    });

    $('.polaris-input').iCheck({
        checkboxClass: 'icheckbox_polaris',
        radioClass: 'iradio_polaris',
        increaseArea: '20%' // optional
    });

    $('.square-input').iCheck({
        checkboxClass: 'icheckbox_square-orange',
        radioClass: 'iradio_square-orange',
        increaseArea: '20%' // optional
    });

    $('.minimal-input').iCheck({
        checkboxClass: 'icheckbox_minimal-blue',
        radioClass: 'iradio_minimal-blue',
        increaseArea: '20%' // optional
    });

    //////////////////////////////////////////////// iCheck Ends /////////////////////////////////////////////////////////////////////////////////////////////////


   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
});