git clone --branch release-2.1.0-rc1 https://git-wip-us.apache.org/repos/asf/ambari.git apache-ambari-2.1.0-src
cd apache-ambari-2.1.0-src
git clean -xdf
cd ambari-web
npm install
ulimit -n 2048
brunch build  (will need to gzip app.js and vendor.js)
rm -rf node_modules
cp -R public/ public-static/
rm -rf public/
cd ../..
tar --exclude=.git --exclude=.gitignore --exclude=.gitattributes -zcvf apache-ambari-2.1.0-src.tar.gz apache-ambari-2.1.0-src/
openssl sha1 apache-ambari-2.1.0-src.tar.gz > apache-ambari-2.1.0-src.tar.gz.sha1
openssl md5 apache-ambari-2.1.1-src.tar.gz > apache-ambari-2.1.1-src.tar.gz.md5
