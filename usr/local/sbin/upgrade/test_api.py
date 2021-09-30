import requests
import json
from subprocess import call, run

#feed_url = "http://13.233.154.223/test.json"
#feed_url = "https://0asnqck5a1.execute-api.ap-south-1.amazonaws.com/checkUpgrade"
feed_url = "https://ueq9xvupy5.execute-api.ap-south-1.amazonaws.com/" #upgrade_status"
info_file = "/etc/thinux-release-info"
file_var = "/usr/local/sbin/upgrade/var/pw_rs"
file_boot = "/boot/boottime.rc"
machineID = "/etc/machine-id"
headers = {"Content-type":"application/json"}
update_done_info = {}


def file_opration(machineID, info_file):

	# appending the matchineID
	with open(machineID) as mach:
        	mach_id = mach.read()

	with open(file_boot) as fh:
		for line in fh:
			try:
				params, descr = line.strip().split("=", 1)
				update_done_info[params] = descr.strip()
			except ValueError:
				pass

	# Fetch  info json file
	with open(info_file) as fl:
        	host_info = json.loads(fl.read())
        	print(host_info)
        	host_info["machine_id"] = mach_id.rstrip()
        	print(host_info)
        	payload = json.dumps(host_info)
        	print(payload)
	return payload


def update_done(feed_url, file_boot, payload):
	print(update_done_info)
	if "UPDATE_STATUS" in update_done_info and update_done_info["UPDATE_STATUS"] == "update_complete":
		# Appening upgrade status to main payload
		host_info = json.loads(payload)
		host_info["upgrade_status"] =  "completed"
		payload = json.dumps(host_info)
		print(payload)
		res = requests.post(feed_url + "upgrade_status", payload, headers=headers)
		print("Status code of upgrade_status: ", res.status_code)
		print(res.text)
		if res.status_code == 200:
			with open(file_boot, "+w") as fb:
				fb.truncate()
				fb.write("RESET=0\n")
				fb.write("UPGRADE=0")


def check_update(feed_url, file_var, payload):
	# api post request
	resp = requests.post(url = feed_url + "check_upgrade", headers=headers, data = payload)
	#resp = requests.get(feed_url)

	# Check content of requests
	print("\nAPI Endpoint: ", feed_url)
	conten = resp.json()
	print("\nResponce: ", conten)
	print("\nStatus code of check update: ", resp.status_code, "\n")

	# Execute api responce
	if resp.status_code == 200 and conten["update_required"]:
		run(["mount -o rw,remount /"], shell=True)
		with open(file_var, "w") as pw:
			pw.write("update=1\n")
			pw.write("rsync_url=" + conten["rsync_url"])
		run(["/usr/local/sbin/upgrade/update-user.sh" + " >" + " /var/log/update-check.log"], shell=True)


if __name__ == "__main__":
	payload = file_opration(machineID, info_file)
	check_update(feed_url, file_var, payload)
	update_done(feed_url, file_boot, payload)
