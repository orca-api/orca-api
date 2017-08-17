# -*- mode: ruby -*-
require 'erb'

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.vm.network 'forwarded_port', guest: 5432, host: 15432
  config.vm.network 'forwarded_port', guest: 8000, host: 18000
  config.vm.network 'forwarded_port', guest: 8080, host: 18080
  config.vm.provider 'virtualbox' do |vb|
    vb.cpus = 4
    vb.memory = 4094
  end
  config.vbguest.auto_update = false
  config.vm.provision :shell, inline: ERB.new(<<-SHELL).result
    <% if File.exist?('.apt-cache-proxy') %>
      echo 'Acquire::http::Proxy "http://<%= File.read('.apt-cache-proxy').strip %>:3142/";' > /etc/apt/apt.conf.d/99proxy
    <% else %>
      sed -i '~' -e 's%http://archive.ubuntu.com/ubuntu%mirror://mirrors.ubuntu.com/JP.txt%g' /etc/apt/sources.list
    <% end %>
    curl -o /etc/apt/sources.list.d/jma-receipt-xenial50.list https://ftp.orca.med.or.jp/pub/ubuntu/jma-receipt-xenial50.list
    curl https://ftp.orca.med.or.jp/pub/ubuntu/archive.key | apt-key add -
    apt-get update
    apt-get upgrade -y
    apt-get install -y \
    curl \
    language-pack-ja \
    nginx \
    rsyslog \
    syslinux-common \
    uuid-runtime
    update-locale LANG=ja_JP.UTF-8
    timedatectl set-timezone Asia/Tokyo
    apt-get install -y jma-receipt
    echo "listen_addresses = '*'" >> /etc/postgresql/9.5/main/postgresql.conf
    echo 'host all all 0.0.0.0/0 trust' >> /etc/postgresql/9.5/main/pg_hba.conf
    echo 'DBENCODING="UTF-8"' >> /etc/jma-receipt/db.conf
    jma-setup
    service jma-receipt start
    if [ ! -f /etc/jma-receipt/passwd ]; then
      echo "ormaster:$(md5pass ormaster):" > /etc/jma-receipt/passwd
      chown orca:orca /etc/jma-receipt/passwd
      chmod 644 /etc/jma-receipt/passwd
      su orca - -c '/usr/lib/jma-receipt/bin/passwd_store.sh | nkf -w'
    fi
    # jma-setup
    # service jma-receipt restart
    # su orca - -c '/usr/lib/jma-receipt/scripts/tools/run_master_upgrade.sh | nkf -w'
    # su orca - -c '/usr/lib/jma-receipt/bin/jma-receipt-program-upgrade.sh | nkf -w'
    # service jma-receipt stop
    # service postgresql restart
    # service jma-receipt start
  SHELL
end
