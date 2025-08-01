#!/bin/bash

# Script de Deploy ECS - Projeto BIA
# Autor: Amazon Q
# Versão: 1.0

set -e

# Configurações padrão
DEFAULT_REGION="us-east-1"
DEFAULT_CLUSTER="bia-cluster-alb"
DEFAULT_SERVICE="bia-service"
DEFAULT_TASK_FAMILY="bia-tf"
DEFAULT_ECR_REPO="bia"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir help
show_help() {
    echo -e "${BLUE}=== Script de Deploy ECS - Projeto BIA ===${NC}"
    echo ""
    echo -e "${YELLOW}DESCRIÇÃO:${NC}"
    echo "  Este script automatiza o processo de build e deploy da aplicação BIA no ECS."
    echo "  Cada build gera uma imagem com tag baseada no commit hash atual, permitindo"
    echo "  rollbacks para versões anteriores."
    echo ""
    echo -e "${YELLOW}USO:${NC}"
    echo "  ./deploy.sh [OPÇÕES] COMANDO"
    echo ""
    echo -e "${YELLOW}COMANDOS:${NC}"
    echo "  build     - Faz build da imagem Docker e push para ECR"
    echo "  deploy    - Cria nova task definition e atualiza o serviço ECS"
    echo "  full      - Executa build + deploy em sequência"
    echo "  rollback  - Faz rollback para uma versão anterior"
    echo "  list      - Lista as últimas 10 versões disponíveis"
    echo "  help      - Exibe esta ajuda"
    echo ""
    echo -e "${YELLOW}OPÇÕES:${NC}"
    echo "  -r, --region REGION        Região AWS (padrão: $DEFAULT_REGION)"
    echo "  -c, --cluster CLUSTER      Nome do cluster ECS (padrão: $DEFAULT_CLUSTER)"
    echo "  -s, --service SERVICE      Nome do serviço ECS (padrão: $DEFAULT_SERVICE)"
    echo "  -f, --family FAMILY        Família da task definition (padrão: $DEFAULT_TASK_FAMILY)"
    echo "  -e, --ecr-repo REPO        Nome do repositório ECR (padrão: $DEFAULT_ECR_REPO)"
    echo "  -t, --tag TAG              Tag específica para rollback"
    echo "  -h, --help                 Exibe esta ajuda"
    echo ""
    echo -e "${YELLOW}EXEMPLOS:${NC}"
    echo "  ./deploy.sh full                    # Build e deploy completo"
    echo "  ./deploy.sh build                   # Apenas build da imagem"
    echo "  ./deploy.sh deploy                  # Apenas deploy (usa última imagem)"
    echo "  ./deploy.sh rollback -t abc123      # Rollback para tag específica"
    echo "  ./deploy.sh list                    # Lista versões disponíveis"
    echo ""
    echo -e "${YELLOW}PRÉ-REQUISITOS:${NC}"
    echo "  - AWS CLI configurado"
    echo "  - Docker instalado e rodando"
    echo "  - Permissões para ECR, ECS e IAM"
    echo "  - Repositório ECR já criado"
    echo ""
    echo -e "${YELLOW}FLUXO DO DEPLOY:${NC}"
    echo "  1. Obtém hash do commit atual (últimos 7 caracteres)"
    echo "  2. Faz build da imagem Docker com tag do commit"
    echo "  3. Faz push da imagem para ECR"
    echo "  4. Cria nova revisão da task definition"
    echo "  5. Atualiza o serviço ECS com a nova task definition"
    echo ""
}

# Função para log colorido
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $*" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $*" ;;
    esac
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log "INFO" "Verificando pré-requisitos..."
    
    # Verificar se está em um repositório git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log "ERROR" "Este diretório não é um repositório Git"
        exit 1
    fi
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        log "ERROR" "AWS CLI não encontrado. Instale o AWS CLI primeiro."
        exit 1
    fi
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
    
    log "INFO" "Pré-requisitos verificados com sucesso"
}

# Função para obter informações da conta AWS
get_aws_info() {
    log "INFO" "Obtendo informações da conta AWS..."
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $REGION)
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha ao obter ID da conta AWS"
        exit 1
    fi
    
    ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"
    log "INFO" "Conta AWS: $AWS_ACCOUNT_ID"
    log "INFO" "ECR URI: $ECR_URI"
}

# Função para obter commit hash
get_commit_hash() {
    COMMIT_HASH=$(git rev-parse --short=7 HEAD)
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha ao obter hash do commit"
        exit 1
    fi
    
    IMAGE_TAG="$COMMIT_HASH"
    FULL_IMAGE_URI="${ECR_URI}:${IMAGE_TAG}"
    
    log "INFO" "Commit hash: $COMMIT_HASH"
    log "INFO" "Image tag: $IMAGE_TAG"
    log "INFO" "Full image URI: $FULL_IMAGE_URI"
}

# Função para fazer login no ECR
ecr_login() {
    log "INFO" "Fazendo login no ECR..."
    
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha no login do ECR"
        exit 1
    fi
    
    log "INFO" "Login no ECR realizado com sucesso"
}

# Função para build da imagem
build_image() {
    log "INFO" "Iniciando build da imagem Docker..."
    
    # Verificar se Dockerfile existe
    if [ ! -f "Dockerfile" ]; then
        log "ERROR" "Dockerfile não encontrado no diretório atual"
        exit 1
    fi
    
    # Build da imagem
    docker build -t $ECR_REPO:$IMAGE_TAG -t $ECR_REPO:latest .
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha no build da imagem Docker"
        exit 1
    fi
    
    # Tag para ECR
    docker tag $ECR_REPO:$IMAGE_TAG $FULL_IMAGE_URI
    docker tag $ECR_REPO:latest ${ECR_URI}:latest
    
    log "INFO" "Build da imagem concluído com sucesso"
}

# Função para push da imagem
push_image() {
    log "INFO" "Fazendo push da imagem para ECR..."
    
    docker push $FULL_IMAGE_URI
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha no push da imagem para ECR"
        exit 1
    fi
    
    docker push ${ECR_URI}:latest
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha no push da tag latest para ECR"
        exit 1
    fi
    
    log "INFO" "Push da imagem concluído com sucesso"
}

# Função para obter task definition atual
get_current_task_definition() {
    log "INFO" "Obtendo task definition atual..."
    
    CURRENT_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --region $REGION --query 'taskDefinition' --output json)
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha ao obter task definition atual"
        exit 1
    fi
    
    log "INFO" "Task definition atual obtida com sucesso"
}

