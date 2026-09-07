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
	ever naming a cause. See FBFlowInstance>>waitingRegistry"
	| instance |
	instance := self waitingInstance.

	instance waitingRegistry.
	instance openWaitingEntries.
	instance waitingEntryFor: 'never registered'.
	instance takeWaitingEntryFor: 'never registered'.

	self assert: (instance instVarNamed: 'waitingRegistry') isNil
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testSignalBehindASplitCompletesTheJoin [
	"the branch identity has to survive an impulse from outside. A trigger-requiring node
	has no activation while the transition into it is parked, so #signal:with: mints one -
	and it has to carry the token the registry entry holds. Without it the fresh
	activation's default token has no #splitId, the join behind it opens a second
	FBJoinState, each of the two holds one arrival, neither reaches its #expected of two -
	and the instance reports #done with everything behind the join left undone. Reaching
	the end node is therefore what discriminates here; #atEnd and #state do not.

	The counterpart of FBWaitForConditionBehaviorTest>>
	testResumingAConditionWaitBehindASplitCompletesTheJoin, which measures the other kind
	of waiting spot - the one whose activation is still standing while it waits"
	| start split trigger other join end flow instance holder transition token entry |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	trigger := FBTriggerTask named: 'trigger'.
	other := FBTask named: 'other'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> trigger --> join.
	split --> other --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.

	"the scenario only holds if the trigger branch really parks, and parks a transition"
	self assert: instance state equals: #waiting.
	self assert: instance suspended asArray equals: { trigger incoming first }.
	transition := instance suspended first.
	holder := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	"the engine registers no waiting spot yet, so the entry is made here - with the very
	token the waiting spot laid down for its suspension"
	token := holder takeTokenForSuspended: transition.
	self assert: token notNil.
	entry := instance registerWaitingToken: token suspendedAt: transition.

	self assert: (instance signal: entry correlationId with: 7).
	instance execute.

	"the trigger got an activation of its own, carrying the impulse as its input"
	self assert: (instance activations
		detect: [ :each | each node == trigger ]) argument equals: 7.
	"both branches arrive at the join either way, so this is the scenario check rather
	than the assertion that discriminates"
	self assert: (instance activations select: [ :each | each node == join ]) size equals: 2.
	"reaching #end is what discriminates: with the branch identity lost the join keeps the
	two arrivals apart and releases neither, while #state still reports #done"
	self assert: (instance activations anySatisfy: [ :each | each node == end ]).
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testSignalResumesWaitingToken [
	"the impulse reaches the waiting spot its correlationId names and the flow runs on.
	A condition wait was activated and parked inside its own execution, so its activation
	is still standing: the impulse becomes that activation's value rather than the input
	of a fresh one, and no second activation of the wait node appears.

	#signal:with: itself only moves the waiting spot on - stepping the flow afterwards is
	the caller's, which is why #execute follows here"
	| instance wait entry |
	instance := self waitingInstance.
	wait := instance suspended first.
	entry := instance
		registerWaitingToken: (self tokenWaitingAt: wait in: instance)
		suspendedAt: wait.

	self assert: (instance signal: entry correlationId with: 7).
	instance execute.

	self assert: (instance activations select: [ :each | each node == wait ]) size equals: 1.
	self assert: (instance activations detect: [ :each | each node == wait ]) value equals: 7.
	"the suspension is gone, the entry with it, and the flow reached its end"
	self assert: instance suspended isEmpty.
	self assert: instance openWaitingEntries isEmpty.
	self assert: (instance activations anySatisfy: [ :each | each node isKindOf: FBEndEvent ]).
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testSignalWithConsumedCorrelationIdIsSilent [
	"a second impulse under the same address is without effect and without error - the
	guarantee a double submit, a redelivery out of the event log and a schedule firing at
	a wait that is already gone all rest on. The first signal consumed the entry, so the
	second finds nothing, and finding nothing is the answer"
	| instance wait entry activationsAfterFirst |
	instance := self waitingInstance.
	wait := instance suspended first.
	entry := instance
		registerWaitingToken: (self tokenWaitingAt: wait in: instance)
		suspendedAt: wait.
	self assert: (instance signal: entry correlationId with: 7).
	instance execute.
	activationsAfterFirst := instance activations size.

	self deny: (instance signal: entry correlationId with: 99).

	self assert: instance activations size equals: activationsAfterFirst.
	self assert: (instance activations detect: [ :each | each node == wait ]) value equals: 7.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testSignalWithUnknownCorrelationIdIsSilent [
	"an address that was never handed out is without effect and without error. Measured
	on an instance that really has an open waiting spot, so that answering false is a
	miss and not an empty registry - and that waiting spot must be left standing rather
	than resumed by whatever impulse happens to arrive"
	| instance wait entry |
	instance := self waitingInstance.
	wait := instance suspended first.
	entry := instance
		registerWaitingToken: (self tokenWaitingAt: wait in: instance)
		suspendedAt: wait.

	self deny: (instance signal: 'never handed out' with: 7).

	self assert: (instance suspended includes: wait).
	self assert: instance openWaitingEntries asArray equals: { entry }.
	self assert: instance state equals: #waiting.
	self deny: (instance activations anySatisfy: [ :each | each node isKindOf: FBEndEvent ])
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
	self assert: child waitingRegistry entries asArray equals: { entry }.
	self assert: instance waitingRegistry entries isEmpty.
	"and is reachable through the outer instance all the same"
	self assert: (instance waitingEntryFor: entry correlationId) identicalTo: entry.
	self assert: instance openWaitingEntries asArray equals: { entry }.
	self assert: (instance takeWaitingEntryFor: entry correlationId) identicalTo: entry.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingRegistryEntryIsRemovedOnResume [
	"the removal measured on its own, without a resume around it: #takeWaitingEntryFor:
	answers the entry and forgets it. Taking it a second time is the guarantee a double
	submit rests on - the second attempt finds nothing, and that is the answer rather than
	an error. #signal:with: rests on exactly this, see
	#testSignalWithConsumedCorrelationIdIsSilent"
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
