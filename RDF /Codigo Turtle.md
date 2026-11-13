@prefix : <https://example.org/aire/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix sosa: <http://www.w3.org/ns/sosa/> .
@prefix schema: <https://schema.org/> .
@prefix geo: <http://www.opengis.net/ont/geosparql#> .
@prefix dbo: <http://dbpedia.org/ontology/> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix wd: <http://www.wikidata.org/entity/> .
# ============ Esquema RDFS (clases) ============
:Pais a rdfs:Class ; rdfs:label "País"@es ; rdfs:subClassOf schema:Country .
:Lugar a rdfs:Class ; rdfs:label "Lugar"@es ; rdfs:subClassOf schema:Place , geo:Feature .
:Ciudad a rdfs:Class ; rdfs:label "Ciudad"@es ; rdfs:comment "Entidad de ciudad de Wikidata."@es ; rdfs:subClassOf :Lugar , schema:City .
:Asentamiento a rdfs:Class ; rdfs:label "Asentamiento medido"@es ; rdfs:comment "Ciudad o asentamiento con mediciones de la OMS."@es ; rdfs:subClassOf :Lugar , sosa:FeatureOfInterest .
:Medicion a rdfs:Class ; rdfs:label "Medición"@es ; rdfs:subClassOf sosa:Observation .
:MedicionAnual a rdfs:Class ; rdfs:label "Medición anual"@es ; rdfs:subClassOf :Medicion .
:MedicionAQI a rdfs:Class ; rdfs:label "Medición AQI"@es ; rdfs:subClassOf :Medicion .
:Contaminante a rdfs:Class ; rdfs:label "Contaminante"@es ; rdfs:subClassOf sosa:ObservableProperty .
:FuenteDatos a rdfs:Class ; rdfs:label "Fuente de datos"@es ; rdfs:subClassOf schema:Dataset .
# ============ Propiedades de datos ============
:iso3 a rdf:Property ; rdfs:label "código ISO3"@es ; rdfs:domain :Pais ; rdfs:range xsd:string .
:regionOMS a rdf:Property ; rdfs:label "región OMS"@es ; rdfs:domain :Pais ; rdfs:range xsd:string .
:codigo a rdf:Property ; rdfs:label "código del contaminante"@es ; rdfs:domain :Contaminante ; rdfs:range xsd:string .
:unidad a rdf:Property ; rdfs:label "unidad"@es ; rdfs:domain :Contaminante ; rdfs:range xsd:string .
:anio a rdf:Property ; rdfs:label "año"@es ; rdfs:domain :MedicionAnual ; rdfs:range xsd:gYear .
:concentracionAnual a rdf:Property ; rdfs:label "concentración anual"@es ; rdfs:subPropertyOf sosa:hasSimpleResult ; rdfs:domain :MedicionAnual ; rdfs:range xsd:decimal .
:coberturaTemporal a rdf:Property ; rdfs:label "cobertura temporal (%)"@es ; rdfs:domain :MedicionAnual ; rdfs:range xsd:decimal .
:numeroEstaciones a rdf:Property ; rdfs:label "número de estaciones"@es ; rdfs:domain :MedicionAnual ; rdfs:range xsd:integer .
:metodoEnlace a rdf:Property ; rdfs:label "método de enlace"@es ; rdfs:domain :Asentamiento ; rdfs:range xsd:string .
:distanciaKm a rdf:Property ; rdfs:label "distancia del enlace (km)"@es ; rdfs:domain :Asentamiento ; rdfs:range xsd:decimal .
:nombreCiudadKaggle a rdf:Property ; rdfs:label "ciudad (Kaggle)"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:aqiTotal a rdf:Property ; rdfs:label "AQI total"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:integer .
:aqiPM25 a rdf:Property ; rdfs:label "AQI PM2.5"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:integer .
:aqiNO2 a rdf:Property ; rdfs:label "AQI NO2"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:integer .
:aqiO3 a rdf:Property ; rdfs:label "AQI ozono"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:integer .
:aqiCO a rdf:Property ; rdfs:label "AQI CO"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:integer .
:categoriaAQI a rdf:Property ; rdfs:label "categoría AQI"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:categoriaPM25 a rdf:Property ; rdfs:label "categoría AQI PM2.5"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:categoriaNO2 a rdf:Property ; rdfs:label "categoría AQI NO2"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:categoriaO3 a rdf:Property ; rdfs:label "categoría AQI ozono"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:categoriaCO a rdf:Property ; rdfs:label "categoría AQI CO"@es ; rdfs:domain :MedicionAQI ; rdfs:range xsd:string .
:urlLicencia a rdf:Property ; rdfs:label "URL de licencia o términos"@es ; rdfs:domain :FuenteDatos ; rdfs:range xsd:anyURI .
# ============ Propiedades de relación ============
:ubicadaEn a rdf:Property ; rdfs:label "ubicada en"@es ; rdfs:subPropertyOf schema:containedInPlace ; rdfs:domain :Lugar ; rdfs:range :Pais .
:enlazadoCon a rdf:Property ; rdfs:label "enlazado con"@es ; rdfs:subPropertyOf skos:closeMatch ; rdfs:domain :Asentamiento ; rdfs:range :Ciudad .
:deAsentamiento a rdf:Property ; rdfs:label "de asentamiento"@es ; rdfs:subPropertyOf sosa:hasFeatureOfInterest ; rdfs:domain :MedicionAnual ; rdfs:range :Asentamiento .
:contaminante a rdf:Property ; rdfs:label "contaminante medido"@es ; rdfs:subPropertyOf sosa:observedProperty ; rdfs:domain :MedicionAnual ; rdfs:range :Contaminante .
:enPais a rdf:Property ; rdfs:label "en país"@es ; rdfs:domain :MedicionAQI ; rdfs:range :Pais .
# ============ Reutilización directa (sin redefinir) ============
# schema:name -> nombre de Pais, Lugar, Contaminante y FuenteDatos
# dbo:populationTotal-> población de Lugar (Ciudad y Asentamiento)
# geo:hasGeometry / geo:asWKT -> geometría de Lugar (punto WKT)
# dct:source, dct:publisher -> procedencia de mediciones y lugares
# ============ Ejemplo con datos reales (Quito, Ecuador) ============
:OMS a :FuenteDatos ; schema:name "WHO Ambient Air Quality Database v8.0 (2026)" ; dct:publisher "Organización Mundial de la Salud" ;
:urlLicencia "https://www.who.int/publications/m/item/who-ambient-air-quality-database-(update-jun-2026)"^^xsd:anyURI .
:Wikidata a :FuenteDatos ; schema:name "Wikidata" ; dct:publisher "Fundación Wikimedia" ; :urlLicencia "https://www.wikidata.org/wiki/Wikidata:Licensing"^^xsd:anyURI .
:PM25 a :Contaminante ; schema:name "PM2.5" ; :codigo "PM2.5" ; :unidad "µg/m³" .
:PM10 a :Contaminante ; schema:name "PM10" ; :codigo "PM10" ; :unidad "µg/m³" .
:NO2 a :Contaminante ; schema:name "NO2" ; :codigo "NO2" ; :unidad "µg/m³" .
:ECU a :Pais ; schema:name "Ecuador" ; :iso3 "ECU" ; :regionOMS "AMR" .
wd:Q2900 a :Ciudad ; schema:name "Quito" ; :ubicadaEn :ECU ; dbo:populationTotal "1763275"^^xsd:integer ; geo:hasGeometry [ a geo:Geometry ; geo:asWKT "POINT(-78.512500 -0.220000)"^^geo:wktLiteral ] ; dct:source :Wikidata .
:Asentamiento_ECU_Quito a :Asentamiento ; schema:name "Quito" ; :ubicadaEn :ECU ; geo:hasGeometry [ a geo:Geometry ; geo:asWKT "POINT(-78.525 -0.2298)"^^geo:wktLiteral ] ;
:enlazadoCon wd:Q2900 ; :metodoEnlace "nombre" ; :distanciaKm "1.77"^^xsd:decimal ; dct:source :OMS .
:M_ECU_Quito_2010_PM25 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM25 ; :anio "2010"^^xsd:gYear ; :concentracionAnual "19.28"^^xsd:decimal ; :numeroEstaciones "14"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2010_NO2 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :NO2 ; :anio "2010"^^xsd:gYear ; :concentracionAnual "24.327"^^xsd:decimal ; :numeroEstaciones "14"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2010_PM10 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM10 ; :anio "2010"^^xsd:gYear ; :concentracionAnual "33.825"^^xsd:decimal ; :numeroEstaciones "14"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2011_PM25 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM25 ; :anio "2011"^^xsd:gYear ; :concentracionAnual "17.834"^^xsd:decimal ; :numeroEstaciones "13"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2011_NO2 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :NO2 ; :anio "2011"^^xsd:gYear ; :concentracionAnual "23.267"^^xsd:decimal ; :numeroEstaciones "13"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2011_PM10 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM10 ; :anio "2011"^^xsd:gYear ; :concentracionAnual "32.988"^^xsd:decimal ; :numeroEstaciones "13"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2012_PM25 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM25 ; :anio "2012"^^xsd:gYear ; :concentracionAnual "18.436"^^xsd:decimal ; :numeroEstaciones "12"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2012_NO2 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :NO2 ; :anio "2012"^^xsd:gYear ; :concentracionAnual "22.595"^^xsd:decimal ; :numeroEstaciones "12"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2012_PM10 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM10 ; :anio "2012"^^xsd:gYear ; :concentracionAnual "37.656"^^xsd:decimal ; :numeroEstaciones "12"^^xsd:integer ; dct:source :OMS .
:M_ECU_Quito_2013_PM25 a :MedicionAnual ; :deAsentamiento :Asentamiento_ECU_Quito ; :contaminante :PM25 ; :anio "2013"^^xsd:gYear ; :concentracionAnual "18.482"^^xsd:decimal ; :numeroEstaciones "13"^^xsd:integer ; dct:source :OMS .
