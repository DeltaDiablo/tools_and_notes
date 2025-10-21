## What operating systems are supported? 

Arkime provides pre-packaged support for a wide range of operating systems, which you can find on the downloads page. The Arkime development team primarily works with the EL 8 build, choosing between pcap and afpacket readers based on deployment requirements. We recommend using the afpacket reader when possible for optimal capture performance. 

While significant development occurs on macOS using Homebrew, this environment hasn't been validated for production use. Note that Arkime no longer supports 32-bit machines, making it incompatible with many lower-powered devices. Our support is currently limited to LTS versions of Ubuntu due to potential library compatibility issues with non-LTS releases.

**Supported operating system distributions and versions:**

- Amazon Linux 2 and EL 7 (support ending in Arkime 6)
- Amazon Linux 2023
- Arch
- Debian 12
- EL 8 and 9
- Ubuntu 20.04, 22.04, 24.04

## Arkime is not working 

Here's the common troubleshooting checklist (replace /opt/arkime with /data/moloch for Moloch builds):

1. **Check OpenSearch/Elasticsearch status:** Run `curl http://localhost:9200/_cat/health` on the OpenSearch/Elasticsearch machine. An Unauthorized response likely means you need user:pass in URLs or are using the wrong URL.

2. **Verify database initialization:** Run `/opt/arkime/db/db.pl http://elasticsearch.hostname:9200 info` to see database version and session count information.

3. **Check viewer accessibility:** Visit `http://arkime-viewer.hostname:8005` in your browser.
    - If it doesn't render or looks strange, use a newer supported browser
    - If the browser can't connect and viewer.js is running, check for firewalls
    - Ensure `viewHost=localhost` is NOT set in config.ini
    - Test that `curl http://IP:8005` works from the viewer host

4. **Check logs:**
    - Review `/opt/arkime/logs/viewer.log` for errors and verify viewer is running with `pgrep -lf viewer`
    - Review `/opt/arkime/logs/capture.log` for errors and verify capture is running with `pgrep -lf capture`

5. **Check stats page:** Visit `http://arkime-viewer.hostname:8005/stats?statsTab=1`
    - If packet count is low for any node, check its capture.log
    - If timestamp is over 5 seconds old for any node, check its capture.log
    - If Disk Q or ES Q is above 50 for any node, check its capture.log

6. **Disable BPF filters:** Temporarily disable any `bpf=` settings in `/opt/arkime/etc/config.ini`

7. **If browser shows "Oh no, Arkime is empty!"** but stats show packets are being captured:
    - Arkime only writes records when sessions end; wait several minutes after fresh start
    - OpenSearch/Elasticsearch refreshes indices once per minute by default; force refresh with `curl http://elasticsearch.hostname:9200/_refresh`
    - Verify your search time frame covers the data (try switching to ALL)
    - Check that no view is set
    - Verify your user doesn't have a forced expression

8. **Enable debugging:** Add `--debug` to start commands or `debug=1` in the `[default]` section of config.ini for more detailed information.

9. **Check plugin configuration:** Ensure plugins and parsers directories are correctly set and readable in `/opt/arkime/etc/config.ini`.

10. **Verify packet processing:** Run `grep arkime_packet_log /opt/arkime/logs/capture.log | tail` and verify the packets number and first pstats number are greater than 0.

## How do I reset Arkime? 

1. Leave OpenSearch/Elasticsearch running
2. Shut down all viewer and capture processes
3. Delete SPI data: `/opt/arkime/db/db.pl http://ESHOST:9200 wipe` (wipe preserves users; init removes everything)
4. Delete PCAP files on all capture machines: `/bin/rm -f /opt/arkime/raw/*`

## Self-Signed or Private CA TLS Certificates 

The Arkime team recommends against self-signed certificates and suggests investing in legitimate certificates or using free certificates from Let's Encrypt. However, if you must use self-signed certificates:

**Preferred method:** Add certificates to your OS's trusted certificate list. The process varies by distribution, so search for specific instructions. You may need to register certificates in multiple trust stores for node, curl, and perl.

**Alternative method (less secure):** Disable certificate verification by adding the `--insecure` flag:

