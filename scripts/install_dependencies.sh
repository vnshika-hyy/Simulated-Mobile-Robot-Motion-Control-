#!/usr/bin/env bash

set -euo pipefail

echo "Checking Ubuntu and ROS 2 dependencies..."

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo "[MISSING] Ubuntu is required; detected ${ID:-unknown}"
        exit 1
    fi
    echo "[OK] Ubuntu ${VERSION_ID:-unknown}"
else
    echo "[MISSING] /etc/os-release"
    exit 1
fi

if [[ -r /opt/ros/jazzy/setup.bash ]]; then
    echo "[OK] ROS 2 Jazzy setup file"
    source /opt/ros/jazzy/setup.bash
else
    echo "[MISSING] /opt/ros/jazzy/setup.bash"
    echo "ROS 2 Jazzy is not available. Install ROS 2 Jazzy before building this project."
fi

if command -v ros2 >/dev/null 2>&1; then
    echo "[OK] ros2 command"
else
    echo "[MISSING] ros2 command"
fi

if command -v colcon >/dev/null 2>&1; then
    echo "[OK] colcon"
else
    echo "[MISSING] colcon"
    echo "  sudo apt install python3-colcon-common-extensions"
fi

if command -v rosdep >/dev/null 2>&1; then
    echo "[OK] rosdep"
else
    echo "[MISSING] rosdep"
    echo "  sudo apt install python3-rosdep"
fi

for package in turtlebot3_gazebo ros_gz_bridge; do
    if command -v ros2 >/dev/null 2>&1 && ros2 pkg prefix "$package" >/dev/null 2>&1; then
        echo "[OK] $package"
    else
        echo "[MISSING] $package"
    fi
done

echo
echo "The script did not install or remove any system packages."
echo "If packages are available, run:"
echo "  sudo rosdep init        # only if rosdep has never been initialized"
echo "  rosdep update"
echo "  rosdep install --from-paths src --ignore-src -r -y"
