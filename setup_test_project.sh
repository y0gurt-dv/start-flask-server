# Install Python 3.10
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install python3.10 python3.10-venv python3.10-dev -y

# Install nginx
sudo apt install nginx -y
sudo apt install net-tools build-essential -y


# Create test project
mkdir test_project
cd test_project

python3.10 -m venv venv

source venv/bin/activate
pip install flask
pip install wheel uwsgi 

project_secret_key=$(openssl rand -hex 32)

cat > run.py << EOF
from flask import Flask,render_template

app = Flask(__name__)
app.config['SECRET_KEY'] = '$project_secret_key'

@app.route('/')
def home():
	return '<h3>OK<h3>'

if __name__ == '__main__':
	app.run()

EOF

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/test << EOF
server {
        server_name $(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p');

        location / {
                include uwsgi_params;
                uwsgi_pass unix:$(pwd)/test_app.sock;
                   proxy_temp_file_write_size 64k;

		}
}

EOF

ln -s /etc/nginx/sites-available/test /etc/nginx/sites-enabled/test


cat > /etc/systemd/system/test_app.service << EOF
[Unit]
Description=Test flask project
After=network.target
[Service]
User=root
Group=www-data
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/uwsgi --ini test_app.ini
[Install]
WantedBy=multi-user.target

EOF

cat > test_app.ini << EOF 
[uwsgi]
module = run:app
master = true
processes = 5
socket = test_app.sock
chmod-socket = 777
vacuum = true
die-on-term = true
EOF

systemctl restart nginx
systemctl enable test_app
systemctl start test_app






