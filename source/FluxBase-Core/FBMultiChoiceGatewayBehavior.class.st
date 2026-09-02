Class {
	#name : 'FBMultiChoiceGatewayBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBMultiChoiceGatewayBehavior >> execute [
	| splitId matchingTransitions |
	activation value: self argument.
	activation done.
	splitId := FBIdGenerator current newId.
	matchingTransitions := activation node outgoing select: [ :t | activation transitionMatches: t ].
	activation instance registerExpectedBranchCount: matchingTransitions size forSplitId: splitId.
	matchingTransitions do: [ :transition |
		activation followTransition: transition withToken: (
			activation childToken
				splitId: splitId;
				yourself) ]
]
