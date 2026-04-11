NOTES_DIR ?= notes
DIST_DIR ?= dist

TEMPLATE_DIR := templates
TYP_TEMPLATE := $(TEMPLATE_DIR)/typst.html
INDEX_TEMPLATE := $(TEMPLATE_DIR)/index.html

GEN_TYP := gen_typ
GEN_INDEX := gen_index

.PHONY: all typst index clean

TYP_SRCS := $(shell find $(NOTES_DIR)/ -name "*.typ")
TYP_DIRS := $(sort $(dir $(TYP_SRCS)))
TYP_TARGETS := $(patsubst $(NOTES_DIR)/%.typ, $(DIST_DIR)/%.html, $(TYP_SRCS))
TYP_PDF_TARGETS := $(patsubst $(NOTES_DIR)/%.typ, $(DIST_DIR)/%.pdf, $(TYP_SRCS))
TYP_TARGET_DIRS := $(sort $(dir $(TYP_TARGETS)))

TARGET_DIRS := $(TYP_TARGET_DIRS)
TARGET_DIRS_REC := $(sort $(shell \
	for d in $(TARGET_DIRS); do \
		while [ "$$d" != "." ] && [ -n "$$d" ]; do \
			echo $$d; \
			d=$$(dirname $$d); \
		done; \
	done))
TARGET_DIRS_REC := $(patsubst %/,%,$(TARGET_DIRS_REC))

INDEX_TARGETS := $(addsuffix /index.html, $(TARGET_DIRS_REC))

all: typst index

define define_mkdir_target
$(1):
	@mkdir -p $(1)
endef
$(foreach dir,$(TYP_TARGET_DIRS),$(eval $(call define_mkdir_target,$(dir))))

typst: $(TYP_TARGETS)

$(TYP_TARGETS): $(DIST_DIR)/%.html: $(NOTES_DIR)/%.typ $(TYP_TEMPLATE) $(GEN_TYP) | $(TYP_TARGET_DIRS) $(DIST_DIR)/%.pdf
	./$(GEN_TYP) $@

$(TYP_PDF_TARGETS): $(DIST_DIR)/%.pdf: $(NOTES_DIR)/%.typ $(dir $<)
	typst compile $< $@

index: $(INDEX_TARGETS)

$(INDEX_TARGETS): $(DIST_DIR)/%index.html: $(NOTES_DIR)/% $(INDEX_TEMPLATE) $(GEN_INDEX)
	./$(GEN_INDEX) $@

clean:
	rm -rf $(DIST_DIR)
