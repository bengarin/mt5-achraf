# Checklist de Validation - Gold EA Professional v2.0

## Instructions

Cochez chaque étape une fois complétée. Toutes les étapes doivent être validées pour confirmer que la correction est effective.

---

## Phase 1: Installation des Fichiers

- [ ] **1.1** Fichier `GoldEA_CORRECT.set` créé et placé dans `MQL5/Presets/`
- [ ] **1.2** Fichier `Logger.mqh` modifié avec la nouvelle fonction `LogParametersVerification()`
- [ ] **1.3** Fichier `RiskManager.mqh` présent dans `MQL5/Experts/Gold EA/Include/`
- [ ] **1.4** Fichier `TradeExecutor.mqh` présent dans `MQL5/Experts/Gold EA/Include/`
- [ ] **1.5** Fichier `GoldEA_Pro.mq5` modifié pour appeler le logging dans `ExecuteTrade()`
- [ ] **1.6** Script `verify_parameters.py` présent et exécutable

---

## Phase 2: Compilation

- [ ] **2.1** MetaEditor ouvert avec `GoldEA_Pro.mq5`
- [ ] **2.2** Compilation effectuée (F7)
- [ ] **2.3** Résultat: **0 erreur(s)**
- [ ] **2.4** Résultat: **0 avertissement(s)** (ou avertissements non critiques uniquement)
- [ ] **2.5** Fichier `GoldEA_Pro.ex5` généré dans `MQL5/Experts/Gold EA/`

---

## Phase 3: Nettoyage du Cache

- [ ] **3.1** Dossier `Tester/cache/` vidé
- [ ] **3.2** Fichiers `.opt` supprimés du dossier `Tester/`
- [ ] **3.3** MetaTrader 5 redémarré après le nettoyage
- [ ] **3.4** (Optionnel) EA renommé si problème de cache persistant

---

## Phase 4: Configuration du Backtest

- [ ] **4.1** Strategy Tester ouvert (Ctrl+R)
- [ ] **4.2** Expert Advisor sélectionné: `Gold EA Pro`
- [ ] **4.3** Symbole: `XAUUSD` (ou équivalent Gold)
- [ ] **4.4** Période: `H1` ou supérieure
- [ ] **4.5** Modélisation: `Every tick based on real ticks`
- [ ] **4.6** Fichier `.set` chargé: `GoldEA_CORRECT.set`

---

## Phase 5: Vérification des Paramètres (CRITIQUE)

Avant de lancer le test, vérifiez **manuellement** les valeurs dans la fenêtre des paramètres:

- [ ] **5.1** `InpSLMultiplier` = **1.50** (pas 2.50 !)
- [ ] **5.2** `InpTPMultiplier` = **3.00** (pas 1.50 !)
- [ ] **5.3** `InpEnableLogging` = **true**
- [ ] **5.4** `InpEnableParameterVerification` = **true**
- [ ] **5.5** `InpLogLevel` = **2** ou supérieur

**Capture d'écran recommandée** avant de lancer le test.

---

## Phase 6: Exécution du Backtest

- [ ] **6.1** Test lancé avec bouton "Démarrer"
- [ ] **6.2** Test terminé sans erreurs critiques
- [ ] **6.3** Onglet "Journal" vérifié (pas d'erreurs rouge)
- [ ] **6.4** Nombre de trades exécutés > 50

---

## Phase 7: Vérification des Fichiers CSV

- [ ] **7.1** Fichier `GoldEA_parameters_verification_*.csv` généré
- [ ] **7.2** Fichier situé dans `MQL5/Files/`
- [ ] **7.3** Fichier contient des données (pas vide)
- [ ] **7.4** Colonnes présentes:
  - [ ] Timestamp
  - [ ] TradeNumber
  - [ ] Input_SL_Multiplier
  - [ ] Input_TP_Multiplier
  - [ ] Calculated_SL_Multiplier
  - [ ] Calculated_TP_Multiplier
  - [ ] RR_Ratio
  - [ ] Match_Status

---

## Phase 8: Exécution du Script Python

- [ ] **8.1** Python 3.8+ installé: `python --version`
- [ ] **8.2** Packages installés: `pip install pandas matplotlib numpy`
- [ ] **8.3** Script exécuté: `python verify_parameters.py <chemin_csv>`
- [ ] **8.4** Rapport affiché dans le terminal
- [ ] **8.5** Graphique généré: `verification_graph.png`
- [ ] **8.6** Rapport texte généré: `verification_report.txt`

---

## Phase 9: Validation des Résultats (OBJECTIF FINAL)

### Critères de Succès

| Critère | Valeur Attendue | Valeur Obtenue | Status |
|---------|-----------------|----------------|--------|
| SL Multiplier moyen | **1.50** (±5%) | ________ | [ ] OK |
| TP Multiplier moyen | **3.00** (±5%) | ________ | [ ] OK |
| R:R Ratio moyen | **2.00** (±5%) | ________ | [ ] OK |
| Trades avec Match_Status=OK | **100%** | ________% | [ ] OK |
| Win Rate | ~66% | ________% | [ ] OK |
| Net Profit | > **$50** | $________ | [ ] OK |

### Validation Finale

- [ ] **9.1** Tous les trades ont `Match_Status = OK`
- [ ] **9.2** Calculated_SL_Multiplier ≈ 1.50 pour tous les trades
- [ ] **9.3** Calculated_TP_Multiplier ≈ 3.00 pour tous les trades
- [ ] **9.4** RR_Ratio ≈ 2.00 pour tous les trades
- [ ] **9.5** Net Profit positif et significatif (> $50)

---

## Résumé de la Validation

### Date de Validation: _______________

### Résultat Global:

- [ ] **SUCCÈS** - Tous les paramètres sont corrects, le système est prêt pour le trading live
- [ ] **ÉCHEC** - Des anomalies ont été détectées (voir détails ci-dessous)

### Notes / Anomalies Détectées:

```
[Notez ici les problèmes rencontrés et les solutions appliquées]





```

### Validé par: _______________

---

## Actions en Cas d'Échec

Si la validation échoue, suivez ces étapes:

### Si SL/TP Calculés ≠ SL/TP Configurés:

1. [ ] Vérifiez que le fichier `.set` est bien chargé
2. [ ] Videz le cache et recompilez
3. [ ] Renommez l'EA et recommencez
4. [ ] Vérifiez le code source pour des valeurs hardcodées

### Si les CSV ne sont pas générés:

1. [ ] Vérifiez `InpEnableLogging = true`
2. [ ] Vérifiez les permissions du dossier `MQL5/Files/`
3. [ ] Consultez l'onglet Journal pour les erreurs

### Si le Script Python Échoue:

1. [ ] Vérifiez la version de Python
2. [ ] Installez les packages manquants
3. [ ] Vérifiez le chemin du fichier CSV

---

## Historique des Validations

| Date | Version | Résultat | Notes |
|------|---------|----------|-------|
| ______ | v2.0 | _______ | _________________ |
| ______ | _____ | _______ | _________________ |
| ______ | _____ | _______ | _________________ |

---

*Gold EA Professional v2.0 - Checklist de Validation*
*Document créé le: 2026-01-28*
