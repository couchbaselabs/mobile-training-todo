## Requirements

- Vagrant 1.8.1
- VirtualBox 5.0.6

## Getting Started

1. Install VirtualBox from the installer on the USB.
1. Install Vagrant from the installer on the USB.
1. Copy **couchbase-mobile-training.box** and **Vagrantfile** to a directory on your machine.
1. Open a new Terminal/Command prompt and import the box image.

    ```bash
    vagrant box add couchbase-mobile-training couchbase-mobile-training.box
    ```

1. Start the VMs.

    ```bash
    vagrant up
    ```

1. Start the Deploy lesson of the Training.
