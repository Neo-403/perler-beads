# 静态文件来源：默认引用本地 builder 阶段（普通单机构建时可用）；
# 多平台 CI 中会被覆盖为「仅 amd64 构建并推送的临时镜像」，避免每个平台都重跑 node 构建
# ARG BUILDER_IMAGE=builder

# 阶段 1: 构建阶段（生成静态导出 /app/out）
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段（静态文件由 nginx 托管）
FROM nginx:alpine AS runner

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=$BUILDER_IMAGE --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]