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
	self assert: (#( cancelled created running waiting done error ) includes: state) description: 'state ', state printString.
	self assert: (state = #cancelled) equals: anInstance isCancelled.
	self assert: (state = #done) equals: (anInstance atEnd and: [ anInstance hasErrors not and: [ anInstance isCancelled not ] ]).
	self assert: (state = #waiting) equals: (anInstance isWaiting and: [ anInstance isCancelled not ]).
	state = #waiting ifTrue: [ self deny: anInstance executor hasPending ].
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

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheCaseTakesEverythingAndEndsCancelled [
	"Cancel Case: the root scope falls, every wait and address with it, the instance is
	over, has ended, and reads #cancelled. A late signal is silent, and so is a second
	cancel"
	| instance address wait |
	instance := self flowWaitingFromOutside newInstance.
	instance executeWith: 1.
	address := instance openWaitingEntries first.
	wait := instance suspended first.

	self assert: instance cancel size equals: 1.

	self assert: instance state equals: #cancelled.
	self assert: instance isCancelled.
	self assert: instance scope isCancelled.
	self assert: instance atEnd.
	self assert: instance hasEnded.
	self assert: instance suspended isEmpty.
	self assert: instance openWaitingEntries isEmpty.
	self assert: (instance activations detect: [ :each | each node == wait ]) state equals: #cancelled.
	self assert: (instance events anySatisfy: [ :each | each isKindOf: FBScopeCancelled ]).
	self assert: (instance events select: [ :each | each isKindOf: FBFlowInstanceEnded ]) size equals: 1.
	self deny: (instance signal: address correlationId with: 7).
	self assert: instance cancel isEmpty.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheCaseStopsAParallelLoopBeforeItsNextIteration [
	"a loop with iterations still to come: after the cancel none of them starts, the
	body never ran, and the parallel executor has popped"
	| start fork body flow instance ran |
	ran := 0.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act | ran := ran + 1. act value: act argument ].
	fork --> body.
	(body addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initialValue: #( 1 2 3 ).
	instance step. "start"
	instance step. "fork - the first iteration is queued, the loop is on top"
	self assert: (instance executor isKindOf: FBParallelExecutor).
	self assert: instance executor pending notEmpty.

	instance cancel.

	self assert: ran equals: 0.
	self assert: instance state equals: #cancelled.
	self assert: instance isRootExecutor.
	self assert: instance atEnd.
	self assert: instance hasEnded.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAnIterationScopeAloneLetsTheLoopGoOn [
	"Cancel Multiple Instance Activity in the small: one iteration's scope falls, the
	loop itself is untouched and completes once the other iteration is resumed"
	| start fork wait flow instance first second |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	(wait addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	first := instance openWaitingEntries first.
	second := instance openWaitingEntries second.
	self deny: first token scope == second token scope.

	self assert: (instance cancelScope: first token scope) size equals: 1.

	self assert: first token scope isCancelled.
	self deny: instance isCancelled.
	self assert: instance state equals: #waiting.
	self assert: instance openWaitingEntries asArray equals: { second }.
	self assertConsistent: instance.
	self assert: (instance signal: second correlationId with: 7).
	instance execute.
	self assert: instance state equals: #done.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheCaseWithAWaitingSubFlowCancelsTheChildAndPopsItsFrame [
	"the child's root scope is nested in the caller's, so it reads #cancelled too; the
	frame pops without failing the caller - nothing errored, a decision was made"
	| instance child |
	instance := (self flowCalling: self flowWaitingFromOutside) newInstance.
	instance executeWith: 1.
	child := instance subFlowInstances first.
	self assert: instance state equals: #waiting.

	instance cancel.

	self assert: child isCancelled.
	self assert: child state equals: #cancelled.
	self assert: child suspended isEmpty.
	self assert: instance state equals: #cancelled.
	self assert: instance isRootExecutor.
	self deny: instance hasErrors.
	self deny: (instance events anySatisfy: [ :each | each isKindOf: FBNodeActivationErrored ]).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testACancelledScopeTakesNoNewWorkAndParksNothing [
	"the rule behind cancellation: a token whose scope was cancelled is neither queued
	nor parked - it is marked cancelled and the strand ends there"
	| instance token activation wait |
	instance := FBFlow simpleFlow newInstance.
	instance initializeExecutor.
	instance scope cancelled.
	token := FBToken new scope: instance scope; yourself.

	instance executor addPending: instance flow start outgoing first withToken: token.
	self assert: instance executor pending size equals: 1. "the start alone"
	self assert: token isCancelled.

	wait := FBPluggableWait new condition: [ :each | false ]; yourself.
	activation := FBActivation new executor: instance executor; node: wait; yourself.
	activation token: (FBToken new scope: instance scope; yourself).
	self assert: (activation waitForNode: wait withToken: activation token) isNil.
	self assert: instance executor suspended isEmpty.
	self assert: activation state equals: #cancelled
]

{ #category : 'tests' }
FBCancellationTest >> testATerminateNodeEndsTheInstanceDoneAndTakesTheOtherStrandBack [
	"Explicit Termination: one branch reaches the terminate node while the other waits.
	The waiting strand is taken back, the instance ends as #done - a modelled end - and
	the terminating step itself reads #done"
	| start split a terminate wait flow instance |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument ].
	terminate := FBTerminateEvent new.
	wait := FBExternalWait new condition: [ :each | false ]; yourself.
	split --> a --> terminate.
	split --> wait --> FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.

	instance executeWith: 1.

	self assert: instance state equals: #done.
	self deny: instance isCancelled.
	self assert: instance atEnd.
	self assert: instance suspended isEmpty.
	self assert: instance openWaitingEntries isEmpty.
	self assert: (instance activations detect: [ :each | each node == terminate ]) state equals: #done.
	self assert: (instance activations detect: [ :each | each node == wait ]) state equals: #cancelled.
	self assert: (instance events anySatisfy: [ :each | each isKindOf: FBFlowInstanceTerminated ]).
	self assert: (instance events select: [ :each | each isKindOf: FBFlowInstanceEnded ]) size equals: 1.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAnErroredInstanceReadsCancelled [
	"an abort is a decision and wins over an error that stood before it"
	| instance |
	instance := FBFlow simpleFlowWithError newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #error.

	instance cancel.

	self assert: instance state equals: #cancelled.
	self assert: instance hasErrors.
	self assert: instance hasEnded.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAnInstanceThatNeverRanEndsItCancelled [
	| instance |
	instance := self flowWaitingFromOutside newInstance.
	self assert: instance state equals: #created.

	instance cancel.

	self assert: instance state equals: #cancelled.
	self assert: instance hasEnded.
	self assert: instance activations isEmpty.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheCaseTakesStrandsWithoutAScopeToo [
	"an instance persisted before tokens carried a scope: its strands belong to no scope,
	and a cancel by scope would miss them. The root cancel takes everything in the
	chain, scope or not"
	| instance token |
	instance := self flowWaitingFromOutside newInstance.
	instance executeWith: 1.
	token := instance openWaitingEntries first token.
	token scope: nil.

	self assert: instance cancel asArray equals: { token }.

	self assert: token isCancelled.
	self assert: instance suspended isEmpty.
	self assert: instance state equals: #cancelled
]

{ #category : 'helpers' }
FBCancellationTest >> flowJoiningAWaitAndATask [
	"start -> split -> wait (external) -> join -> after -> end
	              \-> b (task)     -/"
	| start split wait b join after |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	wait := split addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; name: 'wait'; yourself).
	b := split addOutgoingNode: ((FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ]).
	join := FBAndJoin named: 'join'.
	wait --> join.
	b --> join.
	after := join addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'helpers' }
FBCancellationTest >> nodeNamed: aString in: anInstance [
	^ anInstance flow nodes detect: [ :each | each name = aString ]
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingABranchBeforeItsSiblingArrivesLetsTheJoinGoOnWithTheRest [
	"the branch falls while it is still queued; the sibling arrives later and finds the
	pass one branch short - the join goes on with the sibling's value alone"
	| flow instance wait queued after |
	flow := self flowJoiningAWaitAndATask.
	instance := flow newInstance.
	instance initialValue: 1.
	instance step. "start"
	instance step. "split - both branches queued"
	wait := self nodeNamed: 'wait' in: instance.
	queued := instance executor pending detect: [ :each | each transition target == wait ].
	self assertConsistent: instance.

	instance cancelStrand: queued token.

	self assertConsistent: instance.
	instance execute.
	after := instance activationOfNode: (self nodeNamed: 'after' in: instance).
	self assert: after argument keys asArray equals: { self nodeNamed: 'b' in: instance }.
	self assert: (after argument at: (self nodeNamed: 'b' in: instance)) equals: 10.
	self assert: instance state equals: #done.
	self deny: (instance activations anySatisfy: [ :each | each node == wait ]).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheLastMissingBranchReleasesTheJoinFromTheWithdrawal [
	"the sibling has arrived and the join waits for the branch that is now taken back:
	no further arrival will come to ask, so the withdrawal itself releases the join,
	and the node behind it is queued - the instance runs again"
	| flow instance join after |
	flow := self flowJoiningAWaitAndATask.
	instance := flow newInstance.
	instance executeWith: 1.
	join := self nodeNamed: 'join' in: instance.
	after := self nodeNamed: 'after' in: instance.
	self assert: instance state equals: #waiting.
	self assert: (instance activations select: [ :each | each node == join ]) size equals: 1.
	self deny: (instance activations anySatisfy: [ :each | each node == after ]).
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.

	self assert: instance state equals: #running.
	self assert: (instance executor pending collect: [ :each | each transition target ]) asArray equals: { after }.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :each | each node == after ]) size equals: 1.
	self assert: (instance activationOfNode: after) argument keys asArray equals: { self nodeNamed: 'b' in: instance }.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingEveryBranchOfAPassReleasesNothingAndEndsTheInstance [
	"both branches fall before either arrived: the join never runs, nothing behind it
	runs, and with nothing left on its way the instance is over"
	| start split waitA waitB join after flow instance |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	waitA := split addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	waitB := split addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	join := FBAndJoin named: 'join'.
	waitA --> join.
	waitB --> join.
	after := join addOutgoingNode: (FBTask named: 'after').
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance openWaitingEntries size equals: 2.
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.
	instance cancelStrand: instance openWaitingEntries first token.

	self assert: instance state equals: #done.
	self assert: instance hasEnded.
	self deny: (instance activations anySatisfy: [ :each | each node == join ]).
	self deny: (instance activations anySatisfy: [ :each | each node == after ]).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingABranchInsideAnInnerPassLetsBothJoinsGoOn [
	"a split nested in a branch of another: the inner pass loses a branch, its join goes
	on with the other, and the outer join then sees that branch arrive next to its
	sibling as if nothing had happened inside"
	| start outer inner a1 a2 innerJoin b outerJoin after flow instance |
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBAndSplit named: 'outer').
	inner := outer addOutgoingNode: (FBAndSplit named: 'inner').
	a1 := inner addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	a2 := inner addOutgoingNode: ((FBPluggableTask named: 'a2') block: [ :act | act value: 2 ]).
	innerJoin := FBAndJoin named: 'inner join'.
	a1 --> innerJoin.
	a2 --> innerJoin.
	b := outer addOutgoingNode: ((FBPluggableTask named: 'b') block: [ :act | act value: 3 ]).
	outerJoin := FBAndJoin named: 'outer join'.
	innerJoin --> outerJoin.
	b --> outerJoin.
	after := outerJoin addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.

	self assert: instance state equals: #running.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :each | each node == after ]) size equals: 1.
	self assert: (instance activationOfNode: after) argument keys asSet equals: { innerJoin. b } asSet.
	self assert: ((instance activationOfNode: after) argument at: innerJoin) equals: (Dictionary new at: a2 put: 2; yourself).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAWholeInnerPassCostsTheOuterOneExactlyOneBranch [
	"both branches of the inner pass fall and nothing arrived at its join: the inner
	join never runs, and the branch that led into the inner split is gone for the outer
	pass - one branch, not two. The outer join, which already had the sibling, goes on
	with it alone"
	| start outer inner a1 a2 innerJoin b outerJoin after flow instance |
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBAndSplit named: 'outer').
	inner := outer addOutgoingNode: (FBAndSplit named: 'inner').
	a1 := inner addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	a2 := inner addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	innerJoin := FBAndJoin named: 'inner join'.
	a1 --> innerJoin.
	a2 --> innerJoin.
	b := outer addOutgoingNode: ((FBPluggableTask named: 'b') block: [ :act | act value: 3 ]).
	outerJoin := FBAndJoin named: 'outer join'.
	innerJoin --> outerJoin.
	b --> outerJoin.
	after := outerJoin addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance openWaitingEntries size equals: 2.
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.
	"one inner branch down: the inner join could still be reached by the other, nothing
	moves yet"
	self assert: instance state equals: #waiting.
	self deny: (instance activations anySatisfy: [ :each | each node == after ]).
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.

	self assert: instance state equals: #running.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self deny: (instance activations anySatisfy: [ :each | each node == innerJoin ]).
	self assert: (instance activations select: [ :each | each node == after ]) size equals: 1.
	self assert: (instance activationOfNode: after) argument keys asArray equals: { b }.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingAMultiChoiceBranchCountsAgainstTheBranchesStarted [
	"a multi choice started two of its three branches; one is taken back, and the join
	goes on with the other - the branch never started was never expected"
	| start choice a b c join after flow instance |
	start := FBStartEvent new.
	choice := start addOutgoingNode: (FBMultiChoiceGateway named: 'choice').
	a := FBExternalWait new condition: [ :each | false ]; yourself.
	b := (FBPluggableTask named: 'b') block: [ :act | act value: 2 ].
	c := FBTask named: 'c'.
	join := FBOrJoin named: 'join'.
	choice --> (a when: [ :x | x > 0 ]) --> join.
	choice --> (b when: [ :x | x > 0 ]) --> join.
	choice --> (c when: [ :x | x > 100 ]) --> join.
	after := join addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.

	instance cancelStrand: instance openWaitingEntries first token.

	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance activationOfNode: after) argument keys asArray equals: { b }.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testAJoinReleasedFromAWithdrawalQueuesOnItsOwnExecutorNotOnTheFrameOnTop [
	"the join stands in the root executor; when its last missing branch is taken back a
	parallel scope of another strand is on top, waiting. The join's continuation belongs
	to the root - it runs once the frame has popped - and must not land in the frame"
	| start outer inner wait b innerJoin after fork iteration outerJoin flow instance root frame waitToken |
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBAndSplit named: 'outer').
	"first branch: a split whose join will be released from the withdrawal"
	inner := outer addOutgoingNode: (FBAndSplit named: 'inner').
	wait := inner addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; name: 'wait'; yourself).
	b := inner addOutgoingNode: ((FBPluggableTask named: 'b') block: [ :act | act value: 2 ]).
	innerJoin := FBAndJoin named: 'inner join'.
	wait --> innerJoin.
	b --> innerJoin.
	after := innerJoin addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	"second branch: a parallel scope that waits in every iteration - two nodes later
	than the first branch, so that the first branch's wait has parked and its sibling
	has arrived at the join before the frame is pushed and takes the top (the root
	queue is stepped in order, one activation per step)"
	fork := ((outer addOutgoingNode: ((FBPluggableTask named: 'pre') block: [ :act | act value: act argument ]))
		addOutgoingNode: ((FBPluggableTask named: 'pre 2') block: [ :act | act value: act argument ]))
		addOutgoingNode: (FBParallelNode named: 'fork').
	iteration := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; name: 'iteration'; yourself).
	outerJoin := FBAndJoin named: 'outer join'.
	after --> outerJoin.
	(iteration addOutgoingNode: (FBParallelJoinNode named: 'scope join')) --> outerJoin.
	outerJoin addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	"one iteration: two waiting at the same transition would share its suspension, and
	resuming one drops the other's address today - a separate matter"
	instance executeWith: #( 1 ).
	root := instance rootExecutor.
	frame := instance executor.
	self assert: (frame isKindOf: FBParallelExecutor).
	self assert: instance state equals: #waiting.
	self assert: instance openWaitingEntries size equals: 2.
	self assertConsistent: instance.

	waitToken := (instance openWaitingEntries detect: [ :each | each token node == wait ]) token.
	instance cancelStrand: waitToken.

	"queued where the join stands, behind the frame - the frame itself is untouched"
	self assert: (root pending collect: [ :each | each transition target ]) asArray equals: { after }.
	self assert: frame pending isEmpty.
	self assert: instance executor identicalTo: frame.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.

	"the iteration is resumed, the frame pops, and the root runs what the join queued"
	self assert: (instance signal: instance openWaitingEntries first correlationId with: 7).
	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :each | each node == after ]) size equals: 1.
	self assert: (instance activations select: [ :each | each node == outerJoin ]) size equals: 2.
	self assertConsistent: instance
]

{ #category : 'helpers' }
FBCancellationTest >> loopWaitingTwiceInto: aCollector [
	"start -> fork -> wait (external) -> scope join -> after -> end over #( 10 20 );
	after's argument is collected"
	| start fork wait after flow instance |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	after := (wait addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act |
			aCollector add: act argument.
			act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	^ instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheLastWaitingIterationCompletesTheLoop [
	"the first iteration was resumed and passed the scope join; the second, still
	waiting, is taken back. The loop is over, and the node behind the scope join runs
	with the first iteration's value and a nil slot for the second - it used to be left
	unrun, with the instance reading #done"
	| seen instance entries |
	seen := OrderedCollection new.
	instance := self loopWaitingTwiceInto: seen.
	entries := instance openWaitingEntries copy.
	self assert: (instance signal: entries first correlationId with: 1).
	instance execute.
	self assert: instance state equals: #waiting.
	self assert: seen isEmpty.
	self assertConsistent: instance.

	instance cancelStrand: entries second token.

	self assert: instance state equals: #running.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( 1 nil ) }.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingEveryIterationCompletesTheLoopWithNothing [
	"both iterations are taken back before either arrived: the loop completes with an
	empty result and the flow goes on behind it - a loop is one activity of the flow,
	unlike an AND-join, which releases nothing when nothing arrived"
	| seen instance |
	seen := OrderedCollection new.
	instance := self loopWaitingTwiceInto: seen.
	self assert: instance openWaitingEntries size equals: 2.

	instance cancelStrand: instance openWaitingEntries first token.
	self assert: instance state equals: #waiting.
	self assert: seen isEmpty.
	self assertConsistent: instance.
	instance cancelStrand: instance openWaitingEntries first token.

	self assert: instance state equals: #running.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( nil nil ) }.
	self assert: (self cancelledEventsOf: instance) size equals: 2.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testALoopInACancelledCaseDoesNotGoOnBehindItsJoin [
	"Cancel Case while the loop waits: the loop's own scope fell with the root scope,
	so completing it queues nothing - nothing runs behind the scope join, and the
	instance reads #cancelled"
	| seen instance |
	seen := OrderedCollection new.
	instance := self loopWaitingTwiceInto: seen.
	self assert: instance state equals: #waiting.

	instance cancel.

	self assert: instance state equals: #cancelled.
	self assert: instance hasEnded.
	self assert: seen isEmpty.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheRemainingIterationsCompletesTheLoopWithWhatArrived [
	"Cancel Multiple Instance Activity: one iteration has arrived, the other still
	waits. Cancelling the remaining iterations takes the wait, and the loop completes
	with the first iteration's value and a nil slot - the flow goes on behind it"
	| seen instance entries fork taken |
	seen := OrderedCollection new.
	instance := self loopWaitingTwiceInto: seen.
	fork := instance flow nodes detect: [ :each | each name = 'fork' ].
	entries := instance openWaitingEntries copy.
	self assert: (instance signal: entries first correlationId with: 1).
	instance execute.
	self assert: instance state equals: #waiting.
	self assertConsistent: instance.

	taken := instance cancelIterationsOf: fork.

	self assert: taken asArray equals: { entries second token }.
	self assert: instance openWaitingEntries isEmpty.
	self assert: instance state equals: #running.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( 1 nil ) }.
	self assert: (instance events count: [ :each | each isKindOf: FBScopeCancelled ]) equals: 1.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheIterationsOfANodeThatIsNotLoopingIsSilent [
	"before the loop opened and after it closed there is nothing to cancel: empty
	answer, no event, the instance untouched"
	| seen instance fork before |
	seen := OrderedCollection new.
	instance := (self loopWaitingTwiceInto: seen) flow newInstance.
	fork := instance flow nodes detect: [ :each | each name = 'fork' ].
	self assert: (instance cancelIterationsOf: fork) isEmpty.
	self assert: instance state equals: #created.

	instance executeWith: #( 10 20 ).
	instance openWaitingEntries copy do: [ :each | instance signal: each correlationId with: 0 ].
	instance execute.
	self assert: instance state equals: #done.
	before := instance events size.
	self assert: (instance cancelIterationsOf: fork) isEmpty.
	self assert: instance events size equals: before.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheRemainingIterationsInsideASplitBranchLetsTheJoinGoOn [
	"the loop runs in one branch of an AND-split, its sibling has arrived at the join.
	Cancelling the loop's iterations completes the loop, its branch arrives with the
	loop's result, and the join releases with both"
	| start split fork wait b join after flow instance |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	"the sibling first, and the loop one node later: the sibling has to arrive at the
	join before the loop's frame takes the top - the root queue is stepped in order"
	b := split addOutgoingNode: ((FBPluggableTask named: 'b') block: [ :act | act value: 3 ]).
	join := FBAndJoin named: 'join'.
	b --> join.
	fork := (split addOutgoingNode: ((FBPluggableTask named: 'pre') block: [ :act | act value: act argument ]))
		addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	(wait addOutgoingNode: (FBParallelJoinNode named: 'scope join')) --> join.
	after := join addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	self assert: instance state equals: #waiting.
	self assert: (instance activations count: [ :each | each node == join ]) equals: 1.
	self assertConsistent: instance.

	instance cancelIterationsOf: fork.

	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: (instance activations count: [ :each | each node == after ]) equals: 1.
	self assert: (instance activationOfNode: after) argument keys asSet equals: { b. wait outgoing first target } asSet.
	self assert: ((instance activationOfNode: after) argument at: wait outgoing first target) equals: #( nil nil ).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheForksStrandTakesTheLoopAndNothingRunsBehindIt [
	"Cancel Activity on the loop itself: the fork's strand and everything descending
	from it fall, no further iteration starts, and nothing goes on behind the scope
	join - the strand is gone. Used to take the iterations and then start the next one"
	| seen instance fork forkToken |
	seen := OrderedCollection new.
	instance := self loopWaitingTwiceInto: seen.
	fork := instance flow nodes detect: [ :each | each name = 'fork' ].
	forkToken := (instance activationOfNode: fork) token.
	self assert: instance openWaitingEntries size equals: 2.
	self assertConsistent: instance.

	instance cancelStrand: forkToken.

	self assert: forkToken isCancelled.
	self assert: instance openWaitingEntries isEmpty.
	self assert: instance isRootExecutor.
	self assert: instance state equals: #done.
	self assert: instance hasEnded.
	self assert: seen isEmpty.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBCancellationTest >> testCancellingTheRemainingIterationsTakesAWaitingSubFlowWithThem [
	"an iteration calls a sub flow that waits, so its frame is on top and the loop
	cannot even start the next iteration. Cancelling the iterations takes the child's
	wait, the frame pops, and the loop completes with nothing"
	| start fork subNode after flow instance seen |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	subNode := fork addOutgoingNode: FBSubFlowNode new.
	subNode subFlow: self flowWaitingFromOutside.
	after := (subNode addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act |
			seen add: act argument.
			act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	self assert: instance state equals: #waiting.
	self assert: (instance executor isKindOf: FBSubFlowExecutor).
	self assert: instance openWaitingEntries size equals: 1.
	self assertConsistent: instance.

	instance cancelIterationsOf: fork.

	self assert: instance openWaitingEntries isEmpty.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( nil nil ) }.
	self assertConsistent: instance
]
