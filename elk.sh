
echo "======== ELK STACK SETUP! Credit:PUTRAS  ========"
echo "Y for install, N for UNINSTALL! "
read inorun

if [[ $inorun == "y" || $inorun == "Y" ]]
	then
	OS=$(cat /etc/os-release | grep PRETTY_NAME)
	echo ""
	echo "======== YOUR OS : ${OS} ========="
	echo ""
	if [[ $OS  == *"Ubuntu"* ]]
	        then
		apt-get install unzip
	        echo ""
		echo "====== INSTALLING NEWEST ELK STACK ON Ubuntu OS ======"
		echo ""
	        #wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	        #echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list
	        #apt update
	        #wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.2.0-linux-x86_64.tar.gz"
	        #wget "https://artifacts.elastic.co/downloads/kibana/kibana-8.2.0-linux-x86_64.tar.gz"
	        #wget "https://artifacts.elastic.co/downloads/logstash/logstash-8.2.0-linux-x86_64.tar.gz"
	        #tar -xf elasticsearch-8.2.0-linux-x86_64.tar.gz
	        #tar -xf kibana-8.2.0-linux-x86_64.tar.gz
	        #tar -xf logstash-8.2.0-linux-x86_64.tar.gz
	        #cd elasticsearch-8.2.0-linux-x86_64
		echo "====== INSTALL AND CONFIGURING ELASTICSEARCH ====="
		echo ""
	        apt-get install elasticsearch > secinfo
	        #apt-get install logstash
	        systemctl daemon-reload; systemctl enable elasticsearch.service
		es_ip_def=$(cat /etc/elasticsearch/elasticsearch.yml | grep  '#network.host: ')
		ip_cst=$(ifconfig | grep 'inet.*broadcast' | sed -e 's/.*inet\(.*\)  netmask.*/\1/')
		es_port_def=$(cat /etc/elasticsearch/elasticsearch.yml | grep  '#http.port: ')
		#echo es_ip_def=$(echo "$es_ip_def" | sed 's/192.168.0.1/$es_ip_cst/')
		mv secinfo /etc/elasticsearch/secinfo
		cd /etc/elasticsearch/
		if [[ ! -z "$es_ip_def" ]]
			then
			echo "IP DEFAULT ON elasticsearch.yml CHANGE TO IP DEVICE"
			sed -i '56d' elasticsearch.yml
			sed -i "56 i network\.host\:$ip_cst" elasticsearch.yml
		fi
		if [[ $es_port_def == *"http.port: 9200"* ]]
			then
			echo "ELASTICSEARCH DEFAULT PORT FOUND, CUSTOM YOURS ELASTICSEARCH PORT !"
			read es_port_cst
			sed -i "s/$es_port_def/http\.port\: $es_port_cst/g" elasticsearch.yml
		fi
                echo "====== CHECK file /etc/elasticsearch/secinfo (CREDENTIAL)!! ====="
		echo "====== CHECK FILE /etc/elasticsearch/elasticsearch.yml LATER, JUST MAKESURE network.host AND http.port !! ====="
		echo "====== WAIT ======"
		systemctl restart elasticsearch
		echo  "====== ElasticSearch DONE ======"
		echo ""
		echo "====== INSTALL & CONFIGURING KIBANA ====="
		apt-get install kibana
		systemctl daemon-reload; systemctl start kibana; systemctl enable kibana
		cd /etc/kibana
	        kb_ip_def=$(cat /etc/kibana/kibana.yml | grep  'server.host: ')
	        kb_port_def=$(cat /etc/kibana/kibana.yml | grep  'server.port: ')

		if [[ $kb_ip_def == *'#server.host: "localhost"'* ]]
			then
			echo ""
			#echo "====== server.host USE LOCALHOST ADDRESS! input the KIBANA IP ADDRESS ! ======"
			#read kb_ip_cst
			sed -i '15d' kibana.yml
			sed -i "15 i server\.host\:$ip_cst" kibana.yml
			#sed -i s/$kb_ip_def/server\.host\: $ip_cst/g" kibana.yml
		fi
	        if [[ $kb_port_def != "server.port: "* ]]
	                then
	                echo "====== KIBANA server.port USE DEFAULT PORT, YOU CAN CHANGE TO ANOTHER PORT! CHOOSE CUSTOM PORT ! ====== "
	                read kb_port_cst
			kb_port_line=$(awk '/server.port: 5601/{print NR}' kibana.yml)
	                #echo "KIBANA PORT : ${kb_port_cst}"
			#sed -i $kb_port_line'd" kibana.yml
			sed -i "$kb_port_line i server\.port\: $kb_port_cst" kibana.yml
	                #sed -i s/$kb_port_def/server\.port\: $kb_port_cst/g" kibana.yml
		else
			echo "THERE ARE ANY PORT HAS BEEN OPEN"
	 	fi
                systemctl restart kibana
		echo "====== KIBANA DONE ======"
		echo ""
		cd /usr/share/elasticsearch
                echo "====== GENERATING CERTIFICATE FOR FLEET-SERVER ======"
		echo "====== SAVE AS ca.zip ! ======"
		./bin/elasticsearch-certutil ca --pem; unzip ca.zip
		echo ""
		echo "====== NOW, SAVE AS fleet-server.zip ! ======"
		./bin/elasticsearch-certutil cert --name fleet-server --ca-cert /usr/share/elasticsearch/ca/ca.crt --ca-key /usr/share/elasticsearch/ca/ca.key --ip $ip_cst --pem; unzip fleet-server.zip
		echo ""
		echo "======  CERTIFICATE DIRECTORY IS ON /usr/share/elasticsearch/... ====== "
		echo ""
	  	./bin/elasticsearch-create-enrollment-token -s kibana
		echo "COPY THE TOKEN"
		echo "AND PASTE BELOW!"; cd /usr/share/kibana/bin
		./kibana-setup 

	else
	echo "CentOS"
	fi

elif [[ $inorun == "N" || $inorun == "n" ]]
	then
	echo "Are you sure to uninstall ELK Stack?"
	echo "1 - just uninstall and dont delete the configurations"
	echo "2 - uninstall and delete all configurations"
	echo "enter the number"
	read unext
		if [[ $unext == "1" ]]
		then
		apt-get remove elasticsearch kibana logstash
		elif [[ $unext == "2" ]]
		then
		apt-get remove \--purge elasticsearch kibana logstash; rm \-r \-f /var/lib/elasticsearch /var/lib/kibana /var/lib/logstash /usr/share/elasticsearch /usr/share/kibana /usr/share/logstash /etc/elasticsearch /etc/kibana
		echo "THOSE FOLDER HAVE BEEN DELETED !!"
		fi
fi
