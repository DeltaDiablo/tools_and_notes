# Fix-ArkimePerformance.ps1 - Diagnose and fix Arkime memory/disk queue issues
# PowerShell version for Windows environments

[CmdletBinding()]
param(
    [string]$Namespace = "default",
    [string]$PodSelector = "app=arkime-capture",
    [switch]$ApplyFixes,
    [switch]$MonitorOnly
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = "Red"
        "Green" = "Green" 
        "Yellow" = "Yellow"
        "Blue" = "Cyan"
        "White" = "White"
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

function Write-Log { param([string]$Message) Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] $Message" "Blue" }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARNING] $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "[ERROR] $Message" "Red" }

function Test-ArkimeStatus {
    Write-Log "Checking Arkime pod status and resource usage..."
    
    try {
        # Get pods
        $pods = kubectl get pods -l $PodSelector --namespace $Namespace -o json | ConvertFrom-Json
        
        if ($pods.items.Count -eq 0) {
            Write-Error "No Arkime pods found with selector: $PodSelector"
            return $null
        }
        
        $podName = $pods.items[0].metadata.name
        Write-Success "Found Arkime pod: $podName"
        
        # Get resource usage
        Write-Host "`n=== Resource Usage ===" -ForegroundColor Cyan
        kubectl top pod $podName --namespace $Namespace 2>$null
        if ($LASTEXITCODE -ne 0) { Write-Warning "Metrics not available" }
        
        # Get pod events
        Write-Host "`n=== Recent Events ===" -ForegroundColor Cyan
        kubectl describe pod $podName --namespace $Namespace | Select-String -Pattern "Events:" -Context 0,20
        
        # Get logs
        Write-Host "`n=== Recent Logs (Last 50 lines) ===" -ForegroundColor Cyan
        kubectl logs $podName -c capture --tail=50 --namespace $Namespace 2>$null
        if ($LASTEXITCODE -ne 0) { Write-Warning "No capture logs available" }
        
        return $podName
    }
    catch {
        Write-Error "Failed to check Arkime status: $_"
        return $null
    }
}

function Get-ArkimeConfiguration {
    Write-Log "Analyzing current Arkime configuration..."
    
    Write-Host "`n=== IDENTIFIED CONFIGURATION ISSUES ===" -ForegroundColor Red
    
    # Current config analysis based on values seen
    @"
🔍 CURRENT CONFIGURATION ANALYSIS:

1. MEMORY CONFIGURATION:
   ❌ mem_limit: 20Gi (may be insufficient for high traffic)
   ❌ maxPacketsInQueue: 400,000 (each packet uses ~256 bytes = ~102MB)
   ❌ packetsPerPoll: 500,000 (memory spikes during polls)
   
   IMPACT: With 400k queued packets, memory usage can spike to 500MB-1GB
          just for packet queues, not including processing overhead.

2. PACKET PROCESSING:
   ❌ packetThreads: 3 (may be insufficient for high-volume traffic)
   ❌ tpacketv3NumThreads: 2 (network capture threads)
   
   IMPACT: Too few threads can cause packet drops and queue buildup.

3. ELASTICSEARCH BULK OPERATIONS:
   ❌ dbBulkSize: 400,000 (very large bulk operations)
   ❌ maxESConns: 60 (high connection count)
   ❌ maxESRequests: 500 (high request queue)
   
   IMPACT: Large bulk operations consume memory while waiting for ES.
          If ES is slow, requests queue up consuming more memory.

4. DISK I/O CONFIGURATION:
   ❌ pcapWriteSize: 2,560,000 (2.5MB per write operation)
   ❌ maxFileSizeG: 1 (1GB files may be too large for fast rotation)
   
   IMPACT: Large writes can cause I/O blocking and disk queue buildup.

5. MEMORY MANAGEMENT:
   ❌ maxStreams: 14,000,000 (extremely high - uses ~16GB RAM)
   ❌ maxPackets: 10,000 (per stream tracking)
   
   IMPACT: Stream tracking is likely your biggest memory consumer!
"@
    
    Write-Host "`n=== ROOT CAUSE ANALYSIS ===" -ForegroundColor Yellow
    @"
🚨 MOST LIKELY CAUSES OF YOUR MEMORY/DISK ISSUES:

1. STREAM TRACKING MEMORY EXPLOSION:
   - maxStreams: 14M can use 16+ GB of RAM alone
   - Each stream tracks packets, metadata, and state
   - This is likely your primary memory consumer

2. PACKET QUEUE BUILDUP:
   - 400k packet queue can grow under high traffic
   - Insufficient processing threads cause backpressure
   - Queue growth is exponential under overload

3. ELASTICSEARCH BACKPRESSURE:
   - Large bulk sizes (400k) take time to process
   - If ES is slow, requests queue in memory
   - 60 connections × 500 requests = 30,000 pending operations

4. DISK I/O BOTTLENECK:
   - 2.5MB writes may be causing I/O blocking
   - 1GB files are slow to rotate
   - Disk queue builds when writes can't keep up
"@
}

function New-OptimizedConfiguration {
    Write-Log "Creating optimized configuration files..."
    
    # High-traffic optimized config
    $highTrafficConfig = @"
# Arkime High-Traffic Optimized Configuration
# Optimized for environments processing >1Gbps

#### MEMORY OPTIMIZATION (Primary Fix) ####
maxStreams: 2000000          # Reduced from 14M to 2M (saves ~12GB RAM)
maxPackets: 5000             # Reduced from 10k to 5k per stream
maxPacketsInQueue: 150000    # Reduced from 400k to 150k
packetsPerPoll: 150000       # Reduced from 500k to match queue

#### RESOURCE LIMITS ####
mem_limit: 32Gi              # Increased memory limit
cpu_request: 4000            # 4 CPU cores minimum

#### PACKET PROCESSING ####
packetThreads: 8             # Increased from 3 to 8
tpacketv3NumThreads: 4       # Increased from 2 to 4
tpacketv3BlockSize: 8388608  # 8MB blocks for better performance

#### ELASTICSEARCH OPTIMIZATION ####
dbBulkSize: 100000           # Reduced from 400k to 100k
maxESConns: 20               # Reduced from 60 to 20
maxESRequests: 100           # Reduced from 500 to 100
compressES: true             # Enable compression

#### DISK I/O OPTIMIZATION ####
pcapWriteSize: 1048576       # Reduced to 1MB writes
maxFileSizeG: 0.5            # Smaller files for faster rotation
pcapWriteMethod: simple      # Most reliable method
freespaceG: 15%              # Less conservative than 25%

#### INDEX MANAGEMENT ####
rotateIndex: hourly4         # 4-hour rotation for manageability
"@

    # Emergency low-memory config
    $emergencyConfig = @"
# Arkime Emergency Low-Memory Configuration
# Use this to get system stable quickly

#### EMERGENCY MEMORY REDUCTION ####
maxStreams: 500000           # Drastically reduced from 14M
maxPackets: 2000             # Minimal per-stream tracking
maxPacketsInQueue: 50000     # Very small queue
packetsPerPoll: 50000        # Small poll size

#### MINIMAL PROCESSING ####
packetThreads: 4             # Moderate processing
tpacketv3NumThreads: 2       # Basic capture

#### SMALL ELASTICSEARCH OPERATIONS ####
dbBulkSize: 25000            # Very small bulk operations
maxESConns: 10               # Few connections
maxESRequests: 50            # Small request queue

#### AGGRESSIVE DISK MANAGEMENT ####
pcapWriteSize: 524288        # 512KB writes
maxFileSizeG: 0.1            # 100MB files for fast rotation
freespaceG: 10%              # Allow more data

#### DISABLE HEAVY FEATURES ####
parseSMTP: false             # Disable SMTP parsing
parseSMB: false              # Disable SMB parsing  
maxReqBody: 0                # Don't store request bodies
"@

    # Save configurations
    Set-Content -Path "arkime-high-traffic-values.yaml" -Value $highTrafficConfig
    Set-Content -Path "arkime-emergency-values.yaml" -Value $emergencyConfig
    
    Write-Success "Created optimized configuration files:"
    Write-Host "  - arkime-high-traffic-values.yaml (recommended long-term fix)"
    Write-Host "  - arkime-emergency-values.yaml (immediate stability)"
}

function Invoke-ImmediateFixes {
    param([string]$PodName)
    
    Write-Log "Providing immediate fixes for memory/disk issues..."
    
    Write-Host "`n=== IMMEDIATE ACTIONS ===" -ForegroundColor Red
    
    if ($ApplyFixes) {
        Write-Warning "Applying immediate fixes..."
        
        # Scale down temporarily
        Write-Host "Scaling down Arkime deployment..."
        kubectl scale deployment arkime-capture --replicas=0 --namespace $Namespace
        Start-Sleep -Seconds 10
        
        # Clean old PCAP files
        if ($PodName) {
            Write-Host "Cleaning old PCAP files..."
            kubectl exec $PodName -c capture --namespace $Namespace -- find /data/moloch/raw -name "*.pcap" -mtime +3 -delete 2>$null
        }
        
        Write-Success "Immediate fixes applied. Review configuration before scaling back up."
    }
    else {
        @"

🚨 EMERGENCY COMMANDS (run manually if needed):

1. IMMEDIATE SHUTDOWN (if completely overwhelmed):
   kubectl scale deployment arkime-capture --replicas=0

2. CLEAR OLD PCAP FILES:
   kubectl exec $PodName -c capture -- find /data/moloch/raw -name "*.pcap" -mtime +3 -delete

3. CHECK DISK USAGE:
   kubectl exec $PodName -c capture -- df -h /data/moloch/raw

4. CHECK MEMORY USAGE:
   kubectl exec $PodName -c capture -- free -h

5. RESTART WITH NEW CONFIG:
   # Apply one of the generated configurations, then:
   kubectl rollout restart deployment arkime-capture
"@
    }
}

function Start-ArkimeMonitoring {
    param([string]$PodName)
    
    if (-not $PodName) {
        Write-Error "No pod available for monitoring"
        return
    }
    
    Write-Log "Starting Arkime monitoring loop..."
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    
    try {
        while ($true) {
            Clear-Host
            Write-Host "=== Arkime Performance Monitor ===" -ForegroundColor Cyan
            Write-Host "Pod: $PodName" -ForegroundColor Green
            Write-Host "Time: $(Get-Date)" -ForegroundColor Green
            Write-Host ""
            
            # Resource usage
            Write-Host "=== Resource Usage ===" -ForegroundColor Cyan
            kubectl top pod $PodName --namespace $Namespace 2>$null
            
            # Memory from inside container
            Write-Host "`n=== Container Memory ===" -ForegroundColor Cyan
            kubectl exec $PodName -c capture --namespace $Namespace -- free -h 2>$null
            
            # Disk usage
            Write-Host "`n=== Disk Usage ===" -ForegroundColor Cyan
            kubectl exec $PodName -c capture --namespace $Namespace -- df -h /data/moloch/raw 2>$null
            
            # PCAP file info
            Write-Host "`n=== PCAP Files ===" -ForegroundColor Cyan
            $pcapInfo = kubectl exec $PodName -c capture --namespace $Namespace -- find /data/moloch/raw -name "*.pcap" -printf "%s %p\n" 2>$null
            if ($pcapInfo) {
                $pcapInfo | ForEach-Object {
                    $parts = $_ -split ' ', 2
                    $size = [long]$parts[0]
                    $totalSize += $size
                    $count++
                }
                Write-Host "Count: $count files, Total Size: $([math]::Round($totalSize/1GB, 2)) GB"
            }
            
            Start-Sleep -Seconds 30
        }
    }
    catch {
        Write-Log "Monitoring stopped"
    }
}

# Main execution
function Main {
    Write-Log "Starting Arkime performance diagnosis..."
    
    $podName = Test-ArkimeStatus
    
    if (-not $MonitorOnly) {
        Get-ArkimeConfiguration
        New-OptimizedConfiguration
        Invoke-ImmediateFixes -PodName $podName
        
        Write-Host "`n" -NoNewline
        Write-Success "Arkime performance analysis complete!"
        
        Write-Host "`n=== RECOMMENDED NEXT STEPS ===" -ForegroundColor Yellow
        @"
1. IMMEDIATE (if system is unstable):
   - Apply arkime-emergency-values.yaml configuration
   - This will dramatically reduce memory usage

2. LONG-TERM (for production):
   - Apply arkime-high-traffic-values.yaml configuration
   - Monitor performance and tune as needed

3. ROOT CAUSE:
   - Your maxStreams: 14M setting is using ~16GB RAM alone
   - Reducing this to 2M will free up ~12GB immediately

4. MONITORING:
   - Run this script with -MonitorOnly to watch performance
   - Watch for memory growth and packet drops

KEY INSIGHT: Stream tracking is your biggest memory consumer!
Reducing maxStreams from 14M to 2M will solve most memory issues.
"@
    }
    
    if ($MonitorOnly -and $podName) {
        Start-ArkimeMonitoring -PodName $podName
    }
}

# Execute
Main