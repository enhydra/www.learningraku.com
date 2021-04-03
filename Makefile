PERL=perl

DOCS=docs
STATIC=_static

LOCAL_SITE=http://127.0.0.1:3000/index.html

.PHONY: build
build: clear static cook $(DOCS)/index.html ## build the entire website

.PHONY: clear
clear: ## remove all the previous files
	rm -rf $(DOCS)/*

.PHONY: cname
cname: ## show the cname for this site
	@ cat $(STATIC)/CNAME

.PHONY: cook
cook: ## process the templates
	$(PERL) bin/cook
	cp -r $(STATIC)/* $(DOCS)/.

$(DOCS)/index.html: ## make the main index.html
	$(PERL) bin/single_page index.html index.html

.PHONY: localserver
localserver: ## run a Mojo server to see the local files
	$(PERL) bin/static daemon

.PHONY: open
open: localserver
	open -a Safari $(LOCAL_SITE)

.PHONY: publish
publish: cook
	git add docs/.
	git commit -m 'Re-generate site' docs
	git push all master

.PHONY: static
static: ## move the static files into place
	cp -r $(STATIC)/* $(DOCS)/.


######################################################################
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help ## Show all the Makefile targets with descriptions
help: ## show a list of targets
	@grep -E '^[a-zA-Z][/a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
