include ../build/makelib/common.mk

ifeq ($(CI),true)
PUBLISH_REPO := https://github.com/presslabs/dashboard-config-connector.git
else
PUBLISH_REPO := git@github.com:presslabs/dashboard-config-connector.git
endif

# Default is to squash. For docs, we want to preserve commit history.
GIT_SUBTREE_MERGE_ARGS :=

include ../build/makelib/git-publish.mk
