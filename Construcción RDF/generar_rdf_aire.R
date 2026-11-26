# Construye el grafo RDF de calidad del aire desde los CSV de DATOS.
# Ejecutar con Rscript desde cualquier directorio; las rutas se resuelven
# a partir de la ubicación de este archivo.

if (!requireNamespace("rdflib", quietly = TRUE)) {
  stop("Instala primero el paquete rdflib: install.packages('rdflib')")
}

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else ""
script_dir <- if (nzchar(script_path)) dirname(normalizePath(script_path)) else getwd()
project_dir <- normalizePath(file.path(script_dir, ".."), winslash = "/")
data_dir <- file.path(project_dir, "DATOS")
schema_file <- file.path(script_dir, "estructura.ttl")
out_file <- file.path(script_dir, "aire_poblado.ttl")

read_csv <- function(name) {
  path <- file.path(data_dir, name)
  if (!file.exists(path)) stop("No existe el CSV: ", path)
  read.csv(path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE,
           check.names = FALSE, na.strings = c("NA", "", "N/A"))
}

oms <- read_csv("who-ambient-air-quality-database-version-2026-v8.csv")
aqi <- read_csv("global air pollution dataset.csv")
wd_files <- c("wd_ciudad.csv", "wd_comunas.csv", "wd_grandesciudades.csv")
wd <- do.call(rbind, lapply(wd_files, read_csv))
query <- read_csv("query.csv")

BASE <- "https://example.org/aire/"
RDF <- "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
XSD <- "http://www.w3.org/2001/XMLSchema#"
SCHEMA <- "https://schema.org/"
DCT <- "http://purl.org/dc/terms/"
GEO <- "http://www.opengis.net/ont/geosparql#"
DBO <- "http://dbpedia.org/ontology/"

g <- rdflib::rdf()
add_uri <- function(s, p, o) {
  rdflib::rdf_add(g, subject = s, predicate = p, object = o,
                  subjectType = "uri", objectType = "uri")
}
add_lit <- function(s, p, value, datatype = paste0(XSD, "string")) {
  if (length(value) && !is.na(value) && nzchar(trimws(as.character(value)))) {
    rdflib::rdf_add(g, subject = s, predicate = p,
                    object = as.character(value), subjectType = "uri",
                    objectType = "literal", datatype_uri = datatype)
  }
}
add_num <- function(s, p, value, datatype) {
  n <- suppressWarnings(as.numeric(as.character(value)))
  if (length(n) && is.finite(n)) add_lit(s, p, format(n, scientific = FALSE, trim = TRUE), datatype)
}
U <- function(local) paste0(BASE, local)
clean <- function(x) {
  x <- iconv(as.character(x), from = "", to = "ASCII//TRANSLIT")
  x[is.na(x)] <- ""
  tolower(gsub("[^a-z0-9]+", "", x))
}
safe_id <- function(x) {
  x <- iconv(as.character(x), from = "", to = "ASCII//TRANSLIT")
  x[is.na(x)] <- ""
  gsub("[^A-Za-z0-9._-]+", "_", x)
}
nonempty <- function(x) !is.na(x) & nzchar(trimws(as.character(x)))

# estructura.ttl está guardado como documento Markdown con un bloque Turtle.
# Importa sus clases y propiedades, excluyendo el ejemplo de Quito.
schema_lines <- readLines(schema_file, warn = FALSE, encoding = "UTF-8")
start <- grep("^```turtle", schema_lines)[1]
finish <- grep("^```", schema_lines)
finish <- finish[finish > start][1]
if (is.na(start) || is.na(finish)) stop("No se encontró el bloque Turtle en estructura.ttl")
body <- schema_lines[(start + 1):(finish - 1)]
example_at <- grep("Ejemplo con datos reales", body)
if (length(example_at)) body <- body[seq_len(example_at[1] - 1)]
schema_tmp <- tempfile(fileext = ".ttl")
writeLines(body, schema_tmp, useBytes = TRUE)
rdflib::rdf_parse(schema_tmp, format = "turtle", rdf = g)
unlink(schema_tmp)

