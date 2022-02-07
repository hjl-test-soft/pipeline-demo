apiVersion: apps/v1
kind: Deployment
metadata:
  name: ##APP_NAME##-deployment
  namespace: ##NAMESPACE##
  labels:
    app: ##APP_NAME##
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ##APP_NAME##
  template:
    metadata:
      labels:
        app: ##APP_NAME##
    spec:
      containers:
      - name: ##APP_NAME##
        image: ##IMAGE_URL##/##DOCKER_IMAGE##:##IMAGE_TAG##
        imagePullPolicy: IfNotPresent
        command: ["java" ,"-Xms1024m","-Xmx1024m", "-jar","/opt/demo/pipeline-demo-0.0.1-SNAPSHOT.jar"]
        ports:
        - containerPort: 40080
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: ##SPRING_PROFILE##