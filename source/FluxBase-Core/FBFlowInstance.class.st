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
	"run one activation, and notice when it was the last.

	Every activation of every executor of mine passes through here - a step of the root
	executor, a parallel iteration, a resume from outside, a child node of a sub flow
	(through the child instance's own #activateProtected:) - so this is the one boundary
	at which 'the instance is over' can be asked honestly, whichever loop drives the
	steps. #atEnd is false while a scope or sub flow frame is on top, and the moments
	when nothing is pending or suspended only because a transition is half made lie
	inside FBBaseExecutor>>resume:withToken:value:, not at this boundary.

	An instance that errored has stopped rather than ended: the error event stays its
	last word and its run bookkeeping stays for inspection, see #ended"

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
			error pass ].
	(self atEnd and: [ self hasErrors not ]) ifTrue: [ self ended ]
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

{ #category : 'executing' }
FBFlowInstance >> descendFrom: aToken [
	"my first strand descends from aToken - the token of the activation that calls me as a
	sub flow. #scheduleStart queued my start without a token so that the start activation
	mints a root token; put one on that work item instead, and FBFlowExecutor>>step hands
	it to the start activation the way it hands every other queued token on.

	Only #parent is set, not #splitId or #scope: a sub flow is a call, not a branch of the
	caller's split, and it opens a scope of its own (FBSubFlowBehavior>>buildChildScope).
	Sequence, not nesting - the same relation FBBaseActivation>>childToken records.

	This is what lets an address handed out in the calling instance reach a wait in me:
	FBWaitingReservation resolves by token ancestry, and without this link no token of mine
	descended from anything outside. It is also the one reference from a child back up -
	through the token, not the instance - and FBBaseActivation>>waitForNode:withToken:
	uses it to find a reservation made upstream"

	self initializeExecutor.
	executor firstPending token: (FBToken new parent: aToken; yourself)
]

{ #category : 'executing' }
FBFlowInstance >> dropWaitingEntriesMatching: aSuspension [
	"forget every address of mine that names aSuspension - the step a continuation makes
	before it takes the suspension out, see FBBaseExecutor>>resume:withToken:value:.

	Mine only, by design: an entry is registered on the instance whose executor holds the
	suspension (FBBaseActivation>>waitForNode:withToken:), and the executor resuming is
	that one. A reservation names a node ahead of its wait, not a suspension, answers
	FBWaitingAddress>>matchesSuspension: with false and stands until it resumed something
	itself. Read off #waitingRegistry, which answers a throwaway when nothing was ever
	registered here - then there is nothing to forget and nothing is created"

	(waitingRegistry ifNil: [ ^ self ]) entries
		select: [ :each | each matchesSuspension: aSuspension ]
		thenDo: [ :each | waitingRegistry takeEntryFor: each correlationId ]
]

{ #category : 'executing' }
FBFlowInstance >> ended [
	"the one moment 'this instance is over' - reached from #activateProtected: when the
	activation that just ran left nothing pending and nothing suspended with the root
	executor on top, and nothing errored. Recorded as an FBFlowInstanceEnded for the
	event log and for whoever observes me. An instance in #error does not get here: it
	stopped, and what it left behind is what there is to look at.

	What is bookkeeping of the run and not of the result falls here. #joinStates and
	#splitBranchCounts grow by one entry per pass through a split - every iteration of a
	loop or a parallel scope is its own split execution - and nothing could remove them
	before, since a join cannot tell on its own whether a further arrival may still
	come (the latch in FBJoinBehavior>>execute exists for exactly that). Once nothing
	runs, nothing arrives. The waiting registry falls with them: an address of mine names
	a wait, and there is none left - an entry whose wait was resumed went with the resume
	(FBBaseExecutor>>resume:withToken:value:), and a reservation for a node the flow never
	reached is dead now. After me, #waitingEntryFor: answers nil for every address I ever
	handed out, and a signal on one is as silent as on a consumed one.

	Not reached for an instance that was already over when it was persisted - no step
	happens there any more - and reached again only if something runs me again, which
	nothing does"

	joinStates := nil.
	splitBranchCounts := nil.
	waitingRegistry := nil.
	self addEvent: FBFlowInstanceEnded new
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

	"An instance that ended holds no registry any more (#ended). The guard is for the two
	that still hold one: an instance persisted as finished before there was an end moment,
	and an instance that stopped in error - it keeps its addresses for inspection, but a
	reservation for a node it will never reach is not an open waiting spot"
	(executor notNil and: [ self isDone ]) ifTrue: [ ^ #() ].
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

{ #category : 'accessing' }
FBFlowInstance >> reservationAt: aNode forToken: aToken [
	"the address that already stands for a wait at aNode on aToken's strand, in me or in
	an instance executing inside me - or nil. Asked by FBBaseActivation>>waitForNode:
	withToken: so that such a wait does not mint a second address and answers this one
	instead. Walks down the chain only - a reservation in an instance above the parking
	one is not visible from here and is reconciled when it resolves instead, see
	FBWaitingReservation>>resumeIn:with:"
	^ self openWaitingEntries
		detect: [ :each | each reservesWaitAt: aNode forToken: aToken ]
		ifNone: [ nil ]
]

{ #category : 'executing' }
FBFlowInstance >> reserveWaitingSpotAt: aNode anchoredAt: aToken [
	"hand out an address for a wait that has not parked yet: the one that will be at aNode
	on the strand descending from aToken. For a link that has to go into a mail before
	the flow reaches the node that waits - the mail node sits before that node, so at the
	time the link is built there is nothing to register.

	aToken is the token of the activation asking, and it is what makes the address hit
	the right wait when the same node parks more than once: a link node inside a parallel
	scope runs per iteration and reserves per iteration. Registers on me, like a
	registration does; read back through the chain, see FBWaitingReservation"

	waitingRegistry ifNil: [ waitingRegistry := FBWaitingRegistry new ].
	^ waitingRegistry reserveAt: aNode anchoredAt: aToken
]

{ #category : 'executing' }
FBFlowInstance >> resumeWaitingAt: aNode with: aValue [
	"look for the waiting node in this instance's own executors and in those of the
	flow instances executing inside it, so that a wait modelled inside a sub flow can
	be resumed through the outermost instance. resuming is addressed by node identity
	alone, so a node waiting in more than one instance of a recursive sub flow call
	resolves to the outermost one - the same ambiguity the node already has across the
	iterations of a parallel scope. That ambiguity is why this stays the local variant
	and is not developed further: naming a waiting spot is what #signal:with: and a
	correlationId are for.

	Goes on through the same #resume:withToken:value: that #signal:with: uses, so that
	how a suspension continues is decided in one place. No token to hand over here -
	a node addressed by identity carries whatever its standing activation has"
	| holder |
	holder := self activeExecutors
		detect: [ :each | each suspended includes: aNode ]
		ifNone: [ ^ FBNodeNotWaiting signal: 'node is not currently waiting' ].
	holder resume: aNode withToken: nil value: aValue
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

{ #category : 'executing' }
FBFlowInstance >> signal: aCorrelationId with: aValue [
	"the one entrance for an impulse reaching a waiting spot of mine from outside -
	a submitted form, a fired schedule, a remote callback. Resolve the address, hand
	aValue to the waiting spot it names, and answer whether anything was resumed.

	An unknown correlationId and an already consumed one both answer false and change
	nothing. That is the whole idempotency guarantee - a double submit, a redelivery out
	of the event log, a schedule firing at a wait that is long gone.

	Knows nothing about what kind of address this is: the entry resolves itself and
	decides when it is spent. A plain FBWaitingEntry names a parked wait and is spent as
	soon as it is signalled, open or not; an FBWaitingReservation names a wait that may
	not have parked yet and stays until it really resumed something. That is why the
	entry is looked up here and not taken - taking is the entry's own step.

	Does not run the flow on afterwards, the same way #resumeWaitingAt:with: does not -
	the caller decides how far to step. #resumeWaitingAt:with: stays for the local case
	of addressing a wait by node, but is not developed further: node identity cannot
	name a waiting spot, which is what a correlationId is for"

	^ self signal: aCorrelationId with: aValue ifResumed: [ :activation | ]
]

{ #category : 'executing' }
FBFlowInstance >> signal: aCorrelationId with: aValue ifResumed: aBlock [
	"#signal:with:, and aBlock gets the activation that went on when something did - the
	one taken back up, or the one minted for a parked transition. For whoever has to
	say something about that step: ApptiveGrid records who submitted on it. Answers
	whether anything was resumed, like #signal:with:; on a silent signal aBlock is not
	evaluated"

	| entry activation |
	entry := self waitingEntryFor: aCorrelationId.
	entry ifNil: [ ^ false ].
	activation := entry resumeIn: self with: aValue.
	activation ifNil: [ ^ false ].
	aBlock value: activation.
	^ true
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

{ #category : 'executing' }
FBFlowInstance >> waitingSpotsOpenedDuring: aBlock [
	"run aBlock and answer the externally reachable waiting spots that came into being
	while it ran. A collection and not a single value: an AND split into two forms leaves
	two, and the caller that turns them into links and schedules has to see both.

	This is how a correlationId reaches the outside at all. It is minted when a wait parks
	(FBBaseActivation>>waitForNode:withToken:) and nothing announces it there, so without
	this a caller could only ask #openWaitingEntries afterwards and work out which of them
	is new.

	Read over the chain of active instances rather than announced, because a wait modelled
	in a local sub flow registers on the child instance and that child holds no reference
	back to its caller - an announcement there would reach nobody watching the outermost
	instance, which is the one an outward address names. Same chain #suspended and
	#openWaitingEntries already walk.

	A difference rather than a list kept along the way, so that no second structure has to
	be held in agreement with the registry - and because a difference is still right when
	the same run consumes one waiting spot and opens another, which is what every submit
	of a multi-page form does.

	Runs nothing itself: aBlock decides how far the flow goes, be that #executeWith:, a
	series of #step, or a resume."

	| before |
	before := self openWaitingEntries asIdentitySet.
	aBlock value.
	^ self openWaitingEntries reject: [ :each | before includes: each ]
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> whenAnnounced: aClass do: aBlock [

	announcer ifNil: [ announcer := Announcer new ].
	announcer when: aClass do: aBlock for: aBlock receiver
]
