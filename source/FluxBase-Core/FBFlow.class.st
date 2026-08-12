Class {
	#name : 'FBFlow',
	#superclass : 'Object',
	#instVars : [
		'name',
		'start',
		'nodesMap'
	],
	#classInstVars : [
		'activationClass',
		'transitionClass'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBFlow class >> activationClass [ 
	^ activationClass ifNil: [
		activationClass := self defaultActivationClass ]
]

{ #category : 'accessing' }
FBFlow class >> activationClass: anObject [

	activationClass := anObject
]

{ #category : 'as yet unclassified' }
FBFlow class >> complex [
	<sampleInstance>
	| start end one two three four five six seven eight nine |
	start := FBStartEvent new.
	end := FBEndEvent new.
	one := FBTask named: 'one'.
	two := FBTask named: 'two'.
	three := FBTask named: 'three'.
	four := FBTask named: 'four'.
	five := FBTask named: 'five'.
	six := FBTask named: 'six'.
	seven := FBTask named: 'seven'.
	eight := FBTask named: 'eight'.
	nine := FBTask named: 'nine'.
	
	start --> one --> two --> three --> four.
	three --> six.
	two --> five --> six.
	one --> seven --> eight.
	seven --> nine.
	^ FBFlow new start: start
]

{ #category : 'accessing' }
FBFlow class >> defaultActivationClass [
	^ FBActivation 
]

{ #category : 'accessing' }
FBFlow class >> defaultTransitionClass [
	^ FBTransition 
]

{ #category : 'tests' }
FBFlow class >> gatewayedFlow [ 
	<sampleInstance>
	| start end bigger smaller gateway value |
	start := FBStartEvent new.
	value := FBTestTask named: 'generate random number'.
	bigger := FBTask named: 'bigger'.
	smaller := FBTask named: 'smaller'.
	end := FBEndEvent new.
	gateway := (FBExclusiveGateway named: '>= 5 | < 5').
	gateway --> (bigger when: [:x | x >= 5 ]) --> end.
	gateway --> (smaller when: [:x | x < 5 ]) --> end.
	start --> value --> gateway.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> nestedParallelFlowImplicit [
	"same shape as #nestedParallelFlowJoined, but without any explicit join
	or end node at all - 'task' just dead-ends. Used to regression-test that
	FBNode>>effectiveOutgoingFor: correctly synthesizes an implicit join per
	scope (and, eventually, an implicit flow end) instead of the flow just
	silently stopping partway"
	<sampleInstance>
	| start outerFork innerFork task |
	start := FBStartEvent new.
	outerFork := start addOutgoingNode: (FBParallelNode named: 'outer fork').
	innerFork := outerFork addOutgoingNode: (FBParallelNode named: 'inner fork').
	task := innerFork addOutgoingNode: ((FBPluggableTask named: 'task') block: [ :activation | activation value: activation argument ]).

	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> nestedParallelFlowJoined [
	"a parallel node whose own branch contains another, nested parallel node
	(split into its own join before rejoining the outer split's join). Used to
	characterize/regression-test the 'parallel node in parallel node' bug:
	each outer iteration must see its own, correctly-scoped inner join result
	instead of leaking/crashing against a sibling iteration's state"
	<sampleInstance>
	| start end outerFork innerFork task innerJoin outerJoin |
	start := FBStartEvent new.
	outerFork := start addOutgoingNode: (FBParallelNode named: 'outer fork').
	innerFork := outerFork addOutgoingNode: (FBParallelNode named: 'inner fork').
	task := innerFork addOutgoingNode: ((FBPluggableTask named: 'task') block: [ :activation | activation value: activation argument ]).
	innerJoin := task addOutgoingNode: (FBParallelJoinNode named: 'inner join').
	outerJoin := innerJoin addOutgoingNode: (FBParallelJoinNode named: 'outer join').
	end := outerJoin addOutgoingNode: FBEndEvent new.

	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> parallelFlowJoined [ 
	<sampleInstance>
	| start end parallel p1 p2 join |
	start := FBStartEvent new.
	parallel := start addOutgoingNode: (FBParallelNode named: 'parallel fork').
	p1 := parallel addOutgoingNode: (FBTestTask named: 'p1 task').
	p2 := p1 addOutgoingNode: (FBTestTask named: 'p2 task').
	join := p2 addOutgoingNode: (FBParallelJoinNode named: 'join').
	end := join addOutgoingNode: FBEndEvent new.
	
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> parallelFlowNoOutgoing [
	"a parallel node with no outgoing transition at all - literally the last
	node in the flow, no loop body. Regression fixture for the 'never stops'
	bug (Board-Ticket CMSIs-lZ3HA)."
	<sampleInstance>
	| start |
	start := FBStartEvent new.
	start addOutgoingNode: (FBParallelNode named: 'parallel task').
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> parallelFlowOpen [
	<sampleInstance>
	| start end parallel p1 p2 |
	start := FBStartEvent new.
	parallel := start addOutgoingNode: (FBParallelNode named: 'parallel task').
	p1 := parallel addOutgoingNode: (FBTestTask named: 'p1 task').
	p2 := p1 addOutgoingNode: (FBTestTask named: 'p2 task').
	end := p2 addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> parallelFlowWaiting [
	<sampleInstance>
	| start end parallel p1 wait |
	start := FBStartEvent new.
	p1 := start addOutgoingNode: ((FBPluggableTask named: 'bypass') block: [ :activation | activation value: activation argument ]).
	parallel := p1 addOutgoingNode: (FBParallelNode named: 'parallel task').
	p1 addOutgoingNode:  (FBTestTask named: 'p2 task').
	wait := FBPluggableWait new condition: [ :x |false ]; yourself.
	p1 := parallel addOutgoingNode: (wait).
	end := wait addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> simpleFlow [ 
	<sampleInstance>
	| start end intermediate |
	start := FBStartEvent new.
	intermediate := start addOutgoingNode: (FBTask named: 'simple task').
	end := intermediate addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> simpleFlowWithError [
	<sampleInstance>
	| start end intermediate |
	start := FBStartEvent new.
	intermediate := start addOutgoingNode: (FBErrorTestTask  named: 'simple task with handled error').
	end := intermediate addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> simpleFlowWithSystemError [
	<sampleInstance>
	| start end intermediate |
	start := FBStartEvent new.
	intermediate := start addOutgoingNode: (FBSystemErrorTestTask  named: 'simple task with unhandled error').
	end := intermediate addOutgoingNode: FBEndEvent new.
	^ FBFlow new start: start
]

{ #category : 'tests' }
FBFlow class >> simpleWaitFlow [ 
	<sampleInstance>
	| start end wait |
	start := FBStartEvent new.
	end := FBEndEvent new.
	wait := FBPluggableWait new condition: [ :x | x odd ].
	start --> wait --> end.
	^ FBFlow new start: start
]

{ #category : 'accessing' }
FBFlow class >> transitionClass [ 
	^ transitionClass ifNil: [
		transitionClass := self defaultTransitionClass ]
]

{ #category : 'accessing' }
FBFlow class >> transitionClass: anObject [

	transitionClass := anObject
]

{ #category : 'as yet unclassified' }
FBFlow class >> withCycle [
	<sampleInstance>
	| start end one two three four five six seven eight nine |
	start := FBStartEvent new.
	end := FBEndEvent new.
	one := FBTask named: 'one'.
	two := FBTask named: 'two'.
	three := FBTask named: 'three'.
	four := FBTask named: 'four'.
	five := FBTask named: 'five'.
	six := FBTask named: 'six'.
	seven := FBTask named: 'seven'.
	eight := FBTask named: 'eight'.
	nine := FBTask named: 'nine'.
	
	start --> one --> two --> three --> four.
	three --> six.
	"add cycle"
	six --> five --> two.
	one --> seven --> eight.
	seven --> nine.
	nine --> five.
	^ FBFlow new start: start
]

{ #category : 'as yet unclassified' }
FBFlow class >> withCycleForce [
	<sampleInstance>
	| start end one two three four five six seven eight nine |
	start := FBStartEvent new.
	end := FBEndEvent new.
	one := FBTask named: 'one'.
	two := FBTask named: 'two'.
	three := FBTask named: 'three'.
	four := FBTask named: 'four'.
	five := FBTask named: 'five'.
	six := FBTask named: 'six'.
	seven := FBTask named: 'seven'.
	eight := FBTask named: 'eight'.
	nine := FBTask named: 'nine'.
	
	[ start --> one --> two --> three --> four.
	three --> six.
	"add cycle"
	six --> five --> two.
	one --> seven --> eight.
	seven --> nine.
	nine --> five ] 
		on: FBFlowIsCyclic 
		do: [:err | err resume ].
	^ FBFlow new start: start
]

{ #category : 'visiting' }
FBFlow >> acceptFluxBase: aFBVisitor [
	^ aFBVisitor visitFlow: self
]

{ #category : 'accessing' }
FBFlow >> activationClass [ 
	^ self class activationClass
]

{ #category : 'adding' }
FBFlow >> addNode: aFBNode [
	nodesMap 
		at: aFBNode id 
		ifAbsentPut: [ 
			aFBNode setFlow: self.
			aFBNode ]
	
	 
]

{ #category : 'removing' }
FBFlow >> basicRemoveNode: aNode [ 
	nodesMap removeKey: aNode id
]

{ #category : 'converting' }
FBFlow >> convertNode: aNode toClass: aClass [
	"Replace aNode -- one of my nodes -- with a new instance of aClass that
	preserves its id, name, properties, behaviorClass override, and
	connections (see FBNode>>convertTo:). Answers the new node. aNode ends
	up fully detached and unreferenced; there is nothing further to clean up
	on it.

	This is durable purely because FBNode is never itself a Soil root -- it
	only persists as part of its owning AGFlowHolder's cluster. If that ever
	changes (FBNode class>>isSoilClusterRoot, or AGFlowInstanceHook's
	transient `node` ivar becoming persisted), this method would also need
	to re-root/retire the old and new node objects explicitly."
	| newNode |
	(nodesMap at: aNode id ifAbsent: [ nil ]) == aNode
		ifFalse: [ FBNodeNotFound signal: 'node is not managed by this flow' ].
	newNode := aNode convertTo: aClass.
	nodesMap at: newNode id put: newNode.
	start == aNode ifTrue: [ start := newNode ].
	^ newNode
]

{ #category : 'accessing' }
FBFlow >> end [
	start ifNil: [ Error signal: 'Cannot find end without a start node being present' ].
	^ start findEnd
]

{ #category : 'accessing' }
FBFlow >> endNodes [
	^ self nodes select: [ :each | each isKindOf: FBEndEvent ]
]

{ #category : 'initialization' }
FBFlow >> initialize [ 
	super initialize.
	nodesMap := OrderedDictionary new
]

{ #category : 'accessing' }
FBFlow >> name [

	^ name
]

{ #category : 'accessing' }
FBFlow >> name: anObject [

	name := anObject
]

{ #category : 'instance creation' }
FBFlow >> newInstance [
	^ FBFlowInstance new 
		flow: self
]

{ #category : 'as yet unclassified' }
FBFlow >> nodeWithId: aString [ 
	^ self 
		nodeWithId: aString  
		ifAbsent: [ FBNodeNotFound signal: 'Node with id ', aString asString, ' not found' ]
]

{ #category : 'as yet unclassified' }
FBFlow >> nodeWithId: aString ifAbsent: aBlock [
	^ nodesMap 
		at: aString 
		ifAbsent: aBlock
]

{ #category : 'accessing' }
FBFlow >> nodeWithName: aString [ 
	^ nodesMap values 
		detect: [ :each | each name = aString ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
FBFlow >> nodes [
	^ nodesMap values
]

{ #category : 'removing' }
FBFlow >> removeNode: aNode [ 
	aNode detach.
	self basicRemoveNode: aNode
]

{ #category : 'accessing' }
FBFlow >> start [
	^ start ifNil: [ 
		start := (FBStartEvent named: #start) 
			flow: self;
			yourself ]
]

{ #category : 'accessing' }
FBFlow >> start: aFBStartEvent [ 
	aFBStartEvent flow: self.
	start := aFBStartEvent 
]

{ #category : 'accessing' }
FBFlow >> transitionClass [ 
	^ self class transitionClass 
]

{ #category : 'querying' }
FBFlow >> transitionWithId: aString [ 
	^ self 
		transitionWithId: aString 
		ifAbsent: [ FBTransitionNotFound signal: 'transition with id ', aString asString, ' not found' ]
]

{ #category : 'querying' }
FBFlow >> transitionWithId: aString ifAbsent: aBlock [
	nodesMap do: [ :node | 
		node outgoing 
			detect: [ :each | each id = aString ]
			ifFound: [ :transition | ^ transition ] ].
	^ aBlock value
]

{ #category : 'accessing' }
FBFlow >> validate [
	(FBTopologicalSorter new
			nodes: nodesMap values;
		isAcyclic)
		ifFalse: [ FBFlowIsCyclic signal: 'cycle detected'].
	self nodes do: [ :node |
		((node isKindOf: FBSplitGateway) and: [ node outgoing size < 2 ])
			ifTrue: [ FBGatewayMissingBranches signal: 'split gateway ''', node name asString, ''' needs at least 2 outgoing transitions' ].
		((node isKindOf: FBMergeGateway) and: [ node incoming size < 2 ])
			ifTrue: [ FBGatewayMissingBranches signal: 'merge gateway ''', node name asString, ''' needs at least 2 incoming transitions' ] ]
]
