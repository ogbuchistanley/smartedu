<?php echo $this->Html->script("../app/jquery/custom.clone.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
    <div class="col-md-12">
        <div class="panel">
             <div class="panel-heading text-primary">
                <h3 class="panel-title">
                    <i class="fa fa-copy"></i> Cloning of Subjects Assigned To Class Room And Subjects Assigned To Teachers
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
                </h3>
            </div>
            <div class="panel-body">
                <div class="panel panel-default">
                    <div class="panel-body">
                        <ul id="myTab" class="nav nav-tabs">
                            <li class="active">
                                <a href="<?php echo DOMAIN_NAME ?>/clones/index#class" data-toggle="tab"><b><i class="fa fa-building"></i> Subjects To Class Room And Teachers</b></a>
                            </li>
                        </ul>
                        <div id="myTabContent" class="tab-content">
                            <div class="tab-pane fade in active" id="class"><br>
                                <div class="col-md-5">
                                    <div class="panel panel-cascade">
                                        <div class="panel-body">
                                            <div class="panel panel-default">
                                                <div class="panel-heading"><i class="fa fa-copy"></i> Clone Records From Academic Term</div>
                                                <div class="panel-body">
                                                    <?php
                                                    //Creates The Form
                                                    echo $this->Form->create('CloneClass', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'clone_class_form'
                                                        )
                                                    );
                                                    ?>
                                                    <div class="form-group">
                                                        <label for="academic_year_from_id" class="col-sm-5 control-label">Academic Years</label>
                                                        <div class="col-sm-7">
                                                            <?php
                                                            echo $this->Form->input('academic_year_from_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'academic_year_from_id',
                                                                    'required' => "required",
                                                                    'options' => $AcademicYears,
                                                                    'empty' => '(Select Academic Year)'
                                                                )
                                                            );
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="academic_term_from_id" class="col-sm-5 control-label">Academic Terms</label>
                                                        <div class="col-sm-7">
                                                            <select class="form-control" name="data[CloneClass][academic_term_from_id]" id="academic_term_from_id" required="required">
                                                                <option value=""></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-2">
                                    <div style="text-align: center" class="form-group">
                                        <br><i class="fa fa-long-arrow-right fa-4x"></i>
                                        <br><i class="fa fa-copy fa-4x"></i>
                                        <br><i class="fa fa-long-arrow-right fa-4x"></i>
                                        <div class="col-sm-10">
                                            <button type="submit" class="btn btn-info">Clone Records</button>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-5">
                                    <div class="panel panel-cascade">
                                        <div class="panel-body">
                                            <div class="panel panel-default">
                                                <div class="panel-heading"><i class="fa fa-copy"></i> Clone Records To Academic Term</div>
                                                <div class="panel-body">
                                                    <div class="form-group">
                                                        <label for="academic_year_to_id" class="col-sm-5 control-label">Academic Years</label>
                                                        <div class="col-sm-7">
                                                            <?php
                                                            echo $this->Form->input('academic_year_to_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'academic_year_to_id',
                                                                    'required' => "required",
                                                                    'options' => $AcademicYears,
                                                                    'empty' => '(Select Academic Year)'
                                                                )
                                                            );
                                                            ?>
                                                        </div><br>
                                                    </div><br>
                                                    <div class="form-group">
                                                        <label for="academic_term_to_id" class="col-sm-5 control-label">Academic Terms</label>
                                                        <div class="col-sm-7">
                                                            <select class="form-control" name="data[CloneClass][academic_term_to_id]" id="academic_term_to_id" required="required">
                                                                <option value=""></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    </form>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6 col-md-offset-3" id="msg_box1"> </div>
                            </div>
                            <div class="tab-pane fade in" id="teacher"><br>

                                <div class="col-md-5" id="msg_box_2">     </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- Modal For Cloning Subjects Assigned in a class level or class room-->
        <div id="clone_class_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <div class="col-md-12 alert alert-warning" id="clone_class_output"></div>
            </div>
            <?php
                //Creates The Form
                echo $this->Form->create('Clones', array(
                        'action' => 'cloning',
                        'class' => 'form-horizontal',
                        'id' => 'clone_class_confirm_form'
                    )
                );
            ?>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-12">
                            <h4 style="color: orangered">
                                Are You Really Sure You Want To Clone Subjects Assigned To The Class Room And Teachers<br>
                                <i class="fa fa-warning fa-2x"></i>
                                <i class="fa fa-warning fa-2x"></i>
                                <i class="fa fa-warning fa-2x"></i>
                            </h4>
                            <input type="hidden" name="data[Clones][from_term_id]" id="from_term_id">
                            <input type="hidden" name="data[Clones][to_term_id]" id="to_term_id">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                    <button type="submit" class="btn btn-primary">Yes Clone</button>
                </div>
            </form>
        </div><!-- /Modal For Cloning Subjects Assigned in a class level or class room-->


    </div>
<?php
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/clones/index\"]", 1);
    ');
?>