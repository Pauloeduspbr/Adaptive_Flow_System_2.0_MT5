# Workflow Checklist - Análise Individual de Setup

Este checklist guia você através de todo o processo de análise, correção e validação de um setup individual.

---

## 🎯 FASE 1: PREPARAÇÃO

### 1.1 Ambiente
```
□ MetaTrader 5 instalado e atualizado
□ Conta demo/real configurada
□ Broker com dados históricos de qualidade
□ EA do setup compilado sem erros
□ Espaço em disco suficiente (> 1GB)
□ Conexão estável com internet
```

### 1.2 Dados Históricos
```
□ Dados baixados para período mínimo de 1 ano
□ Preferível: 2-3 anos de dados
□ Timeframes necessários disponíveis:
  □ M1 (se setup usar)
  □ M5 (se setup usar)
  □ M15 (se setup usar)
  □ H1 (se setup usar)
  □ H4 (se setup usar)
  □ D1 (se setup usar)
□ Verificado integridade (sem gaps grandes)
□ Dados incluem diferentes condições:
  □ Tendências de alta
  □ Tendências de baixa
  □ Períodos laterais
  □ Alta volatilidade
  □ Baixa volatilidade
```

### 1.3 Documentação Preparada
```
□ Cópia do SETUP_ANALYSIS_PROMPT.md pronta
□ Pasta criada para salvar resultados
□ Nomenclatura definida: Setup_[Nome]_[Data]
□ Spreadsheet/documento para anotar métricas
```

**Tempo estimado:** 30 minutos  
**Status:** [ ] Completo

---

## 🔧 FASE 2: CONFIGURAÇÃO DO BACKTEST

### 2.1 Isolamento do Setup
```
□ Código do EA aberto no MetaEditor
□ Identificados todos os setups no código
□ Setup alvo marcado como Enable = true
□ Todos os outros setups marcados como Enable = false
□ Código compilado sem erros
□ Compilado com warnings verificados
□ Salvo como [Setup]_Isolated.ex5
```

### 2.2 Strategy Tester - Configuração Básica
```
□ Strategy Tester aberto (Ctrl+R)
□ EA isolado selecionado
□ Symbol correto selecionado
□ Period (timeframe) correto selecionado
□ Deposit inicial definido (ex: $10,000)
□ Leverage configurado (ex: 1:100)
□ Date range definido (From/To)
```

### 2.3 Strategy Tester - Configuração Avançada
```
□ Execution mode selecionado:
  □ Every tick based on real ticks (recomendado)
  □ 1 minute OHLC (alternativa)
  □ Open prices only (não recomendado)
□ Forward testing: Disabled
□ Optimization: Disabled
□ Visual mode: Disabled (para velocidade)
```

### 2.4 Custos Operacionais
```
□ Spread configurado:
  □ Modo: Custom (recomendado)
  □ Valor: Spread médio do broker + margem
□ Comissão configurada:
  □ Valor por lote definido
  □ Baseado em dados reais do broker
□ Slippage considerado no código do EA
```

### 2.5 Parâmetros do Setup
```
□ Inputs do EA verificados
□ Parâmetros de entrada corretos
□ Stop Loss configurado
□ Take Profit configurado
□ Trailing Stop (se aplicável)
□ Filtros ativos/inativos conforme planejado
□ Horários de operação definidos
□ Magic Number único para o setup
```

**Tempo estimado:** 20 minutos  
**Status:** [ ] Completo

---

## ▶️ FASE 3: EXECUÇÃO DO BACKTEST

### 3.1 Pré-Execução
```
□ Todos os itens da Fase 2 completos
□ Configurações revisadas uma última vez
□ Journal do MT5 limpo (para facilitar análise)
□ Nenhum outro EA rodando
□ Backtest anterior finalizado (se houver)
```

### 3.2 Durante Execução
```
□ Backtest iniciado (botão "Start")
□ Progresso sendo monitorado
□ Verificar Journal periodicamente:
  □ Sem erros críticos
  □ Sem "Not enough money"
  □ Sem "Invalid stops"
  □ Mensagens do EA normais
□ Barra de progresso avançando
□ Tempo estimado anotado
```

### 3.3 Pós-Execução
```
□ Backtest completado 100%
□ Nenhum erro crítico no Journal
□ Resultados visíveis na aba "Results"
□ Gráfico de equity visível
□ Balance final calculado
```

**Tempo estimado:** 10 min a 2 horas (depende do período e modo)  
**Status:** [ ] Completo

---

## 📊 FASE 4: COLETA DE RESULTADOS

