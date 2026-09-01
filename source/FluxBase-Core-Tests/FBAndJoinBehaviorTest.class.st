Class {
	#name : 'FBAndJoinBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testCompletingActivationValueIsADictionaryOfSourceNodeToValue [
	| start split a b join end flow instance completingActivation joinValue |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	completingActivation := (instance activations select: [ :act | act node = join ]) last.
	joinValue := completingActivation value.
	self assert: (joinValue at: a) equals: 6.
	self assert: (joinValue at: b) equals: 50
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testDoesNotProceedUntilAllBranchesHaveArrived [
	| start split a b join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initializeExecutor.
	instance step. "start"
	instance step. "split"
	instance step. "a arrives at join"
	self deny: (instance activations anySatisfy: [ :act | act node = end ])
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testDuplicateArrivalFromTheSameSourceNodeIsNotCountedTwice [
	| start split a b join end flow instance realActivationForA duplicate1 duplicate2 joinState splitIdUsed |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initializeExecutor.
	instance step. "start"
	instance step. "split"
	instance step. "a itself runs (not yet at join)"
	realActivationForA := instance activationOfNode: a.
	splitIdUsed := realActivationForA token splitId.
	duplicate1 := FBActivation new executor: instance executor; node: join; argument: 10; yourself.
	duplicate1 token splitId: splitIdUsed; parent: realActivationForA token.
	duplicate2 := FBActivation new executor: instance executor; node: join; argument: 20; yourself.
	duplicate2 token splitId: splitIdUsed; parent: realActivationForA token.
	(join defaultBehaviorClass new activation: duplicate1; yourself) execute.
	(join defaultBehaviorClass new activation: duplicate2; yourself) execute.
	joinState := instance joinStateFor: join splitId: splitIdUsed.
	self assert: joinState arrived size equals: 1.
	self assert: (joinState arrived at: a) equals: 20 "second delivery overwrites, still one entry"
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testWaitsForAllBranchesBeforeFollowingOutgoing [
	| start split a b join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 2
]

{ #category : 'as yet unclassified' }
FBAndJoinBehaviorTest >> testWorksWithThreeBranches [
	| start split a b c join end flow instance |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	c := FBTask named: 'c'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	split --> c --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 3
]
