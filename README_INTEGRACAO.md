# Gestão de PI IFSC — versão integrada

Esta versão mantém os módulos e melhorias de `Gestao_PI_IFSC_corrigido` e corrige o registro de pagamentos para a estrutura de banco deste projeto.

## O que foi integrado/corrigido
- Registro de pagamento e marcação **Não Pagar** usando `anuidades.numero_patente` (não usa `anuidades.patente_id`).
- Atualização/criação do registro de anuidade por `numero_patente + numero_anuidade`.
- Campo opcional de valor pago no registro.
- Salvamento do ano do pagamento (`ano_pagamento`) a partir da data informada.
- Relatório anual FORMICT baseado nos pagamentos efetivamente registrados.
- Mantidos os módulos existentes, incluindo Parecer de Patenteabilidade, assistente jurídico NIT, relatórios e recursos de gestão.

## Instalação
1. Faça backup do projeto/banco antes de publicar.
2. No Supabase do projeto que será usado por esta versão, abra **SQL Editor** e execute `SQL_MIGRACAO_PAGAMENTOS_FORMICT.sql`.
3. Configure os Secrets no Streamlit Cloud. Use a URL e a chave do mesmo projeto Supabase:
   - `SUPABASE_URL`
   - `SUPABASE_SECRET_KEY` (preferível no backend) ou a chave que sua configuração atual utiliza.
4. Publique os arquivos deste ZIP no repositório do app e reinicie/redeploy.
5. Em **Gerenciar PIs**, teste primeiro com uma PI de teste: marcar **Não Pagar**, depois registrar pagamento com data e valor.
6. Abra **Relatórios FORMICT**, selecione o ano do pagamento e confira o registro.

## Observações importantes
- Os dois projetos originais apontavam para bancos/estruturas diferentes. Não misture a URL/chave de um projeto com o esquema do outro.
- O SQL adiciona colunas se ainda não existirem e cria a view usada pelo relatório; ele não migra automaticamente pagamentos armazenados no outro banco.
- A view inclui apenas registros com status `pago` e data de pagamento. Marcar **Não Pagar** não gera linha de pagamento no FORMICT.
- O campo `valor` é opcional; se ficar em R$ 0,00, o app envia valor nulo e o pagamento continua registrando data/ano.
