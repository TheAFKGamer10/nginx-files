#!/bin/bash

#      ___    ________ __    __  __           __  _            
#     /   |  / ____/ //_/   / / / /___  _____/ /_(_)___  ____ _
#    / /| | / /_  / ,<     / /_/ / __ \/ ___/ __/ / __ \/ __ `/
#   / ___ |/ __/ / /| |   / __  / /_/ (__  ) /_/ / / / / /_/ / 
#  /_/  |_/_/   /_/ |_|  /_/ /_/\____/____/\__/_/_/ /_/\__, /  
#                                                     /____/   
#
# https://afkhosting.win | license: GNU General Public License v3.0

if [ ! command -v sqlite3 &> /dev/null ]; then
    apt install -y sqlite3 -qq
fi

if [ ! command -v nginx &> /dev/null ]; then
    apt install -y nginx -qq
    rm /etc/nginx/sites-enabled/default
fi

if [ ! command -v certbot &> /dev/null ]; then
    apt install -y certbot -qq
    apt install -y python3-certbot-nginx -qq
fi

getdbdefaults () {
    if [ -f nginx-files.db ]; then
        maindomain=$(sqlite3 nginx-files.db "SELECT domain FROM root_domain WHERE id = 1")
        ptersubdomain=$(sqlite3 nginx-files.db "SELECT subdomain FROM subdomains WHERE id = 1")
        ctrlsubdomain=$(sqlite3 nginx-files.db "SELECT subdomain FROM subdomains WHERE id = 2")
        snaUIsubdomain=$(sqlite3 nginx-files.db "SELECT subdomain FROM snailycadconfig WHERE id = 1")
        snaAPIsubdomain=$(sqlite3 nginx-files.db "SELECT subdomain FROM snailycadconfig WHERE id = 2")
        snaUIport=$(sqlite3 nginx-files.db "SELECT port FROM snailycadconfig WHERE id = 1")
        snaAPIport=$(sqlite3 nginx-files.db "SELECT port FROM snailycadconfig WHERE id = 2")
    else        
        maindomain=""
        ptersubdomain=""
        ctrlsubdomain=""
        snaUIsubdomain=""
        snaAPIsubdomain=""
        snaUIport=""
        snaAPIport=""
    fi
    
    getmaindomain
}

getmaindomain () {
    clear
    if [[ "$wrong" == true ]]; then
        echo ""
        echo "Invalid input. Please enter a domain."	
        echo ""
	fi
	echo "Copyright © 2023 AFK Hosting"
	echo "This script is licensed under the GNU General Public License v3.0"
	echo "Built By The AFK Gamer"
    echo ""
    echo "Please enter your root domain WITH OUT any sub-domains." 
    read -p "Domain: " -i $maindomain -e maindomain
    if [[ $maindomain =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$ ]]; then
        wrong="false"
        question
    else
        wrong="true"
        getmaindomain
    fi
}

question () {
	clear
	if [[ "$wrong" == true ]]; then
		echo ""
		echo "Invalid input. Please try again."	
        echo ""
	fi
    echo "What service would you like to install the files for?"
	echo "[1] Pterodactyl"
	echo "[2] Ctrlpanel"
	echo "[3] Snaily Cad"
	read -p "Please enter a number: " mainchoice

	if [[ "$mainchoice" == 1 ]]; then
		wrong="false"
        Pterodactyl
	elif [[ "$mainchoice" == 2 ]]; then
		wrong="false"
        CtrlPanel
	elif [[ "$mainchoice" == 3 ]]; then
		wrong="false"
        SnailyCadQuestionare
	else
		wrong="true"
		question
	fi
}

#
# Start Services Below Here
#

