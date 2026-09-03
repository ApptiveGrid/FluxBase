Class {
	#name : 'FBParallelExecutorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testAddPendingKeepsTheTokenTheTransitionWasQueuedWith [
	| executor transition token workItem |
	executor := FBParallelExecutor new
		flowInstance: FBFlow simpleFlow newInstance;
		node: (FBParallelNode named: 'p');
		yourself.
	transition := FBTransition new.
	token := FBToken new.
	executor addPending: transition withToken: token.
	workItem := executor pending last.
	self assert: workItem class equals: FBWorkItem.
	self assert: workItem transition == transition.
	self assert: workItem token == token
]

{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testScopeBodyIsQueuedWithTheForksOwnChildToken [
	"the body of a parallel scope is queued by the executor itself rather than by an
	activation following its outgoing transitions, so nothing hands it a token. The
	fork's own child token is the one it has to run under - the same one
	FBBaseActivation>>followAllOutgoing would have produced outside a parallel scope -
	and a fresh one per iteration, so two passes through a split inside the scope stay
	distinguishable"
	| start fork body flow instance bodyTokens |
	bodyTokens := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := fork addOutgoingNode: ((FBPluggableTask named: 'body') block: [ :act |
		bodyTokens add: act token.
		act value: act argument ]).
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	self assert: bodyTokens size equals: 2.
	"the fork's activation is the parent of every iteration's token, and each iteration
	gets its own token rather than sharing one"
	self assert: (bodyTokens collect: [ :each | each parent node ]) asArray
		equals: { fork. fork }.
	self assert: bodyTokens asSet size equals: 2
]

{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testAndJoinInsideAParallelScopeReachesTheNodeBehindItOncePerIteration [
	"the token a transition is queued with carries the branch identity a join needs
	later (see FBToken). Inside a parallel scope it used to be dropped on queueing, so
	every node of the scope started from a fresh default token: both branches of the
	split arrived at the join without a #parent, collapsed onto a single #arrived entry
	(FBJoinBehavior>>arrivalKey), and the join never saw its second branch. Nothing
	behind the join ever ran - while the instance still reported itself #done, so the
	missing half of the result was invisible."
	| start fork split a b join after end flow instance splitIds |
	splitIds := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	split := fork addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	after := (FBPluggableTask named: 'after') block: [ :act |
		splitIds add: act token splitId.
		act value: act argument ].
	split --> a --> join.
	split --> b --> join.
	join --> after.
	end := (after addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	self assert: instance atEnd.
	self assert: instance state equals: #done.
	"the node behind the join runs once per iteration of the fork, not once for the
	whole scope - and never zero times"
	self assert: splitIds size equals: 2.
	self deny: (splitIds anySatisfy: [ :each | each isNil ]).
	"every iteration passes through the split again, so it is its own split execution
	and gets its own FBJoinState instead of finding the previous pass's already
	released one"
	self assert: splitIds asSet size equals: 2
]
