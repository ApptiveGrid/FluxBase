"
I am a scope: a region of a running flow whose tokens share a fate.

Where FBToken tracks a single strand of execution, I track a set of them that
can be bounded, completed or cancelled together. That is why I exist next to the
token rather than inside it: a token and its parent chain describe one path, but
they cannot enumerate the tokens that make up a region.

	id			my own identity, for addressing me from outside
	outer		the scope I am nested in, or nil if I am a root. Nesting, not
			sequence - do not confuse this with FBToken>>parentId, which points
			at another token and records which predecessor an activation
			arrived through. The word is 'outer' rather than 'parent' because
			that is the established vocabulary for scopes, and it keeps the two
			relations apart at a glance.
	ownerNode	the node that opened me
	tokens		the tokens living in me
	state		#active while I am alive
	cancellationPolicy	how my tokens are to be cancelled together

I hold my enclosing scope as a real reference, not as its id. Ids here are for
being addressed from outside; inside the model we navigate by reference. That is
also why #depth is computed by walking the outer chain instead of being stored:
with only an id there was nothing to walk, so the depth had to be carried along
as a second, derived field that could drift out of step.

I am Phase-2 infrastructure and only partly consumed so far: tokens and
cancellationPolicy have no readers yet - they are meant for the cancellation
patterns WCP-19/20/25 - and FBToken>>scopeId is not populated, so a token does
not yet know which of me it belongs to.
"
Class {
	#name : 'FBScope',
	#superclass : 'Object',
	#instVars : [
		'id',
		'outer',
		'ownerNode',
		'tokens',
		'state',
		'cancellationPolicy'
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
	tokens := OrderedCollection new.
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

{ #category : 'as yet unclassified' }
FBScope >> tokens [
	^ tokens
]

{ #category : 'as yet unclassified' }
FBScope >> tokens: aCollection [
	tokens := aCollection
]
