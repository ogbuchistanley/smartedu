
<?php
/**
 *
 *
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.View.Emails.html
 * @since         CakePHP(tm) v 0.10.0.1076
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */
    //$this->Helpers->load('EmailProcessing');
?>

    <h3><strong>Hi, <i><?php echo $name; ?></i></h3>
    <p class="lead" style="margin-bottom: 10px; font-weight: normal; font-size:17px; line-height:1.6;">
        <?php
            $content = explode("\n", $content);

            foreach ($content as $line):
                echo '<p> ' . $line . "</p>\n";
            endforeach;
        ?>
    </p>
    <!--div class="col-md-4 col-md-offset-1">
        <h3 style="color: #1c94c4"><?php //echo $subject;?></h3>
        <p>
            <br><strong>Dear <i><?php //echo $name; ?></i></strong>,
        </p>
        <?php
//            $content = explode("\n", $content);
//
//            foreach ($content as $line):
//                echo '<p> ' . $line . "</p>\n";
//            endforeach;
        ?>
    </div>