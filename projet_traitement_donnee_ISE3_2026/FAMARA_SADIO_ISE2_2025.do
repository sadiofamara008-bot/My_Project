* Indicateur Multidimensionnel de la pauvreté selon l'approche Alkyre et Foster

* Version de STATA utilisée 

version 18.0 

*Pour afficher tous les résultats d'une commande 

set more off 

* Femer l'ancien fichier log

capture log close 

* Définition du fichier log des commandes 

log using "fichier_log.txt", replace 

* Répertoire 

cd "C:\Users\lenovo\Desktop\Var_Qual_FAMARA-SADIO_ISE2_2025\Var_Qual_FAMARA-SADIO_ISE2_2025\Var_Qual_FAMARA_SADIO_ISE2_2025"

* Importation et inspection des bases de données 

* Base individus

use "ehcvm_individu_SEN2021", clear 

* Nombre d'observations

count 

* il y a hhid l'identifiant du ménage 

* Base ménage 

use "ehcvm_menage_SEN2021", clear 

* Nombre d'observations

count 

duplicates list hhid

* il y a hhid l'identifiant du ménage 

* Base welfare 

use "ehcvm_welfare_SEN2021", clear 

* Nombre d'observations

count 


* il y a hhid l'identifiant du ménage 

* Il nous faut merger toutes les bases afin d'avoir les indicateurs de chaque dimension. Le résultat devra être une base individus & ménage de sorte que l'on puisse identifier chaque individu dans son ménage et construire les indicateurs niveau ménage et niveau individu tel que dans le tableau de Alkyre et Foster. 


*********** Fusion des bases de données ***************

* Objectif de la fusion

* Il faut associer les données individuelles à leurs caractéristiques de ménage (ehcvm_menage_SEN2021) et de bien-être (ehcvm_welfare_SEN2021) via l'identifiant hhid.

* Il faut donc partir de la base individuelle, car elle a le plus grand nombre de lignes (63 530), et y ajouter les informations des deux autres bases (7 120 ménages).

* Étape 1 : Chargement de la base individuelle

use "ehcvm_individu_SEN2021.dta", clear

* Étape 2 : Fusion des caractéristiques du ménage

merge m:1 hhid using "ehcvm_menage_SEN2021.dta"

* Vérifions  la fusion

tab _merge

* Gardons seulement les observations correspondantes (cas où on a trouvé une correspondance)

keep if _merge == 3
drop _merge

* Étape 3 : Fusion des données de bien-être

merge m:1 hhid using "ehcvm_welfare_SEN2021.dta"

* Vérifions la fusion

tab _merge
keep if _merge == 3
drop _merge

* Sauvegardons la base finale

save "ehcvm_SEN2021_merge.dta", replace

* Importation 

use "ehcvm_SEN2021_merge.dta", clear

* Nombre d'observations 

count 


********************************************************************************************************************* Construction des indicateurs **************


********************************************************

* Dimension Education :

* Fréquentation  : Le ménage a un enfant de 6-16 ans qui ne fréquente actuellement pas l'école
 
* Création d'une variable individuelle pour identifier les enfants de 6 à 16 ans non scolarisés :

gen enfant_non_scol = (age >= 6 & age <= 16) & scol == 0

* Création de l'indicateur au niveau du ménage (au moins un enfant non scolarisé)

bysort hhid (enfant_non_scol): gen freq_scol = .

bysort hhid: replace freq_scol = 1 if sum(enfant_non_scol) > 0

bysort hhid: replace freq_scol = 0 if freq_scol == .


* Retard scolaire : Le ménage a un enfant de 8-13 ans ayant un retard scolaire de 2 ans ou plus

* Création d'une variable "retard" : différence entre l'âge et le niveau atteint

gen retard = age - educ_scol

* Identification des enfants de 8 à 13 ans en retard de 2 ans ou plus

gen enfant_retard = (age >= 8 & age <= 13) & retard >= 8

* Indicateur au niveau ménage : présence d'au moins un enfant concerné

gen retard_scol =.

bysort hhid (enfant_retard): replace retard_scol = 1 if sum(enfant_retard) > 0

bysort hhid: replace retard_scol = 0 if retard_scol == .



* Nombre d'années de scolarité : Aucun membre du ménage âgé de 15 ans ou plus n'a complété 6 années d'études

* Identification des personnes âgées de plus de 15 n'ayant pas complété plus de 6 années d'études 

gen nombre_annee = age > 15 & educ_hi < 6

* Indicateur au niveau ménage

gen nbre_annee_scol =. 

bysort hhid (nombre_annee): replace nbre_annee_scol = 1 if sum(nombre_annee) > 0

bysort hhid: replace nbre_annee_scol = 0 if nbre_annee_scol == .


