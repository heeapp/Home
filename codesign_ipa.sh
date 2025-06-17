#!/bin/bash

echo "选择IPA文件..."
ipa_path=$(osascript -e 'POSIX path of (choose file with prompt "选择要重签名的IPA文件" of type {"ipa"})')

echo "选择mobileprovision文件..."
mobileprovision_path=$(osascript -e 'POSIX path of (choose file with prompt "选择用于重签的mobileprovision文件" of type {"mobileprovision"})')

echo "输入输出IPA名称（不含后缀）:"
read output_name

# 获取输出目录
base_dir=$(dirname "$ipa_path")
output_dir="$base_dir/new"
mkdir -p "$output_dir"

# 创建工作目录
tmp_dir=$(mktemp -d)

# 解压ipa
unzip -q "$ipa_path" -d "$tmp_dir"

# 查找 app 路径
app_path=$(find "$tmp_dir/Payload" -name "*.app" -type d)

# 获取 app 的 bundle id
info_plist="$app_path/Info.plist"
bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$info_plist")

# 复制描述文件到 app 目录
cp "$mobileprovision_path" "$app_path/embedded.mobileprovision"

echo "自动从描述文件中提取 TeamIdentifier..."

# 提取 TeamIdentifier
team_id=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" "$tmp_dir/profile.plist")

# 提取证书 Common Name（从描述文件中）
cert_common_name=$(/usr/libexec/PlistBuddy -c "Print :DeveloperCertificates:0" "$tmp_dir/profile.plist" | openssl x509 -inform DER -noout -subject | sed -n 's/.*CN=\(.*\)/\1/p')
echo "描述文件中的证书 CN: $cert_common_name"

echo "TeamIdentifier: $team_id"
echo "正在匹配本地证书..."

# 自动匹配本地证书
sign_identity=$(security find-identity -v -p codesigning | grep "$cert_common_name" | head -n 1 | sed -E 's/^[[:space:]]*[0-9]+\) [A-F0-9]+ "(.+)"$/\1/')

if [ -z "$sign_identity" ]; then
  echo "❌ 未找到匹配 Team ID($team_id) 的本地签名证书"
  exit 1
fi

echo "✅ 使用签名证书: $sign_identity"

# 导出 entitlements
entitlements_plist="$tmp_dir/entitlements.plist"
/usr/bin/security cms -D -i "$mobileprovision_path" > "$tmp_dir/profile.plist"
/usr/libexec/PlistBuddy -x -c "Print :Entitlements" "$tmp_dir/profile.plist" > "$entitlements_plist"

# 执行重签
echo "开始重签..."
codesign -f -s "$sign_identity" --entitlements "$entitlements_plist" "$app_path"

# 重新打包 ipa
cd "$tmp_dir"
zip -qr "$output_dir/$output_name.ipa" Payload

echo "✅ 重签完成！新IPA路径：$output_dir/$output_name.ipa"

# 清理
rm -rf "$tmp_dir"