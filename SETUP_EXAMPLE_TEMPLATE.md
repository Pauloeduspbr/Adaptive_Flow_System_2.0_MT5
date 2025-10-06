# Template de Exemplo - Análise de Setup Individual

Este é um exemplo prático de como preencher o prompt de análise para um setup específico.

---

## EXEMPLO: SETUP RSI OVERSOLD/OVERBOUGHT

### 1. IDENTIFICAÇÃO DO SETUP

**Setup Name:** RSI Reversal Strategy
**Setup Type:** Mean Reversion
**Timeframe:** H1 (1 hora)
**Instruments:** EURUSD, GBPUSD, USDJPY

---

### 2. CONFIGURAÇÃO ATUAL DO SETUP

#### Parâmetros de Entrada
```
- Indicadores utilizados:
  * RSI: Período 14, Aplicado em Close
  * Moving Average: Período 200, SMA, Aplicado em Close (filtro de tendência)
  * ATR: Período 14 (para stops dinâmicos)

- Sinais de entrada:
  * Long: RSI < 30 (oversold) + fechamento de candle acima da entrada + preço acima MA200
  * Short: RSI > 70 (overbought) + fechamento de candle abaixo da entrada + preço abaixo MA200

- Filtros aplicados:
  * Filtro 1: Apenas operar a favor da tendência (MA200)
  * Filtro 2: Horário entre 08:00 - 20:00 GMT
  * Filtro 3: Aguardar fechamento de candle para confirmação
```

#### Parâmetros de Gerenciamento de Risco
```
- Stop Loss: 1.5 x ATR abaixo/acima do ponto de entrada
- Take Profit: 2.5 x ATR (Risk/Reward de 1:1.67)
- Trailing Stop: Ativado após 1.5R, com distância de 1 x ATR
- Tamanho da posição: 1% de risco por trade
- Risk/Reward ratio: 1:1.67
- Max drawdown permitido: 15%
```

#### Parâmetros de Tempo
```
- Horários de operação: 08:00 - 20:00 GMT
- Dias da semana: Segunda a Sexta
- Filtros de sessão: Evitar período de baixa liquidez (22:00 - 06:00 GMT)
- Tempo máximo em posição: 72 horas (3 dias)
```

---

### 3. CONFIGURAÇÃO DO BACKTEST ISOLADO

#### Período de Teste
```
- Data inicial: 01/01/2023
- Data final: 31/12/2023
- Justificativa do período: Ano completo incluindo diferentes condições - tendências, lateralizações, alta e baixa volatilidade
```

#### Condições de Mercado
```
- Spread: 1.5 pips (EURUSD), 2.0 pips (GBPUSD), 1.8 pips (USDJPY)
- Comissão: $7 por lote round turn
- Slippage: 2 pontos
- Alavancagem: 1:100
- Depósito inicial: $10,000
```

#### Critérios de Validação
```
- Mínimo de trades: 50 trades
- Período mínimo: 12 meses
- Incluir: Tendências de alta/baixa, períodos laterais, volatilidade alta (guerras, anúncios) e baixa (feriados)
```

---

### 4. MÉTRICAS ESPERADAS vs OBTIDAS

| Métrica | Esperado | Obtido | Status |
|---------|----------|--------|--------|
| Win Rate | 55% | 38% | ✗ |
| Profit Factor | 2.0 | 0.95 | ✗ |
| Max Drawdown | 12% | 22% | ✗ |
| Risk/Reward Ratio | 1:1.67 | 1:1.2 | ✗ |
| Total Trades | 50+ | 127 | ✓ |
| Sharpe Ratio | 1.5 | -0.3 | ✗ |
| Recovery Factor | 3.5 | 0.8 | ✗ |
| Expectativa Matemática | Positiva | -$12 | ✗ |

**RESULTADO GERAL:** ✗ Setup NÃO está performando conforme esperado

---

### 5. ANÁLISE DE PROBLEMAS IDENTIFICADOS