### 4.1 Métricas Básicas
```
Anotar da aba "Results":

□ Total net profit: $_______
□ Gross profit: $_______
□ Gross loss: $_______
□ Profit factor: _______
□ Expected payoff: $_______

□ Total trades: _______
□ Winning trades: _______ (____%)
□ Losing trades: _______ (____%)
□ Win rate: _______%

□ Largest profit trade: $_______
□ Largest loss trade: $_______
□ Average profit trade: $_______
□ Average loss trade: $_______
□ Average trade: $_______

□ Maximum consecutive wins: _______
□ Maximum consecutive losses: _______
□ Maximal consecutive profit: $_______
□ Maximal consecutive loss: $_______

□ Maximal drawdown: $_______ (______%)
□ Relative drawdown: _______%
```

### 4.2 Análise Visual
```
Verificar no gráfico:

□ Curva de equity crescente/estável/decrescente
□ Equity vs Balance (drawdowns)
□ Períodos de melhor performance
□ Períodos de pior performance
□ Distribuição de trades no tempo
□ Trades agrupados ou espaçados
```

### 4.3 Exportação de Dados
```
□ Report HTML exportado:
  - Botão direito em Results → "Report"
  - Salvo como: Report_[Setup]_[Date].html
  
□ Lista de trades exportada (opcional):
  - Botão direito em Results → "Save as Report"
  - Salvo como: Trades_[Setup]_[Date].csv
  
□ Screenshots capturados:
  - Tela de Results
  - Gráfico de equity
  - Exemplos de trades (se Visual mode)
  
□ Configurações salvas:
  - Inputs do EA
  - Settings do Strategy Tester
  - Salvo como: Config_[Setup]_[Date].txt
```

**Tempo estimado:** 15 minutos  
**Status:** [ ] Completo

---

## 🔍 FASE 5: ANÁLISE DE RESULTADOS

### 5.1 Comparação com Benchmarks
```
Comparar resultados obtidos com esperados:

Métrica           | Esperado | Obtido | Status
------------------|----------|--------|--------
Win Rate          | _____%   | ____% | □ ✓ □ ✗
Profit Factor     | ____     | ____  | □ ✓ □ ✗
Max Drawdown      | _____%   | ____% | □ ✓ □ ✗
Total Trades      | ____     | ____  | □ ✓ □ ✗
Risk/Reward Ratio | ____     | ____  | □ ✓ □ ✗
Sharpe Ratio      | ____     | ____  | □ ✓ □ ✗
Recovery Factor   | ____     | ____  | □ ✓ □ ✗
Expectancy        | ____     | ____  | □ ✓ □ ✗
```

### 5.2 Identificação de Problemas

**Problemas de Performance:**
```
□ Win rate abaixo de 40%
□ Profit factor abaixo de 1.5
□ Drawdown acima de 20%
□ Expectativa negativa
□ Recovery factor baixo
□ Muitas perdas consecutivas (> 5)
```

**Problemas de Sinalização:**
```
□ Sinais falsos frequentes
□ Entradas atrasadas
□ Saídas prematuras
□ Muitos trades em períodos específicos
□ Poucos trades (< 30)
□ Trades muito agrupados
```

**Problemas de Risco:**
```
□ Stop Loss atingido com frequência (> 60%)
□ Take Profit raramente atingido (< 30%)
□ Average Loss >= Average Win
□ Margin call durante teste
□ Sizing de posição inadequado
□ Drawdown sequences muito longas
```

**Problemas de Mercado:**
```
□ Performance ruim em mercado lateral
□ Performance ruim em tendências
□ Sensível à volatilidade
□ Dependente de horário/sessão
□ Problemas em pares específicos
```

### 5.3 Documentação de Problemas
```
Para cada problema identificado, documentar:

Problema #1:
□ Descrição clara: _______________________
□ Evidência nos dados: __________________
□ Frequência: ______ (% ou número de vezes)
□ Impacto: _________ (em $ ou %)
□ Prioridade: □ Alta □ Média □ Baixa

Problema #2:
□ Descrição clara: _______________________
□ Evidência nos dados: __________________
□ Frequência: ______ 
□ Impacto: _________
□ Prioridade: □ Alta □ Média □ Baixa

Problema #3:
□ Descrição clara: _______________________
□ Evidência nos dados: __________________
□ Frequência: ______
□ Impacto: _________
□ Prioridade: □ Alta □ Média □ Baixa
```

**Tempo estimado:** 30 minutos  
**Status:** [ ] Completo

---

## 🛠️ FASE 6: PLANEJAMENTO DE CORREÇÕES

### 6.1 Priorização
```
□ Problemas listados por ordem de impacto
□ Soluções identificadas para top 3 problemas
□ Consulta ao SETUP_TROUBLESHOOTING.md feita
□ Estratégia de correção definida
```

