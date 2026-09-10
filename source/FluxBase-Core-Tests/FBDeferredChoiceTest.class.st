"
A deferred choice: the first branch whose wait goes on wins, the others fall - wherever
they stand. Built on FBCancellationTest for its helpers and its state invariant.
"
Class {
	#name : 'FBDeferredChoiceTest',
	#superclass : 'FBCancellationTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'helpers' }
FBDeferredChoiceTest >> choiceBetween: aNode and: anotherNode into: aCollector [
	"start -> choice -> aNode -> after -> end
	                \-> anotherNode -/        ; after's argument is collected"
	| start choice after |
	start := FBStartEvent new.
	choice := start addOutgoingNode: (FBDeferredChoice named: 'choice').
	choice --> aNode.
	choice --> anotherNode.
	after := (FBPluggableTask named: 'after') block: [ :act |
		aCollector add: act argument.
		act value: act argument ].
	aNode --> after.
	anotherNode --> after.
	after addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'helpers' }
FBDeferredChoiceTest >> externalWaitNamed: aString [
	^ FBExternalWait new condition: [ :each | false ]; name: aString; yourself
]

{ #category : 'helpers' }
FBDeferredChoiceTest >> decisionsOf: anInstance [
	^ anInstance events select: [ :each | each isKindOf: FBDeferredChoiceDecided ]
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testTheFirstBranchResumedWinsAndTheOtherFalls [
	| seen a b instance entryA entryB |
	seen := OrderedCollection new.
	a := self externalWaitNamed: 'a'.
	b := self externalWaitNamed: 'b'.
	instance := (self choiceBetween: a and: b into: seen) newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	self assert: instance openWaitingEntries size equals: 2.
	entryA := instance openWaitingEntries detect: [ :each | each token node == a ].
	entryB := instance openWaitingEntries detect: [ :each | each token node == b ].
	self assertConsistent: instance.

	self assert: (instance signal: entryB correlationId with: 'B').

	"b went on, a fell: its wait, its address, its activation reads cancelled"
	self assert: instance openWaitingEntries isEmpty.
	self assert: entryA token isCancelled.
	self assert: (instance activationOfNode: a) state equals: #cancelled.
	self assert: (instance activationOfNode: b) state equals: #done.
	self assert: (self decisionsOf: instance) size equals: 1.
	self assert: (self decisionsOf: instance) first choiceName equals: 'choice'.
	self assert: (self decisionsOf: instance) first winnerTokenId equals: entryB token id.
	self assertConsistent: instance.
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: #( 'B' ).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testASecondImpulseOnTheLoserIsSilent [
	| seen a b instance entryA entryB before |
	seen := OrderedCollection new.
	a := self externalWaitNamed: 'a'.
	b := self externalWaitNamed: 'b'.
	instance := (self choiceBetween: a and: b into: seen) newInstance.
	instance executeWith: 1.
	entryA := instance openWaitingEntries detect: [ :each | each token node == a ].
	entryB := instance openWaitingEntries detect: [ :each | each token node == b ].
	self assert: (instance signal: entryA correlationId with: 'A').
	instance execute.
	before := instance events size.

	self deny: (instance signal: entryB correlationId with: 'late').

	self assert: instance events size equals: before.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: #( 'A' ).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testAParkedTriggerBranchLoses [
	"the losing branch leads into a trigger target: its transition was parked, never
	activated. It falls with its address, and the trigger never runs"
	| seen a trigger instance entryA entryTrigger |
	seen := OrderedCollection new.
	a := self externalWaitNamed: 'a'.
	trigger := FBTriggerTask named: 'trigger'.
	instance := (self choiceBetween: a and: trigger into: seen) newInstance.
	instance executeWith: 1.
	self assert: instance openWaitingEntries size equals: 2.
	entryA := instance openWaitingEntries detect: [ :each | each token node == a ].
	entryTrigger := instance openWaitingEntries detect: [ :each | each waitingNode == trigger ].
	self assertConsistent: instance.

	self assert: (instance signal: entryA correlationId with: 'A').

	self assert: instance openWaitingEntries isEmpty.
	self assert: instance suspended isEmpty.
	self assert: entryTrigger token isCancelled.
	self deny: (instance activations anySatisfy: [ :each | each node == trigger ]).
	instance execute.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: #( 'A' ).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testALoserInsideASubFlowFallsWithItsFrame [
	"the losing branch called a sub flow that waits, so its frame is on top. Deciding
	the choice takes the child's wait and the call itself: the frame pops quietly, the
	call reads #cancelled, and the winner goes on in the root"
	| seen a call instance entryA |
	seen := OrderedCollection new.
	a := self externalWaitNamed: 'a'.
	call := FBSubFlowNode new.
	call subFlow: self flowWaitingFromOutside.
	instance := (self choiceBetween: a and: call into: seen) newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #waiting.
	self assert: (instance executor isKindOf: FBSubFlowExecutor).
	self assert: instance openWaitingEntries size equals: 2.
	entryA := instance openWaitingEntries detect: [ :each | each token node == a ].
	self assertConsistent: instance.

	self assert: (instance signal: entryA correlationId with: 'A').

	self assert: instance openWaitingEntries isEmpty.
	self assert: (instance activationOfNode: call) state equals: #cancelled.
	self assertConsistent: instance.
	instance execute.
	self assert: instance isRootExecutor.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: #( 'A' ).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testAChoiceInsideAnIterationDecidesThatIterationOnly [
	"each iteration of a parallel scope makes its own choice: deciding the second
	iteration's leaves the first iteration's two waits standing"
	| start fork choice a b after flow instance fork2 entriesOf seen |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	choice := fork addOutgoingNode: (FBDeferredChoice named: 'choice').
	a := choice addOutgoingNode: (self externalWaitNamed: 'a').
	b := choice addOutgoingNode: (self externalWaitNamed: 'b').
	after := (FBPluggableTask named: 'after') block: [ :act | seen add: act argument. act value: act argument ].
	a --> after.
	b --> after.
	(after addOutgoingNode: (FBParallelJoinNode named: 'scope join')) addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	fork2 := fork.
	entriesOf := [ :index | instance openWaitingEntries select: [ :each | (each token scope iterationOwnedBy: fork2) index = index ] ].
	self assert: instance openWaitingEntries size equals: 4.
	self assertConsistent: instance.

	self assert: (instance signal: ((entriesOf value: 2) detect: [ :each | each token node == b ]) correlationId with: 'B2').

	self assert: (entriesOf value: 2) isEmpty.
	self assert: (entriesOf value: 1) size equals: 2.
	self assert: (self decisionsOf: instance) size equals: 1.
	self assertConsistent: instance.
	instance execute.
	self assert: (instance signal: ((entriesOf value: 1) detect: [ :each | each token node == a ]) correlationId with: 'A1').
	instance execute.
	self assert: instance state equals: #done.
	self assert: (self decisionsOf: instance) size equals: 2.
	self assert: seen asSet equals: #( 'A1' 'B2' ) asSet.
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testAConditionThatHoldsAtOnceDecidesTheChoice [
	"a condition wait whose condition already holds is a wait that went on: it decides
	the choice as it is entered, and the other branch falls before anything waited"
	| seen a b instance |
	seen := OrderedCollection new.
	a := FBPluggableWait new condition: [ :each | true ]; name: 'a'; yourself.
	b := self externalWaitNamed: 'b'.
	instance := (self choiceBetween: a and: b into: seen) newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #done.
	self assert: instance openWaitingEntries isEmpty.
	self assert: (self decisionsOf: instance) size equals: 1.
	"once - a condition that holds passes no value on, as before"
	self assert: seen size equals: 1.
	self deny: (instance activations anySatisfy: [ :each | each node == b and: [ each state ~= #cancelled ] ]).
	self assertConsistent: instance
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testABranchThatCannotWaitIsRejected [
	"a branch that would run at once decides nothing and lets the others go on with it:
	the choice refuses to start"
	| seen a task instance |
	seen := OrderedCollection new.
	a := self externalWaitNamed: 'a'.
	task := FBTask named: 'task'.
	instance := (self choiceBetween: a and: task into: seen) newInstance.
	instance executeWith: 1.
	self assert: instance state equals: #error.
	self assert: instance openWaitingEntries isEmpty.
	self assert: seen isEmpty.
	self assert: ((instance events detect: [ :each | each isKindOf: FBNodeActivationErrored ]) message includesSubstring: 'waits')
]

{ #category : 'tests' }
FBDeferredChoiceTest >> testTheChoiceStaysOutOfTheExposedNodeSetForNow [
	"ApptiveGrid offers every non-abstract node class to its client as a type to pick;
	the client knows no deferred choice yet, so the class reads abstract the way
	FBRemoteFlowTask and FBTerminateEvent do - and stays instantiable"
	self assert: FBDeferredChoice isAbstract.
	self assert: (FBDeferredChoice named: 'choice') isDeferredChoice
]
