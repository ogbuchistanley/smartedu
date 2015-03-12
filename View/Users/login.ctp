
<?php  echo $this->Html->script("../app/jquery/custom.user.js", FALSE); ?>
<section id="login">
    <div class="row animated fadeILeftBig">
         <div class="login-holder col-md-6 col-md-offset-3">
           <h2 class="page-header text-center text-primary"> <?php echo substr(APP_NAME, 0, 5)?><img src="<?php echo APP_DIR_ROOT; ?>images/icon.png" /><?php echo substr(APP_NAME, 5)?> </h2>
           <div class="row">
                <noscript>
                    <div style="margin:0 0 35px 0; text-align:center" class="alert alert-danger">
                      <h4> <strong><i class="icon-warning-sign"></i> Attention!!!</strong></h4>
                       Javascript is not enabled on this browser. To enjoy this application, turn on Javascript or use another
                      <i>Javascript enabled browser.</i>
                    </div>  
                </noscript>
            </div>
            
            <?php 
                // Authetication Message
                $va = $this->Session->flash('auth');
                if(!empty($va)) {
                    echo '<div class="alert alert-danger">', $va, '</div>'; 
                }            
                // Flash Messages
                echo $this->Session->flash(); 
                //Creates The Form
                echo $this->Form->create('User', array(
                        'action' => 'login',
                        'id' => 'login_form',
                        'role' => 'form',
                    )
                );  
            ?>
           <!--form role="form" action="/smartschool/users/login" method="post"-->               
            <div class="form-group">
              <input type="text" name="data[User][username]" id="UserUsername" class="form-control" placeholder="Username" required>
            </div>
            <div class="form-group">
              <input type="password" name="data[User][password]" id="UserPassword" class="form-control" placeholder="Password" required>
            </div>
            <div class="form-footer">
              <label>
                <input type="checkbox" id="input-checkbox" value="0" >  <i class="fa fa-check-square-o input-checkbox fa-square-o"></i> Remember me?
              </label>
              <button type="submit" class="btn btn-info pull-right btn-submit">Login</button>
            </div>

          </form>
        </div>
      </div>
       </section>
        <section id="forgot-password" style="background:#2F4051;">
            <div class="row animated fadeILeftBig">
                <div class="login-holder col-md-6 col-md-offset-3">
                    <h2 class="page-header text-center text-primary">  <?php echo substr(APP_NAME, 0, 5)?><img src="<?php echo APP_DIR_ROOT; ?>images/icon.png" /><?php echo substr(APP_NAME, 5)?> </h2>
                    <div class="alert alert-info" id="msg_box">Enter Your Valid Username</div>
                    <?php
                        // Flash Messages
                        echo $this->Session->flash(); 
                        //Creates The Form
                        echo $this->Form->create('User', array(
                                'id' => 'forget_password_form',
                                'role' => 'form',
                            )
                        );  
                    ?>
                        <div class="form-group">
                            <input type="text" name="data[User][username]" class="form-control" id="username" placeholder="Enter Username" required>
                        </div>
                        <div class="form-footer">
                          <button type="submit" class="btn btn-info pull-right btn-submit">Send Instructions</button>
                        </div>
                    </form>
                </div>
            </div>
        </section>