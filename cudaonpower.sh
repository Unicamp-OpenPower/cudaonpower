#!/bin/bash
set +e
: '
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'

INSTALL_DIR=~/cuda_install
CUDA_VERSION=8.0
CUDA_PKG=cuda-repo-ubuntu1604-8-0-local-ga2_8.0.54-1_ppc64el-deb

error() {
        printf '\E[31m'; echo "$@"; printf '\E[0m'
}

is_admin() {
        if [[ $EUID -eq 0 ]]; then
                error "Ensure you are running this script as an user with admin rights."
                exit 1
        fi
}

install_cuda(){
        mkdir $INSTALL_DIR
        cd $INSTALL_DIR
        sudo lspci | grep -i nvidia
        sudo apt-get install -y build-essential
        wget https://developer.nvidia.com/compute/cuda/$CUDA_VERSION/prod/local_installers/$CUDA_PKG
        sudo dpkg -i ./$CUDA_PKG
        sudo apt-get -f install
        sudo apt-get update
        sudo apt-get install -y cuda
        echo 'export PATH=$PATH:/usr/local/cuda-8.0/bin' | sudo tee
        echo /usr/local/cuda-8.0/lib64 | sudo tee /etc/ld.so.conf.d/cuda-8-0.conf
        sudo ldconfig
}

post_install(){
        sudo dmesg | grep -i nvidia
        sudo lsmod | grep nvidia
        nvidia-smi --list-gpus
}

run_sample() {
        mkdir $INSTALL_DIR/samples 
        cp -r /usr/local/cuda-$CUDA_VERSION/samples/ $INSTALL_DIR
        cd $INSTALL_DIR/samples/7_CUDALibraries/simpleCUFFT
        make
        ./simpleCUFFT
}

reboot() {
        read -p "Reboot your system now to complete the installation (y/n)? " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
                sudo reboot
        fi
}

# read user option
if [ $# -ne 1 ]; then
        echo "usage: p8cudainstaller [ install | post_install ]"
        exit 1
fi

# act according the option selected
if [[ "$1" == "install" ]]; then
        is_admin
        install_cuda
        echo "When the reboot is completed, run p8cudainstaller.sh post_install."
        echo
        reboot
elif [[ "$1" == "post_install" ]]; then
        post_install
        run_sample
else
	echo "Please, enter the correct command."
	echo "usage: p8cudainstaller [ install | post_install ]"
fi
