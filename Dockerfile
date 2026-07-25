# 阶段 1: 构建阶段
FROM node:22-bookworm-slim AS builder
# 设置工作目录
WORKDIR /app
# 关闭 Next.js 的遥测功能
ENV NEXT_TELEMETRY_DISABLED=1
# 复制依赖文件
COPY package.json package-lock.json ./
# 安装依赖(留一个使用国内镜像源的)
RUN npm ci --no-audit --no-fund
# RUN npm ci --no-audit --no-fund --registry=https://registry.npmmirror.com
# 复制项目文件
COPY . .
# 构建项目
RUN npm run build

# 阶段 2: 生产运行阶段（多平台）
FROM nginx:alpine AS runner
# 直接引用 builder 阶段，静态文件与架构无关
COPY --from=builder --chown=nginx:nginx /app/out /usr/share/nginx/html
# 设置用户
USER nginx
# 暴露端口(Nginx配置文件中对应的端口)
EXPOSE 3000
# 设置停止信号
STOPSIGNAL SIGQUIT
# 设置入口点
ENTRYPOINT ["nginx", "-g", "daemon off;"]