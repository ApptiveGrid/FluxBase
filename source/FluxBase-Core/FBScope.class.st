Class {
	#name : 'FBScope',
	#superclass : 'Object',
	#instVars : [
		'id',
		'parentId',
		'ownerNode',
		'tokens',
		'state',
		'cancellationPolicy'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBScope >> cancellationPolicy [
	^ cancellationPolicy
]

{ #category : 'as yet unclassified' }
FBScope >> cancellationPolicy: aSymbol [
	cancellationPolicy := aSymbol
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
