# Simulated Mobile Robot Motion Control

A lightweight ROS 2 Jazzy project for TurtleBot3 Burger motion control in Gazebo Harmonic.

## Beginner workflow

Run the interactive launcher from the project directory:

```bash
./scripts/run_project.sh
```

In the menu, choose **4** to build the project the first time. Then choose **1**
to start `turtlebot3_world.launch.py`; leave that terminal running. Open a second
Ubuntu/WSL terminal, run the launcher there, and choose **2** for automatic
motion or **3** for keyboard control. The keyboard controller runs in the
foreground because it needs your keyboard input. Choose **6** to inspect ROS
topics, or **5** to run the system check.

The launcher sources ROS 2 Jazzy, sets `TURTLEBOT3_MODEL=burger`, and sources
`install/setup.bash` when available. It does not install packages or start a
manual bridge. The TurtleBot3 Gazebo launch starts `ros_gz_bridge` automatically.
In the verified runtime, `/cmd_vel` is `geometry_msgs/msg/TwistStamped` and
`/odom` is `nav_msgs/msg/Odometry`.

## Project purpose

This project demonstrates:

- Automatic forward, backward, left, and right motion.
- W/A/S/D keyboard control.
- Emergency stopping with Space or Ctrl+C.
- Automatic stopping after movement input becomes inactive.
- Position and heading display from `/odom`.

## Architecture

```text
Automatic sequence or keyboard terminal
                 |
                 v
       mobile_robot_control
                 |
                 v
  /cmd_vel - geometry_msgs/msg/TwistStamped
                 |
                 v
  ros_gz_bridge (started by TurtleBot3 Gazebo launch)
                 |
                 v
    TurtleBot3 Burger in Gazebo
                 |
                 v
  /odom - nav_msgs/msg/Odometry
                 |
                 v
       Position and heading display
```

## Prerequisites

- Ubuntu 24.04
- ROS 2 Jazzy
- Gazebo Harmonic
- TurtleBot3 Gazebo packages
- `ros_gz_bridge`, started automatically by the TurtleBot3 Gazebo launch
- Python 3
- `colcon` and `rosdep`

## Project structure

```text
src/mobile_robot_control/
  package.xml
  setup.py
  setup.cfg
  resource/mobile_robot_control
  mobile_robot_control/
    motion_controller.py
    keyboard_controller.py
  launch/robot_control.launch.py
  config/controller_params.yaml
scripts/
  install_dependencies.sh
  check_system.sh
  run_project.sh
```

## Initial Ubuntu setup

Run the read-only dependency check:

```bash
bash scripts/install_dependencies.sh
```

The script does not install or remove system packages. Install missing tools only after reading the reported commands. Verify ROS 2:

```bash
source /opt/ros/jazzy/setup.bash
export TURTLEBOT3_MODEL=burger
```

Install package dependencies with rosdep:

```bash
source /opt/ros/jazzy/setup.bash
rosdep install --from-paths src --ignore-src -r -y
```

Only initialize rosdep if it has not already been initialized:

```bash
sudo rosdep init
rosdep update
```

## Build

From the repository root:

```bash
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install
source install/setup.bash
export TURTLEBOT3_MODEL=burger
```

The source tree is a ROS 2 workspace, so it may be cloned or copied to any compatible Linux path.

## Manual commands for troubleshooting

The interactive launcher is recommended for normal use. To start the simulation
manually in a separate terminal:

```bash
source /opt/ros/jazzy/setup.bash
export TURTLEBOT3_MODEL=burger
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
```

The TurtleBot3 Gazebo launch starts `ros_gz_bridge` automatically. Do not start
an additional manual bridge. Verify the topics and their actual runtime types:

```bash
ros2 topic list
ros2 topic info /cmd_vel -v
ros2 topic info /odom -v
```

In the verified TurtleBot3 Jazzy/Gazebo Sim 8 environment, `/cmd_vel` uses
`geometry_msgs/msg/TwistStamped` and `/odom` uses `nav_msgs/msg/Odometry`.
The existing launch-provided bridge handles communication; do not add a
manual bridge.

### Automatic controller

For troubleshooting, after building and sourcing the workspace:

```bash
source /opt/ros/jazzy/setup.bash
source install/setup.bash
ros2 run mobile_robot_control motion_controller \
  --ros-args --params-file src/mobile_robot_control/config/controller_params.yaml
```

Or use the legacy launcher mode:

```bash
./scripts/run_project.sh automatic
```

Or use the launch file:

```bash
ros2 launch mobile_robot_control robot_control.launch.py controller:=automatic
```

### Keyboard controller

Keyboard control requires a real interactive Ubuntu terminal. Run:

```bash
source /opt/ros/jazzy/setup.bash
source install/setup.bash
ros2 run mobile_robot_control keyboard_controller \
  --ros-args --params-file src/mobile_robot_control/config/controller_params.yaml
```

Or choose option **3** in the interactive launcher.

Launch-based keyboard input is not recommended because launch may not provide reliable stdin.

Controls:

| Key | Action |
|---|---|
| W | Forward |
| S | Backward |
| A | Rotate left |
| D | Rotate right |
| Space | Stop |
| P | Display position and heading |
| Q | Quit |

## Parameters

`src/mobile_robot_control/config/controller_params.yaml` configures both nodes:

- Linear speeds
- Angular speed
- Action duration
- Stop duration
- Publish frequency
- Keyboard inactivity timeout

## Safe stopping

The keyboard controller publishes a zero-velocity `TwistStamped` when it stops,
times out, or receives Ctrl+C. The automatic controller publishes zero-velocity
`TwistStamped` commands at each stop and before shutdown.

In Gazebo, press Ctrl+C in the active controller and then confirm velocity is no longer non-zero.

## Troubleshooting

| Problem | Check |
|---|---|
| ROS Jazzy not found | Verify `/opt/ros/jazzy/setup.bash` |
| Package not found | Run `colcon build --symlink-install` and source `install/setup.bash` |
| Robot does not move | Inspect `/cmd_vel` publishers and subscribers; confirm its type is `geometry_msgs/msg/TwistStamped` and the launch-provided bridge is active |
| `/odom` missing | Verify Gazebo and odometry bridge, then run `ros2 topic echo /odom --once` |
| Keyboard input fails | Run the node in an interactive Ubuntu terminal rather than launch |
| Keyboard terminal looks wrong | Ctrl+C or Q should restore terminal settings |

Run the system check:

```bash
bash scripts/check_system.sh
```

## WSL2 notes

WSL2 use is supported, but Gazebo graphics must be tested in the Ubuntu environment. Run ROS, Gazebo, bridges, and controllers inside Ubuntu/WSL. Do not use Windows-only paths in ROS commands.

## Limitations

The project does not include SLAM, Nav2, obstacle avoidance, machine learning, or complex path planning.
