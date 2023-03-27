# Todo Docker Compose

This `docker` folder contains the `docker-compose.yml` file for starting and configuring Couchbase Server and Sync Gateway for the Todo app. 

The Couchbase Server instance is configured with the `todo` bucket and 3 collections in the default scope : `lists`, `tasks`, and `users`. 

The admin credentials of the Couchbase Server instance and the `todo` bucket for Sync Gateway are as follows.

| Resource | Credentials |
| :----------- | :----------- |
| Couchbase Server | Administrator:password |
| todo bucket | admin:password |

The users for the Todo app are blake, callum, dan, jens, jianmin, jim, pasin, vlad, user1, user2, user3. All have the same password, which is 'pass'. 

## Requirements

- Docker

## Environment Variables

The environment variables that can be set to the Todo's docker-compose are as follows.

| Key Name | Required | Description |
| :----------- | :-----------: | :----------- |
| COUCHBASE_VERSION | No  | Version of Couchbase Server, default is 7.1.4  |
| SG_DEB            | Yes | Location of Sync Gateway deb file, relative to the `sg` directory |

To set the environment variables, create `.env` file with the variables in key=value format.

**Sample .env file**
```
COUCHBASE_VERSION=7.1.4
SG_DEB=SG_DEB=deb/couchbase-sync-gateway-enterprise_3.1.0-578_x86_64.deb
```

## Steps

1. Download Sync-Gateway deb file and save the file under the `sg` folder. 

   You can use `download-sg-build.sh` in the `scripts` folder to download (Required Couchbase VPN). The `download-sg-build.sh` has 3 arugments : `version`, `build-number`, and `architecture`. The `architecture` argument is optional, and its value can be `arm64` or `x86_64`. Without specified, the script will try to detect the architecture based on the machine that runs the script. When using the script, the downloaded Sync-Gateway deb file will be saved in the `sg/deb` folder.
   
   **Sample:**
   ```
   ./scripts/download-sg-build.sh 3.1.0 578 x86_64
   ```

   **NOTE:** When using `download-sg-build.sh` script, the script will output the SG_DEB variable that you can use the set in .env file (Step 2).
  
2. Create .env file for setting the location of the Sync-Gatewy deb file and the optional Couchbase Server version.

   **Sample:**

   ```
   echo "SG_DEB=deb/couchbase-sync-gateway-enterprise_3.1.0-578_x86_64.deb" > .env 
   ```
   
3. Run docker-compose up
 
   ```
   docker compose up
   ```
   
   **NOTE:** 
   
   * You can also run docker-compose in the detach mode by using `-d` option.
   * Use `Ctrl-C` to stop the containers and use `docker compose down` to remove the containers.
   
4. Tests

   ```
   curl -L -u "admin:password" http://localhost:4985/todo
   curl -L -u "admin:password" http://localhost:4985/todo/_config
   ```
    
## Sync Gateway Log

You can check Sync-Gateway console log at `sg/logs/sg.log`. 

---

# How to run Todo Docker Compose in an EC2 Instance

This section provides some instruction about how to run the Todo docker compose in an EC2 Instance. Note that there is another way to run the docker-compose to deploy the containers in ECS (Amazon Elastic Container Service), but that information is not convered here as it also requires to publish the built docker images to a registry.

## Setup an EC2 instance

1. Use your AWS account and setup a new EC2 Instance. The recommendation is to use Ubuntu, 22.04 LTS, x84_64 image with t2.medium instance type.

2. Add port 4984, 4984, and 8091 to the Security Inbound rules of the instance.

3. Install Docker by following the instruction at https://docs.docker.com/engine/install/ubuntu.

   **Sample**
   ```
   # Install docker using the convenience script 
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Allow to run docker as a non-privileged user
   sudo apt-get install -y uidmap
   dockerd-rootless-setuptool.sh install
   ```

## Run Todo docker compose

1. Clone the project in your EC2 instance

   ```
   # Clone
   git clone https://github.com/couchbaselabs/mobile-training-todo.git
   cd mobile-training-todo
   git checkout release/helium
   ```

2. Go to docker directory

   ```
   cd docker
   ```

3. Create a directory for copying Sync-Gateway deb file

   ```
   mkdir sg/deb
   ```

4. Copy Sync-Gateway deb file from your local machine to the `deb` folder created in Step 3.
   
   **Sample**
   ```
   scp -i MY_EC2_PRIVATE_KEY.pem ./couchbase-sync-gateway-enterprise_3.1.0-578_x86_64.deb ubuntu@<EC2-ADDRESS>:/home/ubuntu/mobile-training-todo/docker/sg/deb/couchbase-sync-gateway-enterprise_3.1.0-578_x86_64.deb
   ```
   
5. Run docker compose up

   ```
   docker compose up
   ```
6. Test
   
   ```
   curl -L -u "admin:password" http://<EC2-ADDRESS>:4985/todo
   curl -L -u "admin:password" http://<EC2-ADDRESS>:4985/todo/_config
   ```
