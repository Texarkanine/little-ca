# Include user configuration if it exists
-include config.mk

CANAME ?= littlelan
CADIR ?= authorities
SITEDIR ?= sites

# Generate config.mk from template if it doesn't exist
config.mk: | config.mk.template
	@if [ ! -f config.mk ]; then \
		echo "Generating config.mk from template..."; \
		cp config.mk.template config.mk; \
		echo "Created config.mk with default values. Edit this file to customize your settings."; \
	fi

.PHONY: ca
ca:
	$(MAKE) $(CADIR)/$(CANAME)CA.key $(CADIR)/$(CANAME)CA.pem

# Test the passphrase for a CA key
.PHONY: test-ca-passphrase
test-ca-passphrase:
	@if [ ! -f "$(CADIR)/$(CANAME)CA.key" ]; then \
		echo "CA key not found at $(CADIR)/$(CANAME)CA.key"; \
		exit 1; \
	fi
	@echo "Testing passphrase for $(CADIR)/$(CANAME)CA.key..."
	@openssl rsa -check -noout -in "$(CADIR)/$(CANAME)CA.key" && echo "Passphrase is correct!"

TARGET := $(firstword $(MAKECMDGOALS))
DOMAIN := $(subst $(CANAME)-,,$(basename $(notdir $(TARGET))))
.PRECIOUS: $(SITEDIR)/$(DOMAIN).key $(SITEDIR)/$(CANAME)-$(DOMAIN).csr $(SITEDIR)/$(DOMAIN).ext $(CADIR)/%CA.key $(CADIR)/%CA.pem

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
	@if [ "$(MAKELEVEL)" = "0" ]; then \
		$(MAKE) $(SITEDIR)/$(CANAME)-$@.crt; \
	fi
