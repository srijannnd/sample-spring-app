# install updates
yum update -y

yum install -y java-1.8.0-openjdk-devel
yum remove java-1.7.0-openjdk
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
yum install -y apache-maven
mvn --version
yum install -y git