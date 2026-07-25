# 阶段 1: 构建阶段(生成静态导出 /app/out)
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段(静态文件由 nginx 托管)
# 静态文件复制自阶段一(--target builder --load)构建并载入本地的 builder-cache 镜像。
# 该镜像含 /app/out,且为纯文件、与架构无关,故多平台构建时各平台只需构建 nginx,
# 无需重复 node 构建。注意:此处写死镜像名 builder-cache(非 ARG 变量),
# 避免 --target builder 阶段 BuildKit 不求值后期 stage 的 ARG 导致 COPY --from 解析失败。
FROM nginx:alpine AS runner

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder-cache --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]