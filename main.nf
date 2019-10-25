#!/usr/bin/env nextflow

/** MSB1015 - Assignment 3
* @author Ammar Ammar
*/

/* get jar dependencies for CDK from maven using Grab dependency manager in Groovy.
   Since CDK main library has classes to handle SMILE parsing, there was no need to use 
   the "bacting" project dependencies, so CDK bundle was used alone with less overhead by avoiding 
   a second dependency.
*/ 
@Grab(group='org.openscience.cdk', module='cdk-bundle', version='2.3')

// Inporting the required classes to parse the SMILEs and calculating the descriptor.

import org.openscience.cdk.*;
import org.openscience.cdk.templates.*;
import org.openscience.cdk.tools.*;
import org.openscience.cdk.tools.manipulator.*;
import org.openscience.cdk.qsar.descriptors.molecular.*;
import org.openscience.cdk.qsar.result.*;
import org.openscience.cdk.smiles.*;
import org.openscience.cdk.silent.*;


// defining the input channel that will read the SMILEs TSV file and parse it line by line
// each row is mapped to a tuple of three items (3 columns)

Channel.fromPath("./data/wikidata_smiles.tsv")
    .splitCsv(header: ['molecule_ids', 'smiles', 'isoSmiles'], sep:'\t', by:1000)
    .map{ row -> tuple(row.molecule_ids, row.smiles, row.isoSmiles) }
    .set { molecules_ch }

// define in instance of the SMILES parser and the JPlogP descriptor classes form CDK
// Since those classes will be used in every process instance, it is better to define them here

smileParser  = new SmilesParser(SilentChemObjectBuilder.getInstance())
jplogpDescriptor = new JPlogPDescriptor()

/*
 Define the process that will calculate the JPlogP after parsing the SMILEs into AtomContainer
*/
process calculateAndPrintJPlogP {

    // define the input which is a set of three value from the input channel
    input:
    set molecule_ids, smiles, isoSmiles from molecules_ch

    exec:

	try {
	
		// Loop through the set of isoSmiles (of length 1000) channeled from the input channel as chunk
		// and perform the descriptor calculation and printing on each item

		for(int i = 0; i < isoSmiles.size(); i++){

			// clean the Wikidata molecule id by extracting only the ID form the URL
			molecule_id = molecule_ids[i].substring(molecule_ids[i].lastIndexOf("/")+1)

			// Check if the isoSmile is not empty then parse it, otherwise check the canonical smile
			if(!isoSmiles[i].trim().equals("")){

				// parse the iso smile into AtomContainer
				moleculeAtomContainer = smileParser.parseSmiles(isoSmiles[i])				
				
			}else{
				// if the isoSmile is empty, print a message and try parsing the canonical smile
				println "Isomeric SMILE for $molecule_id not found, Trying canonical SMILE.."

				// check if the canonical smile is not empty
				if(!smiles[i].trim().equals("")){
					
					// parse the smile into AtomContainer
					moleculeAtomContainer = smileParser.parseSmiles(smiles[i])				
				}else{
					println "Canonical SMILE not found, NAN value will be reported"
				}
			}

			// calculate the JPlogP descriptor for the molecule AtomContainer
			jplogp = jplogpDescriptor.calculate(moleculeAtomContainer).getValue()

			// Print the JPlogP value
			println "JPLogP of $molecule_id : " + jplogp
		}		
	
	} catch (Exception exc) {
		// Catch the errors if any and report them to console
		println "Error : " + exc.message
	} 
}
