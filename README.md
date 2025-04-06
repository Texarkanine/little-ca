# Little LAN Certificate Authority

A tool for creating your own little Certificate Authority and issuing certificates with it.
Useful for generating certificates for devices on your LAN that either don't have TLDs, don't have public IPs, or some combination of the two.

For example, a [pihole](https://pi-hole.net/).

# Quick Start

1. Create your Certificate Authority:
   ```
   make ca
   ```

   1. You will be asked for a passphrase three times. Be sure you remember it; you'll need this passphrase to issue certificates with your authority!
   2. You'll then be asked to fill out the details of your Certificate Authority; these will be used in your "root certificate."

2. Generate a certificate for a domain:
   ```
   make example.com
   ```

   1. You will be asked for details of the domain; these will be used in its certificate.
   2. You will then be asked for the domain name(s) and IP address(es) that the certificate is valid for.

# Usage

## Configuration

You can customize the behavior of littlelan CA by creating a `config.mk` file. This file allows you to set default values for various options without having to specify them on the command line each time.
This file will be created automatically from [config.mk.template](./config.mk.template) the first time any command is run.

This file allows you to specify *defaults* for your certificate creation processes.

See your `config.mk` or [config.mk.template](./config.mk.template) for available options.

## Issuing Certificates

To issue a certificate for a site, just run

      make my-recipient

Where `my-recipient` will be used in the file name(s) of the generated files. It does not have to be a FQDN, but it's fine if it is; `make my.site.com` works, too.

You will be prompted to enter the details of the private key for that recipient, and then to provide domain names and IP addresses that the certificate should be issued to.

When finished, four files will have been created in the `SITEDIR`:

1. `my-recipient.key`: The private key for this recipient
2. `my-recipient.ext`: The information about the IPs and domain names to issue the certificate to
3. `${CANAME}-my-recipient.csr`: The certificate signing request to `${CANAME}`, from `my-recipient`
4. `${CANAME}-my-recipient.crt`: The certificate issued to `my-recipient`, signed by `${CANAME}`

Give the `.crt` to your recipient; this is the certificate they will present.
Give the `.pem` file for `${CANAME}` to all clients that will attempt to connect to your recipient.

### Regenerating Certificates

If a certificate expires or you otherwise need to reissue it,

1. delete the existing cert
   `rm sites/littlelan-my-recipient.crt`
2. explicitly `make` the cert:
   `make CANAME=littlelan sites/littlelan-my-recipient.crt`

The above will re-use the existing `.key` and `.ext` for `my-recipient`.

## Working with Multiple CAs

### Creating a CA with a Specific Name

You can create a Certificate Authority with a custom name in two ways:

1. Using the configuration file:
   ```makefile
   # In config.mk
   CANAME = myca
   ```
   Then run:
   ```
   make ca
   ```

2. Directly on the command line:
   ```
   make CANAME=myca ca
   ```

This will create CA files with your custom name: `_certificate-authority/mycaCA.key` and `_certificate-authority/mycaCA.pem`.

### Using a Specific CA for Certificates

When generating certificates, you can specify which CA to use:

1. Using the configuration file:
   ```makefile
   # In config.mk
   CANAME = myca
   ```
   Then run:
   ```
   make example.com
   ```

2. Directly on the command line:
   ```
   make CANAME=myca example.com
   ```

This will generate certificates signed by your specified CA.

# Pihole Example

I created this as a result of trying to get an SSL certificate for my PiHole on my LAN. It did not have a real TLD (`pi.hole`), and its IP was internal (`192.168.1.*`), so no "real" Certificate Authority could issue a cert for it. However, I did not want clients to get the "insecure" warning of missing or self-signed HTTPS.

By creating a CA, installing that CA as a root CA in all my systems, and then issuing a certificate to the PiHole, this was solved!

1. create CA with `make ca`
   * Remember the passphrase you use for the CA; you'll need it later!
2. `make pi.hole`
   * When prompted for domain names, enter

         pi.hole
         pihole
         pihole.local

   * When prompted for IP addresses, enter the static IP you chose for your PiHole
   * For example, if your pihole is at `192.168.1.254`, the whole sequence should look like this:

         Enter domain names (one per line, press Ctrl+D when done):
         pi.hole
         pihole.local
         pihole
         Enter IP addresses (one per line, press Ctrl+D when done):
         192.168.1.254

3. use `sites/littlelan-pi.hole.crt` as the SSL cert for your PiHole
4. install `_certificate-authority/littlelanCA.pem` as a root certificate authority on any system that will connect to the PiHole over SSL

# Credits

* https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/