#### 5.1 Problemas de Performance
```
☑ Win rate abaixo do esperado
  - Causa possível: Sinais falsos em mercado lateral / Stop Loss muito apertado
  - Evidência no backtest: 62% das operações são perdedoras, muitas com pequenas perdas
  
☑ Drawdown excessivo
  - Causa possível: Sequências de perdas consecutivas / Tamanho de posição inadequado
  - Evidência no backtest: Máximo de 9 perdas consecutivas, DD de 22% observado em março/2023
  
☑ Profit factor baixo
  - Causa possível: Average Loss muito próximo de Average Win
  - Evidência no backtest: Avg Win = $85, Avg Loss = $70, ratio baixo
  
☑ Muitas operações perdedoras consecutivas
  - Causa possível: Setup continuou operando em condições desfavoráveis
  - Evidência no backtest: 9 perdas consecutivas em período de lateralização
```

#### 5.2 Problemas de Sinalização
```
☑ Sinais falsos frequentes
  - Condição específica: RSI tocando oversold/overbought em mercado lateral
  - Frequência: 35% dos sinais em março, junho e setembro (períodos de range)
  
☑ Entradas atrasadas
  - Condição específica: Aguardar fechamento de candle em H1 causa atraso
  - Impacto no resultado: Perda média de 15 pips do movimento
  
☐ Saídas prematuras
  - Não identificado como problema principal
```

#### 5.3 Problemas de Gerenciamento de Risco
```
☑ Stop Loss sendo atingido com frequência
  - Análise: 58% das perdas por Stop Loss, 4% por reversão de sinal
  - Percentual de stops: 62% das operações
  
☑ Take Profit muito próximo ou muito distante
  - Análise: 20% das operações atingem TP, maioria sai por reversão ou SL
  - Otimização sugerida: Reduzir TP para 2R, adicionar saída parcial
  
☐ Sizing de posição inadequado
  - 1% de risco está adequado, não é o problema principal
```

#### 5.4 Problemas de Adaptação ao Mercado
```
☑ Performance ruim em mercados laterais
  - Evidência: Março, Junho e Setembro tiveram -8%, -6% e -7% respectivamente
  - Filtro necessário: Adicionar filtro ADX < 20 para evitar lateralização
  
☐ Performance ruim em tendências
  - Setup performa bem em tendências claras (Jan, Fev, Out, Nov foram positivos)
  
☑ Sensibilidade à volatilidade
  - Evidência: Performance degradou em períodos de alta volatilidade (guerra, anúncios do Fed)
  - Adaptação proposta: Adicionar filtro ATR, pausar quando ATR > 2x média
```

---

### 6. PLANO DE CORREÇÃO PROPOSTO

#### Correção Prioritária 1
```
Problema: Sinais falsos em mercado lateral causando 35% das perdas
Causa raiz: Setup de reversão não funciona em range - RSI fica constantemente em extremos
Solução proposta: Adicionar filtro ADX para identificar e evitar mercado lateral

Parâmetros a ajustar:
  - Adicionar: ADX_Period = 14
  - Adicionar: ADX_Threshold = 20
  - Regra: Só operar se ADX > 20 (tendência presente)

Código proposto:
```mq5
double adx = iADX(_Symbol, _Period, 14, PRICE_CLOSE, MODE_MAIN, 0);
if(adx < 20)
{
   Comment("Mercado lateral - Setup pausado (ADX=", DoubleToString(adx,1), ")");
   return; // Não gerar sinais
}
```

Resultado esperado: 
- Redução de 30-40% no número de trades
- Aumento do Win Rate para 50-55%
- Redução de drawdown para 12-15%
```

#### Correção Prioritária 2
```
Problema: Stop Loss muito apertado (1.5 ATR) causando saídas prematuras
Causa raiz: ATR em H1 não captura volatilidade intracandle, preço toca SL e reverte
Solução proposta: Aumentar SL para 2.0 ATR e ajustar TP proporcionalmente

Parâmetros a ajustar:
  - SL_Multiplier: de 1.5 para 2.0
  - TP_Multiplier: de 2.5 para 3.5 (manter R:R de 1:1.75)

Código proposto:
```mq5
double atr = iATR(_Symbol, _Period, 14, 0);
double slDistance = atr * 2.0; // Era 1.5
double tpDistance = atr * 3.5; // Era 2.5

