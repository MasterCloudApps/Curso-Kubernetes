from flask import Flask, render_template
import random
import socket

app = Flask(__name__)

# list of cat images
images = [
    "https://media.giphy.com/media/mlvseq9yvZhba/giphy.gif",
    "https://media.giphy.com/media/MCfhrrNN1goH6/giphy.gif",
    "https://media.giphy.com/media/8vQSQ3cNXuDGo/giphy.gif",
    "https://media.giphy.com/media/rwCX06Y5XpbLG/giphy.gif",
    "https://media.giphy.com/media/vFKqnCdLPNOKc/giphy.gif",
    "https://media.giphy.com/media/CqVNwrLt9KEDK/giphy.gif",
    "https://media.giphy.com/media/MWSRkVoNaC30A/giphy.gif",
    "https://media.giphy.com/media/TEkr9oBZ57KFmMWScZ/giphy.gif"
]

@app.route('/')
def index():
    url = random.choice(images)
    ip = get_ip();
    return render_template('index.html', url=url, ip=ip)

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

if __name__ == "__main__":
    app.run(host="0.0.0.0")

