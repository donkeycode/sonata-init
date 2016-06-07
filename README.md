# Sonata init - First Install
<br />
1/ Go to vagrant/puppet<br />
2/ Transform config.pp.dist to config.pp<br />
3/ Change data with your informations (site name and ip address)<br />
   * line 9 :config.vm.hostname = "demo-alba.dev"<br>
   * line 10 : config.hostmanager.aliases = %w(pma.demo-alba.dev demo-alba.dev)<br>
   * line 33 : config.vm.network :private_network, ip: "10.10.10.12"<br>
   * line 50 : config.vm.synced_folder "../symfony", "/home/vagrant/demo-alba", :nfs => true
<br />
4/ Go to symfony/config<br />
5/ Transform paramaters.yml.dist to paramaters.yml<br />
6/ Change data with your informations<br />
<br />
7/ Go to /vagrant<br />
8/ Cmd :<br />
<br /><br />
vagrant up<br />
vagrant provision<br />
vagrant ssh<br />
sudo locale-gen UTF-8<br />
sudo dpkg-reconfigure phpmyadmin<br />
composer install<br />
php app/console doctrine:generate:entities --dest=src<br />
php app/console doctrine:schema:update<br />
php app/console fos:user:create admin --super-admin<br />
php app/console sonata:page:create-site
<br /><br />
