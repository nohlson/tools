import sys
import urllib3
import certifi
import json
import shlex
from subprocess import Popen, PIPE

class Location:
    def __init__(self, ip, city, country):
        self.ip = ip
        self.city = city
        self.country = country
        self.count = 1
		



http = urllib3.PoolManager(
    cert_reqs="CERT_REQUIRED",
    ca_certs=certifi.where())

def run(cmd):
    args = shlex.split(cmd)

    proc = Popen(args, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    #
    return out


def main():
    if len(sys.argv) < 2:
        print("Supply path")


    path = sys.argv[1]

    command = "cat " + path + " | sed -e \'s/\s.*$//\'"
    output = run(command)
    command_two = 'sed -e \'s/\s.*$//\''
    args = shlex.split(command_two)
    p = Popen(args, stdout=PIPE, stdin=PIPE, stderr=PIPE)
    grep_stdout = p.communicate(input=output)[0]
    ips = str(grep_stdout.decode()).split('\n')
    del ips[-1]
    locations = []




    base_url = "http://ip-api.com/json/"
    for ipstring in ips:
        alreadyfound = False
        response = http.request('GET', base_url + ipstring)
        responsebody = response.data.decode('utf-8')
        parsed_search_responsebody = json.loads(responsebody)
        for i in locations:
            if i.ip == parsed_search_responsebody.get('query'):
                i.count = i.count + 1
                alreadyfound = True
                break
        if not alreadyfound:
            locations.append(Location(parsed_search_responsebody.get('query'), parsed_search_responsebody.get('city'), parsed_search_responsebody.get('country')))

    locations.sort(key = lambda x: x.count, reverse = True)
    for loc in locations:
        print("{0} from {1}, {2} {3} times.".format(loc.ip, loc.city, loc.country, loc.count))

main()
