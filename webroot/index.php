<?php require_once '../domain.config.php';?>
<?php
/**
 * Index
 *
 * The Front Controller for handling every request
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.webroot
 * @since         CakePHP(tm) v 0.2.9
 */

/**
 * Use the DS to separate the directories in other defines
 */
if (!defined('DS')) {
	define('DS', DIRECTORY_SEPARATOR);
}


/**
 * These defines should only be edited if you have CakePHP installed in
 * a directory layout other than the way it is distributed.
 * When using custom settings be sure to use the DS and do not add a trailing DS.
 */

/**
 * The full path to the directory which holds "app", WITHOUT a trailing DS.
 *
 */
if (!defined('ROOT')) {
	define('ROOT', dirname(dirname(dirname(__FILE__))));
}

/**
 * The actual directory name for the "app".
 *
 */
if (!defined('APP_DIR')) {
	define('APP_DIR', basename(dirname(dirname(__FILE__))));
}

/**
 * The absolute path to the "cake" directory, WITHOUT a trailing DS.
 *
 * Un-comment this line to specify a fixed path to CakePHP.
 * This should point at the directory containing `Cake`.
 *
 * For ease of development CakePHP uses PHP's include_path. If you
 * cannot modify your include_path set this value.
 *
 * Leaving this constant undefined will result in it being defined in Cake/bootstrap.php
 *
 * The following line differs from its sibling
 * /app/webroot/index.php
 */

//Online Path
//define('CAKE_CORE_INCLUDE_PATH',  DS . 'home' . DS . 'crithink' . DS . 'cakephp' . DS . 'lib');
define('CAKE_CORE_INCLUDE_PATH', DS . 'Applications' . DS . 'XAMPP' . DS . 'xamppfiles' . DS . 'cakephp' . DS . 'lib');
//define('CAKE_CORE_INCLUDE_PATH', 'C:' . DS . 'wamp' . DS . 'cakephp' . DS . 'lib');

/**
 * Editing below this line should NOT be necessary.
 * Change at your own risk.
 *
 */
if (!defined('WEBROOT_DIR')) {
	define('WEBROOT_DIR', basename(dirname(__FILE__)));
}
if (!defined('WWW_ROOT')) {
	define('WWW_ROOT', dirname(__FILE__) . DS);
}

//////////////////   Custom Paths Constants   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
if (!defined('WEB_DIR_ROOT')) {
	define('WEB_DIR_ROOT', DS . APP_DIR . DS . WEBROOT_DIR . DS .'web' . DS);
}

if (!defined('APP_DIR_ROOT')) {
	define('APP_DIR_ROOT', DS . APP_DIR . DS . WEBROOT_DIR . DS .'app' . DS);
}

if (!defined('MAIL_DIR_ROOT')) {
	define('MAIL_DIR_ROOT', DS . APP_DIR . DS . WEBROOT_DIR . DS .'mail' . DS);
}



if (!defined('DEVELOPER_SITE_ADDRESS')) {
	define('DEVELOPER_SITE_ADDRESS', 'http://www.zumasoftware.net');
}

if (!defined('DEVELOPER_SITE_NAME')) {
	define('DEVELOPER_SITE_NAME', 'Zuma Software');
}

if (!defined('DEVELOPER_SITE_EMAIL')) {
	define('DEVELOPER_SITE_EMAIL', 'noreply@zumasoftware.net');
}



if (!defined('DOMAIN_NAME')) {
	define('DOMAIN_NAME', '/smartedu');
}

if (!defined('DOMAIN_URL')) {
	define('DOMAIN_URL', 'http://localhost/smartedu');
}

if (!defined('APP_NAME')) {
	define('APP_NAME', 'SmartEdu');
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// for built-in server
if (php_sapi_name() === 'cli-server') {
	if ($_SERVER['REQUEST_URI'] !== '/' && file_exists(WWW_ROOT . $_SERVER['PHP_SELF'])) {
		return false;
	}
	$_SERVER['PHP_SELF'] = '/' . basename(__FILE__);
}

if (!defined('CAKE_CORE_INCLUDE_PATH')) {
	if (function_exists('ini_set')) {
		ini_set('include_path', ROOT . DS . 'lib' . PATH_SEPARATOR . ini_get('include_path'));
	}
	if (!include 'Cake' . DS . 'bootstrap.php') {
		$failed = true;
	}
} else {
	if (!include CAKE_CORE_INCLUDE_PATH . DS . 'Cake' . DS . 'bootstrap.php') {
		$failed = true;
	}
}
if (!empty($failed)) {
	trigger_error("CakePHP core could not be found. Check the value of CAKE_CORE_INCLUDE_PATH in APP/webroot/index.php. It should point to the directory containing your " . DS . "cake core directory and your " . DS . "vendors root directory.", E_USER_ERROR);
}

App::uses('Dispatcher', 'Routing');

$Dispatcher = new Dispatcher();
$Dispatcher->dispatch(
	new CakeRequest(),
	new CakeResponse()
);




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////   Hosting Online Setup  ////////////////////////////////////////////////////////////
//if (!defined('ROOT')) {
//	define('ROOT', DS.'home'.DS.'crithink');
//}

/**
 * The actual directory name for the "app".
 *
 */
//if (!defined('APP_DIR')) {
//	define('APP_DIR', DS  . 'public_html');
//}
//
//define('CAKE_CORE_INCLUDE_PATH', DS . 'home' . DS . 'crithink' . DS . 'cakephp' . DS . 'lib');


/**
 * Editing below this line should NOT be necessary.
 * Change at your own risk.
 *
 */
//if (!defined('WEBROOT_DIR')) {
//	define('WEBROOT_DIR', basename(dirname(dirname(__FILE__))) . DS . 'public_html' . DS . 'webroot');
//}
//if (!defined('WWW_ROOT')) {
//	define('WWW_ROOT', APP_DIR . DS);
//}
//
//// Custom Paths Constants
//if (!defined('WEB_DIR_ROOT')) {
//	define('WEB_DIR_ROOT', DS . 'webroot' . DS .'web' . DS);
//}
//
//if (!defined('APP_DIR_ROOT')) {
//	define('APP_DIR_ROOT', DS . 'webroot' . DS .'app' . DS);
//}
//////////////////////////////////////////////  Parrallel Plesk  //////////////////////////////////////////////////
/*


/**
 * The full path to the directory which holds "app", WITHOUT a trailing DS.
 *
 */
//if (!defined('ROOT')) {
//	define('ROOT', 'G:' . DS . 'PleskVhosts' . DS . 'zumasoftware.net');
//}
//G:\PleskVhosts\zumasoftware.net\

/**
 * The actual directory name for the "app".
 *
 */

//if (!defined('APP_DIR')) {
//	define('APP_DIR', DS  . 'smartschool.zumasoftware.net');
//}


//Online Path
//define('CAKE_CORE_INCLUDE_PATH',  DS . 'home' . DS . 'crithink' . DS . 'cakephp' . DS . 'lib');
//define('CAKE_CORE_INCLUDE_PATH',  'G:' . DS . 'PleskVhosts' . DS . 'zumasoftware.net' . DS . 'cakephp' . DS . 'lib');

/**
 * Editing below this line should NOT be necessary.
 * Change at your own risk.
 *
 */
/*if (!defined('WEBROOT_DIR')) {
	define('WEBROOT_DIR', basename(dirname(dirname(__FILE__))) . DS . 'webroot');
}
if (!defined('WWW_ROOT')) {
	define('WWW_ROOT', APP_DIR . DS);
}  
*/