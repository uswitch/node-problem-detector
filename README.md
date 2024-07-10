# Node Problem Detector custom scripts

Adding our own scripts to https://github.com/kubernetes/node-problem-detector and sharing them in case you might find those handy for you use cases. 


The scripts details can be found in `/config/plugin/` but ultimately, they are:
* `launch-config-drift`: a way to check if your instances launch template has diverged from your asg launch template
* `spot-termination`: uses the `meta-data/spot/instance-action endpoint` to check EC2 Spot Instance interruption notice 
* `local-dns-resolver`: checks the response status value received (if any) from the local dns resolver ip
* `upstream-dns-resolver`: check if we receive an IPv4 address for a given A record.
* `uptime`: every 5 seconds, checks if the information detailing how long the system has been on since its last restart is acceptable (to us the threshold being 604800 seconds) 


## Notes
*July 2024 -* The custom `node problem detector` image is now stored in the `uswitch/node_problem_detectr` repository on Quay.
<br>