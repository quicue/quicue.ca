.PHONY: build serve serve-live demo vet test desktop node cluster enterprise up down clean

build:
	./build.sh

serve:
	python3 serve.py

serve-live:
	python3 serve.py --live

demo: build serve

vet:
	cue vet ./

test:
	./test.sh

desktop:
	cue export ./ -e desktop --out json | python3 -m json.tool

node:
	cue export ./ -e node --out json | python3 -m json.tool

cluster:
	cue export ./ -e cluster --out json | python3 -m json.tool

enterprise:
	cue export ./ -e enterprise --out json | python3 -m json.tool

up:
	docker compose up -d

down:
	docker compose down

clean:
	rm -rf data/ deploy.jsonl
