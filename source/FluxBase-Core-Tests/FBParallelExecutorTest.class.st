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

{ #category : 'tests' }
FBParallelExecutorTest >> testAnIterationsJoinStateFallsWithTheIteration [
	"every iteration of a parallel scope passes through the split again and is its own
	split execution with its own join state. The state falls with the iteration, not
	with the instance: the node behind the join sees one state on the first pass and
	still one on the second, because the first iteration's scope ended in between
	(FBFlowInstance>>scopeEnded:, FBParallelExecutor>>closeFinishedIterations). And a
	finished instance holds none"
	| start fork split a b join after end flow instance seen |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	split := fork addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act | act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	after := (FBPluggableTask named: 'after') block: [ :act |
		seen add: (act flowInstance instVarNamed: 'joinStates') size.
		act value: act argument ].
	split --> a --> join.
	split --> b --> join.
	join --> after.
	end := (after addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	self assert: instance state equals: #done.
	self assert: seen asArray equals: #( 1 1 ).
	self assert: (instance instVarNamed: 'joinStates') isNil
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
	| start fork split a b join after end flow instance splitIds afterRuns |
	splitIds := OrderedCollection new.
	afterRuns := 0.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	split := fork addOutgoingNode: (FBAndSplit named: 'split').
	a := (FBPluggableTask named: 'a') block: [ :act |
		splitIds add: act token splitId.
		act value: act argument + 1 ].
	b := (FBPluggableTask named: 'b') block: [ :act | act value: act argument * 10 ].
	join := FBAndJoin named: 'join'.
	after := (FBPluggableTask named: 'after') block: [ :act |
		afterRuns := afterRuns + 1.
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
	self assert: afterRuns equals: 2.
	"every iteration passes through the split again, so it is its own split execution
	and gets its own FBJoinState instead of finding the previous pass's already
	released one. Read off a branch: behind the join the token is a branch of the
	enclosing pass again, and the fork opens none"
	self assert: splitIds size equals: 2.
	self deny: (splitIds anySatisfy: [ :each | each isNil ]).
	self assert: splitIds asSet size equals: 2
]
{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testEverySuspensionOfOneTransitionKeepsItsOwnToken [
	"a parallel scope runs all its iterations in a single executor (its #suspended holds
	both suspensions below, the outer FBFlowExecutor holds none), so a trigger-requiring
	node inside the scope suspends the very same transition object once per iteration.
	FBBaseExecutor>>addWaiting:withToken: used to keep one token per suspended object,
	so the second suspension overwrote the first: the first resume took the second
	iteration's token and the second resume found none - and an activation resumed
	without its token loses its #splitId, so a join behind it never completes (see
	FBBaseActivation>>waitForNode:withToken:)"
	| start fork body trigger end flow instance executor suspensions tokens |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := fork addOutgoingNode: ((FBPluggableTask named: 'body') block: [ :act |
		act value: act argument ]).
	trigger := body addOutgoingNode: (FBTriggerTask named: 'trigger').
	end := trigger addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	"the scenario only holds if both iterations really suspend in one and the same
	executor, on one and the same transition object"
	self assert: (instance activeExecutors collect: [ :each | each suspended size ])
		asArray equals: #( 0 2 ).
	executor := instance activeExecutors detect: [ :each | each suspended notEmpty ].
	suspensions := executor suspended asArray.
	self assert: suspensions size equals: 2.
	self assert: suspensions first == suspensions second.

	tokens := suspensions collect: [ :each | executor takeTokenForSuspended: each ].
	self deny: (tokens anySatisfy: [ :each | each isNil ]).
	self assert: tokens asSet size equals: 2
]

{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testTokenOfAnExecutorPersistedWithASingleTokenPerSuspensionIsStillFound [
	"executors persisted while FBBaseExecutor>>addWaiting:withToken: kept one token per
	suspended object hold that token itself where a queue of them is now expected, so
	the reader has to tolerate both shapes - reaching into the ivar is the only way to
	produce the old one"
	| executor node token |
	executor := FBParallelExecutor new
		flowInstance: FBFlow simpleFlow newInstance;
		node: (FBParallelNode named: 'p');
		yourself.
	node := FBTask named: 'waiting'.
	token := FBToken new.
	executor instVarNamed: 'suspendedTokens' put: (IdentityDictionary new
		at: node put: token;
		yourself).
	self assert: (executor takeTokenForSuspended: node) == token.
	"and it is forgotten, exactly as a token taken out of a queue is"
	self assert: (executor takeTokenForSuspended: node) isNil
]

{ #category : 'tests' }
FBParallelExecutorTest >> testEachIterationRunsInItsOwnScope [
	"an iteration is a lifetime: its tokens live in a scope of their own, opened per
	iteration, owned by the fork and nested in the scope the fork ran in - the root
	scope here. Two iterations, two scopes, one outer"
	| start fork body end flow instance scopes |
	scopes := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act |
		scopes add: act token scope.
		act value: act argument ].
	fork --> body.
	end := (body addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).

	self assert: instance state equals: #done.
	self assert: scopes size equals: 2.
	self deny: scopes first == scopes second.
	self assert: (scopes allSatisfy: [ :each | each ownerNode == fork ]).
	self assert: (scopes allSatisfy: [ :each | each outer == instance scope ]).
	self assert: (scopes allSatisfy: [ :each | each callDepth = 0 ]).
	"the fork itself ran in the root scope"
	self assert: (instance activations detect: [ :each | each node == fork ]) token scope
		identicalTo: instance scope
]

{ #category : 'tests' }
FBParallelExecutorTest >> testAnIterationScopeKnowsItsIndex [
	| start fork body flow instance scopes |
	scopes := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act |
		scopes add: act token scope.
		act value: act argument ].
	fork --> body.
	(body addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 30 ).
	self assert: (scopes collect: [ :each | each index ]) asArray equals: #( 1 2 3 ).
	self assert: (scopes collect: [ :each | each iterationOwnedBy: fork ]) asArray equals: scopes asArray.
	self assert: (instance scope iterationOwnedBy: fork) isNil
]

{ #category : 'tests' }
FBParallelExecutorTest >> testALateResumedIterationWritesIntoItsOwnSlot [
	"two iterations wait; the second is resumed first, then the first. Each value has to
	land in the slot of its own iteration. The slot used to be the executor's cursor,
	which had moved on to the second iteration by the time the first went on - the
	first iteration's value overwrote the second's, and the node behind the scope join
	saw #(nil 'A')"
	| start fork wait after flow instance entries |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	after := (wait addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act | act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	entries := instance openWaitingEntries copy.
	self assert: entries size equals: 2.

	self assert: (instance signal: entries second correlationId with: 'B').
	instance execute.
	self assert: instance state equals: #waiting.
	self assert: (instance signal: entries first correlationId with: 'A').
	instance execute.

	self assert: instance state equals: #done.
	self assert: (instance activationOfNode: after) argument equals: #( 'A' 'B' )
]

{ #category : 'tests' }
FBParallelExecutorTest >> testTheLoopVariableFollowsTheIterationBeingStepped [
	"the fork's #output is the loop variable scripts read. While the first iteration,
	resumed late, runs its next node, it has to read the first element - not the one
	the cursor stands on, which is the second iteration's by then. Same for a
	predecessor's value: the probe's argument is its own iteration's wait result"
	| start fork wait probe seen flow instance entries |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	wait := fork addOutgoingNode: (FBExternalWait new condition: [ :each | false ]; yourself).
	probe := wait addOutgoingNode: ((FBPluggableTask named: 'probe') block: [ :act |
		seen add: (act instance activationOfNode: fork) output -> act argument.
		act value: act argument ]).
	(probe addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( 10 20 ).
	entries := instance openWaitingEntries copy.

	self assert: (instance signal: entries second correlationId with: 'B').
	instance execute.
	self assert: (instance signal: entries first correlationId with: 'A').
	instance execute.

	self assert: instance state equals: #done.
	self assert: seen asArray equals: { 20 -> 'B'. 10 -> 'A' }
]

{ #category : 'helpers' }
FBParallelExecutorTest >> loopOver: aCollection bodyWhen: aBlock into: aCollector [
	"start -> fork -> body (x2, when aBlock) -> scope join -> after -> end; after's
	argument is collected"
	| start fork body after flow instance |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act | act value: act argument * 2 ].
	fork --> (body when: aBlock).
	after := (body addOutgoingNode: (FBParallelJoinNode named: 'scope join'))
		addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act |
			aCollector add: act argument.
			act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: aCollection.
	^ instance
]

{ #category : 'tests' }
FBParallelExecutorTest >> testALastIterationFilteredByAConditionStillCompletesTheLoop [
	"the last iteration's body is filtered by the condition on the fork's outgoing: the
	loop is over all the same and the node behind the scope join runs, with a nil slot
	for the iteration that had no body. It used to run only when the last iteration
	itself passed the scope join - a filtered last iteration ended the flow silently"
	| seen instance |
	seen := OrderedCollection new.
	instance := self loopOver: #( 1 2 3 ) bodyWhen: [ :x | x < 3 ] into: seen.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( 2 4 nil ) }
]

{ #category : 'tests' }
FBParallelExecutorTest >> testALoopWhoseIterationsAreAllFilteredCompletesWithNothing [
	"no iteration ran a body: the loop completes with an empty result and the flow goes
	on behind it - the loop is one activity, not a join of independent strands"
	| seen instance |
	seen := OrderedCollection new.
	instance := self loopOver: #( 1 2 3 ) bodyWhen: [ :x | false ] into: seen.
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( nil nil nil ) }
]

{ #category : 'tests' }
FBParallelExecutorTest >> testAnEmptyInputCompletesTheLoopAtOnce [
	"nothing to iterate: the scope completes with an empty result and the flow goes on
	behind the loop. It used to end there, silently, with the fork left #created"
	| seen instance fork |
	seen := OrderedCollection new.
	instance := self loopOver: #( ) bodyWhen: [ :x | true ] into: seen.
	fork := instance flow nodes detect: [ :each | each name = 'fork' ].
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { #( ) }.
	self assert: (instance activationOfNode: fork) state equals: #done.
	self assert: instance isRootExecutor
]

{ #category : 'tests' }
FBParallelExecutorTest >> testTokensBehindTheScopeJoinBelongToTheForksStrand [
	"behind the loop the strand is the fork's again: the token of the node after the
	scope join lives in the fork's scope and descends from the fork's token - not from
	the last iteration's, whose scope is over"
	| seen instance fork after forkToken afterToken |
	seen := OrderedCollection new.
	instance := self loopOver: #( 1 2 ) bodyWhen: [ :x | true ] into: seen.
	fork := instance flow nodes detect: [ :each | each name = 'fork' ].
	after := instance flow nodes detect: [ :each | each name = 'after' ].
	forkToken := (instance activationOfNode: fork) token.
	afterToken := (instance activationOfNode: after) token.
	self assert: afterToken scope identicalTo: forkToken scope.
	self assert: (afterToken hasAncestor: forkToken).
	self assert: (afterToken scope iterationOwnedBy: fork) isNil
]

{ #category : 'tests' }
FBParallelExecutorTest >> testTheScopeJoinIsFoundPastAnInnerLoop [
	"the outer loop's last iteration is filtered, so the outer scope completes without an
	arrival and has to find its own join by itself - past the inner loop's join, which
	closes the inner scope only. The first outer iteration ran the inner loop and arrived
	with its result, the second left a nil slot"
	| start outer inner body seen after flow instance |
	seen := OrderedCollection new.
	start := FBStartEvent new.
	outer := start addOutgoingNode: (FBParallelNode named: 'outer').
	inner := FBParallelNode named: 'inner'.
	outer --> (inner when: [ :x | x size > 1 ]).
	body := inner addOutgoingNode: ((FBPluggableTask named: 'body') block: [ :act | act value: act argument * 2 ]).
	after := ((body addOutgoingNode: (FBParallelJoinNode named: 'inner join'))
		addOutgoingNode: (FBParallelJoinNode named: 'outer join'))
		addOutgoingNode: ((FBPluggableTask named: 'after') block: [ :act |
			seen add: act argument.
			act value: act argument ]).
	after addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: #( #( 1 2 ) #( 3 ) ).
	self assert: instance state equals: #done.
	self assert: seen asArray equals: { { #( 2 4 ). nil } }
]

{ #category : 'tests' }
FBParallelExecutorTest >> testEveryIterationRecordsTheTransitionItFollows [
	"a transition followed inside a parallel scope is recorded like one followed by the
	root executor - once per iteration that follows it, not for an iteration its
	condition holds back. The scope's log used to have no transitions at all"
	| seen instance body followed |
	seen := OrderedCollection new.
	instance := self loopOver: #( 1 2 3 ) bodyWhen: [ :x | x < 3 ] into: seen.
	body := instance flow nodes detect: [ :each | each name = 'body' ].
	followed := instance events select: [ :each |
		(each isKindOf: FBTransitionFollowed) and: [ each transition target == body ] ].
	self assert: followed size equals: 2.
	self assert: (followed collect: [ :each | each value ]) asArray equals: #( 1 2 ).
	self assert: instance state equals: #done
]

{ #category : 'tests' }
FBParallelExecutorTest >> testTheInstanceIsAskedBeforeEachIterationsTransition [
	"FBFlowInstance>>aboutToTransition: is asked once per iteration that follows the
	body's transition - what ApptiveBase counts its rate limits with, and what a loop
	used to bypass"
	| start fork body instance flow |
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act | act value: act argument ].
	fork --> (body when: [ :x | x < 3 ]).
	(body addOutgoingNode: (FBParallelJoinNode named: 'scope join')) addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := FBProbingFlowInstance new flow: flow.
	instance executeWith: #( 1 2 3 ).
	self assert: instance state equals: #done.
	self assert: (instance asked count: [ :each | each target == body ]) equals: 2
]

{ #category : 'tests' }
FBParallelExecutorTest >> testARefusedTransitionLeavesTheIterationsWorkQueued [
	"the hook refuses the second iteration's transition: the error comes out of the
	step, the work item stays queued as it does in the root executor, and nothing of
	that iteration ran"
	| start fork body instance flow ran |
	ran := OrderedCollection new.
	start := FBStartEvent new.
	fork := start addOutgoingNode: (FBParallelNode named: 'fork').
	body := (FBPluggableTask named: 'body') block: [ :act | ran add: act argument. act value: act argument ].
	fork --> body.
	(body addOutgoingNode: (FBParallelJoinNode named: 'scope join')) addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := FBProbingFlowInstance new flow: flow.
	instance refuseWith: [ :transition |
		(transition target == body and: [ instance executor currentIteration = 2 ])
			ifTrue: [ Error signal: 'refused' ] ].
	instance initialValue: #( 1 2 3 ).
	self should: [ instance execute ] raise: Error.
	self assert: ran asArray equals: #( 1 ).
	self assert: instance executor pending size equals: 1.
	self assert: instance executor pending first transition target identicalTo: body.
	self deny: (instance events anySatisfy: [ :each |
		(each isKindOf: FBTransitionFollowed) and: [ each transition target == body and: [ each value = 2 ] ] ])
]
