#Grupo 12
#title: "La desigualdad en la participacion politica de las mujeres en las elecciones municipales distritales del 2018"
#author: "Valeria Lévano Torres, Juan Carlos Pérez Gonzáles, Cristian Serrano, Stephy Riega, André Lama"

#Activamos las librerías 
library(readxl)
library(ggplot2)
library(ggpol)
library(rio)
library(dplyr)
library(tidyverse)
library(magrittr)
library(mapsPERU)
library(sf)
library(ggmosaic)
library(gganimate)

#Importación de datos----
#primero fijamos el directorio donde se ubican los archivos
setwd(paste0(getwd(), "/BD/MUNICIPAL DISTRITAL 2018"))
#Importamos en dataframe cada uno de los archivos
candidatos <- read_xlsx("ERM2018_Candidatos_Distrital.xlsx")
padron <- read_xlsx("ERM2018_Padron_Distrital.xlsx")
resultados <- read_xlsx("ERM2018_Resultados_Distrital.xlsx")
autoridades <- read_xlsx("ERM2018_Autoridades_Distrital.xlsx")


autoridades18 <- read_xlsx("ERM2018_Autoridades_Distrital.xlsx")
autoridades14 <- read_xlsx("ERM2014_Autoridades_Distrital.xlsx")
autoridades10 <- read_xlsx("ERM2010_Autoridades_Distrital.xlsx")
autoridades06 <- read_xlsx("ERM2006_Autoridades_Distrital.xlsx")
autoridades02 <- read_xlsx("ERM2002_Autoridades_Distrital.xlsx")

autoridades18$año <- 2018
autoridades14$año <- 2014
autoridades10$año <- 2010
autoridades06$año <- 2006
autoridades02$año <- 2002

autoridades18 <- autoridades18 %>% select("Región", "Cargo electo", "año", "Sexo")
autoridades14 <- autoridades14 %>% select("Región", "Cargo electo", "año", "Sexo")
autoridades10 <- autoridades10 %>% select("Región", "Cargo electo", "año", "Sexo")
autoridades06 <- autoridades06 %>% select("Región", "Cargo electo", "año", "Sexo")
autoridades02 <- autoridades02 %>% select("Región", "Cargo electo", "año", "Sexo")

autoridades_final <- bind_rows(autoridades18, autoridades14, autoridades10, autoridades06, autoridades02)


candidatos %>%
  group_by(Sexo, Cargo, Distrito) %>%
  summarize(count = n()) %>%  
  # Crea el gráfico mediante ggplot 
  ggplot(aes(x = Distrito, y = count, fill = Sexo)) +
  # Agrega barra con tamaño proporcional a la cantidad de candidatos
  geom_bar(stat = "identity", position = "fill") + 
  facet_wrap(~ Cargo ) + #divide el gráfico por cargo
  #Para colocar la leyenda en la parte inferior del gráfico y para no colocar los nombres de Distro en eje x
  theme(legend.position = "bottom", axis.text.x = element_blank(), axis.ticks.x = element_blank()) + 
  # Coloca etiquetas y título. En este gráfico no se considera los nombres del eje x debido a su extensión 
  ylab("Indicador de preferencia") +
  ggtitle("Distribución de Candidatos por distrito")



### Grafico de indicador de preferencia por sexo y distrito ----
unique(candidatos$Region)
candidatos %>%
  group_by(Region, Sexo, Cargo, Distrito) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = Region, y = count, fill = Sexo)) +
  # Agrega barra con tamaño proporcional a la cantidad de candidatos
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~ Cargo ) + #divide el gráfico por cargo
  # Para colocar la leyenda en la parte inferior del gráfico
  theme(legend.position = "bottom") + 
  # Coloca etiquetas y título 
  xlab("Region") +
  ylab("Indicador de preferencia") +
  ggtitle("Distribución de Candidatos por departamento")+
  # Ayuda a convertir los nombres horizontales en verticales, para que no aparezcan superpuestos
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) 


#Distribución de candidatos por Macrorregión (Norte, Centro y Sur)
#Llenamos los valores vacíos de las variables Joven y Nativo
#Luego, agrupamos los departamentos en macrorregiones