# Catálogo de fuentes
sources <- list(
  OMS = c("WHO Ambient Air Quality Database v8.0 (2026)",
          "Organización Mundial de la Salud",
          "https://www.who.int/publications/m/item/who-ambient-air-quality-database-(update-jun-2026)"),
  Wikidata = c("Wikidata", "Fundación Wikimedia", "https://www.wikidata.org/wiki/Wikidata:Licensing"),
  AQI = c("Global Air Pollution Dataset", "Kaggle", ""))
for (id in names(sources)) {
  s <- U(id); add_uri(s, paste0(RDF, "type"), U("FuenteDatos"))
  add_lit(s, paste0(SCHEMA, "name"), sources[[id]][1])
  add_lit(s, paste0(DCT, "publisher"), sources[[id]][2])
  if (nzchar(sources[[id]][3])) add_lit(s, U("urlLicencia"), sources[[id]][3], paste0(XSD, "anyURI"))
}

# Países derivados del catálogo OMS: ISO3 actúa como identificador estable.
country_rows <- unique(oms[nonempty(oms$iso3) & nonempty(oms$country_name), c("iso3", "country_name", "who_region")])
countries <- list()
for (i in seq_len(nrow(country_rows))) {
  code <- toupper(country_rows$iso3[i]); s <- U(paste0("Pais_", safe_id(code)))
  countries[[code]] <- s
  add_uri(s, paste0(RDF, "type"), U("Pais"))
  add_lit(s, paste0(SCHEMA, "name"), country_rows$country_name[i])
  add_lit(s, U("iso3"), code)
  add_lit(s, U("regionOMS"), country_rows$who_region[i])
}

# Combina los tres resultados Wikidata y conserva una instancia por Q-id.
# En caso de población repetida, usa el valor máximo disponible.
wd <- wd[nonempty(wd$city) & nonempty(wd$cityLabel), , drop = FALSE]
wd$city_id <- sub(".*/", "", wd$city)
wd$pop_num <- suppressWarnings(as.numeric(wd$pop))
wd <- wd[order(wd$city_id, -wd$pop_num, na.last = TRUE), , drop = FALSE]
wd <- wd[!duplicated(wd$city_id), , drop = FALSE]
wd_subject <- setNames(wd$city, wd$city_id)
for (i in seq_len(nrow(wd))) {
  s <- wd$city[i]
  add_uri(s, paste0(RDF, "type"), U("Ciudad"))
  add_lit(s, paste0(SCHEMA, "name"), wd$cityLabel[i])
  add_num(s, paste0(DBO, "populationTotal"), wd$pop_num[i], paste0(XSD, "integer"))
  if (nonempty(wd$coord[i])) {
    geom <- paste0(s, "_geometry")
    add_uri(s, paste0(GEO, "hasGeometry"), geom)
    add_uri(geom, paste0(RDF, "type"), paste0(GEO, "Geometry"))
    wkt <- sub("^[Pp]oint", "POINT", trimws(wd$coord[i]))
    add_lit(geom, paste0(GEO, "asWKT"), wkt, paste0(GEO, "wktLiteral"))
  }
  iso <- toupper(wd$iso3[i]); if (iso %in% names(countries)) add_uri(s, U("ubicadaEn"), countries[[iso]])
  add_uri(s, paste0(DCT, "source"), U("Wikidata"))
}

# query.csv aporta ciudades del mismo endpoint Wikidata con país por etiqueta.
# Se incorporan las que no aparecieron en los otros tres listados.
if (all(c("city", "cityLabel", "countryLabel", "pop", "coord") %in% names(query))) {
  for (i in seq_len(nrow(query))) {
    if (!nonempty(query$city[i]) || !nonempty(query$cityLabel[i])) next
    s <- query$city[i]
    add_uri(s, paste0(RDF, "type"), U("Ciudad"))
    add_lit(s, paste0(SCHEMA, "name"), query$cityLabel[i])
    add_num(s, paste0(DBO, "populationTotal"), query$pop[i], paste0(XSD, "integer"))
    if (nonempty(query$coord[i])) {
      geom <- paste0(s, "_geometry")
      add_uri(s, paste0(GEO, "hasGeometry"), geom)
      add_uri(geom, paste0(RDF, "type"), paste0(GEO, "Geometry"))
      wkt <- sub("^[Pp]oint", "POINT", trimws(query$coord[i]))
      add_lit(geom, paste0(GEO, "asWKT"), wkt, paste0(GEO, "wktLiteral"))
    }
    add_uri(s, paste0(DCT, "source"), U("Wikidata"))
  }
}

