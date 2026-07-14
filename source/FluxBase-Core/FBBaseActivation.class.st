Class {
	#name : 'FBBaseActivation',
	#superclass : 'Object',
	#instVars : [
		'executor',
		'node',
		'state',
		'id',
		'timestamp'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'activation' }
FBBaseActivation >> activate [
	node activateWith: self 
]

{ #category : 'events' }
FBBaseActivation >> addEvent: aFBFlowEvent [

	self flowInstance addEvent: (aFBFlowEvent
			 activation: self;
			 yourself)
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> done [
	state := #done
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> errored [ 
	state := #error
]

{ #category : 'events' }
FBBaseActivation >> events [
	^ self flowInstance eventsOfActivation: self
]

{ #category : 'accessing' }
FBBaseActivation >> executor [

	^ executor
]

{ #category : 'accessing' }
FBBaseActivation >> executor: aFBFlowExecutor [ 
	executor := aFBFlowExecutor 
]

{ #category : 'accessing' }
FBBaseActivation >> flow [
	^ executor flow
]

{ #category : 'events' }
FBBaseActivation >> flowInstance [
	^ executor flowInstance 
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followAll: aCollection [
	aCollection do: [ :transition |
		 self followTransition: transition ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followAllOutgoing [
	self node outgoing do: [ :transition |
		 self followTransition: transition ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followTransition: aTransition [
	(aTransition conditionMatches: self value) ifTrue: [ 
		executor flowInstance executor addPending: aTransition ]
]

{ #category : 'testing' }
FBBaseActivation >> hasError [
	^ state = #error
]

{ #category : 'accessing' }
FBBaseActivation >> id [

	^ id
]

{ #category : 'initialization' }
FBBaseActivation >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId.
	timestamp := DateAndTime now.
	state := #created
]

{ #category : 'accessing' }
FBBaseActivation >> instance [
	^ executor flowInstance
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> isDone [
	^ state = #done
]

{ #category : 'accessing' }
FBBaseActivation >> node [
	^ node
]

{ #category : 'accessing' }
FBBaseActivation >> node: aFBNode [
	node := aFBNode
]

{ #category : 'services' }
FBBaseActivation >> output [

	^ self node outputFor: self
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> shouldFollowTransition: aTransition with: value [
	^ (aTransition conditionMatches: value) 
]

{ #category : 'accessing' }
FBBaseActivation >> state [
	^ state
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> waitForNode: aNode [
	state := #waiting.
	executor addWaiting: aNode
]
