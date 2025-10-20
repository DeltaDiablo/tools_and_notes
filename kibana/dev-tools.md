# Kibana Dev Tools

A collection of useful Elasticsearch queries and commands for Kibana Dev Tools.

## Index Operations

### List indices
```json
GET _cat/indices?v
GET _cat/indices?v&s=store.size:desc
GET _cat/indices/<index-pattern>?v
```

### Index information
```json
# Get index settings
GET /<index-name>/_settings

# Get index mappings
GET /<index-name>/_mapping

# Get index stats
GET /<index-name>/_stats

# Get index count
GET /<index-name>/_count
```

### Create and delete indices
```json
# Create index
PUT /<index-name>

# Create index with settings
PUT /<index-name>
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  }
}

# Delete index
DELETE /<index-name>

# Delete multiple indices
DELETE /<index-pattern>*
```

## Document Operations

### Create documents
```json
# Create document with auto-generated ID
POST /<index-name>/_doc
{
  "field1": "value1",
  "field2": "value2"
}

# Create document with specific ID
PUT /<index-name>/_doc/<document-id>
{
  "field1": "value1",
  "field2": "value2"
}

# Create document only if it doesn't exist
PUT /<index-name>/_create/<document-id>
{
  "field1": "value1"
}
```

### Read documents
```json
# Get document by ID
GET /<index-name>/_doc/<document-id>

# Get only source
GET /<index-name>/_source/<document-id>

# Get multiple documents
GET /<index-name>/_mget
{
  "ids": ["id1", "id2", "id3"]
}
```

### Update documents
```json
# Update document
POST /<index-name>/_update/<document-id>
{
  "doc": {
    "field1": "new_value"
  }
}

# Update with script
POST /<index-name>/_update/<document-id>
{
  "script": {
    "source": "ctx._source.counter += params.count",
    "params": {
      "count": 1
    }
  }
}

# Upsert (update or insert)
POST /<index-name>/_update/<document-id>
{
  "doc": {
    "field1": "value1"
  },
  "doc_as_upsert": true
}
```

### Delete documents
```json
# Delete document
DELETE /<index-name>/_doc/<document-id>

# Delete by query
POST /<index-name>/_delete_by_query
{
  "query": {
    "match": {
      "field": "value"
    }
  }
}
```

## Search Queries

### Basic search
```json
# Search all documents
GET /<index-name>/_search

# Match all
GET /<index-name>/_search
{
  "query": {
    "match_all": {}
  }
}

# Match query
GET /<index-name>/_search
{
  "query": {
    "match": {
      "field_name": "search text"
    }
  }
}

# Multi-match query
GET /<index-name>/_search
{
  "query": {
    "multi_match": {
      "query": "search text",
      "fields": ["field1", "field2"]
    }
  }
}
```

### Term-level queries
```json
# Term query (exact match)
GET /<index-name>/_search
{
  "query": {
    "term": {
      "field_name.keyword": "exact_value"
    }
  }
}

# Terms query (multiple exact matches)
GET /<index-name>/_search
{
  "query": {
    "terms": {
      "field_name": ["value1", "value2", "value3"]
    }
  }
}

# Range query
GET /<index-name>/_search
{
  "query": {
    "range": {
      "age": {
        "gte": 10,
        "lte": 20
      }
    }
  }
}

# Exists query
GET /<index-name>/_search
{
  "query": {
    "exists": {
      "field": "field_name"
    }
  }
}

# Wildcard query
GET /<index-name>/_search
{
  "query": {
    "wildcard": {
      "field_name": "val*"
    }
  }
}
```

### Boolean queries
```json
# Bool query combining multiple conditions
GET /<index-name>/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "field1": "value1" } }
      ],
      "filter": [
        { "term": { "field2": "value2" } },
        { "range": { "age": { "gte": 18 } } }
      ],
      "should": [
        { "match": { "field3": "value3" } }
      ],
      "must_not": [
        { "match": { "field4": "value4" } }
      ]
    }
  }
}
```

### Sorting and pagination
```json
# Sort results
GET /<index-name>/_search
{
  "query": { "match_all": {} },
  "sort": [
    { "field_name": "asc" },
    { "timestamp": "desc" }
  ]
}

# Pagination with from/size
GET /<index-name>/_search
{
  "query": { "match_all": {} },
  "from": 0,
  "size": 10
}

# Search after (for deep pagination)
GET /<index-name>/_search
{
  "query": { "match_all": {} },
  "size": 10,
  "sort": [
    { "timestamp": "asc" }
  ],
  "search_after": [1609459200000]
}
```

