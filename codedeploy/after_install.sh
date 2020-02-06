#!/bin/bash -xe

## Code Deploy Agent Bootstrap Script##


exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
AUTOUPDATE=true

function installdep(){

if [ ${PLAT} = "ubuntu" ]; then

  apt-get -y update
  # Satisfying even ubuntu older versions.
  apt-get -y install jq awscli ruby2.0 || apt-get -y install jq awscli ruby



elif [ ${PLAT} = "amz" ]; then
  yum -y update
  yum install -y aws-cli ruby jq
  amazon-linux-extras install nginx1.12
  systemctl enable nginx.service
  systemctl start nginx.service
  echo '
  server {
          listen 80;
          server_name *.amazonaws.com;

          location / {
               proxy_pass http://127.0.0.1:8080/;
               proxy_set_header X-Forwarded-For $remote_addr;
               proxy_set_header Host $http_host;
          }
  }
  ' >> /etc/nginx/conf.d/app.conf
  systemctl reload nginx.service
  systemctl restart nginx.service
  echo '  
[Unit]
Description=Spring Boot HelloWorld
After=syslog.target
After=network.target[Service]
User=username
Type=simple

[Service]
ExecStart=java8 -jar /tmp/target/gs-spring-boot-docker-0.1.0.jar
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=helloworld

[Install]
WantedBy=multi-user.target
  ' >> /etc/systemd/system/spring_app.service
  systemctl enable spring_app
fi

}

function platformize(){

#Linux OS detection#
 if hash lsb_release; then
   echo "Ubuntu server OS detected"
   export PLAT="ubuntu"


elif hash yum; then
  echo "Amazon Linux detected"
  export PLAT="amz"

 else
   echo "Unsupported release"
   exit 1

 fi
}


function execute(){

if [ ${PLAT} = "ubuntu" ]; then

  cd /tmp/
  wget https://aws-codedeploy-${REGION}.s3.amazonaws.com/latest/install
  chmod +x ./install

  if ./install auto; then
    echo "Instalation completed"
      if ! ${AUTOUPDATE}; then
            echo "Disabling Auto Update"
            sed -i '/@reboot/d' /etc/cron.d/codedeploy-agent-update
            chattr +i /etc/cron.d/codedeploy-agent-update
            rm -f /tmp/install
      fi
    exit 0
  else
    echo "Instalation script failed, please investigate"
    rm -f /tmp/install
    exit 1
  fi

elif [ ${PLAT} = "amz" ]; then

  cd /tmp/
  wget https://aws-codedeploy-${REGION}.s3.amazonaws.com/latest/install
  chmod +x ./install

    if ./install auto; then
      echo "Instalation completed"
        if ! ${AUTOUPDATE}; then
            echo "Disabling auto update"
            sed -i '/@reboot/d' /etc/cron.d/codedeploy-agent-update
            chattr +i /etc/cron.d/codedeploy-agent-update
            rm -f /tmp/install
        fi
      exit 0
    else
      echo "Instalation script failed, please investigate"
      rm -f /tmp/install
      exit 1
    fi

else
  echo "Unsupported platform ''${PLAT}''"
fi

}

platformize
installdep
REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".region")
execute
