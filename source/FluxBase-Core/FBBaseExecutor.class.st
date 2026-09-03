Class {
	#name : 'FBBaseExecutor',
	#superclass : 'Object',
	#instVars : [
		'flowInstance',
		'pending',
		'suspended',
		'suspendedExecutor',
		'impliedContinuationNode',
		'impliedTransition',
		'suspendedTokens'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'executing' }
FBBaseExecutor >> activate: activation [
	self activations add: activation.
	flowInstance activateProtected: activation 
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> activationBefore: aFBActivation [ 

	^ self activations before: aFBActivation 
]

{ #category : 'accessing' }
FBBaseExecutor >> activationClass [
	^ flowInstance activationClass
]

{ #category : 'accessing' }
FBBaseExecutor >> activationOf: aFBNode [
	^ (self activations reverse 
				detect: [ :each | each node = aFBNode ]).
]

{ #category : 'accessing' }
FBBaseExecutor >> activations [
	^ flowInstance activations
]

{ #category : 'adding' }
FBBaseExecutor >> addEvent: anEvent [ 
	flowInstance addEvent: anEvent 
]

{ #category : 'adding' }
FBBaseExecutor >> addPending: aTransition [
	^ self addPending: aTransition withToken: nil
]

{ #category : 'adding' }
FBBaseExecutor >> addPending: aTransition withToken: aToken [
	"a transition on its own is not enough to schedule work: the token carries the
	branch identity a join reads later (see FBWorkItem and FBToken), so it has to
	travel through the queue together with the transition rather than be recreated
	at the far end. Every executor queues this way - #pending is the executor's own
	bookkeeping, the token belongs to the flow instance's execution, and queueing is
	the one place the two meet"

	pending add: (FBWorkItem new
			 transition: aTransition;
			 token: aToken;
			 yourself)
]

{ #category : 'accessing' }
FBBaseExecutor >> addWaiting: aNode [
	self addWaiting: aNode withToken: nil
]

{ #category : 'accessing' }
FBBaseExecutor >> addWaiting: aNode withToken: aToken [
	"aToken is remembered alongside the suspension rather than wrapped into it, so
	#suspended stays a plain collection of whatever was suspended - callers read its
	elements as transitions (#target/#source) or as nodes (#includes:/#remove:) all
	over both FluxBase and ApptiveBase, and none of them has to change."
	suspended add: aNode.
	aToken ifNotNil: [
		suspendedTokens ifNil: [ suspendedTokens := IdentityDictionary new ].
		suspendedTokens at: aNode put: aToken ]
]

{ #category : 'services' }
FBBaseExecutor >> buildImpliedContinuationNode [
	"the node a dead-ending activation implicitly continues to when this
	executor is the current one - a plain flow end by default (used by
	FBFlowExecutor, the root/outermost case); FBParallelExecutor overrides
	this to answer an implicit join for its own scope instead"

	^ FBEndEvent new
]

{ #category : 'accessing' }
FBBaseExecutor >> firstPending [
	^ pending first
]

{ #category : 'accessing' }
FBBaseExecutor >> flow [
	^ flowInstance flow
]

{ #category : 'accessing' }
FBBaseExecutor >> flowInstance [

	^ flowInstance
]

{ #category : 'accessing' }
FBBaseExecutor >> flowInstance: aFBFlowInstance [ 
	flowInstance := aFBFlowInstance.

]

{ #category : 'testing' }
FBBaseExecutor >> hasErrors [
	"not an executor-local fact: #activations is the flow instance's collection, shared
	by every executor of that instance, so this answers the same for all of them"

	^ flowInstance hasErrors
]

{ #category : 'testing' }
FBBaseExecutor >> hasPending [
	^ pending notEmpty 
]

{ #category : 'accessing' }
FBBaseExecutor >> impliedContinuationNode [
	^ impliedContinuationNode ifNil: [
		  impliedContinuationNode := self buildImpliedContinuationNode ]
]

{ #category : 'services' }
FBBaseExecutor >> impliedTransition [
	"a single, lazily-created, ad-hoc, never-persisted transition to this
	executor's implied continuation node, reused (with its #source
	reassigned per call, see #impliedTransitionFrom:) for this executor's
	whole lifetime. sharing *one* transition object - rather than one per
	distinct source node - is what makes e.g. every iteration of a
	parallel scope's loop body funnel into the *same* implicit join
	activation, exactly like an explicit join would
	(FBParallelExecutor>>newActivation:'s activation cache is keyed by
	transition identity). safe only because each dead-end is resolved and
	fully consumed (queued via #addPending: and processed by the very next
	#step) before the next one can reassign #source - see
	FBNode>>effectiveOutgoingFor:. never call #attach/#addTo: on it: it
	must never be wired into any real node's own (possibly persistent,
	definition-level) #outgoing"

	^ impliedTransition ifNil: [
		  impliedTransition := FBTransition new
			                        target: self impliedContinuationNode ]
]

{ #category : 'services' }
FBBaseExecutor >> impliedTransitionFrom: aFBNode [
	^ self impliedTransition source: aFBNode; yourself
]

{ #category : 'initialization' }
FBBaseExecutor >> initialize [ 
	super initialize.
	pending := OrderedCollection new.
	suspended := OrderedCollection new
]

{ #category : 'testing' }
FBBaseExecutor >> isCreated [
	^ (pending size = 1) and: [ pending first transition = flowInstance start ]
]

{ #category : 'accessing' }
FBBaseExecutor >> isDone [
	^ pending isEmpty & suspended isEmpty
]

{ #category : 'testing' }
FBBaseExecutor >> isParallel [

	^ false
]

{ #category : 'testing' }
FBBaseExecutor >> isRunning [
	^ pending notEmpty
]

{ #category : 'testing' }
FBBaseExecutor >> isSubFlow [

	^ false
]

{ #category : 'testing' }
FBBaseExecutor >> isWaiting [
	^ pending isEmpty & suspended notEmpty
]

{ #category : 'accessing' }
FBBaseExecutor >> lastValueOf: aFBNode [
	^ (self activationOf: aFBNode) value.
]

{ #category : 'accessing' }
FBBaseExecutor >> takeTokenForSuspended: anObject [
	"answer and forget the token stored for anObject, or nil if there is none - which
	is also the case for executors persisted before #suspendedTokens existed, hence
	the nil guard rather than a lazy initialization (a lazy one would mark the executor
	dirty on a pure read, see FBBaseActivation>>token).

	anObject is whatever #addWaiting:withToken: put into #suspended, and that is read
	as a transition or as a node depending on the layer - ApptiveBase suspends
	transitions - so there is no one class to name it after. The lookup is by identity,
	so it has to be the very object that was suspended."

	suspendedTokens ifNil: [ ^ nil ].
	^ suspendedTokens removeKey: anObject ifAbsent: [ nil ]
]

{ #category : 'accessing' }
FBBaseExecutor >> pending [
	^ pending
]

{ #category : 'accessing' }
FBBaseExecutor >> popThenResume: aBlock [
	"pop this executor off the flow instance's executor stack, run aBlock while the
	parent executor is already current, and only then notify the parent to resume.
	callers that need to enqueue a continuation transition as part of popping (e.g.
	FBParallelJoinNodeBehavior) must do so from aBlock: if it happened after the
	parent's resumeAfter: instead, a parent parallel executor would already have
	eagerly advanced to its next iteration (see FBParallelExecutor>>continue), and
	the continuation would race against - and lose to - that next iteration"
	| parent |
	parent := suspendedExecutor.
	flowInstance popExecutor: parent.
	aBlock value.
	parent ifNotNil: [
		parent resumeAfter: self ]
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> resumeAfter: anExecutor [
	
	^ self
]

{ #category : 'finalization' }
FBBaseExecutor >> rootExecutor [
	^ suspendedExecutor 
		ifNotNil: [ suspendedExecutor rootExecutor ]
		ifNil: [ self ]
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> scheduleStart [
	"the start pseudo-transition is queued through #addPending: like any other work,
	so #pending has a single writer. it carries no token: the start node's own
	activation mints the first one (FBBaseActivation>>initialize)"

	self addPending: flowInstance start.
	flowInstance addEvent: FBFlowInstanceStarted new
]

{ #category : 'accessing' }
FBBaseExecutor >> stop [
	self popThenResume: [ ]
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> suspended [
	^ suspended 
]

{ #category : 'accessing' }
FBBaseExecutor >> suspendedExecutor [ 
	^ suspendedExecutor
]

{ #category : 'accessing' }
FBBaseExecutor >> suspendedExecutor: anObject [

	suspendedExecutor := anObject
]
