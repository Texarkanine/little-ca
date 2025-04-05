CANAME ?= little
CADIR ?= ./_certificate-authority
SITEDIR ?= default

.PHONY: ca
ca: $(CADIR)/$(CANAME)CA.key $(CADIR)/$(CANAME)CA.pem
	@echo "Generated CA files for $(CANAME)"

$(CADIR):
	mkdir -p "$(CADIR)"

$(SITEDIR):
	mkdir -p "$(SITEDIR)"

$(CADIR)/%CA.key: $(CADIR)
	openssl genrsa -des3 -out "$@" 2048

$(CADIR)/%CA.pem: $(CADIR)/%CA.key
	openssl req -x509 -new -nodes -key "$<" -sha256 -days 1825 -out "$@"

$(SITEDIR)/%.crt: $(CADIR)/$(CANAME)CA.pem $(SITEDIR)/%.csr $(SITEDIR)/%.ext
	openssl x509 -req -days 825 -sha256 -CAcreateserial \
		-CA "$(CADIR)/$(CANAME)CA.pem" \
		-CAkey "$(CADIR)/$(CANAME)CA.key" \
		-in "$(SITEDIR)/$*.csr" \
		-extfile "$(SITEDIR)/$*.ext" \
		-out "$(SITEDIR)/$*.crt"

$(SITEDIR)/%.csr: $(SITEDIR)/%.key
	openssl req -new -key "$(SITEDIR)/$*.key" -out "$(SITEDIR)/$*.csr"

$(SITEDIR)/%.ext: $(SITEDIR)
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext"

$(SITEDIR)/%.key: $(SITEDIR)
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048
