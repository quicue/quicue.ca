// Data pipeline audit trail — tracks provenance and source classification
package ext

// #Derivation records what a pipeline worker produced, from what inputs,
// and how the output relates to original source data:
//   pure    = unmodified source data
//   mixed   = partially derived from source
//   derived = fully computed or inferred
#Derivation: {
	"@type":            "kg:Derivation"
	id:                 =~"^DERIV-\\d{3}$"
	worker:             string & !=""
	output_file:        string & !=""
	date:               =~"^\\d{4}-\\d{2}-\\d{2}$"
	description:        string & !=""
	canon_purity:       "pure" | "mixed" | "derived"
	canon_sources:      [...string] & [_, ...] // at least one source
	non_canon_elements: [...string]
	action_required:    string & !=""
	input_files:        [...string]
	record_count?:      int & >=0
	related?:           {[string]: true}
}
