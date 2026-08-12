FROM debian:bookworm-slim

ARG GCLOUD_CLI_VERSION=""

# ---- Common CLI tools -------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git jq vim-tiny unzip ca-certificates gnupg lsb-release apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# ---- Google Cloud SDK -------------------------------------------------------
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
       | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# ---- Supabase CLI (arch-aware) ----------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
         amd64) SB_ARCH="linux_amd64" ;; \
         arm64) SB_ARCH="linux_arm64" ;; \
         *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
       esac \
    && SB_TAG=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest | jq -r '.tag_name') \
    && curl -fsSL "https://github.com/supabase/cli/releases/download/${SB_TAG}/supabase_${SB_ARCH}.tar.gz" \
       | tar -xz -C /usr/local/bin supabase \
    && chmod +x /usr/local/bin/supabase

# ---- Non-root user ----------------------------------------------------------
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app
RUN chown appuser:appgroup /app

USER appuser

CMD ["/bin/bash"]