"
I am a scope: a region of a running flow whose tokens share a lifetime. Where FBToken
tracks a single strand of execution, I bound a set of them: everything that runs inside
me ends, at the latest, when I end - and once cancellation exists, is cancelled together.

Scopes answer 'what falls together'. That is a different question from the one a
split's #splitId answers - 'who is expected at the join' - and a split therefore opens
no scope of its own. Three things do:

	the flow instance		its root scope, there from the moment it has an executor
				(FBFlowInstance>>initializeExecutor), owned by nothing
	a sub flow call		FBSubFlowBehavior>>buildChildScope, owned by the FBSubFlowNode,
				nested in the scope the calling activation ran in
	one iteration of a		FBParallelExecutor>>currentIterationScope, owned by the
	parallel node		FBParallelNode, nested in the scope the fork ran in

Every token carries the scope it lives in (FBToken>>scope): the start token gets the
root scope (FBBaseExecutor>>scheduleStart), a child token inherits its parent's
(FBBaseActivation>>childToken), an iteration's or a sub flow's first token gets the
new one. Membership is not stored anywhere else - which tokens live in me is read off
the executors' pending and suspended bookkeeping and the waiting registry
(FBFlowInstance>>isScopeLive:), so it cannot drift.

	id			my own identity, for addressing me from outside
	outer		the scope I am nested in, or nil if I am a root. Nesting, not
			sequence - FBToken>>parent records which predecessor an activation
			arrived through. 'outer' rather than 'parent' because that is the
			established vocabulary for scopes, and it keeps the two relations apart
	ownerNode	the node that opened me, nil for a root
	state		#active while I am alive, #cancelled once I was cancelled (#cancelled);
			#isCancelled asks my outer scopes as well

#depth is the nesting depth, derived by walking #outer. #callDepth counts only the
scopes a sub flow call opened, which is what the recursion guard has to compare: an
iteration nests a scope without being a call.
"
Class {
	#name : 'FBScope',
	#superclass : 'Object',
	#instVars : [
		'id',
		'outer',
		'ownerNode',
		'state'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBScope class >> defaultMaxDepth [
    ^ 50
]

{ #category : 'instance creation' }
FBScope class >> rootOwnedBy: aFBNode [
    "Answer a new root scope, owned by aFBNode. A root has no outer scope, so its depth is 0."
    ^ self new
        ownerNode: aFBNode;
        yourself
]

{ #category : 'instance creation' }
FBScope >> childOwnedBy: aFBNode [
    "Answer a new scope nested directly inside me, owned by aFBNode."
    ^ self class new
        outer: self;
        ownerNode: aFBNode;
        yourself
]

{ #category : 'accessing' }
FBScope >> depth [
    "How deeply I am nested, counting a root as 0. Derived by walking #outer rather
    than stored, so it can never disagree with the actual nesting."
    ^ outer ifNil: [ 0 ] ifNotNil: [ :aScope | aScope depth + 1 ]
]

{ #category : 'as yet unclassified' }
FBScope >> id [
	^ id
]

{ #category : 'as yet unclassified' }
FBScope >> initialize [
	super initialize.
	id := FBIdGenerator current newId.
	state := #active
]

{ #category : 'accessing' }
FBScope >> outer [
	"The scope I am nested in, or nil if I am a root. Nesting, not sequence -
	FBToken>>parentId is a different relation, see my class comment."
	^ outer
]

{ #category : 'accessing' }
FBScope >> outer: aFBScope [
	outer := aFBScope
]

{ #category : 'as yet unclassified' }
FBScope >> ownerNode [
	^ ownerNode
]

{ #category : 'as yet unclassified' }
FBScope >> ownerNode: aFBNode [
	ownerNode := aFBNode
]

{ #category : 'as yet unclassified' }
FBScope >> state [
	^ state
]

{ #category : 'as yet unclassified' }
FBScope >> state: aSymbol [
	state := aSymbol
]

{ #category : 'accessing' }
FBScope >> callDepth [
	"how many sub flow calls deep I am: the scopes on my #outer chain, myself included,
	that a call opened. The recursion guard in FBSubFlowBehavior>>buildChildScope compares
	this, not #depth - an iteration of a parallel node nests a scope without being a
	call, and must not count as one"
	^ (outer ifNil: [ 0 ] ifNotNil: [ :aScope | aScope callDepth ])
		+ (self isCall ifTrue: [ 1 ] ifFalse: [ 0 ])
]

{ #category : 'testing' }
FBScope >> encloses: aScope [
	"is aScope me or nested in me, at any depth? nil is enclosed by nothing - a token
	persisted before tokens carried a scope belongs to no scope and falls with the
	instance alone"
	aScope ifNil: [ ^ false ].
	aScope == self ifTrue: [ ^ true ].
	^ self encloses: aScope outer
]

{ #category : 'testing' }
FBScope >> isCall [
	"was I opened by a sub flow call? Asked of my owner, see FBNode>>opensCallScope"
	^ ownerNode notNil and: [ ownerNode opensCallScope ]
]

{ #category : 'cancelling' }
FBScope >> cancelled [
	"I am over by decision: nothing that lives in me runs on, and nothing new is taken
	in. Set by FBFlowInstance>>cancelScope:, which then takes my strands back. Read
	through #isCancelled, which walks #outer: cancelling a scope cancels everything
	nested in it without touching the nested scopes' own state"
	state := #cancelled
]

{ #category : 'testing' }
FBScope >> isCancelled [
	"am I cancelled, or nested in a scope that is? The rule every executor enforces:
	FBBaseExecutor>>addPending:withToken: queues nothing for a token in such a scope,
	and FBBaseActivation>>waitForNode:withToken: parks none"
	state = #cancelled ifTrue: [ ^ true ].
	^ outer notNil and: [ outer isCancelled ]
]
