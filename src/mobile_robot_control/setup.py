from glob import glob

from setuptools import find_packages, setup

package_name = "mobile_robot_control"

setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(exclude=["test"]),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml"]),
        ("share/" + package_name + "/launch", glob("launch/*.launch.py")),
        ("share/" + package_name + "/config", glob("config/*.yaml")),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Student",
    maintainer_email="student@example.com",
    description="Lightweight TurtleBot3 motion control with automatic and keyboard controllers.",
    license="MIT",
    entry_points={
        "console_scripts": [
            "motion_controller = mobile_robot_control.motion_controller:main",
            "keyboard_controller = mobile_robot_control.keyboard_controller:main",
        ],
    },
)
