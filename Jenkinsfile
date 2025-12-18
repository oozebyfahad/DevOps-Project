pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "fahadmalik07/jenkins-ci-webapp"
        DOCKER_CREDS = credentials('dockerhub-creds')  // Jenkins credentials ID
    }

    triggers { githubPush() }

    stages {

        stage('Code Fetch Stage') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Docker Image Creation Stage') {
            steps {
                sh '''
                    echo "$DOCKER_CREDS_PSW" | docker login -u "$DOCKER_CREDS_USR" --password-stdin
                    docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} -t $DOCKER_IMAGE:latest .
                    docker push $DOCKER_IMAGE:${BUILD_NUMBER}
                    docker push $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Kubernetes Deployment Stage') {
            steps {
                sh '''
                   bash scripts/deploy.sh
                '''
            }
        }

        stage('Prometheus/ Grafana Stage') {
            steps {
                sh '''
                    echo "Monitoring stack check..."
                    kubectl get pods -n monitoring || true
                    kubectl get svc -n monitoring || true
                '''
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed.' }
        always  { sh 'docker logout || true' }
    }
}