# Índices para enlazar por código ISO3 y nombre normalizado, solo si el enlace
# resulta único. Se evita asignar equivalencias ambiguas entre ciudades homónimas.
wd_key <- paste(toupper(wd$iso3), clean(wd$cityLabel), sep = "|")
settlement_uri <- function(iso, city) U(paste0("Asentamiento_", safe_id(iso), "_", safe_id(city)))
created_settlements <- new.env(parent = emptyenv())
ensure_settlement <- function(iso, city, lat = NA, lon = NA) {
  key <- paste(toupper(iso), clean(city), sep = "|")
  s <- settlement_uri(iso, clean(city))
  if (!exists(key, envir = created_settlements, inherits = FALSE)) {
    assign(key, s, envir = created_settlements)
    add_uri(s, paste0(RDF, "type"), U("Asentamiento"))
    add_lit(s, paste0(SCHEMA, "name"), city)
    if (toupper(iso) %in% names(countries)) add_uri(s, U("ubicadaEn"), countries[[toupper(iso)]])
    if (is.finite(suppressWarnings(as.numeric(lon))) && is.finite(suppressWarnings(as.numeric(lat)))) {
      geom <- paste0(s, "_geometry")
      add_uri(s, paste0(GEO, "hasGeometry"), geom)
      add_uri(geom, paste0(RDF, "type"), paste0(GEO, "Geometry"))
      add_lit(geom, paste0(GEO, "asWKT"), sprintf("POINT(%s %s)", lon, lat), paste0(GEO, "wktLiteral"))
    }
    add_uri(s, paste0(DCT, "source"), U("OMS"))
    hits <- which(wd_key == key)
    if (length(hits) == 1) {
      add_uri(s, U("enlazadoCon"), wd$city[hits])
      add_lit(s, U("metodoEnlace"), "ISO3 y nombre normalizado")
    }
  }
  s
}

# Mediciones anuales OMS: cada valor disponible genera una observación separada.
pollutants <- c(pm25_concentration = "PM25", pm10_concentration = "PM10", no2_concentration = "NO2")
pollutant_names <- c(PM25 = "PM2.5", PM10 = "PM10", NO2 = "NO2")
for (code in names(pollutant_names)) {
  s <- U(code); add_uri(s, paste0(RDF, "type"), U("Contaminante"))
  add_lit(s, paste0(SCHEMA, "name"), pollutant_names[[code]])
  add_lit(s, U("codigo"), pollutant_names[[code]])
  add_lit(s, U("unidad"), "µg/m³")
}
for (i in seq_len(nrow(oms))) {
  iso <- toupper(oms$iso3[i]); city <- sub("/[^/]+$", "", oms$city[i])
  if (!nonempty(iso) || !nonempty(city) || !nonempty(oms$year[i])) next
  assent <- ensure_settlement(iso, city, oms$latitude[i], oms$longitude[i])
  for (col in names(pollutants)) {
    value <- oms[[col]][i]
    if (!nonempty(value)) next
    pol <- pollutants[[col]]
    id <- paste("M", safe_id(iso), safe_id(city), safe_id(oms$year[i]), pol, sep = "_")
    m <- U(id)
    add_uri(m, paste0(RDF, "type"), U("MedicionAnual"))
    add_uri(m, U("deAsentamiento"), assent)
    add_uri(m, U("contaminante"), U(pol))
    add_lit(m, U("anio"), oms$year[i], paste0(XSD, "gYear"))
    add_num(m, U("concentracionAnual"), value, paste0(XSD, "decimal"))
    cov_col <- sub("_concentration$", "_tempcov", col)
    if (cov_col %in% names(oms)) add_num(m, U("coberturaTemporal"), oms[[cov_col]][i], paste0(XSD, "decimal"))
    add_num(m, U("numeroEstaciones"), oms$number_stations[i], paste0(XSD, "integer"))
    add_uri(m, paste0(DCT, "source"), U("OMS"))
  }
}

