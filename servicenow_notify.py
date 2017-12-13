#! /usr/bin/python
#===========================================================================================================
__author__ = "Sudharsan Soundararajan"
__version__ = "1.0"
__email__ = "Sudharsan.Sowndararajan@live.com"
#===========================================================================================================
import base64,os, sys, traceback, exceptions, re, pprint, time, json, requests, subprocess
import datetime
from optparse import OptionParser
import argparse
import urllib2
#===========================================================================================================
def defineOptions():
    parser = argparse.ArgumentParser();
    # How to connect/login to the ServiceNow instance
    parser.add_argument("--endPoint", dest="endPoint", help="The endpoint of the web service", default="https://xxx.service-now.com/api/now/table/em_event")
    parser.add_argument("--user", dest="user", help="The user name credential", default="yyyy")
    parser.add_argument("--password", dest="password", help="The user password credential", default="zzzz")

    # Fields on the Event
    parser.add_argument("--source", dest="source", help="Source of the event", default="OP5")
    parser.add_argument("--eventClass", dest="eventClass", help="Event class", default="OP5_EVENT")
    parser.add_argument("--messageKey", dest="messageKey", help="Message key", default="")
    parser.add_argument("--state", dest="state", help="state", default="")
    parser.add_argument("--node", dest="node", help="Name of the node", default="")
    parser.add_argument("--type", dest="type", help="Type of event", default="")
    parser.add_argument("--resource", dest="resource", help="Represents the resource event is associated with", default="")
    parser.add_argument("--severity", dest="severity", help="Severity of event", default="4")
    parser.add_argument("--timeOfEvent", dest="timeOfEvent", help="Time of event in GMT format", default="")
    parser.add_argument("--description", dest="description", help="Event description", default="Default event description")
    parser.add_argument("--additionalInfo", dest="additionalInfo", help="Additional event information that can be used for third-party integration or other post-alert processing", default="{}")
    parser.add_argument("--ciIdentifier", dest="ciIdentifier", help="Optional JSON string that represents a configuration item", default="{}")
    parser.add_argument("--address", dest="address", help="IP Address of the node", default="")
    parser.add_argument("--vmowner", dest="vmowner", help="VM Owner Name of the node", default="NA")
    parser.add_argument("--stack", dest="stack", help="StackName of the node", default="NA")
    parser.add_argument("--datacenter", dest="datacenter", help="dc of the node", default="NA")
    parser.add_argument("--ecosystem", dest="ecosystem", help="Eco System of the node", default="NA")
    parser.add_argument("--partner", dest="partner", help="Partner Name of the node", default="NA")
    parser.add_argument("--component", dest="component", help="Component Name of the node", default="NA")
    parser.add_argument("--subcomponent", dest="subcomponent", help="Sub-Component Name of the node", default="NA")
    parser.add_argument("--hostgroupname", dest="hostgroupname", help="Hostgroup Name of the node", default="NA")
    parser.add_argument("--servicegroupname", dest="servicegroupname", help="ServiceGroup Name of the node", default="NA")
    parser.add_argument("--serviceowner", dest="serviceowner", help="ServiceOwner Name of the node", default="NA")
    parser.add_argument("--region", dest="region", help="Region Name of the node", default="NA")
    parser.add_argument("--market", dest="market", help="Market Name of the node", default="NA")
    parser.add_argument("--network", dest="network", help="Network Zone Name of the node", default="NA")
    parser.add_argument("--laststate", dest="laststate", help="Last State for event", default="NA")
    parser.add_argument("--eventid", dest="eventid", help="NA", default="NA")
    parser.add_argument("--problemid", dest="problemid", help="NA", default="NA")
    parser.add_argument("--attempt", dest="attempt", help="NA", default="NA")
    parser.add_argument("--maxattempt", dest="maxattempt", help="NA", default="NA")
    parser.add_argument("--stateid", dest="stateid", help="NA", default="NA")
    parser.add_argument("--laststateid", dest="laststateid", help="NA", default="NA")
    parser.add_argument("--notes", dest="notes", help="NA", default="NA")
    parser.add_argument("--alias", dest="alias", help="NA", default="NA")
    args = parser.parse_args()
    return args
#============================================================================================================
def execute():
    if (args.timeOfEvent == ""):
      args.timeOfEvent = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S');

    if args.eventClass == "":
        args.eventClass = args.source

    if args.messageKey == "":
        args.messageKey = args.source +"__" + args.node +"__" + args.type + "__" + args.resource

    data = {"source" : args.source, "node" : args.node , "type" : args.type,
            "resource" : args.node,
            "time_of_event" : args.timeOfEvent, "description" : args.description,
            "ci_identifier" : args.ciIdentifier, "event_class" : args.eventClass, "message_key": args.messageKey,
            "u_address" : args.address, "additional_info" : [ {"Service_Health" : args.additionalInfo},
            {"stack" : args.stack}, {"severity" : args.severity}, {"datacenter" : args.datacenter}, {"ecosystem" : args.ecosystem},
            {"partner" : args.partner}, {"component" : args.component}, {"sub_component" : args.subcomponent},
            {"hostgroupname" : args.hostgroupname}, {"servicegroupname" : args.servicegroupname}, {"serviceowner" : args.serviceowner},
            {"region" : args.region}, {"market" : args.market}, {"network" : args.network}, {"laststate" : args.laststate},
            {"eventid" : args.eventid}, {"problemid" : args.problemid}, {"attempt" : args.attempt}, {"maxattempt" : args.maxattempt},
            {"stateid" : args.stateid}, {"laststateid" : args.laststateid}, {"notes" : args.notes}, {"alias" : args.alias},
	          {"vmowner" : args.vmowner} ], "metric_name" : args.type, "severity" : args.severity}
    data = json.dumps(data)

    LOG = open("/opt/monitor/var/servicenow_event.log", 'a')
    LOG.write( "[%s] - %s\n" % (args.timeOfEvent,data))
    LOG.close
#    proxy = urllib2.ProxyHandler({'https': 'proxy:3128'})
#    opener = urllib2.build_opener(proxy)
#    urllib2.install_opener(opener)
    headers = {'Content-type': 'application/json', 'Accept': 'application/json'}
    request = urllib2.Request(url=args.endPoint, data=data, headers=headers)
    base64string = base64.urlsafe_b64encode('%s:%s' % (args.user, args.password))
    request.add_header("Authorization", "Basic %s" % base64string)
    f = urllib2.urlopen(request)
    f.read()
    f.close()
#============================================================================================================
if __name__ == '__main__':
  args = defineOptions();
  execute();
