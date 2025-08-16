import requests

# tests.py: testCreateMatch
# change database to Completed for both
# update the match_id here
url = "http://127.0.0.1:8000/complete-match"

payload = {
    "match_id": "dgzNDodXYMiyRlXva5Ak",
    "user_id": "gRuNKIYfoOfwQfnl8N6Okq0o6b13",
    "address": "1600 Amphitheatre Parkway, Mountain View, CA"
}

response = requests.post(url, json=payload)

print("Status Code:", response.status_code)
print("Response:", response.text)