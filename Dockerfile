# 阶段 1: 构建阶段（显式指定为 linux/amd64）
FROM --platform=linux/amd64 node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段（多平台）
FROM nginx:alpine AS runner

# 直接引用 builder 阶段，静态文件与架构无关
COPY --from=builder --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]