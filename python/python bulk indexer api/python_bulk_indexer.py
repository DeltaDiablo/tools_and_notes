import argparse
import configparser
from elasticsearch import Elasticsearch, helpers

def create_es_client(hosts, scheme='https', port=9200, username=None, password=None, verify_certs=False):
    es_hosts = [f"{scheme}://{host}:{port}" for host in hosts]
    auth = (username, password) if username and password else None
    return Elasticsearch(hosts=es_hosts, http_auth=auth, verify_certs=verify_certs)

def reindex_documents(es_client, source_index, dest_index, batch_size=10000, scroll='2m'):
    docs = helpers.scan(
        client=es_client,
        index=source_index,
        query={"query": {"match_all": {}}},
        scroll=scroll,
        size=batch_size
    )
    actions = (
        {
            "_index": dest_index,
            "_id": doc['_id'],
            "_source": doc['_source']
        }
        for doc in docs
    )
    helpers.bulk(es_client, actions)

def parse_config(config_path='bulk_indexer.ini'):
    config = configparser.ConfigParser()
    config.read(config_path)
    if 'elasticsearch' not in config:
        return None
    es_conf = config['elasticsearch']
    return {
        'host': es_conf.get('host', '').split(),
        'scheme': es_conf.get('scheme', 'https'),
        'port': es_conf.getint('port', 9200),
        'username': es_conf.get('username', 'elastic'),
        'password': es_conf.get('password', 'changeme'),
        'old_index': es_conf.get('old_index'),
        'new_index': es_conf.get('new_index'),
        'batch_size': es_conf.getint('batch_size', 10000),
        'scroll': es_conf.get('scroll', '2m'),
        'verify_certs': es_conf.getboolean('verify_certs', False)
    }


def parse_arguments():
    parser = argparse.ArgumentParser(description="Bulk indexer for Elasticsearch")
    parser.add_argument('--host', nargs='+', required=True, help='Elasticsearch host(s)')
    parser.add_argument('--scheme', default='https', help='Connection scheme (http or https)')
    parser.add_argument('--port', type=int, default=9200, help='Elasticsearch port')
    parser.add_argument('--username', default='elastic', help='Elasticsearch username')
    parser.add_argument('--password', default='changeme', help='Elasticsearch password')
    parser.add_argument('--old_index', required=True, help='Source index name')
    parser.add_argument('--new_index', required=True, help='Destination index name')
    parser.add_argument('--batch_size', type=int, default=10000, help='Batch size for bulk indexing')
    parser.add_argument('--scroll', default='2m', help='Scroll duration')
    parser.add_argument('--verify_certs', action='store_true', help='Verify SSL certificates')
    return parser.parse_args()

def main():
    config_path = 'bulk_indexer.ini'
    try:
        with open(config_path, 'r') as f:
            pass
        conf = parse_config(config_path)
        print(conf)
        if not conf:
            print("Missing required config values in bulk_indexer.ini.")
            return
    except FileNotFoundError:
        conf = None
        args = argparse.Namespace(**conf)
    else:
        args = parse_arguments()
    es_client = create_es_client(
        hosts=args.host,
        scheme=args.scheme,
        port=args.port,
        username=args.username,
        password=args.password,
        verify_certs=args.verify_certs
    )
    reindex_documents(
        es_client,
        args.old_index,
        args.new_index,
        batch_size=args.batch_size,
        scroll=args.scroll
    )

if __name__ == "__main__":
    main()
