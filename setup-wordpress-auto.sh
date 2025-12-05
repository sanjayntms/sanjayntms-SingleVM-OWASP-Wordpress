#!/bin/bash
set -e

echo "======================================"
echo " Starting Automated WordPress Install "
echo "======================================"

echo "=== Updating system ==="
sudo apt update -y

echo "=== Installing Apache, PHP, MySQL ==="
sudo apt install -y apache2 mysql-server php php-mysql php-xml php-zip php-mbstring php-curl php-gd wget unzip curl

sudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl restart apache2

echo "=== Starting MySQL ==="
sudo systemctl enable mysql
sudo systemctl start mysql
sleep 5

echo "=== Creating DB and User ==="
sudo mysql -e "CREATE DATABASE IF NOT EXISTS wpdb;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'Password123!';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wpdb.* TO 'wpuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "=== Downloading WordPress ==="
sudo wget -q https://wordpress.org/latest.zip -O /tmp/wordpress.zip

echo "=== Extracting WordPress (non-interactive) ==="
sudo rm -rf /tmp/wordpress
sudo unzip -o -q /tmp/wordpress.zip -d /tmp/

echo "=== Removing Apache default content ==="
sudo rm -rf /var/www/html/*

echo "=== Copying WordPress ==="
sudo cp -r /tmp/wordpress/* /var/www/html/

echo "=== Installing WP-CLI ==="
curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

echo "=== Setting permissions ==="
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

IP=$(curl -s ifconfig.me)

echo "=== Generating wp-config.php ==="
sudo -u www-data wp config create \
  --path=/var/www/html \
  --dbname=wpdb \
  --dbuser=wpuser \
  --dbpass=Password123! \
  --dbhost=localhost \
  --skip-check --force

echo "=== Running WordPress installation ==="
sudo -u www-data wp core install \
  --path=/var/www/html \
  --url="http://$IP" \
  --title="OWASP Demo Site" \
  --admin_user="admin" \
  --admin_password="Admin123!" \
  --admin_email="admin@example.com"

echo "=== Fixing permissions ==="
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "======================================"
echo " WordPress Installed Successfully! "
echo " URL: http://$IP"
echo " Admin Login: http://$IP/wp-admin"
echo " Username: admin"
echo " Password: Admin123!"
echo "======================================"
