Class {
	#name : 'FBFlowExecutor',
	#superclass : 'FBBaseExecutor',
	#instVars : [
		'initialValue'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBFlowExecutor >> atEnd [
	^ self isDone 
]

{ #category : 'executing' }
FBFlowExecutor >> execute [
	[ pending isEmpty ] whileFalse: [
		self step ]

	
]

{ #category : 'accessing' }
FBFlowExecutor >> initialValue [
	^ initialValue
]

{ #category : 'accessing' }
FBFlowExecutor >> initialValue: anObject [
	initialValue := anObject
]

{ #category : 'as yet unclassified' }
FBFlowExecutor >> newActivation [ 
	^ self activationClass new
		executor: self
]

{ #category : 'executing' }
FBFlowExecutor >> newActivation: transition [ 
	^ self newActivation 
		node: transition target;
		yourself
]

{ #category : 'executing' }
FBFlowExecutor >> step [
	| transition activation lastValue |
	flowInstance aboutToTransition: pending first.
	transition := pending removeFirst. 
	lastValue := transition source lastValueIn: self.
	flowInstance addEvent: (FBTransitionFollowed new transition: transition; value: lastValue).
	activation := self newActivation: transition. 
	activation argument: lastValue.
	self activate: activation
]
