FROM node:18

WORKDIR /usr/src/app

COPY package*.json* ./


ENV NODE_ENV=production
ENV PORT=3000

# Install dependencies (production only)
RUN npm install

CMD [ "npm", "start" ]