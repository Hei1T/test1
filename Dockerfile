# 基础镜像
FROM node:20-alpine AS base

# 全局安装pnpm
RUN npm install -g pnpm

# 安装依赖阶段
FROM base AS deps
WORKDIR /app

# 复制package.json和pnpm-lock.yaml（如果存在）
COPY package.json pnpm-lock.yaml* ./

# 安装依赖
RUN pnpm install --frozen-lockfile

# 构建阶段
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 构建应用
RUN pnpm build

# 生产阶段
FROM base AS runner
WORKDIR /app

# 设置为生产环境
ENV NODE_ENV=production

# 添加一个非 root 用户来运行应用
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 复制构建产物和必要文件
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# 设置正确的权限
RUN chown -R nextjs:nodejs /app

# 切换到非 root 用户
USER nextjs

# 暴露端口
EXPOSE 80

# 设置环境变量
ENV PORT=80
ENV HOSTNAME="0.0.0.0"

# 启动应用
CMD ["node", "server.js"]