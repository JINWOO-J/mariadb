REPO = dr.ytlabs.co.kr
REPO_HUB = jinwoo
NAME = mariadb
VERSION = 10.4
#VERSION = 10.5.5
TAGNAME = $(VERSION)
TAGS = "$(shell git tag)"
get_last_container := $(shell docker ps -l | grep -v CONTAINER  | awk '{print $$1}')
commit_docker = $(shell docker commit $$1 | cut -d ":" -f 2)
# include ENVAR

.PHONY: all build push test tag_latest release ssh bash changeconfig

all: build

changeconfig:
	    @CONTAINER_ID=$(shell docker run -d $(REPO_HUB)/$(NAME):$(TAGNAME)) ;\
    	 echo "COPY TO [$$CONTAINER_ID]" ;\
	     docker cp "files/." "$$CONTAINER_ID":/ ;\
	     docker exec -it "$$CONTAINER_ID" sh -c "echo `date +%Y-%m-%d:%H:%M:%S` > /.made_day" ;\
	     echo "COMMIT [$$CONTAINER_ID]" ;\
	     docker commit -m "Change config `date`" "$$CONTAINER_ID" $(REPO_HUB)/$(NAME):$(TAGNAME) ;\
	     echo "STOP [$$CONTAINER_ID]" ;\
	     docker stop "$$CONTAINER_ID" ;\
	     echo "CLEAN UP [$$CONTAINER_ID]" ;\
	     docker rm "$$CONTAINER_ID"

build:
	docker build --no-cache --rm=true --build-arg VERSION=$(VERSION) -t $(REPO_HUB)/$(NAME):$(TAGNAME) .

prod:
	docker tag $(REPO_HUB)/$(NAME):$(TAGNAME)  $(REPO_HUB)/$(NAME):$(VERSION)
	docker push $(REPO_HUB)/$(NAME):$(VERSION)

push:
	docker push $(REPO)/$(NAME):$(TAGNAME)

push_hub:
	docker push $(REPO_HUB)/$(NAME):$(TAGNAME)

build_hub:
	echo "TRIGGER_KEY" ${TRIGGERKEY}
	git add .
	git commit -m "$(NAME):$(VERSION) by Makefile"

	echo $(TAGS)
	git tag -d $(VERSION)
	git push origin :tags/$(VERSION)

	git tag -a "$(VERSION)" -m "$(VERSION) by Makefile"
	git push origin --tags

	curl -H "Content-Type: application/json" --data '{"source_type": "Tag", "source_name": "$(VERSION)"}' -X POST https://registry.hub.docker.com/u/jinwoo/${NAME}/trigger/${TRIGGERKEY}/

tag_hub:
	curl -H "Content-Type: application/json" --data '{"source_type": "Tag", "source_name": "$(VERSION)"}' -X POST https://registry.hub.docker.com/u/jinwoo/${NAME}/trigger/${TRIGGERKEY}/

bash:
	docker run -v $(PWD)/data:/var/lib/mysql -v $(PWD)/files/run.sh:/usr/local/bin/run --entrypoint="bash" --rm -it $(REPO_HUB)/$(NAME):$(VERSION)

tag_latest:
	docker tag -f $(REPO)/$(NAME):$(VERSION) $(REPO)/$(NAME):latest
	docker push $(REPO)/$(NAME):latest

test:
	docker run --rm -it $(REPO_HUB)/$(NAME):$(TAGNAME) bash


debug:
	@CONTAINER_ID=$(call get_last_container) ;\
	echo $$CONTAINER_ID ;\
	COMMIT_ID=`docker commit $$CONTAINER_ID | cut -d ":" -f 2 ` ;\
	docker run -it --rm $$COMMIT_ID bash
	docker rmi -f $$COMMIT_ID



init:
	git init
	git add .
	git commit -m "first commit"
	git remote add origin git@github.com:JINWOO-J/$(NAME).git
	git push -u origin master
