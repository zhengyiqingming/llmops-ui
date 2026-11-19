# 使用官方Node.js镜像作为基础镜像//我们可以把 Docker 镜像想象成一台完全独立、隔离的微型电脑。整个 Dockerfile 里的所有 RUN、COPY、WORKDIR 操作，全都是在这台“微型电脑”的硬盘里进行的。
FROM node:20 as builder

# 设置工作目录,创建的目录是在“正在构建的 Docker 镜像（容器）内部”的，完全不会在宿主机（你的 Ubuntu 虚拟机）上创建任何文件夹
WORKDIR /app/web

# 将package.json 和 yarn.lock拷贝到镜像内工作目录下，package.json：项目配置文件 / 依赖清单 yarn.lock：依赖锁定文件
COPY package.json .
COPY yarn.lock .

# 使用yarn安装依赖,这些命令全都是在 Docker 内部的 /app/web 目录下执行的，下载的 node_modules ，全都存在 Docker 内部的硬盘里。
RUN yarn install

# 将项目代码(当前目录所有文件)拷贝到容器（/app/web）中,左边的 .（点）代表的是宿主机（你的 Ubuntu，也就是你执行 docker build 的那个目录）的当前文件夹。右边的 .（点）代表的是 Docker 内部当前的工作目录，也就是刚刚 WORKDIR 设置的 /app/web。
COPY . .

#配置环境变量
ENV VITE_API_PREFIX=/api

# 构建/编译项目,在根目录生成dist文件,这些命令全都是在 Docker 内部的 /app/web 目录下执行的，生成的 dist 文件 ，全都存在 Docker 内部的硬盘里。
RUN yarn build

# 二阶段 使用Nginx来部署Vue静态页面, 这时候，Docker 启动了第二台微型电脑（Nginx 镜像）
#Docker 镜像的生成规则：只有最后一个阶段是“终点”
#这是 Docker 构建的底层逻辑：一个 Dockerfile 构建出来的最终镜像，永远只基于最后一个 FROM 指令所代表的阶段。
#即使你给第一阶段起了名字叫 as builder，它本质上只是一个“中间产物（Intermediate Container）”。Docker 引擎在构建完毕时，只会把最后一个阶段（as production）的文件系统层打包成最终的镜像。
FROM nginx:alpine as production
#去第一阶段的容器（builder）里，把它刚刚自己通过 yarn build 生成的那个 dist 文件夹，拷贝到我现在这个 Nginx 容器的 /usr/share/nginx/html 目录下。
COPY --from=builder /app/web/dist /usr/share/nginx/html
COPY --from=builder /app/web/docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# 设置目录权限为755，确保Nginx可以访问目录 d是文件
RUN find /usr/share/nginx/html -type d -exec chmod 755 {} \;

# 设置文件权限为 644，确保文件可以读但不可执行
RUN find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# 暴露 3000 端口号，将80端口留给nginx
EXPOSE 3000

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]