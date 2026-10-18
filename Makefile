NOTES_DIR ?= notes
DIST_DIR ?= dist

NOTES_DIR := $(patsubst %/,%,$(NOTES_DIR))
DIST_DIR := $(patsubst %/,%,$(DIST_DIR))

TEMPLATE_DIR := templates
TYP_TEMPLATE := $(TEMPLATE_DIR)/typst.html
INDEX_TEMPLATE := $(TEMPLATE_DIR)/index.html

GEN_TYP := gen_typ
GEN_INDEX := gen_index
shell_quote = '$(subst ','"'"',$(1))'

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.PHONY: all typst index icon clean test FORCE

ENTRY_FILE := $(NOTES_DIR)/n2web.entries
TYP_DEFAULT_SRCS := $(shell find "$(NOTES_DIR)/" -type f \( -name main.typ -o -name index.typ \))
TYP_EXTRA_PATHS := $(shell if [ -f "$(ENTRY_FILE)" ]; then sed 's/\#.*//; /^[[:space:]]*$$/d' "$(ENTRY_FILE)"; fi)

# Additional entries are relative Typst paths within the notes tree.
INVALID_ENTRIES := $(filter-out %.typ,$(TYP_EXTRA_PATHS)) $(filter /%,$(TYP_EXTRA_PATHS)) $(foreach entry,$(TYP_EXTRA_PATHS),$(if $(findstring /../,/$(entry)/),$(entry)))
ifneq ($(strip $(INVALID_ENTRIES)),)
$(error Invalid paths in $(ENTRY_FILE): $(INVALID_ENTRIES))
endif
TYP_EXTRA_SRCS := $(addprefix $(NOTES_DIR)/,$(TYP_EXTRA_PATHS))
MISSING_ENTRIES := $(filter-out $(wildcard $(TYP_EXTRA_SRCS)),$(TYP_EXTRA_SRCS))
ifneq ($(strip $(MISSING_ENTRIES)),)
$(error Missing entries in $(ENTRY_FILE): $(MISSING_ENTRIES))
endif

TYP_SRCS := $(sort $(TYP_DEFAULT_SRCS) $(TYP_EXTRA_SRCS))
TYP_TARGETS := $(patsubst $(NOTES_DIR)/%.typ,$(DIST_DIR)/%.html,$(TYP_SRCS))
TYP_PDF_TARGETS := $(TYP_TARGETS:.html=.pdf)
TYP_TARGET_DIRS := $(sort $(patsubst %/,%,$(dir $(TYP_TARGETS))))

# Stop at the output root, including when DIST_DIR is absolute or nested.
TARGET_DIRS := $(sort $(DIST_DIR) $(shell \
	for d in $(TYP_TARGET_DIRS); do \
		while [ "$$d" != "$(DIST_DIR)" ]; do \
			echo "$$d"; \
			parent=$$(dirname "$$d"); \
			[ "$$parent" != "$$d" ] || break; \
			d=$$parent; \
		done; \
	done))
# index.typ supplies its own directory landing page.
INDEX_TARGETS := $(filter-out $(TYP_TARGETS),$(addsuffix /index.html,$(TARGET_DIRS)))
STATE_FILE := $(DIST_DIR)/.generation-state

all: typst index icon

typst: $(TYP_TARGETS)

# Reconcile cached output with the selected sources before any generation starts.
# gen_prune preserves the state's timestamp when the selection is unchanged.
$(STATE_FILE): FORCE
	@./gen_prune "$(DIST_DIR)" "$(NOTES_DIR)" $(foreach target,$(TYP_TARGETS) $(TYP_PDF_TARGETS) $(addsuffix .d,$(TYP_PDF_TARGETS)) $(INDEX_TARGETS),$(call shell_quote,$(target)))

$(TYP_TARGETS) $(TYP_PDF_TARGETS) $(INDEX_TARGETS) $(DIST_DIR)/favicon.svg: | $(STATE_FILE)

$(TYP_TARGETS): $(DIST_DIR)/%.html: $(DIST_DIR)/%.pdf $(TYP_TEMPLATE) $(GEN_TYP) utils.ts
	./$(GEN_TYP) "$@" "$(DIST_DIR)"

$(TYP_PDF_TARGETS): $(DIST_DIR)/%.pdf: $(NOTES_DIR)/%.typ Makefile
	@mkdir -p "$(@D)"
	typst compile --root "$(NOTES_DIR)" --deps "$@.d" --deps-format make "$<" "$@"

# Typst records imported files and assets so edits to them rebuild their PDFs.
TYP_DEP_FILES := $(wildcard $(addsuffix .d,$(TYP_PDF_TARGETS)))
-include $(TYP_DEP_FILES)

# Cached dependencies may refer to packages absent on a fresh runner or imports
# that have since been removed. Empty rules let Typst recompile (and download
# packages) instead of make failing before the compiler can run, like gcc -MP.
$(foreach dep,$(TYP_DEP_FILES),$(eval $(shell sed 's/^[^:]*: //' $(call shell_quote,$(dep))):))

index: $(addsuffix /index.html,$(TARGET_DIRS))

# Only return immediate children of a directory.
children = $(foreach entry,$(2),$(if $(filter $(1)/,$(dir $(entry))),$(entry)))

# Source directories detect new entries; output dependencies order parallel builds.
define define_index_target
$(1)/index.html: $(patsubst $(DIST_DIR)%,$(NOTES_DIR)%,$(1))/ $(INDEX_TEMPLATE) $(GEN_INDEX) utils.ts
$(1)/index.html: $(STATE_FILE)
$(1)/index.html: $(filter-out $(1)/index.html,$(call children,$(1),$(TYP_TARGETS)))
$(1)/index.html: $(addsuffix /index.html,$(call children,$(1),$(TARGET_DIRS)))
	@mkdir -p "$(1)"
	./$(GEN_INDEX) "$$@" "$(DIST_DIR)"
endef
$(foreach dir,$(patsubst %/,%,$(dir $(INDEX_TARGETS))),$(eval $(call define_index_target,$(dir))))

icon: $(DIST_DIR)/favicon.svg

$(DIST_DIR)/favicon.svg: favicon.svg
	@mkdir -p "$(@D)"
	cp "$<" "$@"

test:
	bun test

clean:
	rm -rf "$(DIST_DIR)"
