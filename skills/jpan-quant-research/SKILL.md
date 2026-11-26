---
name: jpan-quant-research
description: 量化研究與回測的紀律。在設計實驗、測試因子或策略、撰寫回測或特徵程式、選參數、或回報研究結果之前使用。
---

# 量化研究紀律 (Quant Research)

## 1. 試驗計數與事前登錄

- **事前登錄**：假設、判準與預計試驗次數，在看結果前 commit；研究 PR 保留這個 commit，不 squash，以 merge commit 合併
- K 計入所有試過的變體：參數、universe、持倉期、丟掉的失敗試驗；每次試驗都進日誌，包含失敗的
- 先減少 K 再談校正：沒有領域依據不做參數掃描或特徵挖掘；要提高檢定力先擴大樣本（更長歷史、更多標的）
- N 選一要做多重檢定校正（DSR、Holm 或 BY），不直接報 t 值
- 每次 run 有可追溯的 run id（例如 MLflow），寫進日誌與報告；追不到就重跑，不憑記憶或舊報告

## 2. 忠於原方法

- 測已發表的方法前，先讀原論文與官方實作；第一個實驗照原定義與設定重現
- 所有偏離都寫明；結論只適用於測過的用法

## 3. 前視與時間戳

- 特徵只用「可得時間 ≤ 決策時點」的資料：對齊用 `join_asof(strategy="backward")`，配對發布時間，不是報表期間結束日；總經資料用初值
- 新資料源先用官方資料確認時間戳語意（時區、標的是區間開始或結束、日期歸屬）；轉換只寫一處
- panel 的 shift、rolling 按資產分組（`.over(asset)`／`groupby`），照交易日曆而非列序；截面操作一律 `.over(date)`
- 不 backward fill；forward fill 一定設 limit；Polars 的 `fill_null` 不處理 NaN，先 `fill_nan(None)`
- universe 用當時的成分，包含已下市；特徵用還原價，成交模擬用未還原價
- IS/OOS 只依時間切；標籤重疊時 purge 與 embargo 至少一個標籤長度；重疊前瞻報酬的 t 值用非重疊樣本或 HAC
- regime 標籤要因果地計算（expanding 門檻，或 walk-forward 重新 fit）；用全樣本 fit 的標籤評估分 regime 績效是循環論證

## 4. 成交真實性

- T 收盤才產生的訊號在 T+1（開盤或 VWAP）成交，不用 T 的收盤價
- 漲跌停鎖死或零成交時不能成交；下市要認列損失，不 ffill 帶過；空方部位扣借券成本
- 樣本太小時回傳 `None` 並記警告，不輸出不可靠的數字
