Run your Sonar on OpenShift
============================

This git repository helps you get up and running quickly w/ a Sonar installation on OpenShift.

Step 1: Sign up for an OpenShift Account
----------------------------

	If you don’t already have an OpenShift account, head on over to the website and signup with promo code ews.
	It is completely free and Red Hat gives every user three free Gears on which to run your applications. 
	At the time of this writing, the combined resources allocated for each user is 1.5 GB of memory and 3 GB of disk space.

Step 2: Install the client tools on your machine
----------------------------

	Note: If you would rather watch a screencast of this step, check out the following videos where I demo how to install the client tools.

	Windows(https://openshift.redhat.com/community/videos/installing-the-new-and-improved-openshift-client-tools-for-windows)

	Linux Ubuntu(http://www.youtube.com/watch?v=WZug3f-Ld34&feature=plcp)

	Linux Fedora(http://www.youtube.com/watch?v=KLtbuvyJFFE)

	OSX(http://www.youtube.com/watch?v=MoGpT1AW3MA)

	The OpenShift client tools are written in a very popular programming language called Ruby. 
	With OSX 10.6 or later and most Linux distributions, Ruby is installed by default so installing the client tools is a snap. 
	Simply issue the following command on your terminal application:

	sudo gem install rhc

Step 3 : Setting up OpenShift
----------------------------

	The rhc client tool makes it very easy to setup your OpenShift instance with ssh keys, git and your applications namespace. 
	The namespace is a unique name per user which becomes part of your application url. 
	For example, if your namespace is cloudbuild and application name is sonar then url of the application will be https://sonar-cloudbuild.rhcloud.com/. 
	The command is shown below.

	rhc setup -l <openshift_login_email>

Step 4 : Creating a Tomcat Gear
----------------------------

	After setting up your OpenShift account, we need to create a gear which will contain the Tomcat environment where we can deploy our application. 
	The -t option specifies the type of the application you want to create. 
	In this, we are using jbossews-1.0. JBoss EWS is the JBoss Enterprise Web Server built on top on Apache Tomcat.
	JBoss Enterprise Web Server is a fully-integrated and certified set of components for hosting Java web applications. 
	It is comprised of the web server (Apache HTTP Server), the Apache Tomcat Servlet container, load balancers (mod_jk and mod_cluster), and the Tomcat Native library.
	To create the tomcat application, execute the command shown below:

	rhc app create -a sonar -t jbossews-1.0
	This command will create a directory named sonar which contains a OpenShift template project.

Step 5 : Create a database
----------------------------
	Add MySQL cartridge, PHPMyAdmin and create "sonar" database in MySQL.

Step 6 : Install Sonar in Tomcat
----------------------------

	cd sonar
	git remote add upstream -m master git://github.com/wenhao/openshift-sonar.git
	git pull -s recursive -X theirs upstream master
	git push
	That's it, you can now checkout your sonar at:

	http://sonar-#yournamespace.rhcloud.com