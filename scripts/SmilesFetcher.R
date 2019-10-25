#------------------------------------------------------------------
# Project       : MSB1015 - Assignment 3
# Author        : Ammar Ammar
# Date          : 2019-10-24
# Description   : Retreive all compounds SMILEs and IsoSMILEs from Wikidata to a TSV file
# Source System : R 3.5.2 (64 Bit)
# Release       : 1
# License       : GNU GPL v3
# File Name     : SmilesFetcher.R
#------------------------------------------------------------------------------- 


# install the required package if it does not exist

if (!requireNamespace("WikidataQueryServiceR", quietly = TRUE))
    install.packages("WikidataQueryServiceR", dependencies = TRUE)


# load the required package
library(WikidataQueryServiceR)


# SPARQL query to select all the compounds with their corresponding SMILE and isoSMILE if exists
query <- 'SELECT DISTINCT ?compound ?smiles ?isoSmiles WHERE {
            ?compound wdt:P233 | wdt:P2017 [] .
            OPTIONAL { ?compound wdt:P233 ?smiles }
            OPTIONAL { ?compound wdt:P2017 ?isoSmiles }
          }'

# Execute the query against Wikidata SPARQL endpoint and retreive the results
SparqlResultSet <- query_wikidata(query)


# set the working directory to the scripts folder with setwd() if you are not already there

# Write the SPARQL query results to a TSV file
write.table(SparqlResultSet, file = "../data/wikidata_smiles.tsv", 
            sep = "\t", row.names = FALSE, quote = F)
