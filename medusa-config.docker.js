const path = require("path")

const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:9000"
const ADMIN_URL = process.env.ADMIN_URL || "http://localhost:7001"
const STORE_CORS = process.env.STORE_CORS || BACKEND_URL
const ADMIN_CORS = process.env.ADMIN_CORS || ADMIN_URL

// Database
const DATABASE_URL = process.env.DATABASE_URL || "postgresql://medusa:password@localhost:5432/medusa"

// Redis
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379"

const plugins = [
  `@medusajs/cache-redis`,
  {
    resolve: `@medusajs/cache-redis`,
    options: {
      redisUrl: REDIS_URL,
    },
  },
  `@medusajs/event-bus-redis`,
  {
    resolve: `@medusajs/event-bus-redis`,
    options: {
      redisUrl: REDIS_URL,
    },
  },
  `@medusajs/workflow-engine-redis`,
  {
    resolve: `@medusajs/workflow-engine-redis`,
    options: {
      redis: {
        url: REDIS_URL,
      },
    },
  },
  `@medusajs/file-local`,
]

/** @type {import('@medusajs/framework/types').ConfigModule} */
module.exports = {
  projectConfig: {
    databaseUrl: DATABASE_URL,
    http: {
      storeCors: STORE_CORS,
      adminCors: ADMIN_CORS,
      authCors: ADMIN_CORS,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret",
    },
    workerMode: process.env.MEDUSA_WORKER_MODE || "shared",
  },
  admin: {
    backendUrl: BACKEND_URL,
  },
  modules: [
    {
      resolve: "@medusajs/cache-redis",
      options: {
        redisUrl: REDIS_URL,
      },
    },
    {
      resolve: "@medusajs/event-bus-redis", 
      options: {
        redisUrl: REDIS_URL,
      },
    },
    {
      resolve: "@medusajs/workflow-engine-redis",
      options: {
        redis: {
          url: REDIS_URL,
        },
      },
    },
  ],
  plugins,
}