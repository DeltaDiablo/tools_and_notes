# How to Tune Arkime: Common Issues and Solutions

Arkime is a powerful network traffic analysis tool that works with Elasticsearch. While highly capable, it requires proper tuning to avoid performance issues. Below are common problems and their solutions for Arkime sensor deployments.

## High CPU Usage

When Arkime consumes excessive CPU resources:

- **Optimize capture threads**: Set `packetThreads` to CPU core count minus 1
- **Reduce parsing overhead**: Disable unused parsers in `parsers.txt`
- **Increase capture buffer**: Set `pcapReadSize=131072` to reduce system calls
- **Enable hardware acceleration**: Use `af-packet` with `afpacketv3=true`
- **Limit concurrent processing**: Set `maxPackets=10000` to prevent CPU spikes

## Packet Drops

When experiencing packet loss during capture:

- **Increase buffer sizes**: Set `pcapReadSize=262144` and `maxPacketsInQueue=500000`
- **Use multiple interfaces**: Configure `interface=eth0;eth1` for load distribution
- **Enable ring buffers**: Add `ringSize=16777216` for better buffering
- **Optimize network hardware**: Use `ethtool -G eth0 rx 4096 tx 4096`
- **Set CPU affinity**: Pin processes to specific cores with `taskset`

## Elasticsearch Connection Problems

When Arkime cannot connect to or write to Elasticsearch:

- **Verify connectivity**: Test with `curl -X GET "elasticsearch-host:9200"`
- **Increase timeouts**: Set `esTimeout=300` and `esMaxConns=20`
- **Configure bulk operations**: Adjust `esBulkSize=1000` and `esBulkTimeout=10`
- **Update index templates**: Run `./db.pl upgrade` for proper mapping
- **Monitor ES resources**: Ensure sufficient heap memory and disk space

## Slow Web Interface

When the Arkime viewer responds slowly:

- **Optimize queries**: Increase `esMaxConcurrentShardRequests=10`
- **Limit search scope**: Use time ranges and specific filters
- **Enable caching**: Set `viewerTimeout=120` and increase connection pools
- **Control result size**: Limit `maxSearchHits=10000`
- **Upgrade hardware**: Ensure adequate RAM and fast storage for viewer nodes