#!/bin/bash

usage() {
    echo "  options:"
    echo "      -t: launch keyboard teleoperation. Default not launch"
    echo "      -v: open rviz. Default not launch"
    echo "      -r: record rosbag. Default not launch"
    echo "      -n: drone namespaces, comma separated. Default get from world config file"
    echo "      -m: launch mocap4ros2. Default launch"
    echo "      -g: launch using gnome-terminal instead of tmux"
}

# Initialize variables with default values
keyboard_teleop="false"
rviz="false"
rosbag="false"
drones_namespace_comma=""
mocap4ros2="true"
use_gnome="false"

# Parse command line arguments
while getopts "mtvrn:g" opt; do
  case ${opt} in
    t )
      keyboard_teleop="true"
      ;;
    v )
      rviz="true"
      ;;
    r )
      rosbag="true"
      ;;
    n )
      drones_namespace_comma="${OPTARG}"
      ;;
    m )
      mocap4ros2="false"
      ;;
    g )
      use_gnome="true"
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    : )
      if [[ ! $OPTARG =~ ^[swrt]$ ]]; then
        echo "Option -$OPTARG requires an argument" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

# If no drone namespaces are provided, get them from the world config file
if [ -z "$drones_namespace_comma" ]; then
  drones_namespace_comma=$(python3 utils/get_drones.py -p config/config.yaml --sep ',')
fi
IFS=',' read -r -a drone_namespaces <<< "$drones_namespace_comma"

# Select between tmux and gnome-terminal
tmuxinator_mode="start"
tmuxinator_end="wait"
tmp_file="/tmp/as2_project_launch_${drone_namespaces[@]}.txt"
if [[ ${use_gnome} == "true" ]]; then
  tmuxinator_mode="debug"
  tmuxinator_end="> ${tmp_file} && python3 utils/tmuxinator_to_genome.py -p ${tmp_file} && wait"
fi

# Launch aerostack2 ground station
eval "tmuxinator ${tmuxinator_mode} -n ground_station -p tmuxinator/ground_station.yaml \
  drone_namespace=${drones_namespace_comma} \
  keyboard_teleop=${keyboard_teleop} \
  rviz=${rviz} \
  rosbag=${rosbag} \
  mocap4ros2=${mocap4ros2} \
  ${tmuxinator_end}"

# Attach to tmux session
if [[ ${use_gnome} == "false" ]]; then
  tmux attach-session -t ground_station
# If tmp_file exists, remove it
elif [[ -f ${tmp_file} ]]; then
  rm ${tmp_file}
fi