function SearchCtrl($scope, $http) {
    $scope.url = 'summaryAngular'; // The url of our search

    // The function that will be executed on button click (ng-click="search()")
    $scope.search = function() {

        // Create the http post request
        // the data holds the keywords
        // The request is a JSON request.
        $http.post($scope.url, { "data" : 'yes'}).
            success(function(data, status) {
                $scope.records = data || "Request failed";
                $scope.status = status;
                console.log(data);
            })
            .
            error(function(data, status) {
                $scope.data = data || "Request failed";
                $scope.status = status;
            });
    };
}

var itemFormData = "";

function submitForm($scope, $http){
    $scope.url = 'validateIfExist';
    //When The Form process_item_form is submitted
    $scope.search = function() {
        ajax_loading_image($('#msg_box'), ' Processing');
        itemFormData = $('#process_item_form').serialize();
        $http.post($scope.url, {"data": itemFormData}).
            success(function (data, status) {
                $scope.records = data || "Request failed";
                $scope.status = status;
                console.log(data);
                set_msg_box($('#msg_box'), 'The Fees Has Been Processed For The Academic Term Already', 2);
            })
            .
            error(function (data, status) {
                $scope.data = data || "Request failed";
                $scope.status = status;
                ajax_remove_loading_image($('#msg_box'));
                var term = $('#academic_term_id').children('option:selected').text();
                var output = '<ol>\n\
                                    <li><b>Academic Term</b> : ' + term + '</li>\n\
                                    <li><b>Process Date</b> : ' + $('#process_date').val() + '</li>\n\
                                </ol>';
                $('#confirm_output').html(output);
                $('#confirm_process_fees_modal').modal('show');
            });
        return false;
    }
}