candidatos_2 <- candidatos |>
  mutate(Joven = ifelse(is.na(Joven), "No Joven", Joven)) |> 
  mutate(Nativo = ifelse(is.na(Nativo), "No Nativo", Nativo)) |> 
  mutate(macrorregion = if_else(Region %in% c("AMAZONAS" , "CAJAMARCA","LA LIBERTAD", "LAMBAYEQUE", "LORETO", "PIURA", "SAN MARTIN", "TUMBES"), "Norte",
                                if_else(Region %in% c("LIMA","ANCASH", "CALLAO", "HUANCAVELICA", "HUANUCO", "JUNIN","MADRE DE DIOS", "PASCO", "UCAYALI"), "Centro",
                                        if_else(Region %in% c("AREQUIPA","APURIMAC", "AYACUCHO", "CUSCO","ICA","MOQUEGUA", "PUNO", "TACNA"), "Sur", "NA"))))

candidatos_2 |> 
  group_by(macrorregion, Sexo) |> 
  ggplot()+
  geom_mosaic(aes(x = product(macrorregion), fill=Sexo)) +
  ggtitle("Distribución de candidatos por macrorregión y sexo")


#Prioridad del candidato a regidor en la lista postulante
#Primeros agrupamos los candidatos de acuerdo a su posición en la lista
#calculamos la cantidad por cada posición y sexo

indice <-candidatos |> 
  mutate(grupo = cut(`N°`, breaks = seq(from = min(`N°`), to = max(`N°`), by = 1))) |> 
  group_by(grupo, Sexo) |> 
  summarise(nro_candidatos=n()) 

#realizamos un grafico de barras 
indice <-as.data.frame(indice)
indice|> 
  filter(!is.na(grupo)) |> 
  ggplot()+
  aes(x=grupo, fill=Sexo) +
  aes(y=nro_candidatos)+
  geom_bar(stat = "identity", position = "stack")+
  scale_x_discrete(labels = c("1", "2", "3","4", "5","6","7","8","9","10","11","12","13","14","15"))+
  labs(title = "Proporción por Sexo según la posición del regidor en la lista") +
  xlab("Posición en la lista candidata") +
  ylab("Número de Candidatos")

#Mapa de calor
#construnimos un mapa
#primero, agrupamos los candidatos por departamento, cargo, sexo
#calculamos el porcenatje de participacion por sexo
#luego, cambiamos los valores de la variable region para poder realizar el join
#https://github.com/musajajorge/mapsPERU

candidatos_map <- candidatos_2 |>
  group_by(Region,Cargo, Sexo,) |>  
  summarize(count = n()) |> 
  mutate(percent = count / sum(count) * 100) |>
  mutate(Region=recode(Region,
                       "AMAZONAS"="Amazonas",
                       "ANCASH"="Áncash",
                       "APURIMAC"="Apurímac",
                       "AREQUIPA"="Arequipa",
                       "AYACUCHO"="Ayacucho",
                       "CAJAMARCA"="Cajamarca",
                       "CALLAO"="Callao",
                       "CUSCO"="Cusco",
                       "HUANCAVELICA"="Huancavelica",
                       "HUANUCO"="Huánuco",
                       "ICA"="Ica",
                       "JUNIN"="Junín",
                       "LA LIBERTAD"="La Libertad",
                       "LAMBAYEQUE"="Lambayeque",
                       "LIMA"="Lima",
                       "LORETO"="Loreto",
                       "MADRE DE DIOS"="Madre de Dios",
                       "MOQUEGUA"="Moquegua",
                       "PASCO"="Pasco",
                       "PIURA"="Piura",
                       "PUNO"="Puno",
                       "SAN MARTIN"="San Martín",
                       "TACNA"="Tacna",
                       "TUMBES"="Tumbes",
                       "UCAYALI"="Ucayali"))

#importamos el shape file del mapa de la libreria mapsPERU  
df_mapa <- map_DEP

# realizamos la union de los dos df
df_mapa<-left_join(df_mapa, candidatos_map, by=c("DEPARTAMENTO"="Region"))



#graficamos el mapa incluyendo el porcentaje de participacion femenina 
#para ello filtramos el sexo femenino y cargo igual a alcalde distrital,
#puesto que se desea saber el comportamiento de los candidatos a alcalde
df_mapa |>
  filter(Sexo=="Femenino", Cargo=="ALCALDE DISTRITAL") |>
  ggplot() +
  aes(geometry=geometry)+
  geom_sf(aes(fill=percent)) +
  scale_fill_gradient (low="white", high="red3", name = "Porcentaje")+
  labs(title = "Participación femenina a nivel de alcaldes distritales",
       subtitle="(Candidatos)") +
  theme(axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())

