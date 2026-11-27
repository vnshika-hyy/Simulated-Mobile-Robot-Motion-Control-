#!/usr/bin/env python3
"""Publish a predefined sequence of safe TurtleBot3 motion commands."""

import time

import rclpy
from geometry_msgs.msg import TwistStamped
from rclpy.node import Node


class MotionController(Node):
    def __init__(self) -> None:
        super().__init__("motion_controller")

        self.declare_parameter("forward_speed", 0.10)
        self.declare_parameter("backward_speed", -0.10)
        self.declare_parameter("angular_speed", 0.50)
        self.declare_parameter("action_duration", 2.0)
        self.declare_parameter("stop_duration", 0.75)
        self.declare_parameter("publish_frequency", 10.0)

        self.forward_speed = float(self.get_parameter("forward_speed").value)
        self.backward_speed = float(self.get_parameter("backward_speed").value)
        self.angular_speed = float(self.get_parameter("angular_speed").value)
        self.action_duration = float(self.get_parameter("action_duration").value)
        self.stop_duration = float(self.get_parameter("stop_duration").value)
        self.publish_frequency = float(self.get_parameter("publish_frequency").value)

        if self.publish_frequency <= 0.0:
            raise ValueError("publish_frequency must be greater than zero")

        self.publisher = self.create_publisher(TwistStamped, "/cmd_vel", 10)

    def publish_motion(self, linear_x: float, angular_z: float, duration: float) -> None:
        command = TwistStamped()
        command.twist.linear.x = linear_x
        command.twist.angular.z = angular_z

        start_time = time.monotonic()
        period = 1.0 / self.publish_frequency

        while rclpy.ok():
            elapsed = time.monotonic() - start_time
            if elapsed >= duration:
                break

            command.header.stamp = self.get_clock().now().to_msg()
            self.publisher.publish(command)
            time.sleep(period)

    def stop(self) -> None:
        stop_command = TwistStamped()
        for _ in range(3):
            stop_command.header.stamp = self.get_clock().now().to_msg()
            self.publisher.publish(stop_command)
            time.sleep(0.05)


def main() -> None:
    rclpy.init()
    node = MotionController()

    try:
        actions = (
            ("FORWARD", node.forward_speed, 0.0),
            ("BACKWARD", node.backward_speed, 0.0),
            ("LEFT", 0.0, node.angular_speed),
            ("RIGHT", 0.0, -node.angular_speed),
        )

        for name, linear_x, angular_z in actions:
            print(
                f"[{name}] linear={linear_x:.2f} m/s, "
                f"angular={angular_z:.2f} rad/s"
            )
            node.publish_motion(linear_x, angular_z, node.action_duration)
            print("[STOP]")
            node.publish_motion(0.0, 0.0, node.stop_duration)

        print("Automatic sequence complete.")
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received.")
    except Exception as error:
        print(f"Unexpected controller error: {error}")
    finally:
        node.stop()
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
