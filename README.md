# ovs_docker_netns
practicing openvswitch and linux network namespace on docker

# How to use
```
docker build -t ovs-imgage .

docker run -it -uroot --privileged --name ovs-container ovs-imgage
```
