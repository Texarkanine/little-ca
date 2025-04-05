CANAME ?= little
CADIR ?= ./_certificate-authority
SITEDIR ?= default

.PHONY: ca
ca: 
	$(MAKE) $(CADIR)/$(CANAME)CA.key $(CADIR)/$(CANAME)CA.pem

# Mark files as precious to prevent Make from deleting them
.PRECIOUS: $(SITEDIR)/%.key $(SITEDIR)/%.csr $(SITEDIR)/%.ext

$(CADIR):
	mkdir -p "$(CADIR)"

$(SITEDIR):
	mkdir -p "$(SITEDIR)"

$(CADIR)/%CA.key: | $(CADIR)
	openssl genrsa -des3 -out "$@" 2048

$(CADIR)/%CA.pem: $(CADIR)/%CA.key
	openssl req -x509 -new -nodes -key "$<" -sha256 -days 1825 -out "$@"

$(SITEDIR)/$(CANAME)-%.crt: $(CADIR)/$(CANAME)CA.pem $(SITEDIR)/$(CANAME)-%.csr $(SITEDIR)/%.ext
	openssl x509 -req -days 825 -sha256 -CAcreateserial \
		-CA "$(CADIR)/$(CANAME)CA.pem" \
		-CAkey "$(CADIR)/$(CANAME)CA.key" \
		-in "$(SITEDIR)/$(CANAME)-$*.csr" \
		-extfile "$(SITEDIR)/$*.ext" \
		-out "$@"

$(SITEDIR)/$(CANAME)-%.csr: $(SITEDIR)/%.key
	openssl req -new -key "$(SITEDIR)/$*.key" -out "$(SITEDIR)/$(CANAME)-$*.csr"

$(SITEDIR)/%.ext: | $(SITEDIR)
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext"

$(SITEDIR)/%.key: | $(SITEDIR)
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048
