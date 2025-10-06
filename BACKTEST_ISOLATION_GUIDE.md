# Guia de Isolamento de Backtest para Setups Individuais

## Introdução
Este guia fornece instruções detalhadas para configurar e executar backtests isolados de cada setup no MT5, garantindo que cada estratégia seja testada independentemente.

---

## 1. PREPARAÇÃO DO AMBIENTE MT5

### 1.1 Requisitos
- MetaTrader 5 instalado e atualizado
- Dados históricos completos do período de teste
- EA (Expert Advisor) do setup a ser testado
- Acesso ao Strategy Tester do MT5

### 1.2 Download de Dados Históricos
```
1. Abrir MT5
2. Tools → History Center (F2)
3. Selecionar o símbolo desejado
4. Verificar disponibilidade de dados:
   - M1 (1 minuto)
   - M5 (5 minutos)
   - M15 (15 minutos)
   - H1 (1 hora)
   - H4 (4 horas)
   - D1 (diário)
5. Download dos dados faltantes
6. Verificar integridade (gaps e inconsistências)
```

---

## 2. CONFIGURAÇÃO DO STRATEGY TESTER

### 2.1 Acesso ao Strategy Tester
```
Menu: View → Strategy Tester
Atalho: Ctrl + R
```

### 2.2 Configurações Básicas

#### Aba Settings
```
Expert Advisor: [Selecionar o EA do setup específico]
Symbol: [Par de moedas/ativo a testar]
Period: [Timeframe do setup]
Deposit: [Valor do depósito inicial]
Leverage: [Alavancagem - ex: 1:100]
Optimization: [Desabilitado para teste isolado]
```

#### Período de Teste
```
Date: Use date
From: [Data inicial - DD.MM.YYYY]
To: [Data final - DD.MM.YYYY]

Recomendação: Mínimo de 1 ano de dados
Ideal: 2-3 anos incluindo diferentes condições de mercado
```

#### Modo de Execução
```
Execution: [Selecionar conforme necessidade]
  - Every tick based on real ticks (mais preciso, mais lento)
  - 1 minute OHLC (balanço entre precisão e velocidade)
  - Open prices only (rápido, menos preciso)

Recomendação: "Every tick based on real ticks" para análise final
```

---

## 3. ISOLAMENTO DO SETUP

### 3.1 Configuração de Inputs do EA

**IMPORTANTE:** Desabilitar todos os outros setups

```mq5
// Exemplo de configuração de inputs para isolamento

// Setup 1 - RSI Oversold/Overbought
input bool    Enable_Setup_RSI = true;      // ✓ ATIVO
input int     RSI_Period = 14;
input double  RSI_Oversold = 30;
input double  RSI_Overbought = 70;

// Setup 2 - Moving Average Crossover
input bool    Enable_Setup_MA = false;      // ✗ DESATIVADO
input int     MA_Fast_Period = 10;
input int     MA_Slow_Period = 20;

// Setup 3 - Breakout
input bool    Enable_Setup_Breakout = false; // ✗ DESATIVADO
input int     Breakout_Period = 20;

// Setup 4 - Scalping
input bool    Enable_Setup_Scalping = false; // ✗ DESATIVADO
input double  Scalping_Target = 10;

// ... desabilitar TODOS os outros setups
```

### 3.2 Verificação de Isolamento

Antes de iniciar o backtest, verificar:

```
□ Apenas UM setup está ativo (Enable = true)
□ Todos os outros setups estão desativados (Enable = false)
□ Parâmetros do setup ativo estão corretos
□ Gerenciamento de risco está configurado
□ Filtros de horário estão ativos (se aplicável)
```

---

## 4. CONFIGURAÇÃO DE CUSTOS OPERACIONAIS

### 4.1 Spread
```
Menu Strategy Tester → Settings → Symbol
Spread: [Selecionar]
  - Current (usa spread atual - não recomendado)
  - Custom (define spread fixo - recomendado)

Valor recomendado: Spread médio do broker + margem de segurança
Exemplo: Se spread médio é 2 pips, use 3 pips
```

### 4.2 Comissão
```
Commission: [Valor por lote]

Exemplos:
- Forex: $5-7 por lote round turn
- Commodities: Varia por instrumento
- Índices: Varia por broker

Consultar: Especificações do broker
```

### 4.3 Slippage
```
// No código do EA
input int Slippage_Points = 10; // 10 pontos de slippage

// Considerar:
// - Volatilidade do ativo
// - Liquidez
// - Horários de operação
```

---

