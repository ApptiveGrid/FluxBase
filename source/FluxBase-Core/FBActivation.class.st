Class {
	#name : 'FBActivation',
	#superclass : 'FBBaseActivation',
	#instVars : [
		'value',
		'metadata',
		'argument'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'activation' }
FBActivation >> activate [ 
	node activateWith: self.
]

{ #category : 'accessing' }
FBActivation >> argument [
	^ argument
]

{ #category : 'accessing' }
FBActivation >> argument: aCollection [ 
	argument := aCollection
]

{ #category : 'accessing' }
FBActivation >> metadata [
	^ metadata 
]

{ #category : 'accessing' }
FBActivation >> metadataAt: aString [ 
	metadata ifNil: [ KeyNotFound signalFor: aString ].
	^ metadata at: aString
]

{ #category : 'accessing' }
FBActivation >> metadataAt: key ifAbsent: aBlock [
	metadata ifNil: [ ^ aBlock value ].
	^ metadata 
		at: key 
		ifAbsent: aBlock
]

{ #category : 'accessing' }
FBActivation >> metadataAt: key put: anObject [ 
	metadata ifNil: [ 
		metadata := FBActivationMetadata new 
			schema: self metadataSchema;
			activation: self;
			yourself ].
	metadata  
		at: key 
		put: anObject
]

{ #category : 'accessing' }
FBActivation >> metadataSchema [
	^ node metadataSchema
]

{ #category : 'accessing' }
FBActivation >> previous [
	^ executor activationBefore: self 
]

{ #category : 'printing' }
FBActivation >> printOn: aStream [ 
	aStream << 'activation: '.
	node printOn: aStream.
	aStream << ', argument: '.
	argument printOn: aStream.
	aStream << ', value: '.
	value printOn: aStream 
	
]

{ #category : 'accessing' }
FBActivation >> returnValue: anInteger [ 
	self shouldBeImplemented.
]

{ #category : 'as yet unclassified' }
FBActivation >> suspend [
	state := #waiting.
	executor addWaiting: node
]

{ #category : 'accessing' }
FBActivation >> value [

	^ value
]

{ #category : 'accessing' }
FBActivation >> value: anObject [

	value := anObject
]
