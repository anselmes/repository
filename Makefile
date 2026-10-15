NAME := repository
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null | sed 's/-\([0-9][0-9]*\)-g/+\1.g/')

PREFIX ?= /usr/local/bin

.PHONY: all help setup clean config rootca ca cert
all: cert
	@echo "🎯 All targets completed successfully!"

# MARK: - Help

help:
	@echo ""
	@echo "                        \033[1;96m✨ $(NAME) ✨\033[0m"
	@echo ""
	@echo "   \033[1;93m🌟 General Commands\033[0m"
	@echo "   \033[38;5;117m╭─\033[0m \033[1;97mall\033[0m               \033[37mGenerate certificates\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mhelp\033[0m              \033[37mShow this help message\033[0m"
	@echo ""
	@echo "   \033[1;93m⚡ Clean\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97mclean\033[0m             \033[37mClean generated files\033[0m"
	@echo ""
	@echo "   \033[1;93m🛠️  Developer Setup\033[0m"
	@echo "   \033[38;5;117m╰─\033[0m \033[1;97msetup\033[0m             \033[37mInstall Brewfile tools and gh extensions (actions-lock, stack)\033[0m"
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

# MARK: - Setup

GH_EXTENSIONS := github/gh-actions-lock github/gh-stack

# Homebrew cannot install gh extensions, so they are provisioned here after
# `brew bundle`: gh-actions-lock backs the actions-lock-verify pre-commit hook
# (`gh actions-lock`) and gh-stack provides stacked PRs (`gh stack`).
setup:
	brew bundle --file=hack/Brewfile
	@for ext in $(GH_EXTENSIONS); do \
		if gh extension list | grep -q "$$ext"; then \
			echo "✅ $$ext already installed"; \
		else \
			gh extension install "$$ext"; \
		fi; \
	done
	@echo "🛠️ Developer setup complete!"

# MARK: - Build

clean:
	rm -f pki/*
	@echo "🧹 Clean complete!"

# MARK: - Config

config:
	mkdir -p pki
	yq '.config' config/cert.yaml -o json >pki/openssl.json
	@echo "⚙️ OpenSSL configuration generated from config/cert.yaml!"

# MARK: - Certificate

rootca: config
	yq '.ca' config/cert.yaml -o json >pki/ca.json
	cfssl genkey -config pki/openssl.json -profile ca -initca pki/ca.json | cfssljson -bare pki/ca
	@echo "🔐 Root CA certificate generated successfully!"

ca: rootca
	yq '.intermediate' config/cert.yaml -o json >pki/intermediate.json
	cfssl gencert \
		-config pki/openssl.json \
		-profile ca \
		-ca pki/ca.pem \
		-ca-key pki/ca-key.pem pki/intermediate.json \
		| cfssljson -bare pki/intermediate
	cat pki/intermediate.pem pki/ca.pem >pki/ca-bundle.pem
	@echo "🔗 Intermediate CA certificate and bundle generated successfully!"

cert: ca
	yq '.tls' config/cert.yaml -o json >pki/tls.json
	cfssl gencert \
		-config pki/openssl.json \
		-profile tls \
		-ca pki/intermediate.pem \
		-ca-key pki/intermediate-key.pem pki/tls.json \
		| cfssljson -bare pki/tls
	cat pki/tls.pem pki/ca-bundle.pem >pki/tls-bundle.pem
	@echo "🔒 TLS certificates and bundle generated successfully!"
