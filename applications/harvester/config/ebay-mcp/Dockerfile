# ebay-mcp HTTP server image — upstream (YosefHayim/ebay-mcp) ships no
# container image, so npm installs the CLI from the pinned npm release.
# Built & pushed by applications/harvester/scripts/build-ebay-mcp-image.sh;
# the consumed ref is pinned (with digest) in init_versions.tf.
FROM node:24-alpine

ARG EBAY_MCP_REF
RUN npm install -g "ebay-mcp@${EBAY_MCP_REF}" \
    && test -f /usr/local/lib/node_modules/ebay-mcp/build/serverHttp.js

EXPOSE 3000
CMD ["node", "/usr/local/lib/node_modules/ebay-mcp/build/serverHttp.js"]
