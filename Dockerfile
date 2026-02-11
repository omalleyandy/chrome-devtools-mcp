FROM node:20-bookworm-slim

# Use a non-root user for security
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /usr/src/app

# Install dependencies based on lockfile first (better layer caching)
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the repository
COPY . .

# Build the TypeScript sources
RUN npm run build

# Run as the non-root user
USER appuser

# The MCP server communicates over stdio, so no ports are exposed here.
# If you want to connect to a Chrome instance running on the host,
# start Chrome with a remote debugging port (e.g. 9222) and pass
# --browser-url=http://host.docker.internal:9222 as an argument.
#
# Example:
#   docker run --rm -it chrome-devtools-mcp \
#     node build/src/index.js --browser-url=http://host.docker.internal:9222
#
# Default command: start the MCP server.
CMD ["node", "build/src/index.js"]

