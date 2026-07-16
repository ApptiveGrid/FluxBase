Class {
	#name : 'FBJoinState',
	#superclass : 'Object',
	#instVars : [
		'joinNode',
		'splitId',
		'expected',
		'arrived',
		'released',
		'policy',
		'scopeId'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBJoinState >> arrived [
	^ arrived
]

{ #category : 'as yet unclassified' }
FBJoinState >> arrived: aCollection [
	arrived := aCollection
]

{ #category : 'as yet unclassified' }
FBJoinState >> expected [
	^ expected
]

{ #category : 'as yet unclassified' }
FBJoinState >> expected: aCollection [
	expected := aCollection
]

{ #category : 'as yet unclassified' }
FBJoinState >> initialize [
	super initialize.
	expected := OrderedCollection new.
	arrived := OrderedCollection new.
	released := false
]

{ #category : 'as yet unclassified' }
FBJoinState >> joinNode [
	^ joinNode
]

{ #category : 'as yet unclassified' }
FBJoinState >> joinNode: aFBNode [
	joinNode := aFBNode
]

{ #category : 'as yet unclassified' }
FBJoinState >> policy [
	^ policy
]

{ #category : 'as yet unclassified' }
FBJoinState >> policy: aSymbol [
	policy := aSymbol
]

{ #category : 'as yet unclassified' }
FBJoinState >> released [
	^ released
]

{ #category : 'as yet unclassified' }
FBJoinState >> released: aBoolean [
	released := aBoolean
]

{ #category : 'as yet unclassified' }
FBJoinState >> scopeId [
	^ scopeId
]

{ #category : 'as yet unclassified' }
FBJoinState >> scopeId: anObject [
	scopeId := anObject
]

{ #category : 'as yet unclassified' }
FBJoinState >> splitId [
	^ splitId
]

{ #category : 'as yet unclassified' }
FBJoinState >> splitId: anObject [
	splitId := anObject
]
