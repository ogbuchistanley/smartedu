<?php //echo 'ID=', $id, '<br>Encrpt=', $en, '<br>base=', $base?>
<?php
/**
 *
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.View.Errors
 * @since         CakePHP(tm) v 0.10.0.1076
 */
?>
<?php //echo $this->Html->css("../app/css/404.css", FALSE);?>
</style>
<div class="col-md-12">
    <div class="row error_page">
        <div class="col-md-7 col-md-offset-3 widget-holder text-white">
            <i class="fa <?php echo $icon;?> text-warning fa-5x"></i> 
            <h1 class="page-header text-warning"> <label class="label">Error Codes - <?php echo $code;?></label>  <?php echo $msg;?></h1>
            <p>	Sorry, the action you are about to perform is restricted or invalid. 
                If you the issues persist please contact your administrator or superior?</p>
        </div>
    </div>
</div>