Pterodactyl () {
    clear
    echo -e "Please enter the sub-domain you would like to use for Pterodactyl.\n\nThis does not include the root domain or the peroid unless it is nested. For example, if you wanted to use panel.$maindomain, you would enter 'panel'."
    read -p "Sub-domain: " -i $ptersubdomain -e ptersubdomain

    echo "
server {
    listen 80;
    server_name $ptersubdomain.$maindomain;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
" > /etc/nginx/sites-enabled/pterodactyl.conf

    finishedcmds
}

CtrlPanel () {
    clear
    echo -e "Please enter the sub-domain you would like to use for CtrlPanel.\n\nThis does not include the root domain or the peroid unless it is nested. For example, if you wanted to use client.$maindomain, you would enter 'client'."
    read -p "Sub-domain: " -i $ctrlsubdomain -e ctrlsubdomain

    echo "
server {
        listen 80;
        root /var/www/controlpanel/public;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $ctrlsubdomain.$maindomain;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
" > /etc/nginx/sites-enabled/ctrlpanel.conf

    finishedcmds
}

SnailyCadQuestionare () {
    clear
    echo -e "Please enter the sub-domain you would like to use for SnailyCad Client.\n\nThis does not include the root domain or the peroid unless it is nested. For example, if you wanted to use cad.$maindomain, you would enter 'cad'."
    if [[ "$wrong" == true ]]; then
        echo ""
        echo "Something you inputed was not correct. Try again."	
        echo ""
    elif [[ "$wrong" == "same" ]]; then
        echo ""
        echo "You can not use the same sub-domain or port for both SnailyCad Client and SnailyCad API."
        echo ""
    fi
    read -p "Sub-domain: " -i $snaUIsubdomain -e snaUIsubdomain

    clear
    echo -e "Please enter the sub-domain you would like to use for SnailyCad API.\n\nThis does not include the root domain or the peroid unless it is nested. For example, if you wanted to use cad-api.$maindomain, you would enter 'cad-api'."
    read -p "Sub-domain: " -i $snaAPIsubdomain -e snaAPIsubdomain

    if [[ "$snaUIsubdomain" == "$snaAPIsubdomain" ]]; then
        wrong="same"
        snaUIsubdomain=""
        snaAPIsubdomain=""
        SnailyCadQuestionare
    else
        wrong="false"
    fi

    clear
    echo -e "Please enter the port for your Snaily Cad Client. This is the port in your .env file named 'PORT_CLIENT'. Default is 3000."
    read -p "Port: " -i $snaUIport -e snaUIport

    if [[ "$snaUIport" =~ ^[0-9]+$ ]]; then
        wrong="false"
    else
        wrong="true"
        snaUIport=""
        SnailyCadQuestionare
    fi

    clear
    echo -e "Please enter the port for your Snaily Cad API. This is the port in your .env file named 'PORT_API'. Default is 8080."
    read -p "Port: " -i $snaAPIport -e snaAPIport

    if [[ "$snaAPIport" =~ ^[0-9]+$ && ! "$snaUIport" == "$snaAPIport" ]]; then
        wrong="false"
        SnailyCadFiles
    elif [[ ! "$snaAPIport" =~ ^[0-9]+$ ]]; then
        wrong="true"
        snaAPIport=""
        SnailyCadQuestionare
    elif [[ "$snaUIport" == "$snaAPIport" ]]; then
        wrong="same"
        snaUIport=""
        snaAPIport=""
        SnailyCadQuestionare
    else
        wrong="true"
        snaAPIport=""
        SnailyCadQuestionare
    fi
}

SnailyCadFiles () {
# API
    echo "
server {
    server_name $snaAPIsubdomain.$maindomain;

    location / {
        proxy_pass http://localhost:$snaAPIport;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }


    # Security headers
    add_header X-XSS-Protection          \"1; mode=block\" always;
    add_header X-Content-Type-Options    \"nosniff\" always;
    add_header Referrer-Policy           \"no-referrer\" always;
    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\" always;
    add_header X-DNS-Prefetch-Control on;
    add_header Cross-Origin-Resource-Policy \"cross-origin\";

    listen 80;
}
" > /etc/nginx/sites-enabled/snailycadapi.conf

# UI
    echo "
server {
    server_name $snaUIsubdomain.$maindomain;

    location / {
      proxy_pass http://localhost:$snaUIport; 
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection 'upgrade';
      proxy_set_header Host \$host;
      proxy_cache_bypass \$http_upgrade;
    }


    # Security headers
    add_header X-XSS-Protection          \"1; mode=block\" always;
    add_header X-Content-Type-Options    \"nosniff\" always;
    add_header Referrer-Policy           \"no-referrer\" always;
    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\" always;
    add_header X-DNS-Prefetch-Control on;
    add_header Cross-Origin-Resource-Policy \"same-site\";

    listen 80;
}
" > /etc/nginx/sites-enabled/snailycadui.conf

    finishedcmds
}

finishedcmds () {

    # Creates a SQLITE database to save information bewtween runs.
    sqlite3 nginx-files.db <<'END_SQL'
        CREATE TABLE IF NOT EXISTS root_domain (
            `id` INTEGER PRIMARY KEY,
            `domain` TEXT
        ) ; 
        CREATE TABLE IF NOT EXISTS subdomains (
            `id` INTEGER PRIMARY KEY,
            `service` TEXT NOT NULL, 
            `subdomain` TEXT NOT NULL
        ) ;
        CREATE TABLE IF NOT EXISTS snailycadconfig (
            `id` INTEGER PRIMARY KEY,
            `service` TEXT NOT NULL, 
            `subdomain` TEXT NOT NULL,
            `port` INTEGER NOT NULL
        ) ;
END_SQL
    sqlite3 "nginx-files.db" "INSERT OR REPLACE INTO root_domain (id, domain) VALUES ( '1', '$maindomain' )"

    if [[ "$mainchoice" == 1 ]]; then
        sqlite3 "nginx-files.db" "INSERT OR REPLACE INTO subdomains ( id, service, subdomain) VALUES ( '1', 'Pterodactyl', '$ptersubdomain')"
        certbot --nginx -d $ptersubdomain.$maindomain
    elif [[ "$mainchoice" == 2 ]]; then
        sqlite3 "nginx-files.db" "INSERT OR REPLACE INTO subdomains (id, service, subdomain) VALUES ( '2', 'CtrlPanel', '$ctrlsubdomain')"
        certbot --nginx -d $ctrlsubdomain.$maindomain
    elif [[ "$mainchoice" == 3 ]]; then
        sqlite3 "nginx-files.db" "INSERT OR REPLACE INTO snailycadconfig (id, service, subdomain, port) VALUES ( '1', 'SnailyCadUI', '$snaUIsubdomain', '$snaUIport')"
        sqlite3 "nginx-files.db" "INSERT OR REPLACE INTO snailycadconfig (id, service, subdomain, port) VALUES ( '2', 'SnailyCadAPI', '$snaAPIsubdomain', '$snaAPIport')"
        certbot --nginx -d $snaUIsubdomain.$maindomain
        certbot --nginx -d $snaAPIsubdomain.$maindomain
    fi

    systemctl restart nginx
}

getdbdefaults