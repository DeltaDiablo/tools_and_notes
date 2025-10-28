# Arkime Configuration Variables and Meanings

Arkime (formerly Moloch) uses a flexible configuration system to manage its capture, viewer, database, and integration settings. Configuration can be specified via **INI/JSON/YAML files**, **environment variables**, or **command-line overrides**. Below is a comprehensive overview of major configuration variables, their defaults, and definitions.

## General Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `nodeName` | System hostname | Unique identifier for this Arkime node |
| `hostName` | System hostname | Hostname used for external connections |
| `prefix` | `arkime_` | Prefix for all session Elasticsearch/OpenSearch indices |
| `usersPrefix` | Same as `prefix` | Prefix for user-related indices |
| `debug` | `0` | Logging/debug verbosity level (0-5) |
| `quiet` | `false` | Reduces logging output when enabled |
| `fileAgeSeconds` | `0` | Frequency to check for old files (seconds) |
| `pluginsDir` | `/opt/arkime/plugins` | Directory containing capture/viewer plugins |
| `parsersDir` | `/opt/arkime/parsers` | Directory containing protocol parsers |
| `viewerPlugins` | Empty | Comma-separated list of viewer plugins to load |

## Capture Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `interface` | Empty | Network interface(s) for packet capture |
| `bpf` | Empty | Berkeley Packet Filter expression for traffic filtering |
| `pcapReadMethod` | `libpcap` | Packet reading method (libpcap, tpacketv3, afpacket) |
| `pcapWriteMethod` | `simple` | Packet writing method (simple, direct-thread) |
| `maxPacketsInQueue` | `200000` | Maximum packets before processing queue blocks |
| `packetThreads` | `1` | Number of threads for packet stream processing |
| `tcpTimeout` | `600` | TCP session inactivity timeout (seconds) |
| `tcpClosingTimeout` | `5` | Wait time after session close before saving |
| `maxPacketLen` | `65335` | Maximum packet length to capture |
| `maxFileSizeG` | `12` | Maximum PCAP file size (GB) before rotation |
| `dbBulkSize` | `1000000` | Bulk write size for Elasticsearch/OpenSearch |
| `parseHTTPHeaderRequestAll` | `false` | Parse all HTTP request headers |
| `parseHTTPHeaderResponseAll` | `false` | Parse all HTTP response headers |
| `parseQSValue` | `true` | Parse query string values |
| `parseDNSRecordAll` | `false` | Parse complete DNS records |
| `supportSha256` | `false` | Calculate SHA256 checksums for packets |
| `enablePacketDedup` | `true` | Remove duplicate packets |
| `minFreeSpaceG` | `5` | Minimum required free disk space (GB) |

## Storage Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `pcapDir` | `/opt/arkime/raw` | Directory for storing PCAP files |
| `simpleCompression` | `zstd` | PCAP compression method (none, gzip, zstd) |
| `simpleCompressionBlockSize` | `64000` | Compression block size for PCAP files |
| `simpleShortHeader` | `false` | Use shorter PCAP headers |
| `s3Bucket` | Empty | S3 bucket name for offload storage |
| `s3Region` | Empty | AWS region for S3 operations |
| `s3AccessKeyId` | Empty | AWS access key for S3 authentication |
| `s3SecretAccessKey` | Empty | AWS secret key for S3 authentication |
| `s3UseECSEnv` | `false` | Use ECS container credentials |
| `s3Compress` | `false` | Enable S3-side compression |

## Viewer Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `viewPort` | `8005` | Port for viewer HTTP service |
| `viewHost` | Empty | Host interface for viewer binding |
| `webBasePath` | `/` | Base path for viewer behind reverse proxy |
| `httpRealm` | `Arkime` | HTTP digest realm for authentication |
| `readOnly` | `false` | Enable viewer-only mode |
| `cronQueries` | `false` | Enable scheduled queries |
| `defaultTimeRange` | `1` | Default search time range (hours) |
| `shortcuts` | Empty | Pre-defined query shortcuts configuration |
| `footerTemplate` | Empty | Default footer template |
| `headerTemplate` | Empty | Default header template |

