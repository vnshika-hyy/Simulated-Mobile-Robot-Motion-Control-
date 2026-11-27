from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, OpaqueFunction
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def launch_controller(context, *args, **kwargs):
    mode = context.perform_substitution(LaunchConfiguration("controller"))
    if mode not in ("automatic", "keyboard"):
        raise RuntimeError(
            "controller must be either 'automatic' or 'keyboard'"
        )

    package_dir = get_package_share_directory("mobile_robot_control")
    parameter_file = package_dir + "/config/controller_params.yaml"
    executable = "motion_controller" if mode == "automatic" else "keyboard_controller"

    return [
        Node(
            package="mobile_robot_control",
            executable=executable,
            name=executable,
            parameters=[parameter_file],
            output="screen",
        )
    ]


def generate_launch_description():
    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "controller",
                default_value="automatic",
                choices=["automatic", "keyboard"],
                description="Controller mode: automatic or keyboard",
            ),
            OpaqueFunction(function=launch_controller),
        ]
    )
