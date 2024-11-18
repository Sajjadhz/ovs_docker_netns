FROM ubuntu:20.04

# Install required packages
RUN apt-get update && apt-get install -y \
    openvswitch-switch \
    iproute2 \
    iputils-ping \
    net-tools \
    isc-dhcp-client \
    dnsmasq \
    && apt-get clean

ENTRYPOINT /bin/bash -c "\
    echo 'Starting Open vSwitch service...'; \
    service openvswitch-switch start; \
    echo 'Adding OVS bridge...'; \
    ovs-vsctl add-br ovs-br; \
    echo 'Adding eth0 to OVS bridge...'; \
    ovs-vsctl add-port ovs-br eth0; \
    echo 'Configuring eth0 and OVS bridge...'; \
    ifconfig eth0 0; \
    ifconfig ovs-br up; \
    echo 'Acquiring IP address for OVS bridge (this may take some time)...'; \
    dhclient ovs-br; \
    echo 'Configuring static IP and default route...'; \
    ip addr add 172.17.0.10/24 dev ovs-br; \
    ip route add default via 172.17.0.1 dev ovs-br; \
    echo 'Setting up namespaces and virtual interfaces...'; \
    ip netns add red; \
    ip netns add blue; \
    ovs-vsctl add-port ovs-br veth-blue-br -- set interface veth-blue-br type=internal; \
    ovs-vsctl add-port ovs-br veth-red-br -- set interface veth-red-br type=internal; \
    ip link set veth-blue-br netns blue; \
    ip link set veth-red-br netns red; \
    ip netns exec blue ip addr add 172.17.0.20/24 dev veth-blue-br; \
    ip netns exec red ip addr add 172.17.0.30/24 dev veth-red-br; \
    ip netns exec blue ip link set veth-blue-br up; \
    ip netns exec red ip link set veth-red-br up; \
    ip netns exec blue ip route add default via 172.17.0.1 dev veth-blue-br; \
    ip netns exec red ip route add default via 172.17.0.1 dev veth-red-br; \
    ip netns exec blue ping -c2 google.com; \
    ip netns exec red ping -c2 google.com; \
    echo 'Setup complete.';

CMD ["bash"]

