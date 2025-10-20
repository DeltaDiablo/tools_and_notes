import requests
import json
#import the elasticsearch client
from elasticsearch import Elasticsearch

#fetch the USGS GeoJSON data for all earthquakes in the past month
url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"
data = requests.get(url).json()

#transform the data into bulk format for Elasticsearch
with open("bulk.json", "w") as f:
    for feature in data["features"]:
        doc = {
            "mag": feature["properties"]["mag"],
            "place": feature["properties"]["place"],
            "time": feature["properties"]["time"],
            "location": {
                "lat": feature["geometry"]["coordinates"][1],
                "lon": feature["geometry"]["coordinates"][0]
            }
        }
        f.write('{ "index": { "_index": "earthquakes" } }\n')
        f.write(f"{json.dumps(doc)}\n")

#optional: index the data into Elasticsearch
es = Elasticsearch(hosts=["https://elasticsearch.default.svc.cluster.local:9200"], http_auth=("elastic", "B000nlxU55G8W0H4Tg75QjKk"), verify_certs=False)
with open("bulk.json", "r") as f:
    bulk_data = f.read()
    es.bulk(body=bulk_data)
    
print("Data transformation complete. Bulk data written to bulk.json")

