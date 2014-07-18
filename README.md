ip2map - Plots IPs on a Map
======

Debian, ElasticSearch, Kibana and bettermap rocks \m/

Setup:

chmod a+x install.sh

./install.sh

Usage:

ip2map < csv-file-path >

Instructions:

1. The CSV file should first row as column identifier/name
2. The column with IPs should be named IP
3. Column names are case-specific
4. Specifying the same index type name again, updates or appends to the previous data in the index type
5. In case of files with IPs only, specify, IP, asthe tooltip field value

Examples CSV/s will be added soon.
