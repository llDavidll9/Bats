library(readxl)
datos<-read_xlsx("RepBat_recurso (1).xlsx")
#View(datos)
library(dplyr)
library(gamlss)
frugivoros <- c("A. and", "A. lit", "A. pha", "A. pla", "M. mac", "S. gia", "U. con", "P. hel","A. plan")
frugivoros_insectivoros <- c("L. bra", "L. sil", "M. mic","L. bras", "M. meg")
insectivoros <- c("E. bra", "E. fur", "L. blo", "M. tem", "M. coi", "M. mol", "M. ruf", 
                  "M. meg", "M. alb", "M. nig", "M. rip", "N. alb", "P. mac", "P. fus", "R. io", 
                  "R. naso", "S. bil", "S. lep", "M. megaphy")

# Crear una función que asigne 1, 2 o 3 basado en el nombre del murciélago
asignar_categoria <- function(nombre) {
  if (nombre %in% frugivoros) {
    return(1)
  } else if (nombre %in% insectivoros) {
    return(2)
  } else if (nombre %in% frugivoros_insectivoros) {
    return(3)
  } else {
    return(NA)  # En caso de que el nombre no esté en ninguna categoría
  }
}

datos <- datos %>%
  mutate(categoria = sapply(Tratamiento, asignar_categoria))
datos <- datos %>%
  mutate(Estadios = case_when(
    Estadios %in% c(1) ~ 1,  # No reproductivo
    Estadios %in% c(2) ~ 2,  # Reproductivo
    Estadios %in% c(3, 5) ~ 3,  # Crianza temprana
    Estadios %in% c(4) ~ 4,  # Gestación
    Estadios %in% c(6, 7) ~ 5,  # Desarrollo esquelético
    TRUE ~ Estadios  # Mantener otros valores como están
  ))
#View(datos)
colnames(datos)
table(datos$Estadios)
seed_cols <- c("A. alo", "A. nym", "C. pel", "F.  ins", "F.  nym", "P. hed", "P. riv", 
               "S. gla", "S. bet", "S. nig", "V. gui", "W. bac", "B. gra", "C. pur", 
               "C. alb", "H. fis", "P. adu", "P. ama", "P. dul", "S. qui", "P. per", 
               "P. not", "C. tap", "C. pub", "C. inc", "S. mac")

# Insect columns
insect_cols <- c("A. ven", "T. vir", "Cersp...37", "Cersp...84", "Colsp", "C. mac", 
                 "Diasp...40", "Diasp...91", "D. sp1", "Digsp", "Dissp", "Episp", 
                 "Limsp", "L. ory", "Lissp", "Oecsp", "Ontsp", "Psesp", "Dersp", 
                 "Aedsp", "Brusp", "Calsp", "Chisp", "Hexsp", "Mersp", "Morsp", 
                 "Mussp...59", "Mussp...60", "Odosp", "Ptesp", "Simsp", "Aposp", 
                 "Baesp", "Closp", "Thrsp", "Alksp", "B. leu", "Blisp", "D. cly", 
                 "H. sim", "Nezsp", "O. ins", "Oebsp...75", "Oebsp...76", "Redsp", 
                 "T. ori", "Tagsp", "Tibsp", "Apesp", "Bomsp", "Camsp", "Ectsp", 
                 "Nassp", "Agrsp...87", "Agrsp...103", "C. con", "C. teu", "D. sac", 
                 "Elasp", "H. lao", "Ichsp", "M. lat", "Mocsp", "Opssp", "R. alb", 
                 "Salsp", "S. fru", "Tinsp", "Z. ell", "C. mic", "Orpsp", "Uvasp", 
                 "Anasp", "Atosp")

# se assegura que columnas sean numericas
datos[seed_cols] <- lapply(datos[seed_cols], function(x) as.numeric(as.character(x)))
datos[insect_cols] <- lapply(datos[insect_cols], function(x) as.numeric(as.character(x)))

# Calcula sumas
datos <- datos %>%
  rowwise() %>%
  mutate(Seed_Sum = sum(c_across(all_of(seed_cols)), na.rm = TRUE),
         Insect_Sum = sum(c_across(all_of(insect_cols)), na.rm = TRUE)) %>%
  ungroup()
library(gamlss.dist)
# Convert Sexo from 1 and 2 to 0 and 1
datos <- datos %>%
  mutate(Sexo = ifelse(Sexo == 1, 0, 1))
datos$Sexo

######estadios reproductivos
modelo <- gamlss(Estadios ~ `Época climática`+ Año + Localidad + Sexo,
                 family = MN5(), data = na.omit(datos))

