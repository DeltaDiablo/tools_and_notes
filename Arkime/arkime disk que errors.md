# Arkime Performance Issues: Memory, Disk Queue, and PCAP Ingestion

This guide addresses three critical Arkime performance problems: **memory exhaustion**, **disk queue errors**, and **PCAP ingestion failures** due to insufficient packet thread allocation.

## Memory and Disk Queue Issues

### Root Causes
- **Disk I/O bottlenecks**: PCAP writes can't keep up with packet rate
- **Elasticsearch overload**: Bulk writes backing up in memory  
- **Queue overflow**: Default `maxPacketsInQueue` (200K) insufficient for high traffic

### Solutions
1. **Monitor performance**: Check `/stats?statsTab=1` for Disk Q and ES Q values >50
2. **Optimize storage**: 
    - Use SSDs with <80% utilization (60% for RAID)
    - Maintain free space ≥ `maxFileSizeG * 10`
3. **Tune Elasticsearch**: Increase `dbBulkSize` from default 1M packets
4. **Memory allocation**: 50% RAM to ES heap (max 31GB), 50% to kernel cache

## PCAP Ingestion Failures

### Configuration Fixes
```ini
[default]
packetThreads=4                # Increase from default 1
maxPacketsInQueue=500000      # Handle traffic bursts
offlineDispatchAfter=10000    # For offline processing
pcapReadMethod=afpacket       # Live capture optimization
```

### Command Line Override
```bash
./capture -c config.ini -o packetThreads=4 -o maxPacketsInQueue=500000
```

## Performance Optimization

| Problem | Solution |
|---------|----------|
| High memory/disk queues | Tune `dbBulkSize`, upgrade storage, monitor disk usage |
| Dropped packets | Increase `packetThreads` and `maxPacketsInQueue` |
| Slow offline processing | Adjust `offlineDispatchAfter`, use `libpcap-file` method |
| General instability | Enable debugging, separate capture/viewer nodes |

### Production Configuration
```ini
[default]
packetThreads=4
maxPacketsInQueue=500000
dbBulkSize=2000000
simpleShortHeader=true
debug=2
```

## Best Practices
- Separate capture and viewer nodes to reduce CPU contention
- Enable `simpleShortHeader=true` to save disk space
- Continuously monitor stats dashboard for queue buildup
- Scale horizontally by adding capture nodes for persistent issues

Sources: [Arkime FAQ](https://arkime.com/faq), [GitHub Issues](https://github.com/arkime/arkime), [Configuration Guide](https://deepwiki.com/arkime/arkime/8.3-configuration-options)
