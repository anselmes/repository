NAME := repository
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null | sed 's/-\([0-9][0-9]*\)-g/+\1.g/')

PREFIX ?= /usr/local/bin

# TODO: Build flags

.PHONY: all install uninstall build clean config rootca ca cert help
all: build cert
	@echo "🎯 All targets completed successfully!"

# MARK: - Help

help:
	@echo ""
	@echo "                        \033[1;96m✨ $(NAME) ✨\033[0m"
	@echo ""
	@echo "   \033[1;93m🌟 General Commands\033[0m"
	@echo "   \033[38;5;117m╭─\033[0m \033[1;97mall\033[0m               \033[37mBuild and generate certificates\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mhelp\033[0m              \033[37mShow this help message\033[0m"
	@echo ""
	@echo "   \033[1;93m⚡ Build & Clean\033[0m"
	@echo "   \033[38;5;117m╭─\033[0m \033[1;97mbuild\033[0m             \033[37mBuild the $(NAME) binary\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mclean\033[0m             \033[37mClean build artifacts and generated files\033[0m"
	@echo ""
	@echo "   \033[1;93m📦 Installation\033[0m"
	@echo "   \033[38;5;117m╭─\033[0m \033[1;97minstall\033[0m           \033[37mInstall $(NAME) to $(PREFIX)\033[0m \033[2;90m(requires sudo)\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97muninstall\033[0m         \033[37mUninstall $(NAME) from $(PREFIX)\033[0m \033[2;90m(requires sudo)\033[0m"
	@echo ""
	@echo "   \033[1;93m⚙️  Configuration\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mconfig\033[0m            \033[37mGenerate OpenSSL config from config/cert.yaml\033[0m"
	@echo ""
	@echo "   \033[1;93m🔐 Certificates\033[0m"
	@echo "   \033[38;5;117m╭─\033[0m \033[1;97mrootca\033[0m            \033[37mGenerate root CA certificate\033[0m"
	@echo "   \033[38;5;117m├─\033[0m \033[1;97mca\033[0m                \033[37mGenerate intermediate CA certificate\033[0m \033[2;90m↳ rootca\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mcert\033[0m              \033[37mGenerate TLS certificates\033[0m \033[2;90m↳ ca\033[0m"
	@echo ""
	@echo "   \033[2;96m💫 Usage:\033[0m \033[3;37mmake \033[1;97m<target>\033[0m"
	@echo ""

# MARK: - Install

install:
	@if [ ! -d .build ]; then \
		echo "Please run 'make build' first."; \
		exit 1; \
	fi
	sudo -E install -m 0755 .build/$(NAME) $(DESTDIR)$(PREFIX)/$(NAME)
	@echo "✅ Installed $(NAME) to $(DESTDIR)$(PREFIX)/$(NAME)"

uninstall:
	@if [ -f $(DESTDIR)$(PREFIX)/$(NAME) ]; then \
		sudo -E rm -f $(DESTDIR)$(PREFIX)/$(NAME); \
		echo "🗑️ Uninstalled $(NAME) from $(DESTDIR)$(PREFIX)/$(NAME)"; \
	else \
		echo "$(DESTDIR)$(PREFIX)/$(NAME) not found."; \
	fi

# MARK: - Build

build:
	@echo "✅ Build complete!"
	@echo "📝 To add $(NAME) to PATH and enable completion, run:"
	@echo "   source .env"

clean:
	go clean .
	rm -rf .build/
	rm -f *.pem *.csr *.json
	@echo "🧹 Clean complete!"

# MARK: - Config

config:
	yq '.config' config/cert.yaml -o json >openssl.json
	@echo "⚙️ OpenSSL configuration generated from config/cert.yaml!"

# MARK: - Certificate

rootca: config
	yq '.ca' config/cert.yaml -o json >ca.json
	cfssl genkey -config openssl.json -profile ca -initca ca.json | cfssljson -bare ca
	@echo "🔐 Root CA certificate generated successfully!"

ca: rootca
	yq '.intermediate' config/cert.yaml -o json >intermediate.json
	cfssl gencert \
		-config openssl.json \
		-profile ca \
		-ca ca.pem \
		-ca-key ca-key.pem intermediate.json \
		| cfssljson -bare intermediate
	cat intermediate.pem ca.pem >ca-bundle.pem
	@echo "🔗 Intermediate CA certificate and bundle generated successfully!"

cert: ca
	yq '.tls' config/cert.yaml -o json >tls.json
	cfssl gencert \
		-config openssl.json \
		-profile tls \
		-ca intermediate.pem \
		-ca-key intermediate-key.pem tls.json \
		| cfssljson -bare tls
	cat tls.pem ca-bundle.pem >tls-bundle.pem
	@echo "🔒 TLS certificates and bundle generated successfully!"
