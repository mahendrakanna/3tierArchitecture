#!/bin/bash
# user_data_web.sh
# This script runs on the web server instance at launch.

# Update package lists
sudo yum update -y

# Install Nginx (example web server)
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx

# Create a simple index.html page
echo "<h1>Hello from the Web Tier!</h1>" | sudo tee /usr/share/nginx/html/index.html
echo "<p>This is the presentation layer.</p>" | sudo tee -a /usr/share/nginx/html/index.html

# You might add more complex setup here, e.g., configuring a reverse proxy
# to forward requests to the application tier.
