Class {
	#name : 'FBAndSplitBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBAndSplitBehavior >> execute [
	| splitId |
	activation value: self argument.
	activation done.
	splitId := FBIdGenerator current newId.
	activation node outgoing do: [ :transition |
		activation followTransition: transition withToken: (
			activation childToken
				splitId: splitId;
				yourself) ]
]
