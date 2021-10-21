PERL=perl

BASE_DIR     = $(shell perl bin/config | jq -r .base_dir)
STATIC_DIR   = $(shell perl bin/config | jq -r .static_dir)
TEMPLATE_DIR = $(shell perl bin/config | jq -r .template_dir)

LOCAL_SITE=http://127.0.0.1:3000/index.html

.PHONY: build
build: | clear cook static $(BASE_DIR)/index.html $(BASE_DIR)/feed/index.xml ## build the entire website

.PHONY: clear
clear: ## remove all the previous files
	rm -rf $(BASE_DIR)/*

.PHONY: cname
$(BASE_DIR)/CNAME: ## show the cname for this site
	@ cat $(STATIC_DIR)/CNAME

.PHONY: cook
cook: ## process the templates
	- rm -rf $(BASE_DIR)
	$(PERL) bin/cook

$(BASE_DIR)/feed/index.xml: $(BASE_DIR)/items.json
	bin/make_feed $(BASE_DIR)/items.json > $@

$(BASE_DIR)/items.json: cook ## create the JSON file

$(BASE_DIR)/index.html: $(BASE_DIR)/items.json $(TEMPLATE_DIR)/index.html ## make the main index.html
	$(PERL) bin/single_page index.html index.html

.PHONY: localserver
localserver: ## run a Mojo server to see the local files
	$(PERL) bin/static daemon

.PHONY: open
open: localserver
	open -a Safari $(LOCAL_SITE)

.PHONY: publish
publish:
	git add docs/.
	git commit -m 'Re-generate site' docs
	git push all master

.PHONY: show_setup
show_setup:
	@ echo "BASE_DIR    " $(BASE_DIR)
	@ echo "STATIC_DIR  " $(STATIC_DIR)
	@ echo "TEMPLATE_DIR" $(TEMPLATE_DIR)

.PHONY: static
static: ## move the static files into place
	mkdir -p $(BASE_DIR)
	rsync -a --exclude-from=_static/.rsync_exclude $(STATIC_DIR)/. $(BASE_DIR)

######################################################################
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help ## Show all the Makefile targets with descriptions
help: ## show a list of targets
	@grep -E '^[a-zA-Z][/a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
