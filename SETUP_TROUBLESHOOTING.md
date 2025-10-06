# Guia de Troubleshooting para Setups Individuais

## Índice de Problemas Comuns

1. [Problemas de Performance](#1-problemas-de-performance)
2. [Problemas de Sinalização](#2-problemas-de-sinalizacao)
3. [Problemas de Gerenciamento de Risco](#3-problemas-de-gerenciamento-de-risco)
4. [Problemas de Adaptação ao Mercado](#4-problemas-de-adaptacao-ao-mercado)
5. [Problemas Técnicos do EA](#5-problemas-tecnicos-do-ea)
6. [Problemas de Dados](#6-problemas-de-dados)

---

## 1. PROBLEMAS DE PERFORMANCE

### 1.1 Win Rate Muito Baixo (< 30%)

#### Sintomas
- Mais de 70% dos trades são perdedores
- Sequências longas de perdas consecutivas
- Equity em declínio constante

#### Possíveis Causas
```
□ Sinais de entrada ruins ou invertidos
□ Stop Loss muito apertado
□ Filtros de entrada insuficientes
□ Setup não adequado ao ativo/timeframe
□ Condições de mercado desfavoráveis
```

#### Diagnóstico
```mq5
// Adicionar prints de debug no EA
void OnTick()
{
   Print("=== ANÁLISE DE SINAL ===");
   Print("Condição 1: ", condition1);
   Print("Condição 2: ", condition2);
   Print("Sinal Final: ", signal);
   Print("=======================");
}
```

#### Soluções

**Solução 1: Revisar lógica de entrada**
```
1. Verificar se condições estão corretas
2. Testar sinais em gráfico manualmente
3. Adicionar filtros de confirmação
4. Implementar múltiplos timeframes
```

**Solução 2: Ajustar parâmetros**
```
- Aumentar período dos indicadores
- Adicionar filtro de tendência
- Requerer confluência de sinais
- Filtrar horários de baixa liquidez
```

**Solução 3: Adicionar filtros de qualidade**
```mq5
// Exemplo de filtro de volatilidade
bool FilterVolatility()
{
   double atr = iATR(_Symbol, _Period, 14, 0);
   double avgATR = iMA(_Symbol, _Period, 20, 0, MODE_SMA, atr);
   
   // Só operar se volatilidade estiver normal
   if(atr < avgATR * 0.5 || atr > avgATR * 2.0)
      return false;
      
   return true;
}
```

---

### 1.2 Profit Factor Baixo (< 1.3)

#### Sintomas
- Lucros e perdas quase se cancelam
- Sistema mal consegue cobrir custos operacionais
- Resultado final próximo de zero ou negativo

#### Possíveis Causas
```
□ Risk/Reward desequilibrado
□ Take Profit muito próximo
□ Stop Loss muito distante
□ Custos operacionais altos (spread/comissão)
□ Saídas prematuras
```

#### Diagnóstico
```
Analisar relatório do backtest:
- Average Win vs Average Loss
- Maiores ganhos vs Maiores perdas
- Distribuição de lucros
- Tempo médio em posição vencedora vs perdedora
```

#### Soluções

**Solução 1: Melhorar Risk/Reward**
```mq5
// Garantir mínimo de R:R 1:1.5
double CalculateTP(double entry, double sl, bool isLong)
{
   double riskPoints = MathAbs(entry - sl);
   double rewardPoints = riskPoints * 1.5; // Mínimo 1:1.5
   
   if(isLong)
      return entry + rewardPoints;
   else
      return entry - rewardPoints;
}
```

**Solução 2: Implementar Trailing Stop**
```mq5
// Proteger lucros com trailing stop
void TrailingStop(int ticket, double trailPoints)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return;
      
   double currentSL = OrderStopLoss();
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double newSL;
   
   if(OrderType() == OP_BUY)
   {
      newSL = currentPrice - trailPoints * _Point;
      if(newSL > currentSL && newSL < currentPrice)
         OrderModify(ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
   }
   else
   {
      newSL = currentPrice + trailPoints * _Point;
      if((newSL < currentSL || currentSL == 0) && newSL > currentPrice)
         OrderModify(ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
   }
}
```

**Solução 3: Saída em estágios (Partial Close)**
```mq5
// Fechar parte da posição no primeiro alvo
void PartialClose(int ticket, double firstTarget)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return;
      
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   
   // Se atingiu primeiro alvo, fechar 50%
   if((OrderType() == OP_BUY && currentPrice >= firstTarget) ||
      (OrderType() == OP_SELL && currentPrice <= firstTarget))
   {
      double lotSize = OrderLots() * 0.5;
      OrderClose(ticket, lotSize, currentPrice, 3);
      
      // Mover SL para breakeven
      OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
   }
}
```

---

### 1.3 Drawdown Excessivo (> 25%)

#### Sintomas
- Quedas bruscas no equity
- Longas sequências de perdas
- Recovery lento após drawdowns
- Risco de margin call

#### Possíveis Causas
```
□ Tamanho de posição excessivo
□ Falta de correlação entre trades
□ Muitas posições simultâneas
□ Ausência de stop loss
□ Martingale ou grid trading
```

#### Diagnóstico
```
Verificar no backtest:
- Máximo de posições abertas simultaneamente
- Tamanho das posições (% do capital)
- Distribuição de perdas no tempo
- Correlação entre ativos operados
```

#### Soluções

**Solução 1: Reduzir tamanho das posições**
```mq5
// Cálculo de lote baseado em risco fixo
double CalculateLotSize(double stopLossPoints, double riskPercent)
{
   double riskAmount = AccountBalance() * riskPercent / 100.0;
   double tickValue = MarketInfo(_Symbol, MODE_TICKVALUE);
   double lotSize = riskAmount / (stopLossPoints * tickValue);
   
   // Normalizar
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   double maxLot = MarketInfo(_Symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

// Usar: 1-2% de risco por trade
double lot = CalculateLotSize(stopLossPips, 1.0); // 1% de risco
```

**Solução 2: Limitar exposição total**
```mq5
// Limitar número de posições simultâneas
int CountOpenPositions()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS))
         if(OrderSymbol() == _Symbol && OrderMagicNumber() == MagicNumber)
            count++;
   }
   return count;
}

// Antes de abrir nova posição
if(CountOpenPositions() >= MaxSimultaneousPositions)
   return; // Não abrir mais posições
```

**Solução 3: Implementar regra de pausa após perdas**
```mq5
// Parar de operar após sequência de perdas
int consecutiveLosses = 0;
int maxConsecutiveLosses = 3;

void CheckConsecutiveLosses()
{
   // Verificar última ordem fechada
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(OrderSymbol() == _Symbol && OrderMagicNumber() == MagicNumber)
         {
            if(OrderProfit() < 0)
               consecutiveLosses++;
            else
               consecutiveLosses = 0;
            break;
         }
      }
   }
   
   // Se atingiu máximo, pausar
   if(consecutiveLosses >= maxConsecutiveLosses)
   {
      Comment("Sistema pausado após ", consecutiveLosses, " perdas consecutivas");
      return; // Não operar
   }
}
```

---

## 2. PROBLEMAS DE SINALIZAÇÃO

### 2.1 Sinais Falsos Frequentes

#### Sintomas
- Entradas seguidas de reversão imediata
- Stop loss atingido rapidamente
- Mercado não segue na direção esperada

#### Possíveis Causas
```
□ Indicadores com lag excessivo
□ Falta de confirmação
□ Sinais em mercado lateral
□ Reversões prematuras
□ Ruído de mercado
```

#### Soluções

**Solução 1: Adicionar confirmação de múltiplos indicadores**
```mq5
// Requerer confluência
bool ValidateSignal(int signalType)
{
   // Indicador 1: RSI
   double rsi = iRSI(_Symbol, _Period, 14, PRICE_CLOSE, 0);
   
   // Indicador 2: MACD
   double macd = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double signal = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
   
   // Indicador 3: Moving Average
   double ma50 = iMA(_Symbol, _Period, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double price = Close[0];
   
   if(signalType == OP_BUY)
   {
      // Todas as condições devem ser verdadeiras
      if(rsi < 70 &&                    // Não sobrecomprado
         macd > signal &&                // MACD bullish
         price > ma50)                   // Preço acima da MA
         return true;
   }
   else if(signalType == OP_SELL)
   {
      if(rsi > 30 &&                    // Não sobrevendido
         macd < signal &&                // MACD bearish
         price < ma50)                   // Preço abaixo da MA
         return true;
   }
   
   return false;
}
```

**Solução 2: Filtro de tendência**
```mq5
// Operar apenas a favor da tendência
enum TrendDirection
{
   TREND_UP,
   TREND_DOWN,
   TREND_SIDEWAYS
};

TrendDirection GetTrend()
{
   double ma20 = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma50 = iMA(_Symbol, _Period, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma200 = iMA(_Symbol, _Period, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   
   // Tendência de alta
   if(ma20 > ma50 && ma50 > ma200)
      return TREND_UP;
   
   // Tendência de baixa
   if(ma20 < ma50 && ma50 < ma200)
      return TREND_DOWN;
   
   // Lateral
   return TREND_SIDEWAYS;
}

// Filtrar sinais
bool signal = GetSignal();
TrendDirection trend = GetTrend();

if(signal == OP_BUY && trend != TREND_UP)
   signal = -1; // Rejeitar sinal

if(signal == OP_SELL && trend != TREND_DOWN)
   signal = -1; // Rejeitar sinal
```

**Solução 3: Aguardar confirmação de candle**
```mq5
// Não entrar em candle em formação
bool WaitForCandleClose()
{
   datetime currentCandleTime = iTime(_Symbol, _Period, 0);
   static datetime lastCandleTime = 0;
   
   // Se é novo candle
   if(currentCandleTime != lastCandleTime)
   {
      lastCandleTime = currentCandleTime;
      return true; // Candle fechou, pode verificar sinal
   }
   
   return false; // Aguardar fechamento
}
```

---

### 2.2 Entradas Atrasadas

#### Sintomas
- Sinal aparece tarde demais
- Grande parte do movimento já ocorreu
- Risk/Reward desfavorável na entrada
- Stop Loss muito distante

#### Possíveis Causas
```
□ Indicadores muito lentos
□ Múltiplas confirmações em excesso
□ Processamento lento do EA
□ Espera desnecessária
```

#### Soluções

**Solução 1: Usar indicadores mais rápidos**
```mq5
// Substituir MAs lentas por exponenciais
double emaFast = iMA(_Symbol, _Period, 12, 0, MODE_EMA, PRICE_CLOSE, 0);
double emaSlow = iMA(_Symbol, _Period, 26, 0, MODE_EMA, PRICE_CLOSE, 0);

// Ou usar períodos menores
double ma10 = iMA(_Symbol, _Period, 10, 0, MODE_SMA, PRICE_CLOSE, 0);
double ma20 = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
```

**Solução 2: Entrada em pullback**
```mq5
// Aguardar retração para melhor preço
bool isPullbackEntry = false;
double pullbackLevel;

void CheckPullback()
{
   TrendDirection trend = GetTrend();
   double price = Close[0];
   double ma20 = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   
   if(trend == TREND_UP)
   {
      // Aguardar preço tocar/aproximar da MA
      if(price <= ma20 * 1.002) // 0.2% de tolerância
      {
         isPullbackEntry = true;
         pullbackLevel = price;
      }
   }
}
```

**Solução 3: Ordem pendente em nível-chave**
```mq5
// Colocar ordem limite em vez de ordem a mercado
void PlacePendingOrder(int orderType, double price, double sl, double tp)
{
   int ticket = OrderSend(
      _Symbol,
      orderType, // OP_BUYLIMIT ou OP_SELLLIMIT
      lotSize,
      price,
      0,
      sl,
      tp,
      "Pullback Entry",
      MagicNumber,
      0,
      clrGreen
   );
}
```

---

### 2.3 Saídas Prematuras

#### Sintomas
- Take Profit atingido muito cedo
- Movimento continua favorável após saída
- Lucros deixados na mesa
- Average Win muito menor que poderia ser

#### Possíveis Causas
```
□ Take Profit muito conservador
□ Trailing Stop muito agressivo
□ Falta de gestão dinâmica
□ Não aproveitar tendências fortes
```

#### Soluções

**Solução 1: Take Profit dinâmico baseado em ATR**
```mq5
// TP baseado na volatilidade atual
double CalculateDynamicTP(double entryPrice, bool isLong)
{
   double atr = iATR(_Symbol, _Period, 14, 0);
   double tpDistance = atr * 2.0; // 2x ATR
   
   if(isLong)
      return entryPrice + tpDistance;
   else
      return entryPrice - tpDistance;
}
```

**Solução 2: Saída parcial em estágios**
```mq5
// Fechar posição em 3 estágios
void ManagePartialExits(int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return;
      
   double entryPrice = OrderOpenPrice();
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double profitPoints = MathAbs(currentPrice - entryPrice) / _Point;
   double sl = OrderStopLoss();
   double riskPoints = MathAbs(entryPrice - sl) / _Point;
   
   // 1º Alvo: 1R (33% da posição)
   if(profitPoints >= riskPoints && !stage1Closed)
   {
      ClosePartial(ticket, 0.33);
      stage1Closed = true;
      // Mover SL para breakeven
      ModifySL(ticket, entryPrice);
   }
   
   // 2º Alvo: 2R (mais 33%)
   if(profitPoints >= riskPoints * 2 && !stage2Closed)
   {
      ClosePartial(ticket, 0.33);
      stage2Closed = true;
      // Mover SL para 1R
      ModifySL(ticket, entryPrice + (riskPoints * _Point));
   }
   
   // 3º Alvo: Trailing stop no restante
   if(stage2Closed)
   {
      TrailingStop(ticket, riskPoints * 0.5);
   }
}
```

**Solução 3: Detector de tendência forte**
```mq5
// Manter posição em tendências fortes
bool IsStrongTrend()
{
   double adx = iADX(_Symbol, _Period, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double atr = iATR(_Symbol, _Period, 14, 0);
   double avgATR = iMA(_Symbol, _Period, 20, 0, MODE_SMA, atr);
   
   // ADX > 25 e volatilidade acima da média
   if(adx > 25 && atr > avgATR * 1.2)
      return true;
      
   return false;
}

// Ajustar gestão
if(IsStrongTrend())
{
   // Usar trailing stop mais solto
   trailingDistance = atr * 3.0;
}
else
{
   // Trailing normal
   trailingDistance = atr * 1.5;
}
```

---

## 3. PROBLEMAS DE GERENCIAMENTO DE RISCO

### 3.1 Stop Loss Atingido Frequentemente

#### Sintomas
- Maioria das perdas por stop loss
- SL muito apertado
- Preço toca o SL e depois vai na direção esperada

#### Soluções

**Solução: SL baseado em estrutura**
```mq5
// Colocar SL abaixo/acima de suporte/resistência
double CalculateStructuralSL(bool isLong)
{
   double swingPoint;
   
   if(isLong)
   {
      // Procurar mínima recente
      swingPoint = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, 20, 1));
      return swingPoint - (10 * _Point); // Buffer
   }
   else
   {
      // Procurar máxima recente
      swingPoint = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, 20, 1));
      return swingPoint + (10 * _Point); // Buffer
   }
}
```

---

### 3.2 Tamanho de Posição Inadequado

#### Sintomas
- Drawdowns excessivos
- Margin call
- Volatilidade de equity muito alta

#### Soluções

**Solução: Gestão baseada em Kelly Criterion**
```mq5
// Cálculo otimizado de tamanho de posição
double KellyCriterion(double winRate, double avgWin, double avgLoss)
{
   double kelly = (winRate * avgWin - (1 - winRate) * avgLoss) / avgWin;
   
   // Usar fração de Kelly (25-50% do valor total)
   kelly = kelly * 0.25; // Kelly fracionário
   
   // Limitar entre 1-5% do capital
   kelly = MathMax(0.01, MathMin(kelly, 0.05));
   
   return kelly;
}
```

---

## 4. PROBLEMAS DE ADAPTAÇÃO AO MERCADO

### 4.1 Performance Ruim em Mercado Lateral

#### Sintomas
- Múltiplos sinais falsos
- Stops atingidos frequentemente
- Oscilação do equity sem progresso

#### Soluções

**Solução: Detector de mercado lateral**
```mq5
// Identificar e evitar lateralizações
bool IsSidewaysMarket()
{
   double adx = iADX(_Symbol, _Period, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double highestHigh = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, 50, 0));
   double lowestLow = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, 50, 0));
   double rangePercent = (highestHigh - lowestLow) / lowestLow * 100;
   
   // ADX baixo e range pequeno = lateral
   if(adx < 20 && rangePercent < 3)
      return true;
      
   return false;
}

// Aplicar filtro
if(IsSidewaysMarket())
{
   Comment("Mercado lateral detectado - Setup pausado");
   return; // Não operar
}
```

---

## 5. PROBLEMAS TÉCNICOS DO EA

### 5.1 EA Não Abre Ordens

#### Checklist de Diagnóstico
```
□ "Allow Automated Trading" está habilitado?
□ EA está ativado no gráfico (smile verde)?
□ Função OnTick() está sendo chamada?
□ Erros no Journal/Experts?
□ Spread muito alto bloqueando entrada?
□ Horário de trading está ativo?
```

#### Debug
```mq5
void OnTick()
{
   Print("OnTick chamado - Time: ", TimeCurrent());
   
   if(!IsTradeAllowed())
   {
      Print("Trading não permitido!");
      return;
   }
   
   Print("Verificando sinais...");
   // ... resto do código
}
```

---

### 5.2 Erro 130 (Invalid Stops)

#### Causas
- Stop Loss ou Take Profit muito próximos do preço
- Não respeitando STOP LEVEL mínimo

#### Solução
```mq5
// Verificar e ajustar stops
double VerifyStopLevel(double price, double stop, bool isSL, bool isLong)
{
   double minDistance = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   double currentDistance = MathAbs(price - stop);
   
   if(currentDistance < minDistance)
   {
      Print("Stop muito próximo! Ajustando...");
      
      if(isLong)
      {
         if(isSL)
            stop = price - minDistance - (2 * _Point);
         else
            stop = price + minDistance + (2 * _Point);
      }
      else
      {
         if(isSL)
            stop = price + minDistance + (2 * _Point);
         else
            stop = price - minDistance - (2 * _Point);
      }
   }
   
   return NormalizeDouble(stop, _Digits);
}
```

---

## 6. PROBLEMAS DE DADOS

### 6.1 Gaps nos Dados Históricos

#### Identificação
```mq5
// Verificar gaps
void CheckForGaps()
{
   for(int i = 1; i < Bars - 1; i++)
   {
      datetime currentTime = iTime(_Symbol, _Period, i);
      datetime previousTime = iTime(_Symbol, _Period, i + 1);
      int periodInSeconds = PeriodSeconds(_Period);
      
      if(currentTime - previousTime > periodInSeconds * 2)
      {
         Print("Gap detectado entre ", TimeToString(previousTime), 
               " e ", TimeToString(currentTime));
      }
   }
}
```

#### Solução
```
1. Redownload dos dados históricos
2. Usar diferentes fontes de dados
3. Excluir períodos com gaps do backtest
```

---

## FLUXO DE TROUBLESHOOTING

```
1. IDENTIFICAR SINTOMA
   ↓
2. ISOLAR O PROBLEMA
   - Adicionar prints de debug
   - Testar componentes individualmente
   - Verificar dados do backtest
   ↓
3. FORMULAR HIPÓTESE
   - Lista possíveis causas
   - Priorizar mais prováveis
   ↓
4. IMPLEMENTAR SOLUÇÃO
   - Uma mudança por vez
   - Documentar alteração
   ↓
5. TESTAR SOLUÇÃO
   - Backtest com mesmos dados
   - Comparar resultados
   ↓
6. VALIDAR CORREÇÃO
   - Out-of-sample test
   - Forward test
   ↓
7. DOCUMENTAR
   - Problema
   - Causa
   - Solução
   - Resultados
```

---

## RECURSOS ADICIONAIS

### Template de Debug
```mq5
#define DEBUG_MODE true

void DebugPrint(string message)
{
   if(DEBUG_MODE)
      Print("[DEBUG] ", TimeToString(TimeCurrent()), " - ", message);
}

// Uso
DebugPrint("Sinal de compra detectado, RSI=" + DoubleToString(rsi, 2));
```

### Logging Avançado
```mq5
void LogTrade(string action, double price, string reason)
{
   int fileHandle = FileOpen("trade_log.csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   
   if(fileHandle != INVALID_HANDLE)
   {
      FileSeek(fileHandle, 0, SEEK_END);
      FileWrite(fileHandle, 
                TimeToString(TimeCurrent()),
                action,
                DoubleToString(price, _Digits),
                reason);
      FileClose(fileHandle);
   }
}
```

---

## CONCLUSÃO

Use este guia sistematicamente:
1. Identifique o problema específico
2. Siga as soluções propostas
3. Teste uma mudança por vez
4. Documente resultados
5. Itere até resolver

**Lembre-se:** A maioria dos problemas vem de:
- Parâmetros inadequados
- Falta de filtros
- Gerenciamento de risco ruim
- Não adaptação às condições de mercado