# de igual forma, se realiza el mapa para los candidatos a regidro
df_mapa |>
  filter(Sexo=="Femenino", Cargo=="REGIDOR DISTRITAL") |>
  ggplot() +
  aes(geometry=geometry)+
  geom_sf(aes(fill=percent)) +
  scale_fill_gradient (low="white", high="red3", name = "Porcentaje")+
  labs(title = "Participación femenina a nivel de regidores distritales",
       subtitle="(Candidatos)") +
  theme(axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())


#similar al df de candidatos, se llena los valores vacios
# se agrupa los departamentos pr macrorregion

autoridades_2 <- autoridades |>
  mutate(Joven = ifelse(is.na(Joven), "No Joven", Joven)) |> 
  mutate(Nativo = ifelse(is.na(Nativo), "No Nativo", Nativo)) |> 
  mutate(macrorregion = if_else(Región %in% c("AMAZONAS" , "CAJAMARCA","LA LIBERTAD", "LAMBAYEQUE", "LORETO", "PIURA", "SAN MARTIN", "TUMBES"), "Norte",
                                if_else(Región %in% c("LIMA","ANCASH", "CALLAO", "HUANCAVELICA", "HUANUCO", "JUNIN","MADRE DE DIOS", "PASCO", "UCAYALI"), "Centro",
                                        if_else(Región %in% c("AREQUIPA","APURIMAC", "AYACUCHO", "CUSCO","ICA","MOQUEGUA", "PUNO", "TACNA"), "Sur", "NA"))))

# se calcula el porcentaje de participacion por sexo
#y recodifica los valores de la variable region
autoridades_map <- autoridades_2 |>
  group_by(Región, `Cargo electo`, Sexo) |>  
  summarize(count = n()) |> 
  mutate(percent = count / sum(count) * 100) |>
  mutate(Región=recode(Región,
                       "AMAZONAS"="Amazonas",
                       "ANCASH"="Áncash",
                       "APURIMAC"="Apurímac",
                       "AREQUIPA"="Arequipa",
                       "AYACUCHO"="Ayacucho",
                       "CAJAMARCA"="Cajamarca",
                       "CALLAO"="Callao",
                       "CUSCO"="Cusco",
                       "HUANCAVELICA"="Huancavelica",
                       "HUANUCO"="Huánuco",
                       "ICA"="Ica",
                       "JUNIN"="Junín",
                       "LA LIBERTAD"="La Libertad",
                       "LAMBAYEQUE"="Lambayeque",
                       "LIMA"="Lima",
                       "LORETO"="Loreto",
                       "MADRE DE DIOS"="Madre de Dios",
                       "MOQUEGUA"="Moquegua",
                       "PASCO"="Pasco",
                       "PIURA"="Piura",
                       "PUNO"="Puno",
                       "SAN MARTIN"="San Martín",
                       "TACNA"="Tacna",
                       "TUMBES"="Tumbes",
                       "UCAYALI"="Ucayali"))


#Primero comprobamos que clase es la variable joven para poder completar la categoria faltante, como para la variable nativo. 
class(autoridades$Joven)

autoridades <- autoridades |> 
  dplyr::mutate(Joven = ifelse(is.na(Joven), "No Joven", Joven)) |> 
  dplyr::mutate(Nativo = ifelse(is.na(Nativo), "No Nativo", Nativo))

autoridades <- as.data.frame(autoridades)


### Gráfico de parlamento de las ganadores a regidores municipales distritales por juventud y sexo ----

#Creamos un cuadro resumen para ver la cantidad de REGIDORES DISTRITALES electos, filtrando solo este grupo usando filter().
#Luego, agrupamos estas observaciones por si son jovenes o no y su sexo con la funcion group_by()
#Por ultimo, resumimos estos datos contando cuantas observaciones existen, lo reducimos a centenas y redondeamos.

aut_sum <- autoridades |> 
  filter(autoridades$`Cargo electo`== "REGIDOR DISTRITAL") |> 
  dplyr::group_by(Joven, Sexo) |> 
  dplyr::summarise(regidores=round(n()/100))

