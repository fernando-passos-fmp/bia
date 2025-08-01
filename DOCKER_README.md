# 🐳 Containerização da Aplicação BIA

Este documento descreve como a aplicação BIA foi containerizada usando Docker, incluindo o frontend React com Vite e o backend Node.js.

## 📋 Visão Geral

A aplicação BIA é composta por:
- **Frontend**: React 18 com Vite como bundler
- **Backend**: Node.js com Express
- **Banco de Dados**: PostgreSQL 16.1

## 🏗️ Arquitetura da Containerização

### Multi-stage Build
O Dockerfile utiliza uma estratégia de multi-stage build para otimizar o tamanho da imagem final:

1. **Stage Builder**: Instala dependências e constrói o frontend React
2. **Stage Production**: Copia apenas os arquivos necessários para produção

### Variáveis de Ambiente do Vite

As seguintes variáveis de ambiente são configuradas para o Vite:
- `VITE_API_URL=http://localhost:3002` - URL da API backend
- `VITE_DEBUG_MODE=false` - Modo de debug desabilitado
- `VITE_APP_NAME=BIA` - Nome da aplicação
- `VITE_APP_VERSION=4.2.0` - Versão da aplicação

## 🚀 Como Executar

### Opção 1: Script de Deploy Automatizado (Recomendado)
```bash
./deploy.sh
```

### Opção 2: Docker Compose
```bash
# Iniciar todos os serviços
docker-compose -f docker-compose.production.yml up -d

# Parar todos os serviços
docker-compose -f docker-compose.production.yml down
```

### Opção 3: Docker Manual
```bash
# Construir a imagem
docker build -f Dockerfile.optimized -t bia-app:latest .

# Executar o container
docker run -d --name bia-container -p 3002:3002 bia-app:latest
```

## 🔧 Configuração

### Portas
- **Aplicação**: 3002
- **Banco de Dados**: 5433 (mapeado para 5432 interno)

### Variáveis de Ambiente
```env
NODE_ENV=production
PORT=3002
VITE_API_URL=http://localhost:3002
VITE_DEBUG_MODE=false
DB_HOST=database
DB_PORT=5432
DB_NAME=bia
DB_USER=postgres
DB_PASSWORD=postgres
```

## 📁 Arquivos de Containerização

- `Dockerfile.optimized` - Dockerfile principal com multi-stage build
- `docker-compose.production.yml` - Orquestração dos serviços
- `.dockerignore.optimized` - Arquivos ignorados no build
- `.env.production` - Variáveis de ambiente para produção
- `deploy.sh` - Script automatizado de deploy

## 🔍 Monitoramento

### Health Checks
Ambos os serviços possuem health checks configurados:
- **App**: Verifica se a aplicação responde na porta 3002
- **Database**: Verifica se o PostgreSQL está aceitando conexões

### Logs
```bash
# Ver logs de todos os serviços
docker-compose -f docker-compose.production.yml logs -f

# Ver logs apenas da aplicação
docker-compose -f docker-compose.production.yml logs -f app

# Ver logs apenas do banco
docker-compose -f docker-compose.production.yml logs -f database
```

## 🛡️ Segurança

- Container executa com usuário não-root (`appuser`)
- Imagem baseada em `node:18-slim` para menor superfície de ataque
- Apenas portas necessárias são expostas
- Dependências de desenvolvimento são removidas na imagem final

## 📊 Otimizações Implementadas

1. **Multi-stage build** - Reduz tamanho da imagem final
2. **Cache de layers** - Melhora velocidade de builds subsequentes
3. **Usuário não-root** - Melhora segurança
4. **Health checks** - Monitora saúde dos serviços
5. **Volumes persistentes** - Dados do banco não são perdidos
6. **Network isolation** - Serviços comunicam via rede Docker interna

## 🧪 Testes

### Verificar se a aplicação está funcionando
```bash
# Testar página principal
curl http://localhost:3002

# Testar API de versão
curl http://localhost:3002/api/versao

# Verificar health check
docker inspect bia-app-container --format='{{.State.Health.Status}}'
```

## 🔧 Troubleshooting

### Container não inicia
```bash
# Verificar logs
docker logs bia-app-container

# Verificar se a porta está em uso
lsof -i :3002
```

### Problemas de conexão com banco
```bash
# Verificar se o banco está rodando
docker-compose -f docker-compose.production.yml ps database

# Testar conexão com banco
docker exec -it bia-database psql -U postgres -d bia
```

### Rebuild completo
```bash
# Parar tudo e limpar
docker-compose -f docker-compose.production.yml down -v
docker system prune -f

# Rebuild e restart
./deploy.sh
```

## 📈 Métricas da Imagem

- **Tamanho da imagem final**: ~200MB (otimizada)
- **Tempo de build**: ~2-3 minutos
- **Tempo de startup**: ~10-15 segundos
- **Uso de memória**: ~100-150MB em runtime

## 🎯 Próximos Passos

- [ ] Implementar CI/CD pipeline
- [ ] Adicionar monitoramento com Prometheus
- [ ] Configurar backup automático do banco
- [ ] Implementar SSL/TLS
- [ ] Adicionar testes automatizados no pipeline
