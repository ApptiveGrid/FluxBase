Class {
	#name : 'FBBaseExecutor',
	#superclass : 'Object',
	#instVars : [
		'flowInstance',
		'pending',
		'suspended',
		'suspendedExecutor'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'executing' }
FBBaseExecutor >> activate: activation [
	self activations add: activation.
	flowInstance activateProtected: activation 
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> activationBefore: aFBActivation [ 

	^ self activations before: aFBActivation 
]

{ #category : 'accessing' }
FBBaseExecutor >> activationClass [
	^ flowInstance activationClass
]

{ #category : 'accessing' }
FBBaseExecutor >> activationOf: aFBNode [
	^ (self activations reverse 
				detect: [ :each | each node = aFBNode ]).
]

{ #category : 'accessing' }
FBBaseExecutor >> activations [
	^ flowInstance activations
]

{ #category : 'adding' }
FBBaseExecutor >> addEvent: anEvent [ 
	flowInstance addEvent: anEvent 
]

{ #category : 'adding' }
FBBaseExecutor >> addPending: aFBNode [ 
	pending add: aFBNode 
]

{ #category : 'accessing' }
FBBaseExecutor >> addWaiting: aNode [
	suspended add: aNode
]

{ #category : 'accessing' }
FBBaseExecutor >> firstPending [
	^ pending first
]

{ #category : 'accessing' }
FBBaseExecutor >> flow [
	^ flowInstance flow
]

{ #category : 'accessing' }
FBBaseExecutor >> flowInstance [

	^ flowInstance
]

{ #category : 'accessing' }
FBBaseExecutor >> flowInstance: aFBFlowInstance [ 
	flowInstance := aFBFlowInstance.

]

{ #category : 'testing' }
FBBaseExecutor >> hasErrors [
	^ self activations anySatisfy: [ :each | each hasError ]
]

{ #category : 'testing' }
FBBaseExecutor >> hasPending [
	^ pending notEmpty 
]

{ #category : 'initialization' }
FBBaseExecutor >> initialize [ 
	super initialize.
	pending := OrderedCollection new.
	suspended := OrderedCollection new
]

{ #category : 'testing' }
FBBaseExecutor >> isCreated [ 
	^ (pending size = 1) and: [ pending first = flowInstance start ]
]

{ #category : 'accessing' }
FBBaseExecutor >> isDone [
	^ pending isEmpty & suspended isEmpty
]

{ #category : 'testing' }
FBBaseExecutor >> isParallel [

	^ false
]

{ #category : 'testing' }
FBBaseExecutor >> isRunning [
	^ pending notEmpty
]

{ #category : 'testing' }
FBBaseExecutor >> isWaiting [
	^ pending isEmpty & suspended notEmpty
]

{ #category : 'accessing' }
FBBaseExecutor >> lastValueOf: aFBNode [
	^ (self activationOf: aFBNode) value.
]

{ #category : 'accessing' }
FBBaseExecutor >> pending [
	^ pending
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> resumeAfter: anExecutor [
	
	^ self
]

{ #category : 'finalization' }
FBBaseExecutor >> rootExecutor [
	^ suspendedExecutor 
		ifNotNil: [ suspendedExecutor rootExecutor ]
		ifNil: [ self ]
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> scheduleStart [
	pending add: flowInstance start.
	flowInstance addEvent: FBFlowInstanceStarted new
]

{ #category : 'accessing' }
FBBaseExecutor >> stop [
	| parent |
	parent := suspendedExecutor.
	flowInstance popExecutor: parent.
	parent ifNotNil: [
		parent resumeAfter: self ]
]

{ #category : 'as yet unclassified' }
FBBaseExecutor >> suspended [
	^ suspended 
]

{ #category : 'accessing' }
FBBaseExecutor >> suspendedExecutor [ 
	^ suspendedExecutor
]

{ #category : 'accessing' }
FBBaseExecutor >> suspendedExecutor: anObject [

	suspendedExecutor := anObject
]
