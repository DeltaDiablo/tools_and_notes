# Malcolm v26.02.0 — Idaho National Laboratory Network Traffic Analysis

Malcolm is an open-source network traffic analysis tool developed by [Idaho National Laboratory (INL)](https://github.com/idaholab/Malcolm). This deployment bundles:

| Component | Role |
| --- | --- |
| **Arkime** | Full packet capture, indexing, and session analysis |
| **Zeek** | Network security monitor — generates structured logs from PCAPs |
| **Suricata** | IDS/IPS — generates alerts from PCAPs |
| **OpenSearch** | Central data lake and search backend |
| **OpenSearch Dashboards** | Dashboards and visualization (Malcolm dashboards pre-loaded) |
| **Logstash** | Log enrichment and transformation pipeline |
| **Filebeat** | Ships Zeek/Suricata logs to Logstash |
| **nginx-proxy** | Reverse proxy, TLS termination, and authentication |
| **pcap-monitor** | Watches for new PCAP files and dispatches processing jobs |
| **upload** | Web UI for drag-and-drop PCAP uploads |

---

## System Requirements

| Resource | Minimum | Recommended |
| --- | --- | --- |
| RAM | 16 GB | 32 GB |
| CPU | 8 cores | 16 cores |
| Disk | 100 GB | 500 GB+ |
| Docker | 24.x+ | — |

> **Windows users:** Docker Desktop with WSL2 backend is required.

---

## Initial Setup (first time only)

## Debian GNU/Linux 12 (64-bit) Step-by-Step

Use this path if you are running Malcolm directly on Debian 12 x86_64 (no WSL).

### ESXi VM deployment notes (recommended for Debian installs)

If you are deploying on VMware ESXi, build the VM with enough resources for packet processing and OpenSearch.

| VM Setting | Minimum | Recommended |
| --- | --- | --- |
| vCPU | 8 | 16 |
| RAM | 16 GB | 32 GB |
| Disk | 100 GB | 500 GB+ |
| NIC | vmxnet3 | vmxnet3 |

Recommended VM configuration:

1. Create a new Linux VM (Debian 12, 64-bit).
2. Use a single large datastore disk or separate OS and data disks.
3. Use thin provisioning only if your datastore has strong free-space monitoring.
4. Attach a vmxnet3 adapter and place it on the correct port group/VLAN.
5. Install `open-vm-tools` in Debian for clean guest operations.
6. Confirm NTP time sync on both ESXi host and Debian guest.

Optional storage layout (better for large PCAP workloads):

- Disk 1: OS and Docker runtime
- Disk 2: Malcolm data and PCAP storage

If using a separate data disk, mount it (for example at `/data/malcolm`) and bind Malcolm capture storage to that path in `docker-compose.yml`.

### ESXi preflight checklist (Debian guest)

Run these checks inside the Debian VM before pulling Malcolm images.

#### Verify CPU, memory, architecture, and kernel

```bash
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
nproc
free -h
```

#### Verify disk capacity (root and data mount if present)

```bash
df -h /
df -h /data/malcolm 2>/dev/null || true
```

#### Verify vm.max_map_count is set correctly

```bash
sysctl vm.max_map_count
```

Expected value: `vm.max_map_count = 262144`.

1. Verify Docker Engine and Compose plugin are healthy:

```bash
docker --version
docker compose version
sudo systemctl is-active docker
docker info >/dev/null && echo "Docker daemon reachable"
```

#### Verify network and DNS from the VM to required endpoints

```bash
getent hosts ghcr.io
curl -I https://ghcr.io
```

#### Optional performance check for VM tools and time sync

```bash
dpkg -l open-vm-tools | grep '^ii' || echo "open-vm-tools not installed"
timedatectl status
```

If all checks pass, continue with the Debian installation steps below.

### 1. Install prerequisites

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apache2-utils git
```

### 2. Install Docker Engine and Docker Compose plugin

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Optional (run Docker without `sudo`):

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Set vm.max_map_count (required for OpenSearch)

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-malcolm-opensearch.conf
sudo sysctl --system
```

Verify:

```bash
sysctl vm.max_map_count
```

Expected output includes: `vm.max_map_count = 262144`.

### 4. Clone this project and enter the Malcolm directory

```bash
git clone <your-repo-url>
cd tools_and_notes/development/Malcolm_project
```

### 5. Log in to GitHub Container Registry

```bash
docker login ghcr.io
```

Use your GitHub username and a Personal Access Token (PAT) with `read:packages` scope.

### 6. Pull Malcolm images

```bash
docker compose --profile malcolm pull
```

### 7. Generate auth and TLS files

```bash
bash create_auth_files.sh
```

This generates:

- `.opensearch.primary.curlrc`
- `nginx/htpasswd`
- `nginx/certs/`

### 8. Start Malcolm

```bash
docker compose --profile malcolm up -d
```

OpenSearch usually needs ~3 minutes to become healthy. Logstash can take ~5 minutes to fully initialize.

### 9. Check status and logs

```bash
docker compose ps
docker compose logs -f opensearch
```

### 10. Access the web interfaces

From the Debian host browser (or another host that can reach it):

- `https://localhost`
- `https://localhost/arkime`
- `https://localhost/dashboards`
- `https://localhost/upload`

Default UI user: `admin` with the password set during `create_auth_files.sh`.

---

## Rocky Linux 9.5 (64-bit) Step-by-Step

Use this path if you are running Malcolm directly on Rocky Linux 9.5 x86_64.

### 1. Install prerequisites

```bash
sudo dnf -y update
sudo dnf -y install dnf-plugins-core curl git httpd-tools policycoreutils-python-utils
```

### 2. Install Docker Engine and Compose plugin

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

Optional (run Docker without `sudo`):

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Set vm.max_map_count (required for OpenSearch)

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-malcolm-opensearch.conf
sudo sysctl --system
sysctl vm.max_map_count
```

Expected output includes: `vm.max_map_count = 262144`.

### 4. Configure SELinux for bind mounts (if using host paths)

For host bind-mounted directories, use SELinux labels in `docker-compose.yml` mounts (`:z` or `:Z`) or set file contexts.

Example context assignment:

```bash
sudo semanage fcontext -a -t container_file_t '/data/malcolm(/.*)?'
sudo restorecon -Rv /data/malcolm
```

### 5. Configure firewall access

```bash
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --reload
```

If OpenSearch API should remain internal, omit port 9200.

### 6. Clone this project and enter the Malcolm directory

```bash
git clone <your-repo-url>
cd tools_and_notes/development/Malcolm_project
```

### 7. Log in to GitHub Container Registry

```bash
docker login ghcr.io
```

Use your GitHub username and a Personal Access Token (PAT) with `read:packages` scope.

### 8. Pull Malcolm images

```bash
docker compose --profile malcolm pull
```

### 9. Generate auth and TLS files

```bash
bash create_auth_files.sh
```

This generates:
- `.opensearch.primary.curlrc`
- `nginx/htpasswd`
- `nginx/certs/`

### 10. Start Malcolm

```bash
docker compose --profile malcolm up -d
```

### 11. Check status and logs

```bash
docker compose ps
docker compose logs -f opensearch
```

### 12. Access web interfaces

- `https://localhost`
- `https://localhost/arkime`
- `https://localhost/dashboards`
- `https://localhost/upload`

Default UI user: `admin` with the password set during `create_auth_files.sh`.

---

## Running Malcolm with Podman

Use this path if you prefer Podman over Docker.

### 1. Install Podman and Podman Compose

Rocky Linux 9.5:

```bash
sudo dnf -y install podman podman-compose
```

Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y podman podman-compose
```

### 2. Enable Podman socket (recommended)

```bash
sudo systemctl enable --now podman.socket
```

### 3. Set vm.max_map_count (required for OpenSearch)

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-malcolm-opensearch.conf
sudo sysctl --system
sysctl vm.max_map_count
```

Expected output includes: `vm.max_map_count = 262144`.

### 4. Change to Malcolm project directory

```bash
cd tools_and_notes/development/Malcolm_project
```

### 5. Authenticate to GitHub Container Registry

```bash
podman login ghcr.io
```

Use your GitHub username and a Personal Access Token (PAT) with `read:packages` scope.

### 6. Generate auth and TLS files

```bash
bash create_auth_files.sh
```

Note: `create_auth_files.sh` auto-detects its base path from script location. You can still override it temporarily with `BASE=/your/path bash create_auth_files.sh`.

### 7. Pull images and start the stack

```bash
podman compose --profile malcolm pull
podman compose --profile malcolm up -d
```

### 8. Check status and logs

```bash
podman compose ps
podman compose logs -f opensearch
```

### 9. Access web interfaces

- `https://localhost`
- `https://localhost/arkime`
- `https://localhost/dashboards`
- `https://localhost/upload`

### Podman compatibility notes

- Rootful Podman is recommended for this stack (simpler networking and fewer low-port binding issues).
- If you use bind mounts on SELinux-enabled hosts, label mount paths appropriately (`:z`/`:Z` or `semanage` + `restorecon`).
- If `podman compose` is unavailable, use `podman-compose` with equivalent commands.

---

### 1. Set vm.max_map_count (WSL2 requirement for OpenSearch)

```powershell
wsl -d Ubuntu-20.04 -e bash -c "sudo sysctl -w vm.max_map_count=262144"
```

### 2. Log in to GitHub Container Registry (needed to pull Malcolm images)

```powershell
docker login ghcr.io
```
Use a GitHub Personal Access Token (PAT) with `read:packages` scope as the password.

### 3. Pull images

```powershell
docker compose --profile malcolm pull
```

### 4. Generate authentication files

Run this from WSL2 (requires `htpasswd` from `apache2-utils`):

```bash
bash create_auth_files.sh
```

This generates:
- `.opensearch.primary.curlrc` — internal service account credentials for OpenSearch
- `nginx/htpasswd` — bcrypt password for the web UI
- `nginx/certs/` — self-signed TLS certificate

### 5. Start Malcolm

```powershell
docker compose --profile malcolm up -d
```

OpenSearch takes ~3 minutes to become healthy. Logstash takes ~5 minutes to initialize all pipelines. Full stack is ready in approximately 5-7 minutes.

### 6. Monitor startup

```powershell
docker compose ps
docker compose logs -f opensearch
```

---

## Accessing Malcolm

| Interface | URL | Credentials |
| --- | --- | --- |
| Malcolm (main UI) | <https://localhost> | `admin` / password from `create_auth_files.sh` |
| Arkime Viewer | <https://localhost/arkime> | same |
| OpenSearch Dashboards | <https://localhost/dashboards> | same |
| PCAP Upload | <https://localhost/upload> | same |
| OpenSearch API | <https://localhost:9200> | `malcolm_internal` / (from curlrc) |

> Note: The self-signed certificate will show a browser warning. Accept it to proceed.

---

## Uploading PCAPs

1. Go to **<https://localhost/upload>**
2. Drag and drop one or more `.pcap` / `.pcapng` files
3. Malcolm automatically routes them through:
   - **Zeek** → structured connection/DNS/HTTP/SSL logs
   - **Suricata** → alert logs
   - **Arkime** → session index + raw PCAP storage
4. View results in the **OpenSearch Dashboards** or **Arkime viewer**

---

## Common Operations

### Stop Malcolm (preserves data)

```powershell
docker compose --profile malcolm down
```

### Stop Malcolm and wipe all data volumes (DESTRUCTIVE)

```powershell
docker compose --profile malcolm down -v
```

### Restart a single service

```powershell
docker compose restart suricata
```

### Check service health

```powershell
docker compose ps
```

### View OpenSearch indices

```powershell
# Via curl using the curlrc (run from the Malcolm project directory):
wsl -d Ubuntu-24.04 -e bash -c "curl -sk --config .opensearch.primary.curlrc https://localhost:9200/_cat/indices?v"
```

---

## Tuning

### OpenSearch heap

In `config/opensearch.env`, set `OPENSEARCH_JAVA_OPTS` to ~50% of total system RAM:

| System RAM | Recommended |
| --- | --- |
| 16 GB | `-server -Xms6g -Xmx6g ...` |
| 32 GB | `-server -Xms14g -Xmx14g ...` |
| 64 GB | `-server -Xms28g -Xmx28g ...` |

### Persistent PCAP storage on a local path

Replace the named volume with a bind mount in `docker-compose.yml`:

```yaml
volumes:
  pcap-capture-volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\malcolm-pcaps
```

---

## References

- [Malcolm GitHub (idaholab)](https://github.com/idaholab/Malcolm)
- [Malcolm Documentation](https://idaholab.github.io/Malcolm/)
- [Arkime Documentation](https://arkime.com/documentation)
- [Zeek Documentation](https://docs.zeek.org/)
- [Suricata Documentation](https://docs.suricata.io/)
