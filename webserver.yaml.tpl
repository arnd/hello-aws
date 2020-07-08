# Cloud-config for webserver

# Update apt database on first boot
package_update: true

# Install needed packages
packages:
  - nginx

# For HTTPS (unfortunately compute.amazonws.com is blacklisted in letsencrypt)
#  - certbot
#  - python3-certbot-nginx

# Install custom index.html
write_files:
  - path: /var/www/html/index.html
    permissions: 644
    encoding: b64
    content: ${index_html_content}