### 6.2 Correção Prioritária #1
```
Problema: ________________________________
Causa raiz: ______________________________
Solução proposta: ________________________

Mudanças no código:
□ Parâmetro 1: de _____ para _____
□ Parâmetro 2: de _____ para _____
□ Adicionar: _____________________________
□ Remover: _______________________________

Resultado esperado:
□ Métrica alvo 1: _________ → _________
□ Métrica alvo 2: _________ → _________
```

### 6.3 Correção Prioritária #2
```
Problema: ________________________________
Causa raiz: ______________________________
Solução proposta: ________________________

Mudanças no código:
□ Parâmetro 1: de _____ para _____
□ Parâmetro 2: de _____ para _____
□ Adicionar: _____________________________

Resultado esperado:
□ Métrica alvo 1: _________ → _________
□ Métrica alvo 2: _________ → _________
```

### 6.4 Correção Prioritária #3
```
Problema: ________________________________
Causa raiz: ______________________________
Solução proposta: ________________________

Mudanças no código:
□ Parâmetro 1: de _____ para _____
□ Parâmetro 2: de _____ para _____
□ Adicionar: _____________________________

Resultado esperado:
□ Métrica alvo 1: _________ → _________
□ Métrica alvo 2: _________ → _________
```

**Tempo estimado:** 30 minutos  
**Status:** [ ] Completo

---

## ⚙️ FASE 7: IMPLEMENTAÇÃO DE CORREÇÕES

### 7.1 Backup
```
□ Backup do código original criado
□ Versão salva como: [Setup]_v1.0_Original.mq5
□ Backup de resultados anteriores
□ Git commit (se usando controle de versão)
```

### 7.2 Implementação
```
□ Correção #1 implementada no código
□ Código compilado sem erros
□ Warnings verificados e resolvidos
□ Salvo como: [Setup]_v1.1_CorrecaoA.mq5
□ Comentários adicionados no código explicando mudança
```

### 7.3 Teste da Correção
```
□ Novo backtest executado (mesmas condições)
□ Resultados coletados
□ Comparação antes/depois documentada
□ Melhoria confirmada: □ Sim □ Não □ Parcial
```

**IMPORTANTE:** Testar apenas UMA correção por vez!

```
Se melhoria SIM:
□ Manter mudança
□ Considerar integrar próxima correção
□ Salvar versão como base

Se melhoria NÃO:
□ Reverter mudança
□ Analisar por que não funcionou
□ Tentar solução alternativa

Se melhoria PARCIAL:
□ Considerar ajustar parâmetros
□ Pode combinar com outra correção
□ Documentar resultado parcial
```

**Tempo estimado:** 1 hora por correção  
**Status:** [ ] Completo

---

## ✅ FASE 8: VALIDAÇÃO

### 8.1 Backtest com Todas as Correções
```
□ Todas as correções aprovadas implementadas
□ Código compilado final
□ Backtest executado (mesmo período)
□ Resultados coletados
□ Report final exportado
```

### 8.2 Comparação Final

```
ANTES vs DEPOIS:

Métrica              | Antes | Depois | Melhoria
---------------------|-------|--------|----------
Win Rate             | ___% | ___% | ____%
Profit Factor        | ____ | ____ | ____%
Max Drawdown         | ___% | ___% | ____%
Total Trades         | ____ | ____ | ____%
Net Profit           | $____ | $____ | ____%
Average Win          | $____ | $____ | ____%
Average Loss         | $____ | $____ | ____%
Risk/Reward          | ____ | ____ | ____%
Consecutive Losses   | ____ | ____ | ____%
Recovery Factor      | ____ | ____ | ____%
```

### 8.3 Critérios de Aprovação
```
Setup APROVADO se:
□ Win rate >= 40%
□ Profit factor >= 1.5
□ Max drawdown <= 20%
□ Total trades >= 30
□ Expectativa positiva
□ Recovery factor >= 3
□ Métricas consistentes

Status: □ APROVADO □ REPROVADO □ REQUER MAIS TRABALHO
```

### 8.4 Validação Out-of-Sample
```
□ Período diferente selecionado (fora da amostra)
□ Backtest executado em novo período
□ Resultados comparados com in-sample
□ Degradação de performance < 30%
□ Setup mantém métricas mínimas aceitáveis
```

**Tempo estimado:** 1 hora  
**Status:** [ ] Completo

---

## 🔄 FASE 9: PRÓXIMOS PASSOS

### Se Setup APROVADO:

#### 9.1 Forward Test
```
□ Período de forward test definido
□ Forward test executado (dados nunca vistos)
□ Performance monitorada
□ Resultados documentados
□ Setup mantém performance: □ Sim □ Não
```

#### 9.2 Teste em Múltiplos Instrumentos
```
Testar em:
□ Par/instrumento 2: ____________
□ Par/instrumento 3: ____________
□ Par/instrumento 4: ____________
□ Resultados consistentes em todos: □ Sim □ Não
```

