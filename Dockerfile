# 阶段 1: 构建阶段(生成静态导出 /app/out)
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com

COPY . .
RUN npm run build

# 阶段 2: 生产运行阶段(静态文件由 nginx 托管)
FROM nginx:alpine AS runner

# 声明 ARG 使其对 COPY --from= 可见(必须在本 stage 内声明,全局 ARG 对此类指令无效)
# 这里声明主要给单平台模式使用,多平台模式下会覆盖该参数
ARG BUILDER_IMAGE=builder

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=$BUILDER_IMAGE --chown=nginx:nginx /app/out /usr/share/nginx/html

USER nginx

EXPOSE 3000

STOPSIGNAL SIGQUIT

ENTRYPOINT ["nginx", "-g", "daemon off;"]