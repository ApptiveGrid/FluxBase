Class {
	#name : 'FBTokenTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBTokenTest >> testAccessorsRoundTrip [
	| token parent scope split |
	parent := FBToken new.
	scope := FBScope new.
	split := FBSplitExecution new.
	token := FBToken new.
	token
		scope: scope;
		parent: parent;
		split: split;
		state: #waiting.
	self assert: token scope equals: scope.
	self assert: token parent equals: parent.
	self assert: token split identicalTo: split.
	self assert: token splitId equals: split id.
	self assert: token state equals: #waiting
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
FBTokenTest >> testNewTokenHasReadyStateAndUniqueId [
	| a b |
	a := FBToken new.
	b := FBToken new.
	self assert: a state equals: #ready.
	self assert: a id notNil.
	self deny: a id equals: b id
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testWaitingIsPartOfTheTokensVocabularyAndDoneIsNot [
	"a strand is #ready or #waiting - and later #cancelled. It never becomes #done: it
	ends by disappearing, not by carrying a state saying it ended (see my class comment)"
	| token |
	token := FBToken new.
	self deny: token isWaiting.
	token waiting.
	self assert: token isWaiting.
	self assert: token state equals: #waiting
]
