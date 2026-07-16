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
