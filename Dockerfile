FROM nvidia/cudagl:11.0.3-devel-ubuntu20.04
LABEL org.opencontainers.image.title="ROS Image"
LABEL org.opencontainers.image.description="Infrastructure for running ROS with GPU support"
LABEL org.opencontainers.image.authors="Nicola A. Piga <nicola.piga@iit.it>"

# Non-interactive installation mode
ENV DEBIAN_FRONTEND=noninteractive

# Update apt database
RUN apt update

# Set the locale
RUN apt install -y -qq locales
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install essentials
RUN apt install -y -qq apt-utils build-essential cmake cmake-curses-gui curl emacs-nox git glmark2 gnupg2 htop iputils-ping lsb-release mesa-utils nano psmisc sudo vim wget

# Install ROS2
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt update
RUN apt install -y -qq libpython3-dev python3-pip python3-colcon-common-extensions python3-rosdep python3-rosinstall ros-foxy-desktop
RUN rosdep init

# Install Gazebo11
RUN curl -sSL http://get.gazebosim.org | sh
RUN apt install -y -qq ros-foxy-gazebo-ros-pkgs

# Install TIAGo dependencies
RUN apt install -y -qq ros-foxy-diagnostic-updater ros-foxy-control-msgs ros-foxy-control-toolbox ros-foxy-realtime-tools ros-foxy-joy-teleop ros-foxy-xacro

# Create user with passwordless sudo
RUN useradd -l -G sudo -md /home/user -s /bin/bash -p user user
RUN sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# Switch to user
USER user

# Setup ROS2
RUN echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc
RUN rosdep update
RUN pip3 install -U argcomplete
RUN mkdir -p /home/user/ws/src

# Setup Gazebo11
RUN echo "source /usr/share/gazebo/setup.sh"

# Build TIAgo
WORKDIR /home/user/ws/src
RUN git clone https://github.com/pal-robotics/tiago_tutorials -b foxy-devel
RUN sed -i "s#git@github.com:#https://github.com/#" tiago_tutorials/tiago_public.rosinstall
# rosinstall fails but it will download all the required repositories
RUN rosinstall /home/user/ws/src /opt/ros/foxy/ tiago_tutorials/tiago_public.rosinstall; rm -r ./build ./log ./install

# It seems that we require tag 0.0.5
WORKDIR /home/user/ws/src/launch_pal
RUN git checkout 0.0.5

WORKDIR /home/user/ws
RUN colcon build

# Make sure the setup.bash is sourced
RUN echo "source /home/user/ws/install/setup.bash" >> ~/.bashrc

# Launch bash from /home/user
WORKDIR /home/user
CMD ["bash"]
