<?php
/**
 * Application model for Cake.
 *
 * This file is application-wide model file. You can put all
 * application-wide model-related methods here.
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.Model
 * @since         CakePHP(tm) v 0.2.9
 */
date_default_timezone_set('Africa/Lagos');

App::uses('Model', 'Model');
App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');

//Email Sending
App::uses('CakeEmail', 'Network/Email');
//App::import('Vendor', 'PHPMailer', array('file' => 'PHPMailer/PHPMailerAutoload.php'));

/**
 * Application model for Cake.
 *
 * Add your application-wide methods in the class below, your models
 * will inherit them.
 *
 * @package       app.Model
 */
class AppModel extends Model {
    
    //Date And Time Format
    public function dateFormatBeforeSave($dateString = null) {
        return ($dateString !== null) ? date('Y-m-d h:i:s', strtotime($dateString)) : date('Y-m-d h:i:s');
    }
    
    //Date Format
    public function dateFormat($dateString = null) {
        return ($dateString !== null) ? date('Y-m-d', strtotime($dateString)) : date('Y-m-d');
    }
    
    //Format The SQL Databse Date To e.g Wenesday, 5th Novermber, 2014 
    public function SQLDateToPHP($dateString = null) {
        $date = DateTime::createFromFormat('Y-m-d', $dateString);
        return ($dateString !== null) ? $date->format('D, jS M, Y') : date('D, jS M, Y');
    }
    
    
//    public function createNewUser($username, $first_name, $other_name, $id, $img, $role=1){
//        $user = ClassRegistry::init('User');
//        $passwordHasher = new BlowfishPasswordHasher();
//        $user->query('INSERT INTO users(username, password, display_name, type_id, group_alias, image_url, user_role_id, created_by, created_at, updated_at) VALUES('
//            . '"'. trim(strtolower($username)).'",'
//            . '"'. $passwordHasher->hash('Password1') .'",'
//            . '"'. trim(strtoupper($first_name . ', ' . ucwords($other_name))) .'",'
//            . '"'. $id .'",'
//            . '"web_users",'
//            . '"'. $img .'",'
//            . '"'. $role .'",'
//            . '"'. AuthComponent::user('type_id') .'",'
//            . '"'. $this->dateFormatBeforeSave() .'",'
//            . '"'. $this->dateFormatBeforeSave() .'")');
//    }      
    //Access Control List ACL ARO Groups
    public function createAROGroups() {
        //$aro = $this->Acl->Aro;
        $aro = new Aro();
        // Here's all of our group info in an array we can iterate through
        $groups = array(
            0 => array(
                'alias' => 'expired_users'
            ),
            1 => array(
                'alias' => 'web_users'
            ),
            2 => array(
                'alias' => 'app_users'
            ),
            3 => array(
                'alias' => 'admin_users'
            ),
        );
        // Iterate and create ARO groups
        foreach ($groups as $data) {
            // Remember to call create() when saving in loops...
            $aro->create();
            // Save data
            $aro->save($data);
        }
    }
    
    //Access Control List ACL ARO Users
    public function createAROUser($alias=Null, $parent_id=1, $foreign_key=NULL) {
        $aro = new Aro();
        // Here are our user records, ready to be linked to new ARO records.
        // This data could come from a model and be modified, but we're using static
        // arrays here for demonstration purposes.
        $users = array(            
            'alias' => $alias,
            'parent_id' => $parent_id,
            'model' => 'User',
            'foreign_key' => $foreign_key,
        );
        // Remember to call create() when saving in loops...
        $aro->create();
        //Save data
        $aro->save($users);
    }
    
    //Access Control List ACL ACO Users
    public function createACOControllers($alias=Null, $parent_id=1, $model=NULL, $foreign_key=NULL) {
        $aro = new Aro();
        // Here are our user records, ready to be linked to new ARO records.
        // This data could come from a model and be modified, but we're using static
        // arrays here for demonstration purposes.
        $users = array(            
            'alias' => $alias,
            'parent_id' => $parent_id,
            'model' => $model,
            'foreign_key' => $foreign_key,
        );
        // Remember to call create() when saving in loops...
        $aro->create();
        //Save data
        $aro->save($users);
    }
    
    //Send Mail
    function sendMail($message, $subject, $to, $name = null) {
        $Email = new CakeEmail();
        //$Email = new CakeEmail(array('from' => 'me@example.org', 'transport' => 'Mail'));
        //$Email->addHeaders(array('X-Mailer' => 'My Cool App (http://crithinks.com)'));
        //$Email->helpers(array('Html', 'Text'));
        $Email->config('smtp')
            ->viewVars( array('subject' => $subject, 'name'=>$name))
            ->template('default')
            ->emailFormat('html')
            ->from(array(DEVELOPER_SITE_EMAIL => DEVELOPER_SITE_NAME))
            ->to($to)
            //->to('kheengz@gmail.com')
            ->subject($subject);
        return ($Email->send($message)) ? "Mail Delivered!" : "Mail Not Delivered... Mail Error: ";
    }
    
//    function sendMail($message, $messge_subject, $to, $name = null){
//        $admin_email = 'crithink@crithinks.com';
//        $admin_name = 'Crithinks SmartSchool App';
//        
//        //Create a new PHPMailer instance
//        $mail = new PHPMailer;
//        //Tell PHPMailer to use SMTP
//        $mail->isSMTP();
//        //Enable SMTP debugging
//        // 0 = off (for production use)
//        // 1 = client messages
//        // 2 = client and server messages
//        //$mail->SMTPDebug = 2;
//        //Ask for HTML-friendly debug output
//        //$mail->Debugoutput = 'html';
//        //Set the hostname of the mail server
//        $mail->Host = "crithinks.com";
//        //Set the SMTP port number - likely to be 25, 465 or 587
//        $mail->Port = 25;
//        //Whether to use SMTP authentication
//        $mail->SMTPAuth = true;
//        //Username to use for SMTP authentication
//        $mail->Username = "crithink";
//        //Password to use for SMTP authentication
//        $mail->Password = "Student_1";
//        //Set who the message is to be sent from
//        $mail->setFrom($admin_email, $admin_name);
//        //Set an alternative reply-to address
//        $mail->addReplyTo($admin_email, $admin_name);
//        //Set who the message is to be sent to
//        $mail->addAddress($to, $name);
//        //Set the subject line
//        $mail->Subject = $messge_subject;
//        //Read an HTML message body from an external file, convert referenced images to embedded,
//        //convert HTML into a basic plain-text alternative body
//        $message_body = '<html><body><h4>'.$messge_subject.'</h4><p>'.$message.'</p>';
//        $message_body .= '<br><a href="'. DOMAIN_NAME.'/dashboard">
//                        <span class="logo small">Smart<img src="'.APP_DIR_ROOT.'images/icon.png" />School App</span>
//                    </a></body></html>';
//        $mail->msgHTML(nl2br($message_body));
//
//        //$mail->Body = 'This is a Test message body';
//        
//        //Replace the plain text body with one created manually
//        $mail->AltBody = nl2br($message_body);
//        //Attach an image file
//        //$mail->addAttachment('images/phpmailer_mini.png');
//        
//        //send the message, check for errors
//        if (!$mail->send()) {
//            return "Mail Not Delivered... Mailer Error: " . $mail->ErrorInfo;
//        } else {
//            return "Mail Delivered!";
//        }
//    }
    
    //Send SMS
    function SendSMS($mobile_no, $msg_sender, $msg_body) {
        if(substr($mobile_no, 0, 1) === '0'){
            $no = '234' . substr ($mobile_no, 1);
        }elseif (substr($mobile_no, 0, 3) === '234') {
            $no = $mobile_no;
        }else{
            $no = '234' . $mobile_no;
        }
        $message = urlencode($msg_body);
        $user = "ZumaComm";
        $password = "zuma123456";
        $from = $msg_sender;
        // auth call
        $url = "http://107.20.195.151/mcast_ws/?user=$user&password=$password&from=$from&to=$no&message=$message";
        // do auth call
        $ret = file($url);
        return $ret;
    }
}
