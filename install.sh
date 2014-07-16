#!/bin/bash
#ip2map installer - spid3y
apt-get install python-virtualenv gzip apache2 openjdk-7-jre

javahome=$(find /usr/lib/jvm/*7* -name javac | sed "s:bin/javac::")
rm -Rf /opt/ip2map
cd /opt; mkdir ip2map; cd ip2map
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.2.tar.gz
tar -xvf elasticsearch*.tar.gz
rm elasticsearch*.tar.gz
mv elasticsearch-1.2.2 elasticsearch
xterm -e  "JAVA_HOME=$javahome /opt/ip2map/elasticsearch/bin/elasticsearch" &

virtualenv /opt/ip2map/env
source /opt/ip2map/env/bin/activate
pip install maxminddb
pip install pycurl      
mkdir geo; cd geo
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
gunzip GeoLite2-City.mmdb.gz
cd ..
wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz
tar -xvf kibana*.tar.gz
rm kibana*.tar.gz
mv kibana* /var/www/kibana/
cat > ip2map.py <<EOF
#!/usr/bin/env /opt/ip2map/env/bin/python
#ip2map by spid3y
import maxminddb
import json
import sys
import hashlib
import pycurl
import cStringIO
from os import popen
from time import sleep



data = []
columns = None
if not len( sys.argv ) == 2:
        print "\nSpecify filename correctly."
        print "Usage: ip2map <IP csv file>"
        print "CSV file format : \n\tIP,Field1,Field2\n\t8.8.8.8,Google Inc,google.com"
        print "The coulmn with IPs should contain the column title as IP"
        print "Firt row is the column name identifier in the CSV. All names are case-sensitive. \n"
        exit()
        
esStatus = popen('netstat -an | grep 9200 | grep LIST | wc -l')

if '0' in esStatus.read():
        javahome = popen('find /usr/lib/jvm/*7* -name javac | sed "s:bin/javac::"')
        javahome = javahome.read().replace("\n", "")
        popen('xterm -e  "JAVA_HOME=%s /opt/ip2map/elasticsearch/bin/elasticsearch" &' % javahome)
        sleep(2)
 
buf = cStringIO.StringIO()


indexName = raw_input("Index type name (your map data will be indexed by this type under 'ip2map' index in ElasticSearch\n: ").replace(" ", "")
pageName = raw_input("Page Title: ")
mapName = raw_input("Map Title: ")
toolTip =  raw_input("Tooltip column name (The Column from the CSV file, which is displayed upon marker's hover)\n: ")
if indexName == "":
        print "Invalid input"
        exit()


jsonOut = """
{
  "title": "%s",
  "services": {
    "query": {
      "list": {
        "0": {
          "query": "*",
          "alias": "",
          "color": "#7EB26D",
          "id": 0,
          "pin": false,
          "type": "lucene",
          "enable": true
        }
      },
      "ids": [
        0
      ]
    },
    "filter": {
      "list": {
        "0": {
          "type": "terms",
          "field": "_type",
          "value": "%s",
          "mandate": "must",
          "active": true,
          "alias": "",
          "id": 0
        }
      },
      "ids": [
        0
      ]
    }
  },
  "rows": [
    {
      "title": "Options",
      "height": "50px",
      "editable": true,
      "collapse": false,
      "collapsable": true,
      "panels": [
        {
          "error": false,
          "span": 12,
          "editable": true,
          "type": "bettermap",
          "loadingEditor": false,
          "field": "cords",
          "size": 20000,
          "height" : "600px",
          "spyable": true,
          "tooltip": "%s",
          "zoom" : 0,
          "queries": {
            "mode": "all",
            "ids": [
              0
            ]
          },
          "title": "%s"
        }
      ],
      "notice": false
    },
    {
      "title": "Graph",
      "height": "250px",
      "editable": true,
      "collapse": false,
      "collapsable": true,
      "panels": [
        {
          "error": false,
          "span": 3,
          "editable": true,
          "group": [
            "default"
          ],
          "type": "terms",
          "queries": {
            "mode": "all",
            "ids": [
              0
            ]
          },
          "field": "_type",
          "exclude": [],
          "missing": true,
          "other": true,
          "size": 10,
          "order": "count",
          "style": {
            "font-size": "10pt"
          },
          "donut": false,
          "tilt": false,
          "labels": true,
          "arrangement": "horizontal",
          "chart": "table",
          "counter_pos": "above",
          "spyable": true,
          "title": "Document Types",
          "tmode": "terms",
          "tstat": "total",
          "valuefield": ""
        },
        {
          "error": false,
          "span": 9,
          "editable": true,
          "type": "table",
          "loadingEditor": false,
          "size": 100,
          "pages": 5,
          "offset": 0,
          "sort": [
            "IP",
            "desc"
          ],
          "overflow": "min-height",
          "fields": [
            "IP",
            "geo.location.time_zone",
            "geo.continent.names.en",
            "geo.country.names.en"
          ],
          "highlight": [],
          "sortable": true,
          "header": true,
          "paging": true,
          "field_list": true,
          "all_fields": false,
          "trimFactor": 300,
          "localTime": false,
          "timeField": "@timestamp",
          "spyable": true,
          "queries": {
            "mode": "all",
            "ids": [
              0
            ]
          },
          "style": {
            "font-size": "9pt"
          },
          "normTimes": true,
          "title": "Data"
        }
      ],
      "notice": false
    },
    {
      "title": "Events",
      "height": "650px",
      "editable": true,
      "collapse": false,
      "collapsable": true,
      "panels": [],
      "notice": false
    }
  ],
  "editable": true,
  "index": {
    "interval": "none",
    "pattern": "[logstash-]YYYY.MM.DD",
    "default": "_all",
    "warm_fields": false
  },
  "style": "dark",
  "failover": false,
  "panel_hints": true,
  "loader": {
    "save_gist": false,
    "save_elasticsearch": true,
    "save_local": true,
    "save_default": true,
    "save_temp": true,
    "save_temp_ttl_enable": true,
    "save_temp_ttl": "30d",
    "load_gist": true,
    "load_elasticsearch": true,
    "load_elasticsearch_size": 20,
    "load_local": true,
    "hide": false
  },
  "pulldowns": [
    {
      "type": "query",
      "collapse": false,
      "notice": false,
      "query": "*",
      "pinned": true,
      "history": [],
      "remember": 10,
      "enable": true
    },
    {
      "type": "filtering",
      "collapse": true,
      "notice": true,
      "enable": true
    }
  ],
  "nav": [
    {
      "type": "timepicker",
      "collapse": false,
      "notice": false,
      "status": "Stable",
      "time_options": [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d"
      ],
      "refresh_intervals": [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ],
      "timefield": "@timestamp",
      "enable": false,
      "now": false
    }
  ],
  "refresh": false
}
""" % (pageName, indexName, toolTip, mapName,)




        
geo = maxminddb.Reader('/opt/ip2map/geo/GeoLite2-City.mmdb')

ipFile = open( sys.argv[1], 'r' )

for line in ipFile.readlines():
        try:
                row = line.replace('\r', '').replace('\n', '').split(',')
                id = hashlib.md5(line).hexdigest()
                if columns == None:
                      columns = row  
                else:
                        i = 0
                        temp = {}
                        for x in columns:
                                temp[x] = row[i]
                                i+=1;
                        c = pycurl.Curl()
                        temp['geo']   = geo.get( temp['IP'] )
                        temp['cords'] = [ temp['geo']['location']['longitude'], temp['geo']['location']['latitude'] ]
                        c.setopt(pycurl.URL, "http://localhost:9200/ip2map/%s/%s" % (indexName, id)      )
                        c.setopt(pycurl.CUSTOMREQUEST, "PUT")
                        c.setopt(c.WRITEFUNCTION, buf.write)
                        c.setopt(pycurl.POST, 1)
                        c.setopt(pycurl.POSTFIELDS, '%s' % json.dumps( temp ))
                        c.perform()
                        
        except:
                pass
                
kibana = open( "/var/www/kibana/app/dashboards/%s.json" % (indexName), "w")
kibana.write(jsonOut)
kibana.close()
ipFile.close()
print "\nOpen the followin URL to access your Map: "
print "\thttp://localhost/kibana/#/dashboard/file/%s.json\n" % indexName
EOF
chmod a+x ip2map.py
ln -sf /opt/ip2map/ip2map.py /usr/bin/ip2map
