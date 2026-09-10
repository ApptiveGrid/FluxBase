"
Cancelling a strand of execution: what falls with it, what stays, and that the instance
stays consistent around it. The state invariants of FBFlowInstanceTest are checked here
as well, at every point a cancellation could have disturbed them.
"
Class {
	#name : 'FBCancellationTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'private' }
FBCancellationTest >> assertConsistent: anInstance [
	| state |
	state := anInstance state.
	self assert: (#( created running waiting done error ) includes: state) description: 'state ', state printString.
	self assert: (state = #done) equals: (anInstance atEnd and: [ anInstance hasErrors not ]).
	self assert: (state = #waiting) equals: anInstance isWaiting.
	anInstance activeExecutors do: [ :each |
		self assert: (each isDone not or: [ each atEnd ]) description: each printString, ' is done but not at its end' ].
	anInstance atEnd ifFalse: [
		self assert: anInstance openWaitingEntries size
			equals: (anInstance activeFlowInstances inject: 0 into: [ :sum :each | sum + each waitingRegistry entries size ]) ]
]

{ #category : 'private' }
FBCancellationTest >> cancelledEventsOf: anInstance [
	^ anInstance events select: [ :each | each isKindOf: FBStrandCancelled ]
]

{ #category : 'private' }
FBCancellationTest >> flowCalling: aFlow [
	"start -> sub flow node calling aFlow -> end"
	| start subNode |
	start := FBStartEvent new.
	subNode := start addOutgoingNode: FBSubFlowNode new.
	subNode subFlow: aFlow.
	subNode addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBCancellationTest >> flowWithExternalTrigger [
	"start -> a trigger-requiring task reachable from outside -> end: the transition
	into the task is what parks"
	| start trigger |
	start := FBStartEvent new.
	trigger := start addOutgoingNode: (FBTriggerTask named: 'trigger').
	trigger addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBCancellationTest >> flowWaitingFromOutside [
	"start -> a condition wait that never holds and can be woken from outside -> end"
	| start wait |
	start := FBStartEvent new.
	wait := start addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	wait addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'private' }
FBCancellationTest >> flowSplittingIntoTwoEnds [
	"start -> split -> a -> end, split -> b -> end: two strands that never join, so a
	cancellation of one cannot be confused with a join waiting for it"
	| start split a b |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: #a ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: #b ].
	split --> a --> FBEndEvent new.
	split --> b --> FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAWaitingStrandTakesItOutOfEverything [
	"a strand parked at a wait that is reachable from outside: the wait falls out of
	#suspended, its address out of the registry, its token reads #cancelled and so does
	the activation standing on it, which stays in the log. Both events are recorded, a
	signal on the old address is silent, and with its only strand gone the instance is
	over"
	| instance wait activation address taken |
	instance := self flowWaitingFromOutside newInstance.
	instance executeWith: 1.
	wait := instance suspended first.
	activation := instance activations detect: [ :each | each node == wait ].
	address := instance openWaitingEntries first.
	self assert: activation state equals: #waiting.
	self assertConsistent: instance.

	taken := instance cancelStrand: activation token.

	self assert: taken asArray equals: { activation token }.
	self assert: activation token isCancelled.
	self assert: activation state equals: #cancelled.
	self assert: instance suspended isEmpty.
	self assert: instance openWaitingEntries isEmpty.
	self deny: (instance signal: address correlationId with: 7).
	self assert: (instance events anySatisfy: [ :each | (each isKindOf: FBNodeActivationCancelled) and: [ each activation == activation ] ]).
	self assert: (self cancelledEventsOf: instance) size equals: 1.
	self assert: (self cancelledEventsOf: instance) first tokenId equals: activation token id.
	self assert: instance atEnd.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAQueuedStrandLeavesItsSiblingRunning [
	"a strand whose work is still queued: its work item falls out of #pending, the
	sibling strand of the same split runs on to its end, and the cancelled node never
	ran"
	| flow a instance queued taken |
	flow := self flowSplittingIntoTwoEnds.
	a := flow nodes detect: [ :each | each name = 'a' ].
	instance := flow newInstance.
	instance initialValue: 1.
	instance step. "start"
	instance step. "split - both branches are queued now"
	self assert: instance pending size equals: 2.
	queued := instance executor pending detect: [ :each | each transition target == a ].
	self assertConsistent: instance.

	taken := instance cancelStrand: queued token.

	self assert: taken asArray equals: { queued token }.
	self assert: queued token isCancelled.
	self assert: instance pending size equals: 1.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self deny: (instance activations anySatisfy: [ :each | each node == a ]).
	self assert: (instance activations anySatisfy: [ :each | each node name = 'b' ]).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAStrandTakesItsDescendantsWithIt [
	"cancelling at the split takes both branches, which descend from the split's token"
	| flow split instance taken |
	flow := self flowSplittingIntoTwoEnds.
	split := flow nodes detect: [ :each | each name = 'split' ].
	instance := flow newInstance.
	instance initialValue: 1.
	instance step.
	instance step.
	self assert: instance pending size equals: 2.

	taken := instance cancelStrand: (instance activations detect: [ :each | each node == split ]) token.

	self assert: taken size equals: 2.
	self assert: (taken allSatisfy: [ :each | each isCancelled ]).
	self assert: instance pending isEmpty.
	self assert: instance atEnd.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAParkedTransitionTakesItsAddressAndLeavesTheParkingStepDone [
	"the transition-shaped wait: a strand parked on its way into a trigger-requiring
	node. The parked token has no activation of its own, so no activation is cancelled -
	the step that parked it is over and reads #done - but the suspension and its
	address fall"
	| instance token parking |
	instance := self flowWithExternalTrigger newInstance.
	instance executeWith: 1.
	token := instance openWaitingEntries first token.
	parking := instance activations detect: [ :each | each node == instance flow start ].
	self assert: instance suspended size equals: 1.

	self assert: (instance cancelStrand: token) asArray equals: { token }.

	self assert: instance suspended isEmpty.
	self assert: instance openWaitingEntries isEmpty.
	self assert: parking state equals: #done.
	self deny: (instance events anySatisfy: [ :each | each isKindOf: FBNodeActivationCancelled ]).
	self assert: (self cancelledEventsOf: instance) size equals: 1.
	self assert: instance atEnd.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingIntoASubFlowTakesTheChildsStrands [
	"the child's strands descend from the caller's token (FBFlowInstance>>descendFrom:),
	so cancelling the calling strand reaches a wait inside the sub flow. The child is
	then over without an end, and until a cancelled scope carries that as its state,
	the frame fails its caller the way an errored child does - the instance stops in
	#error rather than hanging on a frame nothing will pop"
	| child parent instance caller wait |
	child := self flowWaitingFromOutside.
	parent := self flowCalling: child.
	instance := parent newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	caller := instance activations detect: [ :each | each node isKindOf: FBSubFlowNode ].
	wait := instance suspended first.
	self assertConsistent: instance.

	self assert: (instance cancelStrand: caller token) size equals: 1.

	self assert: instance suspended isEmpty.
	self assert: instance subFlowInstances first suspended isEmpty.
	self assert: (instance subFlowInstances first activations detect: [ :each | each node == wait ]) state equals: #cancelled.
	self assert: instance state equals: #error.
	self assert: instance atEnd.
	self assert: (self cancelledEventsOf: instance) size equals: 1.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAWaitingIterationLetsTheParallelScopeGoOn [
	"two iterations of a parallel scope both wait. Cancelling the first one's strand
	leaves the second waiting, and once that is resumed the scope completes - the
	executor moves on after the withdrawal as it would have after a step"
	| start fork wait flow instance first second |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	(wait addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	self assert: instance suspended size equals: 2.
	self assert: instance openWaitingEntries size equals: 2.
	first := instance openWaitingEntries first.
	second := instance openWaitingEntries second.
	self assertConsistent: instance.

	self assert: (instance cancelStrand: first token) size equals: 1.

	self assert: instance suspended size equals: 1.
	self assert: instance openWaitingEntries asArray equals: { second }.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.

	self assert: (instance signal: second correlationId with: 7).
	instance execute.

	self assert: instance state equals: #done.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTwiceIsCancellingOnce [
	| instance token |
	instance := self flowWaitingFromOutside newInstance.
	instance executeWith: 1.
	token := instance openWaitingEntries first token.
	self assert: (instance cancelStrand: token) size equals: 1.

	self assert: (instance cancelStrand: token) isEmpty.
	self assert: (instance cancelStrand: FBToken new) isEmpty.

	self assert: (self cancelledEventsOf: instance) size equals: 1
]
