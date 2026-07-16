Class {
	#name : 'FBAndJoinBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'as yet unclassified' }
FBAndJoinBehavior >> execute [
	| joinState token sourceActivation sourceNode |
	activation value: self argument.
	token := activation token.
	joinState := activation instance joinStateFor: activation node splitId: token splitId.
	sourceActivation := activation instance activations
		detect: [ :act | act token id = token parentId ]
		ifNone: [ nil ].
	sourceNode := sourceActivation ifNotNil: [ sourceActivation node ].
	joinState arrived at: sourceNode put: self argument.
	activation done.
	(joinState arrived size >= joinState expected size) ifTrue: [ 
		activation value: joinState arrived.
		activation followAllOutgoing ]
]
