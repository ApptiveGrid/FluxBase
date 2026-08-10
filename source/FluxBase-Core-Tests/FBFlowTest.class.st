Class {
	#name : 'FBFlowTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBFlowTest >> testAllNodes [
	| flow |
	flow := FBFlow simpleFlow.
	self assert: flow nodes size equals: 3.
	self assert: flow end class equals: FBEndEvent
]

{ #category : 'tests' }
FBFlowTest >> testConvertNodeToClassPreservesBehaviorClassOverrideOnlyWhenSet [
	| flow start gateway a b end newGateway |
	flow := FBFlow new.
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'g'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	flow start: start.
	start --> gateway.
	gateway --> (a when: [ :x | x >= 5 ]) --> end.
	gateway --> (b when: [ :x | x < 5 ]) --> end.

	newGateway := flow convertNode: gateway toClass: FBMultiChoiceGateway.
	self assert: (newGateway instVarNamed: #behaviorClass) isNil.
	self assert: newGateway behaviorClass equals: FBMultiChoiceGatewayBehavior
]

{ #category : 'tests' }
FBFlowTest >> testConvertNodeToClassPreservesIdentityAndConnections [
	| flow start gateway a b end newGateway incomingTransition outgoingA outgoingB oldId |
	flow := FBFlow new.
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	end := FBEndEvent new.
	flow start: start.
	start --> gateway.
	gateway --> (a when: [ :x | x >= 5 ]) --> end.
	gateway --> (b when: [ :x | x < 5 ]) --> end.
	gateway propertyAt: #note put: 'a gateway'.
	oldId := gateway id.
	incomingTransition := start outgoing first.
	outgoingA := gateway outgoing first.
	outgoingB := gateway outgoing second.

	newGateway := flow convertNode: gateway toClass: FBMultiChoiceGateway.

	self assert: newGateway class equals: FBMultiChoiceGateway.
	self deny: newGateway == gateway.
	self assert: newGateway id equals: oldId.
	self assert: newGateway name equals: 'choice'.
	self assert: (newGateway propertyAt: #note) equals: 'a gateway'.

	self assert: (flow nodes includes: newGateway).
	self deny: (flow nodes includes: gateway).
	self assert: (flow nodeWithId: oldId) equals: newGateway.

	self assert: incomingTransition target equals: newGateway.
	self assert: outgoingA source equals: newGateway.
	self assert: outgoingB source equals: newGateway.
	self assert: newGateway incoming size equals: 1.
	self assert: newGateway outgoing size equals: 2
]

{ #category : 'tests' }
FBFlowTest >> testConvertNodeToClassSignalsWhenNodeNotManagedByFlow [
	| otherFlow node |
	otherFlow := FBFlow new.
	otherFlow start: FBStartEvent new.
	node := FBTask named: 'orphan'.
	otherFlow start --> node.

	self
		should: [ FBFlow new convertNode: node toClass: FBTask ]
		raise: FBNodeNotFound
]

{ #category : 'tests' }
FBFlowTest >> testCreateFlow [
	| start end intermediate flow |
	start := FBStartEvent new.
	intermediate := start addOutgoingNode: FBNode new.
	end := intermediate addOutgoingNode: FBEndEvent new.
	flow := FBFlow new 
		start: start.
	self assert: flow end equals: end.
	self assert: flow nodes size equals: 3.

]

{ #category : 'tests' }
FBFlowTest >> testCreateFlowEarlyStart [
	| start end intermediate flow |
	start := FBStartEvent new.
	flow := FBFlow new 
		start: start.
	intermediate := FBNode new.
	end := intermediate addOutgoingNode: FBEndEvent new.
	start addOutgoingNode: intermediate.
	
	self assert: flow end equals: end.
	self assert: flow nodes size equals: 3.

]

{ #category : 'tests' }
FBFlowTest >> testEndNodeManyIncoming [
	| flow |
	flow := FBFlow simpleFlow.
	self 
		shouldnt: [ flow end addIncomingNode: FBNode new ]
		raise: FBCannotAddTransition 
]

{ #category : 'tests' }
FBFlowTest >> testEndNodeNoOutgoing [
	| flow |
	flow := FBFlow simpleFlow.
	self 
		should: [ flow end addOutgoingNode: FBNode new ]
		raise: FBCannotAddTransition 
]

{ #category : 'tests' }
FBFlowTest >> testEndNodesFindsAllEndsInABranchingFlow [
	| start gateway a b successEnd failureEnd flow |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'choice'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	successEnd := FBEndEvent new.
	failureEnd := FBEndEvent new.

	start --> gateway.
	gateway --> (a when: [ :x | x > 0 ]) --> successEnd.
	gateway --> (b when: [ :x | x <= 0 ]) --> failureEnd.

	flow := FBFlow new start: start.

	self assert: flow endNodes size equals: 2.
	self assert: (flow endNodes includes: successEnd).
	self assert: (flow endNodes includes: failureEnd).
	self assert: (flow end isKindOf: FBEndEvent)
]

{ #category : 'tests' }
FBFlowTest >> testEndNodesFindsSingleEnd [
	| flow |
	flow := FBFlow simpleFlow.
	self assert: flow endNodes size equals: 1.
	self assert: flow endNodes anyOne equals: flow end
]

{ #category : 'tests' }
FBFlowTest >> testExecuteGatewayedFlow [ 
	| instance |
	instance := FBFlow gatewayedFlow newInstance.
	instance execute.
	self assert: instance atEnd 
]

{ #category : 'tests' }
FBFlowTest >> testExecuteSimpleFlow [ 
	| instance |
	instance := FBFlow simpleFlow newInstance.
	instance execute.
	self assert: instance atEnd 
]

{ #category : 'tests' }
FBFlowTest >> testFlowWithCycle [
	
	self 
		should: [ FBFlow withCycle ]
		raise: FBFlowIsCyclic 
	
]

{ #category : 'tests' }
FBFlowTest >> testIsCyclic [ 
	| flow |
	flow := FBFlow withCycleForce.
	self
		should: [ flow validate ]
		raise: FBFlowIsCyclic  
]

{ #category : 'tests' }
FBFlowTest >> testIsNotCyclic [ 
	| flow |
	flow := FBFlow complex.
	self
		shouldnt: [ flow validate ]
		raise: FBFlowIsCyclic  
]

{ #category : 'tests' }
FBFlowTest >> testNestedParallelNodeImplicitlyJoinsAndEnds [
	"regression test for making the implicit end of a flow/parallel scope
	real-but-invisible instead of purely inferred from 'nothing left to
	process': #nestedParallelFlowImplicit has no join or end node at all,
	yet each scope must still get its own synthesized (never persisted,
	never added to the flow's own node graph) join, and the whole flow its
	own synthesized end - functioning identically to the explicit case in
	#testNestedParallelNodeJoined/#testNestedParallelNodeJoinedOutput"
	| flow instance joins innerJoins outerJoins ends |
	flow := FBFlow nestedParallelFlowImplicit.
	instance := flow newInstance.
	instance executeWith: { #(1 2). #(3 4 5). #(6) }.

	self assert: instance state equals: #done.

	joins := instance activations select: [ :each |
		         each node isKindOf: FBParallelJoinNode ].
	"the inner (per-outer-iteration) implicit join collects each iteration's
	own flat list of items; the outer implicit join collects one entry per
	outer iteration, each of those entries being one of those flat lists -
	i.e. a collection of collections. that structural difference is what
	distinguishes them, since neither ever gets a name"
	innerJoins := joins select: [ :each |
		              each output noneSatisfy: [ :e | e isCollection ] ].
	outerJoins := joins reject: [ :each | innerJoins includes: each ].

	self assert:
		(innerJoins collect: [ :each | each output ]) asSet
		equals: (Set withAll: { #(1 2). #(3 4 5). #(6) }).

	self assert: outerJoins size equals: 1.
	self assert: outerJoins anyOne output
		equals: (Array with: #(1 2) with: #(3 4 5) with: #(6)).

	ends := instance activations select: [ :each | each node isKindOf: FBEndEvent ].
	self assert: ends size equals: 1
]

{ #category : 'tests' }
FBFlowTest >> testNestedParallelNodeJoined [
	"regression test: a parallel node nested inside another parallel node used
	to crash (index out of bounds) or silently duplicate/mix up values across
	outer iterations, because the inner join's activation - scoped to the
	inner (smaller) list - was read back using the outer executor's index"
	| flow instance innerJoin outerJoin |
	flow := FBFlow nestedParallelFlowJoined.
	innerJoin := flow nodes detect: [ :each | each name = 'inner join' ].
	outerJoin := flow nodes detect: [ :each | each name = 'outer join' ].
	instance := flow newInstance.
	instance executeWith: { #(1 2). #(3 4 5). #(6) }.

	self assert: instance atEnd.
	self assert: instance state equals: #done.

	"each outer iteration gets its own inner join activation, holding exactly
	that iteration's (and only that iteration's) inner results"
	self assert:
		((instance activations select: [ :each | each node = innerJoin ])
			collect: [ :each | each instVarNamed: #values ])
		equals: (OrderedCollection with: #(1 2) with: #(3 4 5) with: #(6)).

	"the single, reused outer join activation gathers one entry per outer
	iteration, each being that iteration's full inner join result"
	self assert:
		((instance activations select: [ :each | each node = outerJoin ])
			collect: [ :each | each instVarNamed: #values ])
		equals: (OrderedCollection with: (Array with: #(1 2) with: #(3 4 5) with: #(6)))
]

{ #category : 'tests' }
FBFlowTest >> testNestedParallelNodeJoinedOutput [
	"companion to #testNestedParallelNodeJoined, checking #output (what a
	flow-run inspector displays) rather than the raw #values ivar: a join
	node's own activation isn't a parallel/split node, so it never goes
	through FBParallelNode>>outputFor:'s #parallelExecutorFrom: lookup -
	#output has to resolve straight to the join's own already-aggregated
	#value instead, regardless of nesting or which executor created it"
	| flow instance innerJoin outerJoin |
	flow := FBFlow nestedParallelFlowJoined.
	innerJoin := flow nodes detect: [ :each | each name = 'inner join' ].
	outerJoin := flow nodes detect: [ :each | each name = 'outer join' ].
	instance := flow newInstance.
	instance executeWith: { #(1 2). #(3 4 5). #(6) }.

	self assert:
		((instance activations select: [ :each | each node = innerJoin ])
			collect: [ :each | each output ])
		equals: (OrderedCollection with: #(1 2) with: #(3 4 5) with: #(6)).

	self assert:
		((instance activations select: [ :each | each node = outerJoin ])
			collect: [ :each | each output ])
		equals: (OrderedCollection with: (Array with: #(1 2) with: #(3 4 5) with: #(6)))
]

{ #category : 'tests' }
FBFlowTest >> testNestedParallelNodePassesInnerElements [
    | start outer inner collect end flow instance seen |

    seen := OrderedCollection new.

    start := FBStartEvent new.
    outer := start addOutgoingNode: (FBParallelNode named: 'outer').
    inner := outer addOutgoingNode: (FBParallelNode named: 'inner').

    collect := inner addOutgoingNode:
        ((FBPluggableTask named: 'collect')
            block: [ :activation |
                seen add: activation argument.
                activation value: activation argument.
                activation done ];
            yourself).

    end := collect addOutgoingNode: FBEndEvent new.

    flow := FBFlow new start: start.
    instance := flow newInstance.

    instance executeWith: { #(1 2). #(3 4) }.

    self assert: seen asArray equals: #(1 2 3 4)
]

{ #category : 'tests' }
FBFlowTest >> testNodeWithId [
	| flow id |
	flow := FBFlow simpleFlow.
	id := flow start id.
	self assert: (flow nodeWithId: id) equals: flow start
]

{ #category : 'tests' }
FBFlowTest >> testNodeWithIdError [
	| flow |
	flow := FBFlow simpleFlow.
	self 
		should: [ flow nodeWithId: #bogus ]
		raise: FBNodeNotFound 
]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeAsLastNodeStops [
	"regression test: a parallel node with no outgoing transition (literally
	the last node in the flow, no loop body) used to leave the flow instance
	stuck forever - pushExecutor: seeded the new FBParallelExecutor's pending
	from node outgoing, which was empty, so the driving loop in
	FBFlowInstance>>execute exited without ever popping the executor back to
	its parent, leaving #atEnd permanently false. Board-Ticket CMSIs-lZ3HA."
	| flow instance |
	flow := FBFlow parallelFlowNoOutgoing.
	instance := flow newInstance.
	instance executeWith: { 1. 2. 3 }.
	self assert: instance atEnd.
	self assert: instance state equals: #done.
	"no parallel executor should have been initialized as there was no outgoing node to fan out to"
	self assert: instance executors size equals: 1.
]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeEmptyList [
	| flow instance |
	flow := FBFlow parallelFlowOpen.
	instance := flow newInstance.
	instance executeWith: { }.
	self assert: instance atEnd.
	self assert: instance state equals: #done.
	"there should be one activation per node. The flow should have stopped at the parallel node because the collection was empty"
	self assert: instance activations size equals:  2.

]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeJoined [
	| flow instance |
	flow := FBFlow parallelFlowJoined.
	instance := flow newInstance.
	instance executeWith: { 1 . 2 . 3 }.
	self assert: instance atEnd.

]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeOpenEnd [
	| flow instance |
	flow := FBFlow parallelFlowOpen.
	instance := flow newInstance.
	instance executeWith: { 1 . 2 . 3 }.
	self assert: instance atEnd.
	self assert: instance state equals: #done.
	"there should be one activation per node.
	The activation for a parallel node is specific and holds collection of arguments and values"
	self assert: instance activations size equals: flow nodes size

]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeStepping [
	| flow instance activation |
	flow := FBFlow parallelFlowOpen.
	instance := flow newInstance.
	instance initialValue: { 1 . 2 . 3 }.
	instance step; step; step.
	activation := instance activations detect: [ :each | each isKindOf: FBParallelActivation ].
	self deny: instance state equals: #done.
]

{ #category : 'tests' }
FBFlowTest >> testParallelNodeWaiting [
	| flow instance |
	flow := FBFlow parallelFlowWaiting.
	instance := flow newInstance.
	instance executeWith: { 1 . 2 . 3 }.
	self deny: instance atEnd.
	self assert: instance pending isEmpty.
	self assert: instance state equals: #waiting.
	self assert: instance suspended size equals: 3

]

{ #category : 'tests' }
FBFlowTest >> testRemoveNode [
	| flow intermediate |
	flow := FBFlow simpleFlow.
	intermediate := flow start outgoing first target.
	intermediate remove.
	self assert: flow nodes size equals: 2
]

{ #category : 'tests' }
FBFlowTest >> testRemoveNodeFlow [
	| flow intermediate |
	flow := FBFlow simpleFlow.
	intermediate := flow start outgoing first target.
	flow removeNode: intermediate.
	self assert: flow nodes size equals: 2
]

{ #category : 'tests' }
FBFlowTest >> testRemoveTransitionWithId [
	| flow transition t |
	flow := FBFlow simpleFlow.
	transition := flow start outgoing first.
	self assert: (flow transitionWithId: transition id) equals: transition.
	transition detach.
	t := flow transitionWithId: transition id ifAbsent: nil.
	self assert: t isNil
]

{ #category : 'tests' }
FBFlowTest >> testStartNodeNoIncoming [
	| flow |
	flow := FBFlow simpleFlow.
	self 
		should: [ flow start addIncomingNode: FBNode new ]
		raise: FBCannotAddTransition 
]

{ #category : 'tests' }
FBFlowTest >> testStartNodeOneOutgoing [
	| flow |
	flow := FBFlow simpleFlow.
	self 
		should: [ flow start addOutgoingNode: FBNode new ]
		raise: FBCannotAddTransition 
]

{ #category : 'tests' }
FBFlowTest >> testTransitionWithId [
	| flow transition |
	flow := FBFlow simpleFlow.
	transition := flow start outgoing first.
	self assert: (flow transitionWithId: transition id) equals: transition
]

{ #category : 'as yet unclassified' }
FBFlowTest >> testValidatePassesForWellFormedSplitAndMergeGateways [
	| start gateway a b merge end flow |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'g'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	merge := FBSimpleMerge named: 'm'.
	end := FBEndEvent new.
	start --> gateway.
	gateway --> (a when: [ :x | x >= 5 ]) --> merge.
	gateway --> (b when: [ :x | x < 5 ]) --> merge.
	merge --> end.
	flow := FBFlow new start: start.
	self shouldnt: [ flow validate ] raise: FBGatewayMissingBranches
]

{ #category : 'as yet unclassified' }
FBFlowTest >> testValidateSignalsWhenMergeGatewayHasFewerThanTwoIncoming [
	| start merge a end flow |
	start := FBStartEvent new.
	merge := FBSimpleMerge named: 'm'.
	a := FBTask named: 'a'.
	end := FBEndEvent new.
	start --> a --> merge --> end.
	flow := FBFlow new start: start.
	self
		should: [ flow validate ]
		raise: FBGatewayMissingBranches
]

{ #category : 'as yet unclassified' }
FBFlowTest >> testValidateSignalsWhenSplitGatewayHasFewerThanTwoOutgoing [
	| start gateway a end flow |
	start := FBStartEvent new.
	gateway := FBExclusiveGateway named: 'g'.
	a := FBTask named: 'a'.
	end := FBEndEvent new.
	start --> gateway.
	gateway --> (a when: [ :x | true ]) --> end.
	flow := FBFlow new start: start.
	self
		should: [ flow validate ]
		raise: FBGatewayMissingBranches
]
