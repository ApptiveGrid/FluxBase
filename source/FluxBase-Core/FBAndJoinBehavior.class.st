Class {
	#name : 'FBAndJoinBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'as yet unclassified' }
FBAndJoinBehavior >> execute [
	| joinState token |
	activation value: self argument.
	token := activation token.
	joinState := activation instance joinStateFor: activation node splitId: token splitId.
	(joinState arrived includes: token branchId) ifFalse: [ joinState arrived add: token branchId ].
	activation done.
	(joinState arrived size >= joinState expected size) ifTrue: [ activation followAllOutgoing ]
]
