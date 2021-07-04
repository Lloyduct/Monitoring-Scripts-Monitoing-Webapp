### Monitoring-Scripts-Monitoing-Webapp ###
For this project there are a number of monitoring tools that can provide comprehensive monitoring capacity - The most common in AWS cloud is cloudwatch, my current project in AWS was for one of the leading retail giant in the UK - a web appilcation, all the logs are ingest into S3 with WAF rules configured to push all external logs to clouwatch and I leverage Athena to read WAF log. I used cloudwatch to get realtime statistic of system resources. In AWS i strongly recommend pushing all logs to cloudwatch. For none AWS lightweight monitoring I recommend monit and Netdata they can provide comprehensive monitoring capability.

Understanding the state of your application and the percentage of system resources it consumes enable you to plan for capacity expansion and isolate performance bottleneck. Application performance is strongly dependent on system resources as such it is critical we monitor and understand which application is utilizing what percentage of system resource

First phase - deployment: This deployments assumes you have a terraform environment setup if not install terraform and use the build script to start the infrastructure build. You need an EC2-user copy the access and secret keep and change accordingly in the provider file ensure the EC2 IAM user have the necessary access to deploy an ECS instance. .

This projects include using terraform to deploy a complete serverless infrastructure which will then use to validate the monitoring scripts. The build script is used to build the infrastructure - such as ec2 instance, VPC, subnets, routing table, ELB, autoscaling, and security groups. A typical deployment as this provides application high availability for your web application.

Second phase - option one - run the scripts. Once the EC2 instance is deployed using terraform you can now proceed in running the scripts to monitor CPU, Memory, Disk Usage, IO, Top processes and top connection session your instance or server. The script was built on bash and very easy to understand.

Second phase - option 2 I added Monit as another lightweight monitoring tool it captures, CPU, Memory, disk usage, filesystem, processes and many more.

Installing steps for Monit on Ubuntu Step 1 - Update your repository Once you are logged in to your Ubuntu 20.04 server, run the following command to update your base system with the latest available packages.

apt-get update -y

Step 2 – Install Monit By default, Monit is available in the Ubuntu 20.04 default repository. You can install it with the following command:

apt-get install monit -y Once Monit is installed, the Monit service will be started automatically. You can check the status of Monit with the following command:

systemctl status monit

Step 3 - Configure Monit The Monit default configuration file is located at /etc/monit/monitrc. Monit provides a web-based interface to monitor Monit through the web browser.

By default, the Monit web interface is disabled, so you will need to enable it and set the admin password. You can do this by editing the file /etc/monit/monitrc. In this setup when you run the monit script it should set the user and password and update custiom configuration with basic application to monitor. If you to need to configure monit manually you can edit the configuration file accordingly. nano /etc/monit/monitrc Uncomment and set the Monit admin password as shown below:

set httpd port 2812 and (or used the script, the script useds port 8080) allow admin:adminpassword Save and close the file when you are finished, then check for syntax errors with the following command:

To reload the configuration file monit -t

systemctl restart monit At this point, Monit is started and listening on port 8080 this is based on my script you can change it based on your environment. You can check it with the following command:

netstat -tnlp | grep 8080

Now, open your web browser and access the Monit web interface using the URL http://your-server-ip:8080. You should see the Monit login page:
