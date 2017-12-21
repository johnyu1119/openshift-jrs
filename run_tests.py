import sys
import requests

URL="http://127.0.0.1:8080/jasperserver/login.html"

print("HTTP GET %s" % URL)
r = requests.get(URL)
if r.status_code != 200:
    print("[FAIL] Wrong status code: %s" % r.status_code)
    sys.exit(1)

