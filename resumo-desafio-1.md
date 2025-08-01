# 📋 Resumo dos Serviços AWS - Projeto BIA
## Primeiro Desafio - Imersão AWS & IA

---

## 🖥️ **SERVIÇOS AWS ATIVOS**

### **1. Amazon EC2**
- **Instância:** `i-056e775ab8dbb6af9`
- **Tipo:** `t3.micro`
- **Nome:** `bia-dev`
- **Status:** `running` ✅
- **IP Público:** `3.222.188.117`
- **IP Privado:** `172.31.15.194`
- **Zona:** `us-east-1a`
- **Função:** Servidor de desenvolvimento para hospedar a aplicação BIA

### **2. Amazon VPC**
- **VPC ID:** `vpc-002c6c0ed6fd320c9`
- **Subnet:** `subnet-099f5680c842daa6a`
- **Função:** Rede virtual isolada para os recursos

### **3. Security Group**
- **Nome:** `bia-dev`
- **ID:** `sg-06108a4c754c7137d`
- **Regras de Entrada:**
  - Porta `3001` - Acesso público (API Backend)
  - Porta `3002` - Acesso público (Frontend React)
- **Função:** Controle de acesso de rede

---

## 🐳 **INFRAESTRUTURA DOCKER**

### **Containers Ativos:**

#### **1. bia-server (Backend)**
- **Container:** `bia`
- **Imagem:** `bia-server`
- **Status:** `Up 2 hours` ✅
- **Porta:** `3001:8080` (Host:Container)
- **Função:** API Backend Node.js/Express
- **Variáveis de Ambiente:**
  - `DB_USER=postgres`
  - `DB_PWD=postgres`
  - `DB_HOST=database`
  - `DB_PORT=5432`

#### **2. postgres:16.1 (Banco de Dados)**
- **Container:** `database`
- **Imagem:** `postgres:16.1`
- **Status:** `Up 2 hours` ✅
- **Porta:** `5433:5432` (Host:Container)
- **Função:** Banco de dados PostgreSQL
- **Variáveis de Ambiente:**
  - `POSTGRES_USER=postgres`
  - `POSTGRES_PASSWORD=postgres`
  - `POSTGRES_DB=bia`
- **Volume:** `bia_db` (persistência de dados)

#### **3. bia-app:latest (Frontend)**
- **Container:** `bia-container`
- **Imagem:** `bia-app:latest`
- **Status:** `Up 23 minutes (healthy)` ✅
- **Porta:** `3002:3002` (Host:Container)
- **Função:** Frontend React com Vite

### **Rede Docker:**
- **Network:** `bia_default` (bridge)
- **Comunicação:** Containers se comunicam via nomes de serviço
- **Isolamento:** Rede isolada para os containers da aplicação

### **Volumes:**
- **Volume:** `bia_db`
- **Função:** Persistência dos dados do PostgreSQL
- **Localização:** `/var/lib/postgresql/data`

### **Orquestração:**
- **Docker Compose:** `compose.yml`
- **Serviços Definidos:** `server`, `database`
- **Links:** Backend conectado ao banco via `database` hostname

---

## 🌐 **APLICAÇÃO FUNCIONANDO**

### **Endpoints Ativos:**
- **API Backend:** `http://3.222.188.117:3001/api/versao`
- **Frontend React:** `http://3.222.188.117:3002`
- **Banco PostgreSQL:** `3.222.188.117:5433`
- **Versão:** `Bia 4.2.0` ✅

### **Health Checks:**
- **Backend:** Respondendo na porta 3001 ✅
- **Frontend:** Container healthy ✅
- **Database:** Conectado e funcionando ✅

---

## 📁 **ESTRUTURA DO PROJETO**

```
/home/ec2-user/bia/
├── 📂 api/                    # APIs do backend (Node.js/Express)
├── 📂 client/                 # Aplicação React (Frontend)
├── 📂 config/                 # Configurações da aplicação
├── 📂 database/               # Migrations e seeds do Sequelize
├── 📂 scripts/                # Scripts auxiliares
├── 📂 tests/                  # Testes unitários (Jest)
├── 📂 docs/                   # Documentação do projeto
├── 📂 .amazonq/               # Regras e contexto do Amazon Q
│   └── 📂 rules/              # Regras específicas (dockerfile, infraestrutura, pipeline)
├── 📄 compose.yml             # Docker Compose (orquestração)
├── 📄 Dockerfile              # Container da aplicação
├── 📄 buildspec.yml           # AWS CodeBuild (CI/CD)
├── 📄 package.json            # Dependências Node.js
├── 📄 README.md               # Documentação principal
└── 📄 AmazonQ.md              # Contexto e análise do projeto
```

### **Stack Tecnológica:**
- **Frontend:** React 17.0.2 + Vite + React Router DOM
- **Backend:** Node.js + Express 4.17.1 + Sequelize ORM
- **Banco:** PostgreSQL 16.1
- **Containerização:** Docker + Docker Compose
- **AWS SDK:** Integrado (Secrets Manager, STS)

---

## 📊 **ARQUITETURA COMPLETA**

```
Internet (0.0.0.0/0)
    ↓
Security Group (bia-dev)
    ↓ (portas 3001, 3002)
EC2 Instance (t3.micro)
    ↓
Docker Engine
    ↓
bia_default Network (bridge)
    ├── bia-container:3002 (Frontend React)
    ├── bia:3001→8080 (Backend Node.js)
    └── database:5433→5432 (PostgreSQL)
         ↓
    Volume: bia_db (persistência)
```

### **Fluxo de Comunicação:**
1. **Cliente** → **Security Group** (portas 3001/3002)
2. **EC2** → **Docker Network** (bia_default)
3. **Frontend** → **Backend** (via network interna)
4. **Backend** → **Database** (hostname: database:5432)

---

## ⚙️ **CONFIGURAÇÕES DOCKER**

### **Mapeamento de Portas:**
| Serviço | Container | Host | Protocolo | Função |
|---------|-----------|------|-----------|---------|
| Frontend | 3002 | 3002 | TCP | Interface React |
| Backend | 8080 | 3001 | TCP | API Node.js |
| Database | 5432 | 5433 | TCP | PostgreSQL |

### **Variáveis de Ambiente:**
- **Backend:** Configurado para ambiente de desenvolvimento
- **Database:** Credenciais padrão (postgres/postgres)
- **Network:** Comunicação interna via hostnames

---

## ✅ **STATUS GERAL**
- **Infraestrutura AWS:** Operacional ✅
- **Containers Docker:** Todos rodando ✅
- **Aplicação BIA:** Funcionando ✅
- **Conectividade:** Backend ↔ Database ✅
- **Acesso Público:** Configurado ✅
- **Health Checks:** Passando ✅

**Data/Hora:** 30/07/2025 - 21:00 UTC  
**Região AWS:** us-east-1 (N. Virginia)  
**Repositório:** https://github.com/henrylle/bia

---

Este resumo mostra uma infraestrutura AWS completa com aplicação BIA containerizada, incluindo todos os detalhes de Docker, portas, redes e volumes - perfeito para o primeiro desafio da Imersão AWS & IA! 🚀