#para elaborar el cuadro, debemos agregar la columna de colors con el color correspondiente que queramos usando mutate.
#Sin embargo, este esta determinado por la combinacion entre Joven y Sexo que se haga, por ello usamos case_when.
aut_sum <-aut_sum |> 
  
  mutate(colors = case_when(Joven == 'Joven' & Sexo == 'Femenino' ~ 'lightpink',
                            Joven == 'Joven' & Sexo == 'Masculino' ~ 'lightblue',
                            Joven == 'No Joven' & Sexo == 'Femenino' ~ 'red',
                            Joven == 'No Joven' & Sexo == 'Masculino' ~ 'blue'
                            
  )) |> 
  mutate(Sexo_Joven = case_when(Joven == 'Joven' & Sexo == 'Femenino' ~ 'Joven Femenina',
                                Joven == 'Joven' & Sexo == 'Masculino' ~ 'Joven Masculino',
                                Joven == 'No Joven' & Sexo == 'Femenino' ~ 'No joven femenina',
                                Joven == 'No Joven' & Sexo == 'Masculino' ~ 'No joven masculino'))


#Por ultimo, usamos una extension de ggplot, geom_parluament, para representar a los regidores distritales por juventud y sexo.
aut_sum |> 
  ggplot() + 
  geom_parliament(aes(seats = regidores, fill = Joven), color = "black") + 
  scale_fill_manual(values = aut_sum$colors, labels = aut_sum$Joven) +
  coord_fixed() + 
  theme_void()+
  labs(title = "Regidores distritales por juventud y sexo",
       subtitle="(En centenas)")+
  scale_fill_manual(name = "",
                    values = aut_sum$colors, 
                    labels = c("Joven Mujer", "Joven Hombre", "No Joven Mujer", "No Joven Hombre"))



### Gráfico de parlamento de las ganadores a alcaldia municipal distrital jovenes y no jovenes por sexo ----


aut_sum2 <- autoridades |> 
  filter(autoridades$`Cargo electo`== "ALCALDE DISTRITAL") |> 
  dplyr::group_by(Joven, Sexo) |> 
  dplyr::summarise(alcaldes=round(n()))

aut_sum2 <-aut_sum2 |> 
  mutate(colors = case_when(Joven == 'Joven' & Sexo == 'Femenino' ~ 'lightpink',
                            Joven == 'Joven' & Sexo == 'Masculino' ~ 'lightblue',
                            Joven == 'No Joven' & Sexo == 'Femenino' ~ 'red',
                            Joven == 'No Joven' & Sexo == 'Masculino' ~ 'blue'
  )) |> 
  mutate(Sexo_Joven = case_when(Joven == 'Joven' & Sexo == 'Femenino' ~ 'Joven Femenina',
                                Joven == 'Joven' & Sexo == 'Masculino' ~ 'Joven Masculino',
                                Joven == 'No Joven' & Sexo == 'Femenino' ~ 'No joven femenina',
                                Joven == 'No Joven' & Sexo == 'Masculino' ~ 'No joven masculino'))

aut_sum2 |> 
  ggplot() + 
  geom_parliament(aes(seats = alcaldes, fill = Joven), color = "black") + 
  scale_fill_manual(name = "", 
                    values = aut_sum2$colors,
                    labels = c("Joven Mujer", "Joven Hombre", "No Joven Mujer", "No Joven Hombre")) +
  coord_fixed() + 
  theme_void()+
  labs(title = "Alcaldes distritales jovenes y no jovenes por sexo",
       subtitle="(En proporción)")




#Distribución de autoridades elegidas por macrorregion
autoridades_2 <- autoridades |>
  mutate(Joven = ifelse(is.na(Joven), "No Joven", Joven)) |> 
  mutate(Nativo = ifelse(is.na(Nativo), "No Nativo", Nativo)) |> 
  mutate(Macrorregion = if_else(Región %in% c("AMAZONAS" , "CAJAMARCA","LA LIBERTAD", "LAMBAYEQUE", "LORETO", "PIURA", "SAN MARTIN", "TUMBES"), "Norte",
                                if_else(Región %in% c("LIMA","ANCASH", "CALLAO", "HUANCAVELICA", "HUANUCO", "JUNIN","MADRE DE DIOS", "PASCO", "UCAYALI"), "Centro",
                                        if_else(Región %in% c("AREQUIPA","APURIMAC", "AYACUCHO", "CUSCO","ICA","MOQUEGUA", "PUNO", "TACNA"), "Sur", "NA"))))

