mvn clean compile sonar:sonar \
  -Dsonar.projectKey=pipeline-demo \
  -Dsonar.host.url=http://sonar.simpletester.cn/ \
  -Dsonar.login=tempuser001 \
  -Dsonar.password=t@mpuser001!