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
