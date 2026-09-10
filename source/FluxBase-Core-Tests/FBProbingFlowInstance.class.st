"
A flow instance for tests that records what the engine asks it before a transition
(FBFlowInstance>>aboutToTransition:) and can refuse one, the way ApptiveBase's instance
refuses a transition whose rate limit is used up.
"
Class {
	#name : 'FBProbingFlowInstance',
	#superclass : 'FBFlowInstance',
	#instVars : [
		'asked',
		'refusal'
	],
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'hooks' }
FBProbingFlowInstance >> aboutToTransition: aTransition [
	self asked add: aTransition.
	refusal ifNotNil: [ :block | block value: aTransition ]
]

{ #category : 'accessing' }
FBProbingFlowInstance >> asked [
	^ asked ifNil: [ asked := OrderedCollection new ]
]

{ #category : 'accessing' }
FBProbingFlowInstance >> refuseWith: aBlock [
	"aBlock gets every transition asked about and may raise"
	refusal := aBlock
]
