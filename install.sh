#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi :${plain} Tập lệnh này phải được chạy với tư cách người dùng root!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Không phát hiện được giản đồ, hãy sử dụng lược đồ mặc định: ${arch}${plain}"
fi

echo "Ngành kiến ​​trúc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), nếu phát hiện sai, vui lòng liên hệ với tác giả"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng CentOS 7 trở lên!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng Ubuntu 16 hoặc cao hơn!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng Debian 8 trở lên!${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/AikoCute-Offical/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Không thể phát hiện phiên bản x-ui, có thể đã vượt quá giới hạn API Github, vui lòng thử lại sau hoặc chỉ định phiên bản x-ui để cài đặt theo cách thủ công${plain}"
            exit 1
        fi
        echo -e "Đã phát hiện phiên bản mới nhất của x-ui:${last_version}，bắt đầu cài đặt"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/AikoCute-Offical/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Không tải xuống được x-ui, hãy đảm bảo máy chủ của bạn có thể tải xuống tệp Github${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/AikoCute-Offical/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "bắt đầu cài đặt x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}tải x-uiv$1 không thành công, hãy đảm bảo rằng phiên bản này tồn tại${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/AikoCute/X-ui/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} Quá trình cài đặt hoàn tất, bảng điều khiển được khởi chạy，"
    echo -e ""
    echo -e "Nếu đó là một cài đặt mới, cổng web mặc định là ${green}54321${plain}，Tên người dùng và mật khẩu đều theo mặc định ${green}admin${plain}"
    echo -e "Hãy đảm bảo rằng cổng này không bị các chương trình khác chiếm giữ，${yellow}Và đảm bảo rằng cổng 54321 được mở${plain}"
    echo -e ""
    echo -e "Nếu đó là bảng cập nhật, hãy truy cập bảng như bạn đã làm trước đây"
    echo -e ""
    echo -e "Cách sử dụng tập lệnh quản lý x-ui: - AikoCuteHotMe"
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Hiển thị menu quản lý (nhiều chức năng hơn)"
    echo -e "x-ui start        - Khởi động bảng điều khiển x-ui"
    echo -e "x-ui stop         - dừng bảng điều khiển x-ui"
    echo -e "x-ui restart      - khởi động lại bảng điều khiển x-ui"
    echo -e "x-ui status       - Xem trạng thái x-ui"
    echo -e "x-ui enable       - Đặt x-ui để bắt đầu tự động khi khởi động"
    echo -e "x-ui disable      - Hủy tự động khởi động x-ui boot"
    echo -e "x-ui log          - Xem nhật ký x-ui"
    echo -e "x-ui v2-ui        - Di chuyển dữ liệu tài khoản v2-ui của máy này sang x-ui"
    echo -e "x-ui update       - Cập nhật bảng điều khiển x-ui"
    echo -e "x-ui install      - cài đặt bảng điều khiển x-ui"
    echo -e "x-ui uninstall    - gỡ cài đặt bảng điều khiển x-ui"
    echo -e "AikoCuteHotMe     - Lệnh này không có đâu nên đừng có sài nhé :D"
    echo -e "----------------------------------------------"
}

echo -e "${green}bắt đầu cài đặt${plain}"
install_base
install_x-ui $1
