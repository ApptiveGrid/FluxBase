Class {
	#name : 'FBSimpleMergeBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBSimpleMergeBehaviorTest >> testTheOtherExclusiveBranchAlsoContinuesImmediately [
	| start choice a b merge end flow instance |
	start := FBStartEvent new.
	choice := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	merge := FBSimpleMerge named: 'merge'.
	end := FBEndEvent new.

	start --> choice.
	choice --> (a when: [ :x | x >= 5 ]) --> merge.
	choice --> (b when: [ :x | x < 5 ]) --> merge.
	merge --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 3.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self deny: (instance activations anySatisfy: [ :each | each node = a ]).
	self assert: (instance activations anySatisfy: [ :each | each node = b ]).
	self assert: (instance activations anySatisfy: [ :each | each node = merge ])
]

{ #category : 'tests' }
FBSimpleMergeBehaviorTest >> testWhicheverExclusiveBranchArrivesContinuesImmediately [
	| start choice a b merge end flow instance |
	start := FBStartEvent new.
	choice := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	merge := FBSimpleMerge named: 'merge'.
	end := FBEndEvent new.

	start --> choice.
	choice --> (a when: [ :x | x >= 5 ]) --> merge.
	choice --> (b when: [ :x | x < 5 ]) --> merge.
	merge --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = a ]).
	self deny: (instance activations anySatisfy: [ :each | each node = b ]).
	self assert: (instance activations anySatisfy: [ :each | each node = merge ]).
	self assert: (instance activations anySatisfy: [ :each | each node = end ])
]
