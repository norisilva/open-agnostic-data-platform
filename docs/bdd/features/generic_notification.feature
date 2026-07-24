# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Serviço de Notificação (Plataforma Core)
# Domínio: Plataforma Agnóstica
# Autor: Time de Engenharia da Plataforma
# =============================================================================

Funcionalidade: Envio de Notificações Genéricas
  Como o serviço central de mensageria (notification-service)
  Quero ler eventos do tipo "notification.requested" e renderizar templates HTML
  Para notificar clientes finais sem precisar conhecer regras de domínio de nenhuma Célula

  Contexto:
    Dado que o "notification-service" está escutando a fila SQS
    E o servidor SMTP (Mailpit/SES) está configurado via variáveis de ambiente

  Cenário: Envio de notificação com sucesso utilizando Template Engine
    Dado que um evento "notification.requested" é consumido da fila
    E o payload do evento especifica o "templateId" como "welcome_email" 
    E o payload fornece um Map de variáveis contendo "nomeUsuario" e "linkAcesso"
    Quando o serviço processa o evento via Virtual Threads
    Então o motor de template (Qute) deve renderizar o HTML final combinando o arquivo base com as variáveis
    E um email deve ser disparado via protocolo SMTP para o endereço "recipient" informado
    E o evento "notification.sent" deve ser publicado confirmando o sucesso da operação
    E o status do envio deve ser salvo de forma agnóstica no banco de dados de log de notificações
