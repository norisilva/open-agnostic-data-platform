# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Consistência Eventual no CQRS Híbrido
# Domínio: Plataforma Agnóstica / Data Engineering
# Autor: Time de Engenharia
# =============================================================================

Funcionalidade: Sincronização Assíncrona CQRS (Postgres para Mongo via CDC)
  Como o arquiteto da plataforma
  Quero garantir que a gravação ocorra unicamente no PostgreSQL e a leitura no MongoDB
  Para maximizar a performance de escrita e leitura enquanto aceitamos a consistência eventual

  Contexto:
    Dado que a plataforma utiliza o "CommandRepository" para o PostgreSQL (Write)
    E utiliza o "QueryRepository" para o MongoDB (Read)
    E existe um worker de CDC propagando eventos do Postgres para o RabbitMQ

  Cenário: Escrita bem sucedida é propagada para o Read Model após breve delay
    Dado que o usuário envia um POST para criar um evento/renegociação válido
    Quando o serviço processa a requisição
    Então o "CommandRepository" deve iniciar uma transação ACID
    E o registro deve ser inserido no PostgreSQL com sucesso
    E a API deve retornar imediatamente o HTTP Status 202 (Accepted)
    
    # Validação da Consistência Eventual
    Quando o cliente faz um GET na API de leitura imediatamente
    Então a API consulta o "QueryRepository"
    E o registro PODE ainda não estar presente no MongoDB (dependendo da latência em ms)
    
    Quando o pipeline de CDC captura a alteração do Postgres
    E o evento trafega pela mensageria (RabbitMQ)
    E o worker de sincronização (Go CDC Sync) processa a mensagem
    E salva o documento JSON desnormalizado (upsert) no MongoDB
    
    Então uma nova consulta GET na API (após Awaitility/Polling de ~500ms)
    Deve retornar HTTP 200 (OK)
    E o payload deve conter o documento JSON formatado e idêntico à intenção original gravada no Postgres
