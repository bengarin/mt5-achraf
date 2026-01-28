# Guide d'Installation Complet - Gold EA Professional v2.0

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Pré-requis](#pré-requis)
3. [Installation des Fichiers](#installation-des-fichiers)
4. [Configuration du Fichier .set](#configuration-du-fichier-set)
5. [Compilation de l'EA](#compilation-de-lea)
6. [Nettoyage du Cache Strategy Tester](#nettoyage-du-cache-strategy-tester)
7. [Lancer un Backtest](#lancer-un-backtest)
8. [Vérification avec Python](#vérification-avec-python)
9. [Interprétation des Résultats](#interprétation-des-résultats)
10. [Dépannage](#dépannage)

---

## Vue d'ensemble

Ce guide vous accompagne dans l'installation et la configuration de **Gold EA Professional v2.0** avec les paramètres SL/TP corrigés:

| Paramètre | Ancienne Valeur | Nouvelle Valeur |
|-----------|-----------------|-----------------|
| SL Multiplier | 2.5 × ATR | **1.5 × ATR** |
| TP Multiplier | 1.5 × ATR | **3.0 × ATR** |
| R:R Ratio | 0.49 | **2.0** |

---

## Pré-requis

### Logiciels Requis

- **MetaTrader 5** (build 3000 ou supérieur)
- **MetaEditor 5** (inclus avec MT5)
- **Python 3.8+** (pour le script de vérification)

### Packages Python

```bash
pip install pandas matplotlib numpy
```

---

## Installation des Fichiers

### Étape 1: Localiser le Dossier MQL5

1. Ouvrez MetaTrader 5
2. Allez dans **Fichier** → **Ouvrir le dossier de données**
3. Naviguez vers `MQL5/`

### Étape 2: Copier les Fichiers

Copiez les fichiers dans les emplacements suivants:

```
MQL5/
├── Experts/
│   └── Gold EA/                    ← Créer ce dossier
│       ├── GoldEA_Pro.mq5          ← Fichier principal
│       └── Include/
│           ├── Logger.mqh
│           ├── RiskManager.mqh
│           └── TradeExecutor.mqh
│
├── Presets/
│   └── GoldEA_CORRECT.set          ← Fichier de configuration
│
└── Files/
    └── (Les CSV seront générés ici)
```

### Commandes de Copie (Windows)

```batch
REM Depuis le dossier du projet:
xcopy /E /I gold-ea\*.mq5 "%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Experts\Gold EA\"
xcopy /E /I gold-ea\Include "%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Experts\Gold EA\Include\"
copy gold-ea\Presets\GoldEA_CORRECT.set "%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Presets\"
```

> **Note**: Remplacez `<TERMINAL_ID>` par l'identifiant de votre terminal MT5.

---

## Configuration du Fichier .set

### Étape 1: Vérifier le Contenu

Ouvrez `GoldEA_CORRECT.set` et vérifiez ces lignes critiques:

```ini
; === PARAMÈTRES SL/TP (CRITIQUES) ===
InpSLMultiplier=1.50     ; ← DOIT être 1.50
InpTPMultiplier=3.00     ; ← DOIT être 3.00
```

### Étape 2: Installer le Preset

1. Copiez `GoldEA_CORRECT.set` dans `MQL5/Presets/`
2. Le fichier sera disponible dans le Strategy Tester

### Charger le Preset dans Strategy Tester

1. Ouvrez le Strategy Tester (Ctrl+R)
2. Sélectionnez **Gold EA Pro**
3. Cliquez sur l'icône engrenage (⚙️) → **Charger**
4. Sélectionnez `GoldEA_CORRECT.set`

---

## Compilation de l'EA

### Étape 1: Ouvrir MetaEditor

1. Dans MetaTrader 5: **Outils** → **MetaQuotes Language Editor** (ou F4)
2. Ou lancez directement MetaEditor depuis le menu Démarrer

### Étape 2: Ouvrir le Fichier

1. **Fichier** → **Ouvrir** (Ctrl+O)
2. Naviguez vers `MQL5/Experts/Gold EA/GoldEA_Pro.mq5`

### Étape 3: Compiler

1. Appuyez sur **F7** ou cliquez sur **Compiler**
2. Vérifiez la fenêtre "Erreurs":
   - ✅ **0 erreur(s), 0 avertissement(s)** = Succès
   - ❌ Si des erreurs apparaissent, voir la section Dépannage

### Résultat Attendu

```
Compiling 'GoldEA_Pro.mq5'...
Including 'Include\Logger.mqh'
Including 'Include\RiskManager.mqh'
Including 'Include\TradeExecutor.mqh'
Including 'Trade\Trade.mqh'

0 error(s), 0 warning(s)
```

---

## Nettoyage du Cache Strategy Tester

**CRITIQUE**: Le Strategy Tester peut utiliser d'anciens paramètres en cache.

### Méthode 1: Via MetaTrader

1. **Fichier** → **Ouvrir le dossier de données**
2. Naviguez vers `Tester/`
3. Supprimez tous les fichiers `.opt` et `.set` liés à GoldEA

### Méthode 2: Nettoyage Complet

```batch
REM Windows - Exécuter en tant qu'Administrateur
cd "%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\Tester"
del /Q cache\*.*
del /Q *.opt
del /Q *.set

REM Redémarrer MetaTrader 5
```

### Méthode 3: Renommer l'EA

Si le problème persiste:
1. Renommez `GoldEA_Pro.mq5` en `GoldEA_Pro_v2.mq5`
2. Recompilez
3. Utilisez le nouvel EA dans le Strategy Tester

---

## Lancer un Backtest

### Configuration du Strategy Tester

1. **Ctrl+R** pour ouvrir le Strategy Tester
2. Configurez:

| Paramètre | Valeur |
|-----------|--------|
| Expert | Gold EA Pro |
| Symbole | XAUUSD |
| Période | H1 (recommandé) |
| Date | 1 an minimum |
| Modélisation | Every tick based on real ticks |
| Dépôt initial | 10000 |
| Levier | 1:100 |

### Charger les Paramètres Corrects

1. Cliquez sur **Paramètres de l'expert** (icône engrenage)
2. Cliquez sur **Charger** (icône dossier)
3. Sélectionnez `GoldEA_CORRECT.set`
4. **VÉRIFIEZ** que:
   - `InpSLMultiplier = 1.50`
   - `InpTPMultiplier = 3.00`

### Lancer le Test

1. Cliquez sur **Démarrer**
2. Attendez la fin du test
3. Vérifiez les fichiers CSV générés

---

## Vérification avec Python

### Étape 1: Localiser le Fichier CSV

Après le backtest, trouvez le fichier:
```
MQL5/Files/GoldEA_parameters_verification_YYYYMMDD.csv
```

### Étape 2: Exécuter le Script

```bash
# Depuis le dossier du projet
cd gold-ea/Scripts

# Option 1: Recherche automatique
python verify_parameters.py

# Option 2: Chemin spécifique
python verify_parameters.py "C:\Users\...\MQL5\Files\GoldEA_parameters_verification_20260128.csv"
```

### Résultat Attendu (Succès)

```
============================================================
📊 RAPPORT DE VÉRIFICATION DES PARAMÈTRES SL/TP
============================================================

📈 RÉSUMÉ GLOBAL:
   Total des trades analysés: 89
   ✅ 89/89 trades avec paramètres corrects (100.0%)

📏 COMPARAISON DES MULTIPLIERS:
   ┌──────────────────────────────────────────────────────┐
   │ Paramètre            Cible      Réel       Status    │
   ├──────────────────────────────────────────────────────┤
   │ SL Multiplier        1.50       1.50       ✅ OK     │
   │ TP Multiplier        3.00       3.00       ✅ OK     │
   │ R:R Ratio            2.00       2.00       ✅ OK     │
   └──────────────────────────────────────────────────────┘

💰 ESTIMATION DE L'IMPACT:
   Avec un R:R de 2.00, le système devrait être rentable
   Win Rate breakeven: 33.3%
   Profit attendu (avec 66% WR): POSITIF ✅

============================================================
✅ CONCLUSION: Tous les paramètres sont CORRECTS!
============================================================
```

---

## Interprétation des Résultats

### Fichiers Générés

| Fichier | Description |
|---------|-------------|
| `parameters_verification_*.csv` | Vérification SL/TP pour chaque trade |
| `trades_*.csv` | Journal des trades exécutés |
| `performance_*.csv` | Métriques de performance |
| `errors_*.csv` | Journal des erreurs |
| `verification_report.txt` | Rapport de validation |
| `verification_graph.png` | Graphique de comparaison |

### Colonnes du CSV de Vérification

| Colonne | Description |
|---------|-------------|
| `Input_SL_Multiplier` | Valeur configurée (devrait être 1.50) |
| `Input_TP_Multiplier` | Valeur configurée (devrait être 3.00) |
| `Calculated_SL_Multiplier` | Valeur calculée depuis les prix |
| `Calculated_TP_Multiplier` | Valeur calculée depuis les prix |
| `RR_Ratio` | Ratio Risk/Reward réel |
| `Match_Status` | OK = correct, ERROR = problème |

### Critères de Succès

✅ **Test Réussi si:**
- 100% des trades ont `Match_Status = OK`
- `Calculated_SL_Multiplier ≈ 1.50` (±5%)
- `Calculated_TP_Multiplier ≈ 3.00` (±5%)
- `RR_Ratio ≈ 2.00` (±5%)
- Net Profit > $50 (avec 66% Win Rate)

---

## Dépannage

### Problème: Erreurs de Compilation

**Solution:**
1. Vérifiez que tous les fichiers `.mqh` sont dans `Include/`
2. Vérifiez les chemins d'inclusion dans `GoldEA_Pro.mq5`
3. Assurez-vous d'avoir la bibliothèque Trade standard (`<Trade\Trade.mqh>`)

### Problème: SL/TP Toujours Incorrects

**Solutions:**
1. **Videz le cache** (voir section 6)
2. **Vérifiez les paramètres** dans la fenêtre des inputs avant le test
3. **Renommez l'EA** pour éviter le cache
4. **Supprimez** `GoldEA_Pro.ex5` et recompilez

### Problème: Fichier CSV Non Généré

**Solutions:**
1. Vérifiez que `InpEnableLogging = true`
2. Vérifiez les permissions d'écriture dans `MQL5/Files/`
3. Regardez dans l'onglet "Journal" pour les erreurs

### Problème: Script Python Échoue

**Solutions:**
1. Installez les dépendances: `pip install pandas matplotlib numpy`
2. Vérifiez la version de Python: `python --version` (3.8+ requis)
3. Vérifiez le chemin vers le CSV

---

## Support

En cas de problème:
1. Vérifiez d'abord cette documentation
2. Consultez l'onglet "Journal" dans MetaTrader
3. Analysez les fichiers CSV d'erreurs générés
4. Contactez le support avec les logs complets

---

*Gold EA Professional v2.0 - Guide d'Installation*
*Dernière mise à jour: 2026-01-28*
