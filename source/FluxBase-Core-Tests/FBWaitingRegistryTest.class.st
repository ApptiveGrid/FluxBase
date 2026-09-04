Class {
	#name : 'FBWaitingRegistryTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'private' }
FBWaitingRegistryTest >> flowCalling: aFlow [
	"a parent flow shaped start -> sub flow node calling aFlow -> end"
	| start subNode |
	start := FBStartEvent new.
	subNode := start addOutgoingNode: FBSubFlowNode new.
	subNode subFlow: aFlow.
	subNode addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBWaitingRegistryTest >> flowWaitingForever [
	"a flow shaped start -> wait that never becomes true -> end"
	| start wait |
	start := FBStartEvent new.
	wait := start addOutgoingNode: (FBPluggableWait new condition: [ :each | false ]; yourself).
	wait addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testASuspensionWithoutRegistrationHasNoEntry [
	"the registry is a selection out of #suspended and not a mirror of it: a condition
	wait has no waker outside the image and gets no entry unless one is asked for"
	| instance |
	instance := self waitingInstance.

	self assert: instance suspended size equals: 1.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testEachRegistrationOfOneSuspendedObjectGetsItsOwnCorrelationId [
	"#suspended takes duplicates and cannot tell two suspensions of the same object
	apart - which is why node identity is too coarse to serve as an address. Giving each
	one an identity of its own is what the registry adds, so two registrations of the
	same object must not collide, and consuming one must leave the other"
	| instance wait token first second |
	instance := self waitingInstance.
	wait := instance suspended first.
	token := self tokenWaitingAt: wait in: instance.

	first := instance registerWaitingToken: token suspendedAt: wait.
	second := instance registerWaitingToken: token suspendedAt: wait.

	self deny: first correlationId equals: second correlationId.
	self assert: (instance waitingEntryFor: first correlationId) identicalTo: first.
	self assert: (instance waitingEntryFor: second correlationId) identicalTo: second.

	instance takeWaitingEntryFor: first correlationId.
	self assert: (instance waitingEntryFor: first correlationId) isNil.
	self assert: (instance waitingEntryFor: second correlationId) identicalTo: second
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testReadingTheRegistryDoesNotCreateOne [
	"a getter that creates and assigns turns a read into a write. That marks the instance
	dirty, and on an instance materialized in a read-only transaction it signals
	SoilWriteOnReadOnlyTransaction - the failure that left a Zinc worker hanging without
	ever naming a cause. See FBFlowInstance>>ownWaitingRegistry"
	| instance |
	instance := self waitingInstance.

	instance ownWaitingRegistry.
	instance openWaitingEntries.
	instance waitingEntryFor: 'never registered'.
	instance takeWaitingEntryFor: 'never registered'.

	self assert: (instance instVarNamed: 'waitingRegistry') isNil
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingEntryInsideASubFlowIsFoundThroughTheOuterInstance [
	"a wait inside a sub flow is registered on the child instance, where its suspension
	is: the child holds no reference back to its caller. Resolving therefore walks the
	chain of active instances, so that the outermost instance - the one an outward
	address names - can answer for it. The same two-level split #suspended has: stored
	per frame, read across the chain"
	| instance child wait entry |
	instance := (self flowCalling: self flowWaitingForever) newInstance.
	instance executeWith: 1.
	child := instance subFlowInstances first.
	wait := instance suspended first.

	entry := child
		registerWaitingToken: (self tokenWaitingAt: wait in: child)
		suspendedAt: wait.

	"the entry lives on the child, not on the caller"
	self assert: child ownWaitingRegistry entries asArray equals: { entry }.
	self assert: instance ownWaitingRegistry entries isEmpty.
	"and is reachable through the outer instance all the same"
	self assert: (instance waitingEntryFor: entry correlationId) identicalTo: entry.
	self assert: instance openWaitingEntries asArray equals: { entry }.
	self assert: (instance takeWaitingEntryFor: entry correlationId) identicalTo: entry.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingRegistryEntryIsRemovedOnResume [
	"nothing is wired into the resume path yet, so the removal is measured where a resume
	will go through it: #takeWaitingEntryFor: answers the entry and forgets it. Taking it
	a second time is the guarantee a double submit rests on - the second attempt finds
	nothing, and that is the answer rather than an error"
	| instance wait entry |
	instance := self waitingInstance.
	wait := instance suspended first.
	entry := instance
		registerWaitingToken: (self tokenWaitingAt: wait in: instance)
		suspendedAt: wait.

	self assert: (instance takeWaitingEntryFor: entry correlationId) identicalTo: entry.

	self assert: (instance takeWaitingEntryFor: entry correlationId) isNil.
	self assert: (instance waitingEntryFor: entry correlationId) isNil.
	self assert: instance openWaitingEntries isEmpty.
	"the suspension itself is untouched - clearing it is the resume's job, not the registry's"
	self assert: (instance suspended includes: wait)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingRegistryRejectsCorrelationIdFromOtherInstance [
	"the address of a waiting spot resolves through the instance that holds it and nowhere
	else. The routing part of an outward address is useful redundancy and not the truth,
	so pointing it at the wrong instance has to answer nothing rather than resolve to
	whatever happens to wait there. Both instances hold an entry here, so answering nil
	is a real miss and not an empty registry"
	| one other mine theirs |
	one := self waitingInstance.
	other := self waitingInstance.
	mine := one
		registerWaitingToken: (self tokenWaitingAt: one suspended first in: one)
		suspendedAt: one suspended first.
	theirs := other
		registerWaitingToken: (self tokenWaitingAt: other suspended first in: other)
		suspendedAt: other suspended first.

	self deny: mine correlationId equals: theirs correlationId.
	self assert: (other waitingEntryFor: mine correlationId) isNil.
	self assert: (other takeWaitingEntryFor: mine correlationId) isNil.
	"and the wrong instance's attempt left both entries as they were"
	self assert: (one waitingEntryFor: mine correlationId) identicalTo: mine.
	self assert: (other waitingEntryFor: theirs correlationId) identicalTo: theirs
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingRegistryResolvesCorrelationIdToToken [
	| instance wait token entry |
	instance := self waitingInstance.
	wait := instance suspended first.
	token := self tokenWaitingAt: wait in: instance.

	entry := instance registerWaitingToken: token suspendedAt: wait.

	self assert: entry correlationId notNil.
	self assert: (instance waitingEntryFor: entry correlationId) identicalTo: entry.
	self assert: (instance waitingEntryFor: entry correlationId) token identicalTo: token.
	"and the entry names a suspension that is really open"
	self assert: entry suspension identicalTo: wait.
	self assert: (instance suspended includes: entry suspension).
	self assert: instance openWaitingEntries asArray equals: { entry }
]

{ #category : 'private' }
FBWaitingRegistryTest >> tokenWaitingAt: aNode in: anInstance [
	"the token of the activation parked on aNode. A condition wait stores no token for
	its suspension, so the activation standing on the node is where the parked strand is
	to be had - and it is the token the wait would have to hand on"
	^ (anInstance activations detect: [ :each | each node == aNode ]) token
]

{ #category : 'private' }
FBWaitingRegistryTest >> waitingInstance [
	"an instance parked on the single wait of #flowWaitingForever"
	| instance |
	instance := self flowWaitingForever newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	self assert: instance suspended size equals: 1.
	^ instance
]
