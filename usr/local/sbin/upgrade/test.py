import requests
from datetime import *
from subprocess import call, run

feed_url = "http://13.233.154.223/test.json"
info_file = "/etc/thinux-release-info"
file_var = "/usr/local/sbin/upgrade/var/pw_rs"
file_boot = "/boot/boottime.rc"

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
		print("PASS")
		pass
except:
	pass

dict1 = {}
with open(info_file) as fh:
		for line in fh:
			try:
				params, descr = line.strip().split("=", 1)
				dict1[params] = descr.strip()
			except ValueError:
				pass

#resp = requests.put(feed_url, dict1)
resp = requests.get(feed_url)

# Check content of requests get
conten = resp.json()
print(conten["os_version"])


# extact yy mm dd from os version
s_osv = conten["os_version"] # Os version from server
s_osv_y, s_osv_m, s_osv_d = s_osv[:4], s_osv[4:6], s_osv[6:]

s = date(int(s_osv_y), int(s_osv_m), int(s_osv_d))

c_osv = dict1["os_version"] # OS version of client
c_osv_y, c_osv_m, c_osv_d = c_osv[:4], c_osv[4:6], c_osv[6:]

c = date(int(c_osv_y), int(c_osv_m), int(c_osv_d))

# Compare os version
if s > c:
	run(["mount -o rw,remount /"], shell=True)
	with open(file_var, "w") as pw:
		pw.write("update=1\n")
		pw.write("rsync_url=" + conten["rsync_url"])
	run(["/usr/local/sbin/upgrade/update-user.sh", ">", "/var/log/update-check.log"], shell=True)
