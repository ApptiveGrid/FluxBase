Class {
	#name : 'FBFlowInstanceTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBFlowInstanceTest >> testInnermostWaitingExecutorIsTheCurrentOneWhenItWaitsItself [
	| flowInstance |
	flowInstance := FBFlow simpleWaitFlow newInstance.
	flowInstance executeWith: 2.
	self assert: flowInstance state equals: #waiting.
	self assert: flowInstance innermostWaitingExecutor identicalTo: flowInstance executor
]

{ #category : 'tests' }
FBFlowInstanceTest >> testTheEndOfAnInstanceIsAnEventOnce [
	"the end of an instance used to be nothing but a derived answer - #state saying #done
	- that nobody observed. Now it is a moment: the last activation records an
	FBFlowInstanceEnded, exactly once, as the last event. A waiting instance has not
	ended and gets the event only once it was resumed and ran to its end"
	| start wait flow instance endedEvents |
	endedEvents := [ instance events select: [ :each | each isKindOf: FBFlowInstanceEnded ] ].
	start := FBStartEvent new.
	wait := start addOutgoingNode: (FBPluggableWait new condition: [ :each | false ]; yourself).
	wait addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.

	self assert: instance state equals: #waiting.
	self assert: endedEvents value isEmpty.

	instance resumeWaitingAt: wait with: 1.
	instance execute.

	self assert: instance state equals: #done.
	self assert: endedEvents value size equals: 1.
	self assert: (instance events last isKindOf: FBFlowInstanceEnded)
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInnermostWaitingExecutorIsNilWhenNothingWaits [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance executeWith: 7.
	self assert: flowInstance state equals: #done.
	self assert: flowInstance innermostWaitingExecutor isNil
]

{ #category : 'tests' }
FBFlowInstanceTest >> testTheRootScopeComesWithTheExecutorNotWithAReading [
	"regression test, kept from the days when #scope created a root scope on first read:
	that is a write on read - on an instance materialized in a read-only Soil transaction
	it marks the instance dirty and signals SoilWriteOnReadOnlyTransaction, which
	surfaced as an unrelated-looking timeout in AGExternalFlowHookTest>>
	testPostToExternalHook. Reading still creates nothing. The root scope comes with the
	executor instead - every instance has one from its first step, and the start token
	lives in it"
	| flowInstance start |
	flowInstance := FBFlow simpleFlow newInstance.
	self assert: flowInstance scope isNil.
	flowInstance scope.
	self assert: flowInstance scope isNil.
	flowInstance executeWith: 7.
	self assert: flowInstance state equals: #done.
	self assert: flowInstance scope notNil.
	self assert: flowInstance scope outer isNil.
	self assert: flowInstance scope callDepth equals: 0.
	start := flowInstance activations detect: [ :each | each node == flowInstance flow start ].
	self assert: start token scope identicalTo: flowInstance scope.
	"and every strand after it inherits the scope"
	self assert: (flowInstance activations allSatisfy: [ :each | each token scope == flowInstance scope ])
]

{ #category : 'tests' }
FBFlowInstanceTest >> testActivationsAreDone [
	"every step of a run that went through reads #done afterwards. Used to compare with
	#isDone, a symbol no activation ever answers, over an instance that had not run -
	an empty collection satisfying anything"
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance executeWith: 7.
	self assert: flowInstance state equals: #done.
	self deny: flowInstance activations isEmpty.
	self assert: (flowInstance activations allSatisfy: [ :each | each state = #done ])
]

{ #category : 'tests' }
FBFlowInstanceTest >> testActivationsWithGatewayAreDone [
	| flowInstance |
	flowInstance := FBFlow gatewayedFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance state equals: #done.
	self assert: (flowInstance activations allSatisfy: [ :each | each state = #done ])
]

{ #category : 'tests' }
FBFlowInstanceTest >> testCompleted [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance atEnd.
	self assert: flowInstance atEnd equals: true
]

{ #category : 'tests' }
FBFlowInstanceTest >> testCreateFlowInstance [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initializeExecutor.
	self assert: flowInstance pending size equals: 1.
	self assert: flowInstance pending first class equals: FBWorkItem.
	self assert: flowInstance pending first transition class equals: FBStartEvent
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncements [ 
	| flowInstance events |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	events := OrderedCollection new.
	flowInstance whenAnnounced: FBNodeActivationStarted  do: [ :e | events add: e ].
	flowInstance execute.
	self assert: events size equals: flowInstance flow nodes size 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncementsWithError [
	| flowInstance events |
	flowInstance := FBFlow simpleFlowWithError newInstance.
	flowInstance initialValue: 7.
	events := OrderedCollection new.
	flowInstance 
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ] .
	flowInstance execute.
	self assert: events last class equals: FBNodeActivationErrored.
	self assert: flowInstance activations last state equals: #error 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testFlowAnnouncementsWithSystemError [
	| flowInstance events |
	flowInstance := FBFlow simpleFlowWithSystemError newInstance.
	events := OrderedCollection new.
	flowInstance 
		whenAnnounced: FBFlowEvent do: [ :e | events add: e ].
	flowInstance initialValue: 7.
	self 
		should: [ flowInstance execute ]
		raise: ZeroDivide.
	self assert: events size equals: 7 
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateCreated [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	self assert: flowInstance state equals: #created
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateDone [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	self assert: flowInstance state equals: #done
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateError [
	| flowInstance |
	flowInstance := FBFlow simpleFlowWithError newInstance.
	flowInstance initialValue: 7.
	flowInstance step; step.
	self assert: flowInstance state equals: #error
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateRunning [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance step.
	self assert: flowInstance state equals: #running
]

{ #category : 'tests' }
FBFlowInstanceTest >> testInstanceStateWaiting [
	| flowInstance |
	flowInstance := FBFlow simpleWaitFlow newInstance.
	flowInstance initialValue: 6.
	flowInstance step; step.
	self assert: flowInstance state equals: #waiting
]

{ #category : 'tests' }
FBFlowInstanceTest >> testListActivationEvents [
	| flowInstance events |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	flowInstance execute.
	events := flowInstance eventsOfActivation: flowInstance activations second.
	self assert: events size equals: 2
]

{ #category : 'tests' }
FBFlowInstanceTest >> testListNodeEvents [
	| flowInstance events node |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7. 
	flowInstance execute.
	node := flowInstance flow nodes second.
	events := flowInstance eventsOfNode: node.
	self assert: events size equals: 2
]

{ #category : 'tests' }
FBFlowInstanceTest >> testNodeActivationEventCarriesTheRootScopeIdAndNoSplitId [
	"the event log reports the scope by id - the root scope's, for a flow without sub
	flows or parallel nodes - and no split id where no split ran"
	| flowInstance node event |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	node := flowInstance flow nodes second.
	event := (flowInstance eventsOfNode: node) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self assert: event scopeId equals: flowInstance scope id.
	self assert: event splitId isNil
]

{ #category : 'as yet unclassified' }
FBFlowInstanceTest >> testNodeActivationEventsExposeTokenId [
	| flowInstance node events startedEvent doneEvent |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	node := flowInstance flow nodes second.
	events := flowInstance eventsOfNode: node.
	startedEvent := events detect: [ :e | e isKindOf: FBNodeActivationStarted ].
	doneEvent := events detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self assert: startedEvent tokenId notNil.
	self assert: startedEvent tokenId equals: doneEvent tokenId
]

{ #category : 'as yet unclassified' }
FBFlowInstanceTest >> testNodeActivationEventsForDifferentNodesHaveDifferentTokenIds [
	| flowInstance firstNode secondNode firstEvent secondEvent |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	flowInstance execute.
	firstNode := flowInstance flow start.
	secondNode := flowInstance flow nodes second.
	firstEvent := (flowInstance eventsOfNode: firstNode) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	secondEvent := (flowInstance eventsOfNode: secondNode) detect: [ :e | e isKindOf: FBNodeActivationDone ].
	self deny: firstEvent tokenId equals: secondEvent tokenId
]

{ #category : 'tests' }
FBFlowInstanceTest >> testNextTransitionAnswersATransitionAndNotTheWorkItemHoldingIt [
	| flowInstance task |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initializeExecutor.
	flowInstance step.
	task := flowInstance flow nodes second.
	self assert: flowInstance nextTransition class equals: FBTransition.
	self assert: flowInstance nextTransition
		equals: (flowInstance pending first transition).
	self assert: flowInstance nextTransition source equals: flowInstance start.
	self assert: flowInstance nextTransition target equals: task
]

{ #category : 'tests' }
FBFlowInstanceTest >> testNextTransitionForTheStartPseudoTransition [
	"the very first queued item holds the start node itself rather than a real
	transition - FBBaseExecutor>>scheduleStart. It answers itself for #transition,
	so #nextTransition stays readable on it"
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initializeExecutor.
	self assert: flowInstance nextTransition equals: flowInstance start.
	self assert: flowInstance nextNode equals: flowInstance start
]

{ #category : 'tests' }
FBFlowInstanceTest >> testResumeWaitingAtContinuesTheFlow [
	| flow instance waitNode |
	flow := FBFlow simpleWaitFlow.
	instance := flow newInstance.
	instance executeWith: 4.

	self deny: instance atEnd.
	self assert: instance suspended size equals: 1.
	waitNode := instance suspended first.

	instance resumeWaitingAt: waitNode with: 4.
	instance execute.

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	self assert: instance suspended isEmpty
]

{ #category : 'tests' }
FBFlowInstanceTest >> testResumeWaitingAtRaisesWhenNodeIsNotWaiting [
	| flow instance |
	flow := FBFlow simpleFlow.
	instance := flow newInstance.
	instance executeWith: 7.

	self
		should: [ instance resumeWaitingAt: flow start with: nil ]
		raise: FBNodeNotWaiting
]

{ #category : 'tests' }
FBFlowInstanceTest >> testSimpleWaitCompletion [
	| instance |
	instance := FBFlow simpleWaitFlow newInstance. 
	instance initialValue: 3.
	instance execute.
	self assert: instance atEnd
]

{ #category : 'tests' }
FBFlowInstanceTest >> testSimpleWaitSuspension [ 
	| instance |
	instance := FBFlow simpleWaitFlow newInstance. 
	instance initialValue: 2.
	instance execute.
	self deny: instance atEnd
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStepping [
	| flowInstance |
	flowInstance := FBFlow simpleFlow newInstance.
	flowInstance initialValue: 7.
	self assert: flowInstance nextNode class equals: FBStartEvent.
	flowInstance step.
	self assert: flowInstance nextNode class equals: FBTask.
	flowInstance step.
	self assert: flowInstance nextNode class equals: FBEndEvent.
	flowInstance step.
	self assert: flowInstance atEnd.
	self assert: flowInstance atEnd equals: true
]

{ #category : 'private' }
FBFlowInstanceTest >> assertStateInvariantsOf: anInstance [
	"the promises FBFlowInstance>>state rests on, checked at one step boundary: the state
	is one of six and never nil; #cancelled means the root scope fell; #done means over,
	nothing failed and nothing was cancelled; #waiting means nothing can advance without
	an impulse; every executor on the stack that calls itself done is at its end; and no
	open address is hidden before the end"
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
FBFlowInstanceTest >> runCheckingInvariants: anInstance [
	"step anInstance as far as it goes, checking the state invariants at every boundary,
	and answer the number of steps taken"
	| steps |
	steps := 0.
	self assertStateInvariantsOf: anInstance.
	[ anInstance executor hasPending ] whileTrue: [
		anInstance step.
		steps := steps + 1.
		self assert: steps < 100.
		self assertStateInvariantsOf: anInstance ].
	^ steps
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStateInvariantsHoldAcrossAWaitAndItsResume [
	| instance wait |
	instance := FBFlow simpleWaitFlow newInstance.
	instance initialValue: 2.
	self runCheckingInvariants: instance.
	self assert: instance state equals: #waiting.
	wait := instance suspended first.
	instance resumeWaitingAt: wait with: 7.
	self assertStateInvariantsOf: instance.
	self runCheckingInvariants: instance.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStateInvariantsHoldAcrossAParallelScopeWithAJoin [
	| start fork split a b join after end flow instance |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	split := fork addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	after := (FBPluggableTask named: 'after') block: [ :act | act value: act argument ].
	split --> a --> join.
	split --> b --> join.
	join --> after.
	end := (after addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initialValue: #( 10 20 ).
	self runCheckingInvariants: instance.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStateInvariantsHoldAcrossASubFlowInsideAParallelScope [
	"the case that caught FBParallelExecutor>>isDone answering #done in the middle of its
	loop: while the sub flow frame pushed by an iteration runs, the parallel executor
	below it has nothing pending and nothing suspended, and is anything but done"
	| childStart childFlow start fork subNode flow instance |
	childStart := FBStartEvent new.
	(childStart addOutgoingNode: ((FBPluggableTask named: 'work') block: [ :act | act value: act argument ]))
		addOutgoingNode: FBEndEvent new.
	childFlow := FBFlow new start: childStart.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	subNode := fork addOutgoingNode: FBSubFlowNode new.
	subNode subFlow: childFlow.
	(subNode addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initialValue: #( 1 2 3 ).
	self runCheckingInvariants: instance.
	self assert: instance state equals: #done.
	self assert: instance subFlowInstances size equals: 3
]

{ #category : 'tests' }
FBFlowInstanceTest >> testStateInvariantsHoldAcrossAWaitInsideASubFlow [
	| childStart childFlow start subNode flow instance wait |
	childStart := FBStartEvent new.
	(childStart addOutgoingNode: (FBPluggableWait new condition: [ :each | false ]; yourself))
		addOutgoingNode: FBEndEvent new.
	childFlow := FBFlow new start: childStart.
	start := FBStartEvent new.
	subNode := start addOutgoingNode: FBSubFlowNode new.
	subNode subFlow: childFlow.
	subNode addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance initialValue: 1.
	self runCheckingInvariants: instance.
	self assert: instance state equals: #waiting.
	self assert: instance isWaiting.
	wait := instance suspended first.
	instance resumeWaitingAt: wait with: 7.
	self assertStateInvariantsOf: instance.
	self runCheckingInvariants: instance.
	self assert: instance state equals: #done
]
