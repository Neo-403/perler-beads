# 阶段 1: 构建阶段(生成静态导出 /app/out)
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段(静态文件由 nginx 托管)
# 静态文件复制自阶段一(仅 amd64 构建并推送到 GHCR 的临时镜像 builder-cache)。
# 该镜像含 /app/out,且为纯文件、与架构无关,故多平台构建时各平台只需构建 nginx,
# 无需重复 node 构建。BUILDER_IMAGE 默认引用本地 builder 阶段(普通单机构建时可用);
# 多平台 CI 中会被 --build-arg 覆盖为 GHCR 上的临时镜像,避免每个平台都重跑 node 构建。
FROM nginx:alpine AS runner

ARG BUILDER_IMAGE=builder

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=$BUILDER_IMAGE --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]