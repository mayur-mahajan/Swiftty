# swarm-controller
![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![License](https://img.shields.io/github/license/mashape/apistatus.svg)
![OS](https://img.shields.io/badge/os-Linux-green.svg?style=flat)

A description of this package.

## Setup Environment 

## 
### Build
![ARM](https://img.shields.io/badge/cpu-ARM-red.svg?style=flat)

```
swift build --destination ../cross-toolchain/rpi-ubuntu-xenial-destination.json
scp .build/arm-linux-gnueabihf/debug/swarm-controller udooer@192.168.7.2:~/.
```

