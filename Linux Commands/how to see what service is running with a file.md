# How to Find What Service is Using a File in Linux

## Method 1: Using `lsof` (List Open Files)

```bash
# Find what process is using a specific file
lsof /path/to/file

# Find what process is using files in a directory
lsof +D /path/to/directory

# Show only process IDs
lsof -t /path/to/file
```

## Method 2: Using `fuser`

```bash
# Show processes using a file
fuser /path/to/file

# Show processes with process IDs and user info
fuser -v /path/to/file

# Kill processes using a file
fuser -k /path/to/file
```

## Method 3: Using `/proc` filesystem

```bash
# Find which processes have the file open
grep -l "/path/to/file" /proc/*/maps 2>/dev/null

# Check file descriptors
ls -la /proc/*/fd | grep "/path/to/file"
```

## Method 4: For SystemD Systems

```bash
# List all services and their status
systemctl list-units --type=service

# Check specific service file usage
systemctl status service-name

# Show service dependencies
systemctl list-dependencies service-name
```

## Method 5: For Non-SystemD Containers

```bash
# Check running processes
ps aux | grep process-name

# Use netstat for network services
netstat -tulpn | grep :port

# Check process tree
pstree -p
```

## Example Output

```bash
$ lsof /var/log/nginx/access.log
COMMAND   PID     USER   FD   TYPE DEVICE SIZE/OFF    NODE NAME
nginx    1234     root    4w   REG  253,1    12345  567890 /var/log/nginx/access.log
```