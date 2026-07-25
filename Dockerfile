# 阶段 1: 构建阶段（生成静态文件）
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段（Nginx 托管静态文件）
FROM nginx:alpine AS runner

# 注意：不再需要 ARG BUILDER_IMAGE，直接使用阶段名称 builder
# 因为本地和 CI 中这个阶段的名称都是 builder，完全一致

# 复制 Nginx 配置（可选）
# COPY nginx.conf /etc/nginx/nginx.conf

# 直接使用 --from=builder，固定引用本地 builder 阶段
COPY --from=builder --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]