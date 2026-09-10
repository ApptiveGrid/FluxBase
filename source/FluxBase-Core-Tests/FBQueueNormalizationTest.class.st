"
Queues persisted in an older shape - a raw transition in #pending, a single token under a
suspension - are brought to the current one by FBFlowInstance>>normalizePersistedQueues,
which ApptiveGrid's database migration runs once. The old shapes are built by reaching
into the ivars, the only way left to produce them.
"
Class {
	#name : 'FBQueueNormalizationTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBQueueNormalizationTest >> testARawPendingTransitionBecomesAWorkItem [
	| instance transition |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	transition := instance start outgoing first.
	instance executor instVarNamed: #pending put: (OrderedCollection with: transition).

	self assert: instance normalizePersistedQueues.

	self assert: (instance executor pending first isKindOf: FBWorkItem).
	self assert: instance executor pending first transition identicalTo: transition.
	self assert: instance executor pending first token isNil.
	self assert: instance nextTransition identicalTo: transition.
	instance initialValue: 7.
	instance execute.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBQueueNormalizationTest >> testASingleSuspendedTokenBecomesAQueueOfOne [
	| instance node token |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	node := FBTask named: 'waiting'.
	token := FBToken new.
	instance executor instVarNamed: 'suspendedTokens' put: (IdentityDictionary new at: node put: token; yourself).

	self assert: instance normalizePersistedQueues.

	self assert: ((instance executor instVarNamed: 'suspendedTokens') at: node) asArray equals: { token }.
	self assert: (instance executor takeTokenForSuspended: node) identicalTo: token.
	self assert: (instance executor takeTokenForSuspended: node) isNil
]

{ #category : 'tests' }
FBQueueNormalizationTest >> testTheExecutorsOfSubFlowInstancesAreNormalizedToo [
	| parent child transition |
	parent := FBFlow simpleFlow newInstance.
	parent initializeExecutor.
	child := FBFlow simpleFlow newInstance.
	child initializeExecutor.
	transition := child start outgoing first.
	child executor instVarNamed: #pending put: (OrderedCollection with: transition).
	parent subFlowInstances add: child.

	self assert: parent normalizePersistedQueues.

	self assert: (child executor pending first isKindOf: FBWorkItem).
	self assert: child executor pending first transition identicalTo: transition
]

{ #category : 'tests' }
FBQueueNormalizationTest >> testAnUpToDateInstanceIsLeftAlone [
	| instance before |
	instance := FBFlow simpleWaitFlow newInstance.
	instance executeWith: 4.
	self assert: instance state equals: #waiting.
	before := instance executor pending copy.

	self deny: instance normalizePersistedQueues.

	self assert: instance executor pending asArray equals: before asArray.
	self deny: FBFlow simpleFlow newInstance normalizePersistedQueues
]
