script "init_daemons" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
      rm -f /var/spool/clientmqueue/*
      if ps -A | grep -q 'sendmail'; then
        kill `ps -A | grep 'sendmail' | gawk '{print $1}'`
      fi

      if ps -A | grep -q 'gearman'; then
        stop gearmand-server
      fi

      if ps -A | grep -q 'java'; then
        stop pdfPrinter
      fi

      if ls /etc/init | grep -q 'gearmand-server.conf'; then
        rm /etc/init/gearmand-server.conf
      fi

      if ps -A | grep -q 'php'; then
        kill `ps -A | grep 'php' | gawk '{print $1}'`
      fi

      echo "start on runlevel [2345]
      stop on runlevel [^2345]
      respawn limit 10 60
      exec /usr/local/sbin/gearmand --port=4730 --log-file=/usr/local/var/log/gearmand.log" >> /etc/init/gearmand-server.conf


      if ls /etc/init | grep -q 'pdfPrinter.conf'; then
        rm /etc/init/pdfPrinter.conf
      fi

      echo "# descrption 'start and stop pdfPrinter worker'
      start on runlevel [2345]
      stop on runlevel [^2345]
      respawn limit 20 60
      exec nohup /usr/bin/java -jar /var/app/current/lib/pdfGenerator/pdfPrinter.jar 4730" >> /etc/init/pdfPrinter.conf

      if ls /etc/init | grep -q 'smtpReceiver.conf'; then
        rm /etc/init/smtpReceiver.conf
      fi

      echo "# descrption 'start and stop smtpReceiver'
      start on runlevel [2345]
      stop on runlevel [^2345]
      respawn limit 20 60
      exec nohup /usr/bin/php /var/app/current/symfony service:SMTPReceiver > /dev/null 2>/dev/null &" >> /etc/init/smtpReceiver.conf

      start gearmand-server
      start pdfPrinter
      start smtpReceiver
    EOH
end

cron "LCODownloading" do
  minute "0"
  hour "3"
  month "*"
  weekday "*"
  command "/usr/bin/php -f /var/app/current/symfony job:LCODownloading >> /var/app/current/log/symfonyJobs.log"
end

cron "Reports" do
  minute "1"
  hour "5"
  month "*"
  weekday "*"
  command "/usr/bin/php -f /var/app/current/symfony generate:reports >> /var/app/current/log/symfonyJobs.log"
end

cron "FreezeStamping" do
  minute "2"
  hour "5"
  month "*"
  weekday "*"
  command "/usr/bin/php -f /var/app/current/symfony freeze:stamping >> /var/app/current/log/symfonyJobs.log"
end

cron "PublicInvoice" do
  minute "5"
  hour "5"
  month "*"
  weekday "*"
  command "/usr/bin/php -f /var/app/current/symfony job:PublicInvoice >> /var/app/current/log/symfonyJobs.log"
end