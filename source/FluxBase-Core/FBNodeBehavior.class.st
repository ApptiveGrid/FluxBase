Class {
	#name : 'FBNodeBehavior',
	#superclass : 'Object',
	#instVars : [
		'activation'
	],
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'accessing' }
FBNodeBehavior class >> metadataSchema [
	^ FBPropertySchema new
]

{ #category : 'as yet unclassified' }
FBNodeBehavior class >> propertySchema [
	^ FBPropertySchema new
]

{ #category : 'accessing' }
FBNodeBehavior >> activation [

	^ activation
]

{ #category : 'accessing' }
FBNodeBehavior >> activation: anObject [

	activation := anObject
]

{ #category : 'accessing' }
FBNodeBehavior >> argument [
	^ activation argument
]

{ #category : 'execution' }
FBNodeBehavior >> execute [ 
	activation flowInstance currentExecutor stop  
]

{ #category : 'finalization' }
FBNodeBehavior >> executor [ 
	^ activation executor
]

{ #category : 'moving' }
FBNodeBehavior >> followTransition: aFBTransition [ 
	activation followTransition: aFBTransition 
]

{ #category : 'accessing' }
FBNodeBehavior >> metadata [
	^ activation metadata
]

{ #category : 'accessing' }
FBNodeBehavior >> metadataSchema [
	^ activation metadataSchema
]

{ #category : 'accessing' }
FBNodeBehavior >> node [
	^ activation node
]

{ #category : 'accessing' }
FBNodeBehavior >> outgoing [
	^ self node outgoing
]

{ #category : 'accessing' }
FBNodeBehavior >> value: anObject [
	activation value: anObject
]