if(signalType == OP_BUY)
{
   sl = entryPrice - slDistance;
   tp = entryPrice + tpDistance;
}
```

Resultado esperado:
- Redução de stops atingidos de 58% para 40%
- Aumento de Average Win
- Melhoria do Profit Factor para 1.5+
```

#### Correção Prioritária 3
```
Problema: Ausência de mecanismo de proteção em sequências de perdas
Causa raiz: Setup continua operando mesmo após múltiplas perdas consecutivas
Solução proposta: Implementar pausa após 4 perdas consecutivas

Parâmetros a ajustar:
  - Adicionar: MaxConsecutiveLosses = 4
  - Adicionar: PausePeriod = 24 (horas)

Código proposto:
```mq5
int consecutiveLosses = 0;
datetime pauseUntil = 0;

void CheckPauseCondition()
{
   if(TimeCurrent() < pauseUntil)
   {
      Comment("Sistema pausado até ", TimeToString(pauseUntil));
      return;
   }
   
   // Contar perdas consecutivas
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(OrderMagicNumber() == MagicNumber)
         {
            if(OrderProfit() < 0)
               consecutiveLosses++;
            else
            {
               consecutiveLosses = 0;
               break;
            }
         }
      }
   }
   
   if(consecutiveLosses >= 4)
   {
      pauseUntil = TimeCurrent() + 24*3600; // 24 horas
      Comment("4 perdas consecutivas - pausando por 24h");
   }
}
```

Resultado esperado:
- Proteção contra sequências extremas (9 perdas reduzidas para máx 4)
- Redução de drawdown máximo
- Melhoria do Recovery Factor
```

---

### 7. VALIDAÇÃO PÓS-CORREÇÃO

#### Novo Backtest com Correções
```
- Período: 01/01/2023 - 31/12/2023 (mesmo período)
- Condições: Mantidas idênticas (spread, comissão, slippage)
- Mudanças aplicadas:
  1. Filtro ADX > 20
  2. SL = 2.0 ATR, TP = 3.5 ATR
  3. Pausa após 4 perdas consecutivas
```

#### Comparação de Resultados

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Win Rate | 38% | 52% | +37% |
| Profit Factor | 0.95 | 1.78 | +87% |
| Max Drawdown | 22% | 13% | -41% |
| Total Trades | 127 | 73 | -43% |
| Expectativa | -$12 | +$48 | +500% |
| Avg Win | $85 | $145 | +71% |
| Avg Loss | $70 | $82 | +17% |
| Consecutivas Loss | 9 | 4 | -56% |

#### Status da Correção
```
☑ Problema resolvido completamente
  - Setup agora passa em todos os critérios mínimos
  - Win rate atingiu meta de 52%
  - Profit factor acima de 1.5
  - Drawdown dentro do limite de 15%
  
Melhorias observadas:
✓ Redução significativa de sinais falsos
✓ Proteção efetiva em períodos laterais
✓ Stops menos frequentes
✓ Drawdown controlado
✓ Expectativa positiva

Pontos de atenção:
- Número de trades reduziu de 127 para 73 (esperado com filtro ADX)
- Average Loss aumentou ligeiramente devido a SL maior
- Monitorar performance em forward test
```

---

### 8. PRÓXIMOS PASSOS

```
1. [x] Implementar correções no código do EA
2. [x] Realizar backtest com correções
3. [x] Validar melhoria nas métricas
4. [ ] Teste em forward test (Jan-Mar 2024 - dados fora da amostra)
5. [ ] Validação em outros pares (EURJPY, AUDUSD)
6. [ ] Teste em timeframe M30 e H4
7. [ ] Teste em conta demo por 30 dias
8. [ ] Documentar lições aprendidas
9. [ ] Integração com portfolio de setups
10. [ ] Aprovação para trading real (se demo positivo)
```

---

## NOTAS DO PROCESSO

