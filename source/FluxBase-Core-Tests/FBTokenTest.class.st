Class {
	#name : 'FBTokenTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBTokenTest >> testAccessorsRoundTrip [
	| token parent scope |
	parent := FBToken new.
	scope := FBScope new.
	token := FBToken new.
	token
		value: 42;
		scope: scope;
		parent: parent;
		splitId: 'split-1';
		state: #waiting;
		metadata: #(1 2 3).
	self assert: token value equals: 42.
	self assert: token scope equals: scope.
	self assert: token parent equals: parent.
	self assert: token splitId equals: 'split-1'.
	self assert: token state equals: #waiting.
	self assert: token metadata equals: #(1 2 3)
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testNodeIsDerivedFromTheActivationRatherThanStored [
	| activation |
	self assert: FBToken new node isNil.
	activation := FBActivation new.
	activation node: (FBTask named: 't').
	self assert: activation token node equals: activation node.
	"and it follows the activation rather than holding a stale copy"
	activation node: (FBTask named: 'other').
	self assert: activation token node equals: activation node
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testTokenKnowsTheActivationItIsAttachedTo [
	| activation loose |
	activation := FBActivation new.
	self assert: activation token activation equals: activation.
	loose := FBToken new.
	self assert: loose activation isNil.
	activation token: loose.
	self assert: loose activation equals: activation
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testLegacyParentIdReadsThroughToTheParentReference [
	"#parentId only exists for tokens persisted before #parent was a real reference.
	For a token that has a parent it must not contradict it."
	| parent child |
	parent := FBToken new.
	child := FBToken new parent: parent; yourself.
	self assert: child parentId equals: parent id.
	self assert: FBToken new parentId isNil
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testNewTokenHasReadyStateAndUniqueId [
	| a b |
	a := FBToken new.
	b := FBToken new.
	self assert: a state equals: #ready.
	self assert: a id notNil.
	self deny: a id equals: b id
]
