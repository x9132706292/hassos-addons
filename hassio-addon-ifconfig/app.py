from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    data = {
        'ip_addr': request.headers.get('X-Forwarded-For', request.remote_addr),
        'user_agent': request.headers.get('User-Agent'),
        'language': request.headers.get('Accept-Language'),
        'referer': request.headers.get('Referer'),
        'method': request.method,
        'encoding': request.headers.get('Accept-Encoding'),
        'mime': request.headers.get('Accept'),
        'x_forwarded_for': request.headers.get('X-Forwarded-For')
    }
    return jsonify(data)

@app.route('/ip')
def ip():
    return request.headers.get('X-Forwarded-For', request.remote_addr)

@app.route('/ua')
def ua():
    return request.headers.get('User-Agent', '')

@app.route('/lang')
def lang():
    return request.headers.get('Accept-Language', '')

@app.route('/referer')
def referer():
    return request.headers.get('Referer', '')

@app.route('/method')
def method():
    return request.method

@app.route('/encoding')
def encoding():
    return request.headers.get('Accept-Encoding', '')

@app.route('/mime')
def mime():
    return request.headers.get('Accept', '')

@app.route('/forwarded')
def forwarded():
    return request.headers.get('X-Forwarded-For', '')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
