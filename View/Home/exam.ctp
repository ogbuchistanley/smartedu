<?php echo $this->Html->script("../app/jquery/custom.home.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

    <div class="col-md-12">
        <div class="panel">
            <div class="panel-heading text-primary">
                <h3 class="panel-title">
                    <i class="fa fa-folder-open"></i> Exam Scores (Terminal and Annual)
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
                </h3>
            </div>

            <div class="panel-body">
                <div class="col-md-6 col-md-offset-1">
                    <div class="panel panel-cascade">
                        <div class="panel-body">
                            <div class="panel panel-default">
                                <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search For The Academic Term</div>
                                <div class="panel-body">
                                    <?php
                                    //Creates The Form
                                        echo $this->Form->create('SearchStudent', array(
                                                'class' => 'form-horizontal',
                                                'id' => 'search_student_sponsor_form'
                                            )
                                        );
                                    ?>
                                    <div class="form-group">
                                        <label for="academic_year_id" class="col-sm-4 control-label">Academic Years</label>
                                        <div class="col-sm-8">
                                            <?php
                                                echo $this->Form->input('academic_year_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'id' => 'academic_year_id',
                                                        'class' => 'form-control',
                                                        'required' => "required",
                                                        'selected' => $term_id->getCurrentYearID(),
                                                        'options' => $AcademicYears,
                                                        'empty' => '(Select Academic Year)'
                                                    )
                                                );
                                            ?>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="academic_term_id" class="col-sm-4 control-label">Academic Terms</label>
                                        <div class="col-sm-8">
                                            <select class="form-control" name="data[SearchStudent][academic_term_id]" id="academic_term_id" required="required">
                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                            </select>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <div class="col-sm-offset-2 col-sm-10">
                                            <button type="submit" class="btn btn-info">Search</button>
                                        </div>
                                    </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4" id="msg_box"> </div>
                <div class="col-md-10 col-md-offset-1">
                    <div style="overflow-x: scroll" class="panel-body">
                        <table  class="table table-bordered table-hover table-striped display" id="search_students_table" >

                        </table>
                    </div>
                </div>
                </div>
            </div>
        </div>
    </div>