## 5. EXECUÇÃO DO BACKTEST

### 5.1 Checklist Pré-Execução

```
□ Setup isolado (apenas um ativo)
□ Dados históricos completos
□ Período de teste definido
□ Custos operacionais configurados
□ Inputs do EA verificados
□ Depósito inicial definido
□ Alavancagem configurada
□ Visual mode: OFF (para velocidade)
```

### 5.2 Iniciar Backtest

```
1. Clicar em "Start" no Strategy Tester
2. Aguardar conclusão do teste
3. Não interromper durante execução
4. Observar progresso na barra inferior
```

### 5.3 Monitoramento Durante o Teste

```
Verificar no Journal (aba inferior):
- Erros de execução
- Avisos do sistema
- Mensagens do EA
- Problemas de dados
```

---

## 6. ANÁLISE DOS RESULTADOS

### 6.1 Aba Results

Analisar as seguintes métricas:

```
PERFORMANCE GERAL:
- Total net profit: [Lucro líquido total]
- Gross profit: [Lucro bruto]
- Gross loss: [Perda bruta]
- Profit factor: [Gross profit / Gross loss]

ESTATÍSTICAS DE TRADES:
- Total trades: [Número total de operações]
- Winning trades: [Operações vencedoras]
- Losing trades: [Operações perdedoras]
- Win rate: [% de trades vencedores]

MÉDIAS:
- Average win: [Média de ganho por trade vencedor]
- Average loss: [Média de perda por trade perdedor]
- Average trade: [Média de resultado por trade]
- Risk/Reward ratio: [Average win / Average loss]

DRAWDOWN:
- Maximal drawdown: [Maior perda acumulada]
- Relative drawdown: [% do capital]
- Recovery factor: [Net profit / Max drawdown]

CONSECUTIVOS:
- Maximum consecutive wins: [Maior sequência de vitórias]
- Maximum consecutive losses: [Maior sequência de perdas]
```

### 6.2 Aba Graph

Analisar visualmente:

```
□ Curva de equity (consistência)
□ Balance vs Equity (drawdowns)
□ Distribuição de lucros/perdas
□ Períodos de performance positiva/negativa
```

### 6.3 Aba Report

```
1. Clicar com botão direito na aba Results
2. Selecionar "Report"
3. Salvar relatório HTML
4. Armazenar com nomenclatura: 
   Setup_[Nome]_[Símbolo]_[Período]_[Data].html
```

---

## 7. EXPORTAÇÃO DE DADOS

### 7.1 Exportar Lista de Trades

```
1. Aba Results → botão direito
2. Selecionar "Save as Report"
3. Ou copiar para Excel para análise detalhada
4. Salvar como: Trades_[Setup]_[Data].csv
```

### 7.2 Captura de Gráficos

```
1. Ativar "Visual mode" no Strategy Tester
2. Executar backtest novamente
3. Pausar em pontos importantes
4. File → Save Picture (PrintScreen)
5. Documentar entradas/saídas problemáticas
```

---

## 8. VALIDAÇÃO DO BACKTEST

### 8.1 Checklist de Validação

```
□ Número mínimo de trades atingido (mínimo 30-50)
□ Dados históricos sem gaps significativos
□ Sem erros no Journal do MT5
□ Resultados fazem sentido (não impossíveis)
□ Drawdown dentro do esperado
□ Margem de segurança respeitada (sem margin call)
```

### 8.2 Sinais de Alerta

```
⚠️ Win rate acima de 90% (provável erro)
⚠️ Profit factor acima de 5 (possível curve fitting)
⚠️ Poucos trades (menos de 20)
⚠️ Todos os trades em um curto período
⚠️ Margin call durante o teste
⚠️ Drawdown superior ao depósito
```

---

## 9. DOCUMENTAÇÃO DO TESTE

### 9.1 Template de Documentação

```
===========================================
BACKTEST ISOLADO - SETUP [NOME]
===========================================

DATA DO TESTE: [DD/MM/YYYY]
EXECUTADO POR: [Nome]

CONFIGURAÇÕES:
- Expert Advisor: [Nome e versão]
- Símbolo: [Par/Ativo]
- Timeframe: [Período]
- Período testado: [Data inicial] até [Data final]
- Depósito inicial: $[Valor]
- Alavancagem: [Valor]

CUSTOS OPERACIONAIS:
- Spread: [Pips]
- Comissão: $[Valor] por lote
- Slippage: [Pontos]

PARÂMETROS DO SETUP:
[Listar todos os inputs utilizados]

RESULTADOS PRINCIPAIS:
- Total de trades: [Número]
- Win rate: [%]
- Profit factor: [Valor]
- Max drawdown: [%]
- Net profit: $[Valor]
- Risk/Reward ratio: [Valor]

OBSERVAÇÕES:
[Notas importantes sobre o teste]

PRÓXIMOS PASSOS:
[Ações recomendadas]

ARQUIVOS GERADOS:
- Report HTML: [Caminho/Nome]
- Lista de trades: [Caminho/Nome]
- Screenshots: [Caminho/Pasta]
===========================================
```

