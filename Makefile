.PHONY: init start stop upload clean

copy_env:
	cp auth-server/.env.dev auth-server/.env
	cp forward-proxy/.env.dev forward-proxy/.env
	cp reverse-proxy/.env.dev reverse-proxy/.env
	mkdir -p logs
	touch logs/forward-proxy.log
	touch logs/reverse-proxy.log

upload_cert:
	@TOKEN=$$(curl --silent --location 'http://localhost:5001/api/v1/login-client' \
		--header 'Content-Type: application/json' \
		--data '{ "password": "12341234", "username": "layer8" }' | jq -r '.token'); \
	echo "Token is: $$TOKEN"; \
	RP_CERT=$$(awk '{printf "%s\\n", $$0}' "./reverse-proxy/ntor_cert.pem"); \
	echo "File content: $$RP_CERT"; \
	curl --location 'http://localhost:5001/api/upload-certificate' \
		--header 'Content-Type: application/json' \
		--header "Authorization: Bearer $$TOKEN" \
		--data "{ \"certificate\": \"$$RP_CERT\" }"

init: copy_env
	sleep 1
	docker compose up -d
	sleep 30
	$(MAKE) upload

start:
	docker compose up -d

stop:
	docker compose down

upload: upload_cert

clean:
	docker compose down
	rm -f auth-server/.env
	rm -f forward-proxy/.env
	rm -f reverse-proxy/.env
	rm -rf auth-server/influxdb2-data
	rm -rf auth-server/pg-data
	rm -f logs/forward-proxy.log
	rm -f logs/reverse-proxy.log
