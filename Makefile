NOTES_DIR ?= notes
DIST_DIR ?= dist

TEMPLATE_DIR := templates
TYP_TEMPLATE := $(TEMPLATE_DIR)/typst.html

GEN_TYP_TEMPLATE := gen_typ_template

.PHONY: all typst clean

TYP_SRCS := $(shell find $(NOTES_DIR)/ -name "*.typ")
TYP_DIRS := $(sort $(dir $(TYP_SRCS)))
TYP_TARGETS := $(patsubst $(NOTES_DIR)/%.typ, $(DIST_DIR)/%.html, $(TYP_SRCS))
TYP_PDF_TARGETS := $(patsubst $(NOTES_DIR)/%.typ, $(DIST_DIR)/%.pdf, $(TYP_SRCS))
TYP_TARGET_DIRS := $(sort $(dir $(TYP_TARGETS)))
DIRS := $(TYP_TARGET_DIRS)

all: typst

define define_mkdir_target
$(1):
	@mkdir -p $(1)
endef
$(foreach dir,$(TYP_TARGET_DIRS),$(eval $(call define_mkdir_target,$(dir))))

typst: $(TYP_TARGETS)

$(TYP_TARGETS): $(DIST_DIR)/%.html: $(NOTES_DIR)/%.typ $(TYP_TEMPLATE) $(GEN_TYP_TEMPLATE) | $(DIST_DIR)/%.pdf $(dir $<)
	./$(GEN_TYP_TEMPLATE) $@

$(TYP_PDF_TARGETS): $(DIST_DIR)/%.pdf: $(NOTES_DIR)/%.typ $(dir $<)
	typst compile $< $@

clean:
	rm -rf $(DIST_DIR)
