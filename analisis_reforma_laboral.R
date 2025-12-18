# ==============================================================================
# PROYECTO: Framing analysis - Reforma Laboral Argentina
# AUTOR: Juana Luz Carbajal 
# DESCRIPCIÓN: Análisis de sentimiento y frecuencia léxica comparando 
#              titulares de Infobae vs. Página 12.
# ==============================================================================

if (!require("tidyverse")) install.packages("tidyverse")
if (!require("tidytext")) install.packages("tidytext")
if (!require("tm")) install.packages("tm")
if (!require("scales")) install.packages("scales")

library(tidyverse)
library(tidytext)
library(tm)
library(scales)


archivo_datos <- "C:/Users/juana/Desktop/GitHub/reforma_laboral/dataset_reforma_final.csv"

if(file.exists(archivo_datos)) {
  df <- read.csv(archivo_datos, stringsAsFactors = FALSE)
  print(paste("Datos cargados:", nrow(df), "noticias."))
} else {
  stop("ERROR: No se encuentra el archivo 'dataset_reforma_final.csv'. Verificá el directorio.")
}

# Relevance filter
keywords_relevantes <- paste(c(
  "reforma", "laboral", "trabajo", "empleo", "despidos", "indemnización",
  "cgt", "gremio", "sindicato", "paro", "huelga", "movilización", "marcha",
  "ley bases", "dnu", "senado", "diputados", "congreso", "legislatura",
  "milei", "sturzenegger", "cordero", "decreto", "reglamentación",
  "artículo", "capítulo laboral", "justicia", "fallo", "amparo", "ate"
), collapse = "|")

# Imprimimos cuántas teníamos antes
print(paste("Noticias totales bajadas:", nrow(df)))

# Aplicamos el filtro
df_filtrado <- df %>%
  mutate(titulo_lower = tolower(titulo)) %>% 
  filter(str_detect(titulo_lower, keywords_relevantes))

# Sobreescribimos el dataframe original con la versión limpia
df <- df_filtrado

# Imprimimos cuántas quedaron y cuántas borramos
print(paste("Noticias relevantes:", nrow(df)))

# Limmpieza de texto

clean_df <- df %>%
  mutate(titulo_limpio = str_remove(titulo, " - .*")) %>%       
  mutate(titulo_limpio = str_remove(titulo_limpio, " \\| .*")) %>% 
  mutate(titulo_limpio = tolower(titulo_limpio))                

# Tokenización: Rompemos las frases en palabras individuales
tokens <- clean_df %>%
  unnest_tokens(word, titulo_limpio)

# Stopwords: Definimos palabras vacías para filtrar
stopwords_es <- stopwords("spanish")

# AGREGAMOS STOPWORDS CUSTOM 
custom_stop <- c(stopwords_es, "reforma", "laboral", "ley", "gobierno", 
                 "proyecto", "argentina", "foto", "video", "tras", "dijo",
                 "infobae", "página", "12", "clarin", "clarín", "destape", "navarro")

tokens_clean <- tokens %>%
  filter(!word %in% custom_stop) %>%
  filter(str_length(word) > 2) 

# Analisis de frecuencia léxica

top_words <- tokens_clean %>%
  count(medio, word, sort = TRUE) %>%
  group_by(medio) %>%
  slice_max(n, n = 10) %>% 
  ungroup() %>%
  mutate(word = reorder_within(word, n, medio))

# Gráfico 1: Barras de Frecuencia
g1 <- ggplot(top_words, aes(word, n, fill = medio)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~medio, scales = "free_y") +
  coord_flip() +
  scale_x_reordered() +
  scale_fill_manual(values = c(
    "Infobae" = "#E67E22",   
    "Pagina 12" = "#3498DB", 
    "Clarin" = "#DA291C"     
  ))
  theme_minimal() +
  labs(title = "Divergencia Léxica en la Reforma Laboral",
       subtitle = "Palabras más frecuentes en titulares según el medio",
       x = NULL, y = "Frecuencia de aparición") +
  theme(plot.title = element_text(face = "bold", size = 14))

print(g1)
ggsave("grafico_frecuencias.png", g1, width = 10, height = 6) 

# Creamos el diccionario "Rioplatense" con pesos ponderados

diccionario_argento <- tribble(
  ~word, ~valor,
  # --- NEGATIVAS ---
  "ajuste", -2, "motosierra", -2, "licuadora", -2, "represión", -2,
  "brutal", -2, "golpe", -2, "caída", -1, "derrumbe", -2,
  "pobreza", -2, "recesión", -2, "paro", -1, "conflicto", -1,
  "tensión", -1, "alerta", -1, "peligro", -1, "pérdida", -1,
  "freno", -1, "contra", -1, "rechazo", -1, "casta", -1,
  "precarización", -2, "despidos", -2, "crisis", -2, "impuestazo", -2,
  "polémica", -1, "cuestiona", -1, "fuerte", -0.5, "batalla", -1,
  
  # --- POSITIVAS ---
  "avance", 1, "acuerdo", 1, "apoyo", 1, "superávit", 2,
  "equilibrio", 1, "baja", 1, "alivio", 2, "modernización", 2,
  "mejora", 2, "inversiones", 2, "derechos", 1, "crecimiento", 2,
  "solución", 1, "luz", 1, "verde", 1, "celebran", 2, "respaldo", 1
)

# Unimos tokens con el diccionario
sentimiento_analisis <- tokens_clean %>%
  inner_join(diccionario_argento, by = "word")

# Calculamos el promedio de sentimiento por medio
resumen_stats <- sentimiento_analisis %>%
  group_by(medio) %>%
  summarise(
    media_sentimiento = mean(valor),
    total_palabras_cargadas = n()
  )

print(resumen_stats)

# Gráfico 2: Distribución de la olaridad
g2 <- ggplot(sentimiento_analisis, aes(x = medio, y = valor, fill = medio)) +
  geom_violin(alpha = 0.5, trim = FALSE) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 2) + 
  stat_summary(fun = mean, geom = "point", shape = 23, size = 5, fill = "white", stroke = 1.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_fill_manual(values = c(
    "Infobae" = "#E67E22",    
    "Clarin" = "#DA291C",     
    "Pagina 12" = "#3498DB",  
    "El Destape" = "#000000"  
  )) +
  theme_minimal() +
  labs(title = "Polaridad emocional",
       subtitle = "Distribución de palabras con carga (Negativo < 0 < Positivo)",
       y = "Score de Sentimiento",
       x = NULL,
       caption = "Nota: El rombo blanco indica el promedio.") +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.position = "none")

print(g2)
ggsave("grafico_sentimiento.png", g2, width = 8, height = 6)
