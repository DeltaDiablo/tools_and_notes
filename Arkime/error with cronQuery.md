# Arkime cronQueries Troubleshooting Guide

When enabling periodic queries in Arkime (`cronQueries=true`) and encountering issues, this guide provides systematic troubleshooting steps to resolve common problems.

## Prerequisites

- Arkime viewer installed and running
- Access to configuration files (typically `config.ini`)
- Administrative privileges to restart services

## Common Issues and Solutions

### 1. Configuration Placement

**Problem**: cronQueries setting not taking effect

**Solution**: Ensure correct configuration placement

The `cronQueries` setting must be placed in the `[default]` section of your Arkime viewer configuration, not in node-specific sections.

**Correct configuration in `config.ini`:**
```ini
[default]
cronQueries=true
```

**After configuration changes:**
```bash
# For systemd installations
systemctl restart arkimeviewer.service

# For Docker deployments
docker restart <arkime-viewer-container>
```

⚠️ **Important**: In multi-node setups, enable `cronQueries=true` on only ONE viewer node to avoid conflicts.

### 2. Query Timeframe Validation

**Problem**: Periodic queries appear not to run or return zero results

**Solution**: Validate query time ranges

- Ensure the time range includes past matching sessions OR future sessions you expect to match
- Queries that fall completely outside of existing/incoming data will return zero matches
- Test with a broader time range first to verify functionality

### 3. Debugging and Diagnostics

**Problem**: Uncertain if cronQueries is working correctly

**Solution**: Enable detailed logging

**Option 1 - Configuration file:**
```ini
[default]
cronQueries=true
debug=1
```

**Option 2 - Command line:**
```bash
node viewer.js -c /opt/arkime/etc/config.ini --debug
```

**Log monitoring:**
```bash
tail -f /opt/arkime/logs/viewer.log
```

Look for log messages confirming:
- `cronQueries=true` is applied
- Periodic queries are executing
- Any error messages during execution

### 4. Version Compatibility

**Problem**: Persistent issues despite correct configuration

**Solution**: Verify Arkime version compatibility

Some periodic query issues were resolved in later versions. Ensure you're running:
- Arkime version with cronQueries fixes
- Latest stable release or up-to-date source builds

**Reference GitHub issues:**
- [#2011](https://github.com/arkime/arkime/issues/2011)
- [#1692](https://github.com/arkime/arkime/issues/1692)

## Best Practices

### Configuration Management
- ✅ Place `cronQueries=true` in `[default]` section only
- ✅ Enable on single viewer node in multi-node deployments
- ❌ Avoid placing in `[nodeName]` or `[nodeClass]` sections unless specifically needed

### Troubleshooting Workflow
1. **Configure**: Place `cronQueries=true` under `[default]`
2. **Restrict**: Ensure only one viewer node has it enabled
3. **Restart**: Restart viewer service (`systemctl restart` or `docker restart`)
4. **Debug**: Enable `debug=1` to monitor execution
5. **Validate**: Verify query timeframes include relevant data
6. **Update**: Upgrade Arkime if using older builds

### Monitoring
- Regularly check `/opt/arkime/logs/viewer.log` for execution status
- Monitor system resources during periodic query execution
- Set appropriate query intervals to avoid system overload

## Additional Notes

- **Service restart required**: Configuration changes only take effect after viewer restart
- **Single node restriction**: Multiple nodes with cronQueries enabled can cause lock conflicts
- **Query timing**: Consider system load when scheduling frequent periodic queries