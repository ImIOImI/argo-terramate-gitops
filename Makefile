SHELL=/bin/zsh
PRE_COMMIT_DIR=.git-template
MAKEFILE_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

KNOWN_TARGETS := init \
	init-upgrade \
	plan \
	fmt \
	pre-commit-setup \
	pre-commit-test \
	gen-lock \

.PHONY: $(KNOWN_TARGETS)

ARGS := $(filter-out $(KNOWN_TARGETS), $(MAKECMDGOALS))

init:
	terramate script run \
		--tags "${ARGS}" \
		--parallel 1 \
		--continue-on-error \
		--disable-safeguards=git \
		--include-output-dependencies \
		-- \
		init

init-upgrade:
	terramate script run \
		--tags "${ARGS}" \
		--parallel 1 \
		--continue-on-error \
		--disable-safeguards=git \
		--include-output-dependencies \
		-- \
		init upgrade

plan:
	terramate script run \
		--tags "${ARGS}" \
		--parallel 1 \
		--continue-on-error \
		--disable-safeguards=git \
		--include-output-dependencies \
		-- \
		plan

gen-lock:
	terramate script run \
		--tags "${ARGS}" \
		--parallel 1 \
		--continue-on-error \
		--include-output-dependencies \
		-- \
		providers lock

fmt:
	terramate fmt
	tofu fmt --recursive

pre-commit-setup:
	# https://github.com/tofuutils/pre-commit-opentofu
	brew install pre-commit
	git config init.templateDir ${MAKEFILE_PATH}${PRE_COMMIT_DIR}
	pre-commit init-templatedir -t pre-commit ${MAKEFILE_PATH}${PRE_COMMIT_DIR}
	pre-commit install

pre-commit-test:
	pre-commit run -a

# Catch-all target to prevent errors when extra words are passed.
%:
	@:
