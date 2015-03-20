<?php echo $this->Html->script("../app/jquery/jquery.textareaCounter.plugin.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.message.js", FALSE);?>

<style type="text/css">
    .originalTextareaInfo {
        font-size: 12px;
        color: #000000;
        font-family: Tahoma, sans-serif;
        text-align: right;
    }

    .warningTextareaInfo {
        font-size: 12px;
        color: #FF0000;
        font-family: Tahoma, sans-serif;
        text-align: right;
    }
</style>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-envelope fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage S.M.S and e-mails Sending for <?php echo ($type === 'STF') ? 'Staffs' : 'Parents'?></h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-envelope-o"></i>
               Messaging Center
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-8 col-md-offset-2">
                <div class="panel-body">
                    <div class="panel panel-default">
                        <div class="panel-heading bg-primary-dark text-white"><i class="fa fa-envelope-o fa-1x"></i> S.M.S / e-mail Message Form for <?php echo ($type === 'STF') ? 'Staffs' : 'Parents'?></div>
                        <div class="panel-body">
                            <?php 
                                //Creates The Form
                                echo $this->Form->create('Send', array(
                                        'class' => 'form-horizontal'
                                    )
                                );     
                            ?>

                                <div class="form-group">
                                    <label for="subject" class="col-lg-3 col-md-3 control-label">Message Subject</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[Send][subject]" 
                                               id="subject" maxlength="11" placeholder="Message Subject" required="required">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="subject" class="col-lg-3 col-md-3 control-label">Sending Options</label>
                                    <div class="col-lg-7 col-md-9">
                                        <div class="radio">
                                            <label><input type="radio" name="data[Send][option]" id="sms" value="1">S.M.S Only</label>
                                        </div>
                                        <div class="radio">
                                            <label><input type="radio" name="data[Send][option]" id="sms_email" value="2" checked="checked">S.M.S and e-mail</label>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="message" class="col-lg-3 col-md-3 control-label">Message Body</label>
                                    <div class="col-lg-7 col-md-9">
                                        <textarea rows="7" class="form-control form-cascade-control input-small" name="data[Send][message]" 
                                        id="message" placeholder="Message Body" required="required"></textarea>
                                    </div>
                                </div>
                                <div class="form-group"><br><br>
                                    <div class="col-sm-offset-2 col-sm-9">
                                        <button type="submit" class="btn btn-success">Send Message</button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>