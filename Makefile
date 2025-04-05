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

# Mark files as precious to prevent Make from deleting them
.PRECIOUS: $(SITEDIR)/%.key $(SITEDIR)/$(CANAME)-%.csr $(SITEDIR)/%.ext

# Prevent Make from treating .ext.tmp as an intermediate file
.INTERMEDIATE: $(SITEDIR)/%.ext.tmp

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

$(SITEDIR)/%.ext: template.ext | $(SITEDIR)
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext.tmp" \
	&& mv "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" \
	|| (rm -f "$(SITEDIR)/$*.ext.tmp" "$(SITEDIR)/$*.ext" && false)

$(SITEDIR)/%.key: | $(SITEDIR)
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048

# User-friendly target that accepts any domain name
.PHONY: %
%:
	$(MAKE) $(SITEDIR)/$(CANAME)-$@.crt
