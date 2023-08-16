import requests
from fake_useragent import UserAgent
from utils import make_json_request
import json

url = "https://citibikenyc.com/bikesharefe-gql"

useragent = UserAgent()

headers = {
    "Host": "citibikenyc.com",
    "Accept": "*/*",
    "Sec-Fetch-Site": "same-origin",
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Fetch-Mode": "cors",
    "Origin": "https://citibikenyc.com",
    "User-Agent": useragent.random,
    "Referer": "https://citibikenyc.com/explore",
    "Connection": "keep-alive",
    "Content-Type": "application/json"
}
data = {
    "operationName": "GetSupply",
    "variables": {
        "input": {
            "regionCode": "BKN",
            "rideablePageLimit": 1000
        }
    },
    "query": """fragment NoticeFields on Notice {
  localizedTitle
  localizedDescription
  url
  __typename
}

query GetSupply($input: SupplyInput) {
  supply(input: $input) {
    stations {
      stationId
      stationName
      location {
        lat
        lng
      }
      bikesAvailable
      bikeDocksAvailable
      ebikesAvailable
      scootersAvailable
      totalBikesAvailable
      totalRideablesAvailable
      isValet
      isOffline
      notices {
        ...NoticeFields
      }
      siteId
      lastUpdatedMs
    }
    notices {
      ...NoticeFields
    }
    requestErrors {
      ...NoticeFields
      __typename
    }
  }
}
"""
}

res = make_json_request(url, headers=headers, json=data)
stations = res["data"]["supply"]["stations"]

empty_stations = []
ebike_only_stations = []

for station in stations:
    
    if station["isOffline"]:
        continue
    
    if station["totalBikesAvailable"] == 0:
        empty_stations.append(station)
    elif station["totalBikesAvailable"] == station["ebikesAvailable"]:
        ebike_only_stations.append(station)
        

print(f"Empty stations: {len(empty_stations)}")
print(f"Ebike only stations: {len(ebike_only_stations)}")

import folium

# Create a base map centered around NYC
m = folium.Map(location=[40.730610, -73.935242], zoom_start=12)  # Coordinates for NYC

# Plot empty stations with red markers
for station in empty_stations:
    lat, lng = station["location"]["lat"], station["location"]["lng"]
    folium.Marker(
        [lat, lng],
        popup=f"Station Name: {station['stationName']}",
        icon=folium.Icon(color='red', icon='info-sign'),
    ).add_to(m)

# Plot ebike only stations with blue markers
for station in ebike_only_stations:
    lat, lng = station["location"]["lat"], station["location"]["lng"]
    folium.Marker(
        [lat, lng],
        popup=f"Station Name: {station['stationName']}",
        icon=folium.Icon(color='blue', icon='info-sign'),
    ).add_to(m)

# Save the map to an HTML file and open in the browser
m.save("stations_map2.html")