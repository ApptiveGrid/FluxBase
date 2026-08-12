"
I am a scope: a region of a running flow whose tokens share a fate.

Where FBToken tracks a single strand of execution, I track a set of them that
can be bounded, completed or cancelled together. That is why I exist next to the
token rather than inside it: a token and its parent chain describe one path, but
they cannot enumerate the tokens that make up a region.

	id			my own identity
	parentId	the id of the scope I am nested in, i.e. my enclosing scope.
			Nesting, not sequence - do not confuse this with FBToken>>parentId,
			which points at another token and records which predecessor an
			activation arrived through.
	ownerNode	the node that opened me
	tokens		the tokens living in me
	state		#active while I am alive
	cancellationPolicy	how my tokens are to be cancelled together

I am Phase-2 infrastructure and only partly consumed so far: tokens and
cancellationPolicy have no readers yet (they are meant for the cancellation
patterns WCP-19/20/25), and FBToken>>scopeId stays nil for as long as nothing
creates scopes at runtime.
"
Class {
	#name : 'FBScope',
	#superclass : 'Object',
	#instVars : [
		'id',
		'parentId',
		'ownerNode',
		'tokens',
		'state',
		'cancellationPolicy',
		'depth'
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
    "Answer a new root scope (no parent), owned by aFBNode, depth 0."
    ^ self new
        ownerNode: aFBNode;
        depth: 0;
        yourself
]

{ #category : 'as yet unclassified' }
FBScope >> cancellationPolicy [
	^ cancellationPolicy
]

{ #category : 'as yet unclassified' }
FBScope >> cancellationPolicy: aSymbol [
	cancellationPolicy := aSymbol
]

{ #category : 'instance creation' }
FBScope >> childOwnedBy: aFBNode [
    "Answer a new child scope of the receiver, owned by aFBNode, one level deeper."
    ^ self class new
        parentId: self id;
        ownerNode: aFBNode;
        depth: self depth + 1;
        yourself
]

{ #category : 'accessing' }
FBScope >> depth [
    ^ depth ifNil: [ 0 ]
]

{ #category : 'accessing' }
FBScope >> depth: anInteger [
    depth := anInteger
]

{ #category : 'as yet unclassified' }
FBScope >> id [
	^ id
]

{ #category : 'as yet unclassified' }
FBScope >> initialize [
	super initialize.
	id := FBIdGenerator current newId.
	tokens := OrderedCollection new.
	state := #active
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
FBScope >> parentId [
	"The id of the scope I am nested in. Nesting, not sequence - FBToken>>parentId
	is a different relation, see my class comment."
	^ parentId
]

{ #category : 'as yet unclassified' }
FBScope >> parentId: anObject [
	parentId := anObject
]

{ #category : 'as yet unclassified' }
FBScope >> state [
	^ state
]

{ #category : 'as yet unclassified' }
FBScope >> state: aSymbol [
	state := aSymbol
]

{ #category : 'as yet unclassified' }
FBScope >> tokens [
	^ tokens
]

{ #category : 'as yet unclassified' }
FBScope >> tokens: aCollection [
	tokens := aCollection
]
