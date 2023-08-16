import requests 
import json 
from tenacity import retry, stop_after_attempt, wait_exponential
from config import PROXY 

@retry(stop=stop_after_attempt(4), wait=wait_exponential(multiplier=1, min=4, max=10))
def make_json_request(url, headers=None, json=None, timeout=10):
    try:
        response = requests.post(
            url,
            headers=headers,
            json=json,
            timeout=timeout,
            proxies={"http": PROXY, "https": PROXY},
        )
        response.raise_for_status()
        try:
            response_json = response.json()
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON response: {e}")
        return response_json
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
        raise 
