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
FBAndSplitBehaviorTest >> testTriggerRequiringTargetIsSuspendedInsteadOfActivated [
	"FBAndSplitBehavior sends #followTransition:withToken:, which used to queue the
	transition without consulting the target's #requiresTrigger - the target was
	activated right away and took the split's value as its own output"
	| start split trigger other join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	trigger := FBTriggerTask named: 'trigger'.
	other := FBTask named: 'other'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> trigger --> join.
	split --> other --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance execute.
	self deny: (instance activations anySatisfy: [ :act | act node = trigger ]).
	self
		assert: (instance suspended collect: [ :each | each target ]) asArray
		equals: { trigger }
]

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testSuspendedTriggerKeepsTheBranchTokenItWouldHaveBeenActivatedWith [
	"the token has to survive the suspension: whoever resumes builds a fresh activation,
	and without it that activation would carry a default token with no #splitId - the
	resumed branch would then reach the join under a split id of its own and neither
	half of the split could ever complete"
	| start split trigger other join end flow instance token |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	trigger := FBTriggerTask named: 'trigger'.
	other := FBTask named: 'other'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> trigger --> join.
	split --> other --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance execute.
	token := instance executor takeTokenForSuspended: instance suspended first.
	self assert: token notNil.
	self
		assert: token splitId
		equals: (instance activations detect: [ :act | act node = other ]) token splitId
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
FBAndSplitBehaviorTest >> testBranchesOfOneSplitShareASplitId [
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
	self assert: aToken splitId equals: bToken splitId
]

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testSplitIdSurvivesAnIntermediateNodeBeforeTheMerge [
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

{ #category : 'as yet unclassified' }
FBAndSplitBehaviorTest >> testJoinIsReleasedWhenBothBranchesArriveThroughTheSamePredecessor [
	"Both branches of one split reach the join through the same predecessor node 'a':
	one directly, the other after passing 'b' first. FBJoinBehavior keys FBJoinState>>arrived
	by FBBaseActivation>>sourceNode, so both arrivals land under the same key.
	The collision is real - #arrived holds one entry for two arrivals - but it does not
	stall the join: #expected comes from the join's own incoming transitions, and both
	branches share the single transition a --> join, so one arrival already satisfies it.
	The join is released twice instead of once, which is the open question of whether a
	possibility needs its own object, not of how arrivals are keyed."
	| start split a b join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> a.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	"the scenario only holds if 'a' really runs twice - once per branch"
	self
		assert: (instance activations select: [ :each | each node = a ]) size
		equals: 2.
	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = end ])
]
