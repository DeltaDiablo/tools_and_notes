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
