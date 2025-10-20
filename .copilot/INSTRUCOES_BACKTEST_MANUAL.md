# INSTRUÇÕES: EXECUTAR BACKTEST NO MT5 STRATEGY TESTER

## 📋 **Passo a Passo Detalhado**

### **1. Abrir Strategy Tester Corretamente**
- No MT5, pressione **`Ctrl+R`** (ou menu `Exibir` → `Strategy Tester`)
- Uma janela deve aparecer na parte inferior da tela

---

### **2. Selecionar Aba "Único" (Single)**
**IMPORTANTE**: Na imagem você está na aba "Testes anteriores". Você precisa:
- Clicar na **primeira aba** (ícone de gráfico com linha verde)
- Nome da aba: **"Único"** ou **"Single"** (depende do idioma)

---

### **3. Configurar Parâmetros do Teste**

Na aba "Único", preencha os campos:

#### **Seção "Geral"** (ou "General")
| Campo | Valor |
|-------|-------|
| **Expert Advisor** | `AdaptiveFlowSystem_v2` |
| **Symbol** | `USDJPY` |
| **Period** | `M15` |
| **Deposit** | `70.00` |
| **Leverage** | `1:100` (padrão) |

#### **Seção "Datas"** (ou "Dates")
| Campo | Valor |
|-------|-------|
| **From** | `2024.01.01` |
| **To** | `2025.09.19` |
| **Forward** | Desmarcado |

#### **Seção "Modelo de Teste"** (ou "Model")
| Campo | Valor |
|-------|-------|
| **Model** | `Every tick` (todos os ticks) |
| **Optimization** | Desmarcado |
| **Visualization** | ❌ **DESMARCAR** (sem gráfico = mais rápido) |

---

### **4. Carregar Parâmetros do Arquivo .SET**

1. Na aba "Parâmetros de entrada" (ou "Inputs"):
   - Clicar no botão **`Load`** (ícone de pasta ou texto "Carregar")
   - Navegar até: `C:\Users\paulo\AppData\Roaming\MetaQuotes\Terminal\FEC98F1D078C037902D797DB372EA18E\tester\`
   - Selecionar: **`AdaptiveFlowSystem_v2.set`**
   - Clicar em "Abrir"

2. **VERIFICAR** que os parâmetros foram carregados:
   - `InpMinSignalConfidence = 0.65` ✅
   - `InpStartTimeHHMM = 07:00` ✅
   - `InpEndTimeHHMM = 17:00` ✅

---

### **5. Iniciar o Teste**

1. **Confirmar** que `Visualization` está **DESMARCADO** ❌
2. Clicar no botão **`Start`** (ícone de "play" verde)
3. **AGUARDAR**: 15-20 minutos (sem visualização)

---

### **6. Acompanhar Progresso**

Durante o teste, você verá:
- **Barra de progresso** (0% → 100%)
- **Estatísticas em tempo real** na aba "Results":
  - Total trades
  - Profit/Loss
  - Drawdown
  - etc.

---

### **7. Após Conclusão**

Quando o teste terminar (100%):
1. **NÃO FECHAR** a janela ainda
2. Vá para a aba "Results" e tire um **screenshot** da tabela completa
3. Execute no PowerShell:
   ```powershell
   Get-Latest-Backtest-Log
   ```
4. Copie o log para o workspace conforme instruções

---

## 🚨 **ERROS COMUNS**

### **"EA não encontrado na lista"**
**Solução**:
```powershell
# Recompilar e deploy
. .\.copilot\CONFIG_IMUTAVEL.ps1
Compile-EA-Safe
```

### **"Símbolo USDJPY não disponível"**
**Solução**:
1. Abrir "Market Watch" (Ctrl+M)
2. Clicar com botão direito → "Symbols"
3. Buscar "USDJPY" e marcar como visível

### **"Dados históricos insuficientes"**
**Solução**:
1. Clicar em "Tools" → "History Center" (F2)
2. Selecionar "USDJPY" → "M15"
3. Clicar em "Download" para baixar dados de 2024-2025

---

## 📊 **Expectativa de Resultados (EA v2.06)**

| Métrica | Expectativa |
|---------|-------------|
| **Total Trades** | ~280 |
| **Profit/Loss** | +R$ 20.46 |
| **Win Rate** | 38-42% |
| **Max Drawdown** | < 80% |
| **Profit Factor** | > 1.2 |

---

## 🔄 **Se o Teste Falhar Imediatamente**

Verifique no log (aba "Journal"):
- **"Erro na inicialização"**: Indicadores não encontrados → executar `Compile-All-Indicators`
- **"No trading allowed"**: Verificar se símbolo permite trading em testes
- **"Invalid stops"**: Problema com Stop Loss/Take Profit → revisar código

---

## ✅ **Próximo Passo Após Teste**

Execute no PowerShell:
```powershell
# Localizar log
Get-Latest-Backtest-Log

# Copiar para workspace
Copy-Item "C:\Users\paulo\...\tester\logs\YYYYMMDD.log" -Destination ".\logs\backtest_v206_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Me avise que terminou para análise comparativa!
```

---

**IMPORTANTE**: Se surgir qualquer mensagem de erro, tire um screenshot e me envie para diagnóstico!
