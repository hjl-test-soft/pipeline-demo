jenkins pipeline示例，详细说明参见：https://www.jianshu.com/p/2d89fd1b4403

docker编译命令：
docker build -f Dockerfile --build-arg JAR_FILE=pipeline-demo-0.0.1-SNAPSHOT.jar -t pipeline-demo:v1.0.0  .

docker运行命令：
# -p: 指定端口映射，格式为：主机(宿主)端口:容器端口
docker run -p 8080:40080 pipeline-demo:v1.0.0  --name="pipeline-demo-v1.0.0"


docker pull registry.cn-qingdao.aliyuncs.com/haojile/pipeline-demo:v1.0.0
