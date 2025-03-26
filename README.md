# frontend-gateway
Reverse Proxy + HTTPS cert provider


config done before setup.. conjob to run @ 1am to check certs


### Install:
1) Cannot be installed directly onto root (~). Nginx Dies if so...   
'/opt/frontend-gateway' is default.  

```angular2html
sudo git clone https://github.com/StevenNaliwajka/frontend-gateway /opt/frontend-gateway
```
TAKE NOTE: 
- If installed under ANY different name or path. YOU MUST change the path to match in:
```angular2html
/Codebase/Config/path.txt
```

-----
### Setup:
1) Run setup script
```angular2html
sudo bash setup.sh
```

2) Start website or re-starts website.
```angular2html
sudo bash start-nginx.sh
```
----

### Other CMDs:
- Status: Checks the nginx instance to see if its running.
```angular2html
sudo bash status-nginx.sh
```
- Stop: Stops the nginx instance
```angular2html
sudo bash stop-nginx.sh
```