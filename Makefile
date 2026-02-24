COMPOSE ?= docker compose

# Default Ruby versions can include newer Rubies locally; override to match CI exactly:
#   make test-matrix RUBIES="3.3"
# Or opt-in to Ruby 4.0 explicitly:
#   make test-matrix RUBIES="4.0 3.4 3.3 3.2"
RUBIES ?= 4.0 3.4 3.3 3.2
DBS ?= sqlite3 mysql57 mysql80 postgres
AR_VERSIONS ?= 7.2 8.0 8.1
SEQUEL_VERSION ?= 5

.DEFAULT_GOAL := help

.PHONY: help
## Following commands are available
help: ## Show this help
	@awk -v FS=':.*?## ' ' /^##/{print $0} /^[a-zA-Z_-]+:.*?## /{printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Infrastructure
compose-up: ## Start required services
	$(COMPOSE) up -d mysql57 mysql80 postgres

compose-down: ## Stop required services
	$(COMPOSE) down --remove-orphans

wait-db: ## Wait for required services to be ready
	$(COMPOSE) run --rm --entrypoint "sh -c 'echo mysql57 ready'" mysql57 >/dev/null
	$(COMPOSE) run --rm --entrypoint "sh -c 'echo mysql80 ready'" mysql80 >/dev/null
	$(COMPOSE) run --rm --entrypoint "sh -c 'echo postgres ready'" postgres >/dev/null

## Development
bash: ## Run bash in a service container, e.g. make bash SERVICE="ruby-3.2"
	$(COMPOSE) run --rm $(SERVICE) bash

test: ## Run tests in a service container, e.g. make test SERVICE="ruby-3.2" DB="mysql57" ORM="active_record" ORM_VERSION="7.2" FEATURE="unit"
	$(COMPOSE) run -e DB=$(DB) -e ORM=$(ORM) -e ORM_VERSION=$(ORM_VERSION) -e FEATURE=$(FEATURE) --rm $(SERVICE) bash -lc '\
bundle install && \
if [ "$$DB" != "" ]; then \
  cleanup() { bundle exec rake db:drop; }; \
  trap cleanup EXIT; \
  bundle exec rake db:drop db:create db:up; \
fi && \
bundle exec rake \
'

test-matrix: ## Run test matrix like in CI
	@set -e; \
	$(MAKE) -s compose-up >/dev/null; \
	for ruby in $(RUBIES); do \
	  service="ruby-$$ruby"; \
	  for db in $(DBS); do \
	    for ar_version in $(AR_VERSIONS); do \
	      if [ "$$ruby" = "3.2" ] && [ "$$ar_version" = "8.1" ]; then continue; fi; \
	      $(MAKE) test SERVICE="$$service" DB="$$db" ORM=active_record ORM_VERSION="$$ar_version" FEATURE=unit; \
	    done; \
	    $(MAKE) test SERVICE="$$service" DB="$$db" ORM=sequel ORM_VERSION="$(SEQUEL_VERSION)" FEATURE=unit; \
	  done; \
	  $(MAKE) test SERVICE="$$service" DB=sqlite3 ORM=active_record ORM_VERSION=7.2 FEATURE=rails; \
	  $(MAKE) test SERVICE="$$service" DB= ORM= ORM_VERSION= FEATURE=i18n_fallbacks; \
	  $(MAKE) test SERVICE="$$service" DB= ORM= ORM_VERSION= FEATURE=performance; \
	  $(MAKE) test SERVICE="$$service" DB= ORM= ORM_VERSION= FEATURE=unit; \
	done
