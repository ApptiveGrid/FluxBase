"
I am a token: one strand of execution through a running flow instance.

FluxBase is single-threaded, so the question 'which branch am I on' cannot be
answered by 'which thread am I in' - it has to be carried as data. That is what
I am for.

Every FBBaseActivation owns exactly one of me, and I hold that activation back,
so the two are navigable in both directions. I am never passed along as-is: when
an activation follows a transition it creates a fresh child of mine via
FBBaseActivation>>childToken - new identity, inherited context, plus a reference
to the token it came from.

	id			my own identity, for being addressed from outside
	activation	the activation I belong to, set when I am attached to one
	parent		the token I was created from. Answers 'through which
			predecessor did this activation arrive' - a runtime fact, unlike
			node incoming, which is only static graph structure and therefore
			cannot tell two passes of a loop apart. Read via
			FBBaseActivation>>sourceNode to attribute each branch arriving at a
			join to the node it came from.
	split		the FBSplitExecution I am a branch of: the pass through a split that
			created my line, shared by every token of that pass and given back
			to the enclosing pass behind the join. Keys the FBJoinState, so a
			second pass through the same split gets its own join state instead
			of colliding with the first. Nil at the outermost level.
	scope		the FBScope I live in

My #parent and FBScope>>outer are deliberately named apart because they are
different relations: mine records sequence (who came before me), the scope's
records nesting (what encloses me). One token can have several children - an
AND-split creates one per branch - so the token graph is a tree, and every token
has exactly one parent, which is why 'parent' fits here and 'outer' fits there.

I reference my parent and my scope as real objects rather than by their ids. Ids
here are for being addressed from outside; inside the model we navigate by
reference. That is also why #node is derived from #activation instead of being
stored: a token that knows its activation knows its node, and a stored copy could
only drift out of step with it.

Three legacy fields, #parentId, #scopeId and #splitId, remain readable for tokens
persisted before this: for those #parent is nil and FBBaseActivation>>sourceNode falls
back to resolving the old id, and #splitId answers the stored id where there is no
#split to derive it from. Nothing writes them any more, and they can be dropped once
no such tokens are left in any store.

