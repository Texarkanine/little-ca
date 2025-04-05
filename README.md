# Little CA

A simple Certificate Authority tool for creating and managing SSL/TLS certificates.

## Quick Start

1. Create your Certificate Authority:
   ```
   make ca
   ```

2. Generate a certificate for a domain:
   ```
   make example.com
   ```

## Configuration

You can customize the behavior of Little CA by creating a `config.mk` file. This file allows you to set default values for various options without having to specify them on the command line each time.

### Sample Configuration

Copy the example configuration file and modify it as needed:

```
cp config.mk.example config.mk
```

Then edit `config.mk` to set your preferred defaults:

```makefile
# Name of the Certificate Authority
CANAME = myca

# Directory where CA files are stored
CADIR = my-certificates

# Directory where site certificates are stored
SITEDIR = sites
```

### Configuration Options

- `CANAME`: The name of your Certificate Authority (default: `little`)
- `CADIR`: Directory where CA files are stored (default: `_certificate-authority`)
- `SITEDIR`: Directory where site certificates are stored (default: `default`)

### Precedence

Configuration values are applied in this order (highest to lowest):

1. Command-line arguments (e.g., `make CANAME=big example.com`)
2. Values in `config.mk`
3. Default values in the Makefile

## Files

- `Makefile`: The main build script
- `config.mk.example`: Example configuration file
- `generate_ext.sh`: Script for generating certificate extensions
- `template.ext`: Template for certificate extensions
