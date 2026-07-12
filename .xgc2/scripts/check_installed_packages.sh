#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-melodic}"
PREFIX="/opt/ros/${ROS_DISTRO}"
PACKAGE="ros-${ROS_DISTRO}-swarm-ros-bridge"
ROS_PACKAGE="swarm_ros_bridge"

dpkg -s "${PACKAGE}" >/dev/null

set +u
source "${PREFIX}/setup.bash"
set -u

test "$(rospack find "${ROS_PACKAGE}")" = "${PREFIX}/share/${ROS_PACKAGE}"
test -f "${PREFIX}/share/${ROS_PACKAGE}/package.xml"
test -f "${PREFIX}/share/${ROS_PACKAGE}/config/ros_topics.yaml"
test -f "${PREFIX}/share/${ROS_PACKAGE}/launch/test.launch"
test -x "${PREFIX}/lib/${ROS_PACKAGE}/bridge_node"
test -x "${PREFIX}/lib/${ROS_PACKAGE}/listener.py"
test -x "${PREFIX}/lib/${ROS_PACKAGE}/talker.py"
ldd "${PREFIX}/lib/${ROS_PACKAGE}/bridge_node" | grep -q "libzmq"

roslaunch --files "${ROS_PACKAGE}" test.launch >/dev/null

echo "Installed package check passed"
