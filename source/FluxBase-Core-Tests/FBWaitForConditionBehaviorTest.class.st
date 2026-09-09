Class {
	#name : 'FBWaitForConditionBehaviorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testAResumedWaitIsNoLongerWaiting [
	"the wait marks its strand #waiting when it parks, and the activation reads its state
	off that mark. The resume has to take the mark back: without it the strand - and
	the activation anyone looks at afterwards - would report #waiting for good"
	| instance wait activation |
	"the sample flow's wait parks on an even value"
	instance := FBFlow simpleWaitFlow newInstance.
	instance initialValue: 2.
	instance execute.
	self assert: instance state equals: #waiting.
	wait := instance suspended first.
	activation := instance activations detect: [ :each | each node == wait ].
	self assert: activation state equals: #waiting.
	self assert: activation token isWaiting.

	instance resumeWaitingAt: wait with: 7.

	self deny: activation token isWaiting.
	self deny: activation state = #waiting.
	instance execute.
	self assert: instance state equals: #done.
	self assert: activation state equals: #done
]

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testAWaitWhoseConditionHoldsIsDone [
	"a wait that does not have to wait is a finished step like any other and reads
	#done in the log - not #created, which is what it read while nothing marked it"
	| instance wait |
	instance := FBFlow simpleWaitFlow newInstance.
	instance initialValue: 3.
	instance execute.
	wait := instance flow nodes detect: [ :each | each isKindOf: FBWaitForCondition ].
	self assert: instance state equals: #done.
	self assert: (instance activations detect: [ :each | each node == wait ]) state equals: #done
]

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

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testResumingAConditionWaitBehindASplitCompletesTheJoin [
	"the branch identity a join reads has to survive a condition wait. It does, but not
	the way a suspended flow form's does: resuming a node takes the suspended activation
	back up (FBNode>>resumeIn:withToken:value:) instead of minting a fresh one, so
	its own token - #splitId included - is still attached and there is nothing to
	restore - the token it stores for its suspension
	(#testAConditionWaitStoresItsOwnTokenForItsSuspension) is what an entry in the
	waiting registry needs, not what this resume needs.

	A resume that mints a fresh activation instead, the way ApptiveBase resumes a flow
	form, would have to carry the token: measured on a flow shaped like this one, a
	fresh activation's default token has no #splitId, so it opens a second FBJoinState,
	each of the two holds one arrival, neither reaches its #expected of two - and the
	instance reports #done with everything behind the join left undone."
	| start split a wait join end flow instance |
	start := FBStartEvent new.
	split := start addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument ].
	wait := FBPluggableWait new condition: [ :each | false ]; yourself.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	split --> a --> join.
	split --> wait --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 42.

	"the scenario only holds if the wait really parks one of the two branches"
	self assert: instance state equals: #waiting.
	self assert: instance suspended asArray equals: { wait }.
	"and if that branch carries the split's identity while it is parked"
	self
		assert: (instance activations detect: [ :each | each node == wait ]) token splitId
		equals: (instance activations detect: [ :each | each node == a ]) token splitId.

	instance resumeWaitingAt: wait with: 7.
	instance execute.

	"both branches arrive at the join either way, so this is the scenario check rather
	than the assertion that discriminates"
	self assert: (instance activations select: [ :each | each node == join ]) size
		equals: 2.
	"reaching #end is what discriminates: with the branch identity lost, the join keeps
	both arrivals apart in two join states and releases neither, while #atEnd and
	#state still report the instance as finished"
	self assert: (instance activations anySatisfy: [ :each | each node == end ]).
	self assert: instance atEnd.
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testAConditionWaitStoresItsOwnTokenForItsSuspension [
	"a condition wait hands its token to the suspension like a trigger-requiring node
	does, and the token it hands over is its own - the strand it is standing on - not a
	child token, because resuming takes this very activation back up rather than spawning
	a new one.

	It used to pass withToken: nil through a one-argument #waitForNode:, which was
	harmless while resuming only ever took the parked activation back up
	(#testResumingAConditionWaitBehindASplitCompletesTheJoin is the guard for that). It
	stopped being harmless once a waiting spot could be registered for resuming from
	outside: FBWaitingEntry has to carry the parked strand, and this is the only place
	that knows it."
	| flow waitNode instance executor |
	flow := FBFlow simpleWaitFlow.
	waitNode := flow start outgoing first target.
	instance := flow newInstance.
	instance executeWith: 4.

	self assert: instance suspended asArray equals: { waitNode }.
	executor := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	self
		assert: (executor takeTokenForSuspended: waitNode)
		identicalTo: (instance activations detect: [ :each | each node == waitNode ]) token
]
