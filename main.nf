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

