<?php
$defaults['moodle']['summary'] = 'Moodle Test Site! '; // for core settings
$defaults['moodle']['noreplyaddress'] = 'sophia-mailer@mail.ct.utfpr.edu.br';
$defaults['moodle']['custommenuitems'] = 'Tema
-Academi | https://mytesturl/?theme=academi
-Adaptable | https://mytesturl/?theme=adaptable
-Boost | https://mytesturl/?theme=boost
-Clássico | https://mytesturl/?theme=classic
-Eguru | https://mytesturl/?theme=eguru
-Fordson | https://mytesturl/?theme=fordson
-Klass | https://mytesturl/?theme=klass
-Moove | https://mytesturl/?theme=moove
Criação de curso | https://mytesturl/course/request.php
';

$defaults['moodle']['timezone'] = 'America/Sao_Paulo';
$defaults['moodle']['defaultcity'] = 'Curitiba';

$defaults['moodle']['pathtophp'] = '/usr/bin/php';
$defaults['moodle']['pathtodu'] = '/usr/bin/du';
$defaults['moodle']['aspellpath'] = '/usr/bin/aspell';
$defaults['moodle']['pathtogs'] = '/usr/bin/gs';
$defaults['moodle']['pathtodot'] = '/usr/bin/dot';
$defaults['moodle']['pathtopython'] = '/usr/bin/python3';

$defaults['moodle']['auth_instructions'] = 'Usuário: admin
Senha: myadmpass';
$defaults['moodle']['forcelogin'] = 1;

// $defaults['moodle']['converter_plugins_sortorder'] = 'unoconv'; // Not worked fileconverter_unoconv

$defaults['backup']['backup_auto_active'] = 2; // Manual
$defaults['backup']['backup_auto_storage'] = 2; // Save on backup area and external location
$defaults['backup']['backup_auto_destination'] = '/mnt/mdl/bkp/auto';
$defaults['backup']['backup_auto_skip_modif_prev'] = 0; // 