* Alphabétisation : Le quart des membres du ménage de 15 ans ou plus ne sait pas lire ou écrire (Français/Arabe/Autre) 

* On Garde les individus de 15 ans ou plus

gen age15plus = age >= 15

* Identification  des analphabètes de 15 ans ou plus

gen analphabete = (age15plus == 1 & alfa == 0)

* Création des totaux par ménage avec egen

egen nb_15plus = total(age15plus), by(hhid)
egen nb_analpha = total(analphabete), by(hhid)

* Calcule de la proportion d'analphabètes
gen prop_analpha = nb_analpha / nb_15plus

*  Création de l'indicateur dichotomique
gen alpha_priv = (prop_analpha >= 0.25)




*****************************************************

* Dimension Santé

* Couverture maladie : Plus du tiers des membres du ménage ne disposent d'aucune forme d'assurance maladie

* Identification des personnes non couvertes
gen non_couvert = (couvmal == 0)

* Nombre total de membres du ménage

gen membre = 1
egen nb_membres = total(membre), by(hhid)

* Nombre de membres non couverts
egen nb_non_couverts = total(non_couvert), by(hhid)

* Calcule de la proportion non couverte
gen prop_non_couv = nb_non_couverts / nb_membres

* Création de l'indicateur dichotomique
gen assur_priv = (prop_non_couv > 1/3)



* Qualité des services de santé : Un membre du ménage apprécie négativement au moins 5 critères (de qualité de services de santé) sur 6

* N'existe pas : On laisse 


* Maladies et problèmes de santé : Un membre du ménage souffre d'une maladie chronique (tension ou diabète) remplacé par  "Un membre du ménage souffre de problème de santé au cours des 30 derniers jours"


* Identification des individus malades
gen malade = (mal30j == 1)

* On Compte le nombre de malades par ménage
egen nb_malades = total(malade), by(hhid)

* Indicateur dichotomique : privation si au moins un membre est malade

gen sante_priv = (nb_malades >= 1)

* Vaccination des enfants de 0-6 ans : Un enfant de 0-6 ans du ménage n'a pas été vacciné lors de la campagne passée

* N'existe pas on laisse 

* Handicap physique et mental : Un membre du ménage souffre d'un handicap physique ou mental l'empêchant d'exercer une activité ou d'aller à l'école. 

* J'utilise la variable Handicap tout niveau 

* Création d'une variable binaire indiquant présence de handicap

gen handicap = (handit == 1)

* Nombre de membres handicapés par ménage

egen nb_handicap = total(handicap), by(hhid)

* Indicateur de privation : au moins un membre avec handicap

gen handicap_priv = (nb_handicap >= 1)


****************************************************

* Dimension Conditions de vie

* Type de logement : Le ménage est privé si le logement est une case ou baraque ou « autre »

tab1 logem toit mur

* Privation par statut d'occupation (locataire ou autre)


gen priv_occup = inlist(logem, 3, 4)   // 3 = Locataire, 4 = Autre

* Privation si toit NON en matériaux définitifs (toit == 0)

gen priv_toit = (toit == 0)

* Privation si mur NON en matériaux définitifs (mur == 0)

gen priv_mur = (mur == 0)

* Indicateur global de privation de logement

gen logement_priv = (priv_occup == 1 | priv_toit == 1 | priv_mur == 1)



* Électricité : La source d'éclairage du ménage n'est pas : électricité, groupe électro. ou solaire

tab1 elec_ac elec_ua elec_ur

* Création d'indicateurs binaires de privation

gen priv_ua = (elec_ua == 0)
gen priv_ur = (elec_ur == 0)
gen priv_ug = (elec_ur == 0)  // solaire/groupe

* Ménage privé d'électricité = 1 si toutes les sources = non

gen electricite_priv = (priv_ua == 1 & priv_ur == 1 & priv_ug == 1)



* Evacuation des eaux usées :  Le ménage est privé si l'évacuation se fait dans la cour ou dans la rue/nature

tab eva_eau

 
* Evacuation des ordures ménagères : Le ménage est privé si l'évacuation se fait par tas d'immondices ou dans la route/rue 

tab ordure

* Indice de surpeuplement : Le ménage est privé si le logement est surpeuplé (plus de 3 personnes par pièce) 

* On laisse on a pas le nombre de pièces 

 
* Eau potable : Le ménage n'a pas accès à l'eau potable


gen eau_potable = (eauboi_sp==0 | eauboi_ss==0)
 

* Énergie de cuisson : Le ménage n'utilise pas d'énergie propre pour la cuisson (électricité et gaz)

tab cuisin



* Équipements sanitaires : Le ménage ne dispose pas de toilettes privées améliorées 

