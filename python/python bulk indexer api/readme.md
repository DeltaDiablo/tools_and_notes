# Python Bulk Indexer API

A simple Python tool for bulk indexing data.

## Installation

1. **Clone the repository** (if applicable).

2. **Create a virtual environment** (recommended):
    ```bash
    python -m venv venv
    # Activate on Windows:
    venv\Scripts\activate
    # Activate on macOS/Linux:
    source venv/bin/activate
    ```

3. **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

## Usage

Run the script from the command line with required arguments:
```bash
python python_bulk_indexer.py --host localhost --old-index source_index --new-index dest_index
```

Optional arguments:
- `--username`
- `--password`
- `--port`
- `--scheme`
- `--batch-size`
- `--scroll`
- `--verify-certs`

See all options:
```bash
python python_bulk_indexer.py --help
```

## Configuration

Adjust configuration files or environment variables as needed before running.

## Notes

- Requires Python 3.x.
- Use `--help` for more options:
    ```bash
    python python_bulk_indexer.py --help
    ```