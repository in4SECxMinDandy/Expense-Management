import requests

url = "https://api.orbit-provider.com/cliproxy-api/api/provider/agy/models"
headers = {
    "Authorization": "Bearer sk-orbit-18ee4a7382a685d91adab1b32f0c27c0"
}

try:
    response = requests.get(url, headers=headers)
    print("Danh sách các model bạn được phép dùng:")
    print(response.json())
except Exception as e:
    print(f"Lỗi: {e}")