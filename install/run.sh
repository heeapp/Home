#!/bin/bash
 
# 提示用户输入目标文件夹
read -p "请输入Bundle包名(com.xxx.xxx): " IPA_BUNDLE

# 提示用户输入目标文件夹
read -p "请输入版本号version: " IPA_VERSION


# 提示用户输入目标文件夹
read -p "请输入应用名称: " IPA_NAME


# 循环直到用户输入有效的文件路径
while true; do
  # 提示用户输入文件路径
  read -p "请输入ipa: " IPA_PATH

  # 检查文件是否存在
  if [ -f "$IPA_PATH" ]; then
    echo "文件存在: $IPA_PATH"
    break
  else
    echo "错误: 文件 '$IPA_PATH' 不存在! 请重新输入."
  fi
done


TARGET_DIR="../${IPA_NAME}" 

rm -rf  "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
 
# 生成一个新的 UUID 
UUID=$(uuidgen)

# 获取文件扩展名
FILE_EXTENSION="${IPA_PATH##*.}"

# 组合新的文件名
NEW_FILE_NAME="${UUID}.${FILE_EXTENSION}"

# 移动ipa并重命名
cp "$IPA_PATH"   "$TARGET_DIR/$NEW_FILE_NAME" 

# 设置权限 可读
chmod 755  "$TARGET_DIR/$NEW_FILE_NAME"


INDEX_PATH="$TARGET_DIR/index.html" 

# 把index.html 复制到文件
cp './base.html'   "$INDEX_PATH" 
chmod 755  "$INDEX_PATH" 
  
# 检查目标文件是否存在
if [ -f "$INDEX_PATH" ]; then
  # 使用 sed 替换文件中的 "IPAPATH" 为 "xxxxxx"
  sed -i '' 's/UUID/'${UUID}'/g'  "$INDEX_PATH"
  sed -i '' 's/NAME/'${IPA_NAME}'/g'     "$INDEX_PATH" 
else
  echo "错误: 文件 '$INDEX_PATH' 不存在!"
fi



INDEX_PLIST="$TARGET_DIR/index.plist" 

# 把index.html 复制到文件
cp './base.plist'   "$INDEX_PLIST" 
chmod 755  "$INDEX_PLIST" 
  
# 检查目标文件是否存在
if [ -f "$INDEX_PLIST" ]; then
  # 使用 sed 替换文件中的 "IPAPATH" 为 "xxxxxx"
  sed -i '' 's/IPANAME/'${UUID}'/g'             "$INDEX_PLIST"
  sed -i '' 's/BUNDLEID/'${IPA_BUNDLE}'/g'      "$INDEX_PLIST" 
  sed -i '' 's/VERSION/'${IPA_VERSION}'/g'      "$INDEX_PLIST" 
  sed -i '' 's/NAME/'${IPA_NAME}'/g'            "$INDEX_PLIST" 

else
  echo "错误: 文件 '$INDEX_PLIST' 不存在!"
fi

cd  ..
#!/bin/sh
# 设置 Git 用户信息（如果尚未设置）
# git config user.name "Your Name"
# git config user.email "your.email@example.com"
# 添加所有更改
git add .

# 提交更改，使用默认的提交信息
git commit -m "$IPA_NAME"

# 推送更改到远程仓库
git push



















