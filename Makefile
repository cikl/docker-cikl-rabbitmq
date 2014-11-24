NAME = cikl/rabbitmq
VERSION = 0.0.3

.PHONY: all build tag_latest

all: build

build:
	docker build -t $(NAME):$(VERSION) --rm .

check_git:
	@status=$$(git status --porcelain); \
        if test "x$${status}" != x; then \
            echo Working directory is dirty >&2; \
	    false; \
        fi
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
        if test "$${branch}" != master; then \
            echo Must be in 'master' branch! >&2; \
	    false; \
        fi

git_tag: check_git
	@git describe --tags $(VERSION) >/dev/null 2>&1 || git tag $(VERSION)
	@git diff --quiet refs/heads/master..refs/tags/$(VERSION) || ( echo "refs/tags/$(VERSION) does not match refs/heads/master."; false) 

push_to_git: git_tag
	git push upstream master refs/tags/$(VERSION)

push_to_docker: check_git build
	docker push $(NAME):$(VERSION)

release: push_to_git push_to_docker
