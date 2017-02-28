# Provision WordPress Develop

# Make a database, if we don't already have one
echo -e "\nCreating database 'wordpress_gh' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS wordpress_gh"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON wordpress_gh.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/src.error.log
touch ${VVV_PATH_TO_SITE}/log/src.access.log
touch ${VVV_PATH_TO_SITE}/log/build.access.log
touch ${VVV_PATH_TO_SITE}/log/build.access.log

# Checkout, install and configure WordPress trunk via develop.svn
if [[ ! -d "${VVV_PATH_TO_SITE}/public_html" ]]; then
  echo "Checking out WordPress trunk. See https://develop.svn.wordpress.org/trunk"
  noroot git clone https://github.com/jeremyfelt/wordpress-develop.git /tmp/wordpress-gh

  echo "Moving WordPress develop to a shared directory, ${VVV_PATH_TO_SITE}/public_html"
  mv /tmp/wordpress-gh ${VVV_PATH_TO_SITE}/public_html

  cd ${VVV_PATH_TO_SITE}/public_html/src/
  echo "Creating wp-config.php for gh.wordpress-develop.dev."
  noroot wp core config --dbname=wordpress_gh --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(gh)(.wordpress-develop.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
} else if ( 'build' === basename( dirname( __FILE__ ) ) ) {
// Allow (gh).wordpress-develop.dev to share the same Database
    define( 'WP_HOME', 'http://gh.wordpress-develop.dev' );
    define( 'WP_SITEURL', 'http://gh.wordpress-develop.dev' );
}

define( 'WP_DEBUG', true );
PHP

  echo "Installing gh.wordpress-develop.dev."
  noroot wp core install --url=gh.wordpress-develop.dev --quiet --title="WordPress Develop (GH)" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
  cp /srv/config/wordpress-config/wp-tests-config.php ${VVV_PATH_TO_SITE}/public_html/
  cd ${VVV_PATH_TO_SITE}/public_html/

fi
