## Layer8 Docker Compose

- If you run this the first time, use this command to set up .env files and create test records:
Run:
```
chmod +x run.sh
./run.sh init
```

If it takes longer than 30s to start the docker and you failed to upload certificate, wait until all the services started and run `./run.sh upload` to upload certificate for the test user.

- Start docker:
```
docker compose up -d
```

or 

```
./run.sh start
```
