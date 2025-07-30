## Layer8 Docker Compose

- If you run this the first time, use this command to set up .env files and create test records:
Run:
```
chmod +x run.sh && ./run.sh init
```
or:
```
make init
```

If it takes longer than 30s to start the docker and you failed to upload certificate, wait until all the services started and run:
`./run.sh upload` or `make upload` to upload certificate for the test user.

- Start docker, try one of these:
```
docker compose up -d
```
```
./run.sh start
```
```
make start
```

- To clean up and start over:
```
make clean
```
