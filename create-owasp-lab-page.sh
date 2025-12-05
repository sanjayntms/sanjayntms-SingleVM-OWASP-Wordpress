#!/bin/bash
set -e

WP_PATH="/var/www/html"

echo "======================================"
echo " Creating OWASP Attack Lab Page       "
echo "======================================"

if ! command -v wp >/dev/null 2>&1; then
  echo "ERROR: wp-cli is not installed."
  exit 1
fi

echo "=== Ensuring correct permissions for WP-CLI ==="
sudo chown -R www-data:www-data "$WP_PATH"
sudo chmod -R 755 "$WP_PATH"

############################################
# Create OWASP Page Content
############################################

CONTENT=$(cat << 'EOF'
<h1>OWASP Attack Lab</h1>

<h2>1. File Manager (LFI Demo)</h2>
<p>This demo illustrates Local File Inclusion vulnerabilities.</p>
[ntms_file_manager_lfi]

<hr>

<h2>2. Unsafe File Upload</h2>
<p>This upload form has NO validation — for OWASP testing purposes.</p>
[ntms_unsafe_upload]

<hr>

<h2>3. Reflected XSS Demo</h2>
<p>Reflects the <code>?msg=</code> parameter without sanitization.</p>
[ntms_xss]

Example: <code>?msg=&lt;script&gt;alert(1)&lt;/script&gt;</code>

<hr>

<h2>4. SQL Injection Demo</h2>
<p>This intentionally insecure query is vulnerable to SQL injection.</p>
[ntms_sqli_demo]

Try: <code>?id=1 OR 1=1</code>

EOF
)

############################################
# Create or Update Page
############################################

echo "=== Creating OWASP Attack Lab WordPress page ==="

PAGE_ID=$(sudo -u www-data wp post list --post_type=page --name=owasp-lab --format=ids --path="$WP_PATH")

if [ -z "$PAGE_ID" ]; then
    echo "Page does not exist — creating..."
    PAGE_ID=$(sudo -u www-data wp post create \
        --post_type=page \
        --post_title="OWASP Attack Lab" \
        --post_name="owasp-lab" \
        --post_status=publish \
        --post_content="$CONTENT" \
        --path="$WP_PATH" \
        --porcelain)
else
    echo "Page exists ($PAGE_ID) — updating..."
    sudo -u www-data wp post update $PAGE_ID \
        --post_content="$CONTENT" \
        --path="$WP_PATH"
fi

echo "OWASP Lab Page ID: $PAGE_ID"

############################################
# Add Page to Menu
############################################

echo "=== Adding page to main menu ==="

MENU_NAME="main-menu"

MENU_EXISTS=$(sudo -u www-data wp menu list --fields=name --format=csv --path="$WP_PATH" | grep -i "$MENU_NAME" || true)

if [ -z "$MENU_EXISTS" ]; then
    echo "Menu '$MENU_NAME' does not exist — creating it"
    sudo -u www-data wp menu create "$MENU_NAME" --path="$WP_PATH"
fi

# Add item if not already present
MENU_ITEM=$(sudo -u www-data wp menu item list "$MENU_NAME" --fields=object_id --format=csv --path="$WP_PATH" | grep "^$PAGE_ID$" || true)

if [ -z "$MENU_ITEM" ]; then
    echo "Adding page to menu..."
    sudo -u www-data wp menu item add-post "$MENU_NAME" $PAGE_ID --path="$WP_PATH"
else
    echo "Menu item already exists."
fi

echo "======================================"
echo " OWASP Attack Lab page created!       "
echo " URL: /owasp-lab                      "
echo " Added to main menu.                  "
echo "======================================"
