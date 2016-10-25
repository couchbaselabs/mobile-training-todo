## Requirements

- Vagrant 1.8.1
- VirtualBox 5.0.6

## Getting Started

1. Install VirtualBox from the installer on the USB.
1. Install Vagrant from the installer on the USB.
1. Copy **couchbase-mobile-training.box** and **Vagrantfile** to a directory on your machine.
1. Open a new Terminal/Command prompt and import the box image.

    ```bash
    vagrant box add couchbase-mobile-training downloaded_boxes/couchbase-mobile-training.box
    ```

1. Start the VMs.

    ```bash
    vagrant up
    ```

- redo VM with node.js
- with test.zip (and extracted) containing loadtest, spec.js

test: run the load test and multiply by 10 and see that all the response are under x ms. then good to deploy to production. you'll be able to split your load between different SGs and you should see the overall latency go down.