CANAME ?= little
CADIR ?= ./_certificate-authority
SITEDIR ?= default

CAKEY=$(CADIR)/$(CANAME)CA.key
CAPEM=$(CADIR)/$(CANAME)CA.pem

$(CADIR):
	mkdir -p "$(CADIR)"

$(SITEDIR):
	mkdir -p "$(SITEDIR)"

$(CAKEY): $(CADIR)
	openssl genrsa -des3 -out "$(CAKEY)" 2048

$(CAPEM): $(CAKEY)
	openssl req -x509 -new -nodes -key "$(CAKEY)" -sha256 -days 1825 -out "$(CAPEM)"

$(SITEDIR)/%.crt: $(CAKEY) $(CAPEM) $(SITEDIR)/%.csr $(SITEDIR)/%.ext
	openssl x509 -req -days 825 -sha256 -CAcreateserial \
		-CA "$(CAPEM)" \
		-CAkey "$(CAKEY)" \
		-in "$(SITEDIR)/$*.csr" \
		-extfile "$(SITEDIR)/$*.ext" \
		-out "$(SITEDIR)/$*.crt"

$(SITEDIR)/%.csr: $(SITEDIR)/%.key
	openssl req -new -key "$(SITEDIR)/$*.key" -out "$(SITEDIR)/$*.csr"

$(SITEDIR)/%.ext: $(SITEDIR)
	./generate_ext.sh template.ext > "$(SITEDIR)/$*.ext"

$(SITEDIR)/%.key: $(SITEDIR)
	openssl genrsa -out "$(SITEDIR)/$*.key" 2048
