# Python API Calls

A collection of simple and practical examples for making API calls with Python.

## Using the `requests` Library

The `requests` library is the most popular and user-friendly way to make HTTP requests in Python.

### Installation
```bash
pip install requests
```

### Basic GET Request
```python
import requests

# Simple GET request
response = requests.get('https://api.example.com/data')

# Check if request was successful
if response.status_code == 200:
    data = response.json()
    print(data)
else:
    print(f"Error: {response.status_code}")
```

### GET Request with Parameters
```python
import requests

# Using params dictionary
params = {
    'key': 'value',
    'page': 1,
    'limit': 10
}

response = requests.get('https://api.example.com/search', params=params)
print(response.url)  # Shows the full URL with parameters
print(response.json())
```

### GET Request with Headers
```python
import requests

headers = {
    'Authorization': 'Bearer YOUR_TOKEN_HERE',
    'Content-Type': 'application/json',
    'User-Agent': 'MyApp/1.0'
}

response = requests.get('https://api.example.com/data', headers=headers)
data = response.json()
print(data)
```

### POST Request with JSON Data
```python
import requests

url = 'https://api.example.com/users'
data = {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30
}

response = requests.post(url, json=data)

if response.status_code == 201:
    print("Created successfully!")
    print(response.json())
else:
    print(f"Error: {response.status_code}")
    print(response.text)
```

### POST Request with Form Data
```python
import requests

url = 'https://api.example.com/login'
data = {
    'username': 'user@example.com',
    'password': 'password123'
}

# Send as form data
response = requests.post(url, data=data)

# Or send as JSON
response = requests.post(url, json=data)

print(response.json())
```

### PUT Request (Update)
```python
import requests

url = 'https://api.example.com/users/123'
updated_data = {
    'name': 'Jane Doe',
    'email': 'jane@example.com'
}

response = requests.put(url, json=updated_data)

if response.status_code == 200:
    print("Updated successfully!")
    print(response.json())
```

### PATCH Request (Partial Update)
```python
import requests

url = 'https://api.example.com/users/123'
partial_data = {
    'email': 'newemail@example.com'
}

response = requests.patch(url, json=partial_data)
print(response.json())
```

### DELETE Request
```python
import requests

url = 'https://api.example.com/users/123'
response = requests.delete(url)

if response.status_code == 204:
    print("Deleted successfully!")
elif response.status_code == 200:
    print("Deleted!")
    print(response.json())
```

## Authentication Methods

### Basic Authentication
```python
import requests
from requests.auth import HTTPBasicAuth

url = 'https://api.example.com/data'
response = requests.get(url, auth=HTTPBasicAuth('username', 'password'))

# Shorthand
response = requests.get(url, auth=('username', 'password'))

print(response.json())
```

### Bearer Token Authentication
```python
import requests

url = 'https://api.example.com/data'
token = 'YOUR_ACCESS_TOKEN'

headers = {
    'Authorization': f'Bearer {token}'
}

response = requests.get(url, headers=headers)
print(response.json())
```

### API Key Authentication
```python
import requests

url = 'https://api.example.com/data'
api_key = 'YOUR_API_KEY'

# In headers
headers = {'X-API-Key': api_key}
response = requests.get(url, headers=headers)

# Or in parameters
params = {'api_key': api_key}
response = requests.get(url, params=params)

print(response.json())
```

### OAuth 2.0
```python
import requests

# Get access token
token_url = 'https://oauth.example.com/token'
token_data = {
    'grant_type': 'client_credentials',
    'client_id': 'YOUR_CLIENT_ID',
    'client_secret': 'YOUR_CLIENT_SECRET'
}

token_response = requests.post(token_url, data=token_data)
access_token = token_response.json()['access_token']

# Use access token for API calls
api_url = 'https://api.example.com/data'
headers = {'Authorization': f'Bearer {access_token}'}
response = requests.get(api_url, headers=headers)

print(response.json())
```

## Error Handling

