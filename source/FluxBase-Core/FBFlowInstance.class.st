Class {
	#name : 'FBFlowInstance',
	#superclass : 'Object',
	#instVars : [
		'id',
		'flow',
		'executor',
		'executors',
		'announcer',
		'events',
		'activations',
		'metadata'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBFlowInstance >> aboutToTransition: aNode [
	"subclasses can overwrite this method to act before a transition
	is taken. This enables checks if a transition is possible before
	adding an activation for it"
]

{ #category : 'convenience' }
FBFlowInstance >> activate: anActivation [ 
	self addEvent: (FBNodeActivationStarted new
		activation: anActivation).
	anActivation activate.
	self addEvent: (FBNodeActivationDone new
		activation: anActivation)

]

{ #category : 'convenience' }
FBFlowInstance >> activateProtected: activation [
	[ [ self activate: activation ]
		on: FBError  
		do: [ :error |
			activation errored.
			self addEvent: (FBNodeActivationErrored new 
				activation: activation;
				activationError: error messageText)  ] ]
		on: Error 
		do: [ :error | 
			activation errored.
			self addEvent: (FBNodeActivationErrored new 
				activation: activation;
				activationError: error messageText).
			error pass ]
]

{ #category : 'accessing' }
FBFlowInstance >> activationClass [
	^ flow activationClass
]

{ #category : 'accessing' }
FBFlowInstance >> activationOfNode: aFBNode [
	^ self activations 
		detect: [ :each | each node = aFBNode ]
		ifNone: [ Error signal: 'no activation found for node' ]
]

{ #category : 'accessing' }
FBFlowInstance >> activations [ 
	^ activations
]

{ #category : 'events' }
FBFlowInstance >> addEvent: aFBFlowEvent [
	events ifNil: [ events := OrderedCollection new ].
	events add: (aFBFlowEvent
			 flowInstance: self;
			 yourself).
	self announce: aFBFlowEvent
]

{ #category : 'announcements' }
FBFlowInstance >> announce: aFBModelEvent [
	announcer ifNil: [ announcer := Announcer new ].
	announcer announce: aFBModelEvent 
]

{ #category : 'accessing' }
FBFlowInstance >> announcer [
	^ announcer
]

{ #category : 'accessing' }
FBFlowInstance >> atEnd [
	^ (executor = self rootExecutor) and: [  
		executors allSatisfy: [ :each | each atEnd ]
		].
]

{ #category : 'finalization' }
FBFlowInstance >> buildRootExecutor [
	^ FBFlowExecutor new 
			flowInstance: self;
			scheduleStart 
]

{ #category : 'accessing' }
FBFlowInstance >> events [
	^ events 
]

{ #category : 'accessing' }
FBFlowInstance >> eventsOfActivation: aFBActivation [ 
	^ self events select: [ :each | (each isKindOf: FBNodeActivationEvent) and: [ each activation = aFBActivation ] ]
]

{ #category : 'events' }
FBFlowInstance >> eventsOfNode: aFBNode [
	^ (self activationOfNode: aFBNode) ifNotNil: [ :activation | activation events ]
]

{ #category : 'executing' }
FBFlowInstance >> execute [ 
	self initializeExecutor.
	[  self executor hasPending ] whileTrue: [
		executor step ]

]

{ #category : 'executing' }
FBFlowInstance >> executeWith: anObject [
	self initialValue: anObject.
	self execute
]

{ #category : 'accessing' }
FBFlowInstance >> executor [ 
	^ executor 
]

{ #category : 'accessing' }
FBFlowInstance >> executors [

	^ executors
]

{ #category : 'accessing' }
FBFlowInstance >> flow [
	^ flow
]

{ #category : 'accessing' }
FBFlowInstance >> flow: aFBFlow [ 
	flow := aFBFlow 
]

{ #category : 'accessing' }
FBFlowInstance >> id [

	^ id
]

{ #category : 'accessing' }
FBFlowInstance >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
FBFlowInstance >> initialValue: anObject [
	self initializeExecutor.
	self executor initialValue: anObject
]

{ #category : 'initialization' }
FBFlowInstance >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId.
	activations := OrderedCollection new.
	executors := OrderedCollection new.
	
]

{ #category : 'accessing' }
FBFlowInstance >> initializeExecutor [
	executor ifNotNil: [ ^ self ].
	executor := self buildRootExecutor.
	executors add: executor.
	
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> inspectionFlow: aBuilder [ 
	<inspectorPresentationOrder: 0 title: 'flow'>
	^ aBuilder newRoassal 
		canvas: (FBFlowMapBuilder new 
			nodes: flow nodes;
			activations: self rootExecutor activations;
			build )
		yourself
]

{ #category : 'testing' }
FBFlowInstance >> isDone [
	^ executor isDone
]

{ #category : 'testing' }
FBFlowInstance >> isRootExecutor [

	^ self rootExecutor = self executor
]

{ #category : 'accessing' }
FBFlowInstance >> metadata [
	
	^ metadata ifNil: [ FBProperties new]
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: aString [ 
	metadata ifNil: [ KeyNotFound signalFor: aString ].
	^ self metadata at: aString
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key ifAbsent: aBlock [
	metadata ifNil: [ ^ aBlock value ].
	^ self metadata 
		at: key 
		ifAbsent: aBlock
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key ifPresent: aBlock [
	metadata ifNil: [ ^ nil ].
	^ self metadata 
		at: key 
		ifPresent: aBlock
]

{ #category : 'accessing' }
FBFlowInstance >> metadataAt: key put: anObject [ 
	metadata ifNil: [ metadata := FBProperties new ].
	self metadata  
		at: key 
		put: anObject
]

{ #category : 'instance creation' }
FBFlowInstance >> newActivation [ 
	self initializeExecutor.
	^ executor newActivation 
]

{ #category : 'accessing' }
FBFlowInstance >> nextNode [
	^ self nextTransition target
]

{ #category : 'accessing' }
FBFlowInstance >> nextTransition [
	^ executor firstPending
]

{ #category : 'accessing' }
FBFlowInstance >> parallelExecutorFrom: aNode ifAbsent: aBlock [

	^ executors detect: [ :each | each isParallel and: [each node = aNode] ] ifNone: aBlock 
]

{ #category : 'accessing' }
FBFlowInstance >> pending [
	^ self executor pending
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> popExecutor: anExecutor [ 
	executor := anExecutor
]

{ #category : 'printing' }
FBFlowInstance >> printOn: aStream [ 
	aStream << 'flow instance id=' << id asString
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> pushExecutor: anExecutor [
 
	executors add: anExecutor.
	executor := anExecutor 
		flowInstance: self;
		suspendedExecutor: executor;
		yourself
]

{ #category : 'finalization' }
FBFlowInstance >> rootExecutor [
	^ executor rootExecutor
]

{ #category : 'accessing' }
FBFlowInstance >> start [
	^ flow start
]

{ #category : 'accessing' }
FBFlowInstance >> state [

	(executor isNil or: [self rootExecutor isCreated]) ifTrue: [ ^ #created ].
	(self isRootExecutor not or: [self rootExecutor isRunning]) ifTrue: [ ^ #running ].
	(self executors anySatisfy:[:each | each hasErrors]) ifTrue: [ ^ #error ].
	(self executors anySatisfy:[:each | each isWaiting])  ifTrue: [ ^ #waiting ].
	(self executors anySatisfy:[:each | each isDone]) ifTrue: [ ^ #done ].

]

{ #category : 'executing' }
FBFlowInstance >> step [
	self initializeExecutor.
	^ self executor step
]

{ #category : 'accessing' }
FBFlowInstance >> suspended [

	^ executors flatCollect:  [ :each | each suspended ]
]

{ #category : 'as yet unclassified' }
FBFlowInstance >> whenAnnounced: aClass do: aBlock [ 
	announcer ifNil: [ announcer := Announcer new ].
	announcer when: aClass do: aBlock 
]
