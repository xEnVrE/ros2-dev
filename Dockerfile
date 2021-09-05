FROM nvidia/cudagl:11.0.3-devel-ubuntu20.04
LABEL org.opencontainers.image.title="ROS Image"
LABEL org.opencontainers.image.description="Infrastructure for running ROS with GPU support"
LABEL org.opencontainers.image.authors="Nicola A. Piga <nicola.piga@iit.it>"

# Non-interactive installation mode
ENV DEBIAN_FRONTEND=noninteractive

# Update apt database
RUN apt update

# Install essentials
RUN apt install -y build-essential cmake cmake-curses-gui curl emacs-nox git gnupg2 htop iputils-ping locales lsb-release nano sudo vim wget

# Set the locale
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Create user with passwordless sudo
RUN useradd -l -G sudo -md /home/user -s /bin/bash -p user user
RUN sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# Install ROS2
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt update
RUN apt install -y ros-foxy-desktop

# Switch to user
USER user

# Setup ROS2
RUN echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc

# Launch bash from /home/user
WORKDIR /home/user
CMD ["bash"]
