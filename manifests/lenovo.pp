class hardware_check::lenovo () inherits hardware_check::params {

 #   if ($facts['disks']['sda']['model'])== /MR*/ {
   
 file { "/opt/MegaRAID":
       source => "puppet:///modules/$module_name/MegaRAID",
       recurse => true
   }
   
   file {'/etc/sudoers.d/sudo_megaraid' :
       mode    => '0644',
       owner   => 'root',
       group   => 'root',
       content => "NRPE     ALL=(ALL)       NOPASSWD: /usr/lib64/nagios/plugins/check_megaraid_sas\n"
    }
 

  ### setup nagios plugin
  $plugin_dir = '/usr/lib64/nagios/plugins'
  $nrpe_cfg_dir = '/etc/nrpe.d'
  if $hardware_auto_nagios_enable { 
  
  file { "${nrpe_cfg_dir}/check_megaraid_sas.cfg":
    source  => "puppet:///modules/${module_name}/check_megaraid_sas.cfg",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }
  
file { "${plugin_dir}/check_megaraid_sas":
    source  => "puppet:///modules/${module_name}/check_megaraid_sas",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
   }


  @@nagios_service { "check_raid${::fqdn}":
    check_command           => 'check_nrpe!check_megaraid_sas',
    host_name               => $::fqdn,
    servicegroups           => 'raid',
    service_description     => 'Raid Check',
    use                     => 'hourly-service',
    notifications_enabled   => $check_raid_notification,
    target                  => "/etc/nagios/nagios_services.d/${::fqdn}.cfg",
    tag                     => $nagios_server
  }

 }
#}
 
}