# Função para criar nova task definition
create_task_definition() {
    log "INFO" "Criando nova task definition..."
    
    # Remover campos que não devem ser incluídos na nova task definition
    NEW_TASK_DEF=$(echo $CURRENT_TASK_DEF | jq --arg IMAGE "$FULL_IMAGE_URI" '
        del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy) |
        .containerDefinitions[0].image = $IMAGE
    ')
    
    # Salvar nova task definition em arquivo temporário
    echo $NEW_TASK_DEF > /tmp/new-task-definition.json
    
    # Registrar nova task definition
    NEW_TASK_DEF_ARN=$(aws ecs register-task-definition --region $REGION --cli-input-json file:///tmp/new-task-definition.json --query 'taskDefinition.taskDefinitionArn' --output text)
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha ao registrar nova task definition"
        exit 1
    fi
    
    # Limpar arquivo temporário
    rm -f /tmp/new-task-definition.json
    
    log "INFO" "Nova task definition criada: $NEW_TASK_DEF_ARN"
}

# Função para atualizar serviço ECS
update_service() {
    log "INFO" "Atualizando serviço ECS..."
    
    aws ecs update-service --region $REGION --cluster $CLUSTER --service $SERVICE --task-definition $NEW_TASK_DEF_ARN > /dev/null
    if [ $? -ne 0 ]; then
        log "ERROR" "Falha ao atualizar serviço ECS"
        exit 1
    fi
    
    log "INFO" "Serviço ECS atualizado com sucesso"
    log "INFO" "Aguardando estabilização do serviço..."
    
    aws ecs wait services-stable --region $REGION --cluster $CLUSTER --services $SERVICE
    if [ $? -ne 0 ]; then
        log "WARN" "Timeout aguardando estabilização do serviço"
    else
        log "INFO" "Serviço estabilizado com sucesso"
    fi
}

# Função para listar versões disponíveis
list_versions() {
    log "INFO" "Listando últimas 10 versões disponíveis..."
    
    aws ecr describe-images --repository-name $ECR_REPO --region $REGION --query 'sort_by(imageDetails,&imagePushedAt)[-10:].[imageTags[0],imagePushedAt]' --output table
}

# Função para rollback
rollback() {
    if [ -z "$ROLLBACK_TAG" ]; then
        log "ERROR" "Tag para rollback não especificada. Use -t ou --tag"
        exit 1
    fi
    
    log "INFO" "Iniciando rollback para tag: $ROLLBACK_TAG"
    
    # Verificar se a imagem existe
    aws ecr describe-images --repository-name $ECR_REPO --region $REGION --image-ids imageTag=$ROLLBACK_TAG > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "Imagem com tag $ROLLBACK_TAG não encontrada no ECR"
        exit 1
    fi
    
    # Definir URI da imagem para rollback
    FULL_IMAGE_URI="${ECR_URI}:${ROLLBACK_TAG}"
    IMAGE_TAG=$ROLLBACK_TAG
    
    log "INFO" "Imagem para rollback: $FULL_IMAGE_URI"
    
    # Executar deploy com a imagem específica
    get_current_task_definition
    create_task_definition
    update_service
    
    log "INFO" "Rollback concluído com sucesso"
}

# Função principal de build
do_build() {
    log "INFO" "=== INICIANDO BUILD ==="
    check_prerequisites
    get_aws_info
    get_commit_hash
    ecr_login
    build_image
    push_image
    log "INFO" "=== BUILD CONCLUÍDO ==="
}

# Função principal de deploy
do_deploy() {
    log "INFO" "=== INICIANDO DEPLOY ==="
    check_prerequisites
    get_aws_info
    
    # Se não temos IMAGE_TAG definida, usar a última imagem
    if [ -z "$IMAGE_TAG" ]; then
        get_commit_hash
        FULL_IMAGE_URI="${ECR_URI}:${IMAGE_TAG}"
    fi
    
    get_current_task_definition
    create_task_definition
    update_service
    log "INFO" "=== DEPLOY CONCLUÍDO ==="
}

# Função principal completa
do_full() {
    log "INFO" "=== INICIANDO DEPLOY COMPLETO ==="
    do_build
    do_deploy
    log "INFO" "=== DEPLOY COMPLETO CONCLUÍDO ==="
}

# Inicializar variáveis com valores padrão
REGION=$DEFAULT_REGION
CLUSTER=$DEFAULT_CLUSTER
SERVICE=$DEFAULT_SERVICE
TASK_FAMILY=$DEFAULT_TASK_FAMILY
ECR_REPO=$DEFAULT_ECR_REPO

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -f|--family)
            TASK_FAMILY="$2"
            shift 2
            ;;
        -e|--ecr-repo)
            ECR_REPO="$2"
            shift 2
            ;;
        -t|--tag)
            ROLLBACK_TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        build|deploy|full|rollback|list|help)
            COMMAND="$1"
            shift
            ;;
        *)
            log "ERROR" "Opção desconhecida: $1"
            echo "Use './deploy.sh help' para ver as opções disponíveis"
            exit 1
            ;;
    esac
done

# Verificar se comando foi especificado
if [ -z "$COMMAND" ]; then
    log "ERROR" "Comando não especificado"
    echo "Use './deploy.sh help' para ver os comandos disponíveis"
    exit 1
fi

# Executar comando
case $COMMAND in
    build)
        do_build
        ;;
    deploy)
        do_deploy
        ;;
    full)
        do_full
        ;;
    rollback)
        rollback
        ;;
    list)
        check_prerequisites
        get_aws_info
        list_versions
        ;;
    help)
        show_help
        ;;
    *)
        log "ERROR" "Comando desconhecido: $COMMAND"
        echo "Use './deploy.sh help' para ver os comandos disponíveis"
        exit 1
        ;;
esac