tab toilet
 
 
* Biens d'équipement : Le ménage dispose de moins de 2 équipements dans la liste suivante : ventilateur, TV, ordinateur, cuisinière, réfrigérateur, bicyclette, motocyclette et ne dispose ni de voiture, camion, machine à laver ou groupe électrogène
 
gen equipement = (telpor==0 & car==0 & cuisin==0 & decod==0 & fer==0 & frigo==0)



* Création de la variable score de privation qui somme tous les indicateurs (pondérés)

gen score_privation = (freq_scol + retard_scol + nbre_annee_scol + alpha_priv + assur_priv + sante_priv +  handicap_priv + logement_priv +electricite_priv + eva_eau + ordure + eau_potable + cuisin + toilet + equipement)/15

* Création de la variable qui indique s'il l'individu est pauvre ou non 

* Application du seuil de pauvreté. L'individu est pauvre s'il est privé dans 45% de l'ensemble des indicateurs 

gen pauvrete = (score_privation>=0.45)


* Labelisation 

label var pauvrete "Indicateur de pauvreté multidimensionel"

* Label 

label define pauvres 1"Pauvre" 0"Non pauvre"

* Attribution du label 


label values pauvrete pauvres


* Statistiques descriptives de l'indicateur de pauvreté multidimensionel (ipm)


asdoc tab pauvrete, m save(ipm.doc) replace


******************************************************************************************************************************************************************************

***** FACTEURS EXPLICATIFS *******************************

* Facteurs explicatifs de la pauvreté (modèle de regression logistique)
 
* Correction des modalités de la variable education du chef des ménages 

replace heduc=4 if heduc==5 
replace heduc=4 if heduc==6
replace heduc=4 if heduc==7
replace heduc=4 if heduc==8
replace heduc=3 if heduc==2

tab heduc	

* Age au carré 

gen hage_carre = hage*hage


* Statistiques descriptives univariées

* Variables quantitatives 

asdoc sum hage hhsize, save(r1.doc) replace  


* Variables qualitatives 

asdoc tab1 heduc hgender hhandig  hsectins, save(r1.doc) append 

* Statistiques descriptives bivariées

* Education et pauvreté 

asdoc tab heduc pauvrete, nofreq row save(r1.doc) append 

* Genre et pauvreté 

asdoc tab hgender pauvrete [aweight=hhweight], nofreq row save(r1.doc) append 

* Handicap et pauvreté 

asdoc tab hhandig pauvrete, nofreq row save(r1.doc) append 

* Secteur institutionnel et pauvreté 

asdoc tab hsectins pauvrete, nofreq row 


* Résultats des estimations 

* logit: coefficient

logit pauvrete hage hage_carre i.i.heduc  i.hgender hhsize i.hhandig  i.hsectins , robust

* Exportation des résultats 

eststo coef

outreg2 [coef] using "estimations.xls", stats(coef se) bracket(se) aster label ct(Coefficients) addstat(Pseudo R2, e(r2_p), Observations, e(N)) nocon nor2 word excel dec(3) noobs replace


* Effet seuil au niveau de l'âge 

disp - _b[hage]/(2*_b[hage_carre])


* Odds ratios


logit pauvrete hage hage_carre i.i.heduc  i.hgender hhsize i.hhandig  i.hsectins, robust or

* Exportation des résultats 

eststo odds

outreg2 [odds] using "estimations.xls", eform stats(coef se) bracket(se) aster label ct(Odds ratios) addstat(Pseudo R2, e(r2_p), Observations, e(N)) nocon nor2 word excel dec(3) noobs append

	
	
* Effets marginaux 

* On dichotomise d'abord les variables 


tab heduc, gen(heduc)
tab hgender, gen(hgender)
tab hhandig, gen(hhandig)
tab hsectins, gen(hsectins)

* On refait le modèle logit avec les variables dichotomiques 


logit pauvrete hage hage_carre heduc1 hgender1 hhsize hhandig1  hsectins1, robust


* On calcule les effets marginaux à un point fixe pour les variables qualitatives et au point moyen pour les variables quantitatives 

mfx compute, at(heduc1=1, hgender1=1, hhandig1=1, hsectins1=1)


* Goodness-of-fit test after logistic model

* On refait d'abord le modèle initial 

logit pauvrete hage hage_carre i.i.heduc  i.hgender hhsize i.hhandig  i.hsectins, robust


* Goodness-of-fit test after logistic model

estat gof


* Tests de validation 

fitstat 

* Matrice de confusion 

estat classification


* Courbe de roc 

lroc

lsens 


* multicolinéarité 

* MPL

reg pauvrete hage heduc hgender hhsize hhandig  hsectins, robust

vif

log close 
