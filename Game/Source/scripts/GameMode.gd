extends Reference
var scores=[0,0]
var limit=20
var elapsed=0.0
var winner=-1
var time_limit=480.0
func reset():
	scores=[0,0];elapsed=0;winner=-1
func kill(victim_team):
	scores[1-victim_team]+=1
	if scores[1-victim_team]>=limit:winner=1-victim_team
