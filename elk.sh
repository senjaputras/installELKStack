echo "========TAKE A NOTE YOU IP ADDRESS FIRST PLEASE ========"
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
		sudo apt-get install apt-transport-https
		sudo apt-get update
		echo "====== Overwrite Keyring if Exist ====="
		wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
		echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
	    	echo ""
		echo "====== INSTALLING NEWEST ELK STACK ON Ubuntu OS ======"
		echo ""
	        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
		echo "====== INSTALL AND CONFIGURING ELASTICSEARCH ====="
		echo ""
		apt-get update
		echo "DOWNLOAD ELK? Y or N"
		read download
		echo "WHICH VERSION ELK STACK?"
		read ELK_VERS
		if [[ $download == "y" || $download == "Y" ]]
			then
			curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELK_VERS}-amd64.deb
			curl -L -O https://artifacts.elastic.co/downloads/kibana/kibana-${ELK_VERS}-amd64.deb
		fi
	        dpkg -i elasticsearch-${ELK_VERS}-amd64.deb | grep "generated password" > secinfo
	        systemctl daemon-reload; systemctl enable elasticsearch.service
		#es_ip_def=$(cat /etc/elasticsearch/elasticsearch.yml | grep  '#network.host: ')
		echo "INPUT YOUR KIBANA IP ADDRESS : "
		read ip_cst
		es_port_def=$(cat /etc/elasticsearch/elasticsearch.yml | grep  '#http.port: ')
		mv secinfo /etc/elasticsearch/secinfo
		#cd /etc/elasticsearch/
		if [[ $es_port_def == *"http.port: 9200"* ]]
			then
			echo "ELASTICSEARCH DEFAULT PORT FOUND, CUSTOM YOURS ELASTICSEARCH PORT !"
			read es_port_cst
			sed -i "s/$es_port_def/http\.port\: $es_port_cst/g" /etc/elasticsearch/elasticsearch.yml
		fi
                echo "====== CHECK file /etc/elasticsearch/secinfo (CREDENTIAL)!! ====="
		echo "====== CHECK FILE /etc/elasticsearch/elasticsearch.yml LATER, JUST MAKESURE network.host AND http.port !! ====="
		echo "====== WAIT ======"
		systemctl restart elasticsearch
		echo  "====== ElasticSearch DONE ======"
		echo ""
		echo "====== INSTALL & CONFIGURING KIBANA ====="
		dpkg -i kibana-${ELK_VERS}-amd64.deb
		systemctl daemon-reload; systemctl start kibana; systemctl enable kibana
		#cd /etc/kibana
	        kb_ip_def=$(cat /etc/kibana/kibana.yml | grep  'server.host: ')
	        kb_port_def=$(cat /etc/kibana/kibana.yml | grep  'server.port: ')

		if [[ $kb_ip_def == *'#server.host: "localhost"'* ]]
			then
			echo ""
			sed -i '15d' kibana.yml
		  	sed -i "15 i server\.host\: $ip_cst" /etc/kibana/kibana.yml
		fi
	        if [[ $kb_port_def != "server.port: "* ]]
	                then
	                echo "====== KIBANA server.port USE DEFAULT PORT, YOU CAN CHANGE TO ANOTHER PORT! CHOOSE CUSTOM PORT ! ====== "
	                read kb_port_cst
			kb_port_line=$(awk '/server.port: 5601/{print NR}' /etc/kibana/kibana.yml)
			sed -i "$kb_port_line i server\.port\: $kb_port_cst" /etc/kibana/kibana.yml
		else
			echo "THERE ARE ANY PORT HAS BEEN OPEN"
	 	fi
                systemctl restart kibana
		echo "====== KIBANA DONE ======"
		echo ""
		cd /usr/share/elasticsearch
                echo "====== GENERATING CERTIFICATE FOR FLEET-SERVER ======"
		echo | ./bin/elasticsearch-certutil ca --pem; unzip elastic-stack-ca.zip
		echo ""
		echo | ./bin/elasticsearch-certutil cert --name fleet-server --ca-cert /usr/share/elasticsearch/ca/ca.crt --ca-key /usr/share/elasticsearch/ca/ca.key --ip $ip_cst --pem; unzip certificate-bundle.zip
		echo ""
		echo "======  CERTIFICATE DIRECTORY IS ON /usr/share/elasticsearch/... ====== "
		echo ""
	  	./bin/elasticsearch-create-enrollment-token -s kibana
		echo "COPY THE TOKEN"
		echo "AND PASTE BELOW!"; cd /usr/share/kibana/bin
		./kibana-setup 
		/usr/share/kibana/bin/kibana-encryption-keys generate | grep "encryptionKey:" >> /etc/kibana/kibana.yml
		service kibana restart
		echo "INSTALL ELASTIC-AGENT? Y/N "
		read agent
			if [[ $agent == "y" || $agent == "Y" ]]
				then
				echo ${ip_cst}
				echo ${es_port_cst}
				echo ${kb_port_cst}
				curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-${ELK_VERS}-linux-x86_64.tar.gz
				sudo tar xzvf elastic-agent-${ELK_VERS}-linux-x86_64.tar.gz
                                cd elastic-agent-${ELK_VERS}-linux-x86_64
                                #sudo ./elastic-agent install --fleet-server-es=https://$ip_cst:$es_port_cst --fleet-server-service-token=$(curl -k -u "elastic:$(awk -F ' : ' {'print $2'} < /etc/elasticsearch/secinfo | tr -d " \t\n\r")" -s -X POST http://$ip_cst:$kb_port_cst/api/fleet/service-tokens --header 'kbn-xsrf: true' | jq -r .value) --fleet-server-policy=fleet-server-policy --fleet-server-es-ca-trusted-fingerprint=$(sudo openssl x509 -fingerprint -sha256 -noout -in /etc/elasticsearch/certs/http_ca.crt | awk -F"=" {' print $2 '} | sed s/://g)
				sudo ./elastic-agent install --fleet-server-es=https://${ip_cst}:${es_port_cst} --fleet-server-service-token=$(curl -k -u "elastic:$(awk -F ' : ' {'print $2'} < /etc/elasticsearch/secinfo | tr -d " \t\n\r")" -s -X POST http://{ip_cst}:${kb_port_cst}/api/fleet/service-tokens --header 'kbn-xsrf: true' | jq -r .value) --fleet-server-policy=fleet-server-policy --fleet-server-es-ca-trusted-fingerprint=$(sudo openssl x509 -fingerprint -sha256 -noout -in /etc/elasticsearch/certs/http_ca.crt | awk -F"=" {' print $2 '} | sed s/://g)
			fi
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