### Filtering fields
```json
# Include specific fields
GET /<index-name>/_search
{
  "query": { "match_all": {} },
  "_source": ["field1", "field2"]
}

# Exclude specific fields
GET /<index-name>/_search
{
  "query": { "match_all": {} },
  "_source": {
    "excludes": ["field3"]
  }
}
```

## Aggregations

### Metrics aggregations
```json
# Average
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "avg_age": {
      "avg": {
        "field": "age"
      }
    }
  }
}

# Sum, min, max
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "total_amount": { "sum": { "field": "amount" } },
    "min_price": { "min": { "field": "price" } },
    "max_price": { "max": { "field": "price" } }
  }
}

# Stats (count, min, max, avg, sum)
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "price_stats": {
      "stats": {
        "field": "price"
      }
    }
  }
}
```

### Bucket aggregations
```json
# Terms aggregation (group by field)
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "categories": {
      "terms": {
        "field": "category.keyword",
        "size": 10
      }
    }
  }
}

# Date histogram
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "events_over_time": {
      "date_histogram": {
        "field": "timestamp",
        "calendar_interval": "day"
      }
    }
  }
}

# Range aggregation
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "price_ranges": {
      "range": {
        "field": "price",
        "ranges": [
          { "to": 50 },
          { "from": 50, "to": 100 },
          { "from": 100 }
        ]
      }
    }
  }
}

# Nested aggregations
GET /<index-name>/_search
{
  "size": 0,
  "aggs": {
    "categories": {
      "terms": {
        "field": "category.keyword"
      },
      "aggs": {
        "avg_price": {
          "avg": {
            "field": "price"
          }
        }
      }
    }
  }
}
```

## Index Templates and Mappings

### Create index template
```json
PUT _index_template/<template-name>
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "timestamp": { "type": "date" },
        "message": { "type": "text" },
        "level": { "type": "keyword" }
      }
    }
  }
}
```

### Update mappings
```json
# Add new field to mapping
PUT /<index-name>/_mapping
{
  "properties": {
    "new_field": {
      "type": "keyword"
    }
  }
}
```

## Bulk Operations

### Bulk index/update/delete
```json
POST _bulk
{ "index": { "_index": "test-index", "_id": "1" } }
{ "field1": "value1" }
{ "index": { "_index": "test-index", "_id": "2" } }
{ "field1": "value2" }
{ "update": { "_index": "test-index", "_id": "1" } }
{ "doc": { "field2": "value3" } }
{ "delete": { "_index": "test-index", "_id": "2" } }
```

## Cluster and Node Operations

### Cluster health
```json
GET _cluster/health
GET _cluster/health?level=indices
GET _cluster/health/<index-name>
```

### Cluster settings
```json
# Get cluster settings
GET _cluster/settings

# Update cluster settings
PUT _cluster/settings
{
  "persistent": {
    "indices.recovery.max_bytes_per_sec": "50mb"
  }
}
```

### Node information
```json
GET _cat/nodes?v
GET _nodes
GET _nodes/stats
```

## Index Lifecycle Management

### Reindex
```json
POST _reindex
{
  "source": {
    "index": "old-index"
  },
  "dest": {
    "index": "new-index"
  }
}
```

### Refresh and flush
```json
# Refresh index
POST /<index-name>/_refresh

# Flush index
POST /<index-name>/_flush

# Force merge
POST /<index-name>/_forcemerge
```

### Index aliases
```json
# Create alias
POST _aliases
{
  "actions": [
    { "add": { "index": "index-name", "alias": "alias-name" } }
  ]
}

# Remove alias
POST _aliases
{
  "actions": [
    { "remove": { "index": "index-name", "alias": "alias-name" } }
  ]
}

# Get aliases
GET _cat/aliases?v
GET /<index-name>/_alias
```

## Useful Commands

### Count documents
```json
GET /<index-name>/_count
GET /<index-name>/_count
{
  "query": {
    "match": {
      "field": "value"
    }
  }
}
```

### Validate query
```json
GET /<index-name>/_validate/query
{
  "query": {
    "match": {
      "field": "value"
    }
  }
}
```

### Explain query
```json
GET /<index-name>/_explain/<document-id>
{
  "query": {
    "match": {
      "field": "value"
    }
  }
}
```

## Common Patterns

### Time-based queries (last 24 hours)
```json
GET /<index-name>/_search
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-24h",
        "lte": "now"
      }
    }
  }
}
```

### Full-text search with highlighting
```json
GET /<index-name>/_search
{
  "query": {
    "match": {
      "content": "search text"
    }
  },
  "highlight": {
    "fields": {
      "content": {}
    }
  }
}
```

### Search with filters (no scoring)
```json
GET /<index-name>/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "status": "active" } },
        { "range": { "price": { "gte": 10 } } }
      ]
    }
  }
}
```