autoridades_2 |> 
  group_by(Macrorregion, Sexo) |> 
  ggplot()+
  geom_mosaic(aes(x = product(Macrorregion), fill=Sexo)) +
  ggtitle("Distribución de autoridades electas por macrorregión y sexo")



#Gráfico a nivel nacional de la proporción de alcades distritales por sexo:

autoridades %>%
  filter(`Cargo electo` == "ALCALDE DISTRITAL") %>%
  group_by(Sexo) %>%
  summarize(count = n()) %>%
  mutate(percent = count/sum(count)) %>%
  ggplot(aes(x = "", y = percent, fill = Sexo)) +
  geom_bar(width = 1, stat = "identity", position = "fill") +
  geom_text(aes(label = scales::percent(percent)), position = position_stack(vjust = 0.5))+
  scale_y_continuous(labels = scales::percent) +
  ggtitle("Proporción Nacional de Alcaldes Distritales por Género") +
  xlab("Alcaldes distritales a nivel Nacional") +
  ylab("Proporción por Sexo") +
  theme(legend.position = "bottom", axis.text.x = element_blank(), axis.ticks.x = element_blank())

#ggsave("grafico1.png", plot = last_plot(), width = 6, height = 4, units = "in")


### Grafico de regidores distritales por sexo y distrito ----

autoridades %>%
  filter(`Cargo electo` == "REGIDOR DISTRITAL") %>%
  group_by(Sexo, Distrito) %>%
  summarize(count = n()) %>%  
  ggplot(aes(x = Distrito, y = count, fill = Sexo)) +
  geom_bar(stat = "identity", position = "fill") + 
  theme(legend.position = "bottom", axis.text.x = element_blank(), axis.ticks.x = element_blank()) + 
  ylab("Proporción por Sexo") +
  ggtitle("Distribución de Regidores Distritales por distrito") 

#ggsave("grafico2.png", plot = last_plot(), width = 6, height = 4, units = "in")


### Grafico de autoridades distritales por sexo y departamento ----
unique(autoridades$Región)
autoridades %>%
  group_by(Región, Sexo, `Cargo electo`, Distrito) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = Región, y = count, fill = Sexo)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~ `Cargo electo` ) + 
  theme(legend.position = "bottom") + 
  xlab("Region") +
  ylab("Proporción por Sexo") +
  ggtitle("Distribución de Autoridades por departamento")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) 

#ggsave("grafico3.png", plot = last_plot(), width = 6, height = 4, units = "in")


#Distribución de autoridades por Macrorregión (Norte, Centro y Sur)
autoridades <- as.data.frame(autoridades)

autoridades_2 <- autoridades |>
  mutate(Joven = ifelse(is.na(Joven), "No Joven", Joven)) |> 
  mutate(Nativo = ifelse(is.na(Nativo), "No Nativo", Nativo)) |> 
  mutate(macrorregion = if_else(Región %in% c("AMAZONAS" , "CAJAMARCA","LA LIBERTAD", "LAMBAYEQUE", "LORETO", "PIURA", "SAN MARTIN", "TUMBES"), "Norte",
                                if_else(Región %in% c("LIMA","ANCASH", "CALLAO", "HUANCAVELICA", "HUANUCO", "JUNIN","MADRE DE DIOS", "PASCO", "UCAYALI"), "Centro",
                                        if_else(Región %in% c("AREQUIPA","APURIMAC", "AYACUCHO", "CUSCO","ICA","MOQUEGUA", "PUNO", "TACNA"), "Sur", "NA"))))


autoridades_2 %>% 
  group_by(macrorregion, Sexo) %>% 
  summarize(count = n()) %>% 
  mutate(percent = count / sum(count) * 100) %>% 
  ggplot(aes(x = macrorregion, y = percent, fill = Sexo)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = paste0(round(percent, 1), "%")), position = position_stack(vjust = 0.5)) +
  ggtitle("Distribución de Autoridades por macrorregión y sexo") +
  xlab("Macrorregión") +
  ylab("Proporción por Sexo")

#ggsave("grafico4.png", plot = last_plot(), width = 6, height = 4, units = "in")


# se importa el df de para graficar el mapa por autoridades electas
df_mapa_autoridades <- map_DEP

df_mapa_autoridades<-left_join(df_mapa_autoridades, autoridades_map, by=c("DEPARTAMENTO"="Región"))

