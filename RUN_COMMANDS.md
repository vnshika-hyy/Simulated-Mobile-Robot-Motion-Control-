# Beginner Quick Start

From the project directory in Ubuntu/WSL, start the interactive launcher:

```bash
./scripts/run_project.sh
```

1. Choose **4. Build/Rebuild Project** the first time (or after source changes).
2. Choose **1. Start TurtleBot3 Gazebo Simulation** and leave that terminal
   running.
3. In a second Ubuntu/WSL terminal, start the launcher again and choose **2**
   for automatic motion or **3** for keyboard control. Keyboard control stays in
   the foreground and reads input in that terminal.
4. Choose **6** to view ROS topics, or **5** to run the system check.

The launcher sources ROS 2 Jazzy, sets `TURTLEBOT3_MODEL=burger`, and sources
the workspace overlay when it exists. It does not install packages or start a
manual bridge. The TurtleBot3 Gazebo launch starts `ros_gz_bridge` automatically.
The verified topic types are `/cmd_vel` (`geometry_msgs/msg/TwistStamped`) and
`/odom` (`nav_msgs/msg/Odometry`).

## Manual Commands for Troubleshooting

## A. First-time setup

```bash
cd /path/to/Simulated-Mobile-Robot-Motion-Control
bash scripts/install_dependencies.sh
source /opt/ros/jazzy/setup.bash
export TURTLEBOT3_MODEL=burger
sudo rosdep init  # only if rosdep is not initialized
rosdep update
rosdep install --from-paths src --ignore-src -r -y
```

## B. Build project

```bash
cd /path/to/Simulated-Mobile-Robot-Motion-Control
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install
source install/setup.bash
export TURTLEBOT3_MODEL=burger
bash scripts/check_system.sh
```

## C. Start simulation

Terminal 1:

```bash
source /opt/ros/jazzy/setup.bash
export TURTLEBOT3_MODEL=burger
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
```

The TurtleBot3 Gazebo launch starts `ros_gz_bridge` automatically. Do not start
an additional manual bridge.

## D. Run automatic controller (manual)

Terminal 2:

```bash
cd /path/to/Simulated-Mobile-Robot-Motion-Control
bash scripts/run_project.sh automatic
```

## E. Run keyboard controller (manual)

Terminal 2 or a separate terminal:

```bash
cd /path/to/Simulated-Mobile-Robot-Motion-Control
bash scripts/run_project.sh keyboard
```

Keyboard controls: W forward, S backward, A left, D right, Space stop, P odometry, Q quit.

## F. Verify topics

```bash
source /opt/ros/jazzy/setup.bash
ros2 topic list
ros2 topic info /cmd_vel -v
ros2 topic info /odom -v
ros2 topic echo /odom --once
```

## G. Troubleshooting

If `/cmd_vel` or `/odom` is missing after launch:

1. Restart the Gazebo launch.
2. Inspect `ros2 topic list`.
3. Verify the installed TurtleBot3 package.
4. Verify the launch-provided `ros_gz_bridge` is active; do not start a manual bridge in the verified target setup.

In the verified TurtleBot3 Jazzy/Gazebo Sim 8 environment, `/cmd_vel` uses
`geometry_msgs/msg/TwistStamped`; `/odom` remains `nav_msgs/msg/Odometry`.
Verify the topics with `ros2 topic info /cmd_vel -v` and
`ros2 topic info /odom -v`.