summary(modelo)
plot(modelo)
ks.test(modelo$residuals, "pnorm")
#####sexo

modelo <- gamlss(Sexo ~ Estadios + Localidad  + Habitat ,
                 family = BI, data = na.omit(datos))

summary(modelo)
plot(modelo)
ks.test(modelo$residuals, "pnorm")
####tipo de murcielago
modelo <- gamlss(categoria ~  Estadios  + Localidad  + Habitat  + Seed_Sum + Insect_Sum,
                 family = MN3(), data = na.omit(datos))

summary(modelo)
plot(modelo)

ks.test(modelo$residuals, "pnorm")
####PCAy MCA
library(factoextra)
library(FactoMineR)
library(ggplot2)
#install.packages("rio")
library(rio)

# Convierte Sexo de 1 y 2 a 0 y 1
datos <- datos %>%
  mutate(Sexo = ifelse(Sexo == 1, 2, 1))


### Variables categóricas
d=datos
summary(d)
d<-na.omit(d)

d$Tratamiento<-as.factor(d$Tratamiento)
d$Localidad<-as.factor(d$Localidad)
d$Sexo<-as.factor(d$Sexo)
d$Estadios<-as.factor(d$Estadios)
d$Habitat<-as.factor(d$Habitat)
d$categoria<-as.factor(d$categoria)
d$`Época climática`<-as.factor(d$`Época climática`)
d$Mes<-as.factor(d$Mes)
d$Año<-as.factor(d$Año)
d$Sexo <- factor(d$Sexo, levels = c(1, 2), labels = c("Hembra", "Macho"))
d$`Época climática`<-factor(d$`Época climática`, levels = c(1, 2, 3), labels = c("Época seca", "Transición","Lluvia"))
d$categoria <- factor(d$categoria, levels = c(1, 2, 3), labels = c("Frugívoros", "Insectívoros", "Frugívoros e Insectívoros"))
d$Estadios <-factor(d$Estadios, levels = c(1, 2, 3, 4, 5), labels = c("No reproductivo", "Reproductivo", "Crianza temprana", "Gestantes", "Desarrollo esqueletico"))
d$Mes <- factor(d$Mes, levels =c(1,2,3,4,5,6,7,8,9,10,11,12), labels = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                                                     "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"))

# Analisis de Correspondencias multiples:
dfacto<-d[,c(2:8,109)]
#View(dfacto)
ACM <- MCA(dfacto,graph = T)
summary(ACM)

fviz_screeplot(ACM,labelsize = 0.1,addlabels = T,barfill = "yellow3")

# Cosenos2 de Variables a las dimensiones
#corrplot::corrplot(cl.cex = 0.8,tl.cex = 0.8,tl.col = "gray2",t(ACM$var$cos2),is.corr = F)

#Plano 1-2 estadios reproductivos
f <- fviz_mca_biplot(
  X = ACM,
  repel = TRUE,
  title = "Plano 1-2 del ACM segun el Estadio reproductivo",
  labelsize = 3,
  col.var = "gray2",
  label = "var",
  col.ind = d$Estadios,
  palette = c("slategray2", "yellow2", "blue", "red", "green")
)
f + theme(legend.title = element_blank())

#######tipo de murcielago
#Plano 1-2
f <- fviz_mca_biplot(
  X = ACM,
  repel = TRUE,
  title = "Plano 1-2 del ACM según el tipo de murcielago",
  labelsize = 3,
  col.var = "gray2",
  label = "var",
  col.ind = d$categoria,
  palette = c("slategray2", "yellow2","deepskyblue4")
)
f + theme(legend.title = element_blank())


###sexo del murcielago
f <- fviz_mca_biplot(
  X = ACM,
  repel = TRUE,
  title = "Plano 1-2 del ACM según Sexo de los Murciélagos",
  labelsize = 3,
  col.var = "gray2",
  label = "var",
  col.ind = d$Sexo,
  palette = c("slategray2", "yellow2")  # Asumiendo que hay dos niveles: hembras y machos
)
f + theme(legend.title = element_blank())

####epoca climatica
f <- fviz_mca_biplot(
  X = ACM,
  repel = TRUE,
  title = "Plano 1-2 del ACM según Época Climática",
  labelsize = 3,
  col.var = "gray2",
  label = "var",
  col.ind = d$`Época climática`,
  palette = c("slategray2", "yellow2", "deepskyblue4")  # Ajustar según el número de niveles
)
f + theme(legend.title = element_blank())

#######

