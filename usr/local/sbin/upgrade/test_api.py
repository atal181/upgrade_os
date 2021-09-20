import requests
import json
from datetime import *
from subprocess import call, run

#feed_url = "http://13.233.154.223/test.json"
feed_url = "https://0asnqck5a1.execute-api.ap-south-1.amazonaws.com/checkUpgrade"
info_file = "/etc/thinux-release-info"
file_var = "/usr/local/sbin/upgrade/var/pw_rs"
file_boot = "/boot/boottime.rc"
machineID = "/etc/machine-id"

# appending the matchineID
with open(machineID) as mach:
        mach_id = mach.read()

update_status = {}
with open(file_boot) as fh:
	for line in fh:
		try:
			params, descr = line.strip().split("=", 1)
			update_status[params] = descr.strip()
		except ValueError:
			pass

try:
	if update_status["UPDATE_STATUS"] == "update_complete":
		res = requests.get(feed_url + "?update=completed&{0}".format(mach_id.rstrip()))
		if res.status_code == 200:
			with file_boot as fb:
				fs.truncate()
				fs.write("RESET=0\n")
				fs.write("UPGRADE=0")
except:
	pass

# Fetch  info json file
with open(info_file) as fl:
	host_info = json.loads(fl.read())
	print(host_info["item"])
	host_info["item"]["MachineID"] = mach_id.rstrip()
	print(host_info)
	payload = json.dumps(host_info)
	print(payload)

# api post request
headers = {"Content-type":"application/json"}
resp = requests.post(url = feed_url, headers=headers, data = payload)
#resp = requests.get(feed_url)

# Check content of requests
print("\nAPI Endpoint: ", feed_url)
conten = resp.json()
print("\nResponce: ", conten)
print("\nStatus code: ", resp.status_code, "\n")

# Execute api responce
if resp.status_code == 200 and conten["update_required"]:
	run(["mount -o rw,remount /"], shell=True)
	with open(file_var, "w") as pw:
		pw.write("update=1\n")
		pw.write("rsync_url=" + conten["rsync_url"])
	run(["/usr/local/sbin/upgrade/update-user.sh", ">", "/var/log/update-check.log"], shell=True)
	print("Gdgd")

