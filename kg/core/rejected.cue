// Failed approach — document to prevent re-exploration
package core

// #Rejected records an approach that was tried and failed.
// alternative is REQUIRED — every rejection must suggest what to do instead.
// This prevents the "we tried that and it didn't work" conversation loop.
#Rejected: {
	"@type":     "kg:Rejected"
	id:          =~"^REJ-\\d{3}$"
	approach:    string & !=""
	reason:      string & !=""
	date:        =~"^\\d{4}-\\d{2}-\\d{2}$"
	alternative: string & !="" // what to do instead (required — forces constructive rejection)
	related?:    {[string]: true}
	...
}
