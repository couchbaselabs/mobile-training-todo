
Vagrant instructions targeted towards the folks who are helping end users follow the **training/deploy** docs.

## Download the Vagrant centos box

```
$ wget http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1609_01.VirtualBox.box
```

## Add it to Vagrant

```
$ vagrant box add centos-local-customized downloaded_boxes/CentOS-7-x86_64-Vagrant-1609_01.VirtualBox.box
```

*NOTE:* for Connect demo, the download step won't be necessary, and the path to the box will be to the file on the USB drive

## Download Vagrantfile 

```
$ wget raw_url_of_this_gist
```

## Start Virtual Machines

```
$ vagrant up
```

## SSH in

```
$ vagrant ssh sync-gateway1
```

## Customizing the box 

Customizations required:

  - update the sshd config to allow password authentication so that you can ssh in without running 'vagrant ssh'
  - pre-install the couchbase and sync gateway packages

Customization steps:

- $ vagrant up (as in previous steps)
- $ vagrant ssh sync-gateway1 
- Make the changes in the vm
- $ vagrant package --output centos-local-customized2.box
- $ vagrant box add centos-local-customized2 centos-local-customized2.box
- Now you can create a Vagrantfile that uses centos-local-customized2 as the box name

