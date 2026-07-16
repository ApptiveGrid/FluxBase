Class {
	#name : 'FBWorkItem',
	#superclass : 'Object',
	#instVars : [
		'transition',
		'token',
		'value'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBWorkItem >> source [
	^ transition source
]

{ #category : 'as yet unclassified' }
FBWorkItem >> target [
	^ transition target
]

{ #category : 'as yet unclassified' }
FBWorkItem >> token [
	^ token
]

{ #category : 'as yet unclassified' }
FBWorkItem >> token: aFBToken [
	token := aFBToken
]

{ #category : 'as yet unclassified' }
FBWorkItem >> transition [
	^ transition
]

{ #category : 'as yet unclassified' }
FBWorkItem >> transition: aFBTransition [
	transition := aFBTransition
]

{ #category : 'as yet unclassified' }
FBWorkItem >> value [
	^ value
]

{ #category : 'as yet unclassified' }
FBWorkItem >> value: anObject [
	value := anObject
]
