# Shaw-WRT

基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 的自定义 OpenWrt 固件构建环境。

## 项目结构

```
.
├── Dockerfile              # Docker 构建镜像配置
├── setup.sh                # 自动化设置脚本
├── attach.sh               # Docker 容器连接脚本
├── conf/
│   ├── sources.list        # Debian APT 源配置
│   ├── feeds.custom.conf   # 自定义 OpenWrt feeds
│   └── initial_script.sh   # uci-defaults 初始化脚本
└── README.md
```

## 快速开始

### 1. 构建 Docker 镜像

```bash
docker build -t shaw-wrt .
```

### 2. 运行容器

```bash
docker run -it --name shaw-wrt shaw-wrt
```

### 3. 连接到已有容器

```bash
./attach.sh
```

## 配置说明

### setup.sh 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-b, --branch` | ImmortalWrt 分支 | `openwrt-24.10` |
| `-p, --proxy` | GitHub 代理前缀 | 无（直连） |
| `-w, --workdir` | 工作目录 | `/home/shaw` |

**示例：**

```bash
# 使用代理
./setup.sh -b openwrt-24.10 -p https://ghfast.top

# 不使用代理
./setup.sh -b openwrt-24.10

# 使用其他分支
./setup.sh -b openwrt-23.05
```

### 自定义 Feeds

编辑 `conf/feeds.custom.conf` 添加自定义源：

```
src-git <name> https://github.com/<user>/<repo>.git;<branch>
```

### 初始化脚本

编辑 `conf/initial_script.sh` 配置首次启动时的系统设置：
- Root 密码
- LAN IP 地址
- PPPoE 拨号配置
- WiFi 设置

## 编译固件

进入容器后：

```bash
cd /home/shaw/immortalwrt

# 配置编译选项
make menuconfig

# 下载依赖
make download -j$(nproc)

# 编译固件
make -j$(nproc) V=s
```

## License

MIT
