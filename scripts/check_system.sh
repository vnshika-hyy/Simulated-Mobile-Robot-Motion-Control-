#!/usr/bin/env bash

set -uo pipefail

if [[ -r /opt/ros/jazzy/setup.bash ]]; then
    echo "[OK] ROS 2 Jazzy"
    source /opt/ros/jazzy/setup.bash
else
    echo "[MISSING] ROS 2 Jazzy setup"
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
fi

if command -v rosdep >/dev/null 2>&1; then
    echo "[OK] rosdep"
else
    echo "[MISSING] rosdep"
fi

if command -v ros2 >/dev/null 2>&1; then
    if ros2 pkg prefix turtlebot3_gazebo >/dev/null 2>&1; then
        echo "[OK] TurtleBot3 packages"
    else
        echo "[MISSING] TurtleBot3 packages"
    fi

    if ros2 pkg prefix ros_gz_bridge >/dev/null 2>&1; then
        echo "[OK] ros_gz/bridge packages"
    else
        echo "[WARNING] ros_gz_bridge package not found"
    fi

    topic_output="$(timeout 2 ros2 topic list 2>/dev/null || true)"
    if [[ -n "$topic_output" ]]; then
        if grep -qx "/cmd_vel" <<<"$topic_output"; then
            echo "[OK] /cmd_vel topic detected"
        else
            echo "[WARNING] /cmd_vel not currently detected"
        fi
        if grep -qx "/odom" <<<"$topic_output"; then
            echo "[OK] /odom topic detected"
        else
            echo "[WARNING] /odom not currently detected"
        fi
    else
        echo "[WARNING] No active ROS 2 topic output detected; launch the simulation first"
    fi
fi