# Mapa país para el CSV AQI, cuyo país está expresado como texto.
country_key <- clean(country_rows$country_name)
country_code_by_name <- setNames(toupper(country_rows$iso3), country_key)
for (i in seq_len(nrow(aqi))) {
  country_name <- aqi$Country[i]; city <- aqi$City[i]
  if (!nonempty(country_name) || !nonempty(city)) next
  iso <- unname(country_code_by_name[clean(country_name)])
  if (!length(iso) || is.na(iso)) next
  m <- U(paste0("AQI_", safe_id(iso), "_", safe_id(city), "_", i))
  add_uri(m, paste0(RDF, "type"), U("MedicionAQI"))
  add_lit(m, U("nombreCiudadKaggle"), city)
  add_uri(m, U("enPais"), countries[[iso]])
  aqi_map <- c("AQI Value" = "aqiTotal", "PM2.5 AQI Value" = "aqiPM25", "NO2 AQI Value" = "aqiNO2", "Ozone AQI Value" = "aqiO3", "CO AQI Value" = "aqiCO")
  category_map <- c("AQI Category" = "categoriaAQI", "PM2.5 AQI Category" = "categoriaPM25", "NO2 AQI Category" = "categoriaNO2", "Ozone AQI Category" = "categoriaO3", "CO AQI Category" = "categoriaCO")
  for (col in names(aqi_map)) add_num(m, U(aqi_map[[col]]), aqi[[col]][i], paste0(XSD, "integer"))
  for (col in names(category_map)) add_lit(m, U(category_map[[col]]), aqi[[col]][i])
  add_uri(m, paste0(DCT, "source"), U("AQI"))
}

# Enlaces adicionales de query.csv, que ofrece ciudad Wikidata y país por nombre.
# Se usa una coincidencia única de nombre Wikidata y código ISO3 cuando es posible.
country_by_label <- setNames(toupper(country_rows$iso3), country_key)
if (all(c("city", "cityLabel", "countryLabel") %in% names(query))) {
  for (i in seq_len(nrow(query))) {
    candidates <- which(clean(wd$cityLabel) == clean(query$cityLabel[i]))
    if (length(candidates) == 1 && nonempty(wd$iso3[candidates])) {
      iso <- toupper(wd$iso3[candidates])
      if (iso %in% names(countries)) add_uri(query$city[i], U("ubicadaEn"), countries[[iso]])
    } else {
      iso <- unname(country_by_label[clean(query$countryLabel[i])])
      if (length(iso) && !is.na(iso) && iso %in% names(countries)) {
        add_uri(query$city[i], U("ubicadaEn"), countries[[iso]])
      }
    }
  }
}

rdflib::rdf_serialize(g, out_file, format = "turtle",
                      namespace = c(ex = BASE, rdf = RDF, rdfs = "http://www.w3.org/2000/01/rdf-schema#",
                                    xsd = XSD, schema = SCHEMA, sosa = "http://www.w3.org/ns/sosa/",
                                    geo = GEO, dbo = DBO, dct = DCT, skos = "http://www.w3.org/2004/02/skos/core#",
                                    wd = "http://www.wikidata.org/entity/"))
cat("Grafo escrito en:", normalizePath(out_file, winslash = "/"), "\n")
cat("Tripletas:", length(g), "\n")
cat("Ciudades Wikidata:", nrow(wd), " | países OMS:", nrow(country_rows),
    " | filas OMS:", nrow(oms), " | filas AQI:", nrow(aqi), "\n")
