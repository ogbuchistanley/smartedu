<?php
App::uses('AppModel', 'Model');

class Item extends AppModel {

    public $primaryKey = 'item_id';

    public $displayField = 'item_name';

    public $belongsTo = array(
        'ItemType' => array(
                'className' => 'ItemType',
                'foreignKey' => 'item_type_id',
                'conditions' => '',
                'fields' => '',
                'order' => ''
        )
    );
    
    public $hasMany = array(
        'ItemBill' => array(
                'className' => 'ItemBill',
                'foreignKey' => 'item_bill_id',
                'dependent' => false,
                'conditions' => ''
        )
    );

    //Find all items charged to a student in an academic term
    public function findStudentTerminalFees($student_id, $term_id) {
        return $this->query('SELECT a.* FROM student_feesviews a WHERE a.student_id="'.$student_id.'" AND academic_term_id="'.$term_id.'"');
    }
    
    //Find all items charged to a student in an academic term
    public function findClassTerminalFees($class_id, $term_id) {
        return $this->query('SELECT student_id, student_no, student_name, student_status_id, student_status, sponsor_name, sponsor_id,'
                . ' class_name, academic_term, academic_term_id, order_id, order_status_id, SUM(subtotal) AS grand_total'
                . ' FROM student_feesviews WHERE class_id="'.$class_id.'" AND academic_term_id="'.$term_id.'"'
                . ' GROUP BY student_id');
    }
    
    //Count all the number of students that have paid and those not piad in the academic term
    public function CurrentTermPaymentStatus() {
        $AcademicTerm = ClassRegistry::init('AcademicTerm');
        $paid = $this->query('SELECT COUNT(*) AS paid FROM students_paymentviews a '
                . 'WHERE academic_term_id="'.$AcademicTerm->getCurrentTermID().'" AND status_id=1');
        $not_paid = $this->query('SELECT COUNT(*) AS not_paid FROM students_paymentviews a '
                . 'WHERE academic_term_id="'.$AcademicTerm->getCurrentTermID().'" AND status_id=2');
        $result[0] = $paid[0][0]['paid'];
        $result[1] = $not_paid[0][0]['not_paid'];
        return $result;
    }
    
    //Count all the number of students that have paid in the academic term
    public function countClassPaid($term_id, $class_id) {
        $paid = $this->query('SELECT COUNT(*) AS paid FROM students_paymentviews a WHERE academic_term_id="'.$term_id.'" '
                . ' AND class_id="'.$class_id.'" AND status_id=1');
        return $paid[0][0]['paid'];
    }
    
    //Count all the number of students that have not paid in the academic term
    public function countClassNotPaid($term_id, $class_id) {
        $paid = $this->query('SELECT COUNT(*) AS not_paid FROM students_paymentviews a WHERE academic_term_id="'.$term_id.'" '
                . ' AND class_id="'.$class_id.'" AND status_id=2');
        return $paid[0][0]['not_paid'];
    }
    
    public function convert_number_to_words($number) {
    
        $hyphen      = '-';
        $conjunction = ' And ';
        $separator   = ', ';
        $negative    = 'Negative ';
        $decimal     = ' Point ';
        $dictionary  = array(
            0                   => 'Zero',
            1                   => 'One',
            2                   => 'Two',
            3                   => 'Three',
            4                   => 'Four',
            5                   => 'Five',
            6                   => 'Six',
            7                   => 'Seven',
            8                   => 'Eight',
            9                   => 'Nine',
            10                  => 'Ten',
            11                  => 'Eleven',
            12                  => 'Twelve',
            13                  => 'Thirteen',
            14                  => 'Fourteen',
            15                  => 'Fifteen',
            16                  => 'Sixteen',
            17                  => 'Seventeen',
            18                  => 'Eighteen',
            19                  => 'Nineteen',
            20                  => 'Twenty',
            30                  => 'Thirty',
            40                  => 'Fourty',
            50                  => 'Fifty',
            60                  => 'Sixty',
            70                  => 'Seventy',
            80                  => 'Eighty',
            90                  => 'Ninety',
            100                 => 'Hundred',
            1000                => 'Thousand',
            1000000             => 'Million',
            1000000000          => 'Billion',
            1000000000000       => 'Trillion',
            1000000000000000    => 'Quadrillion',
            1000000000000000000 => 'Quintillion'
        );

        if (!is_numeric($number)) {
            return false;
        }

        if (($number >= 0 && (int) $number < 0) || (int) $number < 0 - PHP_INT_MAX) {
            // overflow
            trigger_error(
                'convert_number_to_words Only Accepts Numbers Between -' . PHP_INT_MAX . ' And ' . PHP_INT_MAX,
                E_USER_WARNING
            );
            return false;
        }

        if ($number < 0) {
            return $negative . $this->convert_number_to_words(abs($number));
        }

        $string = $fraction = null;

        if (strpos($number, '.') !== false) {
            list($number, $fraction) = explode('.', $number);
        }

        switch (true) {
            case $number < 21:
                $string = $dictionary[$number];
                break;
            case $number < 100:
                $tens   = ((int) ($number / 10)) * 10;
                $units  = $number % 10;
                $string = $dictionary[$tens];
                if ($units) {
                    $string .= $hyphen . $dictionary[$units];
                }
                break;
            case $number < 1000:
                $hundreds  = $number / 100;
                $remainder = $number % 100;
                $string = $dictionary[$hundreds] . ' ' . $dictionary[100];
                if ($remainder) {
                    $string .= $conjunction . $this->convert_number_to_words($remainder);
                }
                break;
            default:
                $baseUnit = pow(1000, floor(log($number, 1000)));
                $numBaseUnits = (int) ($number / $baseUnit);
                $remainder = $number % $baseUnit;
                $string = $this->convert_number_to_words($numBaseUnits) . ' ' . $dictionary[$baseUnit];
                if ($remainder) {
                    $string .= $remainder < 100 ? $conjunction : $separator;
                    $string .= $this->convert_number_to_words($remainder);
                }
                break;
        }

        if (null !== $fraction && is_numeric($fraction)) {
            $string .= $decimal;
            $words = array();
            foreach (str_split((string) $fraction) as $number) {
                $words[] = $dictionary[$number];
            }
            $string .= implode(' ', $words);
        }

        return $string;
    }
}
