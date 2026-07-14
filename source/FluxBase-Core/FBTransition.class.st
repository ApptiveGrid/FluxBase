Class {
	#name : 'FBTransition',
	#superclass : 'Object',
	#instVars : [
		'id',
		'source',
		'target',
		'condition'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBTransition class >> source: aSourceNode target: aTargetNode [ 
	^ self new 
		source: aSourceNode;
		target: aTargetNode
]

{ #category : 'associating' }
FBTransition >> --> aNode [ 
	^ target --> aNode
]

{ #category : 'visiting' }
FBTransition >> acceptFluxBase: aVisitor [
	^ aVisitor visitTransition: self
]

{ #category : 'adding' }
FBTransition >> addTo: aFBNode [
	source := aFBNode.
	aFBNode addOutgoing: self.
	^ target
]

{ #category : 'as yet unclassified' }
FBTransition >> attach [ 
	source addOutgoing: self.
	target addIncoming: self.
]

{ #category : 'accessing' }
FBTransition >> condition [
	^ condition 
]

{ #category : 'accessing' }
FBTransition >> condition: anObject [

	condition := anObject 
]

{ #category : 'testing' }
FBTransition >> conditionMatches: anObject [
	condition ifNil: [ ^ true ].
	^ condition value: anObject 
]

{ #category : 'as yet unclassified' }
FBTransition >> detach [ 
	source removeOutgoing: self.
	target removeIncoming: self.
]

{ #category : 'testing' }
FBTransition >> hasCondition [
	^ condition notNil
]

{ #category : 'accessing' }
FBTransition >> id [

	^ id
]

{ #category : 'initialization' }
FBTransition >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId
]

{ #category : 'printing' }
FBTransition >> printOn: aStream [ 
	source printOn: aStream.
	aStream << ' --> '.
	target printOn: aStream
]

{ #category : 'accessing' }
FBTransition >> source [
	^ source
]

{ #category : 'accessing' }
FBTransition >> source: aFBNode [
	source := aFBNode
]

{ #category : 'accessing' }
FBTransition >> target [
	^ target
]

{ #category : 'accessing' }
FBTransition >> target: aFBNode [ 
	target := aFBNode
]
