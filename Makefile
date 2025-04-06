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
	@echo "MAKELEVEL: $(MAKELEVEL)"
	$(MAKE) $(CADIR)/$(CANAME)CA.key $(CADIR)/$(CANAME)CA.pem

TARGET := $(firstword $(MAKECMDGOALS))
DOMAIN := $(subst $(CANAME)-,,$(basename $(notdir $(TARGET))))
.PRECIOUS: $(SITEDIR)/$(DOMAIN).key $(SITEDIR)/$(CANAME)-$(DOMAIN).csr $(SITEDIR)/$(DOMAIN).ext

$(CADIR):
	@echo "MAKELEVEL: $(MAKELEVEL)"
	mkdir -p "$(CADIR)"

$(SITEDIR):
	@echo "MAKELEVEL: $(MAKELEVEL)"
	mkdir -p "$(SITEDIR)"

$(CADIR)/%CA.key: | $(CADIR)
	@echo "MAKELEVEL: $(MAKELEVEL)"
	openssl genrsa -des3 -out "$@" 2048

$(CADIR)/%CA.pem: $(CADIR)/%CA.key
	@echo "MAKELEVEL: $(MAKELEVEL)"
	openssl req -x509 -new -nodes -key "$<" -sha256 -days 1825 -out "$@"

$(SITEDIR)/$(CANAME)-%.crt: $(SITEDIR)/$(CANAME)-%.csr $(SITEDIR)/%.ext | $(CADIR)/$(CANAME)CA.pem $(CADIR)/$(CANAME)CA.key
	@echo "MAKELEVEL: $(MAKELEVEL)"
	openssl x509 -req -days 825 -sha256 -CAcreateserial \
		-CA "$(CADIR)/$(CANAME)CA.pem" \
		-CAkey "$(CADIR)/$(CANAME)CA.key" \
		-in "$(SITEDIR)/$(CANAME)-$*.csr" \
		-extfile "$(SITEDIR)/$*.ext" \
		-out "$@"

$(SITEDIR)/$(CANAME)-%.csr: $(SITEDIR)/%.key
	@echo "MAKELEVEL: $(MAKELEVEL)"
	openssl req -new -key "$(SITEDIR)/$*.key" -out "$(SITEDIR)/$(CANAME)-$*.csr"

$(SITEDIR)/%.ext: | $(SITEDIR)
	@echo "MAKELEVEL: $(MAKELEVEL)"
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext.tmp" \
	&& mv "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" \
	|| (rm -f "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" && false)

$(SITEDIR)/%.key: | $(SITEDIR)
	@echo "MAKELEVEL: $(MAKELEVEL)"
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048

# User-friendly target that accepts any domain name
.PHONY: %
%:
	@if [ "$(MAKELEVEL)" = "0" ]; then \
		$(MAKE) $(SITEDIR)/$(CANAME)-$@.crt; \
	fi
