# Lighthouse Validator Metrics
Adds some metrics to the standard Sigma Prime Lighthouse Eth2 dashboard. Metrics relating to balance and status of validators running on the Lighthouse node are collected.

## Installation

- Install Prometheus Push Gateway. Choose a release for your environment here: https://github.com/prometheus/pushgateway/releases
- Set up the Push Gateway so that it runs permanently. You'll find a systemd service definition that you can copy to /etc/systemd/system, then start it up as a systemd service.
- Add the Push Gateway as a Prometheus scrape target. Edit /etc/prometheus/prometheus.yml. Add these lines at the end of the 'scrape-configs' section:
```
- job_name: 'push-gateway'
    static_configs:
      - targets: ['localhost:9091']
    scrape_interval: 5m
    honor_labels: true
```
- Add a cron job to run the script, collect metrics from the lighthouse beacon node, and push them.
```
crontab -e
<choose editor>
*/5 * * * * bash /home/ethereum/lh-validator-metrics/push_metrics.sh >>/dev/null 2>&1 | logger -t pushmetrics
<save>
```
- Import Grafana panels. The panel definitions in the `grafana` folder can be imported. 

You may need to edit some of these scripts to suit your environment. The set of validators to be tracked is based on the validator keys as found in the standard lighthouse installation, i.e. `$HOME/.lighthouse/validators`. Edit the `push_metrics.sh` script if your configuration differs.

Copyright (C) 2020 Stonebell Consulting Pty Ltd
