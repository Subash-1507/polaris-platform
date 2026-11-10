// Platform smoke test: managed identity -> ACR push -> AKS access. No stored credentials.
pipeline {
  agent { label 'docker' }

  options {
    timestamps()
    timeout(time: 15, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  environment {
    ACR_NAME = 'acrpolaris4827'
    RG       = 'rg-polaris-devops'
    AKS_NAME = 'aks-polaris'
    // Keep every credential cache inside the workspace, which is wiped after the build
    AZURE_CONFIG_DIR = "${WORKSPACE}/.azure"
    DOCKER_CONFIG    = "${WORKSPACE}/.docker"
    KUBECONFIG       = "${WORKSPACE}/.kube/config"
  }

  stages {
    stage('Azure login (managed identity)') {
      steps {
        sh '''
          az login --identity --output none
          az account show --query "{subscription:name, identity:user.name, type:user.type}" -o table
        '''
      }
    }

    stage('Build and push to ACR') {
      steps {
        sh '''
          az acr login --name "$ACR_NAME"
          IMAGE="$ACR_NAME.azurecr.io/jenkins-smoke:$BUILD_NUMBER"
          printf 'FROM busybox:1.37\\nCMD ["echo","polaris smoke test"]\\n' | docker build -t "$IMAGE" -
          docker push "$IMAGE"
          docker rmi "$IMAGE"
        '''
      }
    }

    stage('AKS access') {
      steps {
        sh '''
          az aks get-credentials -g "$RG" -n "$AKS_NAME" --file "$KUBECONFIG" --overwrite-existing
          kubectl get nodes -o wide
          kubectl get namespaces -l project=polaris -L env,pod-security.kubernetes.io/enforce
        '''
      }
    }
  }

  post {
    cleanup {
      cleanWs() // removes the Azure token cache, Docker login and kubeconfig
    }
  }
}
