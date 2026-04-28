#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script para exportar resultados del análisis SQL a archivos CSV

Uso:
    python export_results.py --db postgres_db --user username --output ./results/
    
Dependencias:
    pip install pandas psycopg2-binary
"""

import os
import sys
import argparse
import pandas as pd
import psycopg2
from pathlib import Path
from datetime import datetime

class MercadoLibreAnalysisExporter:
    """Exporta resultados de análisis SQL a CSV"""
    
    def __init__(self, db_name, db_user, db_password, db_host='localhost', db_port=5432, output_dir='./results/'):
        """
        Inicializa la conexión a la base de datos
        
        Args:
            db_name (str): Nombre de la base de datos
            db_user (str): Usuario de PostgreSQL
            db_password (str): Contraseña
            db_host (str): Host de la BD
            db_port (int): Puerto de conexión
            output_dir (str): Directorio de salida
        """
        self.db_name = db_name
        self.db_user = db_user
        self.db_password = db_password
        self.db_host = db_host
        self.db_port = db_port
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.connection = None
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
    def connect(self):
        """Conectar a la base de datos"""
        try:
            self.connection = psycopg2.connect(
                database=self.db_name,
                user=self.db_user,
                password=self.db_password,
                host=self.db_host,
                port=self.db_port
            )
            print(f"✅ Conectado a {self.db_name} en {self.db_host}")
            return True
        except Exception as e:
            print(f"❌ Error al conectar: {e}")
            return False
    
    def execute_query(self, query):
        """Ejecutar consulta SQL y retornar DataFrame"""
        try:
            df = pd.read_sql(query, self.connection)
            return df
        except Exception as e:
            print(f"❌ Error ejecutando query: {e}")
            return None
    
    def export_to_csv(self, df, filename, description=""):
        """Guardar DataFrame a CSV"""
        if df is None or df.empty:
            print(f"⚠️  {filename}: No hay datos para exportar")
            return False
        
        output_path = self.output_dir / f"{filename}_{self.timestamp}.csv"
        try:
            df.to_csv(output_path, index=False, encoding='utf-8-sig')
            print(f"✅ {description}")
            print(f"   Guardado: {output_path}")
            print(f"   Registros: {len(df)}")
            return True
        except Exception as e:
            print(f"❌ Error guardando {filename}: {e}")
            return False
    
    def run_analysis(self):
        """Ejecutar todas las exportaciones"""
        print("\n" + "="*60)
        print("INICIANDO EXPORTACIÓN DE RESULTADOS")
        print("="*60 + "\n")
        
        # Conectar
        if not self.connect():
            return False
        
        try:
            # 1. ANÁLISIS DEL EMBUDO
            print("\n📊 Exportando Análisis del Embudo...")
            funnel_query = open('queries/02_funnel_analysis.sql').read()
            funnel_df = self.execute_query(funnel_query)
            self.export_to_csv(funnel_df, 'funnel_analysis', 
                             "Análisis del embudo de compra por etapa")
            
            # 2. ANÁLISIS DE RETENCIÓN
            print("\n📈 Exportando Análisis de Retención...")
            retention_query = open('queries/03_retention_cohorts.sql').read()
            retention_df = self.execute_query(retention_query)
            self.export_to_csv(retention_df, 'retention_cohorts', 
                             "Análisis de retención por cohortes mensuales")
            
            # 3. EXPLORACIÓN DE DATOS
            print("\n🔍 Exportando Exploración de Datos...")
            exploration_query = open('queries/01_data_exploration.sql').read()
            exploration_df = self.execute_query(exploration_query)
            self.export_to_csv(exploration_df, 'data_exploration', 
                             "Datos de exploración y verificación de calidad")
            
            # 4. INSIGHTS FINALES
            print("\n💡 Exportando Insights Finales...")
            insights_query = open('queries/04_final_insights.sql').read()
            insights_df = self.execute_query(insights_query)
            self.export_to_csv(insights_df, 'final_insights', 
                             "Insights accionables y análisis específicos")
            
            # Resumen
            self._print_summary(funnel_df, retention_df)
            
        except FileNotFoundError as e:
            print(f"❌ No se encontró archivo de queries: {e}")
            return False
        except Exception as e:
            print(f"❌ Error durante la exportación: {e}")
            return False
        finally:
            self.close()
        
        return True
    
    def _print_summary(self, funnel_df, retention_df):
        """Imprimir resumen de los hallazgos principales"""
        print("\n" + "="*60)
        print("RESUMEN DE HALLAZGOS")
        print("="*60 + "\n")
        
        if funnel_df is not None and not funnel_df.empty:
            print("📊 EMBUDO DE COMPRA:")
            for _, row in funnel_df.iterrows():
                print(f"  • {row.get('etapa', 'Etapa')}: {row.get('usuarios', 0)} usuarios " + 
                      f"({row.get('porcentaje', 0):.1f}%)")
        
        if retention_df is not None and not retention_df.empty:
            print("\n📈 RETENCIÓN PROMEDIO:")
            print(f"  • D7:  {retention_df['d7_retention_pct'].mean():.1f}% de los usuarios")
            print(f"  • D14: {retention_df['d14_retention_pct'].mean():.1f}% de los usuarios")
            print(f"  • D28: {retention_df['d28_retention_pct'].mean():.1f}% de los usuarios")
        
        print(f"\n✅ Exportación completada exitosamente")
        print(f"📁 Archivos guardados en: {self.output_dir.absolute()}\n")
    
    def close(self):
        """Cerrar conexión a la base de datos"""
        if self.connection:
            self.connection.close()
            print("🔌 Conexión cerrada")

def main():
    """Función principal"""
    parser = argparse.ArgumentParser(
        description='Exportar resultados del análisis SQL a CSV'
    )
    parser.add_argument('--db', required=True, help='Nombre de la base de datos')
    parser.add_argument('--user', required=True, help='Usuario de PostgreSQL')
    parser.add_argument('--password', required=True, help='Contraseña de PostgreSQL')
    parser.add_argument('--host', default='localhost', help='Host de la BD')
    parser.add_argument('--port', type=int, default=5432, help='Puerto de conexión')
    parser.add_argument('--output', default='./results/', help='Directorio de salida')
    
    args = parser.parse_args()
    
    exporter = MercadoLibreAnalysisExporter(
        db_name=args.db,
        db_user=args.user,
        db_password=args.password,
        db_host=args.host,
        db_port=args.port,
        output_dir=args.output
    )
    
    success = exporter.run_analysis()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
