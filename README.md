# Monitoring-Scripts-Monitoing-Webapp
For this project there are a number of monitoring tools that can provide comprehensive monitoring capacity - The most common in AWS cloud is cloudwatch, my current project in AWS was for one of the leading retail giant in the UK - a web appication, all the logs are ingest into S3 with WAF rules configured to push all external logs to clouwatch and I leverage Athena to read WAF log. I used cloudwatch to get realtime statistic of system reources. In AWS i strongly recommend pushing all logs to cloudwatch. For none AWS lightwight monitoring I recommned monit and Netdata they can provide comprehensive monitoring capability.

Understanding the state of your application and the percentage of system resources it consumes enable you to plan for capacity expansion and isoldate performance bottleneck. Application performance is strongly dependent on system resources as such it is critical we monitor and understand which application is utilizing what percentage of system resource. 

Installing Monit on Ubuntu
Step 1 - Update your repository
Once you are logged in to your Ubuntu 20.04 server, run the following command to update your base system with the latest available packages.

apt-get update -y

Step 2 – Install Monit
By default, Monit is available in the Ubuntu 20.04 default repository. You can install it with the following command:

apt-get install monit -y
Once Monit is installed, the Monit service will be started automatically. You can check the status of Monit with the following command:

systemctl status monit

Step 3 - Configure Monit
The Monit default configuration file is located at /etc/monit/monitrc. Monit provides a web-based interface to monitor Monit through the web browser.

By default, the Monit web interface is disabled, so you will need to enable it and set the admin password. You can do this by editing the file /etc/monit/monitrc. In this setup when you run the monit script it should set the user and password and update custiom configuration with basic application to monitor.
If you to need to configure monit manually you can edit the configuration file accordingly.
nano /etc/monit/monitrc
Uncomment and set the Monit admin password as shown below:

set httpd port 2812 and (or used the script, the script useds port 8080)
allow admin:adminpassword
Save and close the file when you are finished, then check for syntax errors with the following command:

To reload the configuration file
monit -t

systemctl restart monit
At this point, Monit is started and listening on port 8080 this is based on my script you can change it based on your environment. You can check it with the following command:

netstat -tnlp | grep 8080

Now, open your web browser and access the Monit web interface using the URL http://your-server-ip:8080. You should see the Monit login page:
