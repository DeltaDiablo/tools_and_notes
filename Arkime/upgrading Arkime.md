# Arkime Upgrade Guide

A comprehensive guide for safely upgrading Arkime while ensuring database compatibility, capture continuity, and viewer functionality preservation.

## Overview

Upgrading Arkime requires a careful, sequential process that maintains data integrity and minimizes downtime. This guide covers the complete upgrade procedure from pre-upgrade checks to post-upgrade validation.

## Pre-Upgrade Requirements

### Prerequisites
- Administrative access to Arkime servers
- Access to Elasticsearch/OpenSearch cluster
- Backup of current configuration files
- Maintenance window for service interruption

### Important Considerations
⚠️ **Critical**: Major version upgrades must be performed sequentially (e.g., 4.x → 5.x → 6.x)
⚠️ **Backup**: Always backup your configuration and consider snapshotting your Elasticsearch indices

## Step-by-Step Upgrade Process

### 1. Pre-Upgrade Assessment

**Check Current Version:**
```bash
/opt/arkime/db/db.pl http://localhost:9200 info
```

**Document current configuration:**
```bash
# Backup configuration files
sudo cp /opt/arkime/etc/config.ini /opt/arkime/etc/config.ini.backup
sudo cp -r /opt/arkime/etc/ /opt/arkime/etc.backup.$(date +%Y%m%d)
```

### 2. Compatibility Verification

Before proceeding, verify:

- **Target Arkime version compatibility** with your Elasticsearch/OpenSearch version
- **Operating system requirements** for the target release
- **Hardware requirements** and resource availability
- **Sequential upgrade path** if jumping multiple major versions

**Version Compatibility Matrix:**
| Arkime Version | Elasticsearch | OpenSearch | 
|----------------|---------------|------------|
| 5.x | 7.10+ | 2.x+ |
| 4.x | 7.x | 1.x+ |

### 3. Download Target Version

**Get the appropriate package for your OS:**

**Ubuntu/Debian:**
```bash
# Example for Ubuntu 20.04 LTS
wget https://sourceforge.net/projects/arkime.mirror/files/v5.7.0/arkime_5.7.0-1.ubuntu2004_amd64.deb
```

**RHEL/CentOS/Rocky Linux:**
```bash
# Example for EL8
wget https://sourceforge.net/projects/arkime.mirror/files/v5.7.0/arkime-5.7.0-1.el8.x86_64.rpm
```

### 4. Service Shutdown

**Stop all Arkime services to prevent data corruption:**
```bash
# Stop services in CORRECT ORDER
sudo systemctl stop arkime-viewer
sudo systemctl stop arkime-capture

# Verify services are stopped
sudo systemctl status arkime-viewer arkime-capture
```

### 5. Package Installation

**Install the new version:**

**Ubuntu/Debian:**
```bash
sudo dpkg -i arkime_5.7.0-1.ubuntu2004_amd64.deb

# Fix any dependency issues if they arise
sudo apt-get install -f
```

**RHEL/CentOS/Rocky:**
```bash
sudo rpm -Uvh arkime-5.7.0-1.el8.x86_64.rpm
```

### 6. Database Schema Update

**Critical step for major version upgrades:**

```bash
# Run database upgrade script
/opt/arkime/db/db.pl http://localhost:9200 upgrade

# Verify database version after upgrade
/opt/arkime/db/db.pl http://localhost:9200 info
```

**Monitor for upgrade completion:**
```bash
# Check for any errors during upgrade
tail -f /opt/arkime/logs/viewer.log
```

### 7. Configuration Review and Update

**Verify configuration compatibility:**

```bash
# Check main configuration file
sudo nano /opt/arkime/etc/config.ini
```

**Key areas to review:**
- **Elasticsearch/OpenSearch URLs** and authentication
- **Network interface** selection and capture settings
- **Plugin and parser** directory paths and permissions
- **Authentication methods** and user management
- **New configuration options** introduced in the target version

**Update environment files if needed:**
```bash
# Check and update if necessary
/opt/arkime/etc/capture.env
/opt/arkime/etc/viewer.env
```

### 8. Service Restart and Verification

**Start services in correct order:**
```bash
# Start capture first, then viewer
sudo systemctl start arkime-capture
sudo systemctl start arkime-viewer

# Enable auto-start on boot
sudo systemctl enable arkime-capture arkime-viewer
```

**Verify service status:**
```bash
# Check service status
sudo systemctl status arkime-capture arkime-viewer

# Monitor logs for startup issues
tail -f /opt/arkime/logs/capture.log
tail -f /opt/arkime/logs/viewer.log
```

**Test viewer accessibility:**
```bash
# Default viewer port is 8005
curl -I http://localhost:8005
```

**Browser verification:**
Navigate to `http://<arkime-viewer-host>:8005` and verify:
- Login functionality
- Session data visibility
- Search capabilities
- Dashboard functionality

### 9. Post-Upgrade Validation

**Verify data ingestion:**
```bash
# Check if new sessions are being captured and indexed
curl -s "http://localhost:9200/arkime_sessions3-*/_search?size=1&sort=@timestamp:desc" | jq .
```

**Validate capture functionality:**
```bash
# Monitor capture statistics
tail -f /opt/arkime/logs/capture.log | grep "packets"
```

**Check scheduled jobs:**
```bash
# Verify maintenance tasks are working
crontab -l | grep arkime
```

## Advanced Considerations

### Major Version Upgrades

**Version 4.x to 5.x specific requirements:**
- Configure Parliament authentication before upgrading
- Update user authentication mechanisms
- Review new security features and defaults

**Multi-version jumps:**
- Must upgrade sequentially through major versions
- Each major version requires database upgrade
- Test functionality at each major version step

### Performance Optimization

**Post-upgrade tuning:**
```bash
# Reindex old data for performance (optional)
/opt/arkime/db/db.pl http://localhost:9200 reindex

# Update index templates for new features
/opt/arkime/db/db.pl http://localhost:9200 template-update
```

## Troubleshooting

### Common Issues and Solutions

**"Arkime is empty" after upgrade:**
```bash
# Force Elasticsearch index refresh
curl -X POST "http://localhost:9200/_refresh"

# Check index health
curl "http://localhost:9200/_cat/indices/arkime*?v"
```

**Configuration issues:**
```bash
# Test configuration without starting services
/opt/arkime/bin/capture --test -c /opt/arkime/etc/config.ini

# Enable debug mode for troubleshooting
echo "debug=1" >> /opt/arkime/etc/config.ini
```

**Service startup failures:**
```bash
# Check for detailed error messages
journalctl -u arkime-capture -f
journalctl -u arkime-viewer -f
```

### Emergency Rollback

If critical issues arise:
```bash
# Stop services
sudo systemctl stop arkime-viewer arkime-capture

# Reinstall previous version package
sudo dpkg -i arkime_<previous-version>.deb  # Ubuntu
sudo rpm -Uvh arkime-<previous-version>.rpm  # RHEL

# Restore configuration backup
sudo cp /opt/arkime/etc/config.ini.backup /opt/arkime/etc/config.ini

# Restart services
sudo systemctl start arkime-capture arkime-viewer
```

## Best Practices

### Upgrade Planning
- **Schedule upgrades** during low-traffic periods
- **Test upgrades** in staging environment first  
- **Document custom configurations** before upgrading
- **Monitor resource usage** during and after upgrade

### Maintenance Schedule
- **Minor updates**: Monthly or as security patches are released
- **Major updates**: Quarterly with thorough testing
- **Security updates**: As soon as possible after release

## Quick Reference

### Essential Commands
```bash
# Check version
/opt/arkime/db/db.pl http://localhost:9200 info

# Stop services
sudo systemctl stop arkime-viewer arkime-capture

# Upgrade database
/opt/arkime/db/db.pl http://localhost:9200 upgrade

# Start services  
sudo systemctl start arkime-capture arkime-viewer

# View logs
tail -f /opt/arkime/logs/{capture,viewer}.log
```

### Configuration Files
- **Main config**: `/opt/arkime/etc/config.ini`
- **Environment**: `/opt/arkime/etc/{capture,viewer}.env`
- **Logs**: `/opt/arkime/logs/`

For version-specific upgrade instructions and known issues, always consult:
- [Arkime Official Documentation](https://arkime.com/faq)
- [GitHub Release Notes](https://github.com/arkime/arkime/releases)
- [Community Discord/Forums](https://arkime.com/community)