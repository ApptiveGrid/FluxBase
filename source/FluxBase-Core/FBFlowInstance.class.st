Class {
	#name : 'FBFlowInstance',
	#superclass : 'Object',
	#instVars : [
		'id',
		'flow',
		'executor',
		'announcer',
		'events',
		'activations',
		'metadata',
		'joinStates',
		'splitBranchCounts',
		'subFlowInstances',
		'scope',
		'waitingRegistry'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBFlowInstance >> aboutToTransition: aNode [
	"subclasses can overwrite this method to act before a transition
	is taken. This enables checks if a transition is possible before
	adding an activation for it"
]

{ #category : 'convenience' }
FBFlowInstance >> activate: anActivation [ 
	self addEvent: (FBNodeActivationStarted new
		activation: anActivation).
	anActivation activate.
	self addEvent: (FBNodeActivationDone new
		activation: anActivation)

]

{ #category : 'convenience' }
FBFlowInstance >> activateProtected: activation [
	[ [ self activate: activation ]
		on: FBError  
		do: [ :error |
			activation errored.
			self addEvent: (FBNodeActivationErrored new 
				activation: activation;
				activationError: error messageText)  ] ]
		on: Error 
		do: [ :error | 
			activation errored.
			self addEvent: (FBNodeActivationErrored new 
				activation: activation;
				activationError: error messageText).
			error pass ]
]

{ #category : 'accessing' }
FBFlowInstance >> activationClass [
	^ flow activationClass
]

{ #category : 'accessing' }
FBFlowInstance >> activeExecutors [
    "every executor that can currently hold a waiting node: this instance's own plus
    those of the flow instances executing inside it. the single traversal both
    #suspended and #resumeWaitingAt:with: work off, kept in instance order so the
    outermost instance is searched first"
    ^ self activeFlowInstances flatCollect: [ :each | each executors ]
]

{ #category : 'accessing' }
FBFlowInstance >> activeFlowInstances [
    "this instance followed by the flow instances currently executing inside it,
    outermost first. each sub flow call pushes a FBSubFlowExecutor frame onto the
    caller's executor stack, and that frame's child instance is the next link. sub
    flow calls are synchronous, so only the last instance of this chain is ever
    advancing and the chain is the path a step takes down into the nested flows.
    its length is bounded by FBSubFlowNode>>maxDepth"
    | instances current |
    instances := OrderedCollection with: self.
    current := self.
    [ current := current activeSubFlowInstance. current notNil ] whileTrue: [
        instances add: current ].
    ^ instances
]

{ #category : 'accessing' }
FBFlowInstance >> activeSubFlowInstance [
    "the sub flow instance of the frame on top of this instance's executor stack, nil
    when this instance is not currently inside a sub flow call. a sub flow pushes its
    own frames onto its own stack, so the top frame here is always the sub flow call
    this instance itself is suspended in"
    ^ (executor notNil and: [ executor isSubFlow ])
        ifTrue: [ executor childInstance ]
        ifFalse: [ nil ]
]

{ #category : 'accessing' }
FBFlowInstance >> activationOfNode: aFBNode [
	^ self activations 
		detect: [ :each | each node = aFBNode ]
		ifNone: [ Error signal: 'no activation found for node' ]
]

{ #category : 'accessing' }
FBFlowInstance >> activations [ 
	^ activations
]

{ #category : 'events' }
FBFlowInstance >> addEvent: aFBFlowEvent [
	events ifNil: [ events := OrderedCollection new ].
	events add: (aFBFlowEvent
			 flowInstance: self;
			 yourself).
	self announce: aFBFlowEvent
]

{ #category : 'accessing' }
FBFlowInstance >> addSubFlowInstance: aFBFlowInstance [
    self subFlowInstances add: aFBFlowInstance
]

{ #category : 'announcements' }
FBFlowInstance >> announce: aFBModelEvent [
	announcer ifNil: [ announcer := Announcer new ].
	announcer announce: aFBModelEvent 
]

{ #category : 'accessing' }
FBFlowInstance >> announcer [
	^ announcer
]

{ #category : 'accessing' }
FBFlowInstance >> atEnd [
	^ (executor = self rootExecutor) and: [
		self executors allSatisfy: [ :each | each atEnd ]
		].
]

{ #category : 'finalization' }
FBFlowInstance >> buildRootExecutor [
	^ FBFlowExecutor new 
			flowInstance: self;
			scheduleStart 
]

{ #category : 'accessing' }
FBFlowInstance >> events [
	^ events 
]

{ #category : 'accessing' }
FBFlowInstance >> eventsOfActivation: aFBActivation [ 
	^ self events select: [ :each | (each isKindOf: FBNodeActivationEvent) and: [ each activation = aFBActivation ] ]
]

{ #category : 'events' }
FBFlowInstance >> eventsOfNode: aFBNode [
	^ (self activationOfNode: aFBNode) ifNotNil: [ :activation | activation events ]
]

{ #category : 'executing' }
FBFlowInstance >> execute [ 
	self initializeExecutor.
	[  self executor hasPending ] whileTrue: [
		executor step ]

]

{ #category : 'executing' }
FBFlowInstance >> executeWith: anObject [
	self initialValue: anObject.
	self execute
]

{ #category : 'accessing' }
FBFlowInstance >> executor [ 
	^ executor 
]

{ #category : 'accessing' }
FBFlowInstance >> executors [
	"the live executor stack, outermost first - derived from #executor and the
	#suspendedExecutor chain rather than stored, which is the same set of links
	FBBaseExecutor>>rootExecutor already walks.

	it used to be an instance variable that #pushExecutor: appended to and
	#popExecutor: never removed from, so it accumulated every executor any scope had
	ever opened. that is what let #parallelExecutorFrom:ifAbsent: answer a finished
	executor from an earlier iteration of an enclosing parallel scope - see
	FBFlowTest>>testNestedParallelNodeInnerForkOutputFollowsRunningIteration.
	deriving it makes the accumulation unrepresentable instead of relying on every
	push/pop path to keep a second structure in agreement with #executor"

	| stack current |
	stack := OrderedCollection new.
	current := executor.
	[ current notNil ] whileTrue: [
		stack addFirst: current.
		current := current suspendedExecutor ].
	^ stack
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> expectedBranchCountFor: aSplitId [
	splitBranchCounts ifNil: [ ^ nil ].
	^ splitBranchCounts at: aSplitId ifAbsent: [ nil ]
]

{ #category : 'accessing' }
FBFlowInstance >> flow [
	^ flow
]

{ #category : 'accessing' }
FBFlowInstance >> flow: aFBFlow [ 
	flow := aFBFlow 
]

{ #category : 'testing' }
FBFlowInstance >> hasErrors [
	"whether any activation of this instance errored.

	the fact belongs here, not on the executor: FBBaseExecutor>>hasErrors answers it
	from #activations, which is this instance's one collection shared by all of its
	executors - so every executor answered identically, and #state used to loop over
	the whole stack asking the same question once per executor"

	^ activations anySatisfy: [ :each | each hasError ]
]

{ #category : 'accessing' }
FBFlowInstance >> id [

	^ id
]

{ #category : 'accessing' }
FBFlowInstance >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
FBFlowInstance >> initialValue: anObject [
	self initializeExecutor.
	self executor initialValue: anObject
]

{ #category : 'initialization' }
FBFlowInstance >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId.
	activations := OrderedCollection new
]

{ #category : 'accessing' }
FBFlowInstance >> initializeExecutor [
	executor ifNotNil: [ ^ self ].
	executor := self buildRootExecutor
]

{ #category : 'accessing' }
FBFlowInstance >> innermostWaitingExecutor [
    "the deepest executor of the active stack that has something suspended, or nil.

    #activeExecutors is outermost-first, so the last match is the innermost one - the
    executor that suspended most recently, which is what a caller means by 'the node
    execution just stopped on'. asking #executor directly is not the same thing: a sub
    flow call leaves an FBSubFlowExecutor current whose own #suspended is empty by
    design (see FBSubFlowExecutor>>suspended) while the wait sits in the child
    instance's executor one level in, so #executor answers nothing was suspended for
    an instance that is in fact blocked.

    use #suspended instead when the question is what blocks the instance at all rather
    than where it stopped last"

    ^ self activeExecutors reversed
          detect: [ :each | each suspended notEmpty ]
          ifNone: [ nil ]
]

{ #category : 'testing' }
FBFlowInstance >> isDone [
	^ executor isDone
]

{ #category : 'testing' }
FBFlowInstance >> isRootExecutor [

	^ self rootExecutor = self executor
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> joinStateFor: aNode splitId: aSplitId [
	| registeredCount |
	joinStates ifNil: [ joinStates := Dictionary new ].
	^ joinStates
		at: { aNode. aSplitId }
		ifAbsentPut: [ 
			registeredCount := self expectedBranchCountFor: aSplitId.
			FBJoinState new
				joinNode: aNode;
				splitId: aSplitId;
				expected: (registeredCount
					ifNil: [ aNode incoming asOrderedCollection ]
					ifNotNil: [ Array new: registeredCount ]);
				yourself ]
]

{ #category : 'accessing' }
FBFlowInstance >> metadata [
	
	^ metadata ifNil: [ FBProperties new]
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: aString [ 
	metadata ifNil: [ KeyNotFound signalFor: aString ].
	^ self metadata at: aString
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key ifAbsent: aBlock [
	metadata ifNil: [ ^ aBlock value ].
	^ self metadata 
		at: key 
		ifAbsent: aBlock
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key ifPresent: aBlock [
	metadata ifNil: [ ^ nil ].
	^ self metadata 
		at: key 
		ifPresent: aBlock
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key put: anObject [ 
	metadata ifNil: [ metadata := FBProperties new ].
	self metadata  
		at: key 
		put: anObject
]

{ #category : 'instance creation' }
FBFlowInstance >> newActivation [ 
	self initializeExecutor.
	^ executor newActivation 
]

{ #category : 'accessing' }
FBFlowInstance >> nextNode [
	^ self nextTransition target
]

{ #category : 'accessing' }
FBFlowInstance >> nextTransition [
	"the transition the next step will follow. #firstPending answers the queued work
	item that holds it, so unwrap it here - a work item is not a transition and must
	not pass as one. An entry read back out of a store written before FBWorkItem
	existed is a raw FBTransition and answers itself (FBTransition>>transition)"

	^ executor firstPending transition
]

{ #category : 'accessing' }
FBFlowInstance >> openWaitingEntries [
	"every externally reachable waiting spot open in me or in a flow instance executing
	inside me, outermost first - for monitoring, and for finding a waiting spot that
	nothing outside can reach any more.

	The same view over the chain of active instances that #suspended is over their
	executors, one level up"

	^ self activeFlowInstances flatCollect: [ :each | each waitingRegistry entries ]
]

{ #category : 'accessing' }
FBFlowInstance >> parallelExecutorFrom: aNode ifAbsent: aBlock [
	"#executors is the live stack, so this can only ever answer a scope that is currently
	open - never a finished executor from an earlier iteration of an enclosing parallel
	scope, which is what the stored collection used to allow"

	^ self executors detect: [ :each | each isParallel and: [ each node = aNode ] ] ifNone: aBlock
]

{ #category : 'accessing' }
FBFlowInstance >> pending [
	^ self executor pending
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> popExecutor: anExecutor [ 
	executor := anExecutor
]

{ #category : 'printing' }
FBFlowInstance >> printOn: aStream [ 
	aStream << 'flow instance id=' << id asString
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> pushExecutor: anExecutor [
	"#suspendedExecutor is the only link that has to be set here: #executors is derived
	from it, so there is no second structure left to keep in agreement"

	executor := anExecutor
		flowInstance: self;
		suspendedExecutor: executor;
		yourself
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> registerExpectedBranchCount: aCount forSplitId: aSplitId [
	splitBranchCounts ifNil: [ splitBranchCounts := Dictionary new ].
	splitBranchCounts at: aSplitId put: aCount
]

{ #category : 'executing' }
FBFlowInstance >> registerWaitingToken: aToken suspendedAt: anObject [
	"make one waiting spot of mine reachable from outside and answer its entry. Called
	on request: being reachable is a release rather than something every wait gets, see
	FBNode>>isExternallyResumable.

	Registers here, on the instance whose executor holds the suspension - a wait inside
	a sub flow therefore belongs to the child instance, which holds no reference back to
	its caller. Reading it back goes through #waitingEntryFor:, which walks the chain"

	waitingRegistry ifNil: [ waitingRegistry := FBWaitingRegistry new ].
	^ waitingRegistry registerToken: aToken suspendedAt: anObject
]

{ #category : 'executing' }
FBFlowInstance >> resumeWaitingAt: aNode with: aValue [
	"look for the waiting node in this instance's own executors and in those of the
	flow instances executing inside it, so that a wait modelled inside a sub flow can
	be resumed through the outermost instance. resuming is addressed by node identity
	alone, so a node waiting in more than one instance of a recursive sub flow call
	resolves to the outermost one - the same ambiguity the node already has across the
	iterations of a parallel scope"
	| holder activation |
	holder := self activeExecutors
		detect: [ :each | each suspended includes: aNode ]
		ifNone: [ ^ FBNodeNotWaiting signal: 'node is not currently waiting' ].
	activation := holder activationOf: aNode.
	holder suspended remove: aNode.
	activation value: aValue.
	activation followAllOutgoing.
]

{ #category : 'finalization' }
FBFlowInstance >> rootExecutor [
	^ executor rootExecutor
]

{ #category : 'accessing' }
FBFlowInstance >> scope [
    "my root scope, or nil while nothing has needed one - a flow without a sub flow call
    never opens a scope at all.

    deliberately a plain reader. it used to create the root scope on first read and
    assign it, which is a write on read: on an instance materialized in a read-only
    transaction that marks it dirty and signals SoilWriteOnReadOnlyTransaction, which
    left a Zinc worker hanging on an unhandled error and made
    AGExternalFlowHookTest>>testPostToExternalHook time out without ever naming a cause.
    FBSubFlowBehavior>>buildChildScope creates it instead, where it is first needed and
    where a write transaction is guaranteed. Same hazard, same resolution as
    FBFlowInstance>>metadata and FBBaseActivation>>token, whose comment names it
    'Modification on Read'"

    ^ scope
]

{ #category : 'accessing' }
FBFlowInstance >> scope: aFBScope [
    scope := aFBScope
]

{ #category : 'accessing' }
FBFlowInstance >> start [
	^ flow start
]

{ #category : 'accessing' }
FBFlowInstance >> state [

	(executor isNil or: [self rootExecutor isCreated]) ifTrue: [ ^ #created ].
	self hasErrors ifTrue: [ ^ #error ].
	(self executors anySatisfy:[:each | each isWaiting])  ifTrue: [ ^ #waiting ].
	(self executors allSatisfy:[:each | each isDone]) ifTrue: [ ^ #done ].
	(self isRootExecutor not or: [self rootExecutor isRunning]) ifTrue: [ ^ #running ].

]

{ #category : 'executing' }
FBFlowInstance >> step [
	self initializeExecutor.
	^ self executor step
]

{ #category : 'accessing' }
FBFlowInstance >> subFlowInstances [
    ^ subFlowInstances ifNil: [ subFlowInstances := OrderedCollection new ]
]

{ #category : 'accessing' }
FBFlowInstance >> suspended [
	"every node currently waiting in this instance or in a flow instance executing
	inside it. a caller asking what blocks this instance must see the wait even when
	it is modelled inside a sub flow, since that is what #state reports as #waiting"

	^ self activeExecutors flatCollect: [ :each | each suspended ]
]

{ #category : 'executing' }
FBFlowInstance >> takeWaitingEntryFor: aCorrelationId [
	"answer the externally reachable waiting spot under aCorrelationId and forget it, or
	nil when no instance of my chain holds one. An unknown id and an already consumed one
	give the same answer and neither is an error - that is what a resume addressed by
	correlationId rests its idempotency on"

	self activeFlowInstances do: [ :each |
		| registry |
		registry := each waitingRegistry.
		(registry entryFor: aCorrelationId) ifNotNil: [ :entry |
			registry takeEntryFor: aCorrelationId.
			^ entry ] ].
	^ nil
]

{ #category : 'accessing' }
FBFlowInstance >> waitingEntryFor: aCorrelationId [
	"the externally reachable waiting spot under aCorrelationId, in me or in a flow
	instance executing inside me, or nil. A pure read - it consumes nothing.

	Walks the chain for the same reason #resumeWaitingAt:with: searches #activeExecutors:
	a wait modelled inside a sub flow has to be reachable through the outermost instance,
	which is the one an outward address names. A remote sub flow is not in this chain and
	does not need to be - it runs as an instance of its own, under an address of its own.

	Answering nil for an id registered elsewhere is the check that the waiting spot really
	belongs to the addressed instance: the routing part of an address is useful redundancy,
	not the truth"

	self activeFlowInstances do: [ :each |
		(each waitingRegistry entryFor: aCorrelationId) ifNotNil: [ :entry | ^ entry ] ].
	^ nil
]

{ #category : 'accessing' }
FBFlowInstance >> waitingRegistry [
	"the directory of my own externally reachable waiting spots, or a fresh empty one
	when nothing has registered here yet.

	Deliberately answers a throwaway instead of creating and assigning one: assigning on
	a read marks me dirty, and on an instance materialized in a read-only transaction
	that signals SoilWriteOnReadOnlyTransaction - same hazard and same resolution as
	#metadata and #scope. So nothing may register through this getter;
	#registerWaitingToken:suspendedAt: is the path that creates the real one.

	Mine only. #waitingEntryFor: is the view across the instances executing inside me,
	the way #suspended is the view across their executors"

	^ waitingRegistry ifNil: [ FBWaitingRegistry new ]
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> whenAnnounced: aClass do: aBlock [

	announcer ifNil: [ announcer := Announcer new ].
	announcer when: aClass do: aBlock for: aBlock receiver
]