### 9.2 Organização de Arquivos

```
Estrutura recomendada:

/Backtests/
  /Setup_RSI/
    /2024-01-15/
      - Report_Setup_RSI_EURUSD_H1_2024-01-15.html
      - Trades_Setup_RSI_EURUSD_H1_2024-01-15.csv
      - Config_Setup_RSI_2024-01-15.txt
      /Screenshots/
        - entry_example_1.png
        - exit_example_1.png
  /Setup_MA_Crossover/
    /2024-01-15/
      - Report_Setup_MA_GBPUSD_M15_2024-01-15.html
      ...
```

---

## 10. COMPARAÇÃO ENTRE TESTES

### 10.1 Teste Base vs Teste Otimizado

```
| Métrica | Teste Base | Teste Otimizado | Diferença |
|---------|-----------|----------------|-----------|
| Trades | [valor] | [valor] | [%] |
| Win Rate | [%] | [%] | [%] |
| Profit Factor | [valor] | [valor] | [%] |
| Max DD | [%] | [%] | [%] |
| Net Profit | $[valor] | $[valor] | [%] |
```

### 10.2 Teste In-Sample vs Out-of-Sample

```
Importante: Validar em período diferente

In-Sample (otimização):
- Período: [datas]
- Resultados: [resumo]

Out-of-Sample (validação):
- Período: [datas]
- Resultados: [resumo]

Degradação aceitável: < 30%
Se degradação > 50% → possível overfitting
```

---

## 11. TROUBLESHOOTING

### Problemas Comuns e Soluções

#### Problema: "Testing agent not found"
```
Solução:
1. Tools → Options → Expert Advisors
2. Habilitar "Allow automated trading"
3. Reiniciar MT5
```

#### Problema: "Not enough money"
```
Solução:
1. Aumentar depósito inicial
2. Reduzir tamanho das posições
3. Ajustar alavancagem
4. Verificar cálculo de lote
```

#### Problema: "No ticks"
```
Solução:
1. Verificar dados históricos (History Center)
2. Redownload dos dados
3. Selecionar modo de execução diferente
4. Verificar período selecionado
```

#### Problema: Backtest muito lento
```
Solução:
1. Desabilitar "Visual mode"
2. Usar modo "Open prices only" para teste rápido
3. Reduzir período de teste
4. Fechar outros programas
5. Usar computador mais potente
```

#### Problema: Resultados irreais
```
Verificar:
□ Spread não está zerado
□ Comissão está configurada
□ Slippage está configurado
□ Tamanho de posição é realista
□ Stop Loss e Take Profit estão ativos
□ Não há look-ahead bias no código
```

---

## 12. CHECKLIST FINAL

Antes de considerar o backtest isolado completo:

```
□ Setup está completamente isolado
□ Backtest executado sem erros
□ Resultados salvos e documentados
□ Gráficos e relatórios exportados
□ Métricas principais anotadas
□ Problemas identificados e listados
□ Comparação com benchmarks feita
□ Validação em diferentes períodos
□ Documentação completa
□ Arquivos organizados
```

---

## Recursos Adicionais

### Links Úteis
- MQL5 Documentation: https://www.mql5.com/en/docs
- Strategy Tester Guide: https://www.metatrader5.com/en/terminal/help/algotrading/testing
- Best Practices: https://www.mql5.com/en/articles

### Métricas de Referência
```
Setup considerado BOM:
- Win Rate: > 40%
- Profit Factor: > 1.5
- Max Drawdown: < 20%
- Recovery Factor: > 3
- Risk/Reward: > 1:1.5
- Sharpe Ratio: > 1.0
```

### Fórmulas Importantes
```
Profit Factor = Gross Profit / Gross Loss
Win Rate = (Winning Trades / Total Trades) × 100
Recovery Factor = Net Profit / Max Drawdown
Risk/Reward Ratio = Average Win / Average Loss
Expectancy = (Win Rate × Avg Win) - (Loss Rate × Avg Loss)
```
