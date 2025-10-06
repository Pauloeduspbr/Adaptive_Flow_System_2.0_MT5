# Prompt para Análise e Correção de Setup Individual

## Objetivo
Este prompt orienta a análise isolada e correção de cada setup do sistema Adaptive Flow System 2.0 para MT5, permitindo identificar e resolver problemas específicos através de backtests individualizados.

## Estrutura do Prompt

### 1. IDENTIFICAÇÃO DO SETUP

**Setup Name:** [Nome do Setup]
**Setup Type:** [Trend Following / Mean Reversion / Breakout / Scalping / etc.]
**Timeframe:** [M1 / M5 / M15 / H1 / H4 / D1]
**Instruments:** [Pares de moedas/ativos onde é aplicado]

---

### 2. CONFIGURAÇÃO ATUAL DO SETUP

#### Parâmetros de Entrada
```
- Indicadores utilizados:
  * Indicador 1: [nome] - Período: [valor] - Configuração: [detalhes]
  * Indicador 2: [nome] - Período: [valor] - Configuração: [detalhes]
  * [adicionar mais conforme necessário]

- Sinais de entrada:
  * Long: [condições específicas]
  * Short: [condições específicas]

- Filtros aplicados:
  * Filtro 1: [descrição]
  * Filtro 2: [descrição]
```

#### Parâmetros de Gerenciamento de Risco
```
- Stop Loss: [tipo e valor]
- Take Profit: [tipo e valor]
- Trailing Stop: [configuração]
- Tamanho da posição: [método de cálculo]
- Risk/Reward ratio: [valor]
- Max drawdown permitido: [percentual]
```

#### Parâmetros de Tempo
```
- Horários de operação: [início - fim]
- Dias da semana: [quais dias opera]
- Filtros de sessão: [Asian/European/American]
- Tempo máximo em posição: [valor]
```

---

### 3. CONFIGURAÇÃO DO BACKTEST ISOLADO

#### Período de Teste
```
- Data inicial: [DD/MM/YYYY]
- Data final: [DD/MM/YYYY]
- Justificativa do período: [ex: incluir diferentes condições de mercado]
```

#### Condições de Mercado
```
- Spread: [valor médio simulado]
- Comissão: [valor por lote]
- Slippage: [pontos]
- Alavancagem: [valor]
- Depósito inicial: [valor]
```

#### Critérios de Validação
```
- Mínimo de trades: [número]
- Período mínimo: [meses/anos]
- Incluir: [tendência/lateralização/volatilidade alta/baixa]
```

---

### 4. MÉTRICAS ESPERADAS vs OBTIDAS

| Métrica | Esperado | Obtido | Status |
|---------|----------|--------|--------|
| Win Rate | [%] | [%] | ✓/✗ |
| Profit Factor | [valor] | [valor] | ✓/✗ |
| Max Drawdown | [%] | [%] | ✓/✗ |
| Risk/Reward Ratio | [valor] | [valor] | ✓/✗ |
| Total Trades | [número] | [número] | ✓/✗ |
| Sharpe Ratio | [valor] | [valor] | ✓/✗ |
| Recovery Factor | [valor] | [valor] | ✓/✗ |
| Expectativa Matemática | [valor] | [valor] | ✓/✗ |

---

### 5. ANÁLISE DE PROBLEMAS IDENTIFICADOS

#### 5.1 Problemas de Performance
```
□ Win rate abaixo do esperado
  - Causa possível:
  - Evidência no backtest:
  
□ Drawdown excessivo
  - Causa possível:
  - Evidência no backtest:
  
□ Profit factor baixo
  - Causa possível:
  - Evidência no backtest:
  
□ Muitas operações perdedoras consecutivas
  - Causa possível:
  - Evidência no backtest:
```

#### 5.2 Problemas de Sinalização
```
□ Sinais falsos frequentes
  - Condição específica:
  - Frequência:
  
□ Entradas atrasadas
  - Condição específica:
  - Impacto no resultado:
  
□ Saídas prematuras
  - Condição específica:
  - Lucro deixado na mesa:
```

#### 5.3 Problemas de Gerenciamento de Risco
```
□ Stop Loss sendo atingido com frequência
  - Análise:
  - Percentual de stops:
  
□ Take Profit muito próximo ou muito distante
  - Análise:
  - Otimização sugerida:
  
□ Sizing de posição inadequado
  - Análise:
  - Correção proposta:
```

