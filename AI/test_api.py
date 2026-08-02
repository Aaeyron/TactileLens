import requests

url = "http://127.0.0.1:5001/recognize"

with open("Test2.png", "rb") as img:
    response = requests.post(
        url,
        files={"image": img},
    )

print("Status Code:", response.status_code)
print("Response:")
print(response.text)