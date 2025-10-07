FROM node:18

WORKDIR /usr/src/app

COPY package*.json* ./


ENV NODE_ENV=production
ENV PORT=3000

# Install dependencies (production only)
RUN npm ci --only=production

CMD [ "npm", "start" ]