#### 5.4 Problemas de Adaptação ao Mercado
```
□ Performance ruim em mercados laterais
  - Evidência:
  - Filtro necessário:
  
□ Performance ruim em tendências
  - Evidência:
  - Ajuste necessário:
  
□ Sensibilidade à volatilidade
  - Evidência:
  - Adaptação proposta:
```

---

### 6. PLANO DE CORREÇÃO PROPOSTO

#### Correção Prioritária 1
```
Problema: [descrição clara do problema]
Causa raiz: [análise da causa]
Solução proposta: [mudança específica]
Parâmetros a ajustar:
  - [parâmetro 1]: de [valor atual] para [valor novo]
  - [parâmetro 2]: de [valor atual] para [valor novo]
Resultado esperado: [métrica específica]
```

#### Correção Prioritária 2
```
Problema: [descrição clara do problema]
Causa raiz: [análise da causa]
Solução proposta: [mudança específica]
Parâmetros a ajustar:
  - [parâmetro 1]: de [valor atual] para [valor novo]
  - [parâmetro 2]: de [valor atual] para [valor novo]
Resultado esperado: [métrica específica]
```

#### Correção Prioritária 3
```
Problema: [descrição clara do problema]
Causa raiz: [análise da causa]
Solução proposta: [mudança específica]
Parâmetros a ajustar:
  - [parâmetro 1]: de [valor atual] para [valor novo]
  - [parâmetro 2]: de [valor atual] para [valor novo]
Resultado esperado: [métrica específica]
```

---

### 7. VALIDAÇÃO PÓS-CORREÇÃO

#### Novo Backtest com Correções
```
- Período: [mesmo período do teste anterior]
- Condições: [mantidas idênticas]
- Mudanças aplicadas: [lista de mudanças]
```

#### Comparação de Resultados

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Win Rate | [%] | [%] | [%] |
| Profit Factor | [valor] | [valor] | [%] |
| Max Drawdown | [%] | [%] | [%] |
| Total Trades | [número] | [número] | [%] |
| Expectativa | [valor] | [valor] | [%] |

#### Status da Correção
```
□ Problema resolvido completamente
□ Problema parcialmente resolvido - requer iteração adicional
□ Problema persiste - análise mais profunda necessária
```

---

### 8. PRÓXIMOS PASSOS

```
1. [ ] Teste em forward test (dados fora da amostra)
2. [ ] Validação em diferentes condições de mercado
3. [ ] Integração com outros setups do sistema
4. [ ] Teste em conta demo
5. [ ] Documentar lições aprendidas
```

---

## NOTAS IMPORTANTES

### Boas Práticas
- Testar apenas UMA mudança por vez
- Manter registro detalhado de todas as mudanças
- Usar sempre os mesmos dados para comparação
- Validar em período out-of-sample
- Documentar razões para cada ajuste

### Alertas
⚠️ Evitar over-optimization (curve fitting)
⚠️ Manter coerência com a estratégia original
⚠️ Considerar custos operacionais realistas
⚠️ Validar robustez em diferentes períodos
⚠️ Não buscar 100% win rate (impossível e perigoso)

### Critérios de Sucesso
✓ Win rate >= [valor mínimo aceitável]
✓ Profit factor >= 1.5
✓ Max drawdown <= [valor máximo aceitável]
✓ Consistência entre períodos
✓ Risk/reward >= 1:1.5

---

## TEMPLATE DE REPORT FINAL

```
SETUP: [Nome]
DATA DA ANÁLISE: [DD/MM/YYYY]
ANALISTA: [Nome]

RESUMO EXECUTIVO:
[Breve descrição dos problemas encontrados e soluções implementadas]

PROBLEMAS IDENTIFICADOS:
1. [Problema 1]
2. [Problema 2]
3. [Problema 3]

CORREÇÕES APLICADAS:
1. [Correção 1]
2. [Correção 2]
3. [Correção 3]

RESULTADOS:
- Performance melhorou em [X]%
- Drawdown reduzido em [X]%
- Win rate [aumentou/diminuiu] em [X]%

STATUS: [APROVADO / REQUER MAIS TRABALHO / REJEITADO]

RECOMENDAÇÕES:
[Lista de recomendações para uso do setup]
```
