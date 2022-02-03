def slavename = "${JOB_NAME}-${UUID.randomUUID().toString()}"
def HARBOR_HOST = "registry.cn-qingdao.aliyuncs.com"
def DOCKER_IMAGE = "haojile/pipeline-demo"
def K8S_NAMESPACE = "devops"
def APP_NAME = "pipeline-demo"


environment {
        HARBOR_CREDS = credentials('jenkins-harbor-creds')
        K8S_CONFIG = credentials('jenkins-k8s-config')
        // GIT_TAG = sh(returnStdout: true,script: 'git describe --tags --always').trim()
        // GIT_TAG = '${Tag}'
}

podTemplate(
    name: slavename, 
    label: slavename, 
    cloud: 'kubernetes',
    serviceAccount: 'jenkins-admin', 
    namespace: 'devops', 
    containers: [
        containerTemplate(name: 'maven', image: 'maven:3.3.9-jdk-8-alpine', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'dockerbuildimage', image: 'herychemo/dind-java-maven:latest', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'golang', image: 'golang:1.8.0', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'helm-kubectl-docker', image: 'lwolf/helm-kubectl-docker:v1.21.1-v3.6.0', ttyEnabled: true, command: 'cat')
        
        
    ]
    ,volumes: [
        persistentVolumeClaim(mountPath: '/data/jenkins_slave', claimName:'jenkins-slave-pvc'),
        persistentVolumeClaim(mountPath: '/root/.m2', claimName:'maven-local-pvc'),
        // hostPathVolume(mountPath: '/root/.m2', hostPath:'/root/.m2')
        // hostPathVolume(mountPath: '$(which docker)', hostPath: '/usr/bin/docker'),
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
        hostPathVolume(mountPath: '/usr/bin/docker', hostPath: '/usr/bin/docker')
    ]
    , envVars: [
        podEnvVar(key: 'JENKINS_TUNNEL', value: '10.101.98.35:50000')
        // podEnvVar(key: 'JENKINS_AGENT_WORKDIR', value: '/home/jenkins')
        ]
  ) {
      
        parameters {
            // registry.cn-qingdao.aliyuncs.com/haojile/jenkins
            string(name: 'HARBOR_HOST', defaultValue: 'registry.cn-qingdao.aliyuncs.com', description: 'harbor仓库地址')
            string(name: 'DOCKER_IMAGE', defaultValue: 'haojile/pipeline-demo', description: 'docker镜像名')
            string(name: 'APP_NAME', defaultValue: 'pipeline-demo', description: 'k8s中标签名')
            string(name: 'K8S_NAMESPACE', defaultValue: 'devops', description: 'k8s的namespace名称')
            string(name: 'Tag', defaultValue: 'devops', description: 'Gitda打包的Tag')
        }

        properties([
            parameters([
                string(name: 'HARBOR_HOST', defaultValue: 'registry.cn-qingdao.aliyuncs.com', description: 'harbor仓库地址'),
                string(name: 'DOCKER_IMAGE', defaultValue: 'haojile/pipeline-demo', description: 'docker镜像名'),
                string(name: 'APP_NAME', defaultValue: 'pipeline-demo', description: 'k8s中标签名'),
                string(name: 'K8S_NAMESPACE', defaultValue: 'devops', description: 'k8s的namespace名称'),
                string(name: 'Tag', defaultValue: 'devops', description: 'Gitda打包的Tag')
        ])])

        node(slavename) {
            
            stage('拉取代码') {
                echo "1.拉取代码"
                sh 'echo 当前目录'
                sh 'pwd'
                git  credentialsId: 'faxinba-gitee-readonly', url: 'https://gitee.com/hjl_kubernetes/pipeline-demo.git'
            }

            stage('编译代码') {
                echo "2.编译代码"
                container('maven') {
                stage('编译代码') {
                    sh 'mvn -B clean install'
                }
                }
            }

            stage('静态代码扫描') {
                echo "3.静态代码扫描"
                container('maven') {
                    echo '3.Run sonar'
                    sh 'sh run_sonar.sh'
                }
            }

            stage('maven打包') {
                echo "4.maven打包"
                container('maven') {
                    sh 'mvn -B clean package'
                }
            }
            
            stage('Docker打包') {
                echo "5.Docker打包"
                container('dockerbuildimage') {
                    echo 'Docker打包'
                    // 具体的格式依据Dockerfile中的传递参数
                    sh 'docker build -f Dockerfile --build-arg JAR_FILE=pipeline-demo-0.0.1-SNAPSHOT.jar -t pipeline-demo:$Tag . ' 
                    echo 'docker build successul finished'
                    
                    echo '进行tag'
                    sh 'docker tag  pipeline-demo:$Tag '+HARBOR_HOST+'/'+DOCKER_IMAGE+':$Tag ' 
                    echo "docker tag successul finished"
                    withCredentials([usernamePassword(credentialsId: 'jenkins-cn-qingdao.aliyuncs.com', passwordVariable: 'HARBOR_CREDS_PSW', usernameVariable: 'HARBOR_CREDS_USR')]) {
                        sh 'docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} '+HARBOR_HOST
                        sh 'docker push '+HARBOR_HOST+'/'+DOCKER_IMAGE+':$Tag ' 
                    }
                    echo "docker push successul finished"
            
                }
                
            }
            
            stage('拉取镜像') {
                echo "6.拉取镜像"
                container('dockerbuildimage') {
                    echo '拉取镜像'
                    withCredentials([usernamePassword(credentialsId: 'jenkins-cn-qingdao.aliyuncs.com', passwordVariable: 'HARBOR_CREDS_PSW', usernameVariable: 'HARBOR_CREDS_USR')]) {
                        sh 'docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} '+HARBOR_HOST
                        sh 'docker pull '+HARBOR_HOST+'/'+DOCKER_IMAGE+':$Tag ' 
                    }
                }
                
            }
            
            stage('K8s发布') {
                echo "7.K8s发布"
                container('helm-kubectl-docker') {
                    echo 'K8s发布'
                    withCredentials([usernamePassword(credentialsId: 'jenkins-cn-qingdao.aliyuncs.com', passwordVariable: 'HARBOR_CREDS_PSW', usernameVariable: 'HARBOR_CREDS_USR')]) {
                        // sh 'docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} '+HARBOR_HOST
                        // sh 'docker pull '+HARBOR_HOST+'/'+DOCKER_IMAGE+':$Tag ' 
                        
                        sh "mkdir -p ~/.kube"
                        // sh "echo ${K8S_CONFIG} | base64 -d > ~/.kube/config"
                        sh "sed -e 's#{IMAGE_URL}#"+HARBOR_HOST+"/"+DOCKER_IMAGE+"#g;s#{IMAGE_TAG}#$Tag#g;s#{APP_NAME}#"+APP_NAME+"#g;s#{SPRING_PROFILE}#k8s-test#g' k8s-deployment.tpl > k8s-deployment.yml"
                        sh 'cat k8s-deployment.yml'
                        sh "kubectl apply -f k8s-deployment.yml --namespace="+K8S_NAMESPACE
                    
                    }
                    echo "K8s发布完成"
            
                }
                
            }
            
        }
    

    }
    

