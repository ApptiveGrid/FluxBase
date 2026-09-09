Class {
	#name : 'FBWaitForConditionBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBWaitForConditionBehavior >> execute [
	"the token is handed over even though resuming this wait takes the parked activation
	back up and needs nothing restored (FBNode>>resumeIn:withToken:value:): an entry in
	the waiting registry has to carry the strand that is parked, and this is the only
	place that knows it. Without it a wait that is reachable from outside would be
	registered with a nil token.

	A condition that holds is a step that is over: marked #done like any task's, since
	nothing marks a step done centrally and this activation would otherwise stay
	#created in the log"
	(self node evaluateConditionWith: activation argument)
		ifTrue: [
			activation done.
			activation followAllOutgoing ]
		ifFalse: [ activation waitForNode: self node withToken: activation token ]
]
