<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');
   //Text labels here
   define('BTN_DOWNLOADLOG', 'Download SMS');
   define('BTN_CLEARLOG', 'Clear SMS');


   define('LOGFILE_SMS', 'smsLog.txt');
   $SMSlog = $config['/var/www/html/smsLog.txt'];


   $cliCall = isCli();
   $showLog = true;
   if (!$cliCall && isset($_POST['action'])) {
   //Process any POST data
      switch($_POST['action']) {
         case 'showlog':
            $showLog = true;
            break;
         case 'downloadlog':
            if (file_exists(getSMSLog())) {
               header("Content-Type: text/plain");
               header("Content-Disposition: attachment; filename=\"" . date('Ymd-His-') . LOGFILE_SMS . "\"");
               readfile(getSMSLog());
               return;
            }
         case 'clearlog':
            if (file_exists(getSMSLog())) {
               unlink(getSMSLog());
            }
            break;
      }
   }

   function getSMSLog() {
      global $SMSlog;
      if ($SMSlog != "")
         return $SMSlog;
      else
         return LBASE_DIR . '/' . LOGFILE_SMS;
   }

   function isCli() {
       if( defined('STDIN') ) {
           return true;
       }
       if( empty($_SERVER['REMOTE_ADDR']) and !isset($_SERVER['HTTP_USER_AGENT']) and count($_SERVER['argv']) > 0) {
           return true;
       }
       return false;
   }

   function displayLog() {
      if (file_exists(getSMSLog())) {
         $logData = file_get_contents(getSMSLog());
         echo str_replace(PHP_EOL, '<BR>', $logData);
      } else {
         echo "No log data found";
      }
   }

   function mainHTML() {
      global $showLog;
      echo '<!DOCTYPE html>';
      echo '<html>';
         echo '<head>';
            echo '<meta name="viewport" content="width=550, initial-scale=1">';
            echo '<title>' . CAM_STRING . ' SMS</title>';
            echo '<link rel="stylesheet" href="css/style_minified.css" />';
            echo '<link rel="stylesheet" href="' . getStyle() . '" />';
            echo '<script src="js/style_minified.js"></script>';
            echo '<script src="js/script.js"></script>';
         echo '</head>';
         echo '<body onload="schedule_rows()">';
            echo '<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">';
               echo '<div class="container">';
                  echo '<div class="navbar-header">';
                     if ($showLog) {
                        echo '<a class="navbar-brand" href="index.php">';
                     }
                     echo '<span class="glyphicon glyphicon-chevron-left"></span>Back - ' . CAM_STRING . '</a>';
                  echo '</div>';
               echo '</div>';
            echo '</div>';

            echo '<div class="container-fluid">';
               echo '<form action="sms.php" method="POST">';
                  if ($showLog) {
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='downloadlog'>" . BTN_DOWNLOADLOG . "</button>";
                     echo "&nbsp&nbsp;<button class='btn btn-primary' type='submit' name='action' value='clearlog'>" . BTN_CLEARLOG . "</button><br><br>";
                     displayLog();
                  }
               echo '</form>';
            echo '</div>';
         echo '</body>';
      echo '</html>';
   }

   if (!$cliCall) {
      mainHTML();
   } else {
      mainCLI();
   }
?>
