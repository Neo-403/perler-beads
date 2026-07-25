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

# 关键参数：默认指向本地 builder 阶段
ARG BUILDER_IMAGE=builder

# 复制 Nginx 配置（如果你有自定义配置）
# COPY nginx.conf /etc/nginx/nginx.conf

# 从 builder 阶段复制静态文件
COPY --from=$BUILDER_IMAGE --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]