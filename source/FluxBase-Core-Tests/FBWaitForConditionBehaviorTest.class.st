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

{ #category : 'tests' }
FBWaitForConditionBehaviorTest >> testResumingAConditionWaitBehindASplitCompletesTheJoin [
	"the branch identity a join reads has to survive a condition wait. It does, but not
	the way a suspended flow form's does: FBFlowInstance>>resumeWaitingAt:with: takes
	the suspended activation back up (#activationOf:) instead of minting a fresh one, so
	its own token - #splitId included - is still attached and there is nothing to
	restore. This is what makes the missing suspension token of a condition wait
	harmless today, see #testAConditionWaitStoresNoTokenForItsSuspension.

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
FBWaitForConditionBehaviorTest >> testAConditionWaitStoresNoTokenForItsSuspension [
	"unlike a trigger-requiring node, whose transition is suspended together with the
	token it would have been activated with, a condition wait suspends through the
	single-argument FBBaseActivation>>waitForNode: - which passes withToken: nil. So
	#takeTokenForSuspended: answers nil here in every case, not because a second
	suspension overwrote a first (see
	FBParallelExecutorTest>>testEverySuspensionOfOneTransitionKeepsItsOwnToken) but
	because nothing was ever put there.

	Harmless as long as resuming takes the suspended activation back up rather than
	minting a fresh one - #testResumingAConditionWaitBehindASplitCompletesTheJoin is
	the guard for that. Once a condition wait does store its token, this test is the
	one to change."
	| flow waitNode instance executor |
	flow := FBFlow simpleWaitFlow.
	waitNode := flow start outgoing first target.
	instance := flow newInstance.
	instance executeWith: 4.

	self assert: instance suspended asArray equals: { waitNode }.
	executor := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	self assert: (executor takeTokenForSuspended: waitNode) isNil
]
