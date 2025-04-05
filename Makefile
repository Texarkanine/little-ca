# Include user configuration if it exists
-include config.mk

CANAME ?= little
CADIR ?= _certificate-authority
SITEDIR ?= sites

# Generate config.mk from template if it doesn't exist
config.mk: | config.mk.template
	@echo "Generating config.mk from template..."
	@cp config.mk.template config.mk
	@echo "Created config.mk with default values. Edit this file to customize your settings."

.PHONY: ca
ca: 
	$(MAKE) $(CADIR)/$(CANAME)CA.key $(CADIR)/$(CANAME)CA.pem

# Detect if we're in a submake
ifeq ($(MAKELEVEL),0)
.PRECIOUS: $(SITEDIR)/%.key $(SITEDIR)/$(CANAME)-%.csr $(SITEDIR)/%.ext
else
# In submake, extract the domain from the target and set .PRECIOUS for specific files
TARGET := $(firstword $(MAKECMDGOALS))
DOMAIN := $(subst $(CANAME)-,,$(basename $(notdir $(TARGET))))
.PRECIOUS: $(SITEDIR)/$(DOMAIN).key $(SITEDIR)/$(CANAME)-$(DOMAIN).csr $(SITEDIR)/$(DOMAIN).ext
endif

$(CADIR):
	mkdir -p "$(CADIR)"

$(SITEDIR):
	mkdir -p "$(SITEDIR)"

$(CADIR)/%CA.key: | $(CADIR)
	openssl genrsa -des3 -out "$@" 2048

$(CADIR)/%CA.pem: $(CADIR)/%CA.key
	openssl req -x509 -new -nodes -key "$<" -sha256 -days 1825 -out "$@"

$(SITEDIR)/$(CANAME)-%.crt: $(SITEDIR)/$(CANAME)-%.csr $(SITEDIR)/%.ext | $(CADIR)/$(CANAME)CA.pem $(CADIR)/$(CANAME)CA.key
	openssl x509 -req -days 825 -sha256 -CAcreateserial \
		-CA "$(CADIR)/$(CANAME)CA.pem" \
		-CAkey "$(CADIR)/$(CANAME)CA.key" \
		-in "$(SITEDIR)/$(CANAME)-$*.csr" \
		-extfile "$(SITEDIR)/$*.ext" \
		-out "$@"

$(SITEDIR)/$(CANAME)-%.csr: $(SITEDIR)/%.key
	openssl req -new -key "$(SITEDIR)/$*.key" -out "$(SITEDIR)/$(CANAME)-$*.csr"

$(SITEDIR)/%.ext: | $(SITEDIR)
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext.tmp" \
	&& mv "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" \
	|| (rm -f "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" && false)

$(SITEDIR)/%.key: | $(SITEDIR)
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048

# User-friendly target that accepts any domain name
.PHONY: %
%:
	$(MAKE) $(SITEDIR)/$(CANAME)-$@.crt

# Debug target to print out what targets are marked as .PRECIOUS
.PHONY: debug-precious
debug-precious:
	@echo "MAKELEVEL: $(MAKELEVEL)"
	@echo "MAKECMDGOALS: $(MAKECMDGOALS)"
	@if [ "$(MAKELEVEL)" = "0" ]; then \
		echo "In main Make, .PRECIOUS targets:"; \
		echo "  $(SITEDIR)/%.key"; \
		echo "  $(SITEDIR)/$(CANAME)-%.csr"; \
		echo "  $(SITEDIR)/%.ext"; \
	else \
		echo "In submake, .PRECIOUS targets:"; \
		echo "  $(SITEDIR)/$(DOMAIN).key"; \
		echo "  $(SITEDIR)/$(CANAME)-$(DOMAIN).csr"; \
		echo "  $(SITEDIR)/$(DOMAIN).ext"; \
	fi
