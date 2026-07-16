Class {
	#name : 'FBOrJoinBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBOrJoinBehaviorTest >> testAggregatesOnlyTheActuallyStartedBranchesValues [
	| start choice a b join end flow instance completingActivation joinValue |
	start := FBStartEvent new.
	choice := FBMultiChoiceGateway named: 'choice'.
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBOrJoin named: 'join'.
	end := FBEndEvent new.
	start --> choice.
	choice --> (a when: [ :x | x > 100 ]) --> join.
	choice --> (b when: [ :x | x < 10 ]) --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	completingActivation := (instance activations select: [ :act | act node = join ]) last.
	joinValue := completingActivation value.
	self assert: joinValue size equals: 1.
	self assert: (joinValue at: b) equals: 50.
	self deny: (joinValue includesKey: a)
]

{ #category : 'as yet unclassified' }
FBOrJoinBehaviorTest >> testWaitsForAllBranchesWhenAllConditionsAreTrue [
	| start choice a b join end flow instance |
	start := FBStartEvent new.
	choice := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBOrJoin named: 'join'.
	end := FBEndEvent new.
	start --> choice.
	choice --> (a when: [ :x | x > 0 ]) --> join.
	choice --> (b when: [ :x | x < 10 ]) --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 2
]

{ #category : 'as yet unclassified' }
FBOrJoinBehaviorTest >> testWaitsOnlyForActuallyStartedBranchesNotAllModelledOnes [
	| start choice a b join end flow instance |
	start := FBStartEvent new.
	choice := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBOrJoin named: 'join'.
	end := FBEndEvent new.
	start --> choice.
	choice --> (a when: [ :x | x > 100 ]) --> join.
	choice --> (b when: [ :x | x < 10 ]) --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 1
]

{ #category : 'as yet unclassified' }
FBOrJoinBehaviorTest >> testWorksWithPartialSubsetOfThreeBranches [
	| start choice a b c join end flow instance |
	start := FBStartEvent new.
	choice := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	c := FBTask named: 'c'.
	join := FBOrJoin named: 'join'.
	end := FBEndEvent new.
	start --> choice.
	choice --> (a when: [ :x | x > 0 ]) --> join.
	choice --> (b when: [ :x | x < 10 ]) --> join.
	choice --> (c when: [ :x | x > 100 ]) --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 5.
	self assert: instance atEnd.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1.
	self assert: (instance activations select: [ :act | act node = join ]) size equals: 2
]
