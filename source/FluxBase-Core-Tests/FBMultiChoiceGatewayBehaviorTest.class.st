Class {
	#name : 'FBMultiChoiceGatewayBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBMultiChoiceGatewayBehaviorTest >> testConditionEvaluationGoesThroughActivationHook [
	"See FBExclusiveGatewayBehaviorTest>>testConditionEvaluationGoesThroughActivationHook --
	same regression, same fix, MultiChoice variant."
	| start gateway a b end flow instance |
	FBRecordingTransitionActivation reset.
	FBFlow activationClass: FBRecordingTransitionActivation.
	[ start := FBStartEvent new.
	gateway := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	start --> gateway.
	gateway --> (a when: [ :x | x > 0 ]) --> end.
	gateway --> (b when: [ :x | x < 10 ]) --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.
	self assert: instance atEnd.
	self assert: (FBRecordingTransitionActivation recorded includes: (gateway outgoing detect: [ :t | t target = a ])).
	self assert: (FBRecordingTransitionActivation recorded includes: (gateway outgoing detect: [ :t | t target = b ])) ]
		ensure: [ FBFlow activationClass: FBActivation ]
]

{ #category : 'tests' }
FBMultiChoiceGatewayBehaviorTest >> testAllMatchingTransitionsAreFollowed [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 0 ]) --> end.
	gateway --> (b when: [ :x | x < 10 ]) --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = a ]).
	self assert: (instance activations anySatisfy: [ :each | each node = b ])
]

{ #category : 'tests' }
FBMultiChoiceGatewayBehaviorTest >> testNoMatchingTransitionSilentlyStops [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBMultiChoiceGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 100 ]) --> end.
	gateway --> (b when: [ :x | x > 200 ]) --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self deny: (instance activations anySatisfy: [ :each | each node = a ]).
	self deny: (instance activations anySatisfy: [ :each | each node = b ])
]
