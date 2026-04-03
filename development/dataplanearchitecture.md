# Data Plane Architecture Extension

Planning architecture extension with Auditbeat, Logstash, and Fleet components. This document outlines roles, data flows, and Kubernetes placement.

## Core Roles with New Components

| Component | Role in the Data Plane |
| --- | --- |
| Elasticsearch | Central data lake, search, analytics, SIEM backend |
| Kibana | UI, Elastic Security, Fleet UI |
| Fleet Server | Central management for Elastic Agents and Defend |
| Elastic Agent | Unified shipper (logs, metrics, Defend, Auditd) |
| Auditbeat | Legacy/special audit logs where Agent isn't used |
| Logstash | Heavy transform, routing, complex enrichment |
| Malcolm | Network/PCAP → Zeek/Suricata/Arkime → ES |
| XSOAR | Orchestration, playbooks, response |
| Enrichment Services | TI, CMDB, user/asset context |

## 1. Strategic Default: Elastic Agent + Fleet

Use **Elastic Agent (managed by Fleet)** as your default collector:

- **Endpoints/Servers:** Elastic Agent with Security integration (Elastic Defend), System, Auditd, OSQuery integrations via Fleet
- **Infrastructure:** Elastic Agent integrations where possible
- **Auditbeat:** Keep only where Agent migration isn't possible or specific auditd behavior is required

## 2. Component Placement (Kubernetes)

### Fleet Server

- **Namespace:** `sec-analytics` or `sec-data-plane`
- **Reachability:** Behind Ingress/LoadBalancer
- **Function:** Agent enrollment and policy management

### Logstash

- **Namespace:** `sec-data-plane`
- **Use when:** Complex parsing, fan-out to multiple destinations, heavy enrichment needed

### Auditbeat

- **Location:** Runs on hosts (not in K8s, except for node-level auditing)
- **Output:** ES ingest endpoint or Logstash

## 3. Data Flow Patterns

### Pattern A: Endpoint (Agent + Defend) → ES → SIEM

1. Elastic Agent with Defend enrolls to Fleet Server
2. Fleet policy configures data collection and integrations
3. ES ingest pipelines normalize to ECS
4. Elastic Security runs detection rules

### Pattern B: Network (Malcolm) → ES → SIEM

1. Malcolm parses PCAP → Zeek/Suricata
2. Output to ES directly or via Logstash for ECS mapping
3. Data indexes to `logs-network-*`

### Pattern C: Auditbeat → ES/Logstash

1. Auditbeat on special hosts sends to ES ingest or Logstash
2. Data lands in `logs-audit-*` namespace

## 4. Kubernetes Namespace Structure

| Namespace | Components |
| --- | --- |
| `sec-data-plane` | Elasticsearch, Logstash |
| `sec-analytics` | Kibana, Fleet Server |
| `sec-orchestration` | XSOAR |
| `sec-enrichment` | TI, CMDB services |
| `sec-sensors` | Malcolm UI, collectors |

## 5. Direct to ES vs. Logstash Decision

**Use Direct to ES when:**

- Using Elastic Agent + Fleet
- Transforms can be expressed in ingest pipelines
- Lower latency preferred

**Use Logstash when:**

- Complex conditionals and branching needed
- Fan-out to multiple destinations required
- Integrating non-Elastic sources needing heavy processing

## 6. Migration and Scaling Considerations

- Maintain ECS standardization across all sources
- Plan for dedicated ingest nodes at scale
- Implement Hot/Warm/Cold tiers with ILM
- Migrate legacy Beats configurations into Fleet integrations
