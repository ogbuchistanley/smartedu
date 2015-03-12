<?php
App::uses('AppController', 'Controller');
App::uses('Folder', 'Utility');
/**
 * Setups Controller
 *
 * @property AcademicYear $AcademicYear
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */

class SetupsController extends AppController {

    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }

    public function setup(){
        $Setup = ClassRegistry::init('Setup');
        if ($this->request->is('post')) {
            $Setup->create();
            $data = $this->request->data['Setup'];
            if ($Setup->save($data)) {
                $this->setFlashMessage('The School '.$data['school_name'].' has been Setup.', 1);

                // Copy the project and all its contents into the new folder
                $smartedu = new Folder('/Applications/XAMPP/xamppfiles/htdocs/smartedu/');
                $smartedu->copy('/Applications/XAMPP/xamppfiles/htdocs/' . $data['subdomain']);

                $sql_dump = '/Applications/XAMPP/xamppfiles/htdocs/smartedu/database_empty.sql';
                $db_file = '/Applications/XAMPP/xamppfiles/htdocs/'.$data['subdomain'].'/Config/database.php';
                $domain_file = '/Applications/XAMPP/xamppfiles/htdocs/'.$data['subdomain'].'/domain.config.php';
                $dbname = $data['subdomain'];

                // overwrite the cakephp database file with the new database name
                $this->overwriteDBFile($db_file, $dbname);
                // overwrite the domain config file with the new domain name
                $this->overwriteDomainFile($domain_file, $dbname);
                // Create all the sql objects needed to run the application
                $this->createDBObjects($sql_dump, $dbname);

            } else {
                $this->setFlashMessage('The School could not be Setup. Please, try again.', 2);
            }
            return $this->redirect(array('controller' => 'home', 'action' => 'index'));
        }

    }

    private function cloneProject($src, $dst) {
        $dir = opendir($src);
        @mkdir($dst);
        while(false !== ( $file = readdir($dir)) ) {
            if (( $file != '.' ) && ( $file != '..' )) {
                if ( is_dir($src . '/' . $file) ) {
                    $this->clone_project($src . '/' . $file,$dst . '/' . $file);
                }
                else {
                    copy($src . '/' . $file,$dst . '/' . $file);
                }
            }
        }
        closedir($dir);
    }

    private function overwriteDBFile($file, $dbname){
        $content = '<?php
                        class DATABASE_CONFIG {

                            public $default = array(
                                "driver" => "mysqli",
                                "datasource" => "Database/Mysql",
                                "persistent" => false,
                                "host" => "localhost",
                                "login" => "root",
                                "password" => "",
                                "database" => "'.$dbname.'"
                            );
                        }
                    ?>';
        file_put_contents($file, $content);
    }

    private function overwriteDomainFile($domain_file, $domain_name){
        $content = '<?php
                        if (!defined("DOMAIN_NAME")) {
                            define("DOMAIN_NAME", "/'.$domain_name.'");
                        }

                        if (!defined("DOMAIN_URL")) {
                            define("DOMAIN_URL", "http://localhost/'.$domain_name.'");
                        }
                    ?>';
        file_put_contents($domain_file, $content);
    }

    private function createDBObjects($filename, $mysql_database){
        // MySQL host
        $mysql_host = 'localhost';
        // MySQL username
        $mysql_username = 'root';
        // MySQL password
        $mysql_password = '';

        $link = mysql_connect($mysql_host, $mysql_username, $mysql_password) or die('Error connecting to MySQL server: ' . mysql_error());

        $temp = 'CREATE DATABASE IF NOT EXISTS ' . $mysql_database . ' DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;';
        mysql_query($temp) or print('Error performing query \'<strong>' . $temp . '\': ' . mysql_error() . '<br /><br />');
        $temp = 'USE ' . $mysql_database . ';';
        mysql_query($temp) or print('Error performing query \'<strong>' . $temp . '\': ' . mysql_error() . '<br /><br />');

        // Temporary variable, used to store current query
        $templine = '';
        // Read in entire file
        $lines = file($filename);
        // Check Variable, used to know when its a function or procedure
        $check = false;

        // Loop through each line
        foreach ($lines as $line) {
            // Skip it if it's a comment or blank space
            if (substr($line, 0, 2) === '--' || $line === '')
                continue;

            // Skip it if it's a DELIMITER keyword
            if (substr($line, 0, 9) === 'DELIMITER')
                continue;

            // if its a Function or Procedure start a new query then Reset temp variable to empty
            if (substr(trim($line), 0, 16) === 'CREATE PROCEDURE' || substr(trim($line), 0, 15) === 'CREATE FUNCTION') {
                $templine = '';
                $check = true;
            }


            // If it has a dollar at the end, it's the end of the query then its a Function or Procedure
            if (substr(trim($line), -1, 1) === '$') {
                //Remove the last double dollar sign in the line
                $templine .= substr(trim($line), 0, strlen(trim($line)) - 2);
                // Perform the query
                mysql_query($templine) or print('Error performing query \'<strong>' . $templine . '\': ' . mysql_error() . '<br /><br />');
                // Reset temp variable to empty
                $templine = '';
                $check = false;

            } else {
                // else concatenate the line with the temp
                $templine .= $line;
                // If it has a semicolon at the end, it's the end of the query
                if (substr(trim($line), -1, 1) === ';' && $check === false) {
                    // Perform the query
                    mysql_query($templine) or print('Error performing query \'<strong>' . $templine . '\': ' . mysql_error() . '<br /><br />');
                    // Reset temp variable to empty
                    $templine = '';
                }
            }
        }
    }

}
