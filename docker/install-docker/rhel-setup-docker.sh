echo "Begin bootstrap setup-server-docker.sh"

# install docker
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/rhel/docker-ce.repo

yum install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

usermod -a -G docker itzuser
systemctl daemon-reload
systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service
systemctl start containerd.service

# create docker cleanup cron job
echo "0 3 * * * docker system prune -f" >> /var/spool/cron/root

echo "DONE!!"