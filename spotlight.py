# Spotlight for Windows
# spotlight.py
# WIP
# Ron Egli - github.com/smugzombie
# Version 0.0.3

import commands
import json
import ssl
import argparse
import sys

arguments = argparse.ArgumentParser()
arguments.add_argument('--action','-a', help="Current Action", required=True)
arguments.add_argument('--query','-q', help="Query", required=True)
args = arguments.parse_args()
action = args.action
query = args.query
configfile="apps.json"
output = ""

with open(configfile) as data_file:
		json = json.load(data_file)

appcount = len(json["apps"])
apps = json['apps']

googleEnabled = json["config"][0]["enableGoogle"]
windowsEnabled = json['config'][0]['enableWindows']
digEnabled = json['config'][0]['enableDig']

foundcount = 0

if action == "search":
		for x in xrange(appcount):
				appname = apps[x]['name']
				if appname.startswith(query) is True:
					output += ","+appname
					foundcount += 1
		if output == "":
				output = ",No Results Found for: "+query;
				if googleEnabled: output += ",Google: "+query;
				if windowsEnabled: output += ",Windows: "+query;
				if digEnabled: output += ",DigDNS: "+query;
		else:
				output += ","+str(foundcount)+" Result(s) Found for: "+query;
				if googleEnabled: output += ",Google: "+query;
				if windowsEnabled: output += ",Windows: "+query;
				if digEnabled: output += ",DigDNS: "+query;
		sys.stdout.write(output)

if action == "launch":
		for x in xrange(appcount):
				appname = apps[x]['name']
				apppath = apps[x]['path']
				if appname == query:
						apppath = apppath.replace("\\\\", "\\") #replace .replace(" ", "\\ ")
						output = "\""+apppath+"\"" 
		if output != "":
				sys.stdout.write(output)
