import feedparser
import pandas as pd
from newspaper import Article, Config
import time
import random
from datetime import datetime

# Configuration
QUERIES = [
    {"medio": "Infobae", "query": "site:infobae.com reforma laboral"},
    {"medio": "Pagina 12", "query": "site:pagina12.com.ar reforma laboral"},
    {"medio": "Clarin", "query": "site:clarin.com reforma laboral"},
    {"medio": "El Destape", "query": "site:eldestapeweb.com reforma laboral"} 
]

OUTPUT_FILE = "dataset_reforma_final.csv"

config = Config()
config.browser_user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
config.request_timeout = 10

def obtener_links_rss(query_string):
    query_encoded = query_string.replace(" ", "%20")
    rss_url = f"https://news.google.com/rss/search?q={query_encoded}&hl=es-419&gl=AR&ceid=AR:es-419"
    print(f"Consultando RSS: {query_string}...")
    feed = feedparser.parse(rss_url)
    return feed.entries

def intentar_descargar_texto(url):
    try:
        article = Article(url, config=config)
        article.download()
        article.parse()
        return article.text
    except Exception:
        return "" 

# Ejecución
datos = []

for item in QUERIES:
    medio = item['medio']
    entradas = obtener_links_rss(item['query'])
    
    print(f"Procesando {len(entradas)} noticias de {medio}...")
    
    # Tomamos 100 noticias por medio
    for i, entry in enumerate(entradas[:100]):
        
        titulo = entry.title
        fecha = entry.published
        link = entry.link
        
        print(f"   [{i+1}] Guardando: {titulo[:40]}...")
        
        # 1. Intentamos bajar el texto
        texto_completo = intentar_descargar_texto(link)
        
        # 2. Guardamos TODO 
        datos.append({
            'fecha': fecha,
            'medio': medio,
            'titulo': titulo,
            'texto': texto_completo,
            'url': link
        })
        
        # Pausa muy breve para agilizar
        time.sleep(0.5)

# Guardado
if len(datos) > 0:
    df = pd.DataFrame(datos)
    df.to_csv(OUTPUT_FILE, index=False, encoding='utf-8')
    print(f"Se creó el archivo {OUTPUT_FILE}")
    print(f"Total de noticias: {len(df)}")
    print(df['medio'].value_counts())
    
    # Chequeo de calidad
    con_texto = df[df['texto'].str.len() > 100]
    print(f"Noticias con texto completo recuperado: {len(con_texto)}")
else:
    print("La lista sigue vacía.")