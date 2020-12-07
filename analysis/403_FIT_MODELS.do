


* Need validation dataset with FOI vars for every day...


* Est lambda = exp(cons + xb + z tvc) = exp(cons+xb) x exp(ztvc)
* So get validation data, pick up xb (accept can't update through month). 
* Pick up foi_coefs dataset, get exp(z tvc) from that. 
* Options:		i. use actual foi from future
*				ii. use historical data to predict
*				iii. scenario planning (stay same, grow exponentially)


* P(survive 28 days) =  (P no COVID death day 1) x P(no non-COVIDD death day 1)  	
*					+ 	(P no COVID death day 2) x P(no non-COVIDD death day 2)  	
*					+ 	(P no COVID death day 3) x P(no non-COVIDD death day 3)  	
*					+ 	(P no COVID death day 4) x P(no non-COVIDD death day 4)  	
*					+ 	(P no COVID death day 5) x P(no non-COVIDD death day 5)  	
*					+ 	etc.

* P(die 28 days) = 1 - P(survive)

