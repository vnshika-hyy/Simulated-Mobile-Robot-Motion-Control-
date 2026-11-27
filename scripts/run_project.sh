#!/usr/bin/env bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROS_SETUP="/opt/ros/jazzy/setup.bash"
PARAMETERS="$PROJECT_ROOT/src/mobile_robot_control/config/controller_params.yaml"

cd "$PROJECT_ROOT" || exit 1

if [[ ! -r "$ROS_SETUP" ]]; then
    echo "ERROR: ROS 2 Jazzy was not found at $ROS_SETUP." >&2
    echo "Install/source ROS 2 Jazzy in Ubuntu 24.04 before using this launcher." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ROS_SETUP"

if [[ -r "$PROJECT_ROOT/install/setup.bash" ]]; then
    if ! source "$PROJECT_ROOT/install/setup.bash"; then
        echo "ERROR: Could not source $PROJECT_ROOT/install/setup.bash." >&2
        exit 1
    fi
else
    echo "NOTE: This project has not been built yet. Choose option 4 to build it."
fi

export TURTLEBOT3_MODEL=burger

if ! command -v ros2 >/dev/null 2>&1; then
    echo "ERROR: The ros2 command is unavailable after sourcing ROS 2 Jazzy." >&2
    echo "Check that the ROS 2 Jazzy installation is complete." >&2
    exit 1
fi

check_project_built() {
    if [[ ! -r "$PROJECT_ROOT/install/setup.bash" ]] ||
        ! ros2 pkg prefix mobile_robot_control >/dev/null 2>&1; then
        echo "This project has not been built or its package is not discoverable."
        echo "Choose option 4 to run colcon build --symlink-install first."
        return 1
    fi
}

check_simulation_topics() {
    local topics status

    topics="$(timeout 5 ros2 topic list 2>&1)"
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "WARNING: Could not query ROS topics. Is the simulation running?"
        if [[ -n "$topics" ]]; then
            printf '%s\n' "$topics"
        fi
        return 1
    fi

    if [[ -z "$topics" ]]; then
        echo "WARNING: No ROS topics are visible. Start the TurtleBot3 simulation first."
        return 1
    fi

    if grep -Fxq "/cmd_vel" <<<"$topics"; then
        echo "[OK] /cmd_vel is available (geometry_msgs/msg/TwistStamped)."
    else
        echo "WARNING: /cmd_vel is unavailable. Is the TurtleBot3 simulation running?"
    fi

    if grep -Fxq "/odom" <<<"$topics"; then
        echo "[OK] /odom is available (nav_msgs/msg/Odometry)."
    else
        echo "WARNING: /odom is unavailable. Is the TurtleBot3 simulation running?"
    fi
}

start_simulation() {
    if ! ros2 pkg prefix turtlebot3_gazebo >/dev/null 2>&1; then
        echo "ERROR: TurtleBot3 Gazebo packages were not found in this ROS environment."
        echo "Check the TurtleBot3 Jazzy installation; this launcher does not install packages."
        return 1
    fi

    echo "Starting TurtleBot3 world. Press Ctrl+C to return to this menu."
    echo "The Gazebo launch starts ros_gz_bridge automatically; no manual bridge is needed."
    ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
}

run_controller() {
    local executable="$1"

    if ! check_project_built; then
        return 1
    fi

    check_simulation_topics || true
    if [[ "$executable" == "keyboard_controller" ]]; then
        echo "Keyboard controller is running in this terminal. Use Q or Ctrl+C to exit."
    fi
    ros2 run mobile_robot_control "$executable" \
        --ros-args --params-file "$PARAMETERS"
}

build_project() {
    if ! command -v colcon >/dev/null 2>&1; then
        echo "ERROR: colcon was not found. Install/configure it separately; this launcher does not install packages."
        return 1
    fi

    echo "Building project from: $PROJECT_ROOT"
    if colcon build --symlink-install; then
        if ! source "$PROJECT_ROOT/install/setup.bash"; then
            echo "ERROR: Build succeeded, but install/setup.bash could not be sourced."
            return 1
        fi
        export TURTLEBOT3_MODEL=burger
        echo "Build succeeded and install/setup.bash has been sourced."
    else
        echo "ERROR: Build failed. Review the colcon output above."
        return 1
    fi
}

check_system() {
    bash "$PROJECT_ROOT/scripts/check_system.sh"
}

show_topics() {
    local topics status

    topics="$(timeout 5 ros2 topic list 2>&1)"
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "ERROR: Could not run ros2 topic list. The ROS graph may be unavailable."
        if [[ -n "$topics" ]]; then
            printf '%s\n' "$topics"
        fi
        return 1
    fi

    if [[ -n "$topics" ]]; then
        echo "ROS topics:"
        printf '%s\n' "$topics"
    else
        echo "No ROS topics are visible. Start the TurtleBot3 simulation first."
    fi

    if grep -Fxq "/cmd_vel" <<<"$topics"; then
        echo "[OK] /cmd_vel exists (geometry_msgs/msg/TwistStamped)."
    else
        echo "[MISSING] /cmd_vel is unavailable. Check that the simulation is running."
    fi

    if grep -Fxq "/odom" <<<"$topics"; then
        echo "[OK] /odom exists (nav_msgs/msg/Odometry)."
    else
        echo "[MISSING] /odom is unavailable. Check that the simulation is running."
    fi
}

if [[ $# -gt 0 ]]; then
    case "$1" in
        automatic)
            run_controller motion_controller
            exit $?
            ;;
        keyboard)
            run_controller keyboard_controller
            exit $?
            ;;
        *)
            echo "Usage: $0 [automatic|keyboard]" >&2
            exit 2
            ;;
    esac
fi

if [[ ! -t 0 ]]; then
    echo "ERROR: The interactive launcher needs a terminal. Run it from an Ubuntu/WSL terminal." >&2
    exit 1
fi

while true; do
    echo
    echo "TurtleBot3 Mobile Robot Control"
    echo "Project: $PROJECT_ROOT"
    echo "1. Start TurtleBot3 Gazebo Simulation"
    echo "2. Run Automatic Motion Controller"
    echo "3. Run Keyboard Controller"
    echo "4. Build/Rebuild Project"
    echo "5. Check System"
    echo "6. Show ROS Topics"
    echo "7. Exit"
    read -r -p "Select an option [1-7]: " choice || {
        echo
        echo "Input closed. Exiting."
        break
    }

    case "$choice" in
        1) start_simulation ;;
        2) run_controller motion_controller ;;
        3) run_controller keyboard_controller ;;
        4) build_project ;;
        5) check_system ;;
        6) show_topics ;;
        7)
            echo "Goodbye."
            break
            ;;
        *)
            echo "Please enter a number from 1 to 7."
            ;;
    esac
done
