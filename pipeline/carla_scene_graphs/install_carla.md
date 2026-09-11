Steps to install CARLA on fresh Ubuntu 20.04

# Install GPU Drivers
1. Install driver
```bash
sudo apt install nvidia-driver-530 -y
```


# Install CARLA
0. Setup dirs
```bash
mkdir ./sim
cd ./sim
```

1. Setup [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)
Follow the above link to install conda as appropriate for your system. 


2. Download CARLA from GitHub [here](https://github.com/carla-simulator/carla/blob/master/Docs/download.md) using [0.9.16](https://github.com/carla-simulator/carla/releases/tag/0.9.16/) as the current latest. This will take several minutes

https://tiny.carla.org/carla-0-9-14-linux
```bash
cd ./sim
wget https://tiny.carla.org/carla-0-9-14-linux -O CARLA_0.9.14.tar.gz
wget https://tiny.carla.org/additional-maps-0-9-14-linux -O AdditionalMaps_0.9.14.tar.gz
wget https://tiny.carla.org/carla-0-9-14-rss-linux -O CARLA_0.9.14_RSS.tar.gz
```

3. Unzip and cleanup. This will take a minute or two
```bash
cd ./sim
tar -xvzf CARLA_0.9.14.tar.gz -C ./
tar -xvzf AdditionalMaps_0.9.14.tar.gz -C ./Import
rm -rf CARLA_0.9.14.tar.gz
rm -rf AdditionalMaps_0.9.14.tar.gz
```

4. Install the additional maps
```bash
cd ./sim
./ImportAssets.sh
```
5. Setup the conda environment:
The environment will be called `carla_sgg` and is built from the `environment.yml` file:
```bash
conda env create -f environment.yml --prefix .carlasg
conda activate .carlasg/
```

6. Setup CARLA Python Client Library. 
Optional: This will use the local CARLA library.
<!-- ```bash
pip3 install ./sim/PythonAPI/carla/dist/carla-0.9.14-cp37-cp37m-manylinux_2_27_x86_64.whl
``` -->

7. Install misc. libs
```bash
sudo apt-get install libomp5 -y
sudo apt-get install vulkan-utils -y
sudo apt-get install graphviz -y
```

8. Launch CARLA
```bash
cd $HOME/sim
./CarlaUE4.sh -RenderOffScreen
```
