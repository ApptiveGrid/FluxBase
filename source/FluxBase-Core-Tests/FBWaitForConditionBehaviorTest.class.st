Class {
	#name : 'FBWaitForConditionBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testConditionTrueFollowsOutgoing [
	| flow instance |
	flow := FBFlow simpleWaitFlow.
	instance := flow newInstance.
	instance executeWith: 5.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: instance suspended isEmpty
]

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testSuspendedContainsTheWaitNodeNotTheBehavior [
	| flow waitNode instance |
	flow := FBFlow simpleWaitFlow.
	waitNode := flow start outgoing first target.
	instance := flow newInstance.
	instance executeWith: 4.

	self deny: instance atEnd.
	self assert: instance state equals: #waiting.
	self assert: instance suspended size equals: 1.
	self assert: instance suspended first equals: waitNode.
	self deny: (instance suspended first isKindOf: FBNodeBehavior)
]
