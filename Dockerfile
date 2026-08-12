# =============================================================================
# Base image: docker.io/tnmurthy/default:latest
# OS:        debian:bookworm-slim
# Includes:  curl, git, wget, jq, vim, unzip, ca-certificates
#            Google Cloud SDK (gcloud, gsutil, bq)
#            Supabase CLI
#            Non-root user (appuser:appgroup, uid/gid 1001)
#
# Each project extends this image and installs its own runtime
# (Python, Node, etc.) on top.
# =============================================================================

FROM debian:bookworm-slim

# ---- Build args (override to pin versions) ----------------------------------
ARG GCLOUD_CLI_VERSION=""
# Leave empty to always install latest Supabase CLI

# ---- System packages --------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
        jq \
        vim-tiny \
        unzip \
        ca-certificates \
        gnupg \
        lsb-release \
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# ---- Google Cloud SDK -------------------------------------------------------
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
        https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && if [ -n "$GCLOUD_CLI_VERSION" ]; then \
         apt-get install -y --no-install-recommends "google-cloud-cli=${GCLOUD_CLI_VERSION}"; \
       else \
         apt-get install -y --no-install-recommends google-cloud-cli; \
       fi \
    && rm -rf /var/lib/apt/lists/*

# ---- Supabase CLI -----------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
         amd64) SB_ARCH="linux_amd64" ;; \
         arm64) SB_ARCH="linux_arm64" ;; \
         *)     echo "Unsupported arch: $ARCH" && exit 1 ;; \
       esac \
    && SB_TAG=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest \
         | jq -r '.tag_name') \
    && curl -fsSL \
         "https://github.com/supabase/cli/releases/download/${SB_TAG}/supabase_${SB_ARCH}.tar.gz" \
       | tar -xz -C /usr/local/bin supabase \
    && chmod +x /usr/local/bin/supabase

# ---- Non-root user ----------------------------------------------------------
RUN groupadd --gid 1001 appgroup \
    && useradd  --uid 1001 --gid appgroup \
                --shell /bin/bash \
                --create-home \
                appuser

# ---- Working directory (owned by appuser) -----------------------------------
WORKDIR /app
RUN chown appuser:appgroup /app

# ---- Drop privileges --------------------------------------------------------
USER appuser

# Verify tool availability at build time
RUN gcloud version --format="value(Google Cloud SDK)" \
    && supabase --version

CMD ["/bin/bash"]