# se grafica la participacion femenina de las alcadesas electas
df_mapa_autoridades |>
  filter(Sexo=="Femenino", `Cargo electo`  == "ALCALDE DISTRITAL") |>
  ggplot() +
  aes(geometry=geometry)+
  geom_sf(aes(fill=percent)) +
  scale_fill_gradient (low="white", high="red3", name = "Porcentaje")+
  labs(title = "Participación femenina a nivel de alcaldes distritales",
       subtitle="(Autoridades electas)") +
  theme(axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())

# se grafica la participacion femenina de las regidoras electas
df_mapa_autoridades |>
  filter(Sexo=="Femenino", `Cargo electo` =="REGIDOR DISTRITAL") |>
  ggplot() +
  aes(geometry=geometry)+
  geom_sf(aes(fill=percent)) +
  scale_fill_gradient (low="white", high="red3", name = "Porcentaje")+
  labs(title = "Participación femenina a nivel de regidores distritales",
       subtitle="(Autoridades electas)") +
  theme(axis.line = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())

#####
colnames(autoridades_final)[2] <- "Cargo"


autoridades_final_sum <- autoridades_final |> 
  group_by(Región, Cargo, año, Sexo) |> 
  summarize(count = n()) |> 
  mutate(Porcentaje = round(count / sum(count) * 100, digit=2))


#Alcalde distrital:

al_dist_sum<- autoridades_final_sum|>
  filter(Sexo == "Femenino", Cargo == "ALCALDE DISTRITAL") |>
  group_by(año) |> 
  arrange(año, desc(Porcentaje)) |> 
  mutate(ranking=row_number())%>%
  filter(ranking <= 10)

animacion_al <- al_dist_sum |> 
  ggplot() +
  geom_col(aes(ranking, Porcentaje, fill = Región )) +
  geom_text(aes(ranking, Porcentaje, label = sprintf("%.2f", Porcentaje)), hjust=-0.1) +
  geom_text(aes(ranking, y=0 , label = Región), hjust=1.1) + 
  geom_text(aes(x=6, y=max(Porcentaje) , label = as.factor(año)), vjust = 0.2, alpha = 0.5,  col = "gray", size = 20) +
  coord_flip(clip = "off", expand = FALSE) + scale_x_reverse() +
  theme_minimal() + theme(
    panel.grid = element_blank(), 
    legend.position = "none",
    axis.ticks.y = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    plot.margin = margin(2, 8, 4, 12, "cm")
  ) +
  transition_states(año, state_length = 0, transition_length = 2) +
  labs(title = "Porcentaje de participación femenina en las alcaldías distritales") +
  enter_fade() +
  exit_fade() + 
  ease_aes('quadratic-in-out') 

animate(animacion_al, width = 1000, height = 800, fps = 25, duration = 30, rewind = FALSE)


#Regidor distrital:

reg_dist_sum<- autoridades_final_sum|>
  filter(Sexo == "Femenino", Cargo == "REGIDOR DISTRITAL") |>
  group_by(año) |> 
  arrange(año, desc(Porcentaje)) |> 
  mutate(ranking=row_number())%>%
  filter(ranking <= 10)

animacion_reg <- reg_dist_sum |> 
  ggplot() +
  geom_col(aes(ranking, Porcentaje, fill = Región )) +
  geom_text(aes(ranking, Porcentaje, label = sprintf("%.2f", Porcentaje)), hjust=-0.1) +
  geom_text(aes(ranking, y=0 , label = Región), hjust=1.1) + 
  geom_text(aes(x=6, y=max(Porcentaje) , label = as.factor(año)), vjust = 0.2, alpha = 0.5,  col = "gray", size = 20) +
  coord_flip(clip = "off", expand = FALSE) + scale_x_reverse() +
  theme_minimal() + theme(
    panel.grid = element_blank(), 
    legend.position = "none",
    axis.ticks.y = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    plot.margin = margin(2, 8, 4, 12, "cm")
  ) +
  transition_states(año, state_length = 0, transition_length = 2) +
  labs(title = "Porcentaje de participación femenina en cargos de regidoras distritales") +
  enter_fade() +
  exit_fade() + 
  ease_aes('quadratic-in-out') 

animate(animacion_reg, width = 1000, height = 800, fps = 25, duration = 30, rewind = FALSE)


























































