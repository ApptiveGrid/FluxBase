Class {
	#name : 'FBExclusiveGatewayBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBExclusiveGatewayBehaviorTest >> testConditionEvaluationGoesThroughActivationHook [
	"Characterization test: the gateway must ask the ACTIVATION whether a
	transition matches (#transitionMatches:), not evaluate the condition
	itself -- this is the hook AGFlowActivation (ApptiveBase-Core) overrides
	to set up the ApptiveScript scope a condition like 'source.input'
	needs. Regression test for a bug where FBExclusiveGatewayBehavior/
	FBMultiChoiceGatewayBehavior called #conditionMatches: directly,
	silently bypassing that hook."
	| start gateway a b end flow instance |
	FBRecordingTransitionActivation reset.
	FBFlow activationClass: FBRecordingTransitionActivation.
	[ start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	start --> gateway.
	gateway --> (a when: [ :x | x >= 5 ]) --> end.
	gateway --> (b when: [ :x | x < 5 ]) --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.
	self assert: instance atEnd.
	self assert: (FBRecordingTransitionActivation recorded includes: (gateway outgoing detect: [ :t | t target = a ])).
	self assert: (FBRecordingTransitionActivation recorded includes: (gateway outgoing detect: [ :t | t target = b ])) ]
		ensure: [ FBFlow activationClass: FBActivation ]
]

{ #category : 'tests' }
FBExclusiveGatewayBehaviorTest >> testExactlyOneMatchFollowsThatTransition [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x >= 5 ]) --> end.
	gateway --> (b when: [ :x | x < 5 ]) --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = a ]).
	self deny: (instance activations anySatisfy: [ :each | each node = b ])
]

{ #category : 'tests' }
FBExclusiveGatewayBehaviorTest >> testFallsBackToDefaultTransitionWhenNoConditionMatches [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'default'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 100 ]) --> end.
	gateway --> b --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: (instance activations anySatisfy: [ :each | each node = b ]).
	self deny: (instance activations anySatisfy: [ :each | each node = a ])
]

{ #category : 'tests' }
FBExclusiveGatewayBehaviorTest >> testMultipleMatchesError [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 0 ]) --> end.
	gateway --> (b when: [ :x | x < 10 ]) --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance state equals: #error.
	self assert: instance activations last state equals: #error
]

{ #category : 'tests' }
FBExclusiveGatewayBehaviorTest >> testNoMatchWithoutDefaultErrors [
	| start gateway a b end flow instance |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 10 ]) --> end.
	gateway --> (b when: [ :x | x > 20 ]) --> end.

	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 7.

	self assert: instance state equals: #error.
	self assert: instance activations last state equals: #error
]