#### 9.3 Teste em Conta Demo
```
□ EA instalado em conta demo
□ Período de teste: 30 dias / ___ trades
□ Monitoramento diário
□ Log de trades mantido
□ Performance real vs backtest comparada
□ Slippage real registrado
□ Custos reais registrados
□ Resultado: □ Positivo □ Negativo
```

#### 9.4 Preparação para Real
```
□ Documentação completa finalizada
□ Código revisado e limpo
□ Comentários adequados no código
□ Settings otimizados salvos
□ Plano de gerenciamento de risco definido
□ Capital inicial definido
□ Stop loss de portfólio definido
□ Monitoramento configurado
```

### Se Setup REPROVADO:

#### 9.5 Análise Adicional
```
□ Revisar se todas as correções foram testadas
□ Considerar análise mais profunda
□ Verificar se setup é viável para ativo/timeframe
□ Consultar documentação adicional
□ Considerar:
  □ Mudar timeframe
  □ Mudar instrumento
  □ Combinar com outro setup
  □ Descarte do setup
```

#### 9.6 Decisão Final
```
Após ___ iterações (máx recomendado: 3-5)

□ Setup melhorou substancialmente → Continuar
□ Setup melhorou pouco → Análise adicional
□ Setup não melhorou → Considerar descarte
□ Setup piorou → Descarte

Decisão: □ Continuar □ Pausar □ Descartar
```

**Tempo estimado:** Varia (demo: 30 dias mínimo)  
**Status:** [ ] Completo

---

## 📝 FASE 10: DOCUMENTAÇÃO FINAL

### 10.1 Report Completo
```
□ SETUP_ANALYSIS_PROMPT.md preenchido completo
□ Todas as seções preenchidas
□ Métricas antes/depois documentadas
□ Problemas e soluções listados
□ Report final escrito
□ Status final definido
```

### 10.2 Organização de Arquivos
```
Estrutura de pasta:
□ /Setup_[Nome]/
  □ /Backtest_Initial/
    □ Report_Initial.html
    □ Trades_Initial.csv
    □ Config_Initial.txt
  □ /Backtest_Corrected/
    □ Report_Corrected.html
    □ Trades_Corrected.csv
    □ Config_Corrected.txt
  □ /Code/
    □ [Setup]_v1.0_Original.mq5
    □ [Setup]_v1.5_Corrigido.mq5
  □ /Screenshots/
  □ Analysis_Complete.md
  □ Lessons_Learned.md
```

### 10.3 Lições Aprendidas
```
Documentar:
□ O que funcionou bem
□ O que não funcionou
□ Surpresas encontradas
□ Insights importantes
□ Recomendações para futuros setups
□ Armadilhas a evitar
```

### 10.4 Compartilhamento
```
□ Documentação revisada
□ Resultados verificados
□ Compartilhado com equipe (se aplicável)
□ Adicionado ao repositório de conhecimento
□ Status atualizado em tracking sheet
```

**Tempo estimado:** 1 hora  
**Status:** [ ] Completo

---

## ⏱️ RESUMO DE TEMPO

Estimativa total por setup (primeira iteração):
- Preparação: 30 min
- Configuração: 20 min
- Execução: 30 min - 2 horas
- Análise: 30 min
- Planejamento: 30 min
- Implementação: 1 hora por correção
- Validação: 1 hora
- Documentação: 1 hora

**Total: 4-8 horas** (primeira iteração completa)

Iterações subsequentes: 2-3 horas cada

---

## 🎯 CHECKLIST FINAL DE ENTREGA

Setup pronto para próxima fase quando:
```
□ Todas as 10 fases completas
□ Métricas atingem critérios mínimos
□ Documentação completa
□ Código limpo e comentado
□ Testes out-of-sample positivos
□ Forward test executado
□ Lições documentadas
□ Arquivos organizados
□ Report final aprovado
```

---

## 📋 TRACKING SHEET

| Setup | Data Início | Data Fim | Status | Win Rate | PF | DD | Próximo Passo |
|-------|------------|----------|--------|----------|----|----|---------------|
| RSI   | __/__/____ | __/__/__ | [ ]    | ___%     | __ | __% | _____________ |
| MA    | __/__/____ | __/__/__ | [ ]    | ___%     | __ | __% | _____________ |
| BO    | __/__/____ | __/__/__ | [ ]    | ___%     | __ | __% | _____________ |

**Legenda Status:**
- [ ] Não iniciado
- [P] Em preparação
- [T] Em teste
- [A] Em análise
- [C] Em correção
- [V] Em validação
- [✓] Aprovado
- [✗] Reprovado
- [⏸] Pausado

---

Use este checklist como guia durante todo o processo. Marque cada item conforme completa para não perder o rastro do seu progresso.

**Boa análise! 🚀**
