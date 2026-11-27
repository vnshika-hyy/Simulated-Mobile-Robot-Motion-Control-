# Simulated Mobile Robot Motion Control Using ROS 2, Gazebo Harmonic, TurtleBot3 Burger, and Python

## Title Page

**Project Title:** Simulated Mobile Robot Motion Control Using ROS 2, Gazebo Harmonic, TurtleBot3 Burger, and Python

**Project Type:** Individual college project

**Platform:** Ubuntu 24.04, WSL 2, Windows 11

**Status:** Implementation complete; simulation testing **not yet performed**

---

## 1. Aim

To simulate a TurtleBot3 Burger and control forward, backward, left-turn, right-turn, stop, predefined sequence, and keyboard motion.

## 2. Problem Statement

Mobile robot control requires commands and feedback. Simulation provides a low-cost and safe way to learn velocity control and odometry without physical hardware.

## 3. Software and Tools

| Tool | Role |
|---|---|
| Windows 11 | Host operating system |
| WSL 2 | Ubuntu environment |
| Ubuntu 24.04 | Linux runtime |
| ROS 2 Jazzy | Nodes and topics |
| Gazebo Harmonic | 3D simulation |
| TurtleBot3 Burger | Differential-drive robot model |
| Python 3 | Controller implementation |
| ros_gz_bridge | ROS 2–Gazebo communication |

Installation status is not assumed.

## 4. Methodology

1. Launch the TurtleBot3 empty-world Gazebo package.
2. Use the `ros_gz_bridge` started by the TurtleBot3 Gazebo launch for `/cmd_vel`
   (`geometry_msgs/msg/TwistStamped` in the verified Jazzy/Gazebo Sim 8 runtime).
3. Use the launch-provided odometry bridge for ROS 2 `/odom`
   (`nav_msgs/msg/Odometry`).
4. Verify topic names and types.
5. Run the automatic or keyboard controller.
6. Record real test results and screenshots.

## 5. System Architecture

```text
Automatic sequence or keyboard input
                 |
                 v
          Python ROS 2 node
                 |
                 v
       /cmd_vel (TwistStamped)
                 |
                 v
  ros_gz_bridge (launch-provided)
                 |
                 v
  TurtleBot3 Burger in Gazebo
                 |
                 v
          Gazebo /odom
                 |
                 v
  ros_gz_bridge (launch-provided)
                 |
                 v
       ROS 2 /odom
                 |
                 v
      Position and heading
```

## 6. Implementation

`src/mobile_robot_control/mobile_robot_control/motion_controller.py` publishes stamped velocity commands at 10 Hz using `time.monotonic()` for timing. The sequence is forward, stop, backward, stop, left, stop, right, and stop.

`src/mobile_robot_control/mobile_robot_control/keyboard_controller.py` subscribes to `/odom` and publishes `/cmd_vel` commands. It converts quaternion orientation to yaw in degrees. W, S, A, D, Space, P, and Q are implemented. Movement ceases after a configurable inactivity timeout.

## 7. Robot Motion Mathematics

For a simplified planar differential-drive model:

```text
x_new = x + v × cos(theta) × dt
y_new = y + v × sin(theta) × dt
theta_new = theta + omega × dt
```

- `x` and `y`: robot position coordinates
- `v`: linear velocity
- `omega`: angular velocity
- `theta`: heading
- `dt`: elapsed time

Linear velocity produces forward and backward motion. Angular velocity produces rotation. Gazebo odometry provides the actual simulated position.

## 8. Testing and Results

Controller behavior tests remain **Not yet tested** until verified in Ubuntu;
the target runtime topic types are verified as reported below.

| Test | Procedure | Expected result | Outcome |
|---|---|---|---|
| Forward | Run automatic forward action | Robot moves forward | **Not yet tested** |
| Backward | Run automatic backward action | Robot moves backward | **Not yet tested** |
| Left | Run automatic left action | Robot rotates left | **Not yet tested** |
| Right | Run automatic right action | Robot rotates right | **Not yet tested** |
| Stop | Send Space or execute stop | Robot velocity becomes zero | **Not yet tested** |
| Keyboard W/S | Press W or S | Forward/backward command publishes | **Not yet tested** |
| Keyboard A/D | Press A or D | Left/right angular command publishes | **Not yet tested** |
| Odometry | Press P | X, Y, heading, and velocity appear | **Not yet tested** |
| Topic communication | Run topic information commands | `/cmd_vel` is `geometry_msgs/msg/TwistStamped`; `/odom` is `nav_msgs/msg/Odometry` | **Verified in target runtime** |
| Inactivity timeout | Release movement key | Robot stops after 0.40 seconds | **Not yet tested** |
| Ctrl+C | Interrupt a controller | Zero velocity publishes and terminal restores | **Not yet tested** |

No numerical results or accuracy claims are included.

## 9. Screenshots

No screenshots are available. Add real screenshots after testing and label them in `screenshots/`.

Suggested labels:

- Figure 1: Gazebo world and TurtleBot3
- Figure 2: Forward and backward motion
- Figure 3: Left and right rotation
- Figure 4: Keyboard terminal
- Figure 5: Position and heading output
- Figure 6: ROS 2 topic information

## 10. Limitations

- Empty world and manual/predefined control.
- No SLAM, Nav2, or autonomous obstacle avoidance.
- WSL 2 graphics and laptop performance may vary.
- ROS or Gazebo package versions may affect launch names.
- No physical robot hardware is used.

## 11. Conclusion

The project provides an original lightweight implementation for learning ROS 2 mobile-robot control. Its final motion and accuracy conclusions should be written only after Ubuntu testing.

## 12. References

- ROS 2 Jazzy: https://docs.ros.org/en/jazzy/
- Gazebo Harmonic: https://gazebosim.org/docs/harmonic/
- TurtleBot3: https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/
- ros_gz: https://github.com/gazebosim/ros_gz
- Python: https://docs.python.org/3/
