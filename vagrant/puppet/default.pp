import "config.pp"

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/node/node-v0.10.25/bin/'] }

exec { 'apt_upgrade':
    command => 'apt-get upgrade -y',
    before => [ Exec['apt_autoremove'] ],
    require => [ Exec['apt_update'] ]
}

exec { 'apt_autoremove':
    command => 'apt-get -y autoremove'
}

package { ['gcc', 'make', 'python-software-properties',
           'vim', 'curl', 'git', 'mercurial', 'ruby', 'ruby1.9.1-dev', 'libmysqlclient-dev', 'phpmyadmin', 'ack-grep', 'acl', 'default-jre', 'cmake', 'mcrypt', 'libmcrypt-dev', 'poppler-utils'] :
    ensure  => present,
    install_options => [ '--force-yes' ]
}

package { ['sass', 'compass']:
  ensure => 'installed',
  provider => 'gem',
}


# ntp
#class { 'ntp':
#  runmode => 'cron',
#  cron_command => 'ntpdate 0.pool.ntp.org',
#}

# ssh priv key
# sshprivkey { '/home/vagrant/.ssh/id_rsa':
#   ensure => present,
#   user   => 'vagrant',
#   mailto => $git_user_email,
# }

file { '/etc/apt/sources.list.d/ondrej-php5-trusty.list':
  ensure => present,
  content => 'deb http://ppa.launchpad.net/ondrej/php5/ubuntu trusty main
deb-src http://ppa.launchpad.net/ondrej/php5/ubuntu trusty main',
  before => [ Exec['apt_update'] ]
}

class { 'apt':
  # always_apt_update    => true,
}

apt::key { 'ondrej-php5':
  key        => 'E5267A6C',
  key_server => 'keyserver.ubuntu.com',
}

#php
class { 'php':
  template => 'php/php.ini.erb',
  require => [ File['/etc/apt/sources.list.d/ondrej-php5-trusty.list'] ]
}


php::conf { 'php.ini-cli':
  path     => '/etc/php5/cli/php.ini',
  template => 'php/php.ini.erb',
}

php::module { 'common': }
php::module { 'dev': }
php::module { 'mysql': }
php::module { 'intl': }
php::module { 'cli': }
php::module { 'imagick': }
php::module { 'gd': }
php::module { 'mcrypt': }
php::module { 'curl': }
php::module { 'json': }
php::module { 'sqlite': }
php::module { 'imap': }
php::module { 'xdebug': }
php::module { 'apc':
  module_prefix => "php-"
}

file { '/etc/php5/cli/conf.d/20-imap.ini':
    ensure  => 'link',
    target  => '/etc/php5/conf.d/20-imap.ini',
}


file { '/etc/php5/mods-available/xdebug.ini':
    ensure => 'file',
    content => '
zend_extension=xdebug.so
xdebug.max_nesting_level=800
'
}
# php::pecl::module { "apn":
#   use_package     => 'false',
# }

exec {
  'curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer':
    cwd     => '/tmp',
    creates => '/usr/local/bin/composer',
    require => Class['php']
}

exec {
  'wget http://cs.sensiolabs.org/get/php-cs-fixer.phar -O /usr/local/bin/php-cs-fixer; chmod a+x /usr/local/bin/php-cs-fixer':
    creates => '/usr/local/bin/php-cs-fixer',
    require => Class['php']
}

php::pear::module { 'PHPUnit':
  repository  => 'pear.phpunit.de',
  alldeps => 'true',
  use_package => 'no',
}

# apache
class { 'apache':
  mpm_module => 'prefork',
  purge_configs => true,
  default_vhost => false
}

class {'::apache::mod::php':
  content => '
AddHandler php5-script .php
AddType text/html .php',
}

apache::listen { '8080': }


apache::vhost { 'demo-alba.dev':
  port          => '8080',
  docroot       => '/home/vagrant/demo-alba/web',
  priority      => 10,
  # docroot_owner => 'vagrant',
  # docroot_group => 'vagrant',

  directories => [
      {
        options        => ['Indexes','FollowSymLinks','MultiViews'],
        path           => '/home/vagrant/demo-alba/web',
        allow_override => 'None',
        rewrites      => [ {
            rewrite_cond => ['%{REQUEST_FILENAME} !-f'],
            rewrite_rule => ['^(.*)$ app_dev.php']
          }
        ]
      },
      {
        provider       => 'filesmatch',
        path           => "\.(ttf|otf|eot|woff)$",
        headers        => 'set Access-Control-Allow-Origin "*"'
      }
  ]
}

cron { "sendmails":
  command => "cd /home/vagrant/demo-alba && /usr/bin/php app/console swiftmailer:spool:send",
  user    => "vagrant",
  hour    => "*",
  minute  => "*"
}

apache::vhost { 'pma.demo-alba.dev':
  port         => '8080',
  docroot      => '/usr/share/phpmyadmin',
  directories => [
      {
        options        => ['Indexes','FollowSymLinks','MultiViews'],
        path           => '/usr/share/phpmyadmin',
        directoryindex => 'index.php'
      }
  ]
}

include apache::mod::rewrite

apache::mod { 'headers':
}



# mysql

class { '::mysql::server':
  root_password    => '123',
  override_options => {
    'mysqld' => {
      'max_connections' => '1024'
    }
  }
}

# bashrc

file { '/home/vagrant/.bashrc':
  ensure => file,
  path    => "/home/vagrant/.bashrc",
  content => template("home/.bashrc"),
  owner  => "vagrant",
  group  => "vagrant",
}


file { '/home/vagrant/.bash_aliases':
  ensure => file,
  path    => "/home/vagrant/.bash_aliases",
  content => template("home/.bash_aliases"),
  owner  => "vagrant",
  group  => "vagrant",
}


file { '/home/vagrant/.gitconfig':
  ensure => file,
  path    => "/home/vagrant/.gitconfig",
  content => template("home/.gitconfig"),
  owner  => "vagrant",
  group  => "vagrant",
}

# Node JS
class { 'nodejs':
  version => 'v0.10.25'
}

package { ['bower']:
  provider => npm,
  require  => [ Class['nodejs'] ]
}


## ssh
service { "ssh":
    ensure  => "running",
    enable  => "true",
}

file { '/etc/ssh/sshd_config':
  ensure => file,
  path    => "/etc/ssh/sshd_config",
  content => template("ssh/sshd_config.erb"),
  owner  => "root",
  group  => "root",
  notify  => Service["ssh"],
}

# Varnish
class { 'varnish':
  secret => 'd0743c0de-bdee-4ba3-99bc-3c7a41ffd94f',
  listen_port => 80

}

varnish::vcl { '/etc/varnish/default.vcl':
  content => template('varnish/default.vcl.erb'),
}
