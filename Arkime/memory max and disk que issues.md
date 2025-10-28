# Arkime Memory, Disk Queue, and PCAP Issues Resolution Guide

Arkime's full packet capture system may encounter performance bottlenecks when memory limits, disk queues, or PCAP file handling are improperly configured. This guide provides systematic troubleshooting and optimization strategies.

## Common Error Categories

### Memory Saturation
- **Root Cause**: Insufficient `maxPacketsInQueue`, inadequate `packetThreads`, or oversized bulk operations
- **Symptoms**: Capture stops, queue overflows, performance degradation
- **Impact**: Processing throughput drops as memory buffers fill

### Disk Queue Bottlenecks
- **Root Cause**: Disk I/O cannot keep pace with packet ingestion rate
- **Symptoms**: `Disk Q > 50` in stats, write delays
- **Impact**: Packet loss when queues exceed capacity

### PCAP Management Failures
- **Root Cause**: File rotation limits, insufficient free space, or cleanup policy misconfigurations
- **Symptoms**: 
    ```
    EXPIRE WARNING - not deleting any files
    Disk Q exceeding thresholds
    ```
- **Impact**: Capture halts when storage constraints are hit

## Critical Configuration Parameters

| Parameter | Default | Optimization Guidelines |
|-----------|---------|------------------------|
| `maxPacketsInQueue` | 200,000 | Scale with available RAM; higher values = more memory usage |
| `packetThreads` | 1 | Match CPU cores for parallel processing |
| `dbBulkSize` | 1,000,000 | Balance memory usage vs Elasticsearch write efficiency |
| `maxStreams` | 1000 | Adjust based on concurrent connection volume |
| `maxFileSizeG` | 12 | Increase for high-volume captures to reduce rotation overhead |
| `minFreeSpaceG` | 5 | Set according to storage capacity and retention requirements |
| `pcapDir` | /opt/arkime/raw | Ensure high-throughput storage with adequate space |
| `simpleCompression` | zstd | Trade CPU cycles for reduced storage footprint |
| `maxWriteBuffers` | 0 | Increase when disk I/O becomes the bottleneck |

### Dynamic Configuration
- **Environment Variables**: `ARKIME__maxPacketsInQueue`, `ARKIME__packetThreads`
- **CLI Overrides**: `-o maxPacketsInQueue=400000 -o packetThreads=4`

## Troubleshooting Workflow

### 1. Storage Assessment
```bash
# Check available space and I/O performance
df -h /opt/arkime/raw
iostat -dx 5
```

**Remediation Options**:
- Deploy faster storage (NVMe SSD, RAID 10)
- Dedicated PCAP storage volumes
- Network-attached high-performance storage

### 2. Memory and Threading Optimization
- **Scale `maxPacketsInQueue`** to prevent buffer overflow
- **Increase `packetThreads`** for CPU parallelization
- **Monitor memory consumption** to avoid system instability

### 3. Diagnostic Logging
Enable detailed logging for issue identification:
```bash
# In config.ini
debug=2

# Or via command line
moloch-capture -d
```

**Key Log Indicators**:
- `Disk Q > 50`: I/O bottleneck
- `EXPIRE WARNING`: Cleanup policy issues
- Queue overflow messages

### 4. PCAP Lifecycle Management
- **Adjust `minFreeSpaceG`** to trigger timely cleanup
- **Configure `ARKIME_FREESPACEG`** environment variable
- **Enable `MANAGE_PCAP_FILES`** for automated maintenance

### 5. Performance Monitoring
```bash
# Monitor queue depths and processing rates
curl http://localhost:8005/stats?statsTab=1
```

**Target Metrics**:
- `Disk Q` < 50
- `ES Q` < 50
- Consistent packet processing rates

### 6. Offline Processing Optimization
For large PCAP ingestion:
- **Increase `offlineDispatchAfter`** (e.g., 10,000)
- **Utilize multiple `packetThreads`**
- **Batch processing** for efficiency

## Advanced Performance Tuning

### Memory Efficiency
- **Enable `simpleShortHeader=true`** to reduce per-packet overhead
- **Tune `simpleCompression=zstd`** with `simpleZstdLevel=3-5`

### Distributed Capture
- **Implement `parliament`** for multi-node coordination
- **Use shared storage** for centralized PCAP management
- **Load balance** across capture nodes

## Resolution Summary

**Primary Actions**:
1. **Scale packet buffers**: Increase `maxPacketsInQueue` and `packetThreads`
2. **Validate storage performance**: Ensure disk throughput meets capture requirements
3. **Configure PCAP management**: Set appropriate rotation and cleanup thresholds
4. **Enable monitoring**: Use `debug=2` and track queue metrics
5. **Implement dynamic tuning**: Use environment variables for runtime adjustments

**Success Criteria**:
- Stable queue depths (< 50)
- Consistent packet capture rates
- Automated PCAP lifecycle management
- No capture interruptions due to resource constraints

## Reference Documentation
- [Arkime Configuration Reference](https://deepwiki.com/arkime/arkime/8.3-configuration-options)
- [PCAP Storage Troubleshooting](https://github.com/cisagov/Malcolm/issues/686)
- [Performance Optimization Guide](https://github.com/arkime/arkime/issues/2028)

This systematic approach ensures continuous, high-performance packet capture without resource-related interruptions.

**Sources**:
[^1^]: https://github.com/arkime/arkime/issues/2028
[^2^]: https://arkime.com/settings
[^3^]: https://deepwiki.com/arkime/arkime/2.2-storage-architecture
[^4^]: https://github.com/cisagov/Malcolm/issues/686