### Lições Aprendidas
1. **Filtro de tendência é essencial**: Setups de reversão precisam de filtro para evitar lateralização
2. **ATR dinâmico funciona melhor**: Stops fixos não se adaptam à volatilidade do mercado
3. **Proteção contra perdas consecutivas é crítica**: Evita destruição de capital em períodos ruins
4. **Menos trades != pior resultado**: Qualidade > Quantidade

### Decisões Importantes
- **Por que ADX 20?** Testamos 15, 20 e 25. ADX=20 deu melhor balanço entre filtro e oportunidades
- **Por que SL 2.0 ATR?** Testamos 1.5, 2.0 e 2.5. SL=2.0 teve melhor win rate sem excesso de risco
- **Por que pausa de 24h?** 12h foi insuficiente, 48h perdeu muitas oportunidades

### Ajustes Futuros Considerados
- [ ] Testar RSI com período 10 (mais sensível)
- [ ] Adicionar segundo confirmador (MACD)
- [ ] Implementar trailing stop dinâmico
- [ ] Testar em múltiplos timeframes simultaneamente

---

## REPORT FINAL

```
SETUP: RSI Reversal Strategy
DATA DA ANÁLISE: 15/01/2024
ANALISTA: Paulo Eduardo

RESUMO EXECUTIVO:
Setup RSI Reversal apresentava performance insatisfatória com Win Rate de 38%,
Profit Factor de 0.95 e Drawdown de 22%. Análise identificou três problemas
principais: sinais falsos em mercado lateral, Stop Loss muito apertado, e ausência
de proteção contra perdas consecutivas. Após implementação de filtro ADX, ajuste
de SL/TP baseados em ATR, e mecanismo de pausa, o setup melhorou significativamente
atingindo Win Rate de 52%, Profit Factor de 1.78 e Drawdown de 13%.

PROBLEMAS IDENTIFICADOS:
1. Sinais falsos em mercado lateral (35% dos trades)
2. Stop Loss muito apertado causando saídas prematuras (58% dos trades)
3. Ausência de proteção contra perdas consecutivas (máx 9 perdas)

CORREÇÕES APLICADAS:
1. Filtro ADX > 20 para evitar mercado lateral
2. Ajuste SL para 2.0 ATR e TP para 3.5 ATR
3. Pausa automática após 4 perdas consecutivas

RESULTADOS:
- Performance melhorou em 500% (expectativa de -$12 para +$48)
- Drawdown reduzido em 41% (22% para 13%)
- Win rate aumentou em 37% (38% para 52%)
- Profit Factor melhorou em 87% (0.95 para 1.78)

STATUS: ✓ APROVADO para forward test e testes em demo

RECOMENDAÇÕES:
1. Iniciar forward test em período Jan-Mar 2024
2. Testar em outros pares majors (EURJPY, AUDUSD, NZDUSD)
3. Validar em conta demo por mínimo 30 dias / 20 trades
4. Documentar performance semanal
5. Reavaliar após 3 meses de operação
6. Considerar adicionar segundo indicador de confirmação
7. Manter registro detalhado de cada trade para aprendizado
8. Não usar em períodos de notícias de alto impacto (NFP, FOMC)

PRÓXIMA REVISÃO: 15/04/2024 (após 3 meses de forward test)
```

---

## ANEXOS

### A. Código Principal do Setup (Simplificado)

```mq5
//+------------------------------------------------------------------+
//| RSI Reversal Strategy - Versão Corrigida                         |
//+------------------------------------------------------------------+

// Inputs
input int RSI_Period = 14;
input double RSI_Oversold = 30;
input double RSI_Overbought = 70;
input int MA_Period = 200;
input int ATR_Period = 14;
input double SL_Multiplier = 2.0;
input double TP_Multiplier = 3.5;
input int ADX_Period = 14;
input double ADX_Threshold = 20;
input int MaxConsecutiveLosses = 4;
input double RiskPercent = 1.0;

// Variáveis globais
int consecutiveLosses = 0;
datetime pauseUntil = 0;

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Verificar se está em pausa
   if(TimeCurrent() < pauseUntil)
   {
      Comment("Sistema pausado até ", TimeToString(pauseUntil));
      return;
   }
   
   // Atualizar contagem de perdas consecutivas
   UpdateConsecutiveLosses();
   
   // Verificar filtro ADX
   double adx = iADX(_Symbol, _Period, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   if(adx < ADX_Threshold)
   {
      Comment("Mercado lateral - ADX: ", DoubleToString(adx, 1));
      return;
   }
   
   // Verificar sinais
   int signal = GetSignal();
   
   if(signal == OP_BUY)
      OpenTrade(OP_BUY);
   else if(signal == OP_SELL)
      OpenTrade(OP_SELL);
}

//+------------------------------------------------------------------+
//| Detectar sinal de entrada                                         |
//+------------------------------------------------------------------+
int GetSignal()
{
   double rsi = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE, 0);
   double ma = iMA(_Symbol, _Period, MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double price = Close[0];
   
   // Sinal de compra
   if(rsi < RSI_Oversold && price > ma)
      return OP_BUY;
   
   // Sinal de venda
   if(rsi > RSI_Overbought && price < ma)
      return OP_SELL;
   
   return -1;
}

//+------------------------------------------------------------------+
//| Abrir trade                                                       |
//+------------------------------------------------------------------+
void OpenTrade(int type)
{
   double atr = iATR(_Symbol, _Period, ATR_Period, 0);
   double price = (type == OP_BUY) ? Ask : Bid;
   double sl, tp;
   
   // Calcular SL e TP
   if(type == OP_BUY)
   {
      sl = price - (atr * SL_Multiplier);
      tp = price + (atr * TP_Multiplier);
   }
   else
   {
      sl = price + (atr * SL_Multiplier);
      tp = price - (atr * TP_Multiplier);
   }
   
   // Calcular tamanho da posição
   double lotSize = CalculateLotSize(sl, price, type);
   
   // Enviar ordem
   int ticket = OrderSend(_Symbol, type, lotSize, price, 3, sl, tp, 
                          "RSI Reversal", MagicNumber, 0, clrGreen);
   
   if(ticket > 0)
      Print("Ordem aberta: #", ticket);
   else
      Print("Erro ao abrir ordem: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Calcular tamanho da posição                                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl, double entry, int type)
{
   double slDistance = MathAbs(entry - sl) / _Point;
   double riskAmount = AccountBalance() * RiskPercent / 100.0;
   double tickValue = MarketInfo(_Symbol, MODE_TICKVALUE);
   
   double lots = riskAmount / (slDistance * tickValue);
   
   // Normalizar
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   double maxLot = MarketInfo(_Symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   
   return lots;
}

//+------------------------------------------------------------------+
//| Atualizar perdas consecutivas                                     |
//+------------------------------------------------------------------+
void UpdateConsecutiveLosses()
{
   consecutiveLosses = 0;
   
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(OrderSymbol() == _Symbol && OrderMagicNumber() == MagicNumber)
         {
            if(OrderProfit() < 0)
               consecutiveLosses++;
            else
               break;
         }
      }
   }
   
   // Ativar pausa se necessário
   if(consecutiveLosses >= MaxConsecutiveLosses)
   {
      pauseUntil = TimeCurrent() + 24 * 3600;
      Comment("PAUSA: ", consecutiveLosses, " perdas consecutivas. Retorno: ", 
              TimeToString(pauseUntil));
   }
}
```

### B. Gráfico de Performance (Descrição)
```
[Curva de Equity mostrando melhoria significativa após correções]
- Linha azul: Performance ANTES das correções (declínio de -$1,200)
- Linha verde: Performance DEPOIS das correções (crescimento de +$3,500)
- Áreas sombreadas: Períodos de drawdown
- Marcadores vermelhos: Momentos de pausa automática
```

### C. Distribuição de Trades
```
ANTES:
- Wins: 48 trades (38%)
- Losses: 79 trades (62%)
- Breakeven: 0 trades

DEPOIS:
- Wins: 38 trades (52%)
- Losses: 34 trades (47%)
- Breakeven: 1 trade (1%)
```

---

Este exemplo demonstra o processo completo de análise, correção e validação de um setup individual. Use-o como modelo para seus próprios setups.
