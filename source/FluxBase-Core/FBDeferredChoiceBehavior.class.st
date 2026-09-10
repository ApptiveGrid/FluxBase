Class {
	#name : 'FBDeferredChoiceBehavior',
	#superclass : 'FBAndSplitBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBDeferredChoiceBehavior >> execute [
	"a deferred choice starts every branch like an AND-split does, and each has to park
	at once: a branch that ran on would decide nothing and let the others go on with it"
	activation node outgoing do: [ :transition |
		transition target parksOnEntry ifFalse: [
			FBError signal: 'every branch of a deferred choice has to lead into a node that waits; ',
				transition target printString, ' does not' ] ].
	super execute
]
