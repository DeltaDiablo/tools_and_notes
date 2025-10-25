# Changing File/Directory Permissions from Read-Only to Read-Write

## Using chmod command

### For Files
```bash
# Make file writable for owner
chmod u+w filename

# Make file writable for all users
chmod a+w filename

# Set specific permissions (owner: read/write, group/others: read)
chmod 644 filename

# Set full permissions (read/write/execute for owner, read/execute for group/others)
chmod 755 filename
```

### For Directories
```bash
# Make directory writable for owner
chmod u+w directory_name

# Make directory and all contents writable (recursive)
chmod -R u+w directory_name

# Set directory permissions (typically 755 for directories)
chmod 755 directory_name

# Recursively set permissions for directory and contents
chmod -R 755 directory_name
```

## Permission Number Reference
- `4` = Read (r)
- `2` = Write (w)  
- `1` = Execute (x)
- `6` = Read + Write (4+2)
- `7` = Read + Write + Execute (4+2+1)

## Examples
```bash
# Remove read-only attribute from file
chmod +w myfile.txt

# Make script executable and writable
chmod 755 script.sh

# Recursively change directory permissions
chmod -R 644 /path/to/directory
```