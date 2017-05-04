class hardware_check::dell () inherits hardware_check::params {
        

  file { 'dell-omsa-repository':
          source     => "puppet:///modules/${module_name}/dell-omsa-repository.repo",
          path       => '/etc/yum.repos.d/dell-omsa-repository.repo',
          ensure     => present,
          mode       => '0444',
          owner      => 'root',
          group      => 'root',
       }

  # Its a bug with openmanage software http://www.dell.com/support/article/us/en/19/SLN266217/EN
  file { 'CheckSystemType':
          source     => "puppet:///modules/${module_name}/CheckSystemType",
          path       => '/opt/dell/srvadmin/sbin/CheckSystemType',
          ensure     => present,
          mode       => '0755',
          owner      => 'root',
          group      => 'root',
          subscribe  => Package['srvadmin-omcommon'],
       }
     
  package { 'srvadmin-storageservices' : 
          ensure     => installed, 
          require    => File['dell-omsa-repository'],
       }
  package { 'srvadmin-omcommon' :
          ensure     => installed,
          require    => File['dell-omsa-repository'],
       }
  
  service {'dataeng':
          ensure     => true,
          enable     => true,
          hasstatus  => true,
          hasrestart => true,
          subscribe  => Package['srvadmin-storageservices', 'srvadmin-omcommon'], 
          }  
  ### setup nagios plugin
  $plugin_dir = '/usr/lib64/nagios/plugins'
  $nrpe_cfg_dir = '/etc/nrpe.d'
  if $hardware_auto_nagios_enable { 
  
  file { "${plugin_dir}/check_openmanage":
    source  => "puppet:///modules/${module_name}/check_openmanage",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }

  # /etc/nrpe.d/check_openmanage.cfg file is defined by nagios module
  
  file { "${nrpe_cfg_dir}/check_hardware.cfg":
    content => template('hardware_check/check_hardware.cfg'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }
   
   file { "${nrpe_cfg_dir}/check_raid.cfg":
    content => template('hardware_check/check_raid.cfg'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }
   
   file { "${plugin_dir}/check_raid":
    source  => "puppet:///modules/${module_name}/check_raid",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }
  
 
  @@nagios_service { "check_hardware${::fqdn}":
    check_command           => 'check_nrpe!check_hardware',
    host_name               => $::fqdn,
    servicegroups           => 'hardware',
    service_description     => 'Hardware Check',
    use                     => '12hour-service',
    target                  => "/etc/nagios/nagios_services.d/${::fqdn}.cfg",
    notifications_enabled   => $check_hardware_notification,
    tag                     => $nagios_server
  }

  @@nagios_service { "check_raid${::fqdn}":
    check_command           => 'check_nrpe!check_raid',
    host_name               => $::fqdn,
    servicegroups           => 'hardware',
    service_description     => 'Raid Check',
    use                     => 'hourly-service',
    notifications_enabled   => $check_raid_notification,
    target                  => "/etc/nagios/nagios_services.d/${::fqdn}.cfg",
    tag                     => $nagios_server
  }

 }

 
}
