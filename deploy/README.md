
Vagrant instructions targeted towards the folks who are helping end users follow the **training/deploy** docs.

## Download the Vagrant centos box

```
$ wget http://cbmobile-bucket.s3.amazonaws.com/training-virtual-machines/centos-local-customized.box
```

## Add it to Vagrant

```
$ vagrant box add centos-local-customized downloaded_boxes/centos-local-customized.box
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
ssh vagrant@192.168.34.10
```

For the password, use `vagrant`

Alternatively:

```
$ vagrant ssh sync-gateway1
```

## Deploy

See deployment instructions (separate doc)


## Customizing the box 

Customizations required:

  - update the sshd config to allow password authentication so that you can ssh in without running `vagrant ssh`
  - pre-install the couchbase and sync gateway packages

Customization steps:

- `$ vagrant up` (as in previous steps)
- `$ vagrant ssh sync-gateway1` 
- Make the changes in the vm
- `$ vagrant package --output centos-local-customized2.box`
- `$ vagrant box add centos-local-customized2 centos-local-customized2.box`
- Now you can create a Vagrantfile that uses centos-local-customized2 as the box name

