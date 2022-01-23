// 需要在jenkins的Credentials设置中配置jenkins-harbor-creds、jenkins-k8s-config参数
// withCredentials([usernamePassword(credentialsId: 'jenkins-cn-qingdao.aliyuncs.com', passwordVariable: 'Password', usernameVariable: 'Username')]) {
//   sh 'docker login --u$Username -p$Uassword registry.cn-shanghai.aliyuncs.com'
// }


node{
    // when { expression { sh(returnStdout: true,script: 'git describe --tags --always').trim() == null } }
    stage("初始化本地仓库"){
        // 删除原来旧的仓库
        sh "rm -rf test-slave"
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'faxinba-gitee-readonly', url: 'https://gitee.com/hjl_kubernetes/pipeline-demo.git']]])
    }
}


pipeline {
    agent any
    environment {
        // HARBOR_CREDS = credentials('faxinba-gitee-readonly')
        // K8S_CONFIG = credentials('jenkins-k8s-config')
        GIT_TAG = sh(returnStdout: true,script: 'git describe --tags --always').trim()
    }
    parameters {
        // registry.cn-qingdao.aliyuncs.com/haojile/jenkins
        string(name: 'HARBOR_HOST', defaultValue: 'registry.cn-qingdao.aliyuncs.com', description: 'harbor仓库地址')
        string(name: 'DOCKER_IMAGE', defaultValue: 'haojile/pipeline-demo', description: 'docker镜像名')
        string(name: 'APP_NAME', defaultValue: 'pipeline-demo', description: 'k8s中标签名')
        string(name: 'K8S_NAMESPACE', defaultValue: 'devops', description: 'k8s的namespace名称')
    }
    stages {
        // docker pull maven:3-jdk-8-alpine
        stage('拉取代码'){
            // agent any
            // agent {                
            //     label 'master'            
            // }
            agent {
                docker {
                    image 'docker pull maven:3-jdk-8-alpine'
                    args '-v /root/.m2:/root/.m2'
                 }            
            }       
            steps{
                echo "1.Git Clone Code"
                // git credentialsId: 'dc6b3f14-b7b3-40a9-9880-5cb9f98e114c', url: 'https://gitlab.com/shazforiot/gameoflife.git'
                //checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://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@github.com/hjl-test-soft/pipeline-demo.git']]])
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'faxinba-gitee-readonly', url: 'https://gitee.com/hjl_kubernetes/pipeline-demo.git']]])
            }
        }
        stage('编译代码') { 
            when { expression { env.GIT_TAG != null } }
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v /root/.m2:/root/.m2'
                 }            
            }            
            steps {
                    echo "2.Maven Complie Stage"
                     sh 'mvn -B clean Compile -Dmaven.test.skip=true'
                   }        
        }
        stage('静态代码扫描') { 
            when { expression { env.GIT_TAG != null } }           
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v /root/.m2:/root/.m2'
                 }            
            }            
            steps {
                    // echo "3.Maven Complie Stage"
                    // sh 'mvn -B clean compile -Dmaven.test.skip=true'
                    echo '3.Run sonar'
                    sh 'sh run_sonar.sh'
            } 
        }
        stage('Maven打包') {  
            when { expression { env.GIT_TAG != null } }          
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v /root/.m2:/root/.m2'
                 }            
            }            
            steps {
                    echo "4.Maven Build Stage"
                    sh 'mvn -B clean package -Dmaven.test.skip=true  -Dmaven.test.skip'
                    stash includes: 'target/*.jar', name: 'app'
                   }        
        }
        stage('Docker镜像打包') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent any
            steps {
                unstash 'app'
                withCredentials([usernamePassword(credentialsId: 'jenkins-cn-qingdao.aliyuncs.com', passwordVariable: 'Password', usernameVariable: 'Username')]) {
                sh 'docker login --u$Username -p$Uassword ${params.HARBOR_HOST}'
                }
                // sh "docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} ${params.HARBOR_HOST}"
                sh "docker build --build-arg JAR_FILE=`ls target/*.jar |cut -d '/' -f2` -t ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG} ."
                sh "docker push ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
                sh "docker rmi ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
            }
            
        }
        stage('部署') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent {
                docker {
                    image 'lwolf/helm-kubectl-docker'
                }
            }
            steps {
                sh "mkdir -p ~/.kube"
                // sh "echo ${K8S_CONFIG} | base64 -d > ~/.kube/config"
                sh "sed -e 's#{IMAGE_URL}#${params.HARBOR_HOST}/${params.DOCKER_IMAGE}#g;s#{IMAGE_TAG}#${GIT_TAG}#g;s#{APP_NAME}#${params.APP_NAME}#g;s#{SPRING_PROFILE}#k8s-test#g' k8s-deployment.tpl > k8s-deployment.yml"
                sh "kubectl apply -f k8s-deployment.yml --namespace=${params.K8S_NAMESPACE}"
            }
            
        }
        
    }
}
