Class {
	#name : 'FBAndJoinBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

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
FBAndJoinBehaviorTest >> testDuplicateArrivalOfTheSameBranchIdIsNotCountedTwice [
	| start split a b join end flow instance duplicateActivation joinState splitIdUsed branchIdUsed |
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
	splitIdUsed := (instance activationOfNode: a) token splitId.
	branchIdUsed := (instance activationOfNode: a) token branchId.
	self deny: (instance activations anySatisfy: [ :act | act node = end ]).
	duplicateActivation := FBActivation new
		executor: instance executor;
		node: join;
		argument: 99;
		yourself.
	duplicateActivation token splitId: splitIdUsed; branchId: branchIdUsed.
	(join defaultBehaviorClass new activation: duplicateActivation; yourself) execute.
	joinState := instance joinStateFor: join splitId: splitIdUsed.
	self assert: joinState arrived size equals: 1.
	self deny: (instance activations anySatisfy: [ :act | act node = end ])
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
