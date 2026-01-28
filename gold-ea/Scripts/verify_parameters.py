#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================
Gold EA Professional v2.0 - Script de Vérification des Paramètres SL/TP
============================================================
Ce script analyse le fichier CSV de vérification des paramètres
pour s'assurer que les multiplicateurs SL/TP sont correctement appliqués.

Usage:
    python verify_parameters.py [chemin_vers_csv]

Si aucun chemin n'est fourni, le script cherche dans le dossier courant.

Auteur: Gold EA Professional
Version: 2.0
Python: 3.8+
============================================================
"""

import sys
import os
from pathlib import Path
from datetime import datetime
from typing import Tuple, List, Dict, Optional

# Vérifier les dépendances
try:
    import pandas as pd
    import matplotlib.pyplot as plt
    import numpy as np
    PLOTTING_AVAILABLE = True
except ImportError:
    PLOTTING_AVAILABLE = False
    print("Note: matplotlib/numpy non disponibles. Les graphiques seront désactivés.")
    print("Installez avec: pip install pandas matplotlib numpy")
    try:
        import pandas as pd
    except ImportError:
        print("ERREUR: pandas est requis. Installez avec: pip install pandas")
        sys.exit(1)


# =============================================================================
# Configuration
# =============================================================================
class Config:
    """Configuration du script de vérification"""

    # Paramètres cibles (valeurs attendues)
    TARGET_SL_MULTIPLIER = 1.50
    TARGET_TP_MULTIPLIER = 3.00
    TARGET_RR_RATIO = 2.00

    # Tolérance pour la validation (5%)
    TOLERANCE_PERCENT = 0.05

    # Colonnes du CSV
    CSV_COLUMNS = [
        'Timestamp', 'TradeNumber', 'Input_SL_Multiplier', 'Input_TP_Multiplier',
        'ATR_Value', 'Entry_Price', 'Actual_SL_Price', 'Actual_TP_Price',
        'SL_Distance_Pips', 'TP_Distance_Pips', 'Calculated_SL_Multiplier',
        'Calculated_TP_Multiplier', 'RR_Ratio', 'Match_Status'
    ]

    # Nom du fichier de sortie pour le rapport
    REPORT_FILE = "verification_report.txt"
    GRAPH_FILE = "verification_graph.png"


# =============================================================================
# Fonctions de Vérification
# =============================================================================
def find_csv_file(search_path: str = None) -> Optional[Path]:
    """
    Recherche le fichier CSV de vérification des paramètres.

    Args:
        search_path: Chemin de recherche (optionnel)

    Returns:
        Chemin vers le fichier CSV ou None si non trouvé
    """
    # Patterns de recherche
    patterns = [
        "*parameters_verification*.csv",
        "GoldEA_parameters_verification*.csv",
        "*param*verif*.csv"
    ]

    # Dossiers de recherche
    search_dirs = [
        Path(search_path) if search_path else Path.cwd(),
        Path.cwd(),
        Path.home() / "AppData" / "Roaming" / "MetaQuotes" / "Terminal",
    ]

    for search_dir in search_dirs:
        if not search_dir.exists():
            continue

        for pattern in patterns:
            # Recherche récursive
            matches = list(search_dir.rglob(pattern))
            if matches:
                # Prendre le plus récent
                matches.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                return matches[0]

    return None


def load_csv(filepath: Path) -> pd.DataFrame:
    """
    Charge le fichier CSV de vérification.

    Args:
        filepath: Chemin vers le fichier CSV

    Returns:
        DataFrame pandas avec les données
    """
    print(f"\n📂 Chargement du fichier: {filepath}")

    try:
        df = pd.read_csv(filepath)
        print(f"   ✓ {len(df)} trades chargés")
        return df
    except Exception as e:
        print(f"   ✗ Erreur de chargement: {e}")
        raise


def validate_parameters(df: pd.DataFrame, tolerance: float = 0.05) -> Tuple[pd.DataFrame, Dict]:
    """
    Valide que les paramètres calculés correspondent aux paramètres configurés.

    Args:
        df: DataFrame avec les données de vérification
        tolerance: Tolérance de validation (défaut: 5%)

    Returns:
        Tuple (DataFrame avec validation, statistiques)
    """
    stats = {
        'total_trades': len(df),
        'ok_trades': 0,
        'error_trades': 0,
        'sl_errors': 0,
        'tp_errors': 0,
        'both_errors': 0,
        'avg_input_sl': 0,
        'avg_input_tp': 0,
        'avg_calc_sl': 0,
        'avg_calc_tp': 0,
        'avg_rr': 0,
        'errors_list': []
    }

    # Vérifier chaque trade
    validation_results = []

    for idx, row in df.iterrows():
        input_sl = row.get('Input_SL_Multiplier', 0)
        input_tp = row.get('Input_TP_Multiplier', 0)
        calc_sl = row.get('Calculated_SL_Multiplier', 0)
        calc_tp = row.get('Calculated_TP_Multiplier', 0)

        # Calcul des tolérances
        sl_tolerance = input_sl * tolerance
        tp_tolerance = input_tp * tolerance

        # Vérification
        sl_ok = abs(calc_sl - input_sl) <= sl_tolerance
        tp_ok = abs(calc_tp - input_tp) <= tp_tolerance

        if sl_ok and tp_ok:
            status = "OK"
            stats['ok_trades'] += 1
        elif sl_ok:
            status = "TP_ERROR"
            stats['tp_errors'] += 1
            stats['error_trades'] += 1
            stats['errors_list'].append({
                'trade': row.get('TradeNumber', idx),
                'type': 'TP_ERROR',
                'expected_tp': input_tp,
                'actual_tp': calc_tp
            })
        elif tp_ok:
            status = "SL_ERROR"
            stats['sl_errors'] += 1
            stats['error_trades'] += 1
            stats['errors_list'].append({
                'trade': row.get('TradeNumber', idx),
                'type': 'SL_ERROR',
                'expected_sl': input_sl,
                'actual_sl': calc_sl
            })
        else:
            status = "BOTH_ERROR"
            stats['both_errors'] += 1
            stats['error_trades'] += 1
            stats['errors_list'].append({
                'trade': row.get('TradeNumber', idx),
                'type': 'BOTH_ERROR',
                'expected_sl': input_sl,
                'actual_sl': calc_sl,
                'expected_tp': input_tp,
                'actual_tp': calc_tp
            })

        validation_results.append(status)

    # Ajouter la colonne de validation
    df['Validation_Status'] = validation_results

    # Calculer les moyennes
    stats['avg_input_sl'] = df['Input_SL_Multiplier'].mean() if 'Input_SL_Multiplier' in df else 0
    stats['avg_input_tp'] = df['Input_TP_Multiplier'].mean() if 'Input_TP_Multiplier' in df else 0
    stats['avg_calc_sl'] = df['Calculated_SL_Multiplier'].mean() if 'Calculated_SL_Multiplier' in df else 0
    stats['avg_calc_tp'] = df['Calculated_TP_Multiplier'].mean() if 'Calculated_TP_Multiplier' in df else 0
    stats['avg_rr'] = df['RR_Ratio'].mean() if 'RR_Ratio' in df else 0

    return df, stats


def print_report(stats: Dict, target_sl: float = 1.50, target_tp: float = 3.00):
    """
    Affiche le rapport de vérification.

    Args:
        stats: Statistiques de validation
        target_sl: SL multiplier cible
        target_tp: TP multiplier cible
    """
    target_rr = target_tp / target_sl

    print("\n" + "=" * 60)
    print("📊 RAPPORT DE VÉRIFICATION DES PARAMÈTRES SL/TP")
    print("=" * 60)

    # Résumé global
    total = stats['total_trades']
    ok = stats['ok_trades']
    errors = stats['error_trades']

    ok_percent = (ok / total * 100) if total > 0 else 0

    print(f"\n📈 RÉSUMÉ GLOBAL:")
    print(f"   Total des trades analysés: {total}")

    if ok_percent == 100:
        print(f"   ✅ {ok}/{total} trades avec paramètres corrects ({ok_percent:.1f}%)")
    else:
        print(f"   ⚠️  {ok}/{total} trades avec paramètres corrects ({ok_percent:.1f}%)")
        print(f"   ❌ {errors}/{total} trades avec erreurs ({100-ok_percent:.1f}%)")

    # Détail des erreurs
    if errors > 0:
        print(f"\n   Détail des erreurs:")
        print(f"      - Erreurs SL uniquement: {stats['sl_errors']}")
        print(f"      - Erreurs TP uniquement: {stats['tp_errors']}")
        print(f"      - Erreurs SL + TP: {stats['both_errors']}")

    # Comparaison des moyennes
    print(f"\n📏 COMPARAISON DES MULTIPLIERS:")
    print(f"   ┌{'─'*50}┐")
    print(f"   │ {'Paramètre':<20} {'Cible':<10} {'Réel':<10} {'Status':<8} │")
    print(f"   ├{'─'*50}┤")

    # SL Multiplier
    sl_diff = abs(stats['avg_calc_sl'] - target_sl)
    sl_status = "✅ OK" if sl_diff <= target_sl * 0.05 else "❌ ERREUR"
    print(f"   │ {'SL Multiplier':<20} {target_sl:<10.2f} {stats['avg_calc_sl']:<10.2f} {sl_status:<8} │")

    # TP Multiplier
    tp_diff = abs(stats['avg_calc_tp'] - target_tp)
    tp_status = "✅ OK" if tp_diff <= target_tp * 0.05 else "❌ ERREUR"
    print(f"   │ {'TP Multiplier':<20} {target_tp:<10.2f} {stats['avg_calc_tp']:<10.2f} {tp_status:<8} │")

    # R:R Ratio
    rr_diff = abs(stats['avg_rr'] - target_rr)
    rr_status = "✅ OK" if rr_diff <= target_rr * 0.05 else "❌ ERREUR"
    print(f"   │ {'R:R Ratio':<20} {target_rr:<10.2f} {stats['avg_rr']:<10.2f} {rr_status:<8} │")

    print(f"   └{'─'*50}┘")

    # Estimation du profit
    print(f"\n💰 ESTIMATION DE L'IMPACT:")
    if stats['avg_rr'] >= 1.5:
        print(f"   Avec un R:R de {stats['avg_rr']:.2f}, le système devrait être rentable")
        print(f"   Win Rate breakeven: {100 / (1 + stats['avg_rr']):.1f}%")
        print(f"   Profit attendu (avec 66% WR): POSITIF ✅")
    else:
        print(f"   ⚠️  Avec un R:R de {stats['avg_rr']:.2f}, le système pourrait être déficitaire")
        print(f"   Win Rate breakeven requis: {100 / (1 + stats['avg_rr']):.1f}%")

    # Liste des trades avec erreurs
    if stats['errors_list'] and len(stats['errors_list']) <= 10:
        print(f"\n❌ TRADES AVEC ERREURS:")
        for error in stats['errors_list']:
            trade_num = error.get('trade', '?')
            error_type = error.get('type', '?')

            if error_type == 'SL_ERROR':
                print(f"   Trade #{trade_num}: SL attendu={error.get('expected_sl', 0):.2f}, "
                      f"réel={error.get('actual_sl', 0):.2f}")
            elif error_type == 'TP_ERROR':
                print(f"   Trade #{trade_num}: TP attendu={error.get('expected_tp', 0):.2f}, "
                      f"réel={error.get('actual_tp', 0):.2f}")
            else:
                print(f"   Trade #{trade_num}: SL/TP incorrects")
    elif stats['errors_list']:
        print(f"\n❌ {len(stats['errors_list'])} trades avec erreurs (voir fichier de rapport)")

    # Conclusion
    print(f"\n{'=' * 60}")
    if ok_percent == 100 and sl_status == "✅ OK" and tp_status == "✅ OK":
        print("✅ CONCLUSION: Tous les paramètres sont CORRECTS!")
        print("   Le système utilise bien SL=1.5×ATR et TP=3.0×ATR")
        print("   R:R = 2.0 comme configuré")
    else:
        print("⚠️  CONCLUSION: Des anomalies ont été détectées!")
        print("   Vérifiez les paramètres dans le fichier .set")
        print("   et recompilez l'EA après nettoyage du cache")
    print("=" * 60 + "\n")


def create_graph(df: pd.DataFrame, output_path: Path):
    """
    Crée un graphique de comparaison Input vs Calculated.

    Args:
        df: DataFrame avec les données
        output_path: Chemin de sortie pour le graphique
    """
    if not PLOTTING_AVAILABLE:
        print("⚠️  Graphiques désactivés (matplotlib non disponible)")
        return

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Gold EA - Vérification des Paramètres SL/TP', fontsize=14, fontweight='bold')

    # 1. SL Multiplier: Input vs Calculated
    ax1 = axes[0, 0]
    trades = df['TradeNumber'].values
    ax1.scatter(trades, df['Input_SL_Multiplier'], label='Configuré', alpha=0.7, marker='o', s=50)
    ax1.scatter(trades, df['Calculated_SL_Multiplier'], label='Calculé', alpha=0.7, marker='x', s=50)
    ax1.axhline(y=1.5, color='g', linestyle='--', label='Cible (1.5)')
    ax1.set_xlabel('Numéro de Trade')
    ax1.set_ylabel('SL Multiplier (×ATR)')
    ax1.set_title('SL Multiplier: Configuré vs Calculé')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # 2. TP Multiplier: Input vs Calculated
    ax2 = axes[0, 1]
    ax2.scatter(trades, df['Input_TP_Multiplier'], label='Configuré', alpha=0.7, marker='o', s=50)
    ax2.scatter(trades, df['Calculated_TP_Multiplier'], label='Calculé', alpha=0.7, marker='x', s=50)
    ax2.axhline(y=3.0, color='g', linestyle='--', label='Cible (3.0)')
    ax2.set_xlabel('Numéro de Trade')
    ax2.set_ylabel('TP Multiplier (×ATR)')
    ax2.set_title('TP Multiplier: Configuré vs Calculé')
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    # 3. R:R Ratio
    ax3 = axes[1, 0]
    ax3.bar(trades, df['RR_Ratio'], alpha=0.7, color='steelblue')
    ax3.axhline(y=2.0, color='g', linestyle='--', linewidth=2, label='Cible (2.0)')
    ax3.axhline(y=1.0, color='r', linestyle='--', linewidth=1, label='Seuil (1.0)')
    ax3.set_xlabel('Numéro de Trade')
    ax3.set_ylabel('R:R Ratio')
    ax3.set_title('Risk/Reward Ratio par Trade')
    ax3.legend()
    ax3.grid(True, alpha=0.3)

    # 4. Distribution du statut de match
    ax4 = axes[1, 1]
    if 'Match_Status' in df.columns:
        status_counts = df['Match_Status'].value_counts()
    elif 'Validation_Status' in df.columns:
        status_counts = df['Validation_Status'].value_counts()
    else:
        status_counts = pd.Series({'N/A': len(df)})

    colors = {'OK': 'green', 'ERROR': 'red', 'TP_ERROR': 'orange',
              'SL_ERROR': 'yellow', 'BOTH_ERROR': 'darkred', 'N/A': 'gray'}
    bar_colors = [colors.get(s, 'gray') for s in status_counts.index]

    ax4.bar(status_counts.index, status_counts.values, color=bar_colors, alpha=0.7)
    ax4.set_xlabel('Statut')
    ax4.set_ylabel('Nombre de Trades')
    ax4.set_title('Distribution des Statuts de Validation')
    ax4.grid(True, alpha=0.3)

    # Ajouter les pourcentages sur les barres
    total = status_counts.sum()
    for i, (status, count) in enumerate(status_counts.items()):
        pct = count / total * 100
        ax4.text(i, count + 0.5, f'{pct:.1f}%', ha='center', fontsize=10)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"📊 Graphique sauvegardé: {output_path}")
    plt.close()


def save_report(stats: Dict, output_path: Path, target_sl: float = 1.50, target_tp: float = 3.00):
    """
    Sauvegarde le rapport dans un fichier texte.

    Args:
        stats: Statistiques de validation
        output_path: Chemin du fichier de sortie
        target_sl: SL multiplier cible
        target_tp: TP multiplier cible
    """
    target_rr = target_tp / target_sl

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("=" * 60 + "\n")
        f.write("RAPPORT DE VÉRIFICATION DES PARAMÈTRES SL/TP\n")
        f.write(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 60 + "\n\n")

        f.write("CONFIGURATION CIBLE:\n")
        f.write(f"  SL Multiplier: {target_sl}\n")
        f.write(f"  TP Multiplier: {target_tp}\n")
        f.write(f"  R:R Ratio: {target_rr}\n\n")

        f.write("RÉSULTATS:\n")
        f.write(f"  Total trades: {stats['total_trades']}\n")
        f.write(f"  Trades OK: {stats['ok_trades']}\n")
        f.write(f"  Trades avec erreurs: {stats['error_trades']}\n\n")

        f.write("MOYENNES CALCULÉES:\n")
        f.write(f"  SL Multiplier moyen: {stats['avg_calc_sl']:.2f} (cible: {target_sl})\n")
        f.write(f"  TP Multiplier moyen: {stats['avg_calc_tp']:.2f} (cible: {target_tp})\n")
        f.write(f"  R:R Ratio moyen: {stats['avg_rr']:.2f} (cible: {target_rr})\n\n")

        if stats['errors_list']:
            f.write("TRADES AVEC ERREURS:\n")
            for error in stats['errors_list']:
                f.write(f"  Trade #{error.get('trade', '?')}: {error.get('type', '?')}\n")

        f.write("\n" + "=" * 60 + "\n")

    print(f"📄 Rapport sauvegardé: {output_path}")


# =============================================================================
# Main
# =============================================================================
def main():
    """Fonction principale"""
    print("\n" + "=" * 60)
    print("🔍 GOLD EA - VÉRIFICATION DES PARAMÈTRES SL/TP")
    print("=" * 60)

    # Déterminer le chemin du fichier CSV
    csv_path = None

    if len(sys.argv) > 1:
        # Chemin fourni en argument
        csv_path = Path(sys.argv[1])
        if not csv_path.exists():
            print(f"❌ Fichier non trouvé: {csv_path}")
            sys.exit(1)
    else:
        # Recherche automatique
        csv_path = find_csv_file()
        if not csv_path:
            print("❌ Fichier parameters_verification.csv non trouvé!")
            print("\n💡 Solutions:")
            print("   1. Spécifiez le chemin: python verify_parameters.py <chemin>")
            print("   2. Copiez le fichier CSV dans le dossier courant")
            print("   3. Vérifiez que l'EA a bien généré le fichier")
            sys.exit(1)

    # Charger les données
    try:
        df = load_csv(csv_path)
    except Exception as e:
        print(f"❌ Erreur: {e}")
        sys.exit(1)

    # Valider les paramètres
    df, stats = validate_parameters(df, Config.TOLERANCE_PERCENT)

    # Afficher le rapport
    print_report(stats, Config.TARGET_SL_MULTIPLIER, Config.TARGET_TP_MULTIPLIER)

    # Créer le graphique
    graph_path = csv_path.parent / Config.GRAPH_FILE
    create_graph(df, graph_path)

    # Sauvegarder le rapport
    report_path = csv_path.parent / Config.REPORT_FILE
    save_report(stats, report_path, Config.TARGET_SL_MULTIPLIER, Config.TARGET_TP_MULTIPLIER)

    # Code de sortie
    if stats['ok_trades'] == stats['total_trades']:
        print("✅ Vérification terminée avec succès!")
        return 0
    else:
        print("⚠️  Des anomalies ont été détectées.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
