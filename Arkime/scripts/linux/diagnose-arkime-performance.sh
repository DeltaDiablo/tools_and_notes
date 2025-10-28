#!/bin/bash
# diagnose-arkime-performance.sh - Diagnose and fix Arkime memory/disk queue issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Function to check current Arkime pod status
check_arkime_status() {
    log "Checking Arkime pod status and resource usage..."
    
    echo "=== Arkime Pod Status ==="
    kubectl get pods -l app=arkime-capture -o wide 2>/dev/null || echo "No Arkime pods found"
    
    # Get pod name
    local pod_name
    pod_name=$(kubectl get pods -l app=arkime-capture -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$pod_name" ]; then
        echo ""
        echo "=== Resource Usage ==="
        kubectl top pod "$pod_name" 2>/dev/null || echo "Metrics not available"
        
        echo ""
        echo "=== Pod Description (Events) ==="
        kubectl describe pod "$pod_name" | grep -A 20 "Events:" || echo "No events found"
        
        echo ""
        echo "=== Container Logs (last 50 lines) ==="
        kubectl logs "$pod_name" -c capture --tail=50 2>/dev/null || echo "No capture logs available"
    else
        error "No Arkime capture pod found"
        return 1
    fi
    
    echo ""
}

# Function to analyze current configuration issues
analyze_configuration() {
    log "Analyzing Arkime configuration for performance issues..."
    
    echo "=== Common Causes of Memory/Disk Queue Issues ==="
    echo ""
    
    echo "🔍 IDENTIFIED POTENTIAL ISSUES:"
    
    # Check memory limit
    echo "1. Memory Limit: Currently set to 20Gi"
    warn "   - 20GB may be insufficient for high-traffic environments"
    warn "   - Arkime can use 100MB-1GB per million packets in queue"
    
    # Check packet processing settings
    echo ""
    echo "2. Packet Processing Configuration:"
    warn "   - maxPacketsInQueue: 400,000 (packets waiting to be processed)"
    warn "   - packetsPerPoll: 500,000 (packets read per poll cycle)"
    warn "   - packetThreads: 3 (threads processing packets)"
    
    # Check disk settings
    echo ""
    echo "3. Disk Configuration:"
    warn "   - pcapWriteSize: 2,560,000 bytes (2.5MB per file)"
    warn "   - maxFileSizeG: 1GB (max PCAP file size)"
    warn "   - freespaceG: 25%% (min free space before rotation)"
    
    # Check Elasticsearch settings
    echo ""
    echo "4. Elasticsearch Configuration:"
    warn "   - dbBulkSize: 400,000 (documents per bulk request)"
    warn "   - maxESConns: 60 (max connections to ES)"
    warn "   - maxESRequests: 500 (max pending ES requests)"
    
    echo ""
}

# Function to provide immediate fixes
provide_immediate_fixes() {
    log "Immediate fixes for memory and disk queue issues..."
    
    echo "=== IMMEDIATE ACTIONS (Choose based on your situation) ==="
    echo ""
    
    echo "🚨 EMERGENCY: Stop packet capture temporarily"
    echo "kubectl scale deployment [arkime-deployment-name] --replicas=0"
    echo ""
    
    echo "🧹 CLEANUP: Clear old PCAP files"
    echo "# Find and remove old PCAP files to free disk space"
    echo "kubectl exec -it [pod-name] -- find /data/moloch/raw -name '*.pcap' -mtime +7 -delete"
    echo ""
    
    echo "📊 MONITORING: Check disk usage"
    echo "kubectl exec -it [pod-name] -- df -h /data/moloch/raw"
    echo ""
    
    echo "🔧 QUICK CONFIG FIXES:"
    cat << 'EOF'
# Reduce memory usage by lowering queue sizes:
maxPacketsInQueue: 200000        # (down from 400000)
packetsPerPoll: 250000          # (down from 500000)
dbBulkSize: 200000              # (down from 400000)

# Increase processing threads:
packetThreads: 6                # (up from 3)
tpacketv3NumThreads: 4          # (up from 2)

# Improve disk management:
maxFileSizeG: 0.5               # (down from 1GB for faster rotation)
pcapWriteSize: 1280000          # (down from 2.5MB for smaller writes)
freespaceG: 15%                 # (down from 25% to allow more data)
EOF
    echo ""
}

# Function to create optimized configuration
create_optimized_config() {
    log "Creating optimized Arkime configuration templates..."
    
    # High-traffic environment config
    cat > arkime-high-traffic-values.yaml << 'EOF'
# Arkime Configuration for High-Traffic Environment
# Use this for environments processing >1Gbps or >1M packets/sec

#### Resource Limits ####
mem_limit: 32Gi                 # Increased memory limit
cpu_request: 2000               # 2 CPU cores minimum

#### Packet Processing (Optimized for high traffic) ####
packetThreads: 8                # More threads for packet processing
maxPacketsInQueue: 200000       # Reduced queue to prevent memory bloat
packetsPerPoll: 100000          # Smaller polls for better memory management
tpacketv3NumThreads: 4          # More threads for packet capture
tpacketv3BlockSize: 16777216    # 16MB blocks for better performance

#### Disk Management ####
maxFileSizeG: 0.5               # Smaller files for faster rotation
pcapWriteSize: 1280000          # 1.25MB writes for better I/O
pcapWriteMethod: "simple"       # Most reliable write method
freespaceG: 10%                 # Less conservative free space

#### Elasticsearch Optimization ####
dbBulkSize: 100000              # Smaller bulk sizes for memory
maxESConns: 30                  # Fewer connections to reduce overhead
maxESRequests: 200              # Lower request queue
compressES: true                # Enable compression to save bandwidth

#### Index Management ####
rotateIndex: "hourly6"          # 6-hour rotation for manageability
spiDataMaxIndices: 10           # More indices for better distribution

#### Memory Management ####
maxStreams: 7000000             # Reduced from 14M to save memory
maxPackets: 5000                # Reduced from 10k to save memory
EOF
    
    # Low-resource environment config
    cat > arkime-low-resource-values.yaml << 'EOF'
# Arkime Configuration for Low-Resource Environment
# Use this for environments with limited memory/CPU

#### Resource Limits ####
mem_limit: 8Gi                  # Conservative memory limit
cpu_request: 500                # 0.5 CPU cores

#### Packet Processing (Conservative) ####
packetThreads: 2                # Minimal threads
maxPacketsInQueue: 50000        # Small queue to prevent OOM
packetsPerPoll: 50000           # Small polls
tpacketv3NumThreads: 1          # Single capture thread
tpacketv3BlockSize: 4194304     # 4MB blocks

#### Disk Management ####
maxFileSizeG: 0.25              # Small files (250MB)
pcapWriteSize: 640000           # 640KB writes
pcapWriteMethod: "simple"       # Simple and reliable
freespaceG: 20%                 # Conservative free space

#### Elasticsearch Optimization ####
dbBulkSize: 50000               # Small bulk sizes
maxESConns: 10                  # Few connections
maxESRequests: 50               # Small request queue

#### Memory Management ####
maxStreams: 1000000             # 1M streams max
maxPackets: 2000                # 2k packets max
EOF
    
    # Disk-optimized config (minimal PCAP storage)
    cat > arkime-disk-optimized-values.yaml << 'EOF'
# Arkime Configuration for Minimal Disk Usage
# Use this when disk space is the primary concern

#### Disk Management (Aggressive) ####
pcapWriteMethod: "disablepcap"  # Disable PCAP writing entirely
maxFileSizeG: 0.1               # Very small files if PCAP enabled
freespaceG: 5%                  # Minimal free space requirement

#### Fast Rotation ####
rotateIndex: "hourly2"          # 2-hour rotation
spiDataMaxIndices: 20           # More frequent index cycling

#### Compression ####
compressES: true                # Compress all ES communication
supportSha256: true             # Enable SHA256 for deduplication

#### Selective Parsing (Reduce data stored) ####
parseSMTP: false                # Disable SMTP parsing to save space
parseSMB: false                 # Disable SMB parsing to save space
maxReqBody: 0                   # Don't store request bodies
EOF
    
    success "Created optimized configuration templates:"
    echo "  - arkime-high-traffic-values.yaml (for high-traffic environments)"
    echo "  - arkime-low-resource-values.yaml (for resource-constrained environments)"
    echo "  - arkime-disk-optimized-values.yaml (for minimal disk usage)"
    echo ""
}

# Function to create monitoring script
create_monitoring_script() {
    log "Creating Arkime monitoring script..."
    
    cat > monitor-arkime.sh << 'EOF'
#!/bin/bash
# monitor-arkime.sh - Monitor Arkime performance and health

# Get pod name
POD_NAME=$(kubectl get pods -l app=arkime-capture -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "ERROR: No Arkime pod found"
    exit 1
fi

echo "=== Arkime Health Monitor ==="
echo "Pod: $POD_NAME"
echo "Time: $(date)"
echo ""

# Resource usage
echo "=== Resource Usage ==="
kubectl top pod "$POD_NAME" 2>/dev/null || echo "Metrics not available"
echo ""

# Memory info from inside container
echo "=== Container Memory Info ==="
kubectl exec "$POD_NAME" -c capture -- free -h 2>/dev/null || echo "Memory info not available"
echo ""

# Disk usage
echo "=== Disk Usage ==="
kubectl exec "$POD_NAME" -c capture -- df -h /data/moloch/raw 2>/dev/null || echo "Disk info not available"
echo ""

# PCAP file count and sizes
echo "=== PCAP Files ==="
kubectl exec "$POD_NAME" -c capture -- find /data/moloch/raw -name "*.pcap" -printf "%s %p\n" 2>/dev/null | \
    awk '{total+=$1; count++} END {printf "Count: %d files, Total Size: %.2f GB\n", count, total/1024/1024/1024}' || \
    echo "PCAP info not available"
echo ""

# Recent log entries (look for errors)
echo "=== Recent Logs (Errors/Warnings) ==="
kubectl logs "$POD_NAME" -c capture --tail=100 | grep -E "(ERROR|WARN|error|warning|fail|Error)" | tail -10 || echo "No recent errors found"
echo ""

# Arkime stats (if available)
echo "=== Arkime Statistics ==="
kubectl exec "$POD_NAME" -c capture -- curl -s "http://localhost:8005/stats.json" 2>/dev/null | \
    jq -r '.currentTime, .monitoring, .memory' 2>/dev/null || echo "Stats not available"
EOF
    
    chmod +x monitor-arkime.sh
    success "Created monitor-arkime.sh - run this script to monitor Arkime health"
    echo ""
}

# Function to provide troubleshooting steps
provide_troubleshooting_steps() {
    log "Troubleshooting steps for Arkime memory/disk issues..."
    
    echo "=== ROOT CAUSE ANALYSIS ==="
    echo ""
    
    echo "🔍 Most Common Causes:"
    echo "1. HIGH TRAFFIC VOLUME"
    echo "   - Network traffic exceeds processing capacity"
    echo "   - Solution: Increase resources or reduce capture scope"
    echo ""
    
    echo "2. INSUFFICIENT MEMORY"
    echo "   - Arkime queues packets in memory before processing"
    echo "   - Large queues consume massive amounts of RAM"
    echo "   - Solution: Increase memory limits or reduce queue sizes"
    echo ""
    
    echo "3. SLOW ELASTICSEARCH"
    echo "   - ES cannot keep up with indexing requests"
    echo "   - Causes backpressure and memory buildup"
    echo "   - Solution: Optimize ES or reduce bulk sizes"
    echo ""
    
    echo "4. DISK I/O BOTTLENECK"
    echo "   - PCAP writes are slower than packet capture"
    echo "   - Solution: Use faster storage or reduce PCAP writing"
    echo ""
    
    echo "5. CONFIGURATION MISMATCH"
    echo "   - Settings optimized for different traffic patterns"
    echo "   - Solution: Tune configuration for your environment"
    echo ""
    
    echo "=== DIAGNOSTIC COMMANDS ==="
    echo ""
    echo "# Check current resource usage:"
    echo "kubectl top pods -l app=arkime-capture"
    echo ""
    echo "# Check disk space:"
    echo "kubectl exec [pod] -c capture -- df -h /data/moloch/raw"
    echo ""
    echo "# Check memory usage inside container:"
    echo "kubectl exec [pod] -c capture -- free -h"
    echo ""
    echo "# Check Arkime stats:"
    echo "kubectl exec [pod] -c capture -- curl localhost:8005/stats.json"
    echo ""
    echo "# Monitor packet drops:"
    echo "kubectl exec [pod] -c capture -- netstat -i"
    echo ""
}

# Main execution
main() {
    log "Diagnosing Arkime memory and disk queue issues..."
    echo ""
    
    check_arkime_status
    analyze_configuration
    provide_immediate_fixes
    create_optimized_config
    create_monitoring_script
    provide_troubleshooting_steps
    
    echo ""
    success "Arkime performance analysis complete!"
    echo ""
    log "NEXT STEPS:"
    echo "1. Run './monitor-arkime.sh' to check current status"
    echo "2. Choose appropriate config template and apply it"
    echo "3. Monitor performance after changes"
    echo "4. Consider scaling horizontally if single instance cannot handle load"
    echo ""
    
    warn "CRITICAL: If memory/disk issues persist, consider:"
    echo "  - Reducing network capture scope (BPF filters)"
    echo "  - Implementing load balancing across multiple Arkime instances"
    echo "  - Using dedicated high-performance storage for PCAP files"
    echo "  - Tuning Elasticsearch cluster for better indexing performance"
}

# Execute main function
main "$@"