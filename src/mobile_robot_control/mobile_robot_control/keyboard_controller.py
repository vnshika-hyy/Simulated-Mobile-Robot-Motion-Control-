#!/usr/bin/env python3
"""Keyboard control and odometry display for a TurtleBot3 Burger."""

import math
import select
import sys
import termios
import time
import tty

import rclpy
from geometry_msgs.msg import TwistStamped
from nav_msgs.msg import Odometry
from rclpy.node import Node


class KeyboardController(Node):
    def __init__(self) -> None:
        super().__init__("keyboard_controller")

        self.declare_parameter("forward_speed", 0.10)
        self.declare_parameter("backward_speed", -0.10)
        self.declare_parameter("angular_speed", 0.50)
        self.declare_parameter("inactivity_timeout", 0.40)
        self.declare_parameter("publish_period", 0.05)

        self.forward_speed = float(self.get_parameter("forward_speed").value)
        self.backward_speed = float(self.get_parameter("backward_speed").value)
        self.angular_speed = float(self.get_parameter("angular_speed").value)
        self.inactivity_timeout = float(
            self.get_parameter("inactivity_timeout").value
        )
        self.publish_period = float(self.get_parameter("publish_period").value)

        if self.publish_period <= 0.0:
            raise ValueError("publish_period must be greater than zero")
        if self.inactivity_timeout <= 0.0:
            raise ValueError("inactivity_timeout must be greater than zero")

        self.publisher = self.create_publisher(TwistStamped, "/cmd_vel", 10)
        self.subscription = self.create_subscription(
            Odometry, "/odom", self.odometry_callback, 10
        )

        self.x = 0.0
        self.y = 0.0
        self.heading_degrees = 0.0
        self.linear_velocity = 0.0
        self.angular_velocity = 0.0
        self.odometry_received = False

    def odometry_callback(self, message: Odometry) -> None:
        position = message.pose.pose.position
        self.x = float(position.x)
        self.y = float(position.y)

        orientation = message.pose.pose.orientation
        sin_yaw_cos_pitch = 2.0 * (
            orientation.w * orientation.z + orientation.x * orientation.y
        )
        cos_yaw_cos_pitch = 1.0 - 2.0 * (
            orientation.y * orientation.y + orientation.z * orientation.z
        )
        yaw = math.atan2(sin_yaw_cos_pitch, cos_yaw_cos_pitch)
        self.heading_degrees = math.degrees(yaw)

        self.linear_velocity = float(message.twist.twist.linear.x)
        self.angular_velocity = float(message.twist.twist.angular.z)
        self.odometry_received = True

    def publish_motion(self, linear_x: float, angular_z: float) -> None:
        command = TwistStamped()
        command.header.stamp = self.get_clock().now().to_msg()
        command.twist.linear.x = linear_x
        command.twist.angular.z = angular_z
        self.publisher.publish(command)

    def stop(self) -> None:
        command = TwistStamped()
        command.header.stamp = self.get_clock().now().to_msg()
        self.publisher.publish(command)

    def print_odometry(self) -> None:
        if not self.odometry_received:
            print("Odometry: no /odom message received yet.")
            return

        print(
            f"Position: X={self.x:.4f} m, Y={self.y:.4f} m, "
            f"Heading={self.heading_degrees:.2f} deg"
        )
        print(
            f"Velocity: Linear={self.linear_velocity:.4f} m/s, "
            f"Angular={self.angular_velocity:.4f} rad/s"
        )


def read_key(timeout_seconds: float) -> str:
    readable, _, _ = select.select([sys.stdin], [], [], timeout_seconds)
    if not readable:
        return ""
    return sys.stdin.read(1)


def print_help() -> None:
    print("Keyboard controls:")
    print("  W = forward")
    print("  S = backward")
    print("  A = rotate left")
    print("  D = rotate right")
    print("  Space = stop")
    print("  P = display position and heading")
    print("  Q = quit")


def main() -> None:
    rclpy.init()
    node = KeyboardController()
    original_terminal_settings = None

    try:
        original_terminal_settings = termios.tcgetattr(sys.stdin)
        tty.setcbreak(sys.stdin.fileno())
    except termios.error:
        print("WARNING: terminal keyboard mode unavailable; run this node from an interactive Ubuntu terminal.")

    print_help()
    last_movement_time = time.monotonic()
    stopped = True

    try:
        while rclpy.ok():
            rclpy.spin_once(node, timeout_sec=0.0)
            key = read_key(node.publish_period)
            current_time = time.monotonic()

            if key:
                normalized_key = key.lower()
                if normalized_key == "w":
                    node.publish_motion(node.forward_speed, 0.0)
                    last_movement_time = current_time
                    stopped = False
                elif normalized_key == "s":
                    node.publish_motion(node.backward_speed, 0.0)
                    last_movement_time = current_time
                    stopped = False
                elif normalized_key == "a":
                    node.publish_motion(0.0, node.angular_speed)
                    last_movement_time = current_time
                    stopped = False
                elif normalized_key == "d":
                    node.publish_motion(0.0, -node.angular_speed)
                    last_movement_time = current_time
                    stopped = False
                elif key == " ":
                    node.stop()
                    last_movement_time = current_time
                    stopped = True
                elif normalized_key == "p":
                    node.print_odometry()
                elif normalized_key == "q":
                    print("Quit requested.")
                    break
            elif not stopped and current_time - last_movement_time >= node.inactivity_timeout:
                node.stop()
                stopped = True
                print("Inactivity timeout: robot stopped.")
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received.")
    except Exception as error:
        print(f"Unexpected controller error: {error}")
    finally:
        node.stop()
        if original_terminal_settings is not None:
            termios.tcsetattr(
                sys.stdin, termios.TCSADRAIN, original_terminal_settings
            )
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