```bash
cp /opt/arkime/etc/env.example /opt/arkime/etc/capture.env
echo 'OPTIONS="--insecure"' >> /opt/arkime/etc/capture.env
cp /opt/arkime/etc/env.example /opt/arkime/etc/viewer.env
echo 'OPTIONS="--insecure"' >> /opt/arkime/etc/viewer.env
cp /opt/arkime/etc/env.example /opt/arkime/etc/cont3xt.env
echo 'OPTIONS="--insecure"' >> /opt/arkime/etc/cont3xt.env
```

For Node.js applications (viewer, wise, cont3xt), set the `NODE_EXTRA_CA_CERTS` environment variable to your CA certificate file path.

## Upgrade Instructions

### How do I upgrade to Moloch 1.x?

Moloch 1.x requires reindexing all session data, done in the background after upgrading. Key changes include field name changes, country code format changes, and full IPv6 support.

**Prerequisites:** Elasticsearch 5.5.x (5.6 recommended) and Moloch 0.20.2 or 0.50.x

**Steps:**
1. Download 1.1.1 from downloads page
2. Shut down all capture, viewer, and WISE processes
3. Install Moloch 1.1.1
4. Run `/data/moloch/bin/moloch_update_geo.sh` on capture nodes
5. Run `db.pl http://ESHOST:9200 upgrade` once
6. Start WISE, then capture, then viewers
7. Verify new data collection
8. Reindex old data using `reindex2.js` with appropriate slices
9. Delete old indices and run expire/optimize jobs

### How do I upgrade to Moloch 2.x?

Requires outage. Must use Moloch 1.7/1.8 and Elasticsearch 6.7/6.8 first.

**Steps:**
1. Install Moloch ≥ 2.0 without restarting services
2. Optional: Backup with `./db.pl http://ESHOST:9200 backup pre20`
3. Shut down captures
4. Run `./db.pl http://ESHOST:9200 upgrade`
5. Restart all services

### How do I upgrade to Arkime 3.x?

Requires outage and Elasticsearch 7.10+. Must use Moloch 2.4+ first.

**Breaking changes:** Indices now start with `arkime_`, new multiES requirements, WISE modifications required.

**Steps:**
1. Optional: Backup with `./db.pl http://ESHOST:9200 backup pre30`
2. Install Arkime ≥ 3.0 without restarting
3. Shut down all services
4. Run `./db.pl http://ESHOST:9200 upgrade [options]`
5. Update paths from `/data/moloch` to `/opt/arkime` if needed
6. Re-run ILM commands if using
7. Restart all services

### How do I upgrade to Arkime 4.x?

Requires Arkime 3.3.0+. Introduces new permissions model with roles.

**Breaking changes:** Auto-installed systemd files, new role-based permissions, encrypted PCAP uses `.arkime` extension.

**Steps:**
1. Install new rpm/deb
2. Shut down all services
3. Run `./db.pl http://ESHOST:9200 upgrade [options]`
4. Update paths if needed
5. Restart all services

### How do I upgrade to Arkime 5.x?

Requires Arkime 4.3.2+.

**Breaking changes:** Compression defaults to zstd, packet deduplication enabled by default, auth mode defaults to digest.

**Steps:**
1. Install new rpm/deb
2. Optionally shut down services (recommended)
3. Run `/opt/arkime/db/db.pl http://ESHOST:9200 upgrade [options]`
4. Restart all services

### How do I upgrade to Arkime 6.x?

**Note:** Arkime 6 is in development and not production-ready.

Requires Arkime 5.2.0+. Breaking changes TBD.

## OpenSearch/Elasticsearch

Arkime supports both OpenSearch and Elasticsearch. OpenSearch is compatible with Arkime versions supporting Elasticsearch 7+.

### How many nodes do I need?

Depends on factors like memory, retention period, disk speed, traffic type, session duration, and query requirements.

**Key considerations:**
- Have at least 1% of disk space used by OpenSearch/Elasticsearch available as heap memory
- Assign half system memory to OpenSearch/Elasticsearch (max 30GB per node), half to disk cache
- Use Elasticsearch 7+ or OpenSearch 2.3+
- Quick estimate: 5% of PCAP storage for SPI data

### Data deletion

**Important:** Never put pcapDir and OpenSearch/Elasticsearch data on the same filesystem.

PCAP and SPI data are deleted independently:
- PCAP: Deleted automatically as disk fills up
- SPI: Must setup ILM/ISM or cron job (e.g., `0 0 * * * /opt/arkime/db/db.pl http://localhost:9200 expire daily 90`)

### Common errors and solutions

**"ERROR - Dropping request":** OpenSearch/Elasticsearch can't keep up
- Don't run on same machine as capture
- Ensure 30GB memory + 30GB disk cache per node
- Increase dbBulkSize to 4MB
- Decrease packetThreads
- Check for sick nodes
- Disable swap
- Use latest supported versions

**When to add nodes:** If queries are slow or Java OutOfMemory occurs

**Version upgrades:** Generally follow rolling upgrade procedures, but major versions may require Arkime upgrades

## Capture

### Hardware recommendations

**Capture machine specs:**
- **Case:** 4RU boxes (2RU if space limited)
- **Memory:** 64-96GB
- **OS Disks:** RAID 1 small drives
- **Capture Disks:** 16+ × 16TB SATA drives
- **RAID:** Hardware card with 1-2GB cache, RAID 5 with hot spare or RAID 6
- **NIC:** Modern Mellanox/Intel 10G NICs (25G for 100G NPB connections)
- **CPU:** At least 2 × 6 cores

**Storage requirements:** ~11TB per day for 1Gbps uncompressed traffic

### Performance and troubleshooting

**Typical performance:** 5+ Gbps on modern hardware, limited by disk write speed

**Test disk performance:**
```bash
dd bs=256k count=50000 if=/dev/zero of=/THE_ARKIME_PCAP_DIR/test oflag=direct
```

**Common packet drop causes:**
- Use tpacketv3 reader instead of libpcap
- Configure network card properly (increase ring buffer, disable features)
- Set proper MTU (1600+ or 9216 for jumbo frames)
- Tune packetThreads (start low, increase gradually)
- Ensure adequate disk performance

### Importing existing PCAPs

```bash
/opt/arkime/bin/capture -c [config_file] -r [PCAP file]
# For directories:
/opt/arkime/bin/capture -c [config_file] -R [PCAP directory]
```

Common options: `--monitor`, `--skip`, `--copy`

## Viewer

### Supported browsers

**Minimum versions:**
- **Arkime 5.x+:** Chrome 92, Firefox 95, Safari 15.4, Edge 92
- **Arkime 3.x-4.x:** Chrome 80, Firefox 74, Safari 13.1, Edge 80

### Common issues

**"Couldn't connect to remote viewer":** Usually hostname/FQDN resolution issues
- Use same config.ini on all nodes
- Ensure FQDNs or proper DNS resolution
- Check certificate matching
- Use `--host` option if needed

**Changing viewer port:**
- Ports >1024: Set `viewPort` in `[default]` section
- Ports <1024: Use reverse proxy, iptables forwarding, or run as root

**Missing fields:** Run capture to re-add fields, restart viewer or wait 10 minutes

### Apache proxy setup

For authentication through Apache:
1. Configure Apache with auth method
2. Set `RequestHeader set ARKIME_USER %{username_variable}e`
3. Configure SSL proxy to Arkime
4. Set `userNameHeader` and `webBasePath` in Arkime config
5. Enable "Web Auth Header" for users

## WISE

### Troubleshooting

1. Check WISE is running: `curl http://localhost:8081/fields`
2. Verify config.ini includes:
    - `wise.so` in `plugins=`
    - `wise.js` in `viewerPlugins=`
    - Proper `wiseURL` setting
3. Test connectivity from capture/viewer hosts
4. Enable debugging for detailed information

## Cont3xt

### Troubleshooting

1. Check integrations: `curl http://localhost:3218/settings#integrations`
2. Review `/opt/arkime/logs/cont3xt.log`
3. Add `debug=2` in `[cont3xt]` section for detailed logging

## Parliament

Designed to run behind reverse proxy. Sample Apache config:
```apache
ProxyPassMatch   ^/$ http://localhost:8008/parliament retry=0
ProxyPass        /parliament/ http://localhost:8008/parliament/ retry=0
```
