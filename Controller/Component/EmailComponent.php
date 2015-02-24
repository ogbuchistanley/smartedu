<?php
 
App::uses('Component', 'Controller');
App::import('Vendor', 'PHPMailer', array('file' => 'PHPMailer/PHPMailerAutoload.php'));

class EmailComponent extends Component {
 
  public function send($to, $subject, $message) {
    $sender = "crithink@crithinks.com"; // this will be overwritten by GMail
 
    //$header = "X-Mailer: PHP/".phpversion() . "Return-Path: $sender";
 
    $mail = new PHPMailer();
 
    $mail->IsSMTP();
    $mail->Host = "crithinks.com";
    $mail->SMTPAuth = true;
    $mail->SMTPSecure = "ssl";
    $mail->Port = 465;
    $mail->SMTPDebug  = 2; // turn it off in production
    $mail->Username   = "crithink"; 
    $mail->Password   = "Student_1";
     
    $mail->From = $sender;
    $mail->FromName = "Crithinks";
 
    $mail->AddAddress($to);
 
//    $mail->IsHTML(true);
//    $mail->CreateHeader($header);
 
    $mail->Subject = $subject;
    $mail->Body    = nl2br($message);
    $mail->AltBody = nl2br($message);
 
    // return an array with two keys: error & message
    if(!$mail->Send()) {
        echo 'Mailer Error: ' . $mail->ErrorInfo;
      //return array('error' => true, 'message' => 'Mailer Error: ' . $mail->ErrorInfo);
    } else {
        echo 'Message sent!';
      //return array('error' => false, 'message' =>  "Message sent!");
    }
  }
}

//  Email Usage
//                $to = $email;
//                $subject = 'Hi buddy, i got a message for you.';
//                $message = 'Nothing much. Just testing out my Email Component using PHPMailer.';
//                $mail = $this->Email->send($to, $subject, $message);
                //$this->set('mail', $mail);
                //$this->render(false);
 
?>