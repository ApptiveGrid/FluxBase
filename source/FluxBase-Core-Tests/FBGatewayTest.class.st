Class {
	#name : 'FBGatewayTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBGatewayTest >> testGatewayIsAbstractOnlyForTheBaseClass [
	self assert: FBGateway isAbstract.
	self deny: FBExclusiveGateway isAbstract
]

{ #category : 'tests' }
FBGatewayTest >> testAddOutgoingNodeWithConditionAttachesAConditionedTransition [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway addOutgoingNode: a withCondition: [ :x | x >= 5 ].
	gateway addOutgoingNode: b withCondition: [ :x | x < 5 ].
	a --> end.
	b --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: (instance activations anySatisfy: [ :each | each node = a ]).
	self deny: (instance activations anySatisfy: [ :each | each node = b ])
]
