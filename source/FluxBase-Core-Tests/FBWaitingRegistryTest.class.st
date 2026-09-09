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

{ #category : 'private' }
FBWaitingRegistryTest >> flowWaitingForeverFromOutside [
	"like #flowWaitingForever, but the wait answers FBNode>>isExternallyResumable - so the
	engine registers it and the entry has to carry the parked activation's own token"
	| start wait |
	start := FBStartEvent new.
	wait := start addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	wait addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBWaitingRegistryTest >> flowWithExternalTrigger [
	"a flow shaped start -> trigger-requiring, externally reachable task -> end. The
	transition into the task is what parks, so its waiting spot is transition-shaped"
	| start trigger |
	start := FBStartEvent new.
	trigger := start addOutgoingNode: (FBTriggerTask named: 'trigger').
	trigger addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBWaitingRegistryTest >> flowWithTwoExternalTriggersInSequence [
	"start -> two trigger-requiring, externally reachable tasks in a row -> end. Shaped
	like a two-page form: resuming the first opens the waiting spot of the second"
	| start first second |
	start := FBStartEvent new.
	first := start addOutgoingNode: (FBTriggerTask named: 'page 1').
	second := first addOutgoingNode: (FBTriggerTask named: 'page 2').
	second addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBWaitingRegistryTest >> linkNodeReservingAt: aNode into: aCollection [
	"a task standing in for ApptiveGrid's link node: it hands out an address for the wait
	that will be at aNode on its own strand, ahead of that wait, and keeps it in
	aCollection - the way the real one would put it into a mail"
	^ (FBPluggableTask named: 'link') block: [ :act |
		aCollection add: (act flowInstance reserveWaitingSpotAt: aNode anchoredAt: act token).
		act value: act argument ]
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testANodeAddressedResumeDropsTheEntryOfItsSuspension [
	"a wait continued by node rather than by its address is over all the same, and its
	address has to go with it - otherwise #openWaitingEntries would report a wait that is
	not there and the entry would sit in the persisted instance for good. The dropping is
	the resume's own step, FBBaseExecutor>>resume:withToken:value:, so that every way of
	continuing clears it and no caller has to know. A reservation at the same node is not
	the suspension's address and stands: it names a wait that may still come"
	| instance wait entry reservation |
	instance := self flowWaitingForeverFromOutside newInstance.
	instance executeWith: 1.
	wait := instance suspended first.
	entry := instance openWaitingEntries first.
	reservation := instance reserveWaitingSpotAt: wait anchoredAt: FBToken new.

	instance resumeWaitingAt: wait with: 7.

	self assert: (instance waitingEntryFor: entry correlationId) isNil.
	self assert: (instance waitingEntryFor: reservation correlationId) identicalTo: reservation.
	self deny: (instance signal: entry correlationId with: 8)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testAReservationOfAFinishedInstanceIsNotOpen [
	"a link node reserved an address for a node the flow then never reached - a condition
	ahead of the form did not hold, or, as here, the node is simply not on the way. The
	instance finishes with the reservation still in its registry, because nothing in
	FluxBase runs at the moment an instance ends. What has to hold all the same: nothing
	is reported open, a signal on the dead address is without effect, and a run that
	ended answers no opened waiting spots even though one was reserved on the way"
	| start link never flow instance handedOut |
	handedOut := OrderedCollection new.
	never := FBTriggerTask named: 'never reached'.
	start := FBStartEvent new.
	link := self linkNodeReservingAt: never into: handedOut.
	start --> link --> FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.

	self assert: (instance waitingSpotsOpenedDuring: [ instance executeWith: 1 ]) isEmpty.

	self assert: instance state equals: #done.
	self assert: handedOut size equals: 1.
	"the address exists, but nothing is open"
	self assert: instance waitingRegistry entries asArray equals: handedOut asArray.
	self assert: (instance waitingEntryFor: handedOut first correlationId) identicalTo: handedOut first.
	self assert: instance openWaitingEntries isEmpty.
	self deny: (instance signal: handedOut first correlationId with: 7)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testAReservationReachesAWaitInsideASubFlow [
	"a reservation handed out in the outer instance for a trigger inside a local sub flow
	is the one address of that wait: the child's first token descends from the caller's
	(FBFlowInstance>>descendFrom:), so the wait sees the reservation when it parks and
	mints nothing of its own, and the signal resolves through the outer instance - the
	one an outward address names.

	Until 2026-09-09 this test pinned the opposite: the token chain stopped at the sub
	flow boundary, the child registered a second address, and only that one worked"
	| inner start trigger outerLink flow instance handedOut child |
	handedOut := OrderedCollection new.
	trigger := FBTriggerTask named: 'trigger'.
	inner := FBFlow new start: (FBStartEvent new addOutgoingNode: trigger; yourself).
	trigger addOutgoingNode: FBEndEvent new.
	start := FBStartEvent new.
	outerLink := self linkNodeReservingAt: trigger into: handedOut.
	start --> outerLink.
	(outerLink addOutgoingNode: FBSubFlowNode new) subFlow: inner; addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	child := instance subFlowInstances first.
	self assert: handedOut size equals: 1.
	self assert: instance suspended first waitingNode identicalTo: trigger.
	"one wait, one address: the reservation, and nothing registered by the child"
	self assert: instance openWaitingEntries asArray equals: handedOut asArray.
	self assert: child waitingRegistry entries isEmpty.
	"the child's strand really descends from the caller's"
	self assert: (child activations first token
		hasAncestor: (instance activations detect: [ :each | each node == outerLink ]) token).
	"and the reservation resolves through the outer instance, then the flow runs to its end"
	self assert: (instance signal: handedOut first correlationId with: 7).
	instance execute.
	self assert: (child activations detect: [ :each | each node == trigger ]) argument equals: 7.
	self assert: instance state equals: #done.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testAReservationResolvesToTheWaitThatParksAfterIt [
	"the mail case: the address exists before the wait does. A link node hands it out, the
	flow runs on and parks at the trigger, and the address - handed out when nothing was
	waiting - resolves to exactly that wait. The wait minted no second address of its own,
	because the reservation already stood for it"
	| start trigger link flow instance handedOut |
	handedOut := OrderedCollection new.
	start := FBStartEvent new.
	trigger := FBTriggerTask named: 'trigger'.
	link := self linkNodeReservingAt: trigger into: handedOut.
	start --> link --> trigger --> FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: handedOut size equals: 1.
	self assert: instance state equals: #waiting.
	"one wait, one address - the reservation, not a registration next to it"
	self assert: instance openWaitingEntries asArray equals: handedOut asArray.
	self assert: handedOut first waitingNode identicalTo: trigger.

	self assert: (instance signal: handedOut first correlationId with: 7).
	instance execute.

	self assert: (instance activations detect: [ :each | each node == trigger ]) argument equals: 7.
	self assert: instance openWaitingEntries isEmpty.
	self assert: instance state equals: #done.
	self deny: (instance signal: handedOut first correlationId with: 99)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testASignalBeforeTheReservedWaitParksIsSilentAndKeepsTheReservation [
	"a click on the mail link before the flow has reached the form. Nothing resumes, and
	the address is NOT spent - unlike a plain entry, which names a wait that is over the
	moment it cannot be found. The reservation stands for a wait that may still come,
	and once it does, the same address resolves"
	| start link wait trigger flow instance handedOut |
	handedOut := OrderedCollection new.
	start := FBStartEvent new.
	trigger := FBTriggerTask named: 'trigger'.
	link := self linkNodeReservingAt: trigger into: handedOut.
	wait := FBPluggableWait new condition: [ :each | false ]; yourself.
	start --> link --> wait --> trigger --> FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	"parked at the condition wait, the trigger not reached yet"
	self assert: instance suspended asArray equals: { wait }.
	self deny: (instance signal: handedOut first correlationId with: 7).
	self assert: (instance waitingEntryFor: handedOut first correlationId) identicalTo: handedOut first.
	self assert: instance suspended asArray equals: { wait }.

	"the flow gets there later, and the address that was handed out early is the one"
	instance resumeWaitingAt: wait with: 1.
	instance execute.
	self assert: instance suspended first waitingNode identicalTo: trigger.
	self assert: (instance signal: handedOut first correlationId with: 7).
	instance execute.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testASuspensionWithoutRegistrationHasNoEntry [
	"the registry is a selection out of #suspended and not a mirror of it: this condition
	wait has no waker outside the image, answers FBNode>>isExternallyResumable with false,
	and therefore gets no entry even though the engine now registers on its own. Being
	reachable stays something the node asks for - FBExternalWait is the counterpart"
	| instance |
	instance := self waitingInstance.

	self assert: instance suspended size equals: 1.
	self assert: instance openWaitingEntries isEmpty
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testAnExternallyResumableConditionWaitRegistersWithItsToken [
	"the condition wait hands its token to the suspension now, so its entry carries the
	parked strand rather than nil. That was the condition under which the token could be
	kept on FBToken at all (see the #waiting rebuild of 2026-09-04): an entry without a
	token produces, on the day something resumes it by minting a fresh activation, an
	activation with no #splitId and a join behind it that never releases"
	| instance wait entry |
	instance := self flowWaitingForeverFromOutside newInstance.
	instance executeWith: 1.
	wait := instance suspended first.

	self assert: instance openWaitingEntries size equals: 1.
	entry := instance openWaitingEntries first.

	self assert: entry suspension identicalTo: wait.
	self assert: entry token identicalTo: (self tokenWaitingAt: wait in: instance).
	self assert: entry token notNil
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testAnExternallyResumableTriggerRegistersItsTransition [
	"a trigger-requiring node parks the transition into it, not itself - so the entry's
	suspension is that transition, and its token is the one the target would have been
	activated with. The waiting node is reached through FBTransition>>waitingNode, which
	is also what was asked to decide whether to register at all"
	| instance entry holder |
	instance := self flowWithExternalTrigger newInstance.
	instance executeWith: 1.

	self assert: instance suspended size equals: 1.
	self assert: instance openWaitingEntries size equals: 1.
	entry := instance openWaitingEntries first.

	self assert: entry suspension identicalTo: instance suspended first.
	self assert: entry suspension waitingNode name equals: 'trigger'.
	self assert: entry token notNil.
	"the same token the executor kept alongside the suspension"
	holder := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	self assert: (holder takeTokenForSuspended: entry suspension) identicalTo: entry token.
	"and the target really was not activated"
	self deny: (instance activations anySatisfy: [ :each | each node == entry suspension target ])
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
FBWaitingRegistryTest >> testReservationsInAParallelScopeEachResolveToTheirOwnIteration [
	"the case the reservation exists for. A link node inside a parallel scope runs once per
	iteration and reserves once per iteration; the trigger behind it parks the very same
	transition object once per iteration, so #suspended cannot tell the two waits apart -
	only their tokens can. Signalling the second reservation has to resume the second
	iteration's wait and leave the first iteration its own token.

	This is what a node-based address can never do: both iterations wait at the same node"
	| start fork trigger link flow instance handedOut executor transition remaining |
	handedOut := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	trigger := FBTriggerTask named: 'trigger'.
	link := fork addOutgoingNode: (self linkNodeReservingAt: trigger into: handedOut).
	link --> trigger --> FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	"two iterations, two reservations, and both waits are on one and the same transition"
	self assert: handedOut size equals: 2.
	self deny: handedOut first correlationId equals: handedOut second correlationId.
	executor := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	self assert: executor suspended size equals: 2.
	self assert: executor suspended first == executor suspended second.
	transition := executor suspended first.
	"and the reservations are the only addresses - no registration was minted next to them"
	self assert: instance openWaitingEntries size equals: 2.

	self assert: (instance signal: handedOut second correlationId with: 'B').

	"the second iteration's wait went on, under the token descending from its own link"
	self assert: ((instance activations detect: [ :each | each node == trigger ]) token
		hasAncestor: handedOut second anchorToken).
	"the first iteration still waits, and the token left in the queue is ITS token"
	self assert: executor suspended size equals: 1.
	remaining := executor takeTokenForSuspended: transition.
	self assert: (remaining hasAncestor: handedOut first anchorToken).
	self deny: (remaining hasAncestor: handedOut second anchorToken).
	self assert: instance openWaitingEntries asArray equals: { handedOut first }
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testResumingATransitionWithoutNamingATokenGoesOnWithTheParkedOne [
	"#resume:withToken:value: with a nil token means 'whichever token the suspension
	parked with' - and that one has to be the token the continuation goes on with, not
	merely the one taken off the queue. The same split-and-join as
	#testSignalBehindASplitCompletesTheJoin, continued without naming the token: were the
	taken token dropped, the trigger's fresh activation would carry a default token with
	no #splitId, and the join would hold the two arrivals apart for good"
	| start split trigger other join end flow instance holder transition |
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
	self assert: instance suspended asArray equals: { trigger incoming first }.
	transition := instance suspended first.
	holder := instance activeExecutors detect: [ :each | each suspended notEmpty ].

	holder resume: transition withToken: nil value: 7.
	instance execute.

	self assert: (instance activations detect: [ :each | each node == trigger ]) argument equals: 7.
	self assert: (instance activations anySatisfy: [ :each | each node == end ]).
	self assert: instance state equals: #done.
	self assert: (holder takeTokenForSuspended: transition) isNil
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testResumingClearsTheTokenKeptForTheSuspension [
	"resuming takes the token out of the executor's bookkeeping as well, so nothing is
	left behind for a suspension that is over. Only measurable since the condition wait
	stores a token at all - see #testAnExternallyResumableConditionWaitRegistersWithItsToken
	for that it is there beforehand; asking here would consume it and prove nothing"
	| instance wait holder |
	instance := self flowWaitingForeverFromOutside newInstance.
	instance executeWith: 1.
	wait := instance suspended first.
	holder := instance activeExecutors detect: [ :each | each suspended notEmpty ].

	instance resumeWaitingAt: wait with: 7.

	self assert: (holder takeTokenForSuspended: wait) isNil.
	self assert: (holder instVarNamed: 'suspendedTokens') isEmpty
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
FBWaitingRegistryTest >> testSignalReachesAWaitTheEngineRegistered [
	"the whole way through, with nothing registered by hand: the wait makes itself
	reachable, the address is read off the instance, and signalling it runs the flow to
	its end. Until the engine registered, #signal:with: was only reachable from a test
	that had built its own entry"
	| instance entry |
	instance := self flowWithExternalTrigger newInstance.
	instance executeWith: 1.

	self assert: instance openWaitingEntries size equals: 1.
	entry := instance openWaitingEntries first.

	self assert: (instance signal: entry correlationId with: 7).
	instance execute.

	self assert: (instance activations
		detect: [ :each | each node == entry suspension target ]) argument equals: 7.
	self assert: (instance activations anySatisfy: [ :each | each node isKindOf: FBEndEvent ]).
	self assert: instance state equals: #done.
	"and the address is spent - a second delivery of the same impulse does nothing"
	self deny: (instance signal: entry correlationId with: 99).
	self assert: instance openWaitingEntries isEmpty
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

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingSpotsOpenedAnswersBothHalvesOfASplit [
	"a collection and not a single value: an AND split into two trigger-requiring nodes
	leaves two waiting spots, and a caller that builds a link and a schedule per spot has
	to see both. This is the case the design note calls out"
	| start split a b join end flow instance opened |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTriggerTask named: 'form a'.
	b := FBTriggerTask named: 'form b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.

	opened := instance waitingSpotsOpenedDuring: [ instance executeWith: 42 ].

	self assert: opened size equals: 2.
	self
		assert: ((opened collect: [ :each | each suspension waitingNode name ]) asSortedCollection asArray)
		equals: #( 'form a' 'form b' ).
	"two spots, two addresses - neither may stand in for the other"
	self deny: opened first correlationId equals: opened second correlationId
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingSpotsOpenedAnswersOneOpenedInsideASubFlow [
	"the case an announcement could not have covered: a wait modelled in a local sub flow
	registers on the child instance, and the child holds no reference back to its caller.
	Read over the chain, it is answered through the outermost instance - which is the one
	a caller runs and the one an outward address names"
	| instance opened child |
	instance := (self flowCalling: self flowWithExternalTrigger) newInstance.

	opened := instance waitingSpotsOpenedDuring: [ instance executeWith: 1 ].

	self assert: opened size equals: 1.
	child := instance subFlowInstances first.
	"it really lives on the child, not on the instance that was run"
	self assert: child waitingRegistry entries asArray equals: opened asArray.
	self assert: instance waitingRegistry entries isEmpty.
	"and is signalable through the outer instance"
	self assert: (instance signal: opened first correlationId with: 7)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingSpotsOpenedAnswersOnlyTheNewOneOnResume [
	"the assertion the difference exists for. A submit consumes one waiting spot and opens
	the next one in the same run - every page of a multi-page form does this - and only
	the new one may be answered. A list kept along the way would have to be cleared at
	just the right moment to get this right; a difference is right by construction"
	| instance first second |
	instance := self flowWithTwoExternalTriggersInSequence newInstance.
	first := (instance waitingSpotsOpenedDuring: [ instance executeWith: 1 ]) first.
	self assert: first suspension waitingNode name equals: 'page 1'.

	second := instance waitingSpotsOpenedDuring: [
		instance signal: first correlationId with: 'PAGE-ONE'.
		instance execute ].

	self assert: second size equals: 1.
	self assert: second first suspension waitingNode name equals: 'page 2'.
	self deny: second first correlationId equals: first correlationId.
	"the consumed one is gone rather than answered again"
	self assert: instance openWaitingEntries asArray equals: second asArray.
	self assert: (instance waitingEntryFor: first correlationId) isNil
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingSpotsOpenedAnswersTheOneThatOpened [
	"the plain case, and the one that makes a correlationId usable at all: after a run,
	the caller is handed the waiting spot that came into being instead of having to ask
	#openWaitingEntries and work out which of them is new"
	| instance opened |
	instance := self flowWithExternalTrigger newInstance.

	opened := instance waitingSpotsOpenedDuring: [ instance executeWith: 1 ].

	self assert: opened size equals: 1.
	self assert: opened asArray equals: instance openWaitingEntries asArray.
	self assert: opened first suspension identicalTo: instance suspended first.
	self assert: opened first correlationId notNil.
	"and the address really carries - it is what a caller would put into a link"
	self assert: (instance signal: opened first correlationId with: 7)
]

{ #category : 'tests' }
FBWaitingRegistryTest >> testWaitingSpotsOpenedIgnoresAWaitNotReachableFromOutside [
	"a condition wait parks but has no waker outside the image, so it registers nothing and
	is not answered either. The answer is about addresses handed out, not about what blocks
	the instance - #suspended is the reader for that"
	| instance opened |
	instance := self flowWaitingForever newInstance.

	opened := instance waitingSpotsOpenedDuring: [ instance executeWith: 1 ].

	self assert: opened isEmpty.
	"the wait is real all the same"
	self assert: instance state equals: #waiting.
	self assert: instance suspended size equals: 1
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