### Basic Error Handling
```python
import requests

try:
    response = requests.get('https://api.example.com/data', timeout=5)
    response.raise_for_status()  # Raises HTTPError for bad status codes
    data = response.json()
    print(data)
except requests.exceptions.HTTPError as http_err:
    print(f"HTTP error occurred: {http_err}")
except requests.exceptions.ConnectionError as conn_err:
    print(f"Connection error occurred: {conn_err}")
except requests.exceptions.Timeout as timeout_err:
    print(f"Timeout error occurred: {timeout_err}")
except requests.exceptions.RequestException as err:
    print(f"An error occurred: {err}")
```

### Check Response Status
```python
import requests

response = requests.get('https://api.example.com/data')

# Check status code
if response.status_code == 200:
    print("Success!")
elif response.status_code == 404:
    print("Not found!")
elif response.status_code == 500:
    print("Server error!")

# Or use built-in check
if response.ok:  # True for status codes < 400
    print("Request successful!")
    
# Raise exception for error status codes
response.raise_for_status()
```

## Working with Response Data

### JSON Response
```python
import requests

response = requests.get('https://api.example.com/users')
data = response.json()

# Access data
for user in data['users']:
    print(f"Name: {user['name']}, Email: {user['email']}")
```

### Text Response
```python
import requests

response = requests.get('https://api.example.com/page')
html_content = response.text
print(html_content)
```

### Binary Response (Images, Files)
```python
import requests

response = requests.get('https://api.example.com/image.png')

# Save binary content
with open('image.png', 'wb') as f:
    f.write(response.content)
```

### Response Headers
```python
import requests

response = requests.get('https://api.example.com/data')

# Access headers
print(response.headers['Content-Type'])
print(response.headers.get('X-RateLimit-Remaining'))

# All headers
for key, value in response.headers.items():
    print(f"{key}: {value}")
```

## Advanced Features

### Session Objects (Reuse Connection)
```python
import requests

# Create session
session = requests.Session()

# Set headers for all requests in this session
session.headers.update({'Authorization': 'Bearer TOKEN'})

# Make multiple requests
response1 = session.get('https://api.example.com/users')
response2 = session.get('https://api.example.com/posts')

# Session automatically handles cookies
response3 = session.post('https://api.example.com/login', data={'user': 'admin'})
response4 = session.get('https://api.example.com/dashboard')  # Cookie from login is sent

session.close()
```

### Timeouts
```python
import requests

# Single timeout value (applies to both connect and read)
response = requests.get('https://api.example.com/data', timeout=5)

# Separate connect and read timeouts
response = requests.get('https://api.example.com/data', timeout=(3, 10))

# No timeout (not recommended)
response = requests.get('https://api.example.com/data', timeout=None)
```

### Retries
```python
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

# Configure retry strategy
retry_strategy = Retry(
    total=3,
    backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "OPTIONS", "POST"]
)

adapter = HTTPAdapter(max_retries=retry_strategy)
session = requests.Session()
session.mount("http://", adapter)
session.mount("https://", adapter)

response = session.get('https://api.example.com/data')
print(response.json())
```

### File Upload
```python
import requests

url = 'https://api.example.com/upload'

# Upload single file
files = {'file': open('document.pdf', 'rb')}
response = requests.post(url, files=files)

# Upload with additional data
files = {'file': open('document.pdf', 'rb')}
data = {'description': 'My document', 'category': 'reports'}
response = requests.post(url, files=files, data=data)

# Upload multiple files
files = [
    ('files', open('file1.txt', 'rb')),
    ('files', open('file2.txt', 'rb'))
]
response = requests.post(url, files=files)

print(response.json())
```

### Streaming Large Responses
```python
import requests

url = 'https://api.example.com/large-file'
response = requests.get(url, stream=True)

# Save large file in chunks
with open('large_file.bin', 'wb') as f:
    for chunk in response.iter_content(chunk_size=8192):
        if chunk:
            f.write(chunk)
```

### Custom Query Encoding
```python
import requests
from urllib.parse import urlencode

params = {
    'filter': 'name:John',
    'tags': ['python', 'api']
}

# Custom encoding
query_string = urlencode(params, doseq=True)
url = f'https://api.example.com/search?{query_string}'

response = requests.get(url)
print(response.json())
```

## Using `urllib` (Standard Library)

For simple cases without external dependencies:

```python
import urllib.request
import json

# Simple GET request
url = 'https://api.example.com/data'
response = urllib.request.urlopen(url)
data = json.loads(response.read().decode())
print(data)

# POST request with JSON
import urllib.request
import json

url = 'https://api.example.com/users'
data = {'name': 'John', 'email': 'john@example.com'}
json_data = json.dumps(data).encode()

req = urllib.request.Request(url, data=json_data, headers={'Content-Type': 'application/json'})
response = urllib.request.urlopen(req)
print(response.read().decode())
```

## Using `httpx` (Modern Alternative)

`httpx` is a modern, async-capable HTTP client:

```python
import httpx

# Installation: pip install httpx

# Synchronous request
response = httpx.get('https://api.example.com/data')
print(response.json())

# Async request
import asyncio
import httpx

async def fetch_data():
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.example.com/data')
        return response.json()

data = asyncio.run(fetch_data())
print(data)
```

## Complete Example: RESTful API Client

```python
import requests
from typing import Dict, List, Optional

class APIClient:
    def __init__(self, base_url: str, api_key: str = None):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'Authorization': f'Bearer {api_key}'})
        
        self.session.headers.update({'Content-Type': 'application/json'})
    
    def get(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Make GET request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.get(url, params=params)
        response.raise_for_status()
        return response.json()
    
    def post(self, endpoint: str, data: Dict) -> Dict:
        """Make POST request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.post(url, json=data)
        response.raise_for_status()
        return response.json()
    
    def put(self, endpoint: str, data: Dict) -> Dict:
        """Make PUT request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.put(url, json=data)
        response.raise_for_status()
        return response.json()
    
    def delete(self, endpoint: str) -> bool:
        """Make DELETE request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.delete(url)
        response.raise_for_status()
        return response.status_code == 204 or response.status_code == 200
    
    def close(self):
        """Close session"""
        self.session.close()

# Usage
if __name__ == "__main__":
    client = APIClient('https://api.example.com', api_key='YOUR_API_KEY')
    
    try:
        # Get users
        users = client.get('/users', params={'page': 1, 'limit': 10})
        print(f"Users: {users}")
        
        # Create user
        new_user = client.post('/users', data={'name': 'John', 'email': 'john@example.com'})
        print(f"Created: {new_user}")
        
        # Update user
        updated = client.put(f'/users/{new_user["id"]}', data={'name': 'Jane'})
        print(f"Updated: {updated}")
        
        # Delete user
        deleted = client.delete(f'/users/{new_user["id"]}')
        print(f"Deleted: {deleted}")
        
    finally:
        client.close()
```

## Common API Examples

### GitHub API
```python
import requests

# Get user info
username = 'octocat'
response = requests.get(f'https://api.github.com/users/{username}')
user_data = response.json()
print(f"Name: {user_data['name']}")
print(f"Repos: {user_data['public_repos']}")

# Get repositories
response = requests.get(f'https://api.github.com/users/{username}/repos')
repos = response.json()
for repo in repos[:5]:
    print(f"- {repo['name']}: {repo['description']}")
```

### JSONPlaceholder (Test API)
```python
import requests

base_url = 'https://jsonplaceholder.typicode.com'

# Get posts
posts = requests.get(f'{base_url}/posts').json()
print(f"Total posts: {len(posts)}")

# Get single post
post = requests.get(f'{base_url}/posts/1').json()
print(f"Title: {post['title']}")

# Create post
new_post = {
    'title': 'My Post',
    'body': 'This is my post content',
    'userId': 1
}
response = requests.post(f'{base_url}/posts', json=new_post)
print(f"Created post ID: {response.json()['id']}")
```

## Best Practices

1. **Always use timeouts** to prevent hanging requests
2. **Handle errors gracefully** with try-except blocks
3. **Use sessions** for multiple requests to the same host
4. **Close sessions** when done to free resources
5. **Store API keys in environment variables**, never in code
6. **Respect rate limits** and implement backoff strategies
7. **Validate responses** before using the data
8. **Use HTTPS** for secure communication
9. **Log requests and responses** for debugging
10. **Consider async requests** for multiple concurrent API calls
