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
	splitId		shared by every token one split execution created. Keys the
			FBJoinState, so a second pass through the same split gets its own
			join state instead of colliding with the first.
	branchId	unique per branch of a split
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

Two legacy fields, #parentId and #scopeId, remain readable for tokens persisted
before this: for those #parent is nil and FBBaseActivation>>sourceNode falls back
to resolving the old id. Nothing writes them any more, and they can be dropped
once no such tokens are left in any store.

Not all of me is wired up. Only #splitId and #parent currently drive decisions.
#branchId is inherited but never consulted, #scope is not populated by anything
yet, and #value, #state and #metadata have no readers at all - the engine keeps
the current value on the activation, not on me.
"
Class {
	#name : 'FBToken',
	#superclass : 'Object',
	#instVars : [
		'id',
		'activation',
		'value',
		'scope',
		'parent',
		'splitId',
		'branchId',
		'state',
		'metadata',
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

{ #category : 'as yet unclassified' }
FBToken >> branchId [
	^ branchId
]

{ #category : 'as yet unclassified' }
FBToken >> branchId: anObject [
	branchId := anObject
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

{ #category : 'as yet unclassified' }
FBToken >> metadata [
	^ metadata
]

{ #category : 'as yet unclassified' }
FBToken >> metadata: anObject [
	metadata := anObject
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
FBToken >> scope [
	^ scope
]

{ #category : 'accessing' }
FBToken >> scope: aFBScope [
	scope := aFBScope
]

{ #category : 'as yet unclassified' }
FBToken >> splitId [
	^ splitId
]

{ #category : 'as yet unclassified' }
FBToken >> splitId: anObject [
	splitId := anObject
]

{ #category : 'as yet unclassified' }
FBToken >> state [
	^ state
]

{ #category : 'as yet unclassified' }
FBToken >> state: aSymbol [
	state := aSymbol
]

{ #category : 'as yet unclassified' }
FBToken >> value [
	^ value
]

{ #category : 'as yet unclassified' }
FBToken >> value: anObject [
	value := anObject
]
