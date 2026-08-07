Class {
	#name : 'FBEndEvent',
	#superclass : 'FBEvent',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBEndEvent class >> typeName [

	^ #end
]

{ #category : 'adding' }
FBEndEvent >> addOutgoing: aTransition [ 
	FBCannotAddTransition signal: 'an end node cannot have outgoing transitions'
]

{ #category : 'accessing' }
FBEndEvent >> defaultBehaviorClass [
	^ FBEndEventBehavior
]

{ #category : 'initialization' }
FBEndEvent >> initialize [
	super initialize.
	name := 'end'
]

{ #category : 'testing' }
FBEndEvent >> isFlowTerminal [
	^ true
]
