用终端命令帮我把景点数据导出为 CSV。先用 curl
从 Spring Boot API 拉取景点数据，再用 node 把
JSON 转成 CSV，包含
name、city、category、rating、price
五个字段，保存到 output/
attractions-export.csv。