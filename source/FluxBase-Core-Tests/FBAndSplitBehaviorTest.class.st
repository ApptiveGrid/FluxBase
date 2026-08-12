Class {
	#name : 'FBAndSplitBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBAndSplitBehaviorTest >> testAllOutgoingTransitionsAreFollowedUnconditionally [
	| start split a b end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> split.
	split --> a --> end.
	split --> b --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = a ]).
	self assert: (instance activations anySatisfy: [ :each | each node = b ])
]

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testBranchTokensParentIdPointsAtTheSplitsOwnTokenId [
	| start split a b end flow instance splitToken aToken bToken |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> end.
	split --> b --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	splitToken := (instance executor activationOf: split) token.
	aToken := (instance executor activationOf: a) token.
	bToken := (instance executor activationOf: b) token.
	self assert: aToken parent equals: splitToken.
	self assert: bToken parent equals: splitToken
]

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testBranchesShareASplitIdButHaveDistinctBranchIds [
	| start split a b end flow instance aToken bToken |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> end.
	split --> b --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	aToken := (instance executor activationOf: a) token.
	bToken := (instance executor activationOf: b) token.
	self assert: aToken splitId notNil.
	self assert: aToken splitId equals: bToken splitId.
	self deny: aToken branchId equals: bToken branchId
]

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testSplitIdAndBranchIdSurviveAnIntermediateNodeBeforeTheMerge [
	| start split a a2 b end flow instance aToken a2Token bToken |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	a2 := FBTask named: 'a2'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> a2 --> end.
	split --> b --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	aToken := (instance executor activationOf: a) token.
	a2Token := (instance executor activationOf: a2) token.
	bToken := (instance executor activationOf: b) token.
	self assert: a2Token splitId equals: aToken splitId.
	self assert: a2Token splitId equals: bToken splitId.
	self assert: a2Token branchId equals: aToken branchId.
	self assert: a2Token parent equals: aToken
]

{ #category : 'tests' }
FBAndSplitBehaviorTest >> testValuePropagatesToEachBranch [
	| start split a b end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> split.
	split --> a --> end.
	split --> b --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.

	self assert: (instance activations detect: [ :each | each node = a ]) argument equals: 42.
	self assert: (instance activations detect: [ :each | each node = b ]) argument equals: 42
]
