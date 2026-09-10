Class {
	#name : 'FBMultiChoiceGatewayBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBMultiChoiceGatewayBehavior >> execute [
	"like FBAndSplitBehavior, for the branches whose condition holds: the pass counts
	those, so the join behind it waits for exactly the strands that were started"
	| matchingTransitions split |
	activation value: self argument.
	activation done.
	matchingTransitions := activation node outgoing select: [ :t | activation transitionMatches: t ].
	split := FBSplitExecution openedBy: activation branchCount: matchingTransitions size.
	matchingTransitions do: [ :transition |
		activation followTransition: transition withToken: (
			activation childToken
				split: split;
				yourself) ]
]
