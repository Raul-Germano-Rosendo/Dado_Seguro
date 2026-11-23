FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --chown=node:node dist ./dist
RUN mkdir -p /app/uploads && chown -R node:node /app
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
