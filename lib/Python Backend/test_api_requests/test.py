import requests

url = "http://127.0.0.1:8000/update-location"


lat, long = 39.1930, -79.302 # wvu
lat, long = 37.86450112232678, -117.96676154962282 # Stanford
lat, long = 40.853701068840266, -73.9461268535079 # Columbia

data = {
    "user_id": "gRuNKIYfoOfwQfnl8N6Okq0o6b13",
    "geolocation": {
        "lat": lat,
        "long": long
    }
}

response = requests.post(url, json=data)

print("Status Code:", response.status_code)
print("Response:", response.text)

