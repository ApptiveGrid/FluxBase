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
