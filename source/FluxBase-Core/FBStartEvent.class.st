Class {
	#name : 'FBStartEvent',
	#superclass : 'FBEvent',
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'instance creation' }
FBStartEvent class >> typeName [

	^ #start
]

{ #category : 'visiting' }
FBStartEvent >> acceptFluxBase: aFBVisitor [
	^ aFBVisitor visitStartEvent: self
]

{ #category : 'adding' }
FBStartEvent >> addIncoming: aTransition [ 
	FBCannotAddTransition signal: 'a start node cannot have incming transitions'
]

{ #category : 'adding' }
FBStartEvent >> addOutgoing: aTransition [ 
	outgoing isEmpty ifFalse: [ 
		FBCannotAddTransition signal: 'a start node can only have 1 outgoing transition' ].
	super addOutgoing: aTransition 
]

{ #category : 'accessing' }
FBStartEvent >> defaultBehaviorClass [
	^ FBStartEventBehavior
]

{ #category : 'initialization' }
FBStartEvent >> initialize [ 
	super initialize.
	name := 'start'
]

{ #category : 'accessing' }
FBStartEvent >> lastValueIn: aFBFlowExecutor [ 
	^ aFBFlowExecutor initialValue 
]

{ #category : 'accessing' }
FBStartEvent >> source [
	^ self 
]

{ #category : 'accessing' }
FBStartEvent >> target [
	^ self
]
