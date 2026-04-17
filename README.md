# srtla-irl-relay-server
SRTLA Relay Server to be used with BELABOX
--
based on https://github.com/alexandre-leites/srt-live-server
just changed the SLS, SRTLA



docker build -t srtla-irl-relay .

docker run -d   --name srtla-irl-relay   -p 4001:4001/udp -p 5000:5000/udp   -p 5002:5002/udp   -p 30000:30000/udp   -p 8181:8181/tcp   srtla-irl-relay