My #state says whether this strand is running or parked: #ready or #waiting - and #ready
again once the wait was resumed (#resumed) - or #cancelled, once the strand was taken
back (FBFlowInstance>>cancelStrand:). A cancelled strand never runs or resumes again. There is no #done - a strand ends by my
disappearing, not by my carrying a state that says so. A wait outlives the step that
started it, which is why it is mine and not the activation's; the three step
statements - #created, #done, #error - stay on FBBaseActivation, and its #state
answers #waiting off me.

#split, #parent, #scope and #state drive decisions. A #metadata field once lived here
too; it never had a reader - the engine keeps the current value on the activation, not
on me - and is gone.
"
Class {
	#name : 'FBToken',
	#superclass : 'Object',
	#instVars : [
		'id',
		'activation',
		'scope',
		'parent',
		'split',
		'splitId',
		'state',
		'parentId',
		'scopeId'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBToken >> activation [
	"The activation I belong to, or nil while I am still queued and not attached yet."
	^ activation
]

{ #category : 'accessing' }
FBToken >> activation: anFBBaseActivation [
	activation := anFBBaseActivation
]

{ #category : 'testing' }
FBToken >> hasAncestor: aToken [
	"did I come out of aToken? Walks the #parent chain, which
	FBBaseActivation>>childToken builds one link at a time.

	This is what tells two iterations of a parallel scope apart:
	FBParallelExecutor>>scopeToken mints a fresh child token of the fork's activation for
	each of them, so every iteration has a chain of its own from that point on. Node
	identity cannot do it - the same node parks once per iteration - and neither can the
	suspension, since #suspended holds the very same transition object n times.

	Not reflexive: a token is not its own ancestor. A waiting spot always carries a child
	of the token that reserved an address for it, never that token itself.

	By identity, and only along real #parent references - a token persisted before
	#parent became a reference carries just #parentId and stops the walk. Those are from
	before reservations existed, so none of them is an anchor"

	| each |
	each := parent.
	[ each notNil ] whileTrue: [
		each == aToken ifTrue: [ ^ true ].
		each := each parent ].
	^ false
]

{ #category : 'accessing' }
FBToken >> instancesAlongAncestry [
	"the flow instances my strand has run through, mine first, each once: my activation's,
	then my parent's, and so on up the chain. Within one instance that is a single
	element; a strand that entered a sub flow lists the child and then its callers,
	because FBFlowInstance>>descendFrom: links the child's first token to the caller's.
	Asked by FBBaseActivation>>waitForNode:withToken: to find a reservation that was
	handed out upstream of the instance that is parking"

	| instances each |
	instances := OrderedCollection new.
	each := self.
	[ each notNil ] whileTrue: [
		each activation ifNotNil: [ :anActivation |
			(instances identityIncludes: anActivation flowInstance)
				ifFalse: [ instances add: anActivation flowInstance ] ].
		each := each parent ].
	^ instances
]

{ #category : 'as yet unclassified' }
FBToken >> id [
	^ id
]

{ #category : 'as yet unclassified' }
FBToken >> initialize [
	super initialize.
	id := FBIdGenerator current newId.
	state := #ready
]

{ #category : 'accessing' }
FBToken >> node [
	"The node my activation stands on. Derived rather than stored - see my class comment."
	^ activation ifNotNil: [ :each | each node ]
]

{ #category : 'accessing' }
FBToken >> parent [
	"The token I was created from, set by FBBaseActivation>>childToken. Sequence,
	not nesting - FBScope>>outer is a different relation, see my class comment."
	^ parent
]

{ #category : 'accessing' }
FBToken >> parent: aFBToken [
	parent := aFBToken
]

{ #category : 'legacy' }
FBToken >> parentId [
	"Only for tokens persisted before #parent became a real reference; nothing writes
	this any more. Answers #parent's id when there is one, so a reader sees a
	consistent value either way. See my class comment."
	^ parent ifNil: [ parentId ] ifNotNil: [ :each | each id ]
]

{ #category : 'legacy' }
FBToken >> scopeId [
	"Only for tokens persisted before #scope became a real reference; nothing writes
	this any more. See my class comment."
	^ scope ifNil: [ scopeId ] ifNotNil: [ :each | each id ]
]

{ #category : 'accessing' }
FBToken >> resumed [
	"the wait I was parked at is over and my strand goes on - back to #ready. Sent by
	the suspension that resumes (FBNode>>resumeIn:withToken:value:,
	FBTransition>>resumeIn:withToken:value:); without it a resumed strand would report
	#waiting for good, and so would the activation reading its state off me"
	state := #ready
]

{ #category : 'accessing' }
FBToken >> scope [
	^ scope
]

{ #category : 'accessing' }
FBToken >> scope: aFBScope [
	scope := aFBScope
]

{ #category : 'accessing' }
FBToken >> split [
	"the pass through a split I am a branch of, see my class comment - nil at the
	outermost level and for tokens persisted before splits were objects"
	^ split
]

{ #category : 'accessing' }
FBToken >> split: aSplitExecution [
	split := aSplitExecution
]

{ #category : 'accessing' }
FBToken >> splitId [
	"the id of my split, for the outside (FBNodeActivationEvent>>splitId) - off the
	split itself, or the stored id for a token persisted before splits were objects"
	^ split ifNotNil: [ :each | each id ] ifNil: [ splitId ]
]

{ #category : 'testing' }
FBToken >> isWaiting [
	"am I parked at a wait? Read by FBBaseActivation>>state, which reports #waiting for
	the step that parked me - see my class comment"
	^ state = #waiting
]

{ #category : 'as yet unclassified' }
FBToken >> state [
	^ state
]

{ #category : 'as yet unclassified' }
FBToken >> state: aSymbol [
	state := aSymbol
]

{ #category : 'accessing' }
FBToken >> waiting [
	state := #waiting
]

{ #category : 'accessing' }
FBToken >> cancelled [
	"my strand was taken back - out of every queue, wait and address - and goes on
	nowhere. Set by the withdrawal in FBFlowInstance>>withdrawStrandsSatisfying:; an
	activation that still stands on me reads #cancelled off me"
	state := #cancelled
]

{ #category : 'testing' }
FBToken >> isCancelled [
	^ state = #cancelled
]

{ #category : 'testing' }
FBToken >> isInCancelledScope [
	"does my strand live in a cancelled scope? Then nothing more may be queued or parked
	for it, see FBScope>>isCancelled. A token from before tokens carried a scope lives in
	none and is never held back this way"
	^ scope notNil and: [ scope isCancelled ]
]
