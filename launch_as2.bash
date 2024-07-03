#!/bin/bash

usage() {
    echo "  options:"
    echo "      -r: record rosbag"
    echo "      -t: launch keyboard teleoperation"
}

# Arg parser
while getopts "rt" opt; do
  case ${opt} in
    r )
      record_rosbag="true"
      ;;
    t )
      launch_keyboard_teleop="true"
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    : )
      if [[ ! $OPTARG =~ ^[wrt]$ ]]; then
        echo "Option -$OPTARG requires an argument" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

# Shift optional args
shift $((OPTIND -1))

## DEFAULTS
record_rosbag=${record_rosbag:="false"}
launch_keyboard_teleop=${launch_keyboard_teleop:="false"}

drone="tello"

tmuxinator start -n ${drone} -p tmuxinator/aerostack2.yaml \
    drone_namespace=${drone} &
echo "Background processes started ${drone}..."
wait

tmuxinator start -n mocap -p tmuxinator/mocap4ros2.yaml &
wait

if [[ ${record_rosbag} == "true" ]]; then
    tmuxinator start -p tmuxinator/rosbag.yaml \
        drones=${drone} &
    wait
fi

if [[ ${launch_keyboard_teleop} == "true" ]]; then
    tmuxinator start -p tmuxinator/keyboard_teleop.yaml \
        drone_namespace=${drone} &
    wait
fi

# Attach to tmux session
tmux attach-session -t ${drone}:alphanumeric_viewer
