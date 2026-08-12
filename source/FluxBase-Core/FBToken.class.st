"
I am a token: one strand of execution through a running flow instance.

FluxBase is single-threaded, so the question 'which branch am I on' cannot be
answered by 'which thread am I in' - it has to be carried as data. That is what
I am for.

Every FBBaseActivation owns exactly one of me. I am never passed along as-is:
when an activation follows a transition it creates a fresh child of mine via
FBBaseActivation>>childToken - new identity, inherited context, plus a backlink
to the token it came from.

	id			my own identity
	parentId	the id of the token I was created from. Answers 'through which
			predecessor did this activation arrive' - a runtime fact, unlike
			node incoming, which is only static graph structure and therefore
			cannot tell two passes of a loop apart. Read by FBJoinBehavior to
			attribute each arriving branch to its source node.
	splitId		shared by every token one split execution created. Keys the
			FBJoinState, so a second pass through the same split gets its own
			join state instead of colliding with the first.
	branchId	unique per branch of a split
	scopeId		the FBScope I live in

My parentId and FBScope>>outer are deliberately named apart because they are
different relations: mine records sequence (who came before me), the scope's
records nesting (what encloses me). One token can have several children - an
AND-split creates one per branch - so the token graph is a tree, and every token
has exactly one parent, which is why 'parent' fits here and 'outer' fits there.

Not all of me is wired up. Only splitId and parentId currently drive decisions.
branchId and scopeId are inherited and logged but never consulted, scopeId stays
nil for as long as nothing creates scopes, and node, value, state and metadata
have no readers at all - the engine keeps the current value on the activation,
not on me.
"
Class {
	#name : 'FBToken',
	#superclass : 'Object',
	#instVars : [
		'id',
		'node',
		'value',
		'scopeId',
		'parentId',
		'splitId',
		'branchId',
		'state',
		'metadata'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

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

{ #category : 'as yet unclassified' }
FBToken >> node [
	^ node
]

{ #category : 'as yet unclassified' }
FBToken >> node: aFBNode [
	node := aFBNode
]

{ #category : 'as yet unclassified' }
FBToken >> parentId [
	"The id of the token I was created from, set by FBBaseActivation>>childToken.
	Sequence, not nesting - FBScope>>outer is a different relation, see my class comment."
	^ parentId
]

{ #category : 'as yet unclassified' }
FBToken >> parentId: anObject [
	parentId := anObject
]

{ #category : 'as yet unclassified' }
FBToken >> scopeId [
	^ scopeId
]

{ #category : 'as yet unclassified' }
FBToken >> scopeId: anObject [
	scopeId := anObject
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