## Authentication & Security

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `authMode` | `digest` | Authentication mode (digest, form, basic, OIDC, header) |
| `passwordSecret` | Empty | Secret for password hashing and server encryption |
| `serverSecret` | Empty | Shared key for cluster communication |
| `authCookieSecure` | `true` | Require HTTPS for authentication cookies |
| `authCookieSameSite` | `Lax` | SameSite property for authentication cookies |
| `authTrustProxy` | Empty | Trust reverse proxy headers for HTTP mode |
| `userAuthIps` | `localhost` | Allowed IPs for authentication headers |
| `requiredAuthHeader` | Empty | Header name for external authentication |
| `requiredAuthHeaderVal` | Empty | Expected values for authentication header |
| `userAutoCreate` | `false` | Automatically create users from headers |
| `userAutoCreateTmpl` | Empty | JSON template for auto-created users |
| `userNameHeader` | Empty | Header for username extraction in header auth |

## Elasticsearch/OpenSearch Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `elasticsearch` | `localhost:9200` | Comma-separated list of ES/OS nodes |
| `elasticsearchBasicAuth` | Empty | ES credentials in username:password format |
| `elasticsearchAPIKey` | Empty | API key for ES authentication |
| `usersElasticsearch` | Empty | Dedicated Elasticsearch for user indices |
| `shards` | Installation default | Number of shards per index |
| `replicas` | `0` | Number of replicas per ES/OS index |
| `maxESConns` | `30` | Maximum connections to ES/OS |
| `maxESRequests` | `500` | Maximum concurrent ES/OS requests |
| `dbFlushTimeout` | `5` | Flush timeout to ES/OS (seconds) |
| `rotateIndex` | `daily` | Index rotation frequency (hourly/daily/weekly/monthly) |

## Advanced Settings

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `rulesFiles` | Empty | Semicolon-separated rules files for packet classification |
| `magicMode` | `basic` | File type identification mode (basic, libmagic, both, none) |
| `pcapWriteSize` | `262144` | Buffer block size when writing PCAP files |
| `pcapDirTemplate` | Empty | Template for creating date-based directories |
| `pcapDirAlgorithm` | `round-robin` | Directory selection algorithm (round-robin, max-free-percent/bytes) |

## Configuration Override Methods

### Environment Variables
- **Format**: `ARKIME__option=value` (default section) or `ARKIME_section__option=value` (specific section)
- **Character conversion**: `-` → `DASH`, `:` → `COLON`, `/` → `SLASH`, `.` → `DOT`

### Command Line
- **Format**: `-o key=value` or `-o section.key=value`
- **Precedence**: CLI overrides take precedence over environment variables and config files

## Configuration Notes

- **Hierarchical overrides**: Sections `[default]`, `[nodeClass]`, and `[nodeName]` enable configuration inheritance
- **Security requirements**: Critical settings like `passwordSecret`, `serverSecret`, and `authMode` must be configured for secure cluster operation
- **Geolocation**: MaxMind GeoLite2 files are required for geolocation-based enrichments
- **Performance tuning**: Optimize capture performance using `packetThreads`, `maxPacketsInQueue`, `pcapWriteMethod`, and `pcapWriteSize`

## example of config file 

```ini
[default]
# Basic node identification
nodeName=arkime-standalone
hostName=localhost

# Elasticsearch/OpenSearch connection
elasticsearch=localhost:9200

# Network capture interface
interface=eth0

# Storage configuration
pcapDir=/opt/arkime/raw
maxFileSizeG=1

# Viewer settings
viewPort=8005
viewHost=0.0.0.0

# Authentication (digest mode for standalone)
authMode=digest
passwordSecret=CHANGE_ME_STRONG_PASSWORD
serverSecret=CHANGE_ME_SERVER_SECRET

# Basic performance settings
packetThreads=2
maxPacketsInQueue=100000
dbBulkSize=500000

# Compression
simpleCompression=zstd

# Minimal logging
debug=1
quiet=false

# Index settings
shards=1
replicas=0
rotateIndex=daily

# Session timeouts
tcpTimeout=600
tcpClosingTimeout=5

# Disk space management
minFreeSpaceG=2

# Basic HTTP parsing
parseHTTPHeaderRequestAll=true
parseHTTPHeaderResponseAll=false
parseQSValue=true
```

## References

- [Arkime Settings Documentation](https://arkime.com/settings)
- [Arkime Configuration Sample](https://github.com/arkime/arkime/blob/main/release/config.ini.sample)
- [Arkime Docker Settings](https://arkime.com/docker)
- [DeepWiki Configuration Guide](https://deepwiki.com/arkime/arkime/8.3-configuration-options)
