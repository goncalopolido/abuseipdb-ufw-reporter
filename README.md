# abuseipdb-ufw-reporter

A UFW monitoring and AbuseIPDB reporting script.

<a href="https://www.abuseipdb.com/user/147005">
  <img
    src="https://www.abuseipdb.com/contributor/147005.svg"
    width="400"
    alt="AbuseIPDB Contributor Badge"
    title="My AbuseIPDB contribution badge - click to view my profile"
  >
</a>

## Features

- Real-time UFW firewall log monitoring using journalctl
- Automatic reporting of newly detected source IPs to AbuseIPDB
- Local tracking system to prevent duplicate reports
- Lightweight Bash implementation with no external dependencies
- Optional systemd service for background execution
  
## Quick Start

```bash
# Clone repository
git clone https://github.com/goncalopolido/abuseipdb-ufw-reporter

# Enter directory
cd abuseipdb-ufw-reporter

# Create environment file
cp example.env .env

# Edit and add your AbuseIPDB API key
nano .env

# Make script executable
chmod +x abuseipdb.sh

# Run manually
./abuseipdb.sh
```

## Systemd Service (Run in Background)

If you want the script to run automatically in the background, create `/etc/systemd/system/abuseipdb.service` with the following content. Replace `/path/to/abuseipdb-ufw-reporter` with the correct path on your system.

```ini
[Unit]
Description=Report Unauthorized Connection Attempts To AbuseIPDB

[Service]
Type=simple
ExecStart=/bin/bash /path/to/abuseipdb-ufw-reporter/abuseipdb.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

Then enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable abuseipdb
sudo systemctl start abuseipdb
sudo systemctl status abuseipdb
```

## Configuration

Create a `.env` file in the root directory of the project:

```bash
ABUSEIPDB_API_KEY=your_api_key_here
```

## Reports Log

All reported IPs are stored in `reports.log` to prevent duplicate submissions.  
The file is automatically reset once it exceeds 500 entries.

## How it works

- Listens to system logs in real time using `journalctl -f`
- Filters `[UFW BLOCK]` events
- Extracts source IP and destination port
- Checks `reports.log` to avoid duplicate reports
- Sends data to AbuseIPDB API
- Stores processed IPs locally

## Requirements

- Linux system with UFW
- curl
- journalctl

## Acknowledgments

The free AbuseIPDB API plan allows up to 1,000 requests per day and limits repeated reports of the same IP to once every 15 minutes.

## AbuseIPDB Contributor Badge

You can get your AbuseIPDB contributor badge [here](https://www.abuseipdb.com/account/contributor). It displays the total number of distinct IP addresses you have reported and can be shown on your website, project, or any other public page to showcase your